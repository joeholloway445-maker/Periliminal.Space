#!/usr/bin/env python3
"""Emit a generation job list for every asset the game still wants.

The game already states what each missing asset should look like — the Omni
Dex carries an art prompt per race/frame/morph rig, the entity dex carries a
staged physical description for all ~270 entities, and AssetLibrary declares
the slots. This walks all three and writes one job per wanted file, with the
prompt built from the game's own words and the exact target path.

The output is generator-agnostic on purpose. The same jobs file drives a
Tripo or Meshy API run, a local Hunyuan3D batch, or a copy-paste session in
an in-editor assistant — pick the backend later without redoing the briefs.

    python3 scripts/export_asset_prompts.py
    python3 scripts/export_asset_prompts.py --kind entities --limit 20

Writes:
    build/asset_jobs.jsonl   one JSON job per line, for a runner
    build/asset_jobs.md      the same list, readable, for pasting by hand
"""

import argparse
import json
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS = os.path.join(REPO, "godot", "assets", "models")
OUT_DIR = os.path.join(REPO, "build")

# House style appended to every 3D prompt, so a batch comes back coherent
# rather than as twenty unrelated art directions.
STYLE_3D = (
    "Realistic game-ready 3D asset, physically based materials, clean "
    "topology, neutral A-pose where humanoid, no ground plane, no text, "
    "single subject centred."
)
STYLE_2D = (
    "Game UI icon, centred single subject on transparent background, "
    "readable at 64x64, no text, no border."
)


def read(path):
    with open(os.path.join(REPO, path), encoding="utf-8") as fh:
        return fh.read()


def existing_slots():
    """Basenames already present in assets/models (any subfolder)."""
    have = set()
    for root, _dirs, files in os.walk(MODELS):
        for f in files:
            if f.endswith((".glb", ".gltf")):
                have.add(os.path.splitext(f)[0])
    return have


# ---------------------------------------------------------------- entities

def entity_jobs(limit=None):
    """One job per entity stage — the dex descriptions are already art briefs."""
    src = read("godot/src/data/entity_dex_data.gd")
    jobs = []
    # Entries look like: {id="SC-P5", faction="...", category="...",
    #                     role="...", stages=[{name="X", desc="..."}, ...]}
    for block in re.split(r"\n\s*\{id=", src)[1:]:
        eid = re.match(r'"([A-Z0-9\-]+)"', block)
        if not eid:
            continue
        eid = eid.group(1)
        faction = (re.search(r'faction="(\w+)"', block) or [None, ""])[1]
        category = (re.search(r'category="(\w+)"', block) or [None, ""])[1]
        role = (re.search(r'role="(\w+)"', block) or [None, ""])[1]

        for stage, (name, desc) in enumerate(
                re.findall(r'\{name="([^"]*)",\s*desc="((?:[^"\\]|\\.)*)"', block)):
            if not desc.strip():
                continue
            desc = desc.replace('\\"', '"').strip()
            # The dex truncates some entries with an ellipsis; that is still a
            # usable brief, just note it so a human can extend it.
            truncated = desc.endswith("…") or desc.endswith("...")
            jobs.append({
                "kind": "entity",
                "id": eid,
                "stage": stage,
                "name": name,
                "target": "godot/assets/models/entity_%s.glb" % eid.lower()
                          if stage == 0 else
                          "godot/assets/models/entity_%s_s%d.glb" % (eid.lower(), stage),
                "icon_target": "godot/assets/ui/entities/%s_s%d.png" % (eid.lower(), stage),
                "prompt": "%s. %s Faction %s, %s category%s. %s" % (
                    name, desc, faction or "unaligned", category or "unknown",
                    ", %s-tier" % role.lower() if role else "", STYLE_3D),
                "icon_prompt": "%s. %s %s" % (name, desc[:280], STYLE_2D),
                "truncated_source": truncated,
            })
    return jobs[:limit] if limit else jobs


# ---------------------------------------------------------------- omni dex

