"""ES03 SQL storage and authentication contracts; live class needs an isolated PG18 config."""
import copy
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts/elasticsearch_migration'))
from common import Blocked
from control import Control


def controller(config=None):
    from types import SimpleNamespace
    return Control(SimpleNamespace(config=config or {'docker': {'source': 'test-es5', 'target': 'test-es9',
        'sql': 'test-pg', 'redis': 'test-redis', 'producers': [{'name': 'test-app'}]}, 'snapshot': {'location': '/snapshots'}}))


class SQLStorageTest(unittest.TestCase):
    def storage(self, pgdata, mounts, side='sql'):
        value = controller()
        value.inspect = lambda _: {'Config': {'Env': ['PGDATA=' + pgdata]}, 'Mounts': mounts}
        return value.volume(side)

    def test_legacy_named_storage(self):
        self.assertEqual(self.storage('/var/lib/postgresql/data', [{'Destination': '/var/lib/postgresql/data', 'Type': 'volume', 'Name': 'retained-pg96'}]), 'retained-pg96')

    def test_pg18_named_storage(self):
        self.assertEqual(self.storage('/var/lib/postgresql/18/docker', [{'Destination': '/var/lib/postgresql', 'Type': 'volume', 'Name': 'new-pg18'}]), 'new-pg18')

    def test_pg18_complete_bind_including_space(self):
        self.assertEqual(self.storage('/var/lib/postgresql/18/docker', [{'Destination': '/var/lib/postgresql', 'Type': 'bind', 'Source': '/private/new pg18'}]), '/private/new pg18')

    def test_legacy_complete_bind(self):
        self.assertEqual(self.storage('/var/lib/postgresql/data', [{'Destination': '/var/lib/postgresql/data', 'Type': 'bind', 'Source': '/private/pg96'}]), '/private/pg96')

    def test_unknown_pgdata_requires_explicit_treatment(self):
        with self.assertRaises(Blocked):
            self.storage('/custom/data', [{'Destination': '/custom', 'Type': 'bind', 'Source': '/private/custom'}])

    def test_nested_data_would_not_be_backed_up_completely(self):
        with self.assertRaises(Blocked):
            self.storage('/var/lib/postgresql/18/docker', [
                {'Destination': '/var/lib/postgresql', 'Type': 'volume', 'Name': 'pg18'},
                {'Destination': '/var/lib/postgresql/18/docker/pg_wal', 'Type': 'volume', 'Name': 'wal'}])

    def test_child_only_pg18_mount_is_not_the_supported_layout(self):
        with self.assertRaises(Blocked):
            self.storage('/var/lib/postgresql/18/docker', [{'Destination': '/var/lib/postgresql/18/docker', 'Type': 'volume', 'Name': 'wrong-root'}])

    def test_es_bind_remains_outside_the_supported_adapter(self):
        with self.assertRaises(Blocked):
            self.storage('/var/lib/postgresql/data', [{'Destination': '/usr/share/elasticsearch/data', 'Type': 'bind', 'Source': '/private/es'}], 'source')


class SQLControlLiveTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if os.environ.get('ES_CONTRACT_ISOLATED') != '1':
            raise RuntimeError('Explicit isolated live SQL bench required')
        cls.config = json.loads(Path(os.environ['ES_MIGRATION_PG_CONTROL_CONFIG']).read_text())
        if not cls.config['docker']['sql'].startswith('fm-combined-'):
            raise RuntimeError('Refusing live SQL tests outside the explicitly named disposable bench')

    def test_actual_pg18_bind_and_verified_tls(self):
        value = controller(self.config)
        self.assertEqual(value.volume('sql'), self.config['expected_sql_storage'])
        self.assertEqual(value.sql('SHOW server_version_num').strip(), b'180006')
        self.assertEqual(value.sql('SHOW data_directory').strip(), b'/var/lib/postgresql/18/docker')
        self.assertEqual(value.sql('SELECT ssl FROM pg_stat_ssl WHERE pid=pg_backend_pid()').strip(), b't')

    def test_actual_custom_query_inventory_uses_the_same_authentication(self):
        from transfer import Transfer
        value = Transfer.__new__(Transfer)
        value.control = controller(self.config)
        self.assertGreaterEqual(len(value.sql_queries()), 3)

    def test_wrong_password_is_refused(self):
        config = copy.deepcopy(self.config)
        with tempfile.NamedTemporaryFile(mode='w') as stream:
            stream.write('*:*:*:postgres:wrong-synthetic-password\n'); stream.flush()
            config['docker']['sql_connection']['password_file'] = stream.name
            with self.assertRaises(Blocked):
                controller(config).sql('SELECT 1')

    def test_unapproved_ca_is_refused(self):
        config = copy.deepcopy(self.config)
        config['docker']['sql_connection']['ca_file'] = config['unapproved_ca_file']
        with self.assertRaises(Blocked):
            controller(config).sql('SELECT 1')


if __name__ == '__main__':
    unittest.main(verbosity=2)
