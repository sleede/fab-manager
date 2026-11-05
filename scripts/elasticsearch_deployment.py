#!/usr/bin/env python3
"""Explicit ES9 preparation, credentials, read-only upgrade preflight and native backups."""
import argparse
import base64
import hashlib
import http.client
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import ssl
import subprocess
import sys
import time
import urllib.parse

FAMILIES = ['account', 'event', 'machine', 'project', 'subscription', 'training', 'user', 'space', 'order']
INDICES = ['fm-stats-' + f + '-v1' for f in FAMILIES] + ['fm-availabilities-v1']
ALIASES = ['fm-stats-' + f for f in FAMILIES] + ['fm-availabilities', 'fm-stats-all']
VERSION = '9.5.6'


class Refused(RuntimeError):
    pass


def private_file(path, text, mode=0o600):
    path = Path(path)
    with path.open('x') as stream:
        os.chmod(path, mode)
        stream.write(text)


def private_directory(path):
    directory = Path(path).resolve()
    if any((parent / '.git').exists() for parent in [directory, *directory.parents]):
        raise Refused('Keep persistent CA and credentials outside a Git checkout')
    return directory


def prepare(directory, hostname):
    directory = private_directory(directory)
    if directory.exists():
        raise Refused('Secrets directory already exists; credentials/CA must be retained, never regenerated on recreate')
    if not hostname or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-' for c in hostname):
        raise Refused('Explicit DNS hostname required')
    directory.mkdir(mode=0o700, parents=True)
    (directory / 'server').mkdir(mode=0o755)
    (directory / 'public').mkdir(mode=0o755)
    for name in ['bootstrap', 'runtime', 'migration', 'backup', 'health']:
        private_file(directory / (name + '_password'), secrets.token_hex(32) + '\n', 0o640)
    if os.geteuid() == 0:
        os.chown(directory / 'bootstrap_password', 1000, 0)
    commands = [
        ['openssl', 'req', '-x509', '-newkey', 'rsa:3072', '-nodes', '-days', '365', '-subj', '/CN=Fab-manager Elasticsearch CA',
         '-keyout', str(directory / 'ca.key'), '-out', str(directory / 'server/ca.crt')],
        ['openssl', 'req', '-newkey', 'rsa:3072', '-nodes', '-subj', '/CN=' + hostname,
         '-keyout', str(directory / 'server/elasticsearch.key'), '-out', str(directory / 'server.csr')]]
    private_file(directory / 'extensions.cnf', 'subjectAltName=DNS:' + hostname + '\nextendedKeyUsage=serverAuth\n')
    commands.append(['openssl', 'x509', '-req', '-in', str(directory / 'server.csr'), '-CA', str(directory / 'server/ca.crt'),
                     '-CAkey', str(directory / 'ca.key'), '-CAcreateserial', '-days', '365', '-extfile', str(directory / 'extensions.cnf'),
                     '-out', str(directory / 'server/elasticsearch.crt')])
    for command in commands:
        subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.chmod(directory / 'ca.key', 0o600)
    os.chmod(directory / 'server/elasticsearch.key', 0o640)
    if os.geteuid() == 0:
        os.chown(directory / 'server/elasticsearch.key', 1000, 0)
    (directory / 'public/ca.crt').write_bytes((directory / 'server/ca.crt').read_bytes())
    private_file(directory / 'health.curl', 'user = "fm_health:' + (directory / 'health_password').read_text().strip() + '"\n', 0o444)
    private_file(directory / 'manifest.json', json.dumps({'format': 1, 'hostname': hostname, 'version': VERSION,
        'ca_sha256': hashlib.sha256((directory / 'public/ca.crt').read_bytes()).hexdigest()}, indent=2) + '\n')


class API:
    def __init__(self, url, username=None, password=None, ca=None, address=None, detect=False, api_key=None):
        parsed = urllib.parse.urlsplit(url)
        if parsed.username or parsed.password or parsed.path not in ('', '/') or parsed.query or parsed.fragment or not parsed.hostname:
            raise Refused('Fixed origin without embedded credentials required')
        if parsed.scheme != 'https' and not (detect and parsed.scheme == 'http'):
            raise Refused('Verified HTTPS is required for Elasticsearch 9')
        self.host, self.port, self.scheme = parsed.hostname, parsed.port or (443 if parsed.scheme == 'https' else 80), parsed.scheme
        self.address = address
        self.context = ssl.create_default_context(cafile=ca)
        self.headers = {'Content-Type': 'application/json'}
        if username and password:
            self.headers['Authorization'] = 'Basic ' + base64.b64encode((username + ':' + password).encode()).decode()
        if api_key:
            if password:
                raise Refused('Choose Basic or API key authentication')
            self.headers['Authorization'] = 'ApiKey ' + api_key

    def call(self, method, path, body=None):
        connection = (http.client.HTTPSConnection(self.host, self.port, context=self.context, timeout=30)
                      if self.scheme == 'https' else http.client.HTTPConnection(self.host, self.port, timeout=30))
        if self.address:
            connection._create_connection = lambda address, timeout, *a, **kw: socket.create_connection((self.address, address[1]), timeout)
        try:
            connection.request(method, path, json.dumps(body).encode() if body is not None else None, self.headers)
            response = connection.getresponse()
            raw = response.read(32 * 1024 * 1024 + 1)
            if len(raw) > 32 * 1024 * 1024:
                raise Refused('Oversized Elasticsearch response')
            if not 200 <= response.status < 300:
                raise Refused('Elasticsearch returned HTTP ' + str(response.status) + ' for ' + method + ' ' + path)
            return json.loads(raw)
        finally:
            connection.close()


