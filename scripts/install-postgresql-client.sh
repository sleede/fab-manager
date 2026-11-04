#!/usr/bin/env bash
# Matching client utilities are independent from the libpq used by the Ruby driver.
set -euo pipefail
. /etc/os-release
[[ "$ID" == debian && "$VERSION_CODENAME" == bookworm ]] || { echo 'Pinned PGDG packages require Debian bookworm.' >&2; exit 1; }
install -d -m 0755 /usr/share/postgresql-common/pgdg
curl --fail --silent --show-error --location https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc
printf '%s\n' 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main' > /etc/apt/sources.list.d/pgdg.list
# Keep the later application-image apt upgrade on the tested PostgreSQL packages.
cat > /etc/apt/preferences.d/fabmanager-postgresql <<'PIN'
Package: postgresql-client-18 libpq5 libpq-dev
Pin: version 18.6-1.pgdg12+2
Pin-Priority: 1001
PIN
apt-get update
apt-get install -y --no-install-recommends postgresql-client-18=18.6-1.pgdg12+2 libpq5=18.6-1.pgdg12+2 libpq-dev=18.6-1.pgdg12+2
for tool in psql pg_dump pg_restore; do
  "/usr/lib/postgresql/18/bin/$tool" --version
done
