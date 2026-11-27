#!/usr/bin/env python3
"""Disposable first rehearsal, not the complete deployment acceptance matrix."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import secrets
import subprocess
import sys
import time
import tempfile
import unittest
from unittest.mock import patch

TOOL = Path(__file__).resolve().parents[2] / "scripts/postgresql-migrate.py"
spec = importlib.util.spec_from_file_location("migration", TOOL)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
GUARD = TOOL.parent / "postgresql-upgrade-guard.py"
guard_spec = importlib.util.spec_from_file_location("upgrade_guard", GUARD)
g = importlib.util.module_from_spec(guard_spec)
guard_spec.loader.exec_module(g)
RAW = "https://raw.githubusercontent.com/sleede/fab-manager/master/"

def fake_tools(directory, docker_compose_version=1, curl_fails=False):
    """Fake curl serving this checkout for raw GitHub URLs, and a docker without Compose v2."""
    bin_directory = Path(directory) / "bin"
    bin_directory.mkdir()
    (bin_directory / "curl").write_text("#!/bin/bash\nURL=\"${@: -1}\"\necho \"$URL\" >> \"$FAKE_TRACE\"\n" +
                                        ("exit 22\n" if curl_fails else "cat \"$FAKE_ROOT/${URL#" + RAW + "}\"\n"))
    (bin_directory / "docker").write_text("#!/bin/bash\n[[ \"$1 $2\" == 'compose version' ]] && exit " +
                                          str(docker_compose_version) + "\nexit 1\n")
    for tool in bin_directory.iterdir():
        tool.chmod(0o755)
    return dict(os.environ, PATH=str(bin_directory) + os.pathsep + os.environ["PATH"],
                FAKE_ROOT=str(TOOL.parent.parent), FAKE_TRACE=str(Path(directory) / "curl-trace"))

def shell_function(path, name):
    lines = Path(path).read_text().splitlines()
    start = lines.index(name + "()")
    return "\n".join(lines[start:lines.index("}", start) + 1]) + "\n"

class PipedScriptTests(unittest.TestCase):
    """setup.sh and upgrade.sh are documented as `curl ... | bash`: BASH_SOURCE is then empty."""
    def test_piped_upgrade_downloads_its_guard(self):
        with tempfile.TemporaryDirectory() as directory:
            env = fake_tools(directory)
            script = shell_function(GUARD.parent.parent / "setup/upgrade.sh", "postgresql_guard") + "postgresql_guard\necho reached\n"
            result = subprocess.run(["bash", "-s"], input=script.encode(), cwd=directory, env=env, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            self.assertIn(b"NOTICE: Docker Compose v2 is unavailable", result.stderr)
            self.assertIn(b"reached", result.stdout)
            self.assertEqual((Path(directory) / "curl-trace").read_text().strip(), RAW + "scripts/postgresql-upgrade-guard.py")

    def test_piped_upgrade_without_guard_download_continues_with_warning(self):
        with tempfile.TemporaryDirectory() as directory:
            env = fake_tools(directory, curl_fails=True)
            script = shell_function(GUARD.parent.parent / "setup/upgrade.sh", "postgresql_guard") + "postgresql_guard\necho reached\n"
            result = subprocess.run(["bash", "-s"], input=script.encode(), cwd=directory, env=env, capture_output=True)
            self.assertEqual(result.returncode, 0)
            self.assertIn(b"could not be downloaded", result.stdout)
            self.assertIn(b"reached", result.stdout)

    def test_piped_setup_obtains_release_files(self):
        with tempfile.TemporaryDirectory() as directory:
            env = fake_tools(directory)
            script = shell_function(GUARD.parent.parent / "setup/setup.sh", "release_file") + \
                "release_file docker/postgresql-entrypoint.sh \"$PWD/entrypoint\" && release_file setup/docker-compose.yml \"$PWD/compose\"\n"
            result = subprocess.run(["bash", "-s"], input=script.encode(), cwd=directory, env=env, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            self.assertEqual((Path(directory) / "entrypoint").read_bytes(),
                             (GUARD.parent.parent / "docker/postgresql-entrypoint.sh").read_bytes())
            self.assertEqual((Path(directory) / "compose").read_bytes(),
                             (GUARD.parent.parent / "setup/docker-compose.yml").read_bytes())

    def test_setup_from_checkout_uses_local_files(self):
        with tempfile.TemporaryDirectory() as directory:
            env = fake_tools(directory)
            script = Path(directory) / "functions.sh"
            script.write_text(shell_function(GUARD.parent.parent / "setup/setup.sh", "release_file"))
            # Same layout as a checkout: setup/<script> next to docker/
            (Path(directory) / "setup").mkdir()
            (Path(directory) / "docker").mkdir()
            (Path(directory) / "docker/postgresql-entrypoint.sh").write_text("local copy\n")
            script.rename(Path(directory) / "setup/functions.sh")
            result = subprocess.run(["bash", "-c", "source setup/functions.sh; release_file docker/postgresql-entrypoint.sh out"],
                                    cwd=directory, env=env, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            self.assertEqual((Path(directory) / "out").read_text(), "local copy\n")
            self.assertFalse((Path(directory) / "curl-trace").exists())

    def test_failed_forced_upgrade_restores_the_exact_image_reference(self):
        functions = "".join(shell_function(GUARD.parent.parent / "setup/upgrade.sh", name)
                            for name in ["target_version", "restore_tag"])
        shell = functions + """