def local_api(args, role):
    directory = Path(args.secrets).resolve()
    user = 'elastic' if role == 'bootstrap' else 'fm_' + role
    return API(args.url, user, (directory / (role + '_password')).read_text().strip(), str(directory / 'public/ca.crt'), args.address)


def provision(args):
    client = local_api(args, 'bootstrap')
    info = client.call('GET', '/')
    if info['version']['number'] != VERSION:
        raise Refused('Expected the reviewed exact ES9 target version')
    license = client.call('GET', '/_license')['license']
    if license['type'] != 'basic' or license['status'] != 'active':
        raise Refused('An active Basic license is required; no trial or paid feature is implicitly activated')
    existing = client.call('GET', '/_mapping?expand_wildcards=all')
    if any(not index.startswith('.') for index in existing):
        raise Refused('Provision only a fresh local target; retain existing users and secrets on recreation or external services')
    scoped = INDICES + ALIASES
    roles = {
        'runtime': {'cluster': ['monitor'], 'indices': [{'names': scoped, 'privileges': ['read', 'write', 'view_index_metadata', 'maintenance', 'auto_configure']}]},
        'migration': {'cluster': ['monitor'], 'indices': [
            {'names': ['*'], 'privileges': ['view_index_metadata'], 'allow_restricted_indices': True},
            {'names': scoped, 'privileges': ['all']}]},
        'backup': {'cluster': ['monitor', 'create_snapshot'], 'indices': [{'names': scoped, 'privileges': ['read', 'view_index_metadata']}]},
        'health': {'cluster': ['monitor'], 'indices': []}}
    for name, definition in roles.items():
        client.call('PUT', '/_security/role/fm_' + name, definition)
        client.call('PUT', '/_security/user/fm_' + name, {'password': (Path(args.secrets) / (name + '_password')).read_text().strip(),
            'roles': ['fm_' + name], 'enabled': True})
    client.call('PUT', '/_snapshot/fm-backup', {'type': 'fs', 'settings': {'location': '/snapshots'}})
    # A production external cluster is never provisioned automatically; this command is explicit.
    return {'version': info['version']['number'], 'cluster_uuid': info['cluster_uuid'], 'license': license['type'], 'roles': roles}


def environment(path):
    result = {}
    for line in Path(path).read_text().splitlines():
        if line.strip() and not line.lstrip().startswith('#'):
            key, separator, value = line.partition('=')
            if not separator:
                raise Refused('Invalid environment file')
            result[key.strip()] = value.strip().strip('\"\'')
    return result


def configured_api(args):
    env = environment(args.env_file)
    def resolve(value):
        if args.secrets and value.startswith('/run/es-certificates/'):
            return str(Path(args.secrets) / 'public' / Path(value).name)
        if args.secrets and value.startswith('/run/es-secrets/'):
            return str(Path(args.secrets) / Path(value).name)
        return value
    password = env.get('ELASTICSEARCH_PASSWORD')
    if env.get('ELASTICSEARCH_PASSWORD_FILE'):
        password = Path(resolve(env['ELASTICSEARCH_PASSWORD_FILE'])).read_text().strip()
    api_key = env.get('ELASTICSEARCH_API_KEY')
    if env.get('ELASTICSEARCH_API_KEY_FILE'):
        api_key = Path(resolve(env['ELASTICSEARCH_API_KEY_FILE'])).read_text().strip()
    url = env.get('ELASTICSEARCH_URL') or 'http://' + env.get('ELASTICSEARCH_HOST', 'elasticsearch') + ':9200'
    return API(url, env.get('ELASTICSEARCH_USERNAME'), password,
               resolve(env['ELASTICSEARCH_CA_FILE']) if env.get('ELASTICSEARCH_CA_FILE') else None, args.address, detect=True, api_key=api_key)