def omnidex_jobs(limit=None):
    """Races, frames and morph rigs — the workbook wrote these as art prompts."""
    src = read("godot/src/data/omni_dex.gd")
    jobs = []
    specs = [
        ("RACES", "race", "godot/assets/models/metahuman_%s.glb"),
        ("FRAMES", "frame", "godot/assets/models/frame_%s.glb"),
        ("MORPH_RIGS", "morph_rig", "godot/assets/models/morph_%s.glb"),
    ]
    for const, kind, target in specs:
        m = re.search(r"const %s: Dictionary = \{(.*?)\n\}" % const, src, re.S)
        if not m:
            continue
        for entry in re.split(r'\n\t"', m.group(1))[1:]:
            eid = entry.split('"', 1)[0]
            name = (re.search(r'"name": "([^"]*)"', entry) or [None, eid])[1]
            desc = (re.search(r'"description": "([^"]*)"', entry) or [None, ""])[1]
            extra = []
            for field in ("role", "frame_type", "boon", "cost", "faction"):
                v = re.search(r'"%s": "([^"]*)"' % field, entry)
                if v and v.group(1):
                    extra.append("%s %s" % (field.replace("_", " "), v.group(1)))
            if not desc:
                continue
            jobs.append({
                "kind": kind,
                "id": eid,
                "stage": 0,
                "name": name,
                "target": target % eid,
                "icon_target": "godot/assets/ui/%s/%s.png" % (kind, eid),
                "prompt": "%s. %s%s. %s" % (
                    name, desc, (" " + ", ".join(extra)) if extra else "", STYLE_3D),
                "icon_prompt": "%s. %s %s" % (name, desc, STYLE_2D),
                "truncated_source": False,
            })
    return jobs[:limit] if limit else jobs


# ---------------------------------------------------------------- bare slots

# Slots the code asks for that no photoscan or CC0 pack could fill.
BARE_SLOTS = {
    "player_cat": "A lean housecat-sized feline creature, standing quadruped, "
                  "alert posture, game-ready and riggable.",
    "npc_cat": "A stray city cat, slightly scruffy, standing quadruped, "
               "game-ready and riggable.",
    "training_dummy": "A weathered combat training dummy on a heavy base, "
                      "wrapped canvas torso, wooden crossbar arms.",
    "guild_hideout": "A small fortified urban hideout building, single storey, "
                     "reinforced door, banner mount above the entrance.",
}


def slot_jobs():
    have = existing_slots()
    jobs = []
    for slot, desc in BARE_SLOTS.items():
        if slot in have:
            continue
        jobs.append({
            "kind": "slot",
            "id": slot,
            "stage": 0,
            "name": slot.replace("_", " ").title(),
            "target": "godot/assets/models/%s.glb" % slot,
            "icon_target": "",
            "prompt": "%s %s" % (desc, STYLE_3D),
            "icon_prompt": "",
            "truncated_source": False,
        })
    return jobs


# ---------------------------------------------------------------- output

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kind", choices=["all", "entities", "omnidex", "slots"],
                    default="all")
    ap.add_argument("--limit", type=int, default=None,
                    help="cap jobs per category, for a cheap trial batch")
    ap.add_argument("--skip-existing", action="store_true",
                    help="drop jobs whose target file already exists")
    args = ap.parse_args()

    jobs = []
    if args.kind in ("all", "entities"):
        jobs += entity_jobs(args.limit)
    if args.kind in ("all", "omnidex"):
        jobs += omnidex_jobs(args.limit)
    if args.kind in ("all", "slots"):
        jobs += slot_jobs()

    if args.skip_existing:
        jobs = [j for j in jobs if not os.path.exists(os.path.join(REPO, j["target"]))]

    os.makedirs(OUT_DIR, exist_ok=True)
    jsonl = os.path.join(OUT_DIR, "asset_jobs.jsonl")
    with open(jsonl, "w", encoding="utf-8") as fh:
        for j in jobs:
            fh.write(json.dumps(j, ensure_ascii=False) + "\n")

    md = os.path.join(OUT_DIR, "asset_jobs.md")
    by_kind = {}
    for j in jobs:
        by_kind.setdefault(j["kind"], []).append(j)
    with open(md, "w", encoding="utf-8") as fh:
        fh.write("# Asset generation jobs\n\n")
        fh.write("Generated by `scripts/export_asset_prompts.py`. Each prompt is "
                 "built from the game's own description of the thing.\n\n")
        for kind, items in sorted(by_kind.items()):
            fh.write("## %s (%d)\n\n" % (kind, len(items)))
            for j in items:
                flag = "  *(source description truncated)*" if j["truncated_source"] else ""
                fh.write("### %s → `%s`%s\n\n%s\n\n" % (
                    j["name"], j["target"], flag, j["prompt"]))

    counts = ", ".join("%s %d" % (k, len(v)) for k, v in sorted(by_kind.items()))
    print("%d jobs (%s)" % (len(jobs), counts))
    print("  %s" % jsonl)
    print("  %s" % md)
    trunc = sum(1 for j in jobs if j["truncated_source"])
    if trunc:
        print("  note: %d prompts come from truncated dex text — worth extending "
              "before a paid batch" % trunc)


if __name__ == "__main__":
    raise SystemExit(main())
