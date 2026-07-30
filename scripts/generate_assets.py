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
import concurrent.futures
import json
import os
import subprocess
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Overridable so a composed matrix from scripts/prompt_templates.py can be
# fed straight in without regenerating the canonical job list.
JOBS = os.environ.get("ASSET_JOBS") or os.path.join(REPO, "build", "asset_jobs.jsonl")

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

    def submit(self, prompt, job=None):
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

    def submit(self, prompt, job=None):
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



class Replicate:
    """https://replicate.com — any text-to-image model, billed per prediction.

    This is the entity path. Sprites are pennies where 3D is dollars, and a
    painted creature at billboard distance beats a generated mesh anyway.
    Default model is SDXL; override with REPLICATE_MODEL (a version hash).
    """
    name = "replicate"
    env = "REPLICATE_API_TOKEN"
    base = "https://api.replicate.com/v1/predictions"
    # SDXL base. Any text-to-image version hash works.
    default_version = ("7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")
    output_kind = "image"

    def __init__(self, key):
        self.h = {"Authorization": "Bearer %s" % key}
        self.version = os.environ.get("REPLICATE_MODEL", self.default_version)

    def submit(self, prompt, job=None):
        job = job or {}
        # The authored CSV ships its own negative prompt and seed; using our
        # own would discard half the brief and make reruns unreproducible.
        negative = job.get("negative_prompt") or (
            "text, watermark, signature, multiple subjects, cropped, frame, "
            "border, photograph of a screen")
        payload = {
            "prompt": prompt[:2000],
            "negative_prompt": negative,
            "width": 768, "height": 768,
        }
        if job.get("seed") is not None:
            payload["seed"] = int(job["seed"])
        r = curl(self.base, "POST", self.h, {"version": self.version, "input": payload})
        if not r:
            return None, "request failed"
        try:
            d = json.loads(r)
        except json.JSONDecodeError:
            return None, "bad response: %s" % r[:160]
        if d.get("id"):
            return d["id"], None
        return None, str(d.get("detail", d))[:160]

    def poll(self, task_id):
        r = curl("%s/%s" % (self.base, task_id), "GET", self.h)
        if not r:
            return "error", None
        try:
            d = json.loads(r)
        except json.JSONDecodeError:
            return "error", None
        status = d.get("status", "")
        if status == "succeeded":
            out = d.get("output")
            if isinstance(out, list) and out:
                return "done", out[0]
            return "done", out if isinstance(out, str) else None
        if status in ("failed", "canceled"):
            return "failed", None
        return "running", None



class Pollinations:
    """https://pollinations.ai — keyless text-to-image, free.

    No account, no token, no billing: the prompt goes in the URL and a JPEG
    comes back. That makes it the one provider that can run right now, so it
    is the default. Quality is good enough for creature sprites; swap to
    Replicate later for the same job files if a specific model is wanted.

    Synchronous — the image IS the response — so submit downloads directly
    and poll never runs.
    """
    name = "pollinations"
    env = None                  # no key
    base = "https://image.pollinations.ai/prompt/"
    output_kind = "image"
    synchronous = True

    def __init__(self, key=None):
        self.model = os.environ.get("POLLINATIONS_MODEL", "flux")

    def fetch(self, prompt, job, dest):
        from urllib.parse import quote
        params = "width=768&height=768&nologo=true&model=%s" % self.model
        if job.get("seed") is not None:
            params += "&seed=%d" % (int(job["seed"]) % 2_000_000_000)
        # Negative prompts ride in the prompt text; the endpoint takes no
        # separate field.
        neg = job.get("negative_prompt")
        text = prompt + ((" Avoid: " + neg) if neg else "")
        url = "%s%s?%s" % (self.base, quote(text[:1800], safe=""), params)
        return curl(url, out=dest)


PROVIDERS = {"tripo": Tripo, "meshy": Meshy, "replicate": Replicate,
             "pollinations": Pollinations}


def load_jobs(kind, limit, skip_existing=True, image_targets=False):
    if not os.path.exists(JOBS):
        sys.exit("no %s — run scripts/export_asset_prompts.py first" % JOBS)
    jobs = []
    with open(JOBS, encoding="utf-8") as fh:
        for line in fh:
            j = json.loads(line)
            if kind != "all" and j["kind"] != kind:
                continue
            target = j["sprite_target"] if image_targets else j["target"]
            if skip_existing and target and os.path.exists(os.path.join(REPO, target)):
                continue
            jobs.append(j)
    return jobs[:limit] if limit else jobs


