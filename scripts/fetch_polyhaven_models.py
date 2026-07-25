#!/usr/bin/env python3
"""Fetch CC0 photoscanned models + HDRI skies from Poly Haven.

Models arrive as .gltf + .bin + a textures/ folder. Godot imports that fine,
but AssetLibrary's slot contract is one file per slot, so each model is
re-packed into a single self-contained .glb with its textures embedded as
data URIs — the same treatment the Kenney models already got.

    python3 scripts/fetch_polyhaven_models.py            # models + hdris
    python3 scripts/fetch_polyhaven_models.py --res 2k   # sharper, ~4x size

Everything here is CC0 (public domain): commercial use OK, no attribution
required. Credited in godot/assets/models/ATTRIBUTION.md anyway.
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS_OUT = os.path.join(REPO, "godot", "assets", "models", "polyhaven")
HDRI_OUT = os.path.join(REPO, "godot", "assets", "environments")
API = "https://api.polyhaven.com/files"

# Realistic props for the mega-city (exteriors) and its interiors. Named by
# what they are, not by AssetLibrary slot — pick which slot each fills later.
MODELS = [
    # --- street / exterior ---
    "fire_hydrant", "street_lamp_01", "plastic_crate_01", "wooden_crate_02",
    "barrel_03", "planter_box_01", "painted_wooden_bench", "cardboard_box_01",
    "concrete_bollard", "traffic_cone",
    # --- interior: seating / tables ---
    "sofa_02", "sofa_03", "dining_table", "dining_chair_02",
    "coffee_table_round_01", "bar_chair_round_01", "mid_century_lounge_chair",
    # --- interior: lighting ---
    "desk_lamp_arm_01", "modern_ceiling_lamp_01", "industrial_wall_lamp",
    "hanging_industrial_lamp", "caged_hanging_light",
    "mounted_fluorescent_lights", "lightbulb_01",
    # --- interior: storage / industrial dressing ---
    "drawer_cabinet", "wooden_barrels_01", "old_military_crate",
    "industrial_storage_cart", "barrel_stove", "wine_barrel_01",
]

# Skies for DayNightSky. Night/street plates suit the Metroplex at night;
# overcast/sunset cover the day cycle.
HDRIS = [
    "cobblestone_street_night", "modern_evening_street", "dikhololo_night",
    "moonless_golf", "satara_night", "preller_drive",
    "kloofendal_overcast", "industrial_sunset", "belfast_sunset",
    "the_lost_city", "german_town_street", "potsdamer_platz",
]


def curl(url, dest=None):
    """curl, because this environment's HTTPS egress goes through a proxy
    that urllib does not pick up (it 403s)."""
    cmd = ["curl", "-sS", "--retry", "3", "--retry-delay", "2"]
    if dest:
        cmd += ["-o", dest, url]
        return subprocess.run(cmd, capture_output=True).returncode == 0
    cmd += [url]
    r = subprocess.run(cmd, capture_output=True)
    return r.stdout if r.returncode == 0 else b""


def files_json(asset):
    raw = curl(f"{API}/{asset}")
    if not raw or not raw.lstrip().startswith(b"{"):
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def fetch_model(asset, res):
    meta = files_json(asset)
    if meta is None:
        return None, "no such asset"
    entry = (meta.get("gltf") or {}).get(res, {}).get("gltf")
    if not entry or not entry.get("url"):
        return None, f"no gltf at {res}"

    with tempfile.TemporaryDirectory() as tmp:
        root = os.path.join(tmp, f"{asset}.gltf")
        if not curl(entry["url"], root):
            return None, "gltf download failed"
        # Dependent .bin and textures/ must land at their relative paths or
        # the gltf will not resolve them.
        for rel, info in (entry.get("include") or {}).items():
            dest = os.path.join(tmp, rel)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            if not curl(info["url"], dest):
                return None, f"missing dep {rel}"

        try:
            from pygltflib import GLTF2, ImageFormat
            gltf = GLTF2().load(root)
            # Embed textures so the result is one portable file per slot.
            gltf.convert_images(ImageFormat.DATAURI, path=tmp)
            out = os.path.join(MODELS_OUT, f"{asset}.glb")
            gltf.save_binary(out)
        except Exception as exc:  # noqa: BLE001 - report and keep going
            return None, f"pack failed: {exc}"

    with open(out, "rb") as fh:
        if fh.read(4) != b"glTF":
            os.remove(out)
            return None, "bad glb magic"
    return os.path.getsize(out), None


def fetch_hdri(asset, res):
    meta = files_json(asset)
    if meta is None:
        return None, "no such asset"
    entry = (meta.get("hdri") or {}).get(res, {}).get("hdr")
    if not entry or not entry.get("url"):
        return None, f"no hdr at {res}"
    out = os.path.join(HDRI_OUT, f"{asset}.hdr")
    if not curl(entry["url"], out):
        return None, "download failed"
    with open(out, "rb") as fh:
        if not fh.read(11).startswith(b"#?RADIANCE"):
            os.remove(out)
            return None, "not a radiance hdr"
    return os.path.getsize(out), None


def run(kind, names, res, fetcher):
    print(f"== {kind} @ {res}")
    ok = failed = 0
    for name in names:
        size, err = fetcher(name, res)
        if err:
            print(f"   !! {name}: {err}")
            failed += 1
        else:
            print(f"   {name:32s} {size / 1e6:6.2f} MB")
            ok += 1
    print(f"   -> {ok} ok, {failed} failed\n")
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--res", default="1k",
                    help="texture/HDRI resolution (1k default; 2k ~4x size)")
    ap.add_argument("--skip-models", action="store_true")
    ap.add_argument("--skip-hdris", action="store_true")
    args = ap.parse_args()

    os.makedirs(MODELS_OUT, exist_ok=True)
    os.makedirs(HDRI_OUT, exist_ok=True)

    if not args.skip_models:
        run("models", MODELS, args.res, fetch_model)
    if not args.skip_hdris:
        run("hdris", HDRIS, args.res, fetch_hdri)

    for label, path in (("models", MODELS_OUT), ("hdris", HDRI_OUT)):
        if os.path.isdir(path):
            total = sum(os.path.getsize(os.path.join(path, f))
                        for f in os.listdir(path)
                        if os.path.isfile(os.path.join(path, f)))
            print(f"{label}: {len(os.listdir(path))} files, {total / 1e6:.1f} MB -> {path}")


if __name__ == "__main__":
    sys.exit(main())
