# PostgreSQL 9.6 to 18.6: logical migration

This is the candidate procedure, based on the PostgreSQL 18 application
compatibility change (pg 1.7.0 and 18.6 client tools). The server-default change is **not
ready for release until the full rehearsal matrix below passes**. A successful
small synthetic migration is not production acceptance.

Use PostgreSQL 18.6-bookworm, pinned to
sha256:5c4783a8cc3f0074912164f94dfa1be4e043438f0f707cf968d7af9a0d31a2c8.
The application image supplies pg 1.7.0 and the separately verified psql, pg_dump and pg_restore
18.6 clients. PostgreSQL 9.6.24 is only an isolated transition source.

## Scope and explicit refusals

scripts/postgresql-migrate.py runs on the Linux Docker host with Python 3.10+
and Docker Compose v2 or later. It uses the local Unix socket. Run as root so it
can create private state and set the tested image's postgres UID 999 on new
storage. No packages are installed by the tool.

The first implementation supports one selected application database in a
Compose-managed 9.6 primary. It refuses other application databases, user
objects in postgres/template1, replication slots, prepared transactions,
custom tablespaces, foreign servers, database-specific role settings,
unclassified services, occupied target paths and ambiguous mounts. External
databases require their administrator's separate connection/storage procedure.
An unknown extension must be added to a reviewed plan and tested first.
No production inventory or production connection is implied.

The old scripts/postgre-upgrade.sh remains a historical **9.4 to 9.6** procedure.
Do not substitute its version numbers. It is not used by this workflow.

## Resource plan and hooks

Copy doc/postgresql_migration_plan.example.json to a private directory outside
the source checkout and edit every resource selection. Confirm the effective
configuration with docker compose config and the actual container mounts with
docker inspect. Never infer a volume name from a project name.

The plan identifies every Compose file, the project, the source service and
container, the mount type/source/destination, actual PGDATA, database,
administrator, application login, target service/container/new absolute path,
pinned image, TLS files and password files. File paths must be canonical.
The target path must not exist. No existing container may use the selected
target Compose project/service, including a stopped container. State and target must have distinct paths.
Source credentials use a private libpq pgpass file (0600), never an argument or
connection URI. Target TLS must verify the target service name.

Four executable argv hooks are required; no shell interpolation is performed:

| Hook | Contract |
| --- | --- |
| health_command | Read-only real application/services check; output one JSON object with healthy=true only on success. |
| quiet_command | Quiet Sidekiq processes/schedulers and other declared producers; output JSON, fail if any cannot be quieted. |
| queue_command | Read-only JSON: busy, queued, scheduled, retry, dead, sha256. Hash pending job payloads/order without logging their arguments. |
| business_command | Read-only SQL/Rails checks; output deterministic JSON. Raise on any invalid accounting footprint or business invariant. |

Hooks receive FM_PG_ENDPOINT (JSON containing container, hostname, user,
password-file path, sslmode, CA path), FM_PG_DATABASE and FM_PG_PHASE.
The endpoint never embeds a password. Use the pinned client image on the
selected container network namespace, or the reviewed application image with
PGPASSFILE, PGHOSTADDR=127.0.0.1 and TLS verify-full. SQL must run read-only.
Do not connect a normal worker or scheduler to the target before validation.

scripts/postgresql_queues.rb provides the real Sidekiq quiet/inventory logic.
Run it in the reviewed application environment with FM_PG_QUEUE_ACTION=quiet
for the quiet hook; omit that variable for inventory. The application must
remain available as a one-off read-only runner after its producer container
stops. Do not use FLUSHDB/FLUSHALL or discard pending/scheduled/retry/dead jobs.

scripts/postgresql_business_check.rb checks all six accounting models using
the deterministic latest chained element, and inventories duplicate chained_elements.
Run it using the same code before and after restoration. Extend the hook with
the site's project search, invoice/reservation/calendar queries and additional
data families. It must not regenerate chains to manufacture success.

The repository does not ship the four hook executables: each site wires these
helpers to its own containers and producers. The executable synthetic test has its own real SQL checks, active writer and
Redis queue; it does not claim to execute these Rails helpers.