def external(args):
    # Validate first; never create users, repositories or cluster settings on an external service.
    original_secrets = args.secrets
    args.secrets = None
    result = preflight(args)
    args.secrets = original_secrets
    values = environment(args.env_file)
    directory = private_directory(args.secrets)
    if directory.exists():
        raise Refused('External credential directory already exists; retain it on upgrades')
    directory.mkdir(mode=0o700, parents=True)
    (directory / 'public').mkdir(mode=0o755)
    shutil.copyfile(values['ELASTICSEARCH_CA_FILE'], directory / 'public/ca.crt')
    credentials = {}
    for name, basename in [('PASSWORD', 'runtime_password'), ('API_KEY', 'runtime_api_key')]:
        value = values.get('ELASTICSEARCH_' + name)
        if values.get('ELASTICSEARCH_' + name + '_FILE'):
            value = Path(values['ELASTICSEARCH_' + name + '_FILE']).read_text().strip()
        if value:
            private_file(directory / basename, value + '\n', 0o600)
            credentials['ELASTICSEARCH_' + name + '_FILE'] = '/run/es-secrets/' + basename
    if len(credentials) != 1:
        raise Refused('Supply exactly one external password/API key; credentials remain outside Git')
    output = Path(args.output_env)
    retained = [line for line in output.read_text().splitlines() if not line.startswith('ELASTICSEARCH_')]
    appended = {'ELASTICSEARCH_URL': values['ELASTICSEARCH_URL'], 'ELASTICSEARCH_USERNAME': values.get('ELASTICSEARCH_USERNAME', ''),
                'ELASTICSEARCH_CA_FILE': '/run/es-certificates/ca.crt', **credentials}
    output.write_text('\n'.join(retained + [key + '=' + value for key, value in appended.items()]) + '\n')
    os.chmod(output, 0o600)
    # Docker Compose parses its own format; Python does not introduce a YAML dependency.
    config = json.loads(subprocess.check_output(['docker', 'compose', '-f', args.compose, 'config', '--format', 'json']))
    del config['services']['elasticsearch']
    config['services'].pop('search-permissions', None)
    config.get('secrets', {}).clear()
    config['services']['fabmanager'].pop('secrets', None)
    config['volumes'] = {}
    volumes = config['services']['fabmanager']['volumes']
    volumes[:] = [v for v in volumes if not v['target'].startswith('/run/es-secrets/')]
    for key in credentials:
        basename = Path(credentials[key]).name
        volumes.append({'type': 'bind', 'source': str(directory / basename), 'target': credentials[key], 'read_only': True})
    Path(args.compose).write_text(json.dumps(config, indent=2) + '\n')
    return {**result, 'external': True, 'cluster_mutated': False}


def preflight(args):
    # Read-only and performed before pull/tag edits/DB migrations or container stops.
    if getattr(args, 'container', None):
        info = json.loads(subprocess.check_output(['docker', 'inspect', args.container]))[0]
        if not info['State']['Running']:
            raise Refused('Elasticsearch container is stopped (' + info['Config']['Image'] + '); do not start a new image on its volume. Follow ES03')
        addresses = [network['IPAddress'] for network in info['NetworkSettings']['Networks'].values() if network.get('IPAddress')]
        if not addresses:
            raise Refused('No private container endpoint available for read-only preflight')
        args.address = addresses[0]
    client = configured_api(args)
    info = client.call('GET', '/')
    version = info['version']['number']
    if not version.startswith('9.'):
        raise Refused('Detected Elasticsearch ' + version + ': STOP. Preserve its image/data/auth; use the ES03 migration runbook before deploying this code')
    if client.scheme != 'https':
        raise Refused('ES9 endpoint must use verified HTTPS')
    return {'version': version, 'cluster_uuid': info['cluster_uuid'], 'compatible': True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('step', choices=['prepare', 'provision', 'preflight', 'backup', 'external'])
    parser.add_argument('--secrets')
    parser.add_argument('--hostname', default='elasticsearch')
    parser.add_argument('--url', default='https://elasticsearch:9200')
    parser.add_argument('--address')
    parser.add_argument('--env-file', default='config/env')
    parser.add_argument('--snapshot')
    parser.add_argument('--output-env')
    parser.add_argument('--compose')
    parser.add_argument('--container')
    args = parser.parse_args()
    try:
        if args.step == 'prepare':
            if not args.secrets:
                raise Refused('--secrets requires a new private directory')
            prepare(args.secrets, args.hostname)
            result = {'prepared': True}
        elif args.step == 'provision':
            result = provision(args)
        elif args.step == 'preflight':
            result = preflight(args)
        elif args.step == 'external':
            result = external(args)
        else:
            if not args.snapshot or any(c not in 'abcdefghijklmnopqrstuvwxyz0123456789-_' for c in args.snapshot):
                raise Refused('Explicit snapshot name required')
            client = local_api(args, 'backup')
            result = client.call('PUT', '/_snapshot/fm-backup/' + args.snapshot + '?wait_for_completion=true',
                {'indices': ','.join(INDICES), 'include_global_state': False, 'partial': False})
            value = result['snapshot']
            if value['state'] != 'SUCCESS' or value['shards']['failed'] or value.get('failures'):
                raise Refused('Native target snapshot incomplete')
        print(json.dumps({'ok': True, **result}, indent=2))
        return 0
    except (Refused, OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(json.dumps({'ok': False, 'reason': str(error)}), file=sys.stderr)
        return 3


if __name__ == '__main__':
    sys.exit(main())
