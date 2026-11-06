# ES02 / ES03 / ES04 operator runbook

The target is official Elasticsearch **9.5.6**, with official Ruby client **9.5.0**
and `elastic-transport` **8.5.3**, Ruby 3.2.2 and Rails 7.0.8.7. Faraday 0.17.3,
OAuth2/OpenLab and PostgreSQL remain unchanged. The old model/persistence/rails/
transport integrations are removed. Read the [application contract](elasticsearch_boundary.md)
and [historical transfer procedure](../scripts/elasticsearch_migration/README.md).

ES02 contains the application boundary/client/schema/browser gateway; ES03 contains
inventory, copy, comparison, journals and the Rails/Sidekiq migration guard; ES04
contains deployment, scoped credentials, setup/upgrade and the real rehearsal.
These are identifiable review lots within one uncommitted PR, not three releases.

## Supported deployment and security

Use the [standalone Compose example](../docker/elasticsearch9/README.md) or the
reviewed `setup/docker-compose.yml`. Local mode is **single-node**, with a new named
data volume, new snapshot repository, internal search network and no published
9200/9300. Default heap is 512 MiB, container memory 2 GiB, 2 CPUs. Reserve additional
native/off-heap and filesystem-cache memory; size from actual data and concurrency.
Check host `vm.max_map_count` against Elastic's production Docker requirements
(currently 1048576), file limits, disk free space and memory before startup.
The root permissions init container only adjusts the new snapshot volume.

No historical `setup/elasticsearch.yml` or `log4j2.properties` is mounted. They are
comment-only markers directing maintainers here. No Groovy or historical Log4j JVM
option is passed. HTTP TLS, host verification, authentication and the official
client product check remain enabled. Single-node mode was started and exercised;
multi-node discovery, transport TLS and HA require a separate deployment design.

`scripts/elasticsearch_deployment.py prepare` creates a **new private directory
outside Git** containing persistent CA, certificate and five independent passwords.
It refuses existing directories. Root execution fixes the official uid 1000/gid 0
server-key/bootstrap-file ownership. An unprivileged installation must provide
equivalent permissions; the application uid must read only its runtime secret.
Certificates last 365 days: monitor expiry and arrange reviewed renewal before it.
Never regenerate the CA as a workaround for a failed recreation. Back up the
secret directory separately with restricted access; ES snapshots do not contain it.

`provision` is for an empty local target only; it checks the exact version and active
Basic license before creating these fixed roles and `fm-backup` filesystem repository:

| Identity | Allowed operations |
| --- | --- |
| `fm_runtime` | Cluster monitoring; read/write, refresh, metadata and dynamic-field auto-configuration only on the ten fixed families/aliases. No delete-index, settings/security administration or foreign-index access. |
| `fm_migration` | Cluster monitoring, index metadata inventory including unknown indices, full index operations only on the fixed target catalogue. No security administration or foreign document access. |
| `fm_backup` | Monitoring, create native snapshots, read/metadata only on the catalogue. No restore or repository administration. |
| `fm_health` | Cluster monitoring only; the health check verifies TLS, authentication, yellow-or-green status and absence of timeout. |
| Bootstrap administrator | Local initial users/repository setup, and separately approved restore operations. Never a Rails/browser credential. |

Bootstrap is not rerun when data exists or for an external service. Rails mounts
only public CA + runtime credential. Nginx mounts only its config/logs and public
packs/uploads, replacing the old `volumes_from` secret-sharing path. Browser
requests remain authenticated Rails API calls with existing policies, no ES secret,
arbitrary index/API proxy or caller-selected origin. A wrong password returns 401;
an unapproved CA is refused, as tested against the real server.

## New installation

Run `setup/setup.sh` with `FABMANAGER_IMAGE` set to the ES02–ES04 application
image/digest, either from a local release checkout or piped
(`curl -sSL setup.fab.mn | FABMANAGER_IMAGE=... bash`, which downloads its four ES9
companion files like the other installer files). A missing image is refused; the chosen
image is written into the installed `docker-compose.yml`. Python 3 and OpenSSL
are required. The destination must be empty; the installer never deletes other
Docker containers. Its PostgreSQL/Redis versions are not upgraded by this PR.