## Phases

Use the same immutable plan for every command:

~~~sh
sudo python3 scripts/postgresql-migrate.py --plan /private/migration/plan.json preflight
sudo python3 scripts/postgresql-migrate.py --plan /private/migration/plan.json prepare
sudo python3 scripts/postgresql-migrate.py --plan /private/migration/plan.json maintenance
sudo python3 scripts/postgresql-migrate.py --plan /private/migration/plan.json export
sudo python3 scripts/postgresql-migrate.py --plan /private/migration/plan.json restore
sudo python3 scripts/postgresql-migrate.py --plan /private/migration/plan.json validate
~~~

preflight only reads source/application state and starts ephemeral client
processes. It does not create state, mutate the database or initialize storage.
It compares the connected server and PG_VERSION, actual mount, TLS, client
versions, roles, extensions and space. It checks, as the target image's UID 999,
that the target certificate and key are readable, so that a target which cannot
start is refused before the source is fenced. With application_service set, it
also refuses an application image that cannot read POSTGRES_PASSWORD_FILE. Free-space budgeting retains the source
and reserves five times the larger of source-directory/database size plus
1 GiB for dump, target, indexes/WAL and margin on each destination filesystem.
Also check the physical backing disk when using WSL, thin provisioning or quotas.

prepare repeats preflight, saves original files and the fully resolved Compose
configuration privately, creates generated credentials and an atomic journal.
The journal has no passwords; resolved configuration backups are confidential.
Its plan hash prevents changing resources halfway through a run.

maintenance quiets producers, waits for active jobs, inventories queues, and
stops only declared producer services. It creates a random temporary source
administrator and replaces the backed-up HBA with a fence allowing only that
account over loopback with password authentication. Other TCP/Unix connections,
including ordinary superusers, are rejected; existing sessions are terminated.
Host cron, external schedulers and external producers must be explicitly
identified/stopped in the plan. Sidekiq-scheduler runs with the worker. A failure
leaves producers stopped/quiet for inspection; it does not resume them implicitly.

export writes a custom archive using pg_dump 18.6 with --create and
--quote-all-identifiers. It saves pg_dumpall --globals-only --no-role-passwords,
verifies exit codes, treats diagnostics as failure, records the archive SHA256
and compares the fenced source before/after. Large objects are included.
The archive is streamed when restored. Never execute globals.sql blindly.

restore creates only the selected new target. PG18 mounts /var/lib/postgresql;
PGDATA is /var/lib/postgresql/18/docker. The target keeps the source memory
limit (none by default); set target.memory_limit in the plan to choose another
one. It creates source roles from inspected
attributes/memberships, alters the existing postgres role instead of recreating
it, rotates all login passwords, and preserves owners/ACL. Provide private
rotated secrets for every other login role. Source privileged roles require
explicit approval in the plan. The temporary source fence role is not restored.

The application role retains its existing privileges. If it was postgres, it
remains a superuser; this procedure does not claim a least-privilege redesign.
A separate application role must already have the necessary grants. The
migration administrator needs superuser privileges for all owners, roles,
extensions and large objects; keep its secret out of the normal application.
Later DDL migrations may require a separately selected privileged runner.

pg_restore uses --exit-on-error --create. A cross-database CREATE DATABASE cannot
be wrapped in one transaction, so any failure marks the target incomplete.
No automatic deletion or second import occurs. Extensions are explicitly
updated to the versions supplied by the tested target, then ANALYZE runs.

validate compares complete table row digests, counts, primary-key definitions and
canonical key-set digests (including composite keys), sequences, columns,
indexes, functions, constraints, rules, triggers, database encoding/collation,
owners/ACL and large objects. Raw snapshots are retained. Surviving column
ordinals are ranked within each table because logical restore compacts physical
slots left by dropped columns. Column names, logical order, types, defaults and
nullability remain checked. Unordered catalog result lists are sorted for
comparison across libc versions; ordered properties and table contents are not
ignored. A failed read-only validation can be rerun and keeps its earlier target
snapshot; it never authorizes resuming writes. PostgreSQL 18 stores
NOT NULL in pg_constraint; column nullability is compared separately and
unvalidated NOT NULL is rejected. The new MAINTAIN privilege is equivalent only
for an owner's own implicit privilege; an additional grant to another role
remains a blocker. No blanket ACL or constraint exclusion is used.

