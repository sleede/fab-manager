# PostgreSQL application compatibility

The transition target is PostgreSQL **18.6**; PostgreSQL **9.6.24** remains a
compatibility test case. The pg maintainer documents PostgreSQL 10 and later;
9.6 is an explicitly tested transition case outside that supported range, not
a renewed upstream support commitment. The normal setup server, storage, network and exposure
remain unchanged in this application prerequisite. Enabling the new server and
migrating user data are separate changes.

## Driver and command-line tools

The Ruby driver is pinned to **pg 1.7.0**, built from source against the system
libpq. Its published changes include PostgreSQL 18 protocol support and fixes to
encoding, parameter handling and result lifetimes. Ruby 3.2.2 and Rails 7.0.8.7
are retained. Only pg is updated in Gemfile.lock; there is no global update.

The Debian bookworm image installs these exact PGDG packages:

- postgresql-client-18=18.6-1.pgdg12+2
- libpq5=18.6-1.pgdg12+2
- libpq-dev=18.6-1.pgdg12+2

The package preference also covers the later apt upgrade already in the
Dockerfile. PATH selects /usr/lib/postgresql/18/bin. Check the actual binaries
as well as the library; a recent libpq does not update an old pg_dump:

```sh
bundle exec ruby -rpg -e 'puts "pg=#{PG::VERSION}; libpq=#{PG.library_version}"'
psql --version
pg_dump --version
pg_restore --version
```

An older pg_dump cannot dump a PostgreSQL 18 server. The existing Rails structure
adapter filters the known transaction_timeout SET statement for older servers;
it is retained. SQL schema replay uses the delivered psql. Archives are tested
with the delivered pg_restore into 18, not certified as backward-compatible
restores into 9.6. This is not an automatic data migration or rollback tool.

## Optional password configuration

config/database.yml.default accepts POSTGRES_HOST, POSTGRES_USERNAME and
POSTGRES_PASSWORD. Missing host/user use their historical values; an unset or
empty password retains the historical development value. docker/database.yml
already reads these variables for deployed installations.

Setting a client variable does not change the database role or pg_hba.conf.
Existing installations are not switched to password authentication by this change.
Prepare a matching role password before a later authentication/server cutover.
The isolated 9.6 test uses MD5 and the target uses SCRAM; libpq handles both.
The older method is a temporary compatibility check, not a new production default.

PGSSLMODE=verify-full and PGSSLROOTCERT can configure libpq TLS verification.
Do not disable certificate/hostname verification to make a test pass. Never store
credentials in Git or connection URLs. Keep PostgreSQL private to its network.

## Verification

See [the isolated matrix](../docker/postgresql-compatibility/README.md). Run the
same seeded scenarios against both servers: actual password authentication and
parameter binding, extensions and project search, JSON/JSONB, exact numerics,
bytea and date/time values, indexes/sequences, Rails schema replay, and the
reservation/invoice endpoints. The standalone test does not load unrelated
historical accounting fixtures or alter their checksums.

Exercise the real installation route (db:create, db:migrate, db:seed), and also
schema loading into a separate empty test database. Keep before/after failures,
commands, versions/digests and source fingerprints. A written test is not evidence
that it passed. Full-suite baseline failures must remain visible.

Sources: [pg changelog](https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md),
[PostgreSQL 18.6](https://www.postgresql.org/docs/release/18.6/),
[pg_dump compatibility](https://www.postgresql.org/docs/18/app-pgdump.html).