yq() { if [[ "$1" == -i ]]; then echo "$@" > "$TRACE"; else echo sha256:0123abcd; fi; }
SERVICE=web COMPOSE_CONFIG=/selected.json TARGET=6.6.3 FORCE_TARGET=true
target_version
restore_tag
"""
        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory) / "trace"
            result = subprocess.run(["bash", "-c", shell], env=dict(os.environ, TRACE=str(trace)), capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            self.assertIn('.services.web.image = "sha256:0123abcd"', trace.read_text())

class UpgradeGuardPolicyTests(unittest.TestCase):
    """Only positive evidence of an unsafe PostgreSQL 18 state refuses the general upgrade."""
    def check(self, version="90624", services=None, environment=None, tools="18.6"):
        services = services or {"postgres": {"image": "postgres:9.6"}, "app": {"image": "sleede/fab-manager",
                                                                               "environment": environment or {}}}
        def call(args):
            if args[-3:] == ["config", "--format", "json"]:
                return json.dumps({"services": services})
            if "ps" in args:
                return "container-id\n"
            if args[:2] == ["docker", "inspect"]:
                return json.dumps([{"Name": "/postgres-1", "NetworkSettings": {"Networks": {"n": {"Aliases": ["postgres"]}}},
                                    "Mounts": [{"Destination": "/var/lib/postgresql"}], "HostConfig": {}}])
            if args[-1] == "--version":
                return args[-2] + " (PostgreSQL) " + tools + " (Debian)\n"
            if args[-1].endswith("PG_VERSION"):
                return "18\n"
            if "sh" in args and "$1" in args[-3]:
                return "t\n"
            return version + "|/var/lib/postgresql/18/docker\n"
        compose = subprocess.CompletedProcess([], 0)
        with patch.object(g, "call", side_effect=call), patch.object(g.subprocess, "run", return_value=compose), \
                patch.dict(os.environ, {"FM_APP_SERVICE": "app"}):
            g.check(["docker-compose.yml"])

    def test_current_server_is_kept_with_a_notice(self):
        with self.assertRaisesRegex(g.Notice, "end-of-life"):
            self.check()

    def test_external_databases_are_not_blocked(self):
        with self.assertRaises(g.Notice):
            self.check(services={"app": {"image": "sleede/fab-manager"}})
        with self.assertRaises(g.Notice):
            self.check(environment={"DATABASE_URL": "postgres://elsewhere/db"})
        with self.assertRaises(g.Notice):
            self.check(environment={"POSTGRES_HOST": "managed.example"})

    def test_later_18_minor_is_accepted_but_untested_major_is_refused(self):
        self.check(version="180007", tools="18.7")
        with self.assertRaisesRegex(RuntimeError, "newer than"):
            self.check(version="190000")
        with self.assertRaisesRegex(RuntimeError, "client tools"):
            self.check(version="180006", tools="17.2")

    def test_notice_exits_successfully(self):
        with patch.object(g, "check", side_effect=g.Notice("not inspected.")), patch.object(sys, "argv", ["guard"]):
            self.assertEqual(g.main(), 0)
        with patch.object(g, "check", side_effect=RuntimeError("unsafe")), patch.object(sys, "argv", ["guard"]):
            self.assertEqual(g.main(), 1)

class TargetConfigurationTests(unittest.TestCase):
    def target_config(self, source_memory=None, plan_memory=None):
        with tempfile.TemporaryDirectory() as directory:
            migration = m.Migration.__new__(m.Migration)
            migration.root = Path(directory)
            source = {"image": "postgres:9.6"}
            if source_memory:
                source["mem_limit"] = source_memory
            m.write(migration.root / "source.compose.json", {"services": {"pg96": source}})
            migration.plan, migration.source = {"id": "synthetic", "producers": []}, {"service": "pg96"}
            migration.target = dict(service="pg18", container="pg18", data_path="/data", tls_dir="/tls", ca_file="/ca.crt")
            if plan_memory:
                migration.target["memory_limit"] = plan_memory
            return migration.target_config()["services"]["pg18"]

    def test_target_memory_follows_source_or_plan(self):
        self.assertNotIn("mem_limit", self.target_config())
        self.assertEqual(self.target_config(source_memory="2147483648")["mem_limit"], "2147483648")
        self.assertEqual(self.target_config(source_memory="2147483648", plan_memory="4g")["mem_limit"], "4g")

    def test_target_tls_must_be_readable_by_the_server_uid(self):
        migration = m.Migration.__new__(m.Migration)
        migration.target = {"tls_dir": "/private/tls"}
        with patch.object(m, "command", side_effect=m.Refusal("Command failed: docker (exit 1)")):
            with self.assertRaisesRegex(m.Refusal, "UID 999 cannot read"):
                migration.assert_target_tls_readable()
        with patch.object(m, "command", return_value=b"") as command:
            migration.assert_target_tls_readable()
        self.assertIn("999:999", command.call_args.args[0])

    def test_application_image_must_read_the_password_file(self):
        with patch.object(m, "command", return_value=b"password: <%= ENV['POSTGRES_PASSWORD'] %>\n"):
            with self.assertRaisesRegex(m.Refusal, "upgrade the application"):
                m.Migration.assert_application_reads_password_file("sha256:legacy")
        with patch.object(m, "command", return_value=b'password: <%= ENV["POSTGRES_PASSWORD_FILE"] %>\n'):
            m.Migration.assert_application_reads_password_file("sha256:current")

class GuardTests(unittest.TestCase):
    def test_sql_quoting(self):
        self.assertEqual(m.identifier('owner"x'), '"owner""x"')
        self.assertEqual(m.literal("p'ass"), "'p''ass'")

    def test_copy_json_escapes_and_composite_key_values(self):
        values = ["tab\tline\nbackslash\\", "caf\u00e9", 'quote"', None, 1234567890123]
        raw = json.dumps(values, ensure_ascii=False).encode()
        copied = raw.replace(b"\\", b"\\\\") + b"\n"
        self.assertEqual(json.loads(m.copy_text(copied)), values)

    def test_stopped_compose_target_is_still_occupied(self):
        migration = m.Migration.__new__(m.Migration)
        migration.project = "synthetic"
        migration.target = {"service": "pg18"}
        with patch.object(m, "command", return_value=b"stopped-container-id\n"):
            with self.assertRaisesRegex(m.Refusal, "Target Compose service"):
                migration.assert_target_available()

    def test_upgrade_build_failure_keeps_packs_and_services(self):
        upgrade = TOOL.parent.parent / "setup/upgrade.sh"
        functions = upgrade.read_text().rsplit('proceed "$@"', 1)[0]
        with tempfile.TemporaryDirectory(prefix="fm-pg-build-") as directory:
            root = Path(directory)
            packs = root / "public/packs"
            packs.mkdir(parents=True)
            (packs / "verified").write_text("retained")
            (root / "functions.sh").write_text(functions)
            shell = """
