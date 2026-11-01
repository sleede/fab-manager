# Dependency security regression checks

Run these checks with the repository Ruby/Bundler versions on Linux, using disposable
PostgreSQL/Redis/Elasticsearch services and synthetic fixtures. See `scripts/tests.sh`
and the development guide for the standard test entry point. Test databases must be
separate from shared development and production databases.

## Uploads and URLs (R3)

`bash scripts/tests.sh test/lib/upload_dependency_test.rb test/integration/supporting_document_files_authorization_test.rb test/integration/projects_test.rb --seed 12345`

Checks exercise real CarrierWave uploaders, ImageMagick variants, content and extension
validation, configured model size limits, CAD configuration, removal, private destination
rejection, and Addressable normalization/template round trips. Image processing remains
on the compatible 1.13 family. Temporary upload roots keep test files outside user storage.
CarrierWave 3.1 prints a one-time warning for uploaders whose `filename` is guarded by
`if original_filename`; removing those guards is separate maintenance, not part of this update.

## Tokens and passwords (R4)

`bash scripts/tests.sh test/lib/authentication_dependency_test.rb test/integration/rack_compatibility_test.rb test/models/user_test.rb --seed 12345`

JWT tests use real signatures and explicit algorithms/claims, including nil/empty key
rejection. A simulated OAuth2 exchange exercises the installed parent API. Devise reads
a synthetic hash produced by the previous bcrypt and verifies newly generated passwords.
The existing Rack checks retain CSRF validation during login/logout. JWT 3 is outside
the OAuth2 parent's supported range. The bcrypt Java/JRuby advisory does not apply to MRI.

## Mail and notifications (R5)

`bash scripts/tests.sh test/lib/mail_dependency_test.rb test/integration/notifications/notifications_test.rb --seed 12345`

The mail checks round trip MIME/UTF-8/legacy charsets and attachments, check malformed
headers, and render account, Devise and notification templates through the test adapter.
The template tests stub only the compiled-logo manifest lookup, because the test-environment
Webpack compile is not part of this check. They retain the parser preload workaround. No application IMAP client was found; bounded
IMAP parser checks establish library compatibility and do not represent an IMAP workflow.
Keep net-imap on the compatible 0.5 family. No message is sent to an external recipient.

## Serialization and caches (R6)

`bash scripts/tests.sh test/lib/serialization_dependency_test.rb --seed 12345`

Synthetic fixtures were generated with the previous MessagePack/Oj graph. Tests read
those bytes, exercise the real Bootsnap store, existing Rails JSON date/decimal schemas,
trusted repository-owned cache entries, a MemoryStore and Sidekiq's JSON/fake queue.
No global Oj replacement or object-loading policy is enabled. Bootsnap caches are
platform-specific disposable data; another Ruby platform must invalidate them.
Native Linux builds and a separate old-library reader check establish the bounded
rollback behavior of the compatible synthetic formats. No production data is used.

## Calendars and scheduled jobs (R7)

`bash scripts/tests.sh test/lib/calendar_dependency_test.rb test/workers/reservation_reminder_worker_test.rb test/integration/events/recurrence_test.rb --seed 12345`

Calendar checks exercise actual reservation feeds/exports and the importer against a
stubbed feed, preserving text/UID/time fields and recurrence syntax. The committed job
fixture records every actual ERB/YAML schedule with the previous Fugit/et-orbi versions,
three next occurrences at four fixed references and both configured and explicit Toronto
zones. Tests compare those timings and 23/25-hour DST days. Worker tests use synthetic
fixtures and queued test mail; no scheduler daemon or production job is started.
iCalendar 2.12.5 corrected the generated VTIMEZONE: DAYLIGHT and STANDARD onsets are now
expressed in local time at TZOFFSETFROM, as RFC 5545 requires (the Paris spring change moves
from 03:00 to 02:00). A regression test covers the Paris and Toronto transitions.
The existing ice_cube 0.16.4 family remains pinned by the accepted lockfile.

## Openlab HTTP and WebSocket adapters (R8)

`bash scripts/tests.sh test/lib/http_websocket_dependency_test.rb --seed 12345`

HTTP checks use the real Openlab client/controller with stubbed transport: parameters,
methods, raw versus parsed JSON/BOM/text/XML, errors/timeouts, relative redirects,
TLS peer-verification configuration and rejection of an absolute different-host path.
The HTTParty absolute-path guard does not establish a cross-host redirect policy or
scheme/port isolation; the application builds fixed Openlab paths. No bypass option is enabled.
WebSocket checks connect real client frames to ActionCable's actual ClientSocket/Stream
adapter using in-memory transport callbacks. They cover negotiation, text/binary,
ping/pong, close and bounded invalid/oversize input. The new driver emits binary Strings;
ActionCable's outgoing Array API remains supported. No custom application channels or
consumer usage were found, so this is a framework contract rather than an application journey.

## Combined contribution qualification

Run the final combined checks on one recorded commit, after all implementation and
useful documentation changes. Use the Ruby/Node versions in the repository, frozen
Bundler/Yarn lockfiles, Linux native tools and disposable PostgreSQL/Redis/Elasticsearch
services. Inject Stripe/OAuth/OIDC test settings outside Git. Verify database destinations
before loading the SQL structure or fixtures, and build the Elasticsearch stats mappings.

```bash
BUNDLE_FROZEN=true bundle _2.4.3_ install --local
yarn install --frozen-lockfile --non-interactive --offline --production=false
bash scripts/tests.sh --seed 12345
yarn test --ci --runInBand
yarn lint
yarn tsc --noEmit --project tsconfig.json
yarn tsc --noEmit --project tsconfig.dev.json
yarn test:dependencies
yarn test:build-dependencies
yarn test:http-dependencies
bundle _2.4.3_ exec rubocop --format simple
RAILS_ENV=production NODE_ENV=production bundle _2.4.3_ exec rails assets:precompile
```

The offline installation commands need the complete verified caches. A missing artifact
is a setup blocker, not proof that a network install or a different resolution passed.
Record each command, exit code, source tree and scope. Keep full-suite failures separate
from isolated passing checks, any diagnostic bootstrap and pre-existing baseline errors.
Run the changed Ruby files with the same repository cops for the pre-commit scope.

After compilation, exercise the actual HTTP modules and affected reservation, invoice,
calendar, notification, authentication and upload paths with synthetic data. Real payment
and IdP accounts are unnecessary: repository fixtures, local test services and protocol
fixtures provide the boundaries. A framework WebSocket test is not an application channel
journey when the ActionCable engine is disabled.

When comparing advisory counts before and after an update, use one advisory snapshot for
every state and deduplicate shared transitive findings. A version match alone does not
establish application exploitability. Keep failed observations visible rather than
rewriting them as successful. A later code or dependency change requires rerunning the
affected checks.
