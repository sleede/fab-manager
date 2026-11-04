#!/usr/bin/env python3
"""Behavioral startup/upgrade guards against resources from the isolated rehearsal."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("migration", ROOT / "scripts/postgresql-migrate.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

def run(args, expected, text=None, env=None):
    result = subprocess.run(args, capture_output=True, env=env)
    assert result.returncode == expected, (args[:3], result.returncode, result.stderr.decode())
    if text:
        assert text in (result.stdout + result.stderr).decode(), result.stderr.decode()
    return result

def main(root):
    assert root.is_absolute() and str(root).startswith("/opt/fab-manager-pr-pg-b/")
    migration = m.Migration(str(root / "plan.json"))
    migration.load()
    ep = migration.target_endpoint()
    checks = []
    guard_database = "fm_pg_b_guard_" + str(time.time_ns())
    def record(name):
        checks.append(name)
        print("PASS " + name, flush=True)
    with tempfile.TemporaryDirectory(prefix="guards-", dir=root) as temporary:
        private = Path(temporary)
        for name, version, sentinel in [("legacy", "9.6", False), ("missing", None, False),
                                        ("lost-data", None, True), ("wrong-major", "17", False)]:
            data, guard = private / name, private / (name + "-state")
            data.mkdir()
            guard.mkdir()
            if version == "9.6":
                (data / "PG_VERSION").write_text("9.6\n")
            elif version:
                (data / "18/docker").mkdir(parents=True)
                (data / "18/docker/PG_VERSION").write_text(version + "\n")
            if sentinel:
                (guard / "initialized").write_text("previous initialization\n")
            result = run(["docker", "run", "--rm", "--network", "none",
                          "--mount", "type=bind,src=" + str(data) + ",dst=/var/lib/postgresql,readonly",
                          "--mount", "type=bind,src=" + str(guard) + ",dst=/run/fm-pg-guard,readonly",
                          "--mount", "type=bind,src=" + str(ROOT / "docker/postgresql-entrypoint.sh") + ",dst=/guard.sh,readonly",
                          "-e", "FM_PG_INITIALIZE=" + ("1" if sentinel else "0"), "--entrypoint", "bash",
                          m.IMAGE, "/guard.sh", "postgres"], 1)
            assert not (data / "18/docker/base").exists()
            record("startup-" + name + "-refused-before-init")
        guard_tool = str(ROOT / "scripts/postgresql-upgrade-guard.py")
        source_args = ["python3", guard_tool, "--compose", str(root / "compose.json"),
                       "--project", migration.project, "--service", migration.source["service"],
                       "--database", migration.database]
        run(source_args, 0, "end-of-life")
        record("upgrade-real-9.6-kept-with-notice")
        target_args = ["python3", guard_tool, "--compose", str(root / "run/compose.postgresql18.json"),
                       "--project", migration.project, "--service", migration.target["service"]]
        run(target_args + ["--database", "fm_pg_b_missing"], 1)
        record("upgrade-missing-database-refused")
        # Separate synthetic guard database; never changes the migrated application database.
        migration.sql(ep, "CREATE DATABASE " + m.identifier(guard_database) + ";", "postgres")
        run(target_args + ["--database", guard_database], 1)
        record("upgrade-empty-database-refused")
        migration.sql(ep, "CREATE TABLE schema_migrations(version text); INSERT INTO schema_migrations VALUES('synthetic');"
                      "CREATE TABLE users(id int); INSERT INTO users VALUES(1);", guard_database)
        run(target_args + ["--database", guard_database], 0, "PostgreSQL 18 server")
        record("upgrade-18-storage-tools-and-database-recognized")
        # Execute the real proceed/guard ordering, replacing only unrelated application mutations.
        copy_root = private / "upgrade-case"
        (copy_root / "setup").mkdir(parents=True)
        (copy_root / "scripts").mkdir()
        shutil.copy(ROOT / "scripts/postgresql-upgrade-guard.py", copy_root / "scripts")
        source = (ROOT / "setup/upgrade.sh").read_text().rsplit('\nproceed "$@"', 1)[0]
        (copy_root / "setup/upgrade.sh").write_text(source + """