set -eu
source ./functions.sh
YES_ALL=true
SKIP_ASSETS=false
FORCE_TARGET=false
SERVICE=fabmanager
docker-compose() {
    if [[ "$1" == run ]]; then return 1; fi
    touch service-mutation
    return 99
}
compile_assets
"""
            result = subprocess.run(["bash", "-c", shell], cwd=root, capture_output=True)
            self.assertEqual(result.returncode, 4)
            self.assertEqual((packs / "verified").read_text(), "retained")
            self.assertFalse((root / "service-mutation").exists())

    def test_warning_is_failure(self):
        result = subprocess.CompletedProcess(["pg_dump"], 0, b"", b"WARNING: incomplete")
        with patch.object(subprocess, "run", return_value=result), self.assertRaises(m.Refusal):
            m.command(["pg_dump"], strict=True)

    def test_failure_does_not_expose_secret(self):
        result = subprocess.CompletedProcess(["psql"], 1, b"", b"password=private-secret")
        with patch.object(subprocess, "run", return_value=result), self.assertRaisesRegex(m.Refusal, "exit 1") as caught:
            m.command(["psql"], strict=True)
        self.assertNotIn("private-secret", str(caught.exception))

    def test_rollback_after_write_boundary_is_refused(self):
        migration = m.Migration.__new__(m.Migration)
        migration.state = {"writes_resumed": True}
        with self.assertRaisesRegex(m.Refusal, "delta"):
            migration.rollback()

    def test_missing_rehearsal_refuses_resume_before_writes(self):
        migration = m.Migration.__new__(m.Migration)
        migration.plan = {"rehearsal_approved": False}
        with self.assertRaisesRegex(m.Refusal, "Rehearsal approval"):
            migration.resume()

    def test_invalid_transition(self):
        migration = m.Migration.__new__(m.Migration)
        migration.state = {"phase": "prepared"}
        with self.assertRaises(m.Refusal):
            migration.transition(["validated"], "cutover")

    def test_secret_permissions(self):
        with self.assertRaises(m.Refusal):
            m.secret_file("/etc/passwd")


    def test_owner_maintain_is_equivalent_but_other_grants_are_not(self):
        owner = dict(owner="alice", grantor="alice", grantee="alice", privilege_type="SELECT", is_grantable=False)
        baseline = dict(tables=[dict(acl="raw legacy")], table_privileges=[owner], columns=[])
        target = dict(tables=[dict(acl="raw modern")], columns=[], table_privileges=[
            owner, dict(owner, privilege_type="MAINTAIN")])
        self.assertEqual(m.Migration.comparable(baseline), m.Migration.comparable(target))
        target["table_privileges"].append(dict(owner, grantee="bob", privilege_type="MAINTAIN"))
        self.assertNotEqual(m.Migration.comparable(baseline), m.Migration.comparable(target))


    def test_dropped_column_gaps_are_compacted_without_ignoring_order(self):
        columns = [dict(table_schema="public", table_name="members", column_name=name, ordinal_position=position)
                   for name, position in [("id", 1), ("name", 4), ("amount", 7)]]
        source = dict(tables=[], table_privileges=[], columns=columns)
        target = dict(tables=[], table_privileges=[], columns=[dict(column, ordinal_position=i+1) for i, column in enumerate(columns)])
        self.assertEqual(m.Migration.comparable(source), m.Migration.comparable(target))
        target["columns"][1]["ordinal_position"], target["columns"][2]["ordinal_position"] = (
            target["columns"][2]["ordinal_position"], target["columns"][1]["ordinal_position"])
        self.assertNotEqual(m.Migration.comparable(source), m.Migration.comparable(target))

    def test_partial_target_cannot_be_reimported(self):
        with tempfile.TemporaryDirectory() as directory:
            migration = m.Migration.__new__(m.Migration)
            migration.root = Path(directory)
            archive = migration.root / "database.dump"
            archive.write_bytes(b"immutable archive")
            target = migration.root / "partial-target"
            target.mkdir()
            migration.target = {"data_path": str(target)}
            migration.state = {"archive_sha256": m.file_hash(archive)}
            migration.assert_fenced = lambda: None
            migration.transition = lambda *_: None
            with self.assertRaisesRegex(m.Refusal, "partial or occupied"):
                migration.restore()
            self.assertEqual(archive.read_bytes(), b"immutable archive")

    def test_interrupted_operation_requires_explicit_recovery(self):
        with tempfile.TemporaryDirectory() as directory:
            migration = m.Migration.__new__(m.Migration)
            migration.root = Path(directory)
            migration.state = {"operation": "restore"}
            migration.load = lambda: None
            with self.assertRaisesRegex(m.Refusal, "Interrupted operation"):
                migration.run("restore")

def execute(args, **kwargs):
    result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)
    if result.returncode:
        raise RuntimeError("Test command failed: " + str(args[:3]) + "\n" + result.stderr.decode()[-2000:])
    return result.stdout

def hook(root, action):
    ep = json.loads(os.environ.get("FM_PG_ENDPOINT", "{}"))
    database = os.environ.get("FM_PG_DATABASE", "fm_pg_b_synthetic")
    obj = m.Migration.__new__(m.Migration)
    obj.database = database
    if action == "health":
        obj.sql(ep, "SELECT 1;", readonly=True)
        print(json.dumps({"healthy": True}))
    elif action == "quiet":
        (root / "quiet").write_text("stop synthetic writer\n")
        time.sleep(2)
        print(json.dumps({"quiet": True}))
    elif action == "queue":
        raw = execute(["docker", "exec", "fm-pg-b-" + root.name + "-redis", "redis-cli", "--raw", "LRANGE", "queue:default", "0", "-1"])
        print(json.dumps(dict(busy=0, queued=len(raw.decode().splitlines()), scheduled=0, retry=0, dead=0,
                              sha256=hashlib.sha256(raw).hexdigest())))
    elif action == "business":
        result = obj.rows(ep, "SELECT count(*)::int AS invoices,sum(amount)::text AS total,"
                          "bool_and(footprint=md5(id::text || ':' || amount::text)) AS valid FROM invoices")[0]
        assert result["valid"] and result["invoices"] == 3 and result["total"] == "9007199254741016.13", result
        result["reservations"] = obj.rows(ep, "SELECT id,starts_at,meta FROM reservations ORDER BY id")
        result["search"] = obj.rows(ep, "SELECT id FROM projects WHERE to_tsvector('french',unaccent(name)) "
                                          "@@ plainto_tsquery('french',unaccent('réservation')) ORDER BY id")
        assert result["search"] == [{"id": 1}]
        result["duplicates"] = obj.rows(ep, "SELECT element_type,element_id,count(*)::int AS count FROM chained_elements "
                                           "GROUP BY 1,2 HAVING count(*)>1 ORDER BY 1,2")
        result["sort"] = obj.rows(ep, "SELECT name FROM projects ORDER BY name")
        print(json.dumps(result))
    else:
        raise ValueError(action)

def integration(root, standard=False):
    """standard=True recreates the shipped 9.6 service: trust authentication, no TLS and no command."""
    assert os.geteuid() == 0
    assert str(root).startswith("/opt/fab-manager-pr-pg-b/") and not root.exists()
    root.mkdir(parents=True, mode=0o700)
    os.umask(0o077)
    (root / "source-data").mkdir()
    password = secrets.token_hex(32)
    (root / "source-password").write_text(password + "\n")
    os.chown(root / "source-password", 999, 999)
    (root / "source.pgpass").write_text("*:*:*:postgres:" + password + "\n")
    (root / "reporting-password").write_text(secrets.token_hex(32) + "\n")
    certs = root / "certs"
    certs.mkdir()
    execute(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "3",
             "-keyout", str(certs / "ca.key"), "-out", str(certs / "ca.crt"), "-subj", "/CN=Disposable PG-B"])
    for service in ["pg96", "pg18"]:
        directory = certs / service
        directory.mkdir()
        execute(["openssl", "req", "-newkey", "rsa:2048", "-nodes", "-keyout", str(directory / "server.key"),
                 "-out", str(directory / "server.csr"), "-subj", "/CN=" + service])
        (directory / "ext").write_text("subjectAltName=DNS:" + service + "\n")
        execute(["openssl", "x509", "-req", "-in", str(directory / "server.csr"), "-CA", str(certs / "ca.crt"),
                 "-CAkey", str(certs / "ca.key"), "-CAcreateserial", "-out", str(directory / "server.crt"),
                 "-days", "3", "-extfile", str(directory / "ext")])
        os.chmod(directory / "server.key", 0o600)
        os.chown(directory / "server.key", 999, 999)
        os.chmod(directory / "server.crt", 0o644)
        os.chmod(directory, 0o755)
    os.chmod(certs / "ca.crt", 0o644)
    compose = {
        "services": {
            "pg96": {"image": "postgres:9.6@sha256:caddd35b05cdd56c614ab1f674e63be778e0abdf54e71a7507ff3e28d4902698",
                     "container_name": "fm-pg-b-" + root.name + "-source", "environment": {"POSTGRES_PASSWORD_FILE": "/run/password",
                     "POSTGRES_INITDB_ARGS": "--auth-host=md5 --auth-local=md5"},
                     "volumes": [str(root / "source-data") + ":/var/lib/postgresql/data",
                                 str(root / "source-password") + ":/run/password:ro",
                                 str(certs / "pg96") + ":/certs:ro"],
                     "command": ["postgres", "-c", "ssl=on", "-c", "ssl_cert_file=/certs/server.crt",
                                 "-c", "ssl_key_file=/certs/server.key", "-c", "shared_buffers=32MB"],
                     "networks": ["test"], "mem_limit": "192m"},
            "redis": {"image": "redis:6-alpine@sha256:592b215e9287182f11ba9d7c229dc0ba312bb900a016ea65ae378b0127567319",
                      "container_name": "fm-pg-b-" + root.name + "-redis", "networks": ["test"], "mem_limit": "48m"},
            "writer": {"image": m.IMAGE, "container_name": "fm-pg-b-" + root.name + "-writer", "networks": ["test"],
                       "entrypoint": ["bash", "/fixture/writer.sh"], "mem_limit": "96m",
                       "volumes": [str(root) + ":/fixture:ro"], "environment":
                       {"PGHOST": "pg96", "PGUSER": "postgres", "PGPASSFILE": "/fixture/source.pgpass",
                        "PGDATABASE": "fm_pg_b_synthetic", "PGSSLMODE": "verify-full", "PGSSLROOTCERT": "/fixture/certs/ca.crt"}}},
        "networks": {"test": {"internal": True}}}
    source_tls = "verify-full"
    if standard:
        source_tls = "prefer"
        compose["services"]["pg96"].update(environment={"POSTGRES_HOST_AUTH_METHOD": "trust"},
                                           volumes=[str(root / "source-data") + ":/var/lib/postgresql/data"])
        del compose["services"]["pg96"]["command"]
        compose["services"]["writer"]["environment"].update(PGSSLMODE=source_tls)
        del compose["services"]["writer"]["environment"]["PGSSLROOTCERT"]
    m.write(root / "compose.json", compose)
    (root / "writer.sh").write_text("#!/bin/bash\nset -eu\nwhile [ ! -f /fixture/quiet ]; do\n"
                                  "psql -X -v ON_ERROR_STOP=1 -c 'INSERT INTO write_log DEFAULT VALUES' >/dev/null\nsleep 1\ndone\n"
                                  "exec sleep infinity\n")
    dc = ["docker", "compose", "-p", "fm-pg-b-" + root.name, "-f", str(root / "compose.json")]
    execute(dc + ["up", "-d", "pg96", "redis"])
    obj = m.Migration.__new__(m.Migration)
    obj.database = "fm_pg_b_synthetic"
    ep = dict(container="fm-pg-b-" + root.name + "-source", hostname="pg96", user="postgres",
              password_file=str(root / "source.pgpass"), sslmode=source_tls, ca_file=None if standard else str(certs / "ca.crt"))
    for attempt in range(45):
        try:
            obj.sql(ep, "SELECT 1;", "postgres")
            break
        except m.Refusal:
            time.sleep(1)
    obj.sql(ep, "CREATE DATABASE fm_pg_b_synthetic TEMPLATE template0 ENCODING 'UTF8';", "postgres")
    fixture = """
