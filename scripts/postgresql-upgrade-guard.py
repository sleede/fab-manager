#!/usr/bin/env python3
"""Read-only gate before the general installer/upgrade can start containers."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

class Notice(Exception):
    """A database this gate cannot verify; the application upgrade does not change it."""

def call(args):
    r = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if r.returncode:
        raise RuntimeError("Cannot inspect the existing installation; no database service was started.")
    return r.stdout.decode()

def check(compose, project=None, selected_service=None, database=None):
    # Only positive evidence of an unsafe PostgreSQL 18 state refuses the upgrade. upgrade.sh
    # recreates the application alone, so databases this gate cannot verify are left unchanged.
    if subprocess.run(["docker", "compose", "version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
        raise Notice("Docker Compose v2 is unavailable; the PostgreSQL storage was not inspected.")
    base = ["docker", "compose"]
    if project:
        base += ["-p", project]
    for path in compose:
        base += ["-f", str(Path(path).resolve())]
    config = json.loads(call(base + ["config", "--format", "json"]))
    services = [(name, spec) for name, spec in config["services"].items()
                if spec.get("image", "").split("/")[-1].startswith("postgres:") and not spec.get("profiles")
                and (not selected_service or name == selected_service)]
    if len(services) != 1:
        raise Notice("No single local PostgreSQL service: an external or custom database was not inspected.")
    name, service = services[0]
    cid = call(base + ["ps", "-q", name]).strip()
    if not cid or "\n" in cid:
        raise RuntimeError("Expected PostgreSQL is not running. Refusing to start or initialize an unknown database.")
    info = json.loads(call(["docker", "inspect", cid]))[0]
    application_name = os.environ.get("FM_APP_SERVICE")
    application = config["services"].get(application_name, {}) if application_name else {}
    app_environment = application.get("environment", {})
    if app_environment.get("DATABASE_URL"):
        raise Notice("The application uses DATABASE_URL; that database was not inspected.")
    host = app_environment.get("POSTGRES_HOST")
    aliases = {name, info["Name"].lstrip("/")}
    for network in info["NetworkSettings"]["Networks"].values():
        aliases.update(network.get("Aliases") or [])
        aliases.add(network.get("IPAddress"))
    if host and host not in aliases:
        raise Notice("The application PostgreSQL host differs from the local service; that database was not inspected.")

    # Only reads the existing container's configured credential file; never logs its value.
    probe = r"""set -eu
if [ -n "\${POSTGRES_PASSWORD_FILE:-}" ]; then PGPASSWORD=$(cat "$POSTGRES_PASSWORD_FILE"); export PGPASSWORD
elif [ -n "\${POSTGRES_PASSWORD:-}" ]; then PGPASSWORD=$POSTGRES_PASSWORD; export PGPASSWORD; fi
psql -X -qAt -v ON_ERROR_STOP=1 -h 127.0.0.1 -U "\${POSTGRES_USER:-postgres}" -d postgres \
-c "SELECT current_setting('server_version_num'),current_setting('data_directory');"
"""
    # The backslash only protects this source template; the shell receives ordinary expansion.
    probe = probe.replace("\\$", "$")
    values = call(["docker", "exec", cid, "sh", "-c", probe]).strip().split("|")
    if len(values) != 2:
        raise RuntimeError("Cannot identify the connected PostgreSQL server and PGDATA.")
    version, data = values
    if int(version) < 180000:
        # This release still supports the current server; the migration needs its new application image first.
        raise Notice("PostgreSQL " + version + " is kept; it is end-of-life. After this upgrade, plan the "
                     "logical migration described in doc/postgresql_migration.md.")
    if int(version) >= 190000:
        raise RuntimeError("PostgreSQL " + version + " is newer than the supported major version 18; qualify it explicitly.")
    if version != "180006":
        print("NOTICE: PostgreSQL " + version + " differs from the tested 18.6 release.", file=sys.stderr)
    if call(["docker", "exec", cid, "cat", data + "/PG_VERSION"]).strip() != "18":
        raise RuntimeError("Connected server and volume PG_VERSION disagree.")
    if data != "/var/lib/postgresql/18/docker" or not any(
            m["Destination"] == "/var/lib/postgresql" for m in info["Mounts"]):
        raise RuntimeError("Unsupported PG18 storage layout: audit the actual PGDATA mount before upgrading.")
    if service.get("ports") or any((info["HostConfig"].get("PortBindings") or {}).values()):
        raise RuntimeError("PostgreSQL must stay on its private network.")
    if service.get("environment", {}).get("POSTGRES_HOST_AUTH_METHOD") == "trust":
        raise RuntimeError("Final PostgreSQL configuration must use password authentication.")
    database = database or os.environ.get("FM_POSTGRES_DB") or app_environment.get("POSTGRES_DB") or "fablab_production"
    if not database or any(character in database for character in "\n\r\0"):
        raise RuntimeError("Select the actual application database explicitly.")
    # Database is passed as a positional shell argument, never interpolated into SQL.
    verify = probe[:probe.index("psql -X")] + """psql -X -qAt -v ON_ERROR_STOP=1 -h 127.0.0.1 -U "${POSTGRES_USER:-postgres}" -d "$1" \\
-c "SELECT (SELECT count(*)>0 FROM public.schema_migrations) AND (SELECT count(*)>0 FROM public.users);"
"""
    if call(["docker", "exec", cid, "sh", "-c", verify, "sh", database]).strip() != "t":
        raise RuntimeError("Expected Fab-manager schema/data is absent; refusing an empty replacement.")
    for binary in ["psql", "pg_dump", "pg_restore"]:
        if not re.search(r" 18\.\d+ ", call(["docker", "exec", cid, binary, "--version"])):
            raise RuntimeError("PostgreSQL client tools must match the major version 18 server.")
    print("PostgreSQL 18 server, volume and private storage agree; general application upgrade may proceed.")

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--compose", action="append")
    p.add_argument("--project")
    p.add_argument("--service")
    p.add_argument("--database")
    a = p.parse_args()
    files = a.compose or os.environ.get("COMPOSE_FILE", "docker-compose.yml").split(os.pathsep)
    try:
        check(files, a.project or os.environ.get("COMPOSE_PROJECT_NAME"), a.service or os.environ.get("FM_POSTGRES_SERVICE"), a.database)
    except Notice as notice:
        print("NOTICE: " + str(notice) + " The application upgrade leaves the database service unchanged.", file=sys.stderr)
        return 0
    except (RuntimeError, ValueError, KeyError) as error:
        print("STOP: " + str(error), file=sys.stderr)
        return 1
    return 0
if __name__ == "__main__":
    sys.exit(main())