The local sequence prepares private persistent secrets, starts/provisions ES9,
creates/migrates/seeds the new SQL database, compiles assets, runs the separate
`fablab:es:initialize` with migration credentials, and performs read-only
`fablab:es:validate` with runtime credentials before starting producers. Rails key
generation uses OpenSSL without booting Rails before ES is available. Declining
database setup or any failed DB/schema operation exits nonzero before startup.
New initialization validates existing mappings and adds only missing known indices;
it never deletes statistics. It is not a migration of historical data.

The interactive host installer was syntax/gate checked; the exact delivered ES9
Compose, real SQL migrations, index initialization, scoped runtime validation and
application contracts were exercised separately in the disposable rehearsal. The
host's Nginx/Let's Encrypt/systemd prompts were not run against this workstation.

## External Elasticsearch

Set `FM_SEARCH_ENV_FILE` to a private host-side file before running setup. Provide
`ELASTICSEARCH_URL=https://your-fixed-origin:9200`, `ELASTICSEARCH_CA_FILE=/private/ca.crt`
and either `ELASTICSEARCH_USERNAME` + `ELASTICSEARCH_PASSWORD_FILE`, or
`ELASTICSEARCH_API_KEY_FILE`. Files refer to host paths during import. The helper
performs a verified, read-only version preflight before importing the credential
and public CA into the installation's private `config/search`. It removes the
local ES service, permission service, repository/data volumes and bootstrap secret
from the rendered Compose. It does not create users, mappings, repositories or
settings on the external cluster. Basic and API-key authentication were both tested.

The external administrator supplies scoped runtime rights and separate migration
rights. Before starting, initialize a genuinely new catalogue with those migration
rights and this code's `fablab:es:initialize`, then validate as runtime. For existing
data, use the reviewed transfer instead. If external validation fails after SQL/
assets preparation, the installer exits 3 without starting the application. Keep
that prepared directory; after the administrator resolves the schema, explicitly
run the validation command and start the prepared deployment. Do not rerun the
empty-directory installer over it. URL credentials, query strings and redirects
are refused. Never disable TLS verification to accept a corporate/self-signed CA;
provide the approved CA instead.

## Existing ES5 installation and coherent cutover

`setup/upgrade.sh`, including `-y -i`, runs a read-only preflight **before** pulls,
image/tag edits, stops or SQL migrations. ES5, a stopped/unknown endpoint or invalid
TLS/authentication exits 3. For an existing container, supply
`FM_ELASTICSEARCH_CONTAINER`; `FM_DEPLOYMENT_HELPER` can locate the reviewed helper.
`scripts/elastic-upgrade.sh` now only explains the migration and exits 3. New Rails
and Sidekiq code verifies the server on first use and refuses every Elasticsearch
operation against a non-9 server; booting, SQL migrations and asset compilation do
not contact Elasticsearch. Preserve the source image,
authentication, data format, volume and compatible native backup.

Use the ES03 **one-way typed scroll/export + bounded bulk import** tool. It works
directly between tested ES5.6.16 and ES9.5.6; no snapshot cross-version restore,
in-place server upgrade, permanent dual write or intermediate production target is
used. All nine statistics families and availability histories are copied. Current
PostgreSQL profiles/groups are not used to reconstruct old financial/statistical
values. The identity table and every blocking inventory condition are in ES03.

The bundled control adapter requires named SQL/Redis/source/target volumes, explicit
containers/producers and exclusively internal networks without published service
ports or unknown peers. A normal Internet-facing application topology must first
be put into maintenance and isolated by its operator. External SQL/Redis, other
supervisors or multi-host producers require a reviewed adapter; the installer is
not a universal production cutover orchestrator. Include web, workers, scheduler,
cron/rake, imports and external SQL writers. Do not infer coherence from `updated_at`.

Where ES5 already provides trusted TLS, use it unchanged. The OSS5 rehearsal used
an **additional private TLS/authentication relay**, with fixed ES5 upstream, CA
verification and no host port. It did not change ES5 authentication or require
paid ES5 security. Inventory it in `docker.auxiliaries` and set
`source.endpoint_container`; supply separate source application/migration relay
credentials. The relay-to-OSS5 hop remains inside the fully isolated private
network. This is not browser access or an arbitrary-destination proxy. Do not
expose ES5 to the Internet or silently strip an existing upstream authentication
scheme. Remove temporary migration attachments after all migration clients stop.

