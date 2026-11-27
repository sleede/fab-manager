# Elasticsearch 5.6 application boundary

`SearchIndex` centralizes the operations used by availability projections and
statistics. This change runs with the existing Elasticsearch 5.6 server and the
unchanged Ruby and browser dependencies. It has no PostgreSQL migration prerequisite.

The fixed catalogue maps `account`, `event`, `machine`, `project`, `subscription`,
`training`, `user`, `space` and `order` to their existing types in `stats`.
`availabilities` maps to `fablab/availabilities`. `all_stats` is an internal read
scope over `stats`. Unknown families or stored custom aggregation targets raise
an error before a request is sent. The source business field `type` remains
separate from the document family.

The application operations are:

| Operation | Contract |
| --- | --- |
| `search(family:, query:, **options)` | Pass the existing 5.6 DSL and query parameters through; return a `Result`. URL parameters cannot replace the route family or body. A timed-out or shard-partial response raises instead of being rendered as complete statistics. |
| `next_page(cursor:, keep_alive:)`, `close_cursor(cursor:)` | Continue or release a server cursor. The Rails pagination route retains its existing lifetime contract. |
| `each_page`, `each_hit` | Scoped enumeration with a 1,000-document default batch, empty-page termination, exact count verification, duplicate detection and cursor release in `ensure`. |
| `export(family:, query:)` | Collect complete pages for the existing XLSX templates. Raise on incomplete results. |
| `build_stat`, `create_stat`, `save_stat` | Preserve legacy Stats attributes, validation, callbacks, serialization and generated opaque IDs. |
| `update_stat(family:, id:, changes:)` | Partial update, including the existing `updated_at` behavior. Unspecified historical fields survive. |
| `index_availability(record:)`, `delete(family:, id:)` | Preserve the SQL availability projection and ID. The worker still tolerates missing records/documents only in its existing paths. |
| `delete_by_query(family:, query:, **options)` | Scoped deletion; timeouts, failures and version conflicts remain visible. Conflicts are accepted only when the caller passes `conflicts: 'proceed'`. Reservation cancellation logs an incomplete deletion and continues, because its SQL cancellation is already committed. |
| `refresh(family:)`, `healthy?` | Existing refresh/cluster health operations through the configured server-side client. |
| `rebuild_statistics!`, mapping methods | Administrative tasks only. Rebuild remains explicitly destructive; applying the availability mapping preserves documents. |

`Result#to_h` exposes `{total: {value, relation}, hits, aggregations}` with string
keys. Each hit carries `family` (the stored `_type`, which the internal `all_stats`
scope does not restrict to the catalogue), string `id`, `_source` and optional `routing`.
Totals are exact (`relation = eq`) on this 5.6 backend. No numeric conversion is
applied to source JSON. `Result#legacy_response` preserves numeric `hits.total`,
technical `_type`, `_source.type`, aggregations and scroll IDs for existing consumers.

All nine `POST /stats/<family>/_search` routes retain Devise authentication and
the existing administrator-only Pundit policy. They accept the same ES5 DSL and
`scroll` parameters. `stat-type`, `start-date`, `end-date` and `custom-query` are
still consumed by Rails for stored custom aggregations. `POST /_search/scroll`
still accepts `scrollId` and `scroll`. Existing export routes and the export
worker retain their authorization checks. No migration, schema or raw write API
is exposed to browsers.

The browser `es` service still uses `window.location.origin`: its requests reach
Rails. `elasticsearch-browser` and its application import remain together.
Removing that client, testing its compiled browser consumers and detaching the
Stats persistence models are follow-up ES02 work. AngularJS is unchanged. The
existing Elasticsearch gems remain necessary for Stats serialization and
Availability metadata/mappings; they must not be removed in this preparation.

The manual rebuild task now uses the configured client and reports HTTP failures
instead of ignoring `curl` exit status. It keeps the eight explicit legacy
statistics mappings; `order` retains its existing dynamic mapping behavior.
The old `machineDates`/`spaceDates` mapping requests were malformed JSON and
rejected by 5.6; those fields keep their effective dynamic mapping behavior.
The availability task applies its existing mapping without attempting the mapping
deletion API removed in 5.6, and its optional ID argument is passed to the worker.
No task runs automatically at application startup.

## Characterization

Run only in a disposable environment: the contract setup deletes `stats` and
`fablab`, and Rails loads its complete SQL fixtures. Use an independent ES5.6
container, PostgreSQL 9.6 test database and Redis with no published ports. Do not
point these commands at an existing application's services or volumes.

Install the unchanged lockfiles with Ruby 3.2.2 and Bundler 2.4.3. Use the normal
test environment with synthetic Stripe/OAuth/OIDC credentials, test mail delivery
and external network access blocked. Configure a private `config/database.yml`
and `ELASTICSEARCH_HOST`/`REDIS_HOST` for those disposable services. `db:schema:load`
uses the existing PostgreSQL client compatibility initializer in master.

```sh
RAILS_ENV=test bundle _2.4.3_ exec rails db:create db:schema:load db:fixtures:load
RAILS_ENV=test bundle _2.4.3_ exec rails fablab:es:build_stats
ES_CONTRACT_ISOLATED=1 CHARACTERIZATION_OUTPUT=/private/results/es56.json \
  RAILS_ENV=test bundle _2.4.3_ exec rails test \
  test/elasticsearch/contracts.rb test/elasticsearch/operations.rb test/services/search_index_test.rb --seed 12345
```

`test/fixtures/search_index/es56.json` was recorded from the unmodified master
application at `4d8bdc063a3aee57dffd27a89f2527aa14d5371c`, against Elasticsearch
5.6.16. The same characterization file runs before and after refactoring. The destructive live contracts use explicit file names
outside normal `*_test.rb` discovery; standard Rails test runs do not opt into index deletion.
The reference is asserted per scenario; candidate results do not regenerate it.
Normalization removes request timing, shard/score/version/cursor metadata and
model creation/update timestamps. It preserves deterministic IDs, source business
values, null versus missing fields, integer JSON values, aggregation values,
bucket order and XLSX cell digests. Generated document IDs are checked as opaque
strings separately; source serialization is compared without those random IDs.
XLSX archives are compared by normalized cells, not ZIP timestamps.

Coverage includes every Stats family, availability worker index/update/delete,
partial order updates, reservation cancellation, inclusive cleaner bounds,
disabled daily statistics, SQL builders and unrelated historical documents,
the three stored custom aggregations (including the average-cart script),
custom inclusion/exclusion, sums/averages/nulls/zeros, ranking/top hits and
day/week/month histograms across the Toronto spring DST transition. HTTP cursor
pagination covers 47 records in batches of seven. Global and per-family machine
XLSX exports each cover 10,037 records. Anonymous, member, manager and administrator
search access, restricted scroll/export access and worker authorization are checked.
Live administrative tests also check the effective eight-family rebuild mapping,
all nine writable models, repeatable availability mapping, explicit task IDs,
cleaning across three batches of dates, 23 matching order updates and the absence
of retained search contexts after successful, empty and interrupted exports.

Synthetic fixtures do not inventory a deployed cluster or site-defined queries,
plugins, aliases or scripts. The SQL builder reference produces account, machine,
subscription, user and order documents; event/project/space/training are separately
covered by serialization, read, identity and cleaner contracts. Those are distinct
claims. No compiled-browser or hosted CI result is claimed for this Ruby-only
change. The existing user-family export route remains outside the supported export
worker catalogue. XLSX rendering still collects the full result in memory.
TLS/authentication changes, typeless mappings, server upgrades, data copying and
cutover/rollback qualification belong to the later migration.