Logical restoration rebuilds indexes with the target collation provider.
Record source/target libc versions, review the locale change and compare
accented ordering, uniqueness and business queries. Invalid indexes and actual
collation-version mismatches block validation. The tool never hides a mismatch
with ALTER ... REFRESH COLLATION VERSION. Full collation qualification on the
real anonymized dataset remains mandatory.

## Cutover and rollback

~~~sh
sudo python3 scripts/postgresql-migrate.py --plan /private/migration/plan.json cutover
# Review the generated activation file; use it for ALL later Compose/upgrade commands.
. /private/migration/state/activate.sh
sudo python3 scripts/postgresql-migrate.py --plan /private/migration/plan.json resume
~~~

cutover requires validation and unchanged queues. It stops the source while
keeping its storage and configuration. The generated complete Compose JSON
preserves the resolved service configuration; it adds a separate target,
changes producer database connection settings and places the preserved source
behind an explicit profile. Original Compose files are never rewritten.
Review any database-service-specific tuning or custom mounts before accepting
the target configuration. Store the activation choice in the installation's
service manager; a shell-local variable alone does not change systemd.

resume refuses unless rehearsal_approved was explicitly true in the immutable
plan. Set it only after the rehearsal matrix below is accepted for this site;
the synthetic plan keeps it false.
The journal records writes_resumed BEFORE starting the first producer.

Before that boundary, rollback restores the original source HBA/configuration
and removes the temporary fence role; it leaves producers stopped for an
explicit restart with the original Compose files. The saved source.compose.json pins each application producer to its inspected local image ID; use it for the rollback restart. Only producers running before maintenance are eligible for automatic resume. It retains the target and
all dumps. Confirm the PostgreSQL 18 compatible application is used for either server.

After writes may have resumed, automated rollback is forbidden. Stop writers,
retain both clusters, export the target's new data and reconcile/replay its
delta with a separately tested procedure. Switching a tag or remounting the
9.6 directory is not a lossless rollback. An 18 archive is not certified for
restoration into 9.6.

## Interrupted runs

status prints the checkpoint without secrets. A lock serializes phases and a
persisted operation field identifies interruption. A completed phase can
continue at its next phase. Repeating restore is refused even if it failed.

recover-maintenance restores the saved HBA after an interrupted fence and removes
the temporary role; inspect producer quiet state before retrying.
recover-export preserves any incomplete dump/globals under unique names and
returns to maintenance for a fresh export. It never overwrites the previous dump.
For a partial target: retain it, rollback the still-fenced source, inspect the
failure and create a new plan/state/target with distinct names. The tool never
deletes an existing source, target or backup. In tests, only explicitly identified
disposable resources created by that test may be recreated.

## Installation and general upgrade

The candidate setup/development Compose uses the pinned 18.6 server, private
networking, SCRAM, a password file and the PG18 mount. The startup guard rejects
a 9.6 PG_VERSION and a missing database after initialization. An initialization
sentinel lives outside PGDATA; a restart cannot silently replace missing data.

setup/setup.sh keeps its documented `curl -sSL setup.fab.mn | bash` usage: it
downloads the Compose template and the PostgreSQL startup guard like its other
files, and uses the local copies when it runs from a checkout. It refuses occupied
installation directories, generates a private local password and enables
initialization only for the fresh setup. It stops on failed db:create/migrate/
seed. Existing installations must use the migration, not copy the new template
over their customized Compose files. Development must prepare the same private
password/guard files and explicitly initialize fresh storage; never point the
new template at existing 9.6 data.

