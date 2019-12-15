# Detailed informations about PostgreSQL usage in fab-manager

<a name="run-postgresql-cli"></a>
## Run the PostgreSQL command line interface

You may want to access the psql command line tool to check the content of the database, or to run some maintenance routines.
This can be achieved doing the following:

1. Enter into the PostgreSQL container
   ```bash
   docker exec -it fabmanager-postgres bash
   ```

2. Run the PostgreSQL administration command line interface, logged as the postgres user
   
   ```bash
   su postgres
   psql
   ```
   
## Dumping the database

Use the following commands to dump the PostgreSQL database to an archive file
```bash
cd /apps/fabmanager/
docker-compose exec postgres bash
cd /var/lib/postgresql/data/
pg_dump -U postgres fablab_production > fablab_production_$(date -I).sql
tar cvzf fablab_production_$(date -I).tar.gz fablab_production_$(date -I).sql
```

If you're connected to your server thought SSH, you can download the resulting dump file using the following:
```bash
scp root@remote.server.fab:/apps/fabmanager/postgresql/fabmanager_production_$(date -I).tar.gz .
```

Restore the dump with the following:
```bash
tar xvf fablab_production_$(date -I).tar.gz
sudo cp fablab_production_$(date -I).sql .docker/postgresql/
rake db:drop
rake db:create
docker exec -it fabmanager-postgres bash
cd /var/lib/postgresql/data/
psql -U postgres -d fabmanager_production -f fabmanager_production_$(date -I).sql
```

<a name="postgresql-limitations"></a>
## PostgreSQL Limitations

- While setting up the database, we'll need to activate two PostgreSQL extensions: [unaccent](https://www.postgresql.org/docs/current/static/unaccent.html) and [trigram](https://www.postgresql.org/docs/current/static/pgtrgm.html).
  This can only be achieved if the user, configured in `config/database.yml`, was granted the _SUPERUSER_ role **OR** if these extensions were white-listed.
  So here's your choices, mainly depending on your security requirements:
  - Use the default PostgreSQL super-user (postgres) as the database user. This is the default behavior in fab-manager.
  - Set your user as _SUPERUSER_; run the following command in `psql` (after replacing `username` with you user name):

    ```sql
    ALTER USER username WITH SUPERUSER;
    ```

  - Install and configure the PostgreSQL extension [pgextwlist](https://github.com/dimitri/pgextwlist).
    Please follow the instructions detailed on the extension website to whitelist `unaccent` and `trigram` for the user configured in `config/database.yml`.
- If you intend to contribute to the project code, you will need to run the test suite with `rake test`.
  This also requires your user to have the _SUPERUSER_ role.
  Please see the [known issues](../README.md#known-issues) section for more information about this.


<a name="using-another-dbms"></a>
## Using another DBMS
Some users may want to use another DBMS than PostgreSQL.
This is currently not supported, because of some PostgreSQL specific instructions that cannot be efficiently handled with the ActiveRecord ORM:
 - `app/services/members/list_service.rb@list` is using `ILIKE`, `now()::date` and `OFFSET`.
 - `app/services/invoices_service.rb@list` is using `ILIKE` and `date_trunc()`
 - `db/migrate/20160613093842_create_unaccent_function.rb` is using [unaccent](https://www.postgresql.org/docs/current/static/unaccent.html) and [trigram](https://www.postgresql.org/docs/current/static/pgtrgm.html) modules and defines a PL/pgSQL function (`f_unaccent()`)
 - `app/controllers/api/members_controllers.rb@search` is using `f_unaccent()` (see above) and `regexp_replace()`
 - `db/migrate/20150604131525_add_meta_data_to_notifications.rb` is using [jsonb](https://www.postgresql.org/docs/9.4/static/datatype-json.html), a PostgreSQL 9.4+ datatype.
 - `db/migrate/20160915105234_add_transformation_to_o_auth2_mapping.rb` is using [jsonb](https://www.postgresql.org/docs/9.4/static/datatype-json.html), a PostgreSQL 9.4+ datatype.
 - `db/migrate/20181217103441_migrate_settings_value_to_history_values.rb` is using `SELECT DISTINCT ON`.
 - `db/migrate/20190107111749_protect_accounting_periods.rb` is using `CREATE RULE` and `DROP RULE`.
 - `db/migrate/20190522115230_migrate_user_to_invoicing_profile.rb` is using `CREATE RULE` and `DROP RULE`.
