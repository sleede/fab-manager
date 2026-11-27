# Detailed information about PostgreSQL usage in Fab-manager

<a name="run-postgresql-cli"></a>
## Run the PostgreSQL command line interface

You may want to access the psql command line tool to check the content of the database, or to run some maintenance routines.
This can be achieved doing the following:

   ```bash
   cd /apps/fabmanager
   docker-compose exec postgres psql -Upostgres
   ```

## Backup and restore with explicit resources

For a server migration use [the verified logical migration](postgresql_migration.md),
which preserves owners/ACL, globals, extensions, large objects and sequences and
verifies a fresh restoration. Never infer the database by grepping a name, drop
the source database, or restore an 18 archive directly into 9.6.

For a separate backup, select the actual container, database, administrator,
TLS hostname, CA and private pgpass file. Use the tested **18.6** client image
even when the connected source is 9.6. A recent libpq does not upgrade pg_dump.

~~~bash
set -euo pipefail
umask 077
# Set all of these to inventoried resources, never production guesses.
: "${PG_CONTAINER:?}" "${PG_DATABASE:?}" "${PG_ADMIN:?}" "${PG_HOST:?}"
: "${PGPASS_FILE:?}" "${PG_CA_FILE:?}" "${BACKUP_DIRECTORY:?}"
mkdir -m 700 "$BACKUP_DIRECTORY"  # refuses an existing directory
client=(docker run --rm --network "container:$PG_CONTAINER"
  --mount "type=bind,src=$PGPASS_FILE,dst=/run/pgpass,readonly"
  --mount "type=bind,src=$PG_CA_FILE,dst=/run/ca.crt,readonly"
  -e PGPASSFILE=/run/pgpass -e PGSSLROOTCERT=/run/ca.crt -e PGSSLMODE=verify-full
  -e PGHOST="$PG_HOST" -e PGHOSTADDR=127.0.0.1 -e PGUSER="$PG_ADMIN"
  postgres:18.6-bookworm@sha256:5c4783a8cc3f0074912164f94dfa1be4e043438f0f707cf968d7af9a0d31a2c8)
"${client[@]}" pg_dump --format=custom --create --quote-all-identifiers   --dbname="$PG_DATABASE" > "$BACKUP_DIRECTORY/database.dump.partial"   2> "$BACKUP_DIRECTORY/dump-diagnostics.txt"
test ! -s "$BACKUP_DIRECTORY/dump-diagnostics.txt" # inspect any warning privately
mv "$BACKUP_DIRECTORY/database.dump.partial" "$BACKUP_DIRECTORY/database.dump"
"${client[@]}" pg_dumpall --globals-only --no-role-passwords   > "$BACKUP_DIRECTORY/globals.sql" 2> "$BACKUP_DIRECTORY/globals-diagnostics.txt"
test ! -s "$BACKUP_DIRECTORY/globals-diagnostics.txt"
sha256sum "$BACKUP_DIRECTORY/database.dump" > "$BACKUP_DIRECTORY/database.sha256"
~~~

A successful backup is not a successful recovery test. Restore with pg_restore
18.6 --exit-on-error into a **new, explicitly selected** database/cluster, inspect
diagnostics, compare data/ACL/business invariants and retain the original.
Do not blindly execute globals.sql: the target already has postgres, login
passwords need rotation and non-default tablespaces need explicit mapping.
The migration tool and its independent-restoration matrix provide that path.
Keep backups, role exports, configuration and credentials outside Git.

<a name="postgresql-limitations"></a>
## PostgreSQL Limitations

