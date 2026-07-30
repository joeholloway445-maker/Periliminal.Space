#!/usr/bin/env python3
"""Compose prompts from parts: <subject> doing <action> at <location>.

The authored set in godot/data/entity_image_prompts/ gives one canonical
image per entity stage. That is the right thing for a sprite, but a game
needs the same subject in many poses and places — an attack frame, a dex
portrait, a creature standing in the Liminal, key art of a race in the
Metroplex. Writing those by hand is 600 x poses x places.

So subjects come from the game's own data (every race and every entity
stage), actions and locations are small authored vocabularies, and this
composes the matrix.

Two modes, because they have opposite requirements:

  sprite  Obeys STYLE_BIBLE.md exactly — locked preamble, neutral dark
          studio fog, no environment. Location is deliberately IGNORED,
          because a background breaks sprite extraction. Use for anything
          that becomes a game asset.

  scene   Subject in a real place, doing a real thing. Use for key art, dex
          illustrations, layer establishing shots — and as the input image
          for lingbot-world, which needs a scene to animate.

    python3 scripts/prompt_templates.py --list
    python3 scripts/prompt_templates.py --subject SC-EN1 --action attacking \\
        --location periliminal --mode scene
    python3 scripts/prompt_templates.py --matrix --kind race \\
        --actions idle,attacking --locations metroplex,liminal --out build/keyart.jsonl
"""

import argparse
import csv
import json
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPTS_CSV = os.path.join(REPO, "godot", "data", "entity_image_prompts",
                           "all_600_entities.csv")

# The style bible's locked preamble. Reproduced verbatim because that file
# says any prompt missing it is invalid — do not paraphrase or reorder.
LOCKED_PREAMBLE = (
    "Photorealistic dark-fantasy creature/deity concept art. Cinematic "
    "lighting: strong key light, controlled rim light, deep shadow falloff, "
    "volumetric atmosphere. Physically-based materials — real skin with "
    "pores and subsurface scattering, real metal with accurate reflectance "
    "and wear, real fire with emissive bloom, real stone with granular "
    "texture. Absolutely no cel shading, no anime, no cartoon, no "
    "illustration line-art, no painterly stylization. Grounded, "
    "anatomically plausible construction even for supernatural beings — as "
    "realistic as the deity it derives from can be: muscles, weight, joint "
    "articulation, and material physics must read as real."
)
SPRITE_FRAMING = (
    "Neutral dark studio-fog background (charcoal gradient with low-lying "
    "fog, no environment, no props, no other figures) for clean sprite "
    "extraction. Single subject, full body visible head to toe, centered in "
    "frame, 3/4 view."
)

FACTION_PALETTE = {
    "SovereignCrown": "Imperial palette of burnished gold, ivory white, and "
        "polished marble; regal ornament, halo-warm key light, celestial-court grandeur.",
    "VeiledCurrent": "Ink black, deep violet, and cold moonlit blue; "
        "yokai-realism — Japanese folklore horror rendered with documentary "
        "photorealism, wet ink sheen, lantern and moonlight accents.",
    "WildlandsAscendant": "Mud brown, wet moss green, and sun-bleached bone; "
        "primal naturalism — earth, hide, ochre, gold-circuitry relic accents "
        "weathered into organic matter.",
    "Factionless": "Weathered ancient-pantheon materials — eroded stone, "
        "oxidized bronze, verdigris, aged patina; museum-relic gravitas, "
        "timeless and faction-neutral.",
}

STAGE_SCALE = [
    "Stage 1 (juvenile): roughly human scale (5-7 ft), lean and unproven; "
    "emerging powers only hinted at in surface detail; camera at eye level.",
    "Stage 2 (elite): 8-12 ft, battle-worn and hardened; scars, layered "
    "armor-growth, visibly active power channels; slightly low camera angle "
    "conveying threat.",
    "Stage 3 (apex): 20 ft and beyond, cinematic god-scale; overwhelming "
    "presence, atmosphere reacting to the body (fog displacement, ground "
    "stress); dramatic low-angle hero shot while keeping full body in frame.",
]