config() { :; }
version_check() { printf 'unsafe version mutation' >> "$FM_GUARD_TRACE"; }
upgrade() { printf 'unsafe upgrade mutation' >> "$FM_GUARD_TRACE"; }
clean() { :; }
proceed -y -i
""")
        trace = private / "unsafe-mutation"
        env = dict(os.environ, COMPOSE_FILE=str(root / "run/compose.postgresql18.json"), COMPOSE_PROJECT_NAME=migration.project,
                   FM_POSTGRES_SERVICE=migration.target["service"], FM_POSTGRES_DB="fm_pg_b_missing",
                   FM_GUARD_TRACE=str(trace))
        run(["bash", str(copy_root / "setup/upgrade.sh")], 1, "STOP:", env)
        assert not trace.exists()
        record("upgrade-yes-ignore-cannot-bypass-database-gate")
        # The current 9.6 server keeps receiving application upgrades (the application supports it).
        env.update(COMPOSE_FILE=str(root / "compose.json"), FM_POSTGRES_SERVICE=migration.source["service"],
                   FM_POSTGRES_DB=migration.database)
        run(["bash", str(copy_root / "setup/upgrade.sh")], 0, "end-of-life", env)
        assert trace.exists()
        record("upgrade-9.6-proceeds-after-notice")
        wrong = private / "wrong.pgpass"
        wrong.write_text("*:*:*:postgres:synthetic-wrong-password\n")
        wrong.chmod(0o600)
        try:
            migration.sql(dict(ep, password_file=str(wrong)), "SELECT 1;")
            raise AssertionError("Bad password accepted")
        except m.Refusal:
            pass
        record("target-wrong-password-refused")
        assert migration.sql(ep, "SHOW shared_buffers;").strip() == "32MB"
        record("custom-source-postgres-setting-preserved")
        assert m.sha(m.command(["docker", "exec", migration.state["source_id"], "cat",
                              migration.state["source_meta"]["hba_file"]])) == m.sha((root / "run/source.pg_hba.conf").read_bytes())
        record("rollback-restored-original-source-hba")
        # The preflight must compare configured resources with the actual running source.
        for case in ["image", "environment", "mount"]:
            plan = json.loads((root / "plan.json").read_text())
            config = json.loads((root / "compose.json").read_text())
            source_service = config["services"][migration.source["service"]]
            if case == "image":
                source_service["image"] = m.IMAGE
                reason = "Configured source image differs"
            elif case == "environment":
                source_service["environment"]["POSTGRES_PASSWORD"] = "synthetic-unapplied-change"
                reason = "Effective source environment differs"
            else:
                source_service["volumes"].append(str(private / "uncreated-mount") + ":/unmapped:ro")
                reason = "Unmapped database mount"
            config_path = private / (case + "-compose.json")
            config_path.write_text(json.dumps(config))
            plan["compose_files"] = [str(config_path)]
            plan["state_dir"] = str(private / (case + "-state"))
            plan["target"]["data_path"] = str(private / (case + "-data"))
            plan["target"]["container"] = "fm-pg-b-preflight-" + case
            # The migrated pg18 service still exists; an occupied target is refused before drift checks.
            plan["target"]["service"] = "pg18-preflight-" + case
            plan_path = private / (case + "-plan.json")
            plan_path.write_text(json.dumps(plan))
            run(["python3", str(ROOT / "scripts/postgresql-migrate.py"), "--plan", str(plan_path), "preflight"],
                1, reason)
            assert not Path(plan["state_dir"]).exists() and not Path(plan["target"]["data_path"]).exists()
            record("preflight-" + case + "-drift-refused-before-write")

    (root / "guard-results.json").write_text(json.dumps(checks, indent=2) + "\n")
    print(str(len(checks)) + " behavioral checks passed")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, type=Path)
    main(parser.parse_args().root)
