#!/usr/bin/env bash
# No implicit initialization after migration or an interrupted first start.
set -euo pipefail
data="${PGDATA:-/var/lib/postgresql/18/docker}"
[[ "$data" == /var/lib/postgresql/18/docker ]] || { echo 'Unexpected PGDATA.' >&2; exit 1; }
[[ ! -e /var/lib/postgresql/PG_VERSION && ! -e /var/lib/postgresql/data/PG_VERSION ]] ||
  { echo 'Legacy PostgreSQL data detected. Use the logical migration.' >&2; exit 1; }
if [[ -s "$data/PG_VERSION" ]]; then
  [[ "$(cat "$data/PG_VERSION")" == 18 ]] || { echo 'PG_VERSION is not 18.' >&2; exit 1; }
else
  [[ "${FM_PG_INITIALIZE:-0}" == 1 && -d /run/fm-pg-guard && ! -e /run/fm-pg-guard/initialized ]] ||
    { echo 'Expected database is missing or initialization was interrupted. Refusing an empty replacement.' >&2; exit 1; }
  [[ ! -d /var/lib/postgresql/base && ! -d /var/lib/postgresql/global ]] ||
    { echo 'Unrecognized existing cluster layout.' >&2; exit 1; }
  (umask 077; printf '%s\n' initializing > /run/fm-pg-guard/initialized)
fi
exec /usr/local/bin/docker-entrypoint.sh "$@"