setup/upgrade.sh calls the read-only PostgreSQL guard before target changes,
pulls, preprocessing or migrations. When the script is piped from GitHub, it
downloads the guard from the same branch. The guard refuses only positive evidence
of an unsafe PostgreSQL 18 state (PG_VERSION or storage mismatch, missing or empty
application database, stopped server, newer major version, published port, trust
authentication); -y and -i do not bypass it. A 9.6 server, an external database
or a configuration it cannot inspect (no Python 3, no Compose v2) gets a notice:
the application upgrade recreates the application service only and leaves the
database unchanged. Use COMPOSE_FILE from the accepted migration configuration.

## Order of operations for an existing installation

1. Upgrade the application while still on 9.6. It supports both servers, and
   the migrated configuration passes the database secret only through
   POSTGRES_PASSWORD_FILE: with application_service set in the plan, preflight
   refuses an application image that cannot read it.
2. Run the migration phases above on a rehearsed plan, then cutover and resume.
3. The state directory is now part of the live configuration: the generated
   Compose JSON mounts its entry point, guard, administrator and runtime secrets.
   Never delete, move or prune it; back it up privately with the installation.
   Its files are root-only, so run later Compose and upgrade commands as root
   after sourcing activate.sh.
4. The generated JSON pins application services to their inspected image IDs for
   rollback. Select the next release explicitly with upgrade.sh -t <version>.

## Reproducible first test and required rehearsal matrix

~~~sh
python3 test/postgresql/migration_test.py -v
sudo python3 test/postgresql/migration_test.py --integration \
  --root /opt/fab-manager-pr-pg-b/a-new-unique-rehearsal
~~~

The root must be new. The test creates its own internal network, 9.6 source,
Redis, writer and 18 target; no published ports or external application calls.
It uses synthetic exact numerics/bigint, JSON/JSONB, bytea, dates/DST, extensions,
search/indexes, owners/ACL, a large object, accounting rules, duplicate chains
and a sequence with is_called=false. It keeps every resource and proof.
Stop only its identified containers when finished; never prune unrelated data.

Before the server-default change can be accepted, execute and record:

| Check | Required evidence |
| --- | --- |
| Final application with the migration changes | Frozen dependencies, final image clients, Rails boot/health and complete Rails suite with correct MAX_IMAGE_SIZE; baseline failures separated. |
| Real Fab-manager synthetic seeds/data | Authentication, project search, reservations/calendar, invoices/period closure, all six footprint models, JSONB caches, exact money and all sequences before/after. |
| Independent second restore | Same archive into another fresh target, all fingerprints/business checks, no source mutation. |
| Lifecycle | Restart/recreate only the disposable target container; data and guard persist; missing data refuses initialization. |
| Failure injection | Low disk, wrong mount/PG_VERSION, occupied target, unknown extension/roles/databases, invalid TLS/password, altered plan/config, failed dump, warning, interrupted restore/maintenance, simultaneous phase. |
| Queues/producers | Real Rails/Sidekiq/sidekiq-scheduler plus external producers; active job drains; pending/retry/dead/scheduled payload/order preserved. |
| Collations and access | Provider versions, accented ordering and unique indexes, every extra schema/extension/ACL/default privilege, non-superuser runtime and privileged DDL runner. |
| Cutover/rollback | Before-write rollback with real application; after-write delta capture/reconciliation; refused naive rollback. |
| Installer/upgrader | Actual local artefacts and piped execution: fresh install/seeds, existing 9.6 upgrade with notice, unsafe PG18 state refused even -y/-i, already-modernized and external cases, unchanged custom services. |
| Platform/storage | Linux/WSL resources, supported architectures as applicable, physical free space, secret permissions; source/dumps retained. |

## Official references

