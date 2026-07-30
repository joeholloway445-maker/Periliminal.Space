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
import csv
import json
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS = os.path.join(REPO, "godot", "assets", "models")
OUT_DIR = os.path.join(REPO, "build")

# House style appended to every 3D prompt, so a batch comes back coherent
# rather than as twenty unrelated art directions.
STYLE_3D = (
    "Realistic game-ready 3D character, full body head to feet, symmetrical "
    "T-pose with arms straight out and legs apart, physically based "
    "materials, clean quad topology suitable for rigging, single subject "
    "centred on a plain background, no ground plane, no props, no text, "
    "no base or pedestal."
)
# Entities ship as billboarded sprites, so this is a full creature
# illustration rather than a UI glyph — it is what the player sees in the
# world, not a list icon.
STYLE_2D = (
    "Full body creature illustration, single subject centred, facing the "
    "viewer, standing on nothing, plain flat background for easy cutout, "
    "dramatic rim lighting, painterly realistic detail, no text, no "
    "watermark, no border, no ground shadow."
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
    """One job per entity stage, from the authored prompt set.

    godot/data/entity_image_prompts/all_600_entities.csv is the real brief:
    600 prompts written against STYLE_BIBLE.md, each already carrying the
    locked preamble, the faction palette line, the stage scale line, a
    negative prompt, and a fixed seed. It covers all 270 entities with no
    truncation.

    The copies in entity_dex_data.gd are hard-cut at ~200 characters, so
    reconstructing briefs from those was throwing away the good version.
    Nothing here is generated — the prompts pass through verbatim so the
    style bible stays authoritative and reruns stay reproducible.
    """
    path = os.path.join(REPO, "godot", "data", "entity_image_prompts",
                        "all_600_entities.csv")
    if not os.path.exists(path):
        return []

    # Faction/category/role live in the dex, not the prompt CSV.
    dex = {}
    src = read("godot/src/data/entity_dex_data.gd")
    for block in re.split(r"\n\s*\{id=", src)[1:]:
        m = re.match(r'"([A-Z0-9\-]+)"', block)
        if m:
            dex[m.group(1)] = {
                "faction": (re.search(r'faction="(\w+)"', block) or [None, ""])[1],
                "category": (re.search(r'category="(\w+)"', block) or [None, ""])[1],
                "role": (re.search(r'role="(\w+)"', block) or [None, ""])[1],
            }

    jobs = []
    with open(path, newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            eid = row["entity_id"]
            # The CSV numbers stages 1-3; the engine indexes them 0-2.
            stage = max(int(row.get("stage", 1)) - 1, 0)
            meta = dex.get(eid, {})
            slug = eid.lower()
            jobs.append({
                "kind": "entity",
                "id": eid,
                "stage": stage,
                "name": row.get("stage_name", eid),
                "target": "godot/assets/models/entity_%s.glb" % slug if stage == 0
                          else "godot/assets/models/entity_%s_s%d.glb" % (slug, stage),
                "sprite_target": "godot/assets/entities/%s_s%d.png" % (slug, stage),
                # Verbatim. The style bible forbids paraphrasing these.
                "prompt": row["prompt"],
                "sprite_prompt": row["prompt"],
                "negative_prompt": row.get("negative_prompt", ""),
                # Fixed seed keeps a re-run reproducible and lets a single
                # entity be re-rolled without disturbing the rest.
                "seed": int(row["seed"]) if str(row.get("seed", "")).isdigit() else None,
                "faction": meta.get("faction", ""),
                "category": meta.get("category", ""),
                "role": meta.get("role", ""),
                "truncated_source": False,
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
            # The workbook's lore paragraph is the richest part of the brief;
            # the one-line description alone is too thin for a character.
            lore = (re.search(r'"lore": "([^"]*)"', entry) or [None, ""])[1]
            # Human-readable traits only. Raw snake_case ids (faction
            # wildlands_ascendants) are noise a generator will try to draw.
            extra = []
            for field in ("role", "frame_type", "boon", "cost"):
                v = re.search(r'"%s": "([^"]*)"' % field, entry)
                if v and v.group(1) and "_" not in v.group(1):
                    extra.append(v.group(1))
            if not desc:
                continue
            jobs.append({
                "kind": kind,
                "id": eid,
                "stage": 0,
                "name": name,
                "target": target % eid,
                "sprite_target": "godot/assets/ui/%s/%s.png" % (kind, eid),
                "prompt": "%s — %s%s%s %s" % (
                    name, desc,
                    (" " + lore) if lore and lore != desc else "",
                    (" Character traits: %s." % ", ".join(extra)) if extra else "",
                    STYLE_3D),
                "sprite_prompt": "%s — %s %s" % (name, desc, STYLE_2D),
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
            "sprite_target": "",
            "prompt": "%s %s" % (desc, STYLE_3D),
            "sprite_prompt": "",
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
