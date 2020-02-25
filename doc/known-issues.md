# Known issues

This document is listing common known issues. 

> Production issues may also apply to development environments.

##### Table of contents

1. [Development](#development)
2. [Production](#production)

<a name="development"></a>
## Development

- When starting the Ruby on Rails server (eg. `foreman s`) you may receive the following error:

        worker.1 | invalid url: redis::6379
        web.1    | Exiting
        worker.1 | ...lib/redis/client.rb...:in `_parse_options'

  This may happen when the `application.yml` file is missing.
  To solve this issue copy `config/application.yml.default` to `config/application.yml`.
  This is required before the first start.

- When running the tests suite with `rake test`, all tests may fail with errors similar to the following:

        Error:
        ...
        ActiveRecord::InvalidForeignKey: PG::ForeignKeyViolation: ERROR:  insert or update on table "..." violates foreign key constraint "fk_rails_..."
        DETAIL:  Key (group_id)=(1) is not present in table "...".
        : ...
            test_after_commit (1.0.0) lib/test_after_commit/database_statements.rb:11:in `block in transaction'
            test_after_commit (1.0.0) lib/test_after_commit/database_statements.rb:5:in `transaction'

  This is due to an ActiveRecord behavior witch disable referential integrity in PostgreSQL to load the fixtures.
  PostgreSQL will prevent any users to disable referential integrity on the fly if they doesn't have the `SUPERUSER` role.
  To fix that, logon as the `postgres` user and run the PostgreSQL shell (see [the dedicated section](#run-postgresql-cli) for instructions).
  Then, run the following command (replace `sleede` with your test database user, as specified in your database.yml):

        ALTER ROLE sleede WITH SUPERUSER;

  DO NOT do this in a production environment, unless you know what you're doing: this could lead to a serious security issue.

<a name="production"></a>
## Production

- Due to a stripe limitation, you won't be able to create plans longer than one year.

- With Ubuntu 16.04, ElasticSearch may refuse to start even after having configured the service with systemd.
  To solve this issue, you may have to set `START_DAEMON` to `true` in `/etc/default/elasticsearch`.
  Then reload ElasticSearch with:

  ```bash
  sudo systemctl restart elasticsearch.service
  ```
  
- In some cases, the invoices won't be generated. This can be due to the image included in the invoice header not being supported.
  To fix this issue, change the image in the administrator interface (manage the invoices / invoices settings).
  See [this thread](https://forum.fab-manager.com/t/resolu-erreur-generation-facture/428) for more info.
  
- In the excel exports, if the cells expected to contain dates are showing strange numbers, check that you have correctly configured the [EXCEL_DATE_FORMAT](environment.md#EXCEL_DATE_FORMAT) variable.
