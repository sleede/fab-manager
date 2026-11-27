#!/usr/bin/env bash
# Disposable PostgreSQL test credentials only; never overwrite an existing directory.
set -euo pipefail
umask 077
[[ $# == 1 && -n "$1" ]] || { echo 'Usage: prepare.sh NEW_PRIVATE_DIRECTORY' >&2; exit 2; }
[[ $EUID == 0 ]] || { echo 'Run in Linux as root to assign PostgreSQL UID 999 ownership.' >&2; exit 2; }
target=$(realpath -m -- "$1")
repository=$(realpath "$(dirname "${BASH_SOURCE[0]}")/../..")
[[ "$target" != / && "$target" != "$repository" && "$target" != "$repository/"* && ! -e "$target" ]] || {
  echo 'Use a new private directory outside the repository; existing material is retained.' >&2; exit 2;
}
mkdir -p "$target/certificates"
openssl rand -hex 32 > "$target/password"
openssl genrsa -out "$target/certificates/ca.key" 2048 2>/dev/null
openssl req -x509 -new -sha256 -days 30 -key "$target/certificates/ca.key" -subj /CN=FabManager-PG-Compatibility-Test-CA -out "$target/certificates/ca.crt"
for role in pg96 pg18; do
  directory=$target/certificates/$role
  mkdir "$directory"
  openssl genrsa -out "$directory/server.key" 2048 2>/dev/null
  openssl req -new -key "$directory/server.key" -subj "/CN=$role" -out "$directory/server.csr"
  printf 'subjectAltName=DNS:%s,DNS:localhost,IP:127.0.0.1\nextendedKeyUsage=serverAuth\n' "$role" > "$directory/extensions"
  openssl x509 -req -sha256 -days 30 -in "$directory/server.csr" -CA "$target/certificates/ca.crt" -CAkey "$target/certificates/ca.key" -CAcreateserial -extfile "$directory/extensions" -out "$directory/server.crt" 2>/dev/null
  openssl verify -CAfile "$target/certificates/ca.crt" "$directory/server.crt" >/dev/null
  chown -R 999:999 "$directory"
  chmod 0600 "$directory/server.key"
done
chmod 0600 "$target/password" "$target/certificates/ca.key"
printf '%s\n' 'Private test material created. Keep it outside Git; do not use it in production.'
