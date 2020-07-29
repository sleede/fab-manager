# Test fixtures

Fixtures are test data.
Every time a new test is run, the database is filled with these data.

You can create fixtures manually or using the following task, to dump your current table/database to the YAML fixture files:
```bash
rails db:to_fixtures[table]
```
The parameter `table` is optional. If not specified, the whole database will be dumped.