#!/usr/bin/env python3
"""Fail-closed logical PostgreSQL migration; requires local Linux Docker/Compose."""
import argparse
import datetime
import decimal
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import shlex
import subprocess
import sys
import time

IMAGE = "postgres:18.6-bookworm@sha256:5c4783a8cc3f0074912164f94dfa1be4e043438f0f707cf968d7af9a0d31a2c8"
class Refusal(RuntimeError):
    pass

def require(ok, message):
    if not ok:
        raise Refusal(message)

def identifier(value):
    return '"' + value.replace('"', '""') + '"'

def literal(value):
    return "'" + str(value).replace("'", "''") + "'"

def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode()

def sha(data):
    return hashlib.sha256(data).hexdigest()


def copy_text(line):
    """Remove one COPY text escaping layer before parsing the JSON value."""
    escapes = {b"b": b"\b", b"f": b"\f", b"n": b"\n", b"r": b"\r", b"t": b"\t", b"v": b"\v", b"\\": b"\\"}
    def decode(match):
        value = match.group(1)
        if value[:1] in b"01234567":
            return bytes([int(value, 8)])
        if value.startswith(b"x"):
            return bytes([int(value[1:], 16)])
        return escapes.get(value, value)
    return re.sub(rb"\\([0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)", decode, line.rstrip(b"\n"))

def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()

def write(path, value):
    path = Path(path)
    temporary = path.with_name(path.name + ".tmp")
    with open(temporary, "w", encoding="utf-8", opener=lambda p, f: os.open(p, f, 0o600)) as stream:
        stream.write(value if isinstance(value, str) else json.dumps(value, indent=2, sort_keys=True) + "\n")
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)

def command(args, data=None, output=None, env=None, strict=False, input_file=None):
    result = subprocess.run(args, input=data, stdin=input_file, stdout=output or subprocess.PIPE,
                            stderr=subprocess.PIPE, env=env, timeout=1800)
    # Do not log argv, SQL, or server diagnostics: they can contain passwords/data.
    require(result.returncode == 0, "Command failed: " + Path(args[0]).name +
            " (exit " + str(result.returncode) + "); checkpoint remains incomplete.")
    require(not strict or not result.stderr.strip(),
            "Database command produced diagnostics. Investigate privately; warnings are not accepted.")
    return result.stdout or b""

def absolute(value):
    p = Path(value)
    require(p.is_absolute() and str(p) == str(p.resolve()), "Use canonical absolute paths without symlinks.")
    return p

def secret_file(value):
    p = absolute(value)
    require(p.is_file() and p.stat().st_mode & 0o077 == 0, "Credential files need mode 0600/0400.")
    return p

def file_hash(path):
    h = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()

class Migration:
    def __init__(self, plan_path):
        self.plan = json.loads(absolute(plan_path).read_text())
        self.root = absolute(self.plan["state_dir"])
        self.plan_hash = sha(canonical(self.plan))
        self.state = {}
        self.source, self.target = self.plan["source"], self.plan["target"]
        self.database, self.project = self.plan["database"], self.plan["project"]
        for value in [self.project, self.target["service"], self.target["container"], self.plan["id"]]:
            require(re.fullmatch(r"[a-z][a-z0-9_-]{2,60}", value), "Unsafe resource identifier.")
        require(self.database not in ["postgres", "template0", "template1"], "Select an application database.")
        require(self.target["image"] == IMAGE, "Use the tested PostgreSQL image and digest.")
        require(os.name == "posix" and os.geteuid() == 0, "Run as root on the Linux Docker host.")
        require(not os.environ.get("DOCKER_HOST"), "Remote Docker endpoints are unsupported.")
        context = json.loads(command(["docker", "context", "inspect"]))[0]
        require(context["Endpoints"]["docker"]["Host"].startswith("unix://"), "Use the local Docker socket.")
        self.compose = ["docker", "compose", "--project-name", self.project]
        for filename in self.plan["compose_files"]:
            self.compose += ["--file", str(absolute(filename))]
        self.selected = ["docker", "compose", "--project-name", self.project,
                         "--file", str(self.root / "compose.postgresql18.json")]

    def assert_target_available(self):
        occupied = command(["docker", "ps", "-aq",
            "--filter", "label=com.docker.compose.project=" + self.project,
            "--filter", "label=com.docker.compose.service=" + self.target["service"]]).decode().strip()
        require(not occupied, "Target Compose service already has a container; choose a new service explicitly.")

    def inspect(self, name):
        return json.loads(command(["docker", "inspect", name]))[0]

    def assert_target_tls_readable(self):
        # A server that cannot load its certificate fails during restore, with the source already fenced.
        try:
            command(["docker", "run", "--rm", "--network", "none", "--user", "999:999", "--entrypoint", "sh",
                     "--mount", "type=bind,src=" + self.target["tls_dir"] + ",dst=/certs,readonly", IMAGE,
                     "-c", "test -r /certs/server.crt && test -r /certs/server.key"])
        except Refusal:
            raise Refusal("The target server UID 999 cannot read the TLS certificate and key; fix the directory permissions.")

    @staticmethod
    def assert_application_reads_password_file(image_id):
        # The target configuration passes the database secret only as POSTGRES_PASSWORD_FILE.
        settings = command(["docker", "run", "--rm", "--network", "none", "--entrypoint", "cat", image_id,
                            "/usr/src/app/config/database.yml"]).decode()
        require("POSTGRES_PASSWORD_FILE" in settings,
                "The application image cannot read POSTGRES_PASSWORD_FILE: upgrade the application on the "
                "current server first, then migrate.")

    def effective(self):
        # Resolved environment can contain secrets; never print it.
        return json.loads(command(self.compose + ["config", "--format", "json"]))

    def source_endpoint(self, fenced=False):
        return dict(container=self.state.get("source_id", self.source["container"]),
                    hostname=self.source["hostname"],
                    user=self.state["fence_role"] if fenced else self.source["admin"],
                    password_file=str(self.root / "source.pgpass") if fenced else str(secret_file(self.source["password_file"])),
                    sslmode=self.source["sslmode"], ca_file=self.source.get("ca_file"))

    def target_endpoint(self, runtime=False):
        return dict(container=self.target["container"], hostname=self.target["service"],
                    user=self.plan["app_role"] if runtime else "postgres",
                    password_file=str(self.root / ("runtime.pgpass" if runtime else "target.pgpass")),
                    sslmode="verify-full", ca_file=self.target["ca_file"])

    def client(self, ep):
        args = ["docker", "run", "--rm", "-i", "--network", "container:" + ep["container"],
                "--mount", "type=bind,src=" + ep["password_file"] + ",dst=/run/pgpass,readonly",
                "-e", "PGPASSFILE=/run/pgpass", "-e", "PGHOST=" + ep["hostname"], "-e", "PGHOSTADDR=127.0.0.1",
                "-e", "PGUSER=" + ep["user"], "-e", "PGSSLMODE=" + ep["sslmode"]]
        if ep.get("ca_file"):
            args += ["--mount", "type=bind,src=" + ep["ca_file"] + ",dst=/run/ca.crt,readonly",
                     "-e", "PGSSLROOTCERT=/run/ca.crt"]
        return args

    def sql(self, ep, query, database=None, readonly=False, output=None):
        options = "-c timezone=UTC -c extra_float_digits=3"
        if readonly:
            options += " -c default_transaction_read_only=on"
        args = self.client(ep) + ["-e", "PGDATABASE=" + (database or self.database),
               "-e", "PGOPTIONS=" + options, IMAGE, "psql", "-X", "-qAt", "-v", "ON_ERROR_STOP=1"]
        return command(args, data=query.encode(), output=output, strict=True).decode()

    def rows(self, ep, query, database=None):
        return json.loads(self.sql(ep, "SELECT COALESCE(json_agg(q),'[]'::json) FROM (" + query + ") q;",
                                   database, True))

    def utility(self, ep, args, output=None, data=None, input_file=None):
        return command(self.client(ep) + [IMAGE] + args, output=output, data=data, strict=True, input_file=input_file)

    def hook(self, name, ep=None):
        environment = os.environ.copy()
        environment.update(FM_PG_PHASE=name, FM_PG_ENDPOINT=json.dumps(ep or {}), FM_PG_DATABASE=self.database)
        # Hooks output JSON counts/digests only. Endpoint contains paths, never passwords.
        return json.loads(command(self.plan[name], env=environment, strict=True))

    def preflight(self):
        require(not self.root.exists(), "State already exists. Use status or the next phase with the same plan.")
        require(self.root.parent.is_dir() and os.access(self.root.parent, os.W_OK), "State parent is not writable.")
        target_path = absolute(self.target["data_path"])
        require(not target_path.exists(), "Target must not exist; never reuse a partial/user target.")
        require(target_path.parent.is_dir() and os.access(target_path.parent, os.W_OK), "Target parent is not writable.")
        require(not self.root.is_relative_to(target_path) and not target_path.is_relative_to(self.root),
                "State and target must be separate sibling locations.")
        self.assert_target_available()
        config = self.effective()
        services = config["services"]
        require(self.source["service"] in services and self.target["service"] not in services, "Ambiguous services.")
        source_spec = services[self.source["service"]]
        require(not any(source_spec.get(key) for key in ["entrypoint", "configs", "secrets", "network_mode", "healthcheck"]),
                "Custom database entrypoint/config/secrets/network/healthcheck need an explicit target adaptation.")
        source_command = source_spec.get("command") or ["postgres"]
        require(isinstance(source_command, list) and source_command[0] == "postgres"
                and (len(source_command)-1) % 2 == 0
                and all(source_command[i] == "-c" for i in range(1, len(source_command), 2)),
                "Only explicit postgres -c settings can be transferred automatically.")
        for setting in source_command[2::2]:
            require("=" in setting and setting.split("=", 1)[0] not in ["data_directory", "hba_file", "config_file", "port"],
                    "Custom database storage/config/port requires a separate adaptation.")
        for name in self.plan["producers"]:
            require(not services[name].get("environment", {}).get("DATABASE_URL"),
                    "Resolve DATABASE_URL explicitly before migration.")

        require(set(services) == {self.source["service"]} | set(self.plan["producers"]) | set(self.plan["non_producers"]),
                "Classify every Compose service as source, producer, or non-producer.")
        require(not set(self.plan["producers"]) & set(self.plan["non_producers"]), "Service classifications overlap.")
        require(not self.plan.get("application_service") or self.plan["application_service"] in self.plan["producers"],
                "application_service must be one of the declared producers.")
        require(self.plan["external_producers_stopped"], "Identify stopped host/external producers and schedulers.")
        for hook in ["health_command", "quiet_command", "queue_command", "business_command"]:
            require(isinstance(self.plan[hook], list) and self.plan[hook], "Missing explicit " + hook)
        producers = {}
        for name in self.plan["producers"]:
            cid = command(self.compose + ["ps", "--all", "-q", name]).decode().strip()
            require(cid and "\n" not in cid, "Each producer must resolve to exactly one existing container.")
            producer = self.inspect(cid)
            producers[name] = {"container_id": producer["Id"], "image_id": producer["Image"],
                               "running": producer["State"]["Running"]}
        if self.plan.get("application_service"):
            self.assert_application_reads_password_file(producers[self.plan["application_service"]]["image_id"])
        info = self.inspect(self.source["container"])
        require(info["State"]["Running"], "Source is stopped.")
        configured_image = json.loads(command(["docker", "image", "inspect", source_spec["image"]]))[0]["Id"]
        require(configured_image == info["Image"], "Configured source image differs from the running server; resolve it before migration.")
        require(info["Config"]["Cmd"] == source_command, "Effective source command differs from the running server.")
        actual_environment = dict(value.split("=", 1) for value in info["Config"]["Env"] if "=" in value)
        require(all(actual_environment.get(key) == value for key, value in source_spec.get("environment", {}).items()),
                "Effective source environment differs from the running server.")
        allowed_mounts = {self.source["mount_destination"]}
        password_mount = source_spec.get("environment", {}).get("POSTGRES_PASSWORD_FILE")
        if password_mount:
            allowed_mounts.add(password_mount)
        for setting in source_command[2::2]:
            key, value = setting.split("=", 1)
            if key in ["ssl_cert_file", "ssl_key_file", "ssl_ca_file"]:
                allowed_mounts.add(str(Path(value).parent))
                allowed_mounts.add(value)
        require(all(mount["Destination"] in allowed_mounts for mount in info["Mounts"]) and
                all(mount["target"] in allowed_mounts for mount in source_spec.get("volumes", [])),
                "Unmapped database mount: supply a separate reviewed target adaptation.")

        labels = info["Config"]["Labels"]
        require(labels.get("com.docker.compose.project") == self.project and
                labels.get("com.docker.compose.service") == self.source["service"], "Source container/project/service mismatch.")
        require(not any(info["HostConfig"].get("PortBindings", {}).values()) and
                not services[self.source["service"]].get("ports"), "Source exposes database ports; isolate it first.")
        mounts = [m for m in info["Mounts"] if m["Destination"] == self.source["mount_destination"]]
        require(len(mounts) == 1, "Select the exact source PGDATA mount.")
        mount = mounts[0]
        actual = mount.get("Name") if mount["Type"] == "volume" else mount["Source"]
        require(self.source["pgdata"] == self.source["mount_destination"] or
                self.source["pgdata"].startswith(self.source["mount_destination"] + "/"), "PGDATA is outside the selected mount.")
        require(not any(m["Destination"].startswith(self.source["pgdata"] + "/") for m in info["Mounts"]),
                "Nested PGDATA mounts need a separate storage plan.")
        require(mount["Type"] == self.source["mount_type"] and actual == self.source["mount_source"],
                "Selected source storage differs from the running container.")
        require(not target_path.is_relative_to(Path(mount["Source"])), "Target overlaps source storage.")
        ids = command(["docker", "ps", "-aq"]).decode().split()
        if ids:
            for existing in json.loads(command(["docker", "inspect", *ids])):
                require(existing["Name"].lstrip("/") != self.target["container"], "Target container already exists.")
                require(all(Path(m["Source"]) != target_path for m in existing["Mounts"]), "Target storage is occupied.")
        ep = self.source_endpoint()
        for auxiliary in ["postgres", "template1"]:
            require(not self.rows(ep, "SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace "
                                  "WHERE n.nspname NOT IN ('pg_catalog','information_schema') AND n.nspname !~ '^pg_toast' "
                                  "AND c.relkind IN ('r','S','v','m','f')", auxiliary),
                    "User objects exist outside the selected database; use a multi-database plan.")
        require(not self.rows(ep, "SELECT setdatabase,setrole FROM pg_db_role_setting WHERE setdatabase<>0 AND setrole<>0"),
                "Database-specific role settings need an explicit restoration mapping.")
        require(not self.rows(ep, "SELECT srvname FROM pg_foreign_server"),
                "Foreign servers/user mappings require a separate credentials and connectivity plan.")
        meta = self.rows(ep, "SELECT current_setting('server_version_num')::int AS version,"
                         "current_setting('data_directory') data_directory,current_setting('hba_file') hba_file,"
                         "current_setting('ssl') ssl,pg_is_in_recovery() recovery,pg_database_size(current_database()) bytes")[0]
        require(90600 <= meta["version"] < 100000 and not meta["recovery"], "Source must be a PostgreSQL 9.6 primary.")
        require(meta["data_directory"] == self.source["pgdata"], "Effective PGDATA differs from the plan.")
        require(meta["hba_file"].startswith(meta["data_directory"] + "/"), "External HBA needs a separate reviewed procedure.")
        version = command(["docker", "exec", info["Id"], "cat", meta["data_directory"] + "/PG_VERSION"]).decode().strip()
        require(version == "9.6", "Server version and volume PG_VERSION disagree.")
        require(command(["docker", "exec", info["Id"], "readlink", "-f", meta["hba_file"]]).decode().strip() == meta["hba_file"],
                "Symlinked HBA needs a separate filesystem procedure.")
        command(["docker", "exec", "--user", "postgres", info["Id"], "test", "-w", meta["hba_file"]])
        require(meta["ssl"] != "on" or ep["sslmode"] == "verify-full", "Preserve TLS with verify-full.")
        require(ep["sslmode"] in ["verify-full", "prefer"], "Unsupported source TLS policy.")
        for tool in ["psql", "pg_dump", "pg_dumpall", "pg_restore"]:
            version = command(["docker", "run", "--rm", "--network", "none", IMAGE, tool, "--version"]).decode()
            require(" 18.6 " in version or version.rstrip().endswith(" 18.6"), "Client version mismatch.")
        require(not self.rows(ep, "SELECT datname FROM pg_database WHERE NOT datistemplate AND "
                              "datname NOT IN ('postgres'," + literal(self.database) + ")"), "Other application databases require a multi-database plan.")
        require(not self.rows(ep, "SELECT oid FROM pg_tablespace WHERE spcname NOT IN ('pg_default','pg_global')"),
                "Custom tablespaces need explicit mapping.")
        require(not self.rows(ep, "SELECT gid FROM pg_prepared_xacts"), "Resolve prepared transactions first.")
        require(not self.rows(ep, "SELECT slot_name FROM pg_replication_slots"), "Replication slots require a separate plan.")
        roles = self.rows(ep, "SELECT rolname,rolsuper,rolinherit,rolcreaterole,rolcreatedb,rolcanlogin,"
                          "rolreplication,rolbypassrls,rolconnlimit,rolvaliduntil::text,rolconfig "
                          "FROM pg_roles WHERE rolname !~ '^pg_' ORDER BY rolname")
        require(any(r["rolname"] == self.source["admin"] and r["rolsuper"] for r in roles), "Source administrator must be explicit.")
        require(self.plan["app_role"] in [r["rolname"] for r in roles if r["rolcanlogin"]], "Application login is absent.")
        require(set(r["rolname"] for r in roles if r["rolsuper"]) == set(self.plan["approved_superusers"]),
                "Review every privileged source role.")
        require(set(r["rolname"] for r in roles if r["rolcanlogin"] and r["rolname"] != "postgres") ==
                set(self.plan["login_password_files"]), "Provide rotated secrets for every other login role.")
        require(not any(re.search(r"password|secret|token", setting, re.I) for role in roles for setting in role["rolconfig"] or []),
                "Sensitive role settings need a separate protected globals procedure.")
        for path in self.plan["login_password_files"].values():
            secret_file(path)
        extensions = self.rows(ep, "SELECT extname,extversion FROM pg_extension ORDER BY extname")
        require(set(x["extname"] for x in extensions) == set(self.plan["extensions"]), "Unknown/unapproved extension.")
        require(self.plan["collation_review"], "Record locale/libc changes and sorting/business checks.")
        for path in [self.target["ca_file"], self.target["tls_dir"] + "/server.crt", self.target["tls_dir"] + "/server.key"]:
            require(absolute(path).is_file(), "Target TLS material is missing.")
        command(["openssl", "verify", "-CAfile", self.target["ca_file"], "-verify_hostname",
                 self.target["service"], self.target["tls_dir"] + "/server.crt"])
        key = Path(self.target["tls_dir"]) / "server.key"
        require(key.stat().st_uid == 999 and key.stat().st_mode & 0o077 == 0,
                "Target TLS private key must belong to postgres UID 999 with mode 0600.")
        certificate_key = command(["openssl", "x509", "-in", self.target["tls_dir"] + "/server.crt", "-pubkey", "-noout"])
        require(certificate_key == command(["openssl", "pkey", "-in", str(key), "-pubout"]), "TLS key/certificate mismatch.")
        self.assert_target_tls_readable()
        source_bytes = int(command(["docker", "exec", info["Id"], "du", "-sb", meta["data_directory"]]).split()[0])
        required = max(source_bytes, meta["bytes"]) * 5 + 1024 ** 3
        # Source remains allocated: budget uncompressed dump, target heap/index/WAL, margin on each filesystem.
        require(all(shutil.disk_usage(p).free >= required for p in [self.root.parent, target_path.parent]),
                "Insufficient space for source retained + dump + target + WAL/index margin.")
        require(self.hook("health_command", ep).get("healthy") is True, "Initial application health check failed.")
        return dict(source_id=info["Id"], source_image=info["Image"], source_mount=mount, source_meta=meta,
                    source_bytes=source_bytes, required_free_bytes=required, roles=roles, extensions=extensions, producers=producers,
                    source_hba_mode=command(["docker", "exec", info["Id"], "stat", "-c", "%a", meta["hba_file"]]).decode().strip(),
                    memberships=self.rows(ep, "SELECT r.rolname AS role,m.rolname AS member,a.admin_option FROM pg_auth_members a "
                        "JOIN pg_roles r ON r.oid=a.roleid JOIN pg_roles m ON m.oid=a.member "
                        "WHERE r.rolname !~ '^pg_' OR m.rolname !~ '^pg_' ORDER BY 1,2"),
                    config=config, config_hash=sha(canonical(config)),
                    source_libc=command(["docker", "exec", info["Id"], "getconf", "GNU_LIBC_VERSION"]).decode().strip(),
                    target_libc=command(["docker", "run", "--rm", "--network", "none", IMAGE,
                                         "getconf", "GNU_LIBC_VERSION"]).decode().strip())

    def save(self):
        write(self.root / "state.json", self.state)

    def prepare(self):
        report = self.preflight()
        self.root.mkdir(mode=0o700)
        self.state = {k: v for k, v in report.items() if k != "config"}
        self.state.update(plan_hash=self.plan_hash, phase="prepared", created_at=now(),
                          fence_role="fm_migrate_" + secrets.token_hex(6), writes_resumed=False)
        write(self.root / "plan.json", self.plan)
        source_config = json.loads(json.dumps(report["config"]))
        for name, producer in report["producers"].items():
            source_config["services"][name]["image"] = producer["image_id"]
        write(self.root / "source.compose.json", source_config)
        for number, path in enumerate(self.plan["compose_files"]):
            write(self.root / ("original-" + str(number) + ".yml"), Path(path).read_text())
        write(self.root / "source.pg_hba.conf", command(["docker", "exec", self.state["source_id"], "cat",
                                                       self.state["source_meta"]["hba_file"]]).decode())
        admin, fence = secrets.token_hex(32), secrets.token_hex(32)
        write(self.root / "admin-password", admin + "\n")
        write(self.root / "fence-password", fence + "\n")
        write(self.root / "source.pgpass", "*:*:*:" + self.state["fence_role"] + ":" + fence + "\n")
        write(self.root / "target.pgpass", "*:*:*:postgres:" + admin + "\n")
        app = admin if self.plan["app_role"] == "postgres" else Path(
            self.plan["login_password_files"][self.plan["app_role"]]).read_text().strip()
        write(self.root / "runtime-password", app + "\n")
        write(self.root / "runtime.pgpass", "*:*:*:" + self.plan["app_role"] + ":" +
              app.replace("\\", "\\\\").replace(":", "\\:") + "\n")
        os.chown(self.root / "admin-password", 999, 999)
        write(self.root / "target-entrypoint.sh", (Path(__file__).resolve().parent.parent / "docker/postgresql-entrypoint.sh").read_text())
        (self.root / "target-guard").mkdir(mode=0o700)
        self.save()

    def load(self):
        require(self.root.is_dir() and self.root.stat().st_mode & 0o077 == 0, "State must be private (0700).")
        self.state = json.loads((self.root / "state.json").read_text())
        require(self.state["plan_hash"] == self.plan_hash, "Plan changed. Do not change resources during a run.")

    def transition(self, expected, operation):
        require(self.state["phase"] in expected, "Phase is " + self.state["phase"] + "; expected " + ", ".join(expected))
        self.state.update(operation=operation, operation_started_at=now())
        self.save()

    def done(self, phase):
        self.state.update(phase=phase, updated_at=now())
        self.state.pop("operation", None)
        self.save()

    def assert_source(self):
        require(self.inspect(self.state["source_id"])["State"]["Running"], "Expected source container is stopped.")
        require(sha(canonical(self.effective())) == self.state["config_hash"], "Original effective Compose configuration changed.")

    def replace_hba(self, text, mode="600"):
        command(["docker", "exec", "-i", "--user", "postgres", self.state["source_id"], "sh", "-c",
                 'cat > "$1.fm-tmp" && chmod "$2" "$1.fm-tmp" && mv "$1.fm-tmp" "$1"', "sh",
                 self.state["source_meta"]["hba_file"], mode], data=text.encode())
        command(["docker", "kill", "--signal", "HUP", self.state["source_id"]])
        time.sleep(1)

    def maintenance(self):
        self.assert_source()
        self.transition(["prepared"], "maintenance")
        self.hook("quiet_command", self.source_endpoint())
        deadline = time.time() + self.plan.get("drain_timeout_seconds", 120)
        while True:
            queue = self.hook("queue_command")
            require(all(k in queue for k in ["busy", "queued", "scheduled", "retry", "dead", "sha256"]), "Incomplete queue inventory.")
            if queue["busy"] == 0:
                break
            require(time.time() < deadline, "Active jobs did not drain; producers remain quiet and Redis is retained.")
            time.sleep(2)
        write(self.root / "queue-before.json", queue)
        if self.plan["producers"]:
            command(self.compose + ["stop", "--timeout", "60", *self.plan["producers"]])
        role, password = self.state["fence_role"], (self.root / "fence-password").read_text().strip()
        self.sql(self.source_endpoint(), "CREATE ROLE " + identifier(role) + " LOGIN SUPERUSER PASSWORD " + literal(password) + ";")
        self.replace_hba("host all " + role + " 127.0.0.1/32 md5\nhost all all 0.0.0.0/0 reject\n"
                         "host all all ::/0 reject\nlocal all all reject\n")
        self.sql(self.source_endpoint(True), "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid<>pg_backend_pid();")
        self.state["fence_hba_sha256"] = sha(command(["docker", "exec", self.state["source_id"], "cat",
                                                      self.state["source_meta"]["hba_file"]]))
        write(self.root / "queue-frozen.json", self.hook("queue_command"))
        self.done("maintenance")

    def assert_fenced(self):
        self.assert_source()
        require(sha(command(["docker", "exec", self.state["source_id"], "cat",
                            self.state["source_meta"]["hba_file"]])) == self.state["fence_hba_sha256"],
                "Source connection fence changed.")
        require(not self.rows(self.source_endpoint(True), "SELECT pid FROM pg_stat_activity WHERE datname IS NOT NULL "
                              "AND usename<>" + literal(self.state["fence_role"])), "An unexpected source client is connected.")

    def fingerprint(self, ep, label):
        tables = self.rows(ep, "SELECT n.nspname AS schema,c.relname AS name,pg_get_userbyid(c.relowner) AS owner,c.relacl::text AS acl "
                           "FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE c.relkind='r' AND "
                           "n.nspname NOT IN ('pg_catalog','information_schema') AND n.nspname !~ '^pg_toast' ORDER BY 1,2")
        primary_keys = self.rows(ep, "SELECT n.nspname AS schema,c.relname AS name,"
                                 "array_agg(a.attname ORDER BY key.ordinality) AS columns FROM pg_index i "
                                 "JOIN pg_class c ON c.oid=i.indrelid JOIN pg_namespace n ON n.oid=c.relnamespace "
                                 "CROSS JOIN LATERAL unnest(i.indkey::smallint[]) WITH ORDINALITY key(attnum,ordinality) "
                                 "JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum=key.attnum WHERE i.indisprimary "
                                 "GROUP BY n.nspname,c.relname")
        primary_keys = {(item["schema"], item["name"]): item["columns"] for item in primary_keys}
        result = {"tables": []}
        for table in tables:
            name = identifier(table["schema"]) + "." + identifier(table["name"])
            scratch = self.root / "rows.private.tmp"
            with open(scratch, "wb") as output:
                self.sql(ep, "COPY (SELECT row_to_json(t)::text AS data FROM " + name +
                         ' t ORDER BY row_to_json(t)::text COLLATE "C") TO STDOUT;', readonly=True, output=output)
            h, count = hashlib.sha256(), 0
            columns = primary_keys.get((table["schema"], table["name"]), [])
            keys = self.root / "keys.private.tmp"
            with open(scratch, "rb") as stream, open(keys, "wb") as key_stream:
                for line in stream:
                    h.update(line)
                    count += 1
                    if columns:
                        row = json.loads(copy_text(line), parse_float=decimal.Decimal)
                        key_stream.write(json.dumps([row[column] for column in columns],
                            separators=(",", ":"), ensure_ascii=False, default=str).encode() + b"\n")
            command(["sort", "--output", str(keys), str(keys)], env=dict(os.environ, LC_ALL="C"))
            key_hash = file_hash(keys) if columns else None
            keys.unlink()
            scratch.unlink()  # Only this tool's temporary comparison files.
            result["tables"].append(dict(table, rows=count, sha256=h.hexdigest(),
                                         primary_key=columns, key_sha256=key_hash))
        result["sequences"] = []
        for seq in self.rows(ep, "SELECT n.nspname AS schema,c.relname AS name,pg_get_userbyid(c.relowner) AS owner,c.relacl::text AS acl "
                             "FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE c.relkind='S' ORDER BY 1,2"):
            result["sequences"].append(dict(seq, **self.rows(ep, "SELECT last_value,is_called FROM " +
                                      identifier(seq["schema"]) + "." + identifier(seq["name"]))[0]))
        queries = {
            "table_privileges": "SELECT n.nspname AS schema,c.relname AS name,pg_get_userbyid(c.relowner) AS owner,"
                                "pg_get_userbyid(a.grantor) AS grantor,CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE "
                                "pg_get_userbyid(a.grantee)::text END AS grantee,a.privilege_type,a.is_grantable "
                                "FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace CROSS JOIN LATERAL "
                                "aclexplode(COALESCE(c.relacl,acldefault('r',c.relowner))) a WHERE c.relkind='r' AND "
                                "n.nspname NOT IN ('pg_catalog','information_schema') AND n.nspname !~ '^pg_toast' "
                                "ORDER BY 1,2,4,5,6",
            "schema_acl": "SELECT nspname,pg_get_userbyid(nspowner) AS owner,nspacl::text AS acl FROM pg_namespace "
                          "WHERE nspname NOT IN ('pg_catalog','information_schema') AND nspname !~ '^pg_toast' "
                          "AND nspname !~ '^pg_temp' ORDER BY nspname",
            "default_acl": "SELECT pg_get_userbyid(defaclrole) AS owner,defaclnamespace::regnamespace::text AS schema,"
                           "defaclobjtype,defaclacl::text AS acl FROM pg_default_acl ORDER BY 1,2,3",
            "database": "SELECT pg_encoding_to_char(encoding) AS encoding,datcollate,datctype,datacl::text AS acl,"
                        "pg_get_userbyid(datdba) AS owner FROM pg_database WHERE datname=current_database()",
            "columns": "SELECT table_schema,table_name,column_name,ordinal_position,is_nullable,data_type,udt_name,"
                       "column_default,collation_name FROM information_schema.columns WHERE table_schema "
                       "NOT IN ('pg_catalog','information_schema') ORDER BY table_schema,table_name,ordinal_position",
            "indexes": "SELECT schemaname,tablename,indexname,indexdef FROM pg_indexes WHERE schemaname "
                       "NOT IN ('pg_catalog','information_schema') ORDER BY schemaname,tablename,indexname",
            "functions": "SELECT n.nspname,p.proname,pg_get_userbyid(p.proowner) AS owner,p.proacl::text AS acl,"
                         "p.prosrc,p.probin,p.provolatile,p.prosecdef,p.proisstrict,p.proretset,"
                         "p.prorettype::regtype::text AS result,p.proargtypes::regtype[]::text AS arguments "
                         "FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace "
                         "WHERE n.nspname NOT IN ('pg_catalog','information_schema') AND NOT EXISTS "
                         "(SELECT 1 FROM pg_depend d WHERE d.classid='pg_proc'::regclass AND d.objid=p.oid AND d.deptype='e') "
                         "ORDER BY n.nspname,p.proname,p.proargtypes::regtype[]::text",
            "constraints": "SELECT conname,contype,convalidated,conrelid::regclass::text AS relation,pg_get_constraintdef(oid) AS definition "
                           "FROM pg_constraint WHERE connamespace='public'::regnamespace AND contype<>'n' ORDER BY conname,conrelid::regclass::text",
            "rules": "SELECT schemaname,tablename,rulename,definition FROM pg_rules WHERE schemaname='public' ORDER BY tablename,rulename",
            "triggers": "SELECT tgname,tgrelid::regclass::text AS relation,tgenabled FROM pg_trigger WHERE NOT tgisinternal ORDER BY 2,1",
            "large_objects": "SELECT loid,pageno,md5(data) AS md5 FROM pg_largeobject ORDER BY 1,2",
            "large_object_metadata": "SELECT oid,pg_get_userbyid(lomowner) AS owner,lomacl::text AS acl FROM pg_largeobject_metadata ORDER BY oid"}
        for key, query in queries.items():
            result[key] = self.rows(ep, query)
        write(self.root / (label + "-fingerprint.json"), result)
        return result

    def export(self):
        self.assert_fenced()
        self.transition(["maintenance"], "export")
        ep = self.source_endpoint(True)
        require(not (self.root / "database.dump").exists(), "Archive exists; never overwrite a previous attempt.")
        before = self.fingerprint(ep, "source")
        write(self.root / "business-source.json", self.hook("business_command", ep))
        with open(self.root / "database.dump", "xb") as output:
            self.utility(ep, ["pg_dump", "--format=custom", "--create", "--quote-all-identifiers", "--dbname=" + self.database], output=output)
        with open(self.root / "globals.sql", "xb") as output:
            self.utility(ep, ["pg_dumpall", "--globals-only", "--no-role-passwords"], output=output)
        with open(self.root / "database.dump", "rb") as archive:
            write(self.root / "archive-toc.txt", self.utility(ep, ["pg_restore", "--list"], input_file=archive).decode())
        require(before == self.fingerprint(ep, "source-after-dump"), "Source changed while fenced.")
        self.state["archive_sha256"] = file_hash(self.root / "database.dump")
        self.done("exported")

    def target_config(self):
        config = json.loads((self.root / "source.compose.json").read_text())
        original = config["services"][self.source["service"]]
        require(not original.get("network_mode"), "Custom network mode needs explicit review.")
        config["services"][self.target["service"]] = {
            "image": IMAGE, "container_name": self.target["container"],
            "entrypoint": ["bash", "/run/fm-entrypoint.sh"],
            "environment": {"POSTGRES_PASSWORD_FILE": "/run/secrets/admin-password",
                            "POSTGRES_INITDB_ARGS": "--auth-host=scram-sha-256 --auth-local=scram-sha-256",
                            "PGDATA": "/var/lib/postgresql/18/docker", "FM_PG_INITIALIZE": "1"},
            "command": ["postgres", "-c", "ssl=on", "-c", "ssl_cert_file=/certs/server.crt",
                        "-c", "ssl_key_file=/certs/server.key", "-c", "password_encryption=scram-sha-256"],
            "volumes": [
                {"type": "bind", "source": str(self.root / "target-entrypoint.sh"), "target": "/run/fm-entrypoint.sh",
                 "read_only": True, "bind": {"create_host_path": False}},
                {"type": "bind", "source": str(self.root / "target-guard"), "target": "/run/fm-pg-guard",
                 "bind": {"create_host_path": False}},
                {"type": "bind", "source": self.target["data_path"], "target": "/var/lib/postgresql",
                 "bind": {"create_host_path": False}},
                {"type": "bind", "source": str(self.root / "admin-password"), "target": "/run/secrets/admin-password",
                 "read_only": True, "bind": {"create_host_path": False}},
                {"type": "bind", "source": self.target["tls_dir"], "target": "/certs", "read_only": True,
                 "bind": {"create_host_path": False}}],
            "networks": {name: {} for name in original.get("networks", {"default": {}})},
            "restart": "unless-stopped",
            "labels": {"org.fab-manager.pg-migration": self.plan["id"]}}
        # A production server keeps the source memory policy unless the plan explicitly sets one.
        memory_limit = self.target.get("memory_limit") or original.get("mem_limit")
        if memory_limit:
            config["services"][self.target["service"]]["mem_limit"] = memory_limit
        replaced = {"ssl", "ssl_cert_file", "ssl_key_file", "password_encryption"}
        for setting in (original.get("command") or ["postgres"])[2::2]:
            if setting.split("=", 1)[0] not in replaced:
                config["services"][self.target["service"]]["command"] += ["-c", setting]
        for key in ["shm_size", "ulimits", "logging", "stop_grace_period"]:
            if key in original:
                config["services"][self.target["service"]][key] = original[key]
        original["profiles"], original["restart"] = ["postgresql-source-preserved"], "no"
        for name in self.plan["producers"]:
            app = config["services"][name]
            environment = app.setdefault("environment", {})
            require(not environment.get("DATABASE_URL"), "Resolve DATABASE_URL explicitly before migration.")
            environment.pop("POSTGRES_PASSWORD", None)  # Original value remains only in the private source backup.
            environment.update(POSTGRES_HOST=self.target["service"], POSTGRES_USERNAME=self.plan["app_role"],
                               POSTGRES_DB=self.database, POSTGRES_PASSWORD_FILE="/run/secrets/postgresql-runtime",
                               PGSSLMODE="verify-full", PGSSLROOTCERT="/run/secrets/postgresql-ca.crt")
            app.setdefault("volumes", []).extend([
                {"type": "bind", "source": str(self.root / "runtime-password"), "target": "/run/secrets/postgresql-runtime",
                 "read_only": True, "bind": {"create_host_path": False}},
                {"type": "bind", "source": self.target["ca_file"], "target": "/run/secrets/postgresql-ca.crt",
                 "read_only": True, "bind": {"create_host_path": False}}])
            os.chmod(self.root / "runtime-password", 0o644)  # Root-only parent, readable by the selected app UID inside its container.
            deps = app.setdefault("depends_on", {})
            deps.pop(self.source["service"], None)
            deps[self.target["service"]] = {"condition": "service_started", "required": True}
        return config

    def restore(self):
        self.assert_fenced()
        self.transition(["exported"], "restore")
        require(file_hash(self.root / "database.dump") == self.state["archive_sha256"], "Archive checksum changed.")
        target_path = absolute(self.target["data_path"])
        require(not target_path.exists(), "Refusing to reimport into a partial or occupied target.")
        self.assert_target_available()
        for name in ["target-entrypoint.sh"]:
            path = self.root / name
            expected = (Path(__file__).resolve().parent.parent / "docker/postgresql-entrypoint.sh").read_text()
            if path.exists():
                require(path.read_text() == expected, "Startup guard changed since preparation.")
            else:
                write(path, expected)
        (self.root / "target-guard").mkdir(mode=0o700, exist_ok=True)
        target_path.mkdir(mode=0o700)
        os.chown(target_path, 999, 999)
        write(target_path / ".fabmanager-migration", self.plan["id"] + "\n")
        write(self.root / "compose.postgresql18.json", self.target_config())
        command(self.selected + ["up", "-d", "--no-deps", self.target["service"]])
        ep = self.target_endpoint()
        deadline = time.time() + 90
        while True:
            try:
                self.sql(ep, "SELECT 1;", "postgres")
                break
            except Refusal:
                require(time.time() < deadline, "Target did not become ready with verified TLS/password authentication.")
                time.sleep(2)
        self.sql(ep, "\n".join(self.role_statements()), "postgres")
        with open(self.root / "database.dump", "rb") as archive:
            self.utility(ep, ["pg_restore", "--exit-on-error", "--create", "--dbname=postgres"], input_file=archive)
        for extension in self.state["extensions"]:
            available = self.rows(ep, "SELECT default_version FROM pg_available_extensions WHERE name=" + literal(extension["extname"]))
            require(len(available) == 1, "Target extension is unavailable.")
            current = self.rows(ep, "SELECT extversion FROM pg_extension WHERE extname=" + literal(extension["extname"]))[0]
            if current["extversion"] != available[0]["default_version"]:
                self.sql(ep, "ALTER EXTENSION " + identifier(extension["extname"]) + " UPDATE;")
        self.sql(ep, "ANALYZE;")
        self.done("restored")

    def role_statements(self):
        """Source roles from the inspected catalog, with rotated login passwords; never globals.sql."""
        sql = ["SET password_encryption='scram-sha-256';"]
        for role in self.state["roles"]:
            name = role["rolname"]
            if name != "postgres":
                sql.append("CREATE ROLE " + identifier(name) + ";")
            attrs = []
            for key, attr in [("rolsuper", "SUPERUSER"), ("rolinherit", "INHERIT"), ("rolcreaterole", "CREATEROLE"),
                              ("rolcreatedb", "CREATEDB"), ("rolcanlogin", "LOGIN"), ("rolreplication", "REPLICATION"),
                              ("rolbypassrls", "BYPASSRLS")]:
                attrs.append(("" if role[key] else "NO") + attr)
            attrs += ["CONNECTION LIMIT " + str(role["rolconnlimit"])]
            if role["rolvaliduntil"]:
                attrs += ["VALID UNTIL " + literal(role["rolvaliduntil"])]
            if role["rolcanlogin"]:
                password = ((self.root / "admin-password") if name == "postgres" else
                            Path(self.plan["login_password_files"][name])).read_text().strip()
                attrs += ["PASSWORD " + literal(password)]
            sql.append("ALTER ROLE " + identifier(name) + " " + " ".join(attrs) + ";")
            for setting in role["rolconfig"] or []:
                key, value = setting.split("=", 1)
                sql.append("ALTER ROLE " + identifier(name) + " SET " + identifier(key) + " TO " + literal(value) + ";")
        for member in self.state["memberships"]:
            sql.append("GRANT " + identifier(member["role"]) + " TO " + identifier(member["member"]) +
                       (" WITH ADMIN OPTION" if member["admin_option"] else "") + ";")
        return sql

    @staticmethod
    def comparable(snapshot):
        result = json.loads(json.dumps(snapshot))
        # PG18 records NOT NULL in pg_constraint. Column nullability is compared separately.
        # MAINTAIN is new since PG17. Only the owner's own implicit privilege is equivalent;
        # granting it to any other role is a real ACL difference and remains a blocker.
        result["table_privileges"] = [p for p in result["table_privileges"] if not
            (p["privilege_type"] == "MAINTAIN" and p["grantee"] == p["owner"] == p["grantor"])]
        for table in result["tables"]:
            table.pop("acl", None)  # Raw ACL retained in evidence; expanded privileges are compared above.
        # Logical CREATE TABLE compacts attnum gaps left by dropped columns. Compare surviving
        # column order and every type/default/nullability property, retaining physical ordinals in raw evidence.
        result["columns"].sort(key=lambda column: (column["table_schema"], column["table_name"], column["ordinal_position"]))
        counters = {}
        for column in result["columns"]:
            name = (column["table_schema"], column["table_name"])
            counters[name] = counters.get(name, 0) + 1
            column["ordinal_position"] = counters[name]
        # Catalog collections are sets; libc changes can reorder information_schema names.
        # Nested ordered properties (column lists, FK definitions) retain their own order.
        for key, value in result.items():
            if key != "columns" and isinstance(value, list):
                value.sort(key=canonical)
        return result

    def validate(self):
        self.assert_fenced()
        self.transition(["restored", "validated"], "validate")
        ep = self.target_endpoint()
        previous = self.root / "target-fingerprint.json"
        if previous.exists():
            shutil.copy2(previous, self.root / ("target-fingerprint.previous-" + str(time.time_ns()) + ".json"))
        require(self.sql(ep, "SHOW server_version_num;").strip() == "180006", "Unexpected target version.")
        require(command(["docker", "exec", self.target["container"], "cat",
                         "/var/lib/postgresql/18/docker/PG_VERSION"]).decode().strip() == "18", "Misplaced target PGDATA.")
        checks = [
            ("SELECT conname FROM pg_constraint WHERE contype='n' AND NOT convalidated", "Unvalidated NOT NULL constraint."),
            ("SELECT line_number FROM pg_hba_file_rules WHERE auth_method='trust' OR error IS NOT NULL", "Trust/invalid target HBA."),
            ("SELECT rolname FROM pg_authid WHERE rolcanlogin AND (rolpassword IS NULL OR rolpassword NOT LIKE 'SCRAM-SHA-256$%')",
             "Every target login needs SCRAM."),
            ("SELECT indexrelid::regclass::text FROM pg_index WHERE NOT indisvalid OR NOT indisready", "Invalid indexes."),
            ("SELECT datname FROM pg_database WHERE datname=current_database() AND datcollversion IS DISTINCT FROM "
             "pg_database_collation_actual_version(oid)", "Database collation mismatch; do not suppress with REFRESH."),
            ("SELECT collname FROM pg_collation WHERE collversion IS NOT NULL AND collversion IS DISTINCT FROM "
             "pg_collation_actual_version(oid)", "Collation provider mismatch: review affected indexes.")]
        for query, message in checks:
            require(not self.rows(ep, query), message)
        expected = json.loads((self.root / "source-fingerprint.json").read_text())
        require(self.comparable(self.fingerprint(ep, "target")) == self.comparable(expected),
                "Data/sequence/owner/ACL/constraint/rule/large-object comparison failed.")
        require(self.hook("business_command", self.target_endpoint(True)) ==
                json.loads((self.root / "business-source.json").read_text()), "Business/accounting checks differ.")
        roles = self.rows(ep, "SELECT rolname,rolsuper,rolinherit,rolcreaterole,rolcreatedb,rolcanlogin,"
                          "rolreplication,rolbypassrls,rolconnlimit,rolvaliduntil::text,rolconfig "
                          "FROM pg_roles WHERE rolname !~ '^pg_' ORDER BY rolname")
        require(roles == self.state["roles"], "Restored role attributes differ.")
        memberships = self.rows(ep, "SELECT r.rolname AS role,m.rolname AS member,a.admin_option FROM pg_auth_members a "
                               "JOIN pg_roles r ON r.oid=a.roleid JOIN pg_roles m ON m.oid=a.member "
                               "WHERE r.rolname !~ '^pg_' OR m.rolname !~ '^pg_' ORDER BY 1,2")
        require(memberships == self.state["memberships"], "Role membership/grant options differ.")
        self.sql(self.target_endpoint(True), "SELECT 1;")
        require(self.hook("queue_command") == json.loads((self.root / "queue-frozen.json").read_text()), "Pending jobs changed.")
        write(self.root / "validation.json", dict(validated_at=now(), target_image=IMAGE,
              archive_sha256=self.state["archive_sha256"], collation_review=self.plan["collation_review"]))
        self.done("validated")

    def cutover(self):
        self.assert_fenced()
        self.transition(["validated"], "cutover")
        require(self.hook("queue_command") == json.loads((self.root / "queue-frozen.json").read_text()), "Queue changed.")
        command(self.compose + ["stop", self.source["service"]])
        variables = {"COMPOSE_FILE": str(self.root / "compose.postgresql18.json"),
                     "COMPOSE_PROJECT_NAME": self.project, "FM_POSTGRES_DB": self.database,
                     "FM_POSTGRES_SERVICE": self.target["service"]}
        application = self.plan.get("application_service")
        if not application and len(self.plan["producers"]) == 1:
            application = self.plan["producers"][0]
        if application:
            variables["FM_APP_SERVICE"] = application
        write(self.root / "activate.sh", "#!/bin/sh\n" + "".join(
            "export " + key + "=" + shlex.quote(value) + "\n" for key, value in variables.items()))
        self.done("cutover")
        print("Source retained. Select generated Compose; review validation before explicitly resuming.")

    def resume(self):
        require(self.plan.get("rehearsal_approved") is True, "Rehearsal approval (rehearsal_approved) is required before production writes.")
        self.transition(["cutover"], "resume")
        self.state["writes_resumed"] = True  # Persist the boundary before even the first producer can start.
        self.save()
        running = [name for name, producer in self.state["producers"].items() if producer["running"]]
        if running:
            command(self.selected + ["up", "-d", "--no-deps", *running])
        self.done("writes-resumed")

    def rollback(self):
        require(not self.state["writes_resumed"], "Writes may have resumed. Capture/reconcile the delta; tag rollback is forbidden.")
        require(self.state["phase"] in ["prepared", "maintenance", "exported", "restored", "validated", "cutover"],
                "No rollback checkpoint.")
        if self.plan["producers"] and (self.root / "compose.postgresql18.json").exists():
            command(self.selected + ["stop", *self.plan["producers"]])
        original = ["docker", "compose", "--project-name", self.project, "--file", str(self.root / "source.compose.json")]
        command(original + ["up", "-d", "--no-deps", self.source["service"]])
        cid = command(original + ["ps", "-q", self.source["service"]]).decode().strip()
        info = self.inspect(cid)
        selected = [mount for mount in info["Mounts"] if mount["Destination"] == self.source["mount_destination"]]
        require(len(selected) == 1 and selected[0]["Source"] == self.state["source_mount"]["Source"],
                "Rollback container is not on the retained source storage.")
        self.state["source_id"] = info["Id"]
        self.save()
        self.replace_hba((self.root / "source.pg_hba.conf").read_text(), self.state["source_hba_mode"])
        ep = self.source_endpoint()
        if self.rows(ep, "SELECT rolname FROM pg_roles WHERE rolname=" + literal(self.state["fence_role"])):
            self.sql(ep, "DROP ROLE " + identifier(self.state["fence_role"]) + ";", "postgres")
        self.state["source_restored_at"] = now()
        self.done("rolled-back")
        print("Source/config restored. Producers stay stopped; restart explicitly with the saved source.compose.json and inspected images.")

    def recover_maintenance(self):
        require(self.state.get("operation") == "maintenance" and self.state["phase"] == "prepared", "No interrupted fence.")
        self.replace_hba((self.root / "source.pg_hba.conf").read_text(), self.state["source_hba_mode"])
        ep = self.source_endpoint()
        if self.rows(ep, "SELECT rolname FROM pg_roles WHERE rolname=" + literal(self.state["fence_role"])):
            self.sql(ep, "DROP ROLE " + identifier(self.state["fence_role"]) + ";", "postgres")
        self.done("prepared")
        print("Fence reverted. Inspect quiet/producers before retrying maintenance.")


    def recover_export(self):
        require(self.state.get("operation") == "export" and self.state["phase"] == "maintenance",
                "No interrupted export checkpoint.")
        self.assert_source()
        require(self.hook("queue_command") == json.loads((self.root / "queue-frozen.json").read_text()),
                "Queues changed; inspect external producers.")
        self.sql(self.source_endpoint(True), "SELECT 1;", readonly=True)
        for name in ["database.dump", "globals.sql", "archive-toc.txt"]:
            path = self.root / name
            if path.exists():
                path.rename(self.root / (name + ".incomplete-" + str(time.time_ns())))
        self.done("maintenance")

    def run(self, phase):
        if phase == "preflight":
            report = self.preflight()
            report.pop("config")
            print(json.dumps(report, indent=2))
            return
        if phase == "prepare":
            self.prepare()
            return
        self.load()
        with open(self.root / "lock", "a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            if phase == "status":
                print(json.dumps(self.state, indent=2))
                return
            pending = self.state.get("operation")
            require(not pending or phase in ["recover-maintenance", "recover-export", "rollback"] or
                    (pending == "validate" and phase == "validate"),
                    "Interrupted operation: inspect journal; never repeat a partial restore.")
            getattr(self, phase.replace("-", "_"))()

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--plan", required=True)
    p.add_argument("phase", choices=["preflight", "prepare", "maintenance", "export", "restore", "validate",
                                   "cutover", "resume", "rollback", "status", "recover-maintenance", "recover-export"])
    args = p.parse_args()
    os.umask(0o077)
    try:
        Migration(args.plan).run(args.phase)
    except (Refusal, OSError, subprocess.TimeoutExpired, ValueError) as error:
        print("STOP: " + str(error), file=sys.stderr)
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
