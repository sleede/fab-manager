# Elasticsearch 9 application boundary

PR-ES-B builds on the reviewed PR-ES-A boundary. It targets a **new** Elasticsearch
9 cluster, without a PostgreSQL migration prerequisite. It is not an in-place
upgrade or a data migration tool. Existing ES5 services, volumes and credentials
must remain unchanged until the separate copy/cutover/rollback procedure is qualified.

## Versions and transport

Verified on 2026-11-04: Elasticsearch **9.5.6** supersedes the initially proposed
9.5.5, including security corrections. The isolated integration environment used
the official `docker.elastic.co/elasticsearch/elasticsearch:9.5.6` image, HTTPS,
password authentication, a private CA and no published Elasticsearch port.

The lockfile pins `elasticsearch` / `elasticsearch-api` **9.5.0** and
`elastic-transport` **8.5.3**. The transport's major version is independent of the
server major. Ruby **3.2.2**, Rails **7.0.8.7**, Faraday **0.17.3**, OAuth2 **1.4.4**
and OpenLab **0.0.8** are unchanged. The published client requires Ruby >= 2.6;
transport 8.5.3 requires Ruby >= 2.5 and Faraday < 3. The resolved old Faraday stack
was exercised against the real server, including TLS hostname/CA verification,
bad credentials, searches, bulk, scroll and clear-scroll. OAuth2 token exchange
and the OpenLab HTTParty client are separately exercised with stub HTTP endpoints.
These checks do not qualify a real identity provider or OpenLab deployment.

Primary sources:

- [Elasticsearch release notes](https://www.elastic.co/docs/release-notes/elasticsearch)
- [Official Ruby client](https://www.elastic.co/docs/reference/elasticsearch/clients/ruby)
- [Ruby transport](https://www.elastic.co/docs/reference/elasticsearch/clients/ruby/transport)
- [Connecting and product verification](https://www.elastic.co/docs/reference/elasticsearch/clients/ruby/connecting)
- [Client 9.5.0 gem metadata](https://rubygems.org/api/v2/rubygems/elasticsearch/versions/9.5.0.json)
- [Transport 8.5.3 gem metadata](https://rubygems.org/api/v2/rubygems/elastic-transport/versions/8.5.3.json)
- [Current scroll API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-scroll)

`config/initializers/elasticsearch.rb` creates the official client at
`Rails.configuration.x.elasticsearch_client`. Configure `ELASTICSEARCH_URL`,
`ELASTICSEARCH_USERNAME` / `ELASTICSEARCH_PASSWORD` (or `ELASTICSEARCH_API_KEY`),
and `ELASTICSEARCH_CA_FILE` on the Rails/worker side. Verification and the client
product check remain enabled. Do not use the retired host-only ES5 installation
configuration for this branch. No custom compatibility header emulates ES5.

The removed model, persistence, Rails integration and old transport gems have no
remaining application calls. `Stats::Base` supplies only the typed attributes,
defaults, validation and JSON values actually used by the nine business classes.
`SearchIndex` owns persistence and opaque IDs. `request.elasticsearch` notifications
contain the operation and resolved index, not request bodies or credentials.

## Identity, mappings and aliases

There are ten independent physical indices. The application writes through fixed
aliases with `require_alias` for index, update and bulk operations. There is no
browser-supplied target, generic storage interface, fallback backend or double write.

| Source index | Source `_type` | Target physical index | Application alias | Target `_id` |
| --- | --- | --- | --- | --- |
| `stats` | `account` | `fm-stats-account-v1` | `fm-stats-account` | unchanged source ID |
| `stats` | `event` | `fm-stats-event-v1` | `fm-stats-event` | unchanged source ID |
| `stats` | `machine` | `fm-stats-machine-v1` | `fm-stats-machine` | unchanged source ID |
| `stats` | `project` | `fm-stats-project-v1` | `fm-stats-project` | unchanged source ID |
| `stats` | `subscription` | `fm-stats-subscription-v1` | `fm-stats-subscription` | unchanged source ID |
| `stats` | `training` | `fm-stats-training-v1` | `fm-stats-training` | unchanged source ID |
| `stats` | `user` | `fm-stats-user-v1` | `fm-stats-user` | unchanged source ID |
| `stats` | `space` | `fm-stats-space-v1` | `fm-stats-space` | unchanged source ID |
| `stats` | `order` | `fm-stats-order-v1` | `fm-stats-order` | unchanged source ID |
| `fablab` | `availabilities` | `fm-availabilities-v1` | `fm-availabilities` | unchanged SQL/source ID |

The mapping is injective over the supported source catalogue: equal IDs in two
legacy types occupy different indices. The real-server contract writes the same
ID to every family and reads all of them back. New statistics use UUID strings;
re-saving an object reuses its ID. The business `_source.type` is preserved.
The reserved source object `__fm.uid` contains `family#id`, preserving explicit
legacy `_uid` sorting, and is removed from application/HTTP/XLSX results.
Writes reject a supplied `__fm` object. Migration must detect a source collision
with this reserved name before copying anything. Empty IDs are rejected.

The read-only application scope `all_stats` resolves to `fm-stats-all`, covering
the nine statistical indices. Unknown legacy types require an explicit migration
decision; they must not be silently discarded. This is a difference from ES-A's
global ES5 read, which could return unknown stored types. Custom routing, extra
indices/aliases and site-specific scripts require explicit treatment by the transfer inventory.

`SearchIndex::Schema` is the executable schema definition. It uses typeless
`mappings.properties`, version/family `_meta`, one shard, zero default replicas
for the isolated target, and a 1,000-field limit. Production replica/capacity
choices require an operational plan. Initialization validates existing mappings
and aliases, not every mutable index setting.

| Fields | Target semantics |
| --- | --- |
| `type`, `subType`, `name`, `ageRange`, `eventTheme` in Stats | `keyword`, preserving legacy exact-match fields |
| `gender`, `group`, `groupName`, `coupon`, `state`, `status` | `text` plus `.keyword` (256-character subfield limit) |
| `date`, `created_at`, `updated_at`, `eventDate`, `trainingDate` | explicit `date` |
| IDs, age, users | explicit `long` |
| `stat`, `ca` | explicit `float` for a new installation, matching the real legacy model precision; migrated float/double/integer mappings are retained |
| `machineDates.name`, `spaceDates.name` | date values inside ordinary objects |
| licence/themes/components/machines/project users/products/categories | ordinary objects with long `id`, text/keyword `name` |
| Availability `available_type` | `text` with the existing `simple` analyzer plus keyword subfield |
| Availability dates, IDs, durations and places | explicit dates/longs, with float durations matching the legacy projection; migration retains observed precision |
| additional strings | dynamic text/keyword template; automatic date detection disabled |

Custom numeric/date/array fields and strings exceeding keyword limits must be
checked against the real source schema by the transfer inventory. Synthetic mappings do not
prove that every deployed plugin or custom field is compatible. No `_type`
mapping, typed URL or `string` / `not_analyzed` mapping is sent to ES9.

## Application and API contracts

| Operation | Contract |
| --- | --- |
| `search(family:, query:, **options)` | Fixed family, translated application DSL, exact totals. Supported URL options: scroll, size, from, search_type. |
| `next_page`, `close_cursor` | Native ES9 scroll request bodies and clear-scroll request bodies. |
| `each_page`, `each_hit` | 1,000-document default pages, empty-page termination, exact count and duplicate checks; latest cursor released in `ensure`, including interrupted exports. |
| `export` | Complete pages assembled for existing XLSX templates; incomplete results raise. XLSX still uses memory proportional to the exported data. |
| `build_stat`, `create_stat`, `save_stat` | Typed business values, validation, UTC timestamps and opaque IDs. |
| `update_stat` | Partial update plus `updated_at`; unspecified historical fields survive. |
| `index_availability`, `delete` | Existing SQL projection/ID, same worker behavior for missing records/documents. |
| `bulk_index` | Every item status/error and item count checked. `BulkFailure#items` exposes partial successes; callers must not blindly retry the whole batch. |
| `delete_by_query` | Family-scoped deletion, timeout/failure checks; version conflicts accepted only with explicit `conflicts: 'proceed'`. Reservation cancellation continues after logging an incomplete ES cleanup. |
| `refresh`, `healthy?` | Configured official client, no dependency on removed Rails instrumentation/model clients. Health preserves the existing reachability contract. |
| `initialize_schema!` | Non-destructive schema validation/creation, separate from data migration. |

`Result#to_h` exposes string keys `{total: {value, relation}, hits, aggregations}`.
Hits carry family, string ID and unmodified business source values. ES9
`hits.total` is required to have `relation: eq`; approximate totals, timeouts and
shard-partial responses raise. The compatibility response used only by existing
Rails/XLSX consumers has numeric `hits.total` and synthetic legacy `_index` and
`_type`. Neither is sent back as a typed ES9 request.

The DSL adapter translates only the queries found in statistics, graphs, builders
and stored custom aggregations: bool/term/terms/match/range/exists/match_all,
metrics, terms, filter, top_hits and date_histogram. It translates keyword sorts
and terms fields, `_uid`, `_term` ordering, and legacy calendar/fixed intervals.
Ambiguous intervals are rejected. The exact seeded average-cart script is allowed
as Painless; other scripts, terms lookup, arbitrary root options and scripted
sort/top_hits are rejected. Custom scripts need explicit migration review.

All nine `POST /stats/<family>/_search` routes retain Devise and the existing
administrator Pundit policies. Rails still handles `stat-type`, `custom-query`,
`start-date` and `end-date` for custom aggregations. URL parameters cannot replace
the route family or body. No raw Elasticsearch API or migration endpoint exists.

`POST /_search/scroll` accepts `{scrollId, scroll}`. `DELETE /_search/scroll`
accepts `{scrollId}` and returns 204, using the same authorization policy. Browser
cursors are Rails-signed, purpose-bound tokens expiring after five minutes;
Elasticsearch's requested context lifetime may expire earlier. Invalid/expired
cursors return 410, unsupported/malformed searches return 422, and backend/partial
read errors return 503, with generic error identifiers rather than cluster details.
Existing unauthorized/anonymous behavior is preserved.

AngularJS remains. The `es` service uses `$http` with explicit JSON `Accept` headers against fixed Rails paths,
preserving callbacks and promises for statistics tables and graphs. The browser
package, import and Angular dependency were removed together. Refresh, completion
and destruction release table cursors. No Elastic credential or destination URL
is present in browser configuration.

## New installation versus migration

Provision a **new**, separately named ES9 service and empty volume with TLS/auth.
See [the isolated target example](../docker/elasticsearch9/docker-compose.yml).
Do not substitute that image into the old compose stack or mount an ES5 data path.
Configure Rails and workers with server-side credentials and the trusted CA, then:

```sh
bundle _2.4.3_ install
RAILS_ENV=production bundle _2.4.3_ exec rails fablab:es:initialize
RAILS_ENV=production bundle _2.4.3_ exec rails fablab:es:build_availabilities_index
```

The availability task queues indexing jobs, so its completion requires a worker.
`fablab:es:build_stats` remains a non-destructive setup alias (honoring the disabled
statistics setting). `add_event_filters` and `add_spaces` validate the current
schema. Re-running initialization preserves documents and rejects unknown aliases,
incompatible mappings and legacy `stats`/`fablab` indices before creating targets.
It is not automatically invoked at Rails startup. A failed request can leave some
new empty indices; the safe, idempotent initialization can be retried.

`generate_stats[period]` still explicitly replaces a requested historical period
from SQL; it is **not** a migration and may not reproduce historical/custom ES
data. Existing setup/development compose files and `scripts/elastic-upgrade.sh`
describe the legacy deployment and must not be used to deploy this branch.

For an existing installation, use the explicit
[historical transfer procedure](../scripts/elasticsearch_migration/README.md)
(ES03 in the current transfer request; ES05/ES06 in the original plan).
It inventories and fences the source, takes a native ES5 recovery snapshot,
copies all ten families through a bounded scroll/archive/bulk pipeline and compares
complete identities, contents and business aggregations. It never regenerates the
historical data from current SQL. Unknown families/routing/scripts and missing
source require explicit treatment. Maintenance, queue isolation, deployment image
verification, rollback before writes and a post-reopen reconciliation audit are
separate journaled operations. The optional runtime guard prevents an old job or
historical cleaner from replacing imported records. Keep it enabled throughout
the reconciliation period.

The large migration fixture retains a **blocking** sum difference:
ES5 `200238.15000002686` versus ES9 `200238.15` for 10,037 amounts of 19.95.
Its document identity/content fingerprints are equal. No tolerance or changed
expected value makes that aggregation pass. This is distinct from the 14 original
application observations below, which remain equal. See
`test/fixtures/search_index/migration_observed.json` for the recorded migration
results. No production transfer, source authentication change or rollout approval
is implied by the synthetic tests.

## Evidence and repeatable tests

Use disposable ES9/PG9.6/Redis services, independent volumes, synthetic credentials
and an internal network. Install the frozen Ruby/Node lockfiles. Set the regular
test environment and CA/auth variables above. The explicit opt-in contracts delete
only the ten known ES9 physical indices and load SQL fixtures; never run them
against a deployed application. They are outside normal `*_test.rb` discovery.

```sh
RAILS_ENV=test bundle _2.4.3_ exec rails db:create db:schema:load db:fixtures:load
ES_CONTRACT_ISOLATED=1 CHARACTERIZATION_OUTPUT=/private/es9-results.json \
  RAILS_ENV=test bundle _2.4.3_ exec rails test \
  test/elasticsearch/contracts.rb test/elasticsearch/operations.rb \
  test/elasticsearch/transport.rb test/services/search_index_test.rb \
  test/services/search_index_query_test.rb test/services/elasticsearch_http_consumers_test.rb
yarn install --frozen-lockfile
yarn test --runInBand
```

The frozen `test/fixtures/search_index/es56.json` was recorded against real ES5.6.16
from upstream master `4d8bdc063a3aee57dffd27a89f2527aa14d5371c`. It is unchanged.
All **14** normalized observations match on ES9.5.6. Normalization excludes timing,
shards, scores, versions, cursors, random model IDs and creation/update timestamps;
it preserves business JSON, null/missing/zero distinctions, exact integers,
aggregation values, deterministic sort/bucket order and XLSX cell digests.
Unspecified order is canonicalized only for scenarios without a sorting contract.
No expected snapshot was regenerated to accept different values.

Coverage includes all nine Stats families, availability index/update/delete,
disabled daily statistics, builders, partial updates, cancellation, inclusive
cleaner bounds, three seeded custom aggregations, zeros/nulls, dates/timezones and
the Toronto DST boundary, 47-result HTTP pagination, and per-family/global XLSX
exports of 10,037 documents. Additional ES9 checks cover identity collisions,
typeless idempotent schema setup, aliases, unknown targets, keyword fields, large
integers, exact totals, partial bulk failures and cursor cleanup after interruption.
Anonymous, member, manager, administrator and export-worker permissions are tested.

The earlier ES02 combined targeted run had **40 tests / 429 assertions**, no failures/errors/skips;
the complete Jest run has **72 tests** passing. The standard Rails run has
**726 tests / 9,531 assertions**, zero failures, one pre-existing SSO constant-loading
error, zero skips. This is a suite reserve, not a complete suite PASS.
The compiled Angular service also passed 31 real Edge/Rails/ES9 checks with CSRF
enabled: real synthetic sessions, anonymous/member/manager/admin permissions,
all nine families, graph metrics, signed cursors and 47-document pagination.
The complete production assets compile successfully (resource-limited test runner);
this does not claim a full visual UI acceptance test. TypeScript reports ten
diagnostics in each application configuration, identical on ES-A and this branch.

The SQL builder reference produces account/machine/subscription/user/order;
event/project/space/training also have serialization/read/identity/cleaner coverage,
not a claim of every real-world builder input. Site-defined queries, data migration,
production topology, real SSO and hosted CI remain separate qualification work.
The inherited user-family export route is outside the export worker catalogue.

## ES04 deployment rehearsal

Read [the operator runbook](elasticsearch_deployment.md) for new installs, ES5
upgrade detection, external services, scoped roles, TLS, backups and rollback.
The latest affected application contracts pass **44 tests / 458 assertions** with
the unchanged 14-observation ES5 fixture. Real reference/candidate observations
also match for ten families, historical snapshots, permissions, custom charts,
filters and multi-page XLSX exports. Runtime reports client 9.5.0 and none of the
four removed legacy integrations loaded. This does not waive the explicit raw
legacy-double aggregation difference documented above, nor the ACD/SSO reserves
in the general suite. ES03 retains source numeric indexing precision and signed
zero; defaults and migrated precision are deliberately distinct contracts.
