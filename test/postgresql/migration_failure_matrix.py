#!/usr/bin/env python3
"""Failure and independent recovery checks. Synthetic migration plans only."""
import argparse
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
from types import SimpleNamespace
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("migration", REPO / "scripts/postgresql-migrate.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

def main(plan_path, output):
    original = m.Migration(str(plan_path))
    original.load()
    assert original.database.startswith("fm_pg_b_")
    assert original.state["phase"] in ["restored", "validated"]
    assert str(output).startswith("/opt/fab-manager-pr-pg-b/") and not output.exists()
    output.mkdir(mode=0o700)
    cases = []
    token = hashlib.sha256(str(output).encode()).hexdigest()[:8]
    source_hash = m.file_hash(original.root / "database.dump")

    def record(name, result, started):
        cases.append(dict(scenario=name, status=result, seconds=round(time.monotonic()-started, 3)))
        m.write(output / "results.json", cases)
        print(json.dumps(cases[-1]), flush=True)

    def reject(name, function, message=None):
        started = time.monotonic()
        try:
            function()
        except m.Refusal as error:
            if message:
                assert message in str(error), str(error)
            record(name, "PASS", started)
            return
        raise AssertionError("Expected refusal: " + name)

    def fixture(name, phase="exported"):
        root = output / name
        root.mkdir(mode=0o700)
        for file in original.root.iterdir():
            if file.is_file() and file.name != "lock":
                if phase == "maintenance" and file.name in ["database.dump", "globals.sql", "archive-toc.txt"]:
                    continue
                shutil.copy2(file, root / file.name)
        os.chown(root / "admin-password", 999, 999)
        plan = copy.deepcopy(original.plan)
        plan.update(state_dir=str(root), rehearsal_approved=True)
        plan["target"].update(container="fm-pg-b-fault-"+token+"-"+name.replace("_","-"), data_path=str(output/(name+" data")))
        m.write(root / "input-plan.json", plan)
        obj = m.Migration(str(root / "input-plan.json"))
        obj.state = copy.deepcopy(original.state)
        obj.state.update(phase=phase, plan_hash=obj.plan_hash)
        obj.state.pop("operation", None)
        obj.save()
        obj.project = "fm-pg-b-fault-"+token+"-"+name.replace("_","-")
        obj.selected = ["docker","compose","-p",obj.project,"-f",str(root/"compose.postgresql18.json")]
        generator = obj.target_config
        def config():
            result = generator()
            result["networks"]["test"] = {"name":original.project+"_test","external":True}
            return result
        obj.target_config = config
        return obj

    # A partial real pg_dump stream must not become a valid export checkpoint.
    obj = fixture("dump_interrupted", "maintenance")
    obj.fingerprint = lambda *_: json.loads((original.root/"source-fingerprint.json").read_text())
    utility = obj.utility
    def interrupted(ep, args, output=None, data=None, input_file=None):
        if args[0] != "pg_dump":
            return utility(ep, args, output=output, data=data, input_file=input_file)
        helper = "fm-pg-b-interrupted-dump-"+token
        argv = obj.client(ep)
        argv[3:3] = ["--name", helper]
        process = subprocess.Popen(argv+[m.IMAGE]+args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        block = process.stdout.read(4096)
        assert block
        output.write(block);output.flush();os.fsync(output.fileno())
        subprocess.run(["docker","kill","--signal","KILL",helper],capture_output=True)
        process.stdout.close()
        process.wait(timeout=30)
        raise m.Refusal("Injected interruption of a real dump stream.")
    obj.utility = interrupted
    reject("dump-interrupted-real-stream", obj.export, "interruption")
    assert (obj.root/"database.dump").stat().st_size < (original.root/"database.dump").stat().st_size
    reject("resume-after-interrupted-dump", lambda: obj.run("resume"), "Interrupted operation")
    started = time.monotonic()
    obj.recover_export()
    assert obj.state["phase"] == "maintenance" and list(obj.root.glob("database.dump.incomplete-*"))
    record("interrupted-dump-preserved-for-explicit-retry", "PASS", started)

    obj = fixture("corrupt_archive")
    (obj.root/"database.dump").write_bytes(b"PGDMP truncated synthetic corruption")
    reject("corrupt-dump-checksum", obj.restore, "checksum")
    assert not Path(obj.target["data_path"]).exists()
    reject("resume-after-corrupt-archive", lambda: obj.run("resume"), "Interrupted operation")

    obj = fixture("occupied_target")
    target = Path(obj.target["data_path"]);target.mkdir()
    (target/"preserve-this").write_text("synthetic occupied target\n")
    reject("occupied-target-refused-before-import", obj.restore, "partial or occupied")
    assert (target/"preserve-this").read_text() == "synthetic occupied target\n"

    obj = fixture("restore_failed")
    utility = obj.utility
    truncated = obj.root/"broken-input-stream.dump"
    archive = (obj.root/"database.dump").read_bytes()
    truncated.write_bytes(archive[:len(archive)//2])
    def broken_restore(ep, args, output=None, data=None, input_file=None):
        if args[0] == "pg_restore" and "--create" in args:
            with truncated.open("rb") as stream:
                return utility(ep,args,output=output,input_file=stream)
        return utility(ep,args,output=output,data=data,input_file=input_file)
    obj.utility = broken_restore
    reject("restore-failed-on-real-truncated-stream", obj.restore)
    assert Path(obj.target["data_path"]).exists()
    reject("partial-restore-cannot-resume-writers", lambda: obj.run("resume"), "Interrupted operation")
    reject("partial-restore-cannot-reimport", lambda: obj.run("restore"), "Interrupted operation")
    subprocess.run(["docker","stop",obj.target["container"]],check=True,capture_output=True)

    # Exercise the full read-only preflight with its disk metric fault-injected.
    plan = copy.deepcopy(original.plan)
    plan["state_dir"] = str(output/"disk-state")
    plan["target"].update(container="fm-pg-b-fault-low-disk",data_path=str(output/"disk-target"))
    plan["source"].update(admin=original.state["fence_role"],password_file=str(original.root/"source.pgpass"))
    plan["approved_superusers"] += [original.state["fence_role"]]
    plan["login_password_files"] = {original.state["fence_role"]:str(original.root/"fence-password")}
    certificate = output/"disk-certificates"
    certificate.mkdir()
    service_name = "pg-disk-"+token
    plan["target"].update(service=service_name,tls_dir=str(certificate))
    subprocess.run(["openssl","req","-newkey","rsa:2048","-nodes","-keyout",str(certificate/"server.key"),
        "-out",str(certificate/"server.csr"),"-subj","/CN="+service_name],check=True,capture_output=True)
    (certificate/"extensions").write_text("subjectAltName=DNS:"+service_name+"\n")
    subprocess.run(["openssl","x509","-req","-in",str(certificate/"server.csr"),"-CA",original.target["ca_file"],
        "-CAkey",str(Path(original.target["ca_file"]).parent/"ca.key"),"-set_serial","0x"+token,
        "-out",str(certificate/"server.crt"),"-days","2","-extfile",str(certificate/"extensions")],
        check=True,capture_output=True)
    (certificate/"server.key").chmod(0o600)
    os.chown(certificate/"server.key",999,999)
    # Readable by the server UID like real target material, so only the disk metric is faulty.
    certificate.chmod(0o755);(certificate/"server.crt").chmod(0o644)
    m.write(output/"disk-plan.json",plan)
    disk = m.Migration(str(output/"disk-plan.json"))
    with patch.object(m.shutil,"disk_usage",return_value=SimpleNamespace(free=0)):
        reject("insufficient-space-read-only-preflight",disk.preflight,"Insufficient space")
    assert not Path(plan["state_dir"]).exists() and not Path(plan["target"]["data_path"]).exists()

    # New independently initialized 18 cluster, first used as an unexpected source.
    server_root = output/"independent server"
    server_root.mkdir();data_root=server_root/"data";data_root.mkdir();os.chown(data_root,999,999)
    name="fm-pg-b-independent-restore-"+token
    project="fm-pg-b-independent-"+token
    service={"image":m.IMAGE,"container_name":name,
             "environment":{"PGDATA":"/var/lib/postgresql/18/docker","POSTGRES_PASSWORD_FILE":"/run/password",
                            "POSTGRES_INITDB_ARGS":"--auth-host=scram-sha-256 --auth-local=scram-sha-256"},
             "command":["postgres","-c","ssl=on","-c","ssl_cert_file=/certs/server.crt","-c","ssl_key_file=/certs/server.key"],
             "volumes":[str(data_root)+":/var/lib/postgresql",str(original.root/"admin-password")+":/run/password:ro",
                        original.target["tls_dir"]+":/certs:ro"],"networks":["test"],"mem_limit":"256m"}
    m.write(server_root/"compose.json",{"services":{"pg18source":service},"networks":{"test":{"internal":True}}})
    dc=["docker","compose","-p",project,"-f",str(server_root/"compose.json")]
    subprocess.run(dc+["up","-d"],check=True,capture_output=True)
    endpoint=dict(original.target_endpoint(),container=name)
    for _ in range(60):
        try:
            original.sql(endpoint,"SELECT 1;","postgres");break
        except m.Refusal:time.sleep(1)
    original.sql(endpoint,"CREATE DATABASE "+m.identifier(original.database)+";","postgres")
    plan=copy.deepcopy(original.plan)
    plan.update(project=project,compose_files=[str(server_root/"compose.json")],state_dir=str(output/"wrong-version-state"),
                producers=[],non_producers=[])
    plan["source"].update(service="pg18source",container=name,hostname="pg18",admin="postgres",
        password_file=str(original.root/"target.pgpass"),mount_source=str(data_root),
        mount_destination="/var/lib/postgresql",pgdata="/var/lib/postgresql/18/docker")
    plan["target"].update(container="fm-pg-b-unused-target",data_path=str(output/"unused-target"))
    m.write(output/"wrong-version-plan.json",plan)
    reject("unexpected-real-source-version-18",lambda:m.Migration(str(output/"wrong-version-plan.json")).preflight(),"9.6 primary")
    assert not Path(plan["state_dir"]).exists()
    # Remove only the empty synthetic probe database created immediately above.
    original.sql(endpoint,"DROP DATABASE "+m.identifier(original.database)+";","postgres")
    started=time.monotonic()
    # Same inspected roles as the tool's restore: the archive owners/grants need them.
    original.sql(endpoint,"\n".join(original.role_statements()),"postgres")
    with (original.root/"database.dump").open("rb") as stream:
        original.utility(endpoint,["pg_restore","--exit-on-error","--create","--dbname=postgres"],input_file=stream)
    original.sql(endpoint,"ANALYZE;")
    obj=fixture("independent_copy","restored")
    obj.target.update(container=name,data_path=str(data_root))
    obj.plan["target"]=obj.target
    obj.plan_hash=m.sha(m.canonical(obj.plan));obj.state["plan_hash"]=obj.plan_hash
    m.write(obj.root/"input-plan.json",obj.plan);obj.save()
    obj.validate()
    record("same-archive-independent-full-restore-and-business-validation","PASS",started)

    # Real data corruption on only the disposable copy must block validation and resume.
    obj.sql(obj.target_endpoint(),"UPDATE projects SET name='Injected validation failure' WHERE id=(SELECT min(id) FROM projects);")
    reject("real-business-data-mismatch-blocks-validation",obj.validate,"comparison failed")
    reject("failed-validation-cannot-resume-writers",lambda:obj.run("resume"),"Interrupted operation")
    subprocess.run(["docker","stop",name],check=True,capture_output=True)

    started=time.monotonic()
    current=original.fingerprint(original.source_endpoint(True),"source-after-fault-matrix")
    expected=json.loads((original.root/"source-fingerprint.json").read_text())
    assert current==expected
    assert m.file_hash(original.root/"database.dump")==source_hash
    assert original.hook("business_command",original.source_endpoint(True))==json.loads((original.root/"business-source.json").read_text())
    record("source-and-original-archive-unchanged-after-all-failures","PASS",started)
    print("Failure matrix completed; no source/target volume removed.",flush=True)

if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--plan",required=True,type=Path);p.add_argument("--output",required=True,type=Path)
    a=p.parse_args();os.umask(0o077);main(a.plan,a.output)