CREATE EXTENSION unaccent;
CREATE EXTENSION pg_trgm;
CREATE EXTENSION fuzzystrmatch;
CREATE ROLE reporting NOLOGIN;
CREATE SCHEMA archive AUTHORIZATION reporting;
CREATE TABLE invoices(id bigserial PRIMARY KEY,amount numeric(30,2) NOT NULL,footprint text NOT NULL);
INSERT INTO invoices(amount,footprint) VALUES(1500.01,''),(24.00,''),(9007199254739492.12,'');
UPDATE invoices SET footprint=md5(id::text || ':' || amount::text);
GRANT SELECT ON invoices TO reporting;
CREATE TABLE reservations(id bigserial PRIMARY KEY,invoice_id bigint REFERENCES invoices(id),starts_at timestamptz,
                          meta jsonb,payload json,day date,bytes bytea);
INSERT INTO reservations VALUES(1,1,'2026-11-01 01:30:00-04','{"places":[1,2],"exact":9007199254740993}',
                               '{"x":null,"accent":"é"}','2024-02-29',decode('0001ff','hex'));
SELECT setval('reservations_id_seq',42,false);
CREATE TABLE projects(id serial PRIMARY KEY,name text);
INSERT INTO projects(name) VALUES('réservation atelier'),('Été'),('Zèbre'),('alpha');
CREATE INDEX projects_search ON projects USING gin(to_tsvector('french',name));
CREATE TABLE chained_elements(id serial PRIMARY KEY,element_type text,element_id bigint,footprint text);
INSERT INTO chained_elements(element_type,element_id,footprint) VALUES('Invoice',1,'old'),('Invoice',1,'new');
CREATE TABLE accounting_periods(id serial PRIMARY KEY,closed_at date);
INSERT INTO accounting_periods(closed_at) VALUES('2026-10-31');
CREATE RULE accounting_periods_del_protect AS ON DELETE TO accounting_periods DO INSTEAD NOTHING;
CREATE FUNCTION archive.exact_total() RETURNS numeric LANGUAGE sql STABLE AS 'SELECT sum(amount) FROM public.invoices';
ALTER FUNCTION archive.exact_total() OWNER TO reporting;
CREATE TABLE write_log(id bigserial PRIMARY KEY,created_at timestamptz DEFAULT now());
SELECT lo_from_bytea(18421,decode('aabbcc0011','hex'));
"""
    obj.sql(ep, fixture)
    execute(["docker", "exec", "fm-pg-b-" + root.name + "-redis", "redis-cli", "RPUSH", "queue:default",
             '{"class":"SyntheticJob","jid":"one"}', '{"class":"SyntheticJob","jid":"two"}'])
    execute(dc + ["up", "-d", "--no-deps", "writer"])
    time.sleep(3)
    plan = dict(id="fm-pg-b-" + root.name, state_dir=str(root / "run"), project="fm-pg-b-" + root.name,
                compose_files=[str(root / "compose.json")], database=obj.database, app_role="postgres",
                source=dict(service="pg96", container="fm-pg-b-" + root.name + "-source", hostname="pg96", admin="postgres",
                            password_file=str(root / "source.pgpass"), sslmode=source_tls,
                            mount_type="bind", mount_source=str(root / "source-data"),
                            mount_destination="/var/lib/postgresql/data", pgdata="/var/lib/postgresql/data"),
                target=dict(service="pg18", container="fm-pg-b-" + root.name + "-target", image=m.IMAGE,
                            data_path=str(root / "target-data"), tls_dir=str(certs / "pg18"),
                            ca_file=str(certs / "ca.crt"), memory_limit="256m"),
                producers=["writer"], non_producers=["redis"],
                external_producers_stopped="Only the synthetic writer in this isolated internal network; no external producers.",
                approved_superusers=["postgres"], login_password_files={},
                extensions=["plpgsql", "unaccent", "pg_trgm", "fuzzystrmatch"],
                collation_review="Synthetic en_US.utf8 libc change: new logical indexes, accents sort, unique constraints and business query comparison.",
                rehearsal_approved=False)
    for key, action in [("health_command", "health"), ("quiet_command", "quiet"), ("queue_command", "queue"), ("business_command", "business")]:
        plan[key] = [sys.executable, str(Path(__file__).resolve()), "--hook", action, "--root", str(root)]
    if not standard:
        plan["source"]["ca_file"] = str(certs / "ca.crt")
    m.write(root / "plan.json", plan)
    results = []
    for phase in ["preflight", "prepare", "maintenance", "export", "restore", "validate", "cutover", "rollback"]:
        started = time.time()
        result = subprocess.run([sys.executable, str(TOOL), "--plan", str(root / "plan.json"), phase],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        (root / (phase + ".stdout")).write_bytes(result.stdout)
        (root / (phase + ".stderr")).write_bytes(result.stderr)
        results.append(dict(phase=phase, exit_code=result.returncode, duration_seconds=round(time.time()-started, 2)))
        m.write(root / "results.json", results)
        print(json.dumps(results[-1]), flush=True)
        if result.returncode:
            raise RuntimeError(result.stderr.decode())
        if phase == "maintenance":
            try:
                obj.sql(ep, "INSERT INTO write_log DEFAULT VALUES;")
                raise AssertionError("Source fence allowed the application login")
            except m.Refusal:
                pass
    obj.sql(ep, "SELECT count(*) FROM invoices;", readonly=True)
    assert (root / "source-data/PG_VERSION").read_text().strip() == "9.6"
    assert (root / "target-data/18/docker/PG_VERSION").read_text().strip() == "18"
    assert (root / "run/database.dump").stat().st_size > 0
    print("FIRST_REHEARSAL_PASS: source, archive, target and Redis retained; producers stopped.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--integration", action="store_true")
    parser.add_argument("--standard-source", action="store_true")
    parser.add_argument("--root", type=Path)
    parser.add_argument("--hook")
    args, rest = parser.parse_known_args()
    if args.hook:
        hook(args.root, args.hook)
    elif args.integration:
        integration(args.root, args.standard_source)
    else:
        unittest.main(argv=[sys.argv[0]] + rest)