- [PostgreSQL 18.6 release](https://www.postgresql.org/docs/release/18.6/)
- [pg_dump compatibility and warnings](https://www.postgresql.org/docs/18/app-pgdump.html)
- [pg_restore](https://www.postgresql.org/docs/18/app-pgrestore.html)
- [Official image and PG18 storage](https://hub.docker.com/_/postgres)
- [PostgreSQL 18 NOT NULL catalog change](https://www.postgresql.org/docs/18/release-18.html)
- [Privileges including MAINTAIN](https://www.postgresql.org/docs/18/ddl-priv.html)

The upgrade entry point selects one effective COMPOSE_FILE, including the generated
migration JSON, for all subsequent reads and edits. Asset compilation uses a
Compose one-off runner to inherit the accepted network, TLS and secret mounts.
Multiple active files and the legacy -e flag on resolved JSON are refused;
review changes directly in the selected configuration. Use FM_POSTGRES_SERVICE
and FM_POSTGRES_DB for an explicitly renamed service/database. Select the main
application with application_service in the plan, or FM_APP_SERVICE for a direct
upgrade. activate.sh exports these values together with COMPOSE_FILE and
COMPOSE_PROJECT_NAME. When the application host differs from the selected local
server, or with DATABASE_URL, that database is not inspected: the guard prints a
notice and the upgrade leaves it unchanged. Image IDs in
resolved JSON are read as raw strings and inspected locally, without a registry
pull. To preserve rollback images, always pass --no-image-cleanup to upgrade.sh. The gate also
checks that the expected users/schema_migrations data exists.

Additional behavioral checks after the synthetic rehearsal:

~~~sh
sudo python3 test/postgresql/upgrade_guard_test.py \
  --root /opt/fab-manager-pr-pg-b/a-new-unique-rehearsal
bundle exec ruby test/postgresql/database_configuration_test.rb
~~~

The guard test creates a separate, uniquely named synthetic database in its
own target cluster; it retains that database and leaves the migrated database
unchanged. It does not exercise the complete installer or a real Rails upgrade.

## Fresh installation, secrets and TLS

The new template mounts the PG18 parent directory, not the old 9.6 PGDATA.
The guarded entry point refuses a legacy directory, a missing initialized
directory, or an unapproved empty directory. Fresh setup alone sets
FM_PG_INITIALIZE=1; later starts default to 0. Never enable it to bypass a lost
volume. Existing installations keep their 9.6 service until the explicit
migration; never copy this template over them.

prepare_postgresql creates the password, a private local CA, and a server
certificate for postgres/fabmanager-postgres/localhost outside Git. The CA key
stays on the host; only its public certificate is mounted into the application.
The server key is 0600 and owned by the tested image's UID 999. The config
directory is 0700; do not copy those files into a public directory. Connections
use SCRAM plus sslmode=verify-full, which rejects an expired certificate. The
server certificate is valid ten years, like the private CA, and nothing renews
it automatically: renew it with the retained CA before expiry and test the
renewed chain. Custom DNS/service
names require matching reviewed SANs. The example development Compose needs
the same private certificate/password preparation; it never publishes SQL ports.

## Rehearsal recorded on 2026-11-03

One application revision, based on the PostgreSQL 18 compatibility commit
2c1fc2dab1848b5a52a0172be13ce7f491518482, ran against 9.6.24 and 18.6 on
Linux x86_64/WSL2.
The release image delivered pg 1.7.0, libpq 180006 and psql/pg_dump/pg_restore
18.6. Ruby/Rails, Redis and Elasticsearch were kept at their existing versions.

The synthetic Rails workload used seeds and real application APIs: 21 users,
profiles/groups, 30 accented projects, training reservations around the two
2026-11-01 America/Toronto DST instants, a subscription, a shop order and five
financial documents including a credit note. It checked all six accounting
footprints without regenerating historical chains, generated/read PDFs and a
CSV accounting export, and ran an actual Redis/Sidekiq database job.
The exact invoice total sum was 23,884 cents (raw document sum, not net balance).

Both full migrations, the independent restore and before-write rollback passed.
A second cutover ran new member/reservation/subscription/order/refund/cancellation
writes and a real worker on 18.6. The tool then refused rollback because a delta
existed. Fifteen failure/recovery scenarios checked interrupted/corrupt dumps,
real restore errors, partial/nonempty targets, low space, wrong source version,
validation failure and source/archive preservation. Source/dump/target paths
included spaces. All sequences were advanced only on an independent disposable
copy and their next generated values were checked against owned-column keys.

The full Rails command was the repository's actual entry point:

~~~sh
# In an isolated reviewed application environment, with synthetic credentials,
# test mail/payment adapters and initialized private Redis/Elasticsearch:
RAILS_ENV=test bundle exec rails db:create
RAILS_ENV=test bundle exec rails db:schema:load
RAILS_ENV=test bundle exec rails db:fixtures:load
RAILS_ENV=test bundle exec rails fablab:es:build_stats
# Initialize/reindex Availability through its existing indexer before the suite.
bundle exec bash scripts/tests.sh --seed 12345
~~~

Both servers produced 717 tests, 9,480 assertions, zero failures, one error and
zero skips. The error is the pre-existing SsoLoggerTest NameError for
OmniAuth::Strategies::SsoOauth2Provider, which also occurs on master.
This is a failing full-suite result, not a green CI result. Six configuration
tests subsequently passed with 24 assertions; they include the test database
selection, which never follows POSTGRES_DB.

The collation probe intentionally retained a real difference: en_US.UTF-8 with
source glibc 2.24 sorts "côte" before "coté", while target glibc 2.36 reverses
them. A logical restore rebuilt indexes and passed key/uniqueness/search checks;
this does not prove identical ordering for every real dataset. Review sorting
and uniqueness on an authorized representative copy before production cutover.

The before-write check expects the original 20 synthetic members and one credit
note; check_after_writes expects exactly 21 synthetic members and two credit
notes. It preserves strict baseline checks rather than accepting arbitrary
extra records. PaymentSchedule families and large objects are empty in this
Rails dataset; their populated historical transfer is not proved by this run.

The reusable test helpers are test/postgresql/migration_workload.rb,
migration_probe_worker.rb and migration_failure_matrix.py. The workload refuses
databases outside the fm_pg_b_ synthetic prefix. Load the probe worker explicitly
in the disposable Sidekiq process and select only its migration_probe queue.
FM_MIGRATION_ACTION selects provision, finish_provision, check, check_after_writes or journeys:

~~~sh
# After db:create/db:migrate/db:seed, with synthetic admin credentials:
FM_MIGRATION_ACTION=provision bundle exec rails runner test/postgresql/migration_workload.rb
FM_MIGRATION_ACTION=check bundle exec rails runner test/postgresql/migration_workload.rb
# Only after the separate new-write cutover test:
FM_MIGRATION_ACTION=journeys bundle exec rails runner test/postgresql/migration_workload.rb
FM_MIGRATION_ACTION=check_after_writes bundle exec rails runner test/postgresql/migration_workload.rb
~~~

Run the failure matrix only with its documented synthetic plan/output guards;
it must never be pointed at an administrator's production migration state.
External producers, site-specific plugins, a representative production-size
copy, non-x86_64 execution and hosted CI remain separate acceptance work.
Measure dump, restore, validation, total write interruption and physical storage
on that copy. Synthetic timings cannot guarantee production downtime.

## Installer and optimized asset verification

The isolated fresh installation used the actual setup preparation and
db:create/db:migrate/db:seed commands, followed by the production
assets:precompile command. PostgreSQL restarted successfully with initialization
disabled. Puma and Sidekiq started with the seeded administrator and verified
SQL TLS. A private HTTPS proxy with a verified CA exercised production secure
cookies: health 200, valid login 201, wrong password 401 and missing CSRF 422.

Initial asset builds were killed by the memory cgroup, confirmed by kernel
diagnostics. Stopping only this rehearsal's completed services and reserving
3 GiB / one CPU for the unchanged production build produced a successful
optimized compilation. This resource measurement is specific to the test host;
it is not an installation sizing guarantee. No minification, version, TLS,
authentication or test check was disabled.

The upgrader now aborts with exit 4 when asset compilation fails, even with -y,
before stopping the application or replacing its existing packs. The regression
test in migration_test.py exercises this failure against the real shell function.
Use --no-image-cleanup to preserve rollback images. The full Rails suite still
has the baseline OAuth NameError described above; it is not a passing global CI.