# --- the vocabularies ------------------------------------------------------

ACTIONS = {
    "idle": "standing at rest, weight settled on one leg, alert but unthreatened",
    "attacking": "mid-attack, weight driving forward, weapon or limb committed, "
                 "muscle and cloth reacting to the motion",
    "defending": "braced defensively, guard raised, body angled away from an "
                 "incoming blow",
    "channeling": "channeling power, arms raised, energy visibly gathering at "
                  "the hands and eyes, air distorting around the body",
    "wounded": "wounded and still standing, favouring one side, visible damage "
               "to armour and skin, breath heavy",
    "stalking": "stalking low and silent, head level, deliberately placed steps",
    "emerging": "emerging from cover or shadow, half-revealed, only partly lit",
    "portrait": "head and shoulders portrait, direct eye contact with the "
                "viewer, shallow depth of field",
    "triumphant": "standing over a defeated foe, chest open, head raised",
}

# Locations are the game's own places. Reality layers first, then the hubs.
LOCATIONS = {
    "hyperliminal": "inside a neon casino floor at night, slot-machine glow, "
                    "cigarette haze, deep carpet, mirrored ceiling",
    "liminal": "in a liminal in-between space — empty fluorescent corridor, "
               "damp carpet, doors that do not line up, no visible exit",
    "periliminal": "in the Periliminal — a space that is wrong at a structural "
                   "level, impossible geometry, light arriving from no source, "
                   "deep colour bleed at the edges of vision",
    "subliminal": "in a small lived-in apartment, warm lamps, personal clutter, "
                  "rain on the window",
    "supraliminal": "on a rain-slick Dallas street at night, wet asphalt, neon "
                    "reflections, traffic light bloom, distant skyline",
    "extraliminal": "in an overlay of the real world — the city visible but "
                    "translucent, territory boundaries drawn in light across "
                    "the ground",
    "metroplex": "in the DFW Metroplex at dusk, concrete overpasses, glass "
                 "towers, heat shimmer off the road",
    "stockyards": "in the Fort Worth Stockyards, weathered timber pens, dust, "
                  "low sun through slatted fences",
    "arena": "in a floodlit combat arena, packed dark stands, churned ground, "
             "dust hanging in the light",
    "dungeon": "in a sealed Periliminal descent — a service stairwell that "
               "goes further down than the building is tall, emergency "
               "lighting, condensation on concrete",
}

SCENE_FRAMING = (
    "Cinematic wide shot, subject full body and clearly readable against the "
    "environment, natural interaction between subject and place, atmospheric "
    "depth. No text, no watermark, no UI."
)
NEGATIVE = (
    "anime, cartoon, cel shading, illustration, flat colors, chibi, low poly, "
    "text, watermark, multiple subjects, blurry, deformed anatomy, extra "
    "limbs beyond described"
)


# --- subjects, from the game's own data ------------------------------------