def run_job(provider, job):
    wants_image = getattr(provider, "output_kind", "model") == "image"

    if getattr(provider, "synchronous", False):
        dest = os.path.join(REPO, job["sprite_target"])
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        prompt = job["sprite_prompt"] if wants_image else job["prompt"]
        if not provider.fetch(prompt, job, dest):
            return False, "request failed"
        with open(dest, "rb") as fh:
            head = fh.read(4)
        if not (head.startswith(b"\x89PNG") or head.startswith(b"\xff\xd8")):
            os.remove(dest)
            return False, "not an image"
        return True, None

    task_id, err = provider.submit(
        job["sprite_prompt"] if wants_image else job["prompt"], job)
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
            wants_image = getattr(provider, "output_kind", "model") == "image"
            dest = os.path.join(REPO, job["sprite_target"] if wants_image
                                else job["target"])
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            if not curl(url, out=dest):
                return False, "download failed"
            with open(dest, "rb") as fh:
                head = fh.read(8)
            ok = head.startswith(b"\x89PNG") or head.startswith(b"\xff\xd8") \
                if wants_image else head.startswith(b"glTF")
            if not ok:
                os.remove(dest)
                return False, "unexpected file type"
            return True, None
        if state == "failed":
            return False, "generation failed"
    return False, "timed out after %ds" % POLL_TIMEOUT


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--provider", choices=sorted(PROVIDERS), default="pollinations",
                    help="pollinations needs no key and is the default")
    ap.add_argument("--kind", default="race",
                    help="race / frame / morph_rig / entity / slot / all")
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--jobs", help="job file (default build/asset_jobs.jsonl, "
                    "or a matrix from scripts/prompt_templates.py)")
    ap.add_argument("--workers", type=int, default=1,
                    help="parallel requests. The bottleneck is the image "
                         "service's per-image time, not this script, so N "
                         "workers is roughly an N-times speedup until the "
                         "service starts throttling. 8 is a sane start.")
    ap.add_argument("--dry-run", action="store_true",
                    help="list the batch without submitting anything")
    args = ap.parse_args()
    if args.jobs:
        globals()["JOBS"] = os.path.abspath(args.jobs)

    image_targets = getattr(PROVIDERS[args.provider], "output_kind", "model") == "image"
    jobs = load_jobs(args.kind, args.limit, image_targets=image_targets)
    if not jobs:
        print("nothing to do — every target for kind=%s already exists" % args.kind)
        return 0

    print("%s · %d jobs · kind=%s" % (args.provider, len(jobs), args.kind))
    if args.dry_run:
        for j in jobs:
            t = j["sprite_target"] if image_targets else j["target"]
            pr = j["sprite_prompt"] if image_targets else j["prompt"]
            print("   %-46s %s" % (t, pr[:90]))
        print("\ndry run — nothing submitted")
        return 0

    cls = PROVIDERS[args.provider]
    key = os.environ.get(cls.env) if cls.env else None
    if cls.env and not key:
        sys.exit("set %s to run against %s" % (cls.env, cls.name))
    provider = cls(key)

    ok = failed = 0
    done = [0]

    def _one(job):
        target = job["sprite_target"] if image_targets else job["target"]
        good, err = run_job(provider, job)
        done[0] += 1
        if good:
            size = os.path.getsize(os.path.join(REPO, target)) / 1e6
            print("[%d/%d] %s  ok, %.2f MB" % (done[0], len(jobs), target, size),
                  flush=True)
        else:
            print("[%d/%d] %s  !! %s" % (done[0], len(jobs), target, err), flush=True)
        return good

    if args.workers > 1:
        # Each worker is an independent request; the provider objects hold no
        # per-request state, so they are safe to share.
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            for good in pool.map(_one, jobs):
                ok += 1 if good else 0
                failed += 0 if good else 1
    else:
        for job in jobs:
            good = _one(job)
            ok += 1 if good else 0
            failed += 0 if good else 1

    print("\n%d generated, %d failed" % (ok, failed))
    if ok:
        print("Kenney/Poly Haven models were re-packed to embed textures; if these "
              "arrive with external references, run the same embed step before "
              "committing.")
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