- While setting up the database, we'll need to activate two PostgreSQL extensions: [unaccent](https://www.postgresql.org/docs/current/static/unaccent.html) and [trigram](https://www.postgresql.org/docs/current/static/pgtrgm.html).
  This can only be achieved if the user, configured in `config/database.yml`, was granted the _SUPERUSER_ role **OR** if these extensions were white-listed.
  So here's your choices, mainly depending on your security requirements:
  - Use the default PostgreSQL super-user (postgres) as the database user. This is the default behavior in Fab-manager.
  - Set your user as _SUPERUSER_; run the following command in `psql` (after replacing `username` with you user name):

    ```sql
    ALTER USER username WITH SUPERUSER;
    ```

  - Install and configure the PostgreSQL extension [pgextwlist](https://github.com/dimitri/pgextwlist).
    Please follow the instructions detailed on the extension website to whitelist `unaccent` and `trigram` for the user configured in `config/database.yml`.
- If you intend to contribute to the project code, you will need to run the test suite with `scripts/tests.sh`.
  This also requires your user to have the _SUPERUSER_ role.
  Please see the [known issues](known-issues.md) documentation for more information about this.


<a name="using-another-dbms"></a>
## Using another DBMS
Some users may want to use another DBMS than PostgreSQL.
This is currently not supported, because of some PostgreSQL specific instructions that cannot be efficiently handled with the ActiveRecord ORM:
 - `app/services/members/list_service.rb@list` is using `ILIKE`, `now()::date` and `OFFSET`;
 - `app/services/invoices_service.rb@list` is using `ILIKE` and `date_trunc()`;
 - `db/migrate/20160613093842_create_unaccent_function.rb` is using [unaccent](https://www.postgresql.org/docs/current/static/unaccent.html) and [trigram](https://www.postgresql.org/docs/current/static/pgtrgm.html) modules and defines a PL/pgSQL function (`f_unaccent()`);
 - `app/controllers/api/members_controller.rb@search` is using `f_unaccent()` (see above);
 - `db/migrate/20150604131525_add_meta_data_to_notifications.rb` is using [jsonb](https://www.postgresql.org/docs/9.4/static/datatype-json.html), a PostgreSQL 9.4+ datatype;
 - `db/migrate/20160915105234_add_transformation_to_o_auth2_mapping.rb` is using [jsonb](https://www.postgresql.org/docs/9.4/static/datatype-json.html), a PostgreSQL 9.4+ datatype;
 - `db/migrate/20181217103441_migrate_settings_value_to_history_values.rb` is using `SELECT DISTINCT ON`;
 - `db/migrate/20190107111749_protect_accounting_periods.rb` is using `CREATE RULE` and `DROP RULE`;
 - `db/migrate/20190522115230_migrate_user_to_invoicing_profile.rb` is using `CREATE RULE` and `DROP RULE`;
 - `db/migrate/20200511075933_fix_accounting_periods.rb` is using `CREATE RULE` and `DROP RULE`;
 - `app/models/project.rb` is using the `pg_search` gem.
 - `db/migrate/20200622135401_add_pg_search_dmetaphone_support_functions.rb` is using [fuzzystrmatch](http://www.postgresql.org/docs/current/static/fuzzystrmatch.html) module and defines a PL/pgSQL function (`pg_search_dmetaphone()`);
 - `db/migrate/20200623134900_add_search_vector_to_project.rb` is using [tsvector](https://www.postgresql.org/docs/10/datatype-textsearch.html), a PostgreSQL datatype and [GIN  (Generalized Inverted Index)](https://www.postgresql.org/docs/9.1/textsearch-indexes.html) a PostgreSQL index type;
 - `db/migrate/20200623141305_update_search_vector_of_projects.rb` defines a PL/pgSQL function (`fill_search_vector_for_project()`) and create an SQL trigger for this function;
 - `db/migrate/20200629123011_update_pg_trgm.rb` is using [ALTER EXTENSION](https://www.postgresql.org/docs/10/sql-alterextension.html);
 - `db/migrate/20201027101809_create_payment_schedule_items.rb` is using [jsonb](https://www.postgresql.org/docs/9.4/static/datatype-json.html);
 - `db/migrate/20230112151631_add_places_cache_to_slot.rb` is using [jsonb](https://www.postgresql.org/docs/9.4/static/datatype-json.html);