def load_subjects():
    """{id: {name, kind, description, faction, stage}} for races and entities."""
    subjects = {}

    dex_path = os.path.join(REPO, "godot", "src", "data", "entity_dex_data.gd")
    dex = {}
    if os.path.exists(dex_path):
        src = open(dex_path, encoding="utf-8").read()
        for block in re.split(r"\n\s*\{id=", src)[1:]:
            m = re.match(r'"([A-Z0-9\-]+)"', block)
            if m:
                dex[m.group(1)] = (re.search(r'faction="(\w+)"', block)
                                   or [None, "Factionless"])[1]

    if os.path.exists(PROMPTS_CSV):
        with open(PROMPTS_CSV, newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                stage = max(int(row.get("stage", 1)) - 1, 0)
                key = row["entity_id"] if stage == 0 else "%s_s%d" % (row["entity_id"], stage)
                # Strip the authored preamble/palette/scale back off so the
                # entity's own description can be recomposed with new parts.
                body = row["prompt"]
                if LOCKED_PREAMBLE[:60] in body:
                    body = body.split(SPRITE_FRAMING)[-1]
                for pal in FACTION_PALETTE.values():
                    body = body.replace(pal, "")
                for sc in STAGE_SCALE:
                    body = body.replace(sc, "")
                subjects[key] = {
                    "name": row.get("stage_name", row["entity_id"]),
                    "kind": "entity",
                    "description": body.strip(),
                    "faction": dex.get(row["entity_id"], "Factionless"),
                    "stage": stage,
                    "seed": row.get("seed"),
                }

    # Frames and morph rigs are subjects too — a frame is worn armour and a
    # morph rig is a body plan, both of which are drawable.
    reg = os.path.join(REPO, "godot", "src", "data", "omni_dex_registry.gd")
    if os.path.exists(reg):
        rsrc = open(reg, encoding="utf-8").read()
        blk = re.search(r"const FRAMES: Array\[Dictionary\] = \[(.*?)\n\]", rsrc, re.S)
        if blk:
            for fid, fname, ftype, frole in re.findall(
                    r'\{id="(\w+)", name="([^"]*)", type="(\w+)", role="([^"]*)"\}',
                    blk.group(1)):
                subjects["frame_" + fid] = {
                    "name": "%s frame" % fname, "kind": "frame",
                    "description": ("A %s-class %s combat frame — worn powered "
                                    "armour built for the %s role, fitted to a "
                                    "humanoid wearer." % (ftype, fname, frole)),
                    "faction": "Factionless", "stage": 0, "seed": None,
                }

    rigs = os.path.join(REPO, "godot", "src", "data", "morph_rig_data.gd")
    if os.path.exists(rigs):
        msrc = open(rigs, encoding="utf-8").read()
        for mid, mname in re.findall(r'\{id="(\w+)", name="([^"]*)"', msrc):
            desc = re.search(r'id="%s".*?desc="([^"]*)"' % mid, msrc, re.S)
            bonus = re.search(r'id="%s".*?bonus="([^"]*)"' % mid, msrc, re.S)
            subjects["morph_" + mid] = {
                "name": "%s rig" % mname, "kind": "morph_rig",
                "description": ("A %s morphological rig — %s%s" % (
                    mname, desc.group(1) if desc else "an altered body plan.",
                    (" Grants %s." % bonus.group(1)) if bonus else "")),
                "faction": "Factionless", "stage": 0, "seed": None,
            }

    omni = os.path.join(REPO, "godot", "src", "data", "omni_dex.gd")
    if os.path.exists(omni):
        src = open(omni, encoding="utf-8").read()
        m = re.search(r"const RACES: Dictionary = \{(.*?)\n\}", src, re.S)
        if m:
            for entry in re.split(r'\n\t"', m.group(1))[1:]:
                rid = entry.split('"', 1)[0]
                desc = (re.search(r'"description": "([^"]*)"', entry) or [None, ""])[1]
                lore = (re.search(r'"lore": "([^"]*)"', entry) or [None, ""])[1]
                fac = (re.search(r'"faction": "([^"]*)"', entry) or [None, ""])[1]
                fac_key = {"sovereign_crown": "SovereignCrown",
                           "veiled_current": "VeiledCurrent",
                           "wildlands_ascendants": "WildlandsAscendant"}.get(fac, "Factionless")
                if desc:
                    subjects[rid] = {
                        "name": (re.search(r'"name": "([^"]*)"', entry) or [None, rid])[1],
                        "kind": "race",
                        "description": "%s %s" % (desc, lore),
                        "faction": fac_key,
                        "stage": 0,
                        "seed": None,
                    }
    return subjects


# --- composition -----------------------------------------------------------

def compose(subject, action=None, location=None, mode="sprite"):
    """<subject> doing <action> at <location>, in style-bible order."""
    parts = [LOCKED_PREAMBLE]

    if mode == "sprite":
        # Style bible rule 3: background stays neutral regardless of lore.
        parts.append(SPRITE_FRAMING)
    parts.append("%s — %s" % (subject["name"], subject["description"]))

    if action:
        parts.append("Pose: %s." % ACTIONS.get(action, action))
    if location and mode != "sprite":
        parts.append("Setting: %s." % LOCATIONS.get(location, location))
        parts.append(SCENE_FRAMING)

    parts.append(FACTION_PALETTE.get(subject.get("faction", ""), FACTION_PALETTE["Factionless"]))
    parts.append(STAGE_SCALE[min(int(subject.get("stage", 0)), 2)])
    return " ".join(p.strip() for p in parts if p and p.strip())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true", help="show subjects, actions, locations")
    ap.add_argument("--subject")
    ap.add_argument("--action")
    ap.add_argument("--location")
    ap.add_argument("--mode", choices=["sprite", "scene"], default="sprite")
    ap.add_argument("--matrix", action="store_true", help="every combination")
    ap.add_argument("--kind",
                    choices=["race", "entity", "frame", "morph_rig", "all"],
                    default="all")
    ap.add_argument("--actions", help="comma-separated, for --matrix")
    ap.add_argument("--locations", help="comma-separated, for --matrix")
    ap.add_argument("--limit", type=int)
    ap.add_argument("--out", default=os.path.join(REPO, "build", "composed_prompts.jsonl"))
    args = ap.parse_args()

    subjects = load_subjects()

    if args.list:
        from collections import Counter
        counts = Counter(v["kind"] for v in subjects.values())
        races = [k for k, v in subjects.items() if v["kind"] == "race"]
        ents = [k for k, v in subjects.items() if v["kind"] == "entity"]
        print("subjects: " + ", ".join("%d %s" % (n, k) for k, n in sorted(counts.items())))
        print("  races  :", ", ".join(sorted(races)))
        print("  entities: %s ..." % ", ".join(sorted(ents)[:8]))
        print("\nactions  :", ", ".join(ACTIONS))
        print("locations:", ", ".join(LOCATIONS))
        return 0

    if args.subject:
        s = subjects.get(args.subject)
        if not s:
            print("no such subject: %s (try --list)" % args.subject)
            return 1
        print(compose(s, args.action, args.location, args.mode))
        return 0

    if not args.matrix:
        print("nothing to do — pass --list, --subject, or --matrix")
        return 1

    actions = (args.actions or "idle").split(",")
    locations = (args.locations or "").split(",") if args.locations else [None]
    picked = {k: v for k, v in subjects.items()
              if args.kind == "all" or v["kind"] == args.kind}

    rows = []
    for sid, s in sorted(picked.items()):
        for a in actions:
            for loc in locations:
                rows.append({
                    "subject": sid, "kind": s["kind"], "name": s["name"],
                    "action": a, "location": loc, "mode": args.mode,
                    "sprite_target": "godot/assets/entities/%s%s%s.png" % (
                        sid.lower(), "_" + a if a != "idle" else "",
                        "_" + loc if loc else ""),
                    "prompt": compose(s, a, loc, args.mode),
                    "sprite_prompt": compose(s, a, loc, args.mode),
                    "negative_prompt": NEGATIVE,
                    "seed": int(s["seed"]) if str(s.get("seed") or "").isdigit() else None,
                    "target": "",
                    "truncated_source": False,
                })
                if args.limit and len(rows) >= args.limit:
                    break
            if args.limit and len(rows) >= args.limit:
                break
        if args.limit and len(rows) >= args.limit:
            break

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as fh:
        for r in rows:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")
    print("%d prompts (%d subjects x %d actions x %d locations) -> %s"
          % (len(rows), len(picked), len(actions), len(locations), args.out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
