# Isolated PostgreSQL compatibility matrix

This file is for tests, not normal setup or production. It starts PostgreSQL
9.6.24 and 18.6 with different named volumes, plus the existing Redis/Elasticsearch
families needed to boot this application. No service publishes a host port and
the network is internal. Old unsupported servers are used only for this rehearsal.
Never attach an existing volume or a production backup.

## Provision a new test project

Use a Linux/WSL shell with root access for UID 999 ownership and Docker. Choose a
new private directory outside this repository and a unique Compose project name:

```sh
bash docker/postgresql-compatibility/prepare.sh /opt/fm-pg-compat-NEW/private
export PG_COMPAT_PRIVATE_DIR=/opt/fm-pg-compat-NEW/private
docker compose -p fm-pg-compat-NEW -f docker/postgresql-compatibility/compose.yml config
docker compose -p fm-pg-compat-NEW -f docker/postgresql-compatibility/compose.yml up -d
```

The provisioner refuses existing material. Keep the CA key and password outside
Git. PostgreSQL uses TLS; host authentication is MD5 for 9.6 and SCRAM for 18.
Local Unix-socket trust is limited to administration inside these test containers.
The named volumes and project labels identify which resources belong to the test.
Do not use a global Compose down/volume deletion against another project.

## Application test runtime

Build the application from the code under review. Use a separate disposable gem
volume and install the test/development groups with Bundler 2.4.3 and frozen
Gemfile.lock. Never mount a developer's credential files into the test runtime.
The normal Dockerfile installs production gems, so it alone is not a test image.

On a private Linux source copy, copy config/database.yml.default to
config/database.yml and change only its test database name to a new fm_pg_a_*
name. This explicit prefix protects the standalone test runner. Set POSTGRES_HOST
to pg96 or pg18, POSTGRES_USERNAME=postgres and POSTGRES_PASSWORD to the provisioned
password. Use PGSSLMODE=verify-full and PGSSLROOTCERT pointing to the mounted public
CA. Make the same code/scenario run against both services on the test network.

Use a private environment file, not credentials in command-line URLs. Set
RAILS_ENV=test, RACK_ENV=test, REDIS_HOST=redis, ELASTICSEARCH_HOST=elasticsearch,
POSTGRESQL_LANGUAGE_ANALYZER=french, TIME_ZONE=America/Toronto, WEEK_STARTING_DAY=monday,
ADMIN_EMAIL to an example.test address and ADMIN_PASSWORD to a newly generated
strong test password. The password policy requires at least 12 characters and
upper/lowercase, digits and a special character; do not relax it. Mail stays on
the test adapter and Sidekiq jobs are fake. Keep the runtime on the internal
network so payment/SMTP/IdP/Openlab calls cannot leave it.

Inside that runtime, run the actual installation route in an empty database:

```sh
bundle _2.4.3_ exec rails db:create
SCHEMA=/private/new-structure.sql bundle _2.4.3_ exec rails db:migrate
bundle _2.4.3_ exec rails db:seed
bundle _2.4.3_ exec ruby test/postgresql/compatibility.rb --seed 12345
```

Repeat with a separate empty database using db:schema:load then db:seed. Keep
SCHEMA dump outputs outside the source so the compared inputs remain unchanged.
The standalone scenarios use fresh seeds, not the unrelated historical invoice
fixtures. They execute SQL types, real extensions/project search, password/TLS,
schema replay, custom archive dump/restore into 18, and local reservation/invoice
endpoints with checksum and JSONB-cache assertions. Temporary replay databases
are uniquely named, created by the test and removed only by that same test.

For the existing suite, use a separate fixture database and the real entry point:

```sh
bash scripts/tests.sh --seed 12345
```

Record before/after on 9.6 and 18, versions/digests, source fingerprint, commands,
durations and every failure. Do not call the whole suite green if a subset passes.
SQL restore compatibility with 9.6 does not certify downgrading arbitrary 18 data
or restoring 18 archives into 9.6. Server cutover/data migration are later work.
