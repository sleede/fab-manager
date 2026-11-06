"""Offline checks of pure migration rules; no Docker or Elasticsearch required."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts/elasticsearch_migration'))
from transfer import protected_floor


class ProtectedFloorTest(unittest.TestCase):
    def test_statistics_dates_extend_the_protected_history(self):
        self.assertEqual(protected_floor('2026-11-05', 'machine', {'date': '2026-11-04'}), '2026-11-05')
        self.assertEqual(protected_floor('2026-11-05', 'order', {'date': '2026-11-06T10:00:00Z'}), '2026-11-06')

    def test_future_availability_schedules_never_extend_it(self):
        self.assertEqual(protected_floor('2026-11-05', 'availabilities', {'date': '2027-06-30'}), '2026-11-05')
        self.assertEqual(protected_floor('2026-11-05', 'availabilities', {'date': 'not-a-date'}), '2026-11-05')

    def test_missing_or_unreadable_statistics_dates(self):
        self.assertEqual(protected_floor('2026-11-05', 'account', {}), '2026-11-05')
        self.assertEqual(protected_floor('2026-11-05', 'account', {'date': 'not-a-date'}), '9999-12-31')


if __name__ == '__main__':
    unittest.main(verbosity=2)