Review one persisted step at a time: inventory → maintenance/drain → native backup
and cold SQL/Redis archives → export → initialize empty target → import → validate
→ switch with writes closed → deploy stopped reviewed producers → adopt-producers
→ reopen → explicitly start target producers. A failed or incomplete validation
cannot publish the open guard. Keep the read-only **guard directory** mounted in
every producer. Workers started with the normal `config/sidekiq.yml` consume only the
matching `es9-RUN_ID-*` queues (the guard maps every configured name). Legacy jobs remain
queued/scheduled/retrying with payloads intact; they require individual SQL/effect
review. Imported history and the cutover day are protected from automatic cleaners.

Float/integer mapping precision is part of the contract. Migration retains the old
numeric mapping and coercion, exact business `_source`, signed zero and int64 values.
Do not change float32 to double64 merely because the JSON source looks the same.
The independent legacy-double fixture still exposes an ES5/9 aggregation difference
and blocks validation. There is no tolerance, rounded snapshot replacement or
automatic waiver. Unsupported numeric semantics require explicit review.

## Rehearsal measurements and limits

The 2026-11-05 isolated rehearsal started exact reviewed ES-A business code on
ES5.6.16, used real SQL models/builders for all Stats including order, created
availability/reservation data and 10,037 extra machine export records, then changed
validated SQL profiles/groups. Imported histories retained their original values.
Ten families contained **10,084 documents**. Complete identities, canonical contents,
date ranges and business probes matched, as did Rails permissions, custom charts,
filters, exports and historical snapshots. No volatile metadata was compared.

The successful automated inventory-to-switch pass took **40.98 s**, followed by
explicit adoption/reopen **9.98 s**. The **observed service outage was 1339.83 s**
(22 min 20 s), including diagnosis, image rebuild and manual producer deployment.
Do not quote the copy time as the outage or extrapolate this small synthetic run
to production capacity. Source observation: 28.35 s / 442,310,656 bytes peak app
cgroup; target: 31.56 s / 511,172,608 bytes. These are whole observer processes,
including XLSX/SQL, not Elasticsearch heap or peak migration-tool RSS measurements.
An additional instrumented 10,046-document failure/recovery copy (including killed
export, bulk, explicit raw-double rejection, rollback and complete ES5 snapshot
restore) took 73.36 s and peaked at **44,588 KiB RSS** for the Python host driver and
its CLI children. Docker daemon/server memory is excluded; this is a different
workload from the successful 40.98 s application rehearsal.
Rehearsal ES5 heap/cap: 256/768 MiB; ES9: 384/1536 MiB, each 2 CPUs. Fresh Compose
checks used ES9 256 MiB heap / 1 GiB cap / 1 CPU. Standard defaults remain larger.

Plan disk for the retained source, compatible ES5 snapshot, cold SQL/Redis archives,
SQLite export with indexes/WAL, new ES9 data, native ES9 snapshots and fresh restore
verification volumes, plus operational headroom. Tool reserves are fail-closed
checks, not a production capacity forecast. Measure your inventory and filesystem
before maintenance. Keep a separate off-host compatible backup, not just Docker
volumes on the same machine. No production data or site-sized load was exercised.

## Backup, restore, recreation and rollback

For a coherent application backup, stop/drain all producers and SQL writers, save
Redis, capture compatible cold SQL/Redis archives and native ES9 snapshots:

```sh
python3 scripts/elasticsearch_deployment.py backup --secrets /private/es9 \
  --address PRIVATE_ES_IP --snapshot explicit-backup-name
```

