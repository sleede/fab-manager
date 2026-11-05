"""Explicit Docker maintenance boundary. No service discovery followed by destructive actions."""
import collections
import hashlib
import os
from pathlib import Path
import re
import subprocess
import time
import urllib.parse
from common import Blocked, atomic, canonical, decode, digest, free_space


class Control:
    def __init__(self, ledger):
        self.ledger = ledger
        self.config = ledger.config['docker']
        self.names = [self.config[key] for key in ('source', 'target', 'sql', 'redis')]
        self.names += [item['name'] for item in self.config['producers']]
        self.names += self.config.get('auxiliaries', [])
        if not self.config['producers'] or len(set(self.names)) != len(self.names):
            raise Blocked('Distinct source/target/SQL/Redis and explicit producer containers required')
        if any(not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]+', name) for name in self.names):
            raise Blocked('Explicit container names required')

    def run(self, *arguments):
        result = subprocess.run(['docker', *arguments], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode:
            raise Blocked('Docker command failed: ' + ' '.join(arguments[:2]) + ' (details withheld; inspect the named container)')
        return result.stdout

    def inspect(self, name):
        return decode(self.run('inspect', name))[0]

    def topology(self, attach=False, adopt=False, adopt_target=False):
        network = decode(self.run('network', 'inspect', self.config['network']))[0]
        if not network.get('Internal'):
            raise Blocked('Migration network must be internal')
        identities = {}
        known_ids = {self.inspect(item)['Id'] for item in self.names}
        for name in self.names:
            info = self.inspect(name)
            identities[name] = info['Id']
            if info['HostConfig'].get('PortBindings'):
                raise Blocked('Published service ports are outside the supported isolated procedure: ' + name)
            if attach and name in self.names[:2] and self.config['network'] not in info['NetworkSettings']['Networks']:
                side = 'source' if name == self.config['source'] else 'target'
                hostname = urllib.parse.urlsplit(self.ledger.config[side]['url']).hostname
                self.run('network', 'connect', '--alias', hostname, self.config['network'], name)
                info = self.inspect(name)
            for attached in info['NetworkSettings']['Networks']:
                attached_info = decode(self.run('network', 'inspect', attached))[0]
                if not attached_info.get('Internal'):
                    raise Blocked('Service also attached to an external network: ' + name)
                unknown = set(attached_info.get('Containers', {})) - known_ids
                if unknown:
                    raise Blocked('Unknown peer on a source/target network; inventory its producer role first')
        previous = self.ledger.state.get('containers')
        if not previous:
            self.ledger.save(original_containers=identities,
                             original_producer_images={item['name']: self.inspect(item['name'])['Image'] for item in self.config['producers']})
        if previous and previous != identities:
            changed = {name for name in identities if identities[name] != previous.get(name)}
            producers = {item['name'] for item in self.config['producers']}
            producer_change = adopt and changed <= producers
            target_change = (adopt_target and changed == {self.config['target']} and self.ledger.state['phase'] == 'writes_open'
                             and self.ledger.state.get('data_volumes', {}).get('target') == self.volume('target')
                             and self.ledger.state.get('data_images', {}).get('target') == self.inspect(self.config['target'])['Image'])
            if not (producer_change or target_change):
                raise Blocked('Container identity changed during maintenance')
        if not self.ledger.state.get('data_volumes'):
            self.ledger.save(data_volumes={side: self.volume(side) for side in ('source', 'target', 'sql', 'redis')},
                             data_images={side: self.inspect(self.config[side])['Image'] for side in ('source', 'target', 'sql', 'redis')})
        self.ledger.save(containers=identities)
        source_volume = self.volume('source')
        if source_volume == self.volume('target'):
            raise Blocked('Source and target Elasticsearch volumes must be distinct')

    def address(self, side):
        endpoint = self.ledger.config[side].get('endpoint_container', self.config[side])
        if endpoint not in self.names:
            raise Blocked('Endpoint relay must be explicitly inventoried as an auxiliary container')
        info = self.inspect(endpoint)
        address = info['NetworkSettings']['Networks'].get(self.config['network'], {}).get('IPAddress')
        if not info['State']['Running'] or not address:
            raise Blocked('Endpoint container is stopped or disconnected: ' + side)
        return address

    def volume(self, side):
        destination = {'source': '/usr/share/elasticsearch/data', 'target': '/usr/share/elasticsearch/data',
                       'sql': '/var/lib/postgresql/data', 'redis': '/data',
                       'source_backup': self.ledger.config['snapshot']['location']}[side]
        container_side = 'source' if side == 'source_backup' else side
        mounts = [item for item in self.inspect(self.config[container_side])['Mounts'] if item['Destination'] == destination]
        if len(mounts) != 1 or mounts[0]['Type'] != 'volume':
            raise Blocked('This procedure requires a dedicated named volume: ' + side)
        return mounts[0]['Name']

    def redis(self, *arguments):
        return self.run('exec', self.config['redis'], 'redis-cli', '--raw', *map(str, arguments)).decode().rstrip('\n')

    def busy(self):
        script = "local r={} for _,p in ipairs(redis.call('SMEMBERS','processes')) do r[p]=redis.call('HGET',p,'busy') end return cjson.encode(r)"
        result = decode(self.redis('EVAL', script, 0))
        return {key: int(value or 0) for key, value in (result or {}).items()}

    def pending(self):
        counts, classes = {}, collections.Counter()
        fingerprint = hashlib.sha256()
        path = self.ledger.root / 'pending-jobs.jsonl'
        with path.open('w') as stream:
            os.chmod(path, 0o600)
            queues = sorted(filter(None, self.redis('SMEMBERS', 'queues').splitlines()))
            keys = [('queue:' + queue, 'LLEN', 'LRANGE') for queue in queues]
            keys += [(name, 'ZCARD', 'ZRANGE') for name in ('schedule', 'retry', 'dead')]
            for key, length_command, range_command in keys:
                count = int(self.redis(length_command, key) or 0)
                counts[key] = count
                for start in range(0, count, 100):
                    free_space(self.ledger.root, self.ledger.config['minimum_free_bytes'])
                    items = self.redis(range_command, key, start, start + 99).splitlines()
                    for raw in items:
                        item = decode(raw)
                        classes[item.get('class', 'unknown')] += 1
                        entry = {'key': key, 'jid': item.get('jid'), 'class': item.get('class'), 'payload_sha256': digest(item)}
                        fingerprint.update((canonical(entry) + '\n').encode())
                        stream.write(canonical(entry) + '\n')
            stream.flush()
            os.fsync(stream.fileno())
        result = {'counts': counts, 'classes': dict(classes), 'sha256': fingerprint.hexdigest(),
                  'policy': 'All pre-maintenance jobs remain on legacy queues; no automatic replay or purge.'}
        atomic(self.ledger.root / 'pending-summary.json', result)
        return result

    def stop_producers(self, check_sql):
        for item in self.config['producers']:
            if item.get('worker') and self.inspect(item['name'])['State']['Running']:
                if item.get('supervisor'):
                    self.run('exec', item['name'], 'supervisorctl', 'signal', 'TSTP', item['supervisor'])
                else:
                    self.run('kill', '--signal=TSTP', item['name'])
            elif self.inspect(item['name'])['State']['Running']:
                self.run('stop', '--time', str(self.config.get('stop_seconds', 60)), item['name'])
        # Recover a partially completed maintenance step. Never restart a producer.
        for side in ('redis', 'sql'):
            if not self.inspect(self.config[side])['State']['Running']:
                if any(self.inspect(item['name'])['State']['Running'] for item in self.config['producers']):
                    raise Blocked('Stop all producers before recovering partially stopped databases')
                self.run('start', self.config[side])
        for _ in range(60):
            try:
                self.run('exec', self.config['sql'], 'pg_isready', '-U', self.config.get('sql_user', 'postgres'))
                if self.redis('PING') == 'PONG':
                    break
            except Blocked:
                pass
            time.sleep(1)
        else:
            raise Blocked('SQL/Redis did not become ready for the final maintenance check')
        deadline = time.monotonic() + self.config.get('drain_seconds', 60)
        while any(self.busy().values()):
            if time.monotonic() >= deadline:
                raise Blocked('Active Sidekiq work remains; maintenance is not established')
            time.sleep(1)
        for item in self.config['producers']:
            if self.inspect(item['name'])['State']['Running']:
                self.run('stop', '--time', str(self.config.get('stop_seconds', 60)), item['name'])
        # No open SQL transaction may straddle the final snapshot. SQL itself is then stopped.
        sql = self.run('exec', self.config['sql'], 'psql', '-XAt', '-U', self.config.get('sql_user', 'postgres'),
                       '-d', self.config.get('sql_database', 'postgres'), '-c',
                       "SELECT count(*) FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND (state <> 'idle' OR xact_start IS NOT NULL)")
        if int(sql.strip()) != 0:
            raise Blocked('SQL transactions remain; stop or drain the identified producers')
        check_sql()
        pending = self.pending()
        if self.redis('SAVE') != 'OK':
            raise Blocked('Redis SAVE did not complete')
        self.run('stop', '--time', '60', self.config['redis'], self.config['sql'])
        self.ledger.save(pending=pending, producers_stopped_at=time.time())

    def stopped(self):
        names = [item['name'] for item in self.config['producers']] + [self.config['sql'], self.config['redis']]
        if any(self.inspect(name)['State']['Running'] for name in names):
            raise Blocked('A producer, SQL or Redis is running during the coherent copy')

    def backups(self):
        self.stopped()
        artifacts = self.ledger.state.get('backups', {})
        directory = self.ledger.root / 'backups'
        directory.mkdir(mode=0o700, exist_ok=True)
        try:
            for side in ('source', 'sql', 'redis'):
                if side in artifacts:
                    path = Path(artifacts[side]['path'])
                    if hash_file(path) != artifacts[side]['sha256']:
                        raise Blocked('Existing compatible backup changed')
                    continue
                volume = self.volume('source_backup' if side == 'source' else side)
                image = self.config['archive_image']
                size = int(self.run('run', '--rm', '--network', 'none', '-v', volume + ':/from:ro', image,
                                    'du', '-sb', '/from').split()[0])
                free_space(directory, size * 2 + self.ledger.config['minimum_free_bytes'])
                partial = side + '-' + str(time.time_ns()) + '.partial'
                self.run('run', '--rm', '--network', 'none', '-v', volume + ':/from:ro', '-v', str(directory) + ':/backup',
                         image, 'tar', '-C', '/from', '-cpf', '/backup/' + partial, '.')
                path = directory / (side + '.tar')
                if path.exists():
                    raise Blocked('Unjournaled archive already exists; inspect it before recovery')
                os.rename(directory / partial, path)
                os.chmod(path, 0o600)
                with path.open('rb') as stream:
                    os.fsync(stream.fileno())
                artifacts[side] = {'path': str(path), 'sha256': hash_file(path), 'volume': volume,
                                   'image_id': self.inspect(self.config[side])['Image'], 'bytes': path.stat().st_size,
                                   'format': 'es5-native-snapshot-repository' if side == 'source' else 'stopped-volume-tar'}
                self.ledger.save(backups=artifacts)
        finally:
            self.ledger.event('backup_attempt_finished')
        return artifacts

    def verify_backups(self):
        artifacts = self.ledger.state.get('backups', {})
        if set(artifacts) != {'source', 'sql', 'redis'}:
            raise Blocked('All three compatible backups are required')
        for artifact in artifacts.values():
            if hash_file(artifact['path']) != artifact['sha256']:
                raise Blocked('Compatible backup checksum differs')

    def capture_activation(self):
        path = Path(self.ledger.config['activation_file']).resolve()
        original = self.ledger.root / 'activation.before'
        if not original.exists():
            if self.ledger.state.get('activation_before_sha256'):
                raise Blocked('Original deployment environment backup is missing')
            if not path.is_file():
                raise Blocked('Existing deployment environment file required')
            original.write_bytes(path.read_bytes())
            os.chmod(original, 0o600)
        checksum = hash_file(original)
        if self.ledger.state.get('activation_before_sha256', checksum) != checksum:
            raise Blocked('Original deployment environment backup changed')
        self.ledger.save(activation_before_sha256=checksum)
        return path, original

    def activation(self, target):
        path, original = self.capture_activation()
        if target:
            settings = {**self.ledger.config['target_activation'],
                        'ELASTICSEARCH_URL': self.ledger.config['target']['url'],
                        'ES_MIGRATION_GUARD': '/run/fab-manager-es-migration/guard.json'}
            if any(not re.fullmatch(r'[A-Z_][A-Z0-9_]*', key) or not isinstance(value, str) or '\n' in value or '\r' in value for key, value in settings.items()):
                raise Blocked('Invalid deployment environment entry')
            text = original.read_text()
            retained = [line for line in text.splitlines() if line.partition('=')[0] not in settings]
            text = '\n'.join(retained + [key + '=' + value for key, value in settings.items()]) + '\n'
            self.ledger.save(activation_target_sha256=hashlib.sha256(text.encode()).hexdigest())
        else:
            text = original.read_text()
        if hash_file(path) not in {self.ledger.state['activation_before_sha256'], self.ledger.state.get('activation_target_sha256')}:
            raise Blocked('Deployment environment changed outside the journaled switch')
        temporary = path.with_name(path.name + '.migration-tmp')
        with temporary.open('w') as stream:
            os.chmod(temporary, 0o600)
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)

    def detach(self):
        names = [self.config[side] for side in ('source', 'target')]
        names += [self.ledger.config[side].get('endpoint_container', self.config[side]) for side in ('source', 'target')]
        for name in dict.fromkeys(names):
            if self.config['network'] in self.inspect(name)['NetworkSettings']['Networks']:
                self.run('network', 'disconnect', self.config['network'], name)
        self.ledger.event('temporary_network_detached')

    def verify_deployment(self):
        for item in self.config['producers']:
            info = self.inspect(item['name'])
            if info['State']['Running']:
                raise Blocked('Target producers must remain stopped until reopening is complete')
            expected = item.get('target_image', '')
            if not re.fullmatch(r'sha256:[a-f0-9]{64}', expected) or info['Image'] != expected:
                raise Blocked('Target producer image is not the configured reviewed image digest')
            env = dict(line.split('=', 1) for line in info['Config']['Env'] if '=' in line)
            if env.get('ELASTICSEARCH_URL') != self.ledger.config['target']['url'] or env.get('ES_MIGRATION_GUARD') != '/run/fab-manager-es-migration/guard.json':
                raise Blocked('Target producer environment does not enforce the migration guard')
            mounts = [m for m in info['Mounts'] if m['Destination'] == '/run/fab-manager-es-migration']
            if len(mounts) != 1 or mounts[0]['RW'] or Path(mounts[0]['Source']).resolve() != self.ledger.root / 'runtime':
                raise Blocked('Target producers require the current guard directory mounted read-only')


def hash_file(path):
    value = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            value.update(block)
    return value.hexdigest()
