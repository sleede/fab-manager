#!/usr/bin/env python3
"""Explicit offline Elasticsearch migration steps. Run on the Docker host, never in a web request."""
import argparse
import sys
import sqlite3
from pathlib import Path
from common import Blocked, Ledger, canonical, decode
from transfer import Transfer


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', required=True)
    parser.add_argument('--journal', required=True)
    parser.add_argument('step', choices=['inventory', 'maintenance', 'backup', 'export', 'initialize', 'import', 'validate', 'switch', 'adopt-producers', 'adopt-target', 'reopen', 'rollback', 'audit-target', 'detach', 'status'])
    args = parser.parse_args()
    journal = Ledger(args.journal, decode(Path(args.config).read_text()))
    try:
        tool = Transfer(journal)
        if args.step == 'status':
            print(canonical(journal.state))
            return 0
        if args.step == 'detach':
            journal.require('switched', 'rolled_back', 'writes_open')
            tool.control.detach()
        else:
            method = {'import': 'import_data', 'validate': 'validation'}.get(args.step, args.step.replace('-', '_'))
            getattr(tool, method)()
        journal.event('step_complete', step=args.step)
        print(canonical({'step': args.step, 'phase': journal.state['phase'], 'ok': True}))
        return 0
    except (Blocked, OSError, KeyError, ValueError, sqlite3.Error) as error:
        journal.event('step_blocked', step=args.step, reason=str(error))
        print(canonical({'step': args.step, 'phase': journal.state['phase'], 'ok': False, 'reason': str(error)}), file=sys.stderr)
        return 2
    finally:
        journal.close()


if __name__ == '__main__':
    sys.exit(main())
