"""Explicit destructive synthetic tests: requires its own five-container Docker bench."""
import copy
import decimal
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import time
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts/elasticsearch_migration'))
from common import Blocked, HTTP, Ledger, canonical, decode, digest
from transfer import Transfer


class MigrationLiveTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if os.environ.get('ES_CONTRACT_ISOLATED') != '1':
            raise RuntimeError('Explicit disposable migration bench required')
        cls.base_config = decode(Path(os.environ['ES_MIGRATION_LIVE_CONFIG']).read_text())
        if not cls.base_config['docker']['network'].startswith('fm-es-transfer-'):
            raise RuntimeError('Refusing destructive fixtures outside named isolated migration bench')
        cls.root = Path(os.environ['ES_MIGRATION_TEST_OUTPUT'])
        cls.root.mkdir(parents=True, exist_ok=True)

    def setUp(self):
        self.config = copy.deepcopy(self.base_config)
        self.directory = self.root / (self._testMethodName + '-' + str(time.time_ns()))
        self.directory.mkdir()
        self.config['activation_file'] = str(self.directory / 'deployment.env')
        Path(self.config['activation_file']).write_text('FABMANAGER_IMAGE=es5-reviewed\nELASTICSEARCH_HOST=legacy-elasticsearch\n')
        self.journal = Ledger(self.directory / 'journal', self.config)
        self.tool = Transfer(self.journal)
        for name in self.tool.control.names:
            if not self.tool.control.inspect(name)['State']['Running']:
                self.tool.control.run('start', name)
        self.wait_servers()
        for side in ('source', 'target'):
            client = getattr(self.tool, side)
            indices = client.request('GET', '/_settings')
            for index in indices:
                if index in ('stats', 'fablab', 'unexpected') or index.startswith('fm-stats-') or index == 'fm-availabilities-v1':
                    client.request('DELETE', '/' + index)
                else:
                    raise RuntimeError('Unexpected fixture index; do not automatically delete ' + index)
        self.tool.control.redis('FLUSHDB')  # This disposable Redis was created by the named test bench only.
        self.config_path = self.directory / 'config.json'
        self.config_path.write_text(canonical(self.config))

    def tearDown(self):
        self.journal.close()

    def wait_servers(self):
        last = None
        for _ in range(60):
            try:
                self.tool.clients()
                return
            except Blocked as error:
                last = error
                time.sleep(1)
        raise last

    def seed(self, count=3, missing_source=False, invalid=False, extra_index=False, numeric_type='double', availability_hours=2):
        common = {'date': {'type': 'date'}, 'type': {'type': 'keyword'}, 'subType': {'type': 'keyword'},
                  'stat': {'type': numeric_type}, 'ca': {'type': numeric_type}, 'exact_number': {'type': 'long'},
                  'historical_amount': {'type': 'double'}, 'historical_note': {'type': 'string', 'index': 'not_analyzed'},
                  'end_date': {'type': 'keyword' if invalid else 'date'}}
        mappings = {family: {'properties': common, '_source': {'enabled': not missing_source}} for family in self.tool.families if family != 'availabilities'}
        self.tool.source.request('PUT', '/stats', {'settings': {'number_of_shards': 1, 'number_of_replicas': 0}, 'mappings': mappings})
        availability = {**common, 'available_type': {'type': 'text', 'analyzer': 'simple'}, 'hours_duration': {'type': numeric_type}, 'bookable_hours': {'type': numeric_type}}
        self.tool.source.request('PUT', '/fablab', {'settings': {'number_of_shards': 1, 'number_of_replicas': 0},
            'mappings': {'availabilities': {'properties': availability}}})
        source = {'type': 'booking', 'subType': 'historical', 'date': '2019-03-10T01:30:00-05:00', 'stat': 0, 'ca': decimal.Decimal('19.95'),
                  'exact_number': 9007199254740993, 'historical_amount': decimal.Decimal('1234.56789012345678901234567890123456789'),
                  'historical_note': 'Historical; never rebuilt from current SQL', 'nullable': None, 'empty': [], 'missing_is_different': False}
        for family, spec in self.tool.families.items():
            value = {**source}
            if family == 'availabilities':
                value.update(available_type='machines', hours_duration=availability_hours, bookable_hours=availability_hours + 2, end_date='2019-04-10T12:00:00Z')
            self.tool.source.request('PUT', '/' + spec['source_index'] + '/' + family + '/same-id', value)
        for first in range(1, count, 500):
            lines = []
            for number in range(first, min(count, first + 500)):
                lines += [canonical({'index': {'_index': 'stats', '_type': 'machine', '_id': 'id-%06d' % number}}),
                          canonical({**source, 'stat': number % 3})]
            result = self.tool.source.request('POST', '/_bulk', ('\n'.join(lines) + '\n').encode(), raw=True)
            self.assertFalse(result['errors'])
        if invalid:
            self.tool.source.request('PUT', '/fablab/availabilities/invalid-date', {**source, 'end_date': 'not-a-date'})
        if extra_index:
            self.tool.source.request('PUT', '/unexpected', {})
            self.tool.source.request('PUT', '/unexpected/unknown/history', {'preserve': True})
        self.tool.source.request('POST', '/_refresh')
        return source

    def frozen_export(self, count=3, **seed_options):
        self.seed(count, **seed_options)
        self.tool.inventory()
        self.tool.maintenance()
        self.tool.backup()
        self.wait_servers()
        self.tool.export()

    def imported(self, **seed_options):
        self.frozen_export(**seed_options)
        self.tool.initialize()
        self.tool.import_data()

    def test_01_full_copy_interrupt_expiry_backup_rollback_and_reopen(self):
        expected = self.seed(10037)
        job = {'class': 'PeriodStatisticsWorker', 'args': ['2019-01-01'], 'jid': 'historical-job', 'queue': 'default', 'created_at': 1552181400}
        self.tool.control.redis('SADD', 'queues', 'default')
        self.tool.control.redis('LPUSH', 'queue:default', canonical(job))
        self.tool.control.redis('ZADD', 'schedule', '2000000000', canonical({**job, 'jid': 'scheduled-history'}))
        self.tool.control.redis('ZADD', 'retry', '2000000000', canonical({**job, 'jid': 'retry-history'}))
        self.tool.inventory()
        self.tool.maintenance()
        self.assertEqual(self.journal.state['pending']['counts']['queue:default'], 1)
        self.tool.backup()
        self.wait_servers()
        self.journal.close()
        cli = Path(__file__).resolve().parents[2] / 'scripts/elasticsearch_migration/migrate.py'
        with (self.directory / 'interrupted-export.log').open('w') as log:
            process = subprocess.Popen([sys.executable, str(cli), '--config', str(self.config_path), '--journal', str(self.directory / 'journal'), 'export'], stdout=log, stderr=log)
            copied = 0
            for _ in range(1500):
                with sqlite3.connect(self.directory / 'journal/documents.sqlite3') as db:
                    copied = db.execute('SELECT count(*) FROM documents').fetchone()[0]
                if copied > 0 or process.poll() is not None:
                    break
                time.sleep(.01)
            process.kill()
            process.wait()
        self.assertGreater(copied, 0)
        self.assertLess(process.returncode, 0)
        self.journal = Ledger(self.directory / 'journal', self.config)
        self.tool = Transfer(self.journal)
        original = HTTP.request
        expired = []
        def expire_once(client, method, path, body=None, raw=False):
            if client.host == 'legacy-elasticsearch' and method == 'POST' and path == '/_search/scroll' and not expired:
                expired.append(True)
                original(client, 'DELETE', '/_search/scroll', {'scroll_id': [body['scroll_id']]})
            return original(client, method, path, body, raw)
        with patch.object(HTTP, 'request', expire_once):
            self.tool.export()
        self.assertEqual(expired, [True])
        self.assertEqual(self.journal.db.execute('SELECT count(*) FROM documents').fetchone()[0], 10046)
        self.tool.initialize()
        self.tool.import_data()
        # ES5's naive floating-point accumulation differs from ES9 on 10,037 x 19.95.
        # Preserve the fixture and both raw results: this is a BLOCK, not a relaxed snapshot.
        with self.assertRaisesRegex(Blocked, 'aggregations differ'):
            self.tool.validation()
        result = decode((self.journal.root / 'comparison.json').read_text())
        self.assertFalse(result['ok'])
        self.assertEqual(result['differences'], [{'family': 'machine', 'probe': 'business'}])
        for values in result['families'].values():
            self.assertEqual(values['source'], values['target'])
        self.assertEqual(result['families']['machine']['target']['count'], 10037)
        for family, spec in self.tool.families.items():
            hit = self.tool.target.request('GET', '/' + spec['target'] + '/_doc/same-id')
            self.assertEqual(hit['_source']['historical_amount'], expected['historical_amount'])
            self.assertEqual(hit['_source']['exact_number'], 9007199254740993)
            self.assertEqual(hit['_source']['type'], 'booking')
        with self.assertRaises(Blocked):
            self.tool.switch()
        self.tool.rollback()
        self.assertEqual(Path(self.config['activation_file']).read_text(), 'FABMANAGER_IMAGE=es5-reviewed\nELASTICSEARCH_HOST=legacy-elasticsearch\n')
        self.assertEqual(self.tool.source.request('GET', '/stats/machine/same-id')['_source'], expected)
        self.restore_backup()
        # A second journal/copy is required after a rollback; the state machine never relabels it as a validated target.
        with self.assertRaises(Blocked):
            self.tool.reopen()

    def restore_backup(self):
        artifact = self.journal.state['backups']['source']
        name = self.config['docker']['source'] + '-restore-' + self.journal.state['run_id'][:8]
        volume = name + '-data'
        repository_volume = name + '-snapshots'
        self.tool.control.run('volume', 'create', volume)
        self.tool.control.run('volume', 'create', repository_volume)
        self.tool.control.run('run', '--rm', '--network', 'none', '-v', repository_volume + ':/restore',
            '-v', str(Path(artifact['path']).parent) + ':/backup:ro', self.config['docker']['archive_image'],
            'tar', '-C', '/restore', '-xpf', '/backup/source.tar')
        self.tool.control.run('run', '-d', '--name', name, '--network', self.config['docker']['network'],
            '-e', 'ES_JAVA_OPTS=-Xms256m -Xmx256m', '-e', 'discovery.type=single-node', '-e', 'path.repo=/snapshots',
            '-v', volume + ':/usr/share/elasticsearch/data', '-v', repository_volume + ':/snapshots:ro', 'elasticsearch:5.6',
            'elasticsearch', '-Epath.repo=/snapshots', '-Ediscovery.type=single-node')
        try:
            ip = self.tool.control.inspect(name)['NetworkSettings']['Networks'][self.config['docker']['network']]['IPAddress']
            restored = HTTP(self.config['source'], ip)
            for attempt in range(60):
                try:
                    self.assertEqual(restored.request('GET', '/')['version']['number'], '5.6.16')
                    break
                except Blocked:
                    time.sleep(1)
            restored.request('PUT', '/_snapshot/restored', {'type': 'fs', 'settings': {'location': '/snapshots', 'readonly': True}})
            snapshot = self.journal.state['snapshot']['name']
            result = restored.request('POST', '/_snapshot/restored/' + snapshot + '/_restore?wait_for_completion=true', {'include_global_state': False})
            self.assertEqual(result['snapshot']['shards']['failed'], 0)
            restored.request('POST', '/_refresh')
            self.assertEqual(restored.request('GET', '/stats/machine/_count')['count'], 10037)
            self.assertEqual(restored.request('GET', '/stats/machine/same-id')['_source'], self.tool.source.request('GET', '/stats/machine/same-id')['_source'])
            for family, spec in self.tool.families.items():
                observed = 0
                for hits in restored.scroll('/' + spec['source_index'] + '/' + family + '/_search'):
                    for hit in hits:
                        expected = self.journal.db.execute('SELECT sha256 FROM documents WHERE source_type=? AND id=?', (family, hit['_id'])).fetchone()
                        self.assertIsNotNone(expected)
                        self.assertEqual(digest(hit['_source']), expected[0])
                        observed += 1
                self.assertEqual(observed, self.journal.db.execute('SELECT count(*) FROM documents WHERE source_type=?', (family,)).fetchone()[0])
        finally:
            self.tool.control.run('stop', name)

    def test_02_unknown_index_blocks_without_discard(self):
        self.seed(extra_index=True)
        with self.assertRaisesRegex(Blocked, 'Unknown source'):
            self.tool.inventory()
        self.assertTrue(self.tool.source.request('GET', '/unexpected/unknown/history')['_source']['preserve'])
        with self.assertRaises(Blocked):
            self.tool.maintenance()

    def test_03_source_unavailable_is_not_reconstructed(self):
        self.seed(missing_source=True)
        with self.assertRaisesRegex(Blocked, '_source'):
            self.tool.inventory()
        inventory = decode((self.journal.root / 'inventory.json').read_text())
        self.assertGreater(inventory['families']['stats/machine']['missing_source'], 0)

    def test_04_partial_bulk_invalid_document_and_retry(self):
        self.frozen_export(invalid=True)
        self.tool.initialize()
        with self.assertRaisesRegex(Blocked, 'Bulk failed'):
            self.tool.import_data()
        success = self.journal.db.execute('SELECT count(*) FROM documents WHERE imported=1').fetchone()[0]
        self.assertGreater(success, 0)
        with self.assertRaisesRegex(Blocked, 'Bulk failed'):
            self.tool.import_data()
        self.assertEqual(self.journal.db.execute('SELECT count(*) FROM documents WHERE imported=1').fetchone()[0], success)
        with self.assertRaises(Blocked):
            self.tool.switch()

    def test_05_incompatible_mapping_does_not_get_replaced(self):
        self.frozen_export()
        self.tool.target.request('PUT', '/fm-stats-machine-v1', {'mappings': {'properties': {'date': {'type': 'keyword'}}}})
        with self.assertRaisesRegex(Blocked, 'mapping incompatible'):
            self.tool.initialize()
        self.assertEqual(set(self.tool.target.request('GET', '/_mapping')), {'fm-stats-machine-v1'})

    def test_06_real_disk_reserve_blocks_before_copy(self):
        self.seed()
        self.tool.inventory()
        self.tool.maintenance()
        self.tool.config['minimum_free_bytes'] = 10**30
        with self.assertRaisesRegex(Blocked, 'Insufficient local space'):
            self.tool.backup()
        self.assertEqual(self.journal.db.execute('SELECT count(*) FROM documents').fetchone()[0], 0)

    def test_07_source_access_loss_is_blocking_and_resumable(self):
        self.frozen_export()
        self.tool.control.run('stop', self.config['docker']['source'])
        with self.assertRaises(Blocked):
            self.tool.export()
        with self.assertRaises(Blocked):
            self.tool.switch()
        self.tool.control.run('start', self.config['docker']['source'])
        self.wait_servers()
        self.tool.export()
        self.assertEqual(self.journal.db.execute('SELECT count(*) FROM documents').fetchone()[0], 12)

    def test_08_equal_counts_changed_source_or_target_block_validation(self):
        self.imported()
        self.tool.target.request('POST', '/fm-stats-machine-v1/_update/same-id', {'doc': {'ca': 999}})
        with self.assertRaisesRegex(Blocked, 'differ'):
            self.tool.validation()
        report = decode((self.journal.root / 'comparison.json').read_text())
        self.assertFalse(report['ok'])
        self.assertTrue(any(item.get('side') == 'target' for item in report['differences']))
        self.tool.source.request('PUT', '/stats/_settings', {'index.blocks.write': False})
        self.tool.source.request('POST', '/stats/machine/same-id/_update', {'doc': {'ca': 777}})
        self.tool.source.request('PUT', '/stats/_settings', {'index.blocks.write': True})
        self.tool.source.request('POST', '/_refresh')
        with self.assertRaises(Blocked):
            self.tool.validation()
        report = decode((self.journal.root / 'comparison.json').read_text())
        self.assertTrue(any(item.get('side') == 'source' for item in report['differences']))

    def test_09_reopen_preserves_queued_jobs_and_forbids_stale_rollback(self):
        self.seed()
        job = {'class': 'PeriodStatisticsWorker', 'args': [3000], 'jid': 'old-history', 'queue': 'default', 'created_at': 1}
        self.tool.control.redis('SADD', 'queues', 'default')
        self.tool.control.redis('LPUSH', 'queue:default', canonical(job))
        self.tool.inventory(); self.tool.maintenance(); self.tool.backup(); self.wait_servers()
        self.tool.export(); self.tool.initialize(); self.tool.import_data(); self.tool.validation(); self.tool.switch()
        with self.assertRaises(Blocked):
            self.tool.reopen()
        self.deploy_producer()
        self.tool.adopt_producers()
        self.tool.target.request('DELETE', '/fm-stats-machine-v1/_alias/fm-stats-machine')
        with self.assertRaisesRegex(Blocked, 'Required target aliases'):
            self.tool.reopen()
        self.assertEqual(self.journal.state['phase'], 'switched')
        self.tool.target.request('PUT', '/fm-stats-machine-v1/_alias/fm-stats-machine', {'is_write_index': True})
        # A failure after the first unfence must resume as writes_open, never rollback.
        original = HTTP.request
        failed = []
        def fail_once(client, method, path, body=None, raw=False):
            result = original(client, method, path, body, raw)
            if client.host == 'elasticsearch' and body == {'index.blocks.write': False} and not failed:
                failed.append(True)
                raise Blocked('Injected lost response after first unfence')
            return result
        with patch.object(HTTP, 'request', fail_once), self.assertRaisesRegex(Blocked, 'Injected'):
            self.tool.reopen()
        self.assertEqual(self.journal.state['phase'], 'writes_open')
        with self.assertRaises(Blocked):
            self.tool.rollback()
        self.tool.reopen()
        self.assertEqual(decode(self.tool.control.redis('LINDEX', 'queue:default', 0)), job)
        self.tool.target.request('POST', '/fm-stats-machine/_update/same-id', {'doc': {'ca': 3}})
        with self.assertRaises(Blocked):
            self.tool.rollback()
        self.assertEqual(self.tool.target.request('GET', '/fm-stats-machine/_doc/same-id')['_source']['ca'], 3)
        self.tool.target.request('DELETE', '/fm-stats-project/_doc/same-id')
        self.tool.target.request('PUT', '/fm-stats-machine/_doc/new', {'date': '2026-11-05', '__fm': {'uid': 'machine#new'}})
        self.tool.target.request('POST', '/_refresh')
        self.assertEqual(self.tool.audit_target(), {'new': 1, 'changed': 1, 'deleted': 1})
        self.assertEqual(self.tool.target.request('GET', '/fm-stats-machine/_doc/same-id')['_id'], 'same-id')
        self.tool.control.detach()
        for side in ('source', 'target'):
            self.assertNotIn(self.config['docker']['network'], self.tool.control.inspect(self.config['docker'][side])['NetworkSettings']['Networks'])
        self.tool.clients()
        aliases = self.tool.control.inspect(self.config['docker']['target'])['NetworkSettings']['Networks'][self.config['docker']['network']]['Aliases']
        self.assertIn('elasticsearch', aliases)

    def deploy_producer(self):
        item = self.config['docker']['producers'][0]
        self.tool.control.run('rename', item['name'], item['name'] + '-old-' + self.journal.state['run_id'][:8])
        self.tool.control.run('create', '--name', item['name'], '--network', self.config['docker']['network'],
            '-e', 'ELASTICSEARCH_URL=' + self.config['target']['url'],
            '-e', 'ES_MIGRATION_GUARD=/run/fab-manager-es-migration/guard.json',
            '-v', str(self.journal.root / 'runtime') + ':/run/fab-manager-es-migration:ro',
            item['target_image'], 'sleep', 'infinity')

    def test_10_active_jobs_block_maintenance(self):
        self.seed(); self.tool.inventory()
        self.tool.control.redis('SADD', 'processes', 'synthetic-worker')
        self.tool.control.redis('HSET', 'synthetic-worker', 'busy', '1')
        with self.assertRaisesRegex(Blocked, 'Active Sidekiq'):
            self.tool.maintenance()
        self.assertEqual(self.journal.state['phase'], 'maintenance_start')

    def test_11_unknown_plugin_and_stored_script_block(self):
        self.seed()
        original = HTTP.request
        def plugin(client, method, path, body=None, raw=False):
            result = original(client, method, path, body, raw)
            if client.host == 'legacy-elasticsearch' and path == '/_nodes/plugins':
                next(iter(result['nodes'].values()))['plugins'] = [{'name': 'unreviewed-plugin'}]
            return result
        with patch.object(HTTP, 'request', plugin), self.assertRaisesRegex(Blocked, 'plugins'):
            self.tool.inventory()
        self.tool.source.request('POST', '/_scripts/painless/legacy-script', {'script': 'return 42'})
        with self.assertRaisesRegex(Blocked, 'scripts'):
            self.tool.inventory()
        self.tool.source.request('DELETE', '/_scripts/painless/legacy-script')

    def test_12_canonical_numbers_are_lossless_and_not_rounded_to_28_digits(self):
        value = decode('{"amount":1234.56789012345678901234567890123456789,"id":9007199254740993,"zero":-0.0}')
        self.assertEqual(decode(canonical(value)), value)
        self.assertIn('1234.56789012345678901234567890123456789', canonical(value))
        self.assertEqual(digest({'a': decimal.Decimal('1.00')}), digest({'a': 1}))
        self.assertNotEqual(digest({'a': None}), digest({}))

    def test_13_partial_maintenance_stop_resumes_without_purging_jobs(self):
        self.seed(); self.tool.inventory()
        job = {'class': 'UnknownHistoricalJob', 'jid': 'held', 'queue': 'default', 'args': []}
        self.tool.control.redis('SADD', 'queues', 'default')
        self.tool.control.redis('LPUSH', 'queue:default', canonical(job))
        original = self.tool.control.run
        def stop_then_fail(*args):
            result = original(*args)
            if args[0] == 'stop' and self.config['docker']['sql'] in args:
                raise Blocked('Injected interruption after database stop')
            return result
        with patch.object(self.tool.control, 'run', stop_then_fail), self.assertRaisesRegex(Blocked, 'Injected'):
            self.tool.maintenance()
        self.assertEqual(self.journal.state['phase'], 'maintenance_start')
        self.tool.maintenance()
        self.assertEqual(self.journal.state['pending']['classes'], {'UnknownHistoricalJob': 1})
        self.tool.rollback()
        self.tool.control.run('start', self.config['docker']['redis'])
        self.assertEqual(decode(self.tool.control.redis('LINDEX', 'queue:default', 0)), job)

    def test_14_lost_bulk_acknowledgement_replays_same_identities(self):
        self.frozen_export(); self.tool.initialize()
        original = HTTP.request
        failed = []
        def lose_ack(client, method, path, body=None, raw=False):
            result = original(client, method, path, body, raw)
            if client.host == 'elasticsearch' and path == '/_bulk' and not failed:
                failed.append(True)
                raise Blocked('Injected lost bulk acknowledgement')
            return result
        with patch.object(HTTP, 'request', lose_ack), self.assertRaisesRegex(Blocked, 'Injected'):
            self.tool.import_data()
        self.assertEqual(self.journal.db.execute('SELECT count(*) FROM documents WHERE imported=1').fetchone()[0], 0)
        self.tool.import_data()
        self.assertTrue(self.tool.validation()['ok'])
        self.assertEqual(self.journal.db.execute('SELECT count(*) FROM documents').fetchone()[0], 12)

    def test_15_metadata_drift_and_corrupt_backup_block_cutover(self):
        self.imported()
        backup = Path(self.journal.state['backups']['source']['path'])
        original = backup.read_bytes()
        backup.with_suffix('.original').write_bytes(original)
        backup.write_bytes(original + b'corrupt')
        with self.assertRaisesRegex(Blocked, 'checksum'):
            self.tool.validation()
        backup.write_bytes(original)
        self.tool.source.request('PUT', '/stats/unknown/_mapping', {'properties': {'new': {'type': 'keyword'}}})
        with self.assertRaisesRegex(Blocked, 'mappings changed'):
            self.tool.validation()
        with self.assertRaises(Blocked):
            self.tool.switch()

    def test_16_sql_query_drift_and_oversized_documents_block(self):
        self.seed(); self.tool.inventory()
        sql = self.tool.sql_queries()
        self.assertTrue(sql, 'The live fixture must exercise an actual SQL custom aggregation')
        original_query = sql[0]['query']
        args = ['exec', self.config['docker']['sql'], 'psql', '-XAt', '-U', 'postgres', '-d', self.config['docker']['sql_database'], '-c']
        identity = int(sql[0]['id'])
        self.tool.control.run(*args, "UPDATE statistic_custom_aggregations SET query=query || ' ' WHERE id=" + str(identity))
        try:
            with self.assertRaisesRegex(Blocked, 'SQL custom queries changed'):
                self.tool.maintenance()
        finally:
            self.tool.control.run(*args, "UPDATE statistic_custom_aggregations SET query='" + original_query.replace("'", "''") + "' WHERE id=" + str(identity))
        self.tool.maintenance(); self.tool.backup()
        self.tool.config['document_bytes'] = 128
        with self.assertRaisesRegex(Blocked, 'oversized'):
            self.tool.export()
        with self.assertRaises(Blocked):
            self.tool.switch()

    def test_17_rollback_after_switch_and_deployment_before_writes(self):
        self.imported()
        self.tool.validation(); self.tool.switch()
        original_ids = dict(self.journal.state['original_containers'])
        self.deploy_producer(); self.tool.adopt_producers()
        self.assertNotEqual(self.journal.state['containers'][self.config['docker']['producers'][0]['name']],
                            original_ids[self.config['docker']['producers'][0]['name']])
        self.assertEqual(self.journal.state['original_containers'], original_ids)
        self.assertIn('ELASTICSEARCH_URL=https://elasticsearch:9200', Path(self.config['activation_file']).read_text())
        self.tool.rollback()
        self.assertEqual(self.journal.state['phase'], 'rolled_back')
        self.assertEqual(Path(self.config['activation_file']).read_text(), 'FABMANAGER_IMAGE=es5-reviewed\nELASTICSEARCH_HOST=legacy-elasticsearch\n')
        self.assertEqual(self.tool.source.request('GET', '/stats/machine/same-id')['_source']['ca'], decimal.Decimal('19.95'))
        self.assertFalse(self.tool.control.inspect(self.config['docker']['producers'][0]['name'])['State']['Running'])
        self.tool.source.request('PUT', '/stats/machine/rollback-proof', {'ca': 0, 'date': '2026-11-04'})
        self.assertEqual(self.tool.source.request('GET', '/stats/machine/rollback-proof')['_source']['ca'], 0)
        with self.assertRaises(Blocked):
            self.tool.reopen()


    def test_18_preserves_legacy_float_precision_without_rounding_source(self):
        self.imported(numeric_type='float', availability_hours=decimal.Decimal('2.0000000133333333'))
        for family, spec in self.tool.families.items():
            mapping = self.tool.target.request('GET', '/' + spec['target'] + '/_mapping')[spec['target']]['mappings']['properties']
            fields = ['hours_duration', 'bookable_hours'] if family == 'availabilities' else ['stat', 'ca']
            for field in fields:
                self.assertEqual(mapping[field]['type'], 'float')
        self.assertTrue(self.tool.validation()['ok'])
        source = self.tool.source.request('GET', '/fablab/availabilities/same-id')['_source']
        target = self.tool.target.request('GET', '/fm-availabilities-v1/_doc/same-id')['_source']
        target.pop('__fm')
        self.assertEqual(source, target)
        self.assertEqual(target['hours_duration'], decimal.Decimal('2.0000000133333333'))

    def test_19_incomplete_validation_never_reopens_the_application(self):
        self.imported()
        self.tool.target.request('POST', '/fm-stats-machine-v1/_update/same-id', {'doc': {'ca': 999}})
        with self.assertRaisesRegex(Blocked, 'differ'):
            self.tool.validation()
        for operation in [self.tool.switch, self.tool.reopen]:
            with self.assertRaises(Blocked):
                operation()
        self.assertEqual(self.journal.state['phase'], 'imported')
        guard = decode((self.journal.root / 'runtime/guard.json').read_text())
        self.assertNotEqual(guard['phase'], 'writes_open')
        self.tool.control.stopped()
        self.assertNotIn('ELASTICSEARCH_URL=https', Path(self.config['activation_file']).read_text())


    def test_20_legacy_integer_mapping_preserves_its_indexing_semantics(self):
        self.imported(numeric_type='long')
        self.assertTrue(self.tool.validation()['ok'])
        mapping = self.tool.target.request('GET', '/fm-stats-machine-v1/_mapping')['fm-stats-machine-v1']['mappings']['properties']
        self.assertEqual(mapping['ca']['type'], 'long')
        self.assertEqual(mapping['stat']['type'], 'long')
        value = self.tool.target.request('GET', '/fm-stats-machine-v1/_doc/same-id')['_source']['ca']
        self.assertEqual(value, decimal.Decimal('19.95'))

    def test_21_signed_zero_survives_archive_bulk_and_term_queries(self):
        self.seed()
        for identity, value in [('negative-zero', decimal.Decimal('-0.0')), ('positive-zero', decimal.Decimal('0.0'))]:
            self.tool.source.request('PUT', '/stats/machine/' + identity, {'date': '2019-03-10', 'ca': value, 'stat': 0})
        self.tool.source.request('POST', '/_refresh')
        self.tool.inventory(); self.tool.maintenance(); self.tool.backup(); self.tool.export(); self.tool.initialize(); self.tool.import_data()
        self.assertTrue(self.tool.validation()['ok'])
        value = self.tool.target.request('GET', '/fm-stats-machine-v1/_doc/negative-zero')['_source']['ca']
        self.assertTrue(value.is_signed())
        for client, path in [(self.tool.source, '/stats/machine/_search'), (self.tool.target, '/fm-stats-machine-v1/_search')]:
            response = client.request('POST', path, {'query': {'term': {'ca': decimal.Decimal('-0.0')}}})
            self.assertEqual([hit['_id'] for hit in response['hits']['hits']], ['negative-zero'])
        self.assertNotEqual(digest({'ca': decimal.Decimal('-0.0')}), digest({'ca': decimal.Decimal('0.0')}))

    def test_22_future_availability_schedules_do_not_extend_statistics_protection(self):
        source = self.seed()
        self.tool.source.request('PUT', '/fablab/availabilities/future-slot', {**source, 'date': '2099-01-01', 'available_type': 'machines'})
        self.tool.source.request('PUT', '/stats/machine/latest-history', {**source, 'date': '2021-06-30'})
        self.tool.source.request('POST', '/_refresh')
        self.frozen_export_without_seed()
        expected = max(self.config['protected_through'], '2021-06-30')
        self.assertEqual(self.journal.state['protected_through'], expected)
        self.tool.initialize(); self.tool.import_data()
        self.assertTrue(self.tool.validation()['ok'])
        self.assertEqual(self.tool.target.request('GET', '/fm-availabilities-v1/_doc/future-slot')['_source']['date'], '2099-01-01')

    def frozen_export_without_seed(self):
        self.tool.inventory()
        self.tool.maintenance()
        self.tool.backup()
        self.wait_servers()
        self.tool.export()


if __name__ == '__main__':
    unittest.main(verbosity=2)
