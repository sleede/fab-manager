# Historical Elasticsearch transfer

This is a temporary operator tool, not an application storage backend. It implements
one route: ES **5.6.16 scroll → private SQLite archive → ES 9.5.6 bulk**. Python 3.10+
and its standard library are sufficient on the Linux Docker host. The exact server
versions, container IDs, cluster UUIDs, reviewed schema digest and configuration
digest are pinned in the journal. No compatibility header or intermediate cluster
is used. The application continues to use its official Ruby client and Rails access
controls. Nothing in this directory is exposed through HTTP or the browser.

The source is read using its own typed API. Destination operations use typeless APIs.
Both versions support scroll and bulk, independently of wire/index-format
compatibility. Each cursor is cleared in a `finally` block; an expired scroll starts
a new complete scan against the frozen source. The SQLite primary key deduplicates
replayed documents. Import acknowledgements are checked individually. A lost bulk
response can repeat the same destination IDs; it cannot generate new IDs.

References: [ES5 scroll](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/search-request-scroll.html),
[ES9 scroll](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-scroll),
[bulk](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-bulk),
[ES5 native snapshot/restore](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/modules-snapshots.html),
[snapshot compatibility](https://www.elastic.co/docs/deploy-manage/tools/snapshot-and-restore).
The live test is the compatibility evidence for these exact versions. Snapshots are
for recovery on ES5, never direct restoration into ES9. An archive of a live ES data
directory is not a supported backup.

## Supported operating boundary

This implementation supports an explicitly enumerated, single-node Docker source
and target, PostgreSQL and Redis with dedicated named volumes. Every attached
network must be internal, with no published ports and no unknown peer. Move the
installation into maintenance and its services onto reviewed private networks
before running the tool. Do not publish ES5 to make a transfer possible. Kubernetes,
managed/cloud clusters, multi-node clusters, external cron/SQL producers, external
Redis, Redis authentication, nonstandard script paths, and arbitrary deployment
supervisors require a separately reviewed control adapter; they are not silently
treated as covered by the Docker procedure. Record every producer, including web,
workers, scheduler, rake/cron, imports and external SQL writers. Inventory and disable
host scheduling too. An incomplete producer inventory is not a coherent snapshot.

Provision ES9 on an empty **different** volume with its own TLS credentials. Keep
ES5's image, data volume and authentication unchanged. Provide a dedicated ES5
filesystem snapshot repository mounted at the configured absolute `snapshot.location`
and permitted by `path.repo` before this procedure. Repository setup may require a
planned restart with the same ES5 image. The tool never mounts the ES5 data volume
in ES9. Keep configuration/security files, deployment manifests and image digests
in the operator's existing secure backup as well; ES snapshots do not include them.

The tool requires local Docker administration, source read/count/scroll/metadata/
write-fence/snapshot privileges, and target index creation/bulk/search/alias/settings
privileges. The real ES04 rehearsal uses separate limited runtime, migration, health and backup
roles, with bootstrap only for empty-cluster provisioning and separately approved
restore operations. See [deployment and role definitions](../../doc/elasticsearch_deployment.md). Supply passwords through named environment variables and CA
files; URLs cannot contain credentials, paths or redirects. No secret goes into Git.
Use a private encrypted filesystem for the journal, config and backup artifacts.

## Identities and reconstruction

| Source `(index, _type, _id)` | Destination `(index, _id)` | Read/write alias |
| --- | --- | --- |
| `(stats, F, ID)`, F one of account/event/machine/project/subscription/training/user/space/order | `(fm-stats-F-v1, ID)` | `fm-stats-F` |
| `(fablab, availabilities, ID)` | `(fm-availabilities-v1, ID)` | `fm-availabilities` |

`fm-stats-all` reads the nine statistics indices. IDs remain opaque strings, including
leading zeroes and large integers represented as strings. Different old types may
have the same ID because they land in different indices. The source business `type`
field is unchanged. Destination `__fm.uid = family#ID` is the only added source
metadata; pre-existing `__fm` is blocking. The archive records both full identities.
Application updates/deletes retain family + ID through `SearchIndex`; never update
by ID alone across all families.

**All ten ES families are copied. None is regenerated from PostgreSQL.** SQL remains
the source for new work after cutover and supplies reviewed custom aggregation
templates and the target schema. Availability projections can be rebuilt in a new
installation, but historical availability documents are copied in this migration.
Current SQL is not evidence that old statistics are reproducible. Unknown families,
plugins, scripts, aliases, routing/parent relationships, filtered/missing `_source`,
reserved metadata, unsupported field/analyzer definitions and collisions block the
operation. Do not remove an index or document to make inventory pass. Implement and
review an explicit treatment, then start a new reviewed configuration/journal.

Legacy `string/not_analyzed` becomes `keyword`, other `string` becomes `text`.
Application fields use the reviewed ES9 schema; extra supported historical fields
are merged recursively. Existing float32/double64/integer mappings and numeric
coercion are retained for business values, rather than promoting them to double.
An identical `_source` with changed index precision can change aggregates. Canonical
content retains negative zero, exact int64/decimals, nulls and absent values.
Unsupported numeric precision requires explicit treatment. Reinitialization
recognizes the migrated precision and never rewrites it. No typed mapping is sent to ES9. Unsupported definitions
fail before bulk or as explicit per-document failures. Aliases are installed only
after validation. Destination indices must belong to this journal; incompatible
indices are never replaced. Fresh ES9 security and built-in ILM/deprecation history
indices are explicitly recognized and retained, not imported or deleted.

## Configuration and steps

Export the actual application schema and SQL custom queries from this reviewed
branch, against the source SQL with producers stopped:

```sh
ES_MIGRATION_SCHEMA_OUTPUT=/private/schema.json bundle exec rails runner scripts/elasticsearch_migration/schema.rb
python3 -c 'import sys; sys.path.insert(0,"scripts/elasticsearch_migration"); from common import decode,digest; print(digest(decode(open("/private/schema.json").read())))'
```

Supply that digest as `schema_sha256`. The source SQL templates are checked during
inventory and again after producers drain, immediately before SQL stops. A changed
template requires a new artifact and reviewed journal, not editing a checksum.
Use `config.example.json` as a template. `activation_file` is an existing private
deployment environment file; the tool retains its exact previous content. Explicit
container names are mandatory, including each producer. Worker containers must
have `worker: true`; TSTP must reach the real Sidekiq PID 1, or supply the explicit
`supervisor` program name. A generic sleeping container is only a synthetic fixture.

Run each command explicitly; successful output includes the persisted phase:

```sh
python3 scripts/elasticsearch_migration/migrate.py --config /private/config.json --journal /private/es-transfer inventory
# Then, with the same arguments, one step at a time:
# maintenance → backup → export → initialize → import → validate → switch
# Choose rollback OR reopen after reviewing the evidence and deployment configuration.
```

1. `inventory`: stores mappings/settings/aliases/cluster metadata/plugins/scripts,
   counts and a scan of every document for missing source/routing/collisions. A
   blocker is persisted and exits nonzero.
2. `maintenance`: quiets workers, stops other producers, waits for busy work to
   finish, checks SQL transactions/custom queries, inventories all queues/scheduled/
   retry/dead jobs, saves Redis, then stops Redis and SQL. It write-fences ES5 and
   captures a fresh inventory. Tasks remain intact; active mutations block the step.
3. `backup`: verifies a native ES5 snapshot completed with all shards successful;
   archives its dedicated repository and the stopped SQL/Redis volumes. Checksums,
   image IDs, volume names and sizes are journaled. Existing archives are verified,
   never overwritten. Restore-test a copy before production cutover.
4. `export`: stores original business `_source` JSON and its canonical digest in
   SQLite in bounded pages. Dates, null, absent values, arrays and exact decimal/
   int64 values survive; technical `_version`, `_seq_no`, scores and shard metadata
   are excluded. Memory is bounded by the response/page/document/bulk limits.
5. `initialize`: creates modern mappings in the empty target. This is separate from
   new-installation `SearchIndex.initialize_schema!` and never clears existing data.
6. `import`: bounded bulk, per-item acknowledgements and checkpoints. Successes in
   a partially failed lot remain acknowledged; failures remain pending and block.
7. `validate`: rereads both clusters and compares counts per old type/destination,
   complete identity sets, canonical business content and ordered identity/content
   fingerprints; also compares date ranges, sums, timezone histograms, subtype and
   every saved SQL custom aggregation. Non-equality is explicit in `comparison.json`.
   A different unspecified search order is harmless; different values are not.
   In particular, ES5 sums of 10,037 amounts of 19.95 yield `200238.15000002686`
   while ES9 yields `200238.15`. The unchanged large fixture proves exact document
   preservation and **blocks** on this raw aggregation difference. No epsilon,
   rounding or automatic waiver is applied. A business decision about numeric
   presentation/rounding requires a separate reviewed contract before such a
   production dataset can pass; the tool must not label this equality.
   Rechecks source fences/schema, target schema/aliases and backup checksums. Fences
   target writes after success.
8. `switch`: repeats validation, installs fixed aliases and atomically changes the
   deployment environment pointer. **Writes stay closed.** No application container
   is automatically started or silently recreated. Deploy the reviewed ES9 code,
   TLS/auth configuration and the guard directory mount below; review the actual
   environment/image/worker queue configuration before proceeding. Keep them stopped
   and run `adopt-producers`: it verifies each configured `target_image` SHA-256 image
   ID, ES origin, guard environment and read-only directory mount. Only producer
   container IDs can change at this explicit step; source/target/SQL/Redis identities
   remain pinned. `reopen` refuses an unreviewed deployment.
9. `reopen`: repeats validation, records the irreversible `writes_open` boundary
   before any index is unfenced, publishes the guard and starts SQL/Redis. Operators
   explicitly start only reviewed new-code producers. An interrupted reopen can be
   completed with `reopen` while producers remain stopped. It cannot become a rollback.
10. `detach`: disconnects source and target from the temporary migration network.
    Explicit source/target endpoint relays are disconnected too.
    Keep the source stopped/isolated, its volume, repository and backups. Do not
    remove the destination's separate private application network.

`status` is read-only except for the journal lock. Every step journals events and
nonzero blocking reasons. Resume using the exact same config, schema, containers
and journal. Export deliberately starts a full frozen scan again; it does not infer
a delta from `updated_at`. Import retries pending IDs. Never delete the SQLite file,
edit expected hashes, discard invalid documents, or purge queues to make progress.
Space checks cover archive/export/bulk reserves; exhaustion still fails closed.
An orphan `.partial` or unjournaled final backup requires manual checksum/recovery
review, not automatic deletion. A changed deployment requires a separately reviewed
recovery journal. Stop source/target clients before removing the temporary network.

## Queue and historical protection

Mount the **directory** `JOURNAL/runtime` read-only at `/run/fab-manager-es-migration`
in every Rails/Sidekiq/cron producer; the atomic replacement of `guard.json` must be
visible. Keep `ES_MIGRATION_GUARD=/run/fab-manager-es-migration/guard.json`. The target
activation file forces that setting. A missing/invalid/closed guard blocks writes
and job creation. ES mutations also verify the destination cluster UUID.

All pre-cutover queued, scheduled, retry and dead jobs keep their original payload
and queue. Do not start workers on these legacy queues. New jobs are routed to
`es9-RUN_ID-QUEUE`. At worker startup the guard maps every configured queue name
(including `config/sidekiq.yml` weights) onto that namespace; server middleware rejects
old queues/jobs. Sidekiq's scheduler/retry forwarding retains
`created_at`, so old jobs continue to land on legacy queues. The real Redis backup
retains scores and payloads; `pending-jobs.jsonl` is a bounded audit, not a replacement
for Redis. Unknown job classes are held too. Review jobs individually: financial,
email/import and reservation effects require SQL reconciliation; historical
`PeriodStatisticsWorker`/`StatisticsWorker` work must not regenerate the imported past.

The cleaner also refuses date ranges at/before `protected_through` (at least the
configured maintenance day and the latest imported statistic date). This can hold
a new daily job that spans the cutover day; reconcile that day explicitly. A
historical correction needs a reviewed operation preserving other records, not a
general rebuild. Do not remove the guard merely to get a scheduled job through.

## Rollback and recovery

Before writes reopen, `rollback` restores the original deployment environment and
source write settings, leaving producers/SQL/Redis stopped. Verify the source
comparison and start the original code/image/config with the unchanged SQL/Redis
volumes and old queue configuration. Target indices/volumes are retained for review.
Use a new migration journal for another attempt. The native snapshot restoration
test uses **ES5.6.16**, an empty data volume and a read-only copy of the repository;
`POST /_snapshot/REPO/NAME/_restore?wait_for_completion=true`, followed by complete
identity/content/count checks. SQL/Redis archives restore only into fresh volumes
using their recorded compatible images. Never overwrite an existing source volume.

After `writes_open`, the tool refuses rollback even if no writes were observed.
Stop new producers, drain/record work, fence ES9 and take fresh SQL/Redis/ES9 backups.
Reconcile new, changed and deleted ES identities; reservations/orders/statistics,
availability projections, SQL effects, jobs and external side effects since reopen
must all be accounted for. The old cluster is stale. Compare current content against
the immutable archive using `audit-target` (streams new/changed/deleted IDs and hashes
to a new `reconciliation-*.jsonl`); a timestamp-only delta is insufficient for deletions, old
date updates or delayed jobs. An explicitly reviewed reverse transfer/SQL recovery
is required before deciding to serve ES5 again. The audit alone is not a coherent
multi-index or SQL snapshot while producers run. There is no automatic reverse writer.

## Reproduction

Only run the destructive fixture on an entirely disposable five-container bench:

```sh
ES_CONTRACT_ISOLATED=1 ES_MIGRATION_LIVE_CONFIG=/private/test-config.json \
  ES_MIGRATION_TEST_OUTPUT=/private/new-test-output python3 test/elasticsearch/migration_live_test.py
ES_CONTRACT_ISOLATED=1 bundle exec rails test test/elasticsearch/migration_guard.rb
```

The Python test refuses a network outside `fm-es-transfer-*`. It exercises real
ES5/ES9 operations, an actual killed export process, a deleted/expired scroll,
partial bulk failures, invalid dates, incompatible mappings, unknown indices,
missing source, insufficient reserve, lost source access, queue preservation,
snapshot restore and rollback. Plugin metadata and busy-worker entries are
injected explicitly; they are not a claim of running arbitrary plugins or a full
production worker fleet. See the PR-ES-B ES03 report for exact final test results,
failed attempts retained, remaining deployment/ES04 reserves and evidence hashes.

## TLS endpoints and target recreation

Use verified HTTPS for source application/migration connections and the target.
For a legacy OSS5 node without TLS, a separately inventoried, private fixed-upstream
relay can terminate TLS/auth without changing the source node/image/authentication.
Set `source.endpoint_container` to an explicit `docker.auxiliaries` member and keep
the relay/source on the isolated network. Never publish source ports or disable
verification. Preserve an already authenticated source's upstream credentials;
the rehearsal's unauthenticated OSS5 internal hop is not an auth migration recipe.

After writes reopen, a container can be recreated with the **same** target data
volume and image. Keep all producers stopped and run `adopt-target`: it verifies
the original cluster UUID, exact version, image, volume, TLS and current schema/
aliases before journaling the new container identity. It cannot adopt a different
cluster or change any other container. It does not reopen a closed migration or
authorize rollback. Do not regenerate CA/passwords or rerun provisioning.

ES04's real rehearsal compared all nine Stats families and Availability, Rails
permissions, custom aggregations/filters, XLSX pages over 10,000 documents and
historical snapshots after SQL profile/group changes. It also exercised actual
Sidekiq retry/recovery, pre-write rollback, post-write refusal/reconciliation,
native ES9 restore and persistence across recreation. The standalone live suite
now contains 21 distinct cases; the latest 19-case run plus five affected numeric
regressions cover them without relabeling the preserved large-double difference
as equality. See the deployment runbook and external ES04 report for timings,
resources, command logs, unchanged ES5 baseline and general-suite reserves.
