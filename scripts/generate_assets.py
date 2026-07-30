#!/usr/bin/env python3
"""Run the exported generation jobs against a text-to-3D API and land the
results in the repo at their slot paths.

Reads build/asset_jobs.jsonl (scripts/export_asset_prompts.py), submits each
prompt, polls until the model is ready, downloads the GLB, and writes it to
the job's `target`. Resumable: a job whose target already exists is skipped,
so an interrupted or partial run costs nothing to repeat.

    export TRIPO_API_KEY=...        # or MESHY_API_KEY
    python3 scripts/export_asset_prompts.py --kind omnidex
    python3 scripts/generate_assets.py --provider tripo --kind race --limit 20

Start with `--dry-run` to see the batch, the provider, and the job count
before anything is charged.

Providers are thin adapters — `submit` returns a task id, `poll` returns
(state, glb_url). Adding one is a dozen lines; nothing else changes.
"""

import argparse
import json
import os
import subprocess
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JOBS = os.path.join(REPO, "build", "asset_jobs.jsonl")

POLL_SECONDS = 10
POLL_TIMEOUT = 900


def curl(url, method="GET", headers=None, body=None, out=None):
    """curl rather than requests: this environment's HTTPS egress goes through
    a proxy that urllib does not pick up."""
    cmd = ["curl", "-sS", "--retry", "3", "--retry-delay", "2", "-X", method]
    for k, v in (headers or {}).items():
        cmd += ["-H", "%s: %s" % (k, v)]
    if body is not None:
        cmd += ["-H", "Content-Type: application/json", "-d", json.dumps(body)]
    if out:
        cmd += ["-o", out]
    cmd.append(url)
    r = subprocess.run(cmd, capture_output=True)
    if r.returncode != 0:
        return None
    return True if out else r.stdout


class Tripo:
    """https://platform.tripo3d.ai — text_to_model, then poll the task."""
    name = "tripo"
    env = "TRIPO_API_KEY"
    base = "https://api.tripo3d.ai/v2/openapi"

    def __init__(self, key):
        self.h = {"Authorization": "Bearer %s" % key}

    def submit(self, prompt):
        r = curl("%s/task" % self.base, "POST", self.h,
                 {"type": "text_to_model", "prompt": prompt[:1024]})
        if not r:
            return None, "request failed"
        try:
            d = json.loads(r)
        except json.JSONDecodeError:
            return None, "bad response: %s" % r[:160]
        if d.get("code") not in (0, None):
            return None, str(d.get("message", d))[:160]
        return (d.get("data") or {}).get("task_id"), None

    def poll(self, task_id):
        r = curl("%s/task/%s" % (self.base, task_id), "GET", self.h)
        if not r:
            return "error", None
        try:
            d = (json.loads(r).get("data") or {})
        except json.JSONDecodeError:
            return "error", None
        status = d.get("status", "")
        if status in ("success", "succeed", "completed"):
            out = d.get("output") or {}
            return "done", out.get("pbr_model") or out.get("model")
        if status in ("failed", "cancelled", "banned", "expired"):
            return "failed", None
        return "running", None


class Meshy:
    """https://docs.meshy.ai — openapi/v2/text-to-3d."""
    name = "meshy"
    env = "MESHY_API_KEY"
    base = "https://api.meshy.ai/openapi/v2/text-to-3d"

    def __init__(self, key):
        self.h = {"Authorization": "Bearer %s" % key}

    def submit(self, prompt):
        r = curl(self.base, "POST", self.h,
                 {"mode": "preview", "prompt": prompt[:600], "art_style": "realistic"})
        if not r:
            return None, "request failed"
        try:
            d = json.loads(r)
        except json.JSONDecodeError:
            return None, "bad response: %s" % r[:160]
        tid = d.get("result") or d.get("id")
        return (tid, None) if tid else (None, str(d)[:160])

    def poll(self, task_id):
        r = curl("%s/%s" % (self.base, task_id), "GET", self.h)
        if not r:
            return "error", None
        try:
            d = json.loads(r)
        except json.JSONDecodeError:
            return "error", None
        status = str(d.get("status", "")).upper()
        if status == "SUCCEEDED":
            return "done", (d.get("model_urls") or {}).get("glb")
        if status in ("FAILED", "CANCELED", "EXPIRED"):
            return "failed", None
        return "running", None


PROVIDERS = {"tripo": Tripo, "meshy": Meshy}


def load_jobs(kind, limit, skip_existing=True):
    if not os.path.exists(JOBS):
        sys.exit("no %s — run scripts/export_asset_prompts.py first" % JOBS)
    jobs = []
    with open(JOBS, encoding="utf-8") as fh:
        for line in fh:
            j = json.loads(line)
            if kind != "all" and j["kind"] != kind:
                continue
            if skip_existing and os.path.exists(os.path.join(REPO, j["target"])):
                continue
            jobs.append(j)
    return jobs[:limit] if limit else jobs


def run_job(provider, job):
    task_id, err = provider.submit(job["prompt"])
    if not task_id:
        return False, err or "submit failed"

    waited = 0
    while waited < POLL_TIMEOUT:
        time.sleep(POLL_SECONDS)
        waited += POLL_SECONDS
        state, url = provider.poll(task_id)
        if state == "done":
            if not url:
                return False, "finished with no model url"
            dest = os.path.join(REPO, job["target"])
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            if not curl(url, out=dest):
                return False, "download failed"
            with open(dest, "rb") as fh:
                if fh.read(4) != b"glTF":
                    os.remove(dest)
                    return False, "not a GLB"
            return True, None
        if state == "failed":
            return False, "generation failed"
    return False, "timed out after %ds" % POLL_TIMEOUT


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--provider", choices=sorted(PROVIDERS), default="tripo")
    ap.add_argument("--kind", default="race",
                    help="race / frame / morph_rig / entity / slot / all")
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--dry-run", action="store_true",
                    help="list the batch without submitting anything")
    args = ap.parse_args()

    jobs = load_jobs(args.kind, args.limit)
    if not jobs:
        print("nothing to do — every target for kind=%s already exists" % args.kind)
        return 0

    print("%s · %d jobs · kind=%s" % (args.provider, len(jobs), args.kind))
    if args.dry_run:
        for j in jobs:
            print("   %-46s %s" % (j["target"], j["prompt"][:90]))
        print("\ndry run — nothing submitted")
        return 0

    cls = PROVIDERS[args.provider]
    key = os.environ.get(cls.env)
    if not key:
        sys.exit("set %s to run against %s" % (cls.env, cls.name))
    provider = cls(key)

    ok = failed = 0
    for i, job in enumerate(jobs, 1):
        print("[%d/%d] %s" % (i, len(jobs), job["target"]), flush=True)
        good, err = run_job(provider, job)
        if good:
            size = os.path.getsize(os.path.join(REPO, job["target"])) / 1e6
            print("        ok, %.2f MB" % size)
            ok += 1
        else:
            print("        !! %s" % err)
            failed += 1

    print("\n%d generated, %d failed" % (ok, failed))
    if ok:
        print("Kenney/Poly Haven models were re-packed to embed textures; if these "
              "arrive with external references, run the same embed step before "
              "committing.")
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