That command verifies every snapshot shard but does not stop producers or back up
SQL/Redis for you. The limited backup identity cannot restore. Register the retained
repository read-only on a **new ES9.5.6 volume** under a separately authorized
administrator, list the intended snapshot, and restore only its explicit ten-index
catalogue with `include_global_state:false`, `partial:false`. Validate all shard
results, aliases, complete identities/content and application behavior before use.
For ES5 rollback, restore its native repository only to ES5.6.16 with a new volume;
restore SQL/Redis with their recorded compatible images. Never overlay live volumes.
Restore the fixed role definitions and backed-up credential values under the
recovery administrator too: the business snapshot excludes security/global state.
Runtime credentials alone cannot perform that administration. Keep restored
business indices write-fenced pending complete application validation and a
reviewed new guard/cluster UUID; the old guard rejects writes to a new restore UUID.

The rehearsal restored an ES9 post-write snapshot into a separate empty volume:
all 10,084 identities and contents matched. It also tested real target recreation
with retained image/volume/cluster UUID, CA/passwords and limited roles. Do not
rerun `prepare`/`provision`. With a live migration journal and producers stopped,
`adopt-target` verifies exact version, image, original volume, UUID, TLS, schema and
aliases before accepting the recreated container ID. Old Sidekiq jobs stayed held;
a new job failed during the outage, retried and completed after recreation.
The cold SQL/Redis archives were then checksum-verified and restored into new
volumes under the recorded PostgreSQL 9.6 / Redis 6 images. Rails `/health` returned
200 under `fm_runtime`; order/cancellation and changed SQL profiles survived while
the imported historical source remained unchanged. Both legacy job IDs survived,
including the retry moved by Sidekiq to its original `elasticsearch` queue. No
worker was started on those queues. The restored cluster's new UUID and explicit
write fences kept writes closed pending review.

Before `writes_open`, `rollback` restores the original environment/fences and leaves
producers/SQL/Redis stopped. Check source data, start the recorded old code/config
and preserve target artifacts. Two real pre-write rollbacks were exercised. A new
attempt uses a new reviewed journal, not rewritten history.

After `writes_open`, rollback is **always refused**. Stop producers, take coherent
new backups and run `audit-target`: it compares against the immutable export and
records new/changed/deleted identities and hashes. The rehearsal detected **2 new,
2 changed, 2 deleted**, refused rollback and preserved new SQL/Redis/ES9 backups.
Reconcile SQL transactions, reservations/orders, jobs, deletions and external
effects explicitly; there is no automatic reverse writer or safe timestamp-only
delta. An old ES5 cluster is stale after reopening writes.

## Verification and review handoff

The opt-in `test/elasticsearch/rehearsal.rb` runs only under test with
`ES_CONTRACT_ISOLATED=1`, using the exact reference code for seed/observe and the
candidate for observe/post-cutover. Never run destructive contracts against a site.
The PR evidence directory retains commands, image digests, failed attempts,
normalized observations, comparisons, journals and backup checksums. The latest
targeted Ruby run passed **44 tests / 458 assertions**, including the unchanged
14-observation ES5 baseline. The ES03 failure suite passed 19 cases plus five
affected precision/canonicalization regressions (21 distinct test methods total).

Latest general suite: **726 tests / 9459 assertions, 1 ACD failure, 1 SSO error,
0 skips**. These remain review reserves, not a green full suite. The ACD date-tie
ordering and SSO autoload issue were previously recorded; no unrelated accounting
or identity-provider changes were made to hide them. Production inventory, capacity,
HA, real IdP and operator acceptance remain outside this disposable rehearsal.
No commit, push, publication or production deployment is performed by these tools.

Primary references: [Docker production requirements](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-docker-prod),
[HTTPS setup](https://www.elastic.co/docs/deploy-manage/security/set-up-basic-security-plus-https),
[security settings](https://www.elastic.co/docs/reference/elasticsearch/configuration-reference/security-settings),
[privileges](https://www.elastic.co/docs/reference/elasticsearch/security-privileges),
[numeric mappings](https://www.elastic.co/docs/reference/elasticsearch/mapping-reference/number),
[snapshot compatibility](https://www.elastic.co/docs/deploy-manage/tools/snapshot-and-restore),
[Basic license setting](https://www.elastic.co/docs/reference/elasticsearch/configuration-reference/license-settings),
[feature matrix](https://www.elastic.co/subscriptions),
[official distribution ELv2 conditions](https://www.elastic.co/licensing/elastic-license).
No paid feature was required or implicitly enabled in this rehearsal.
