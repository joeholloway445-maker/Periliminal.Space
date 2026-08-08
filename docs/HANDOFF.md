# Handoff — state of `claude/metahumans-godot-q24q73`

Written for whoever picks this up next, human or agent. Everything below is
pushed; the working tree is clean.

## Correction pass (after the owner's review)

The owner caught real mistakes in the previous session's lore/faction work,
fixed here:

- **Only 3 factions**, not 4 — Factionless is the unjoined starting status,
  not a fourth ideology. `RACE_FACTION_OF` had 5 races wrongly tied to
  "Factionless" as if it were a historical claim faction; fixed to fall
  through to the default instead (see `persona_buckets.gd`). Faction choice
  is now enforced as permanent in code — `PlayerProfile.set_faction()`
  refuses to change an already-set faction. Player-facing copy
  (`tutorial_ui.gd`, `npc_dialogue.gd`, `screen_list.md`) corrected to match.
- **Entity Dex is already correct at 600** (150/faction × 3 factions +
  Factionless, counting evolution stages) — `entity_dex_data.gd`'s own
  header comment had this right; the wrong "~270 entities" number was only
  in a stale comment in `entity_visual.gd`, now fixed. Companion roster is
  604, not the 200/500 that had drifted into tutorial and dialogue copy.
- **Main storyline confirmed**: Theory of Everything / Solution of
  Everything vs Solution of Nothing, exactly as scaffolded — see
  `docs/STORY_SINGULARITY.md`.
- **New structural note**: the six reality layers don't share one plot —
  each gets its own local storyline (`LAYER_ARCS` in `persona_buckets.gd`),
  with the Theory war as the throughline underneath all of them, not a
  seventh competing plot.
- **Resolved**: "which race is Human" was a false alarm — "race" in this
  game means what it means in the real world (human diversity, not
  species). All 20 canon races are Human; the faction war being
  "humanity's ego" indicts all 20 at once, not one literal human among 19
  aliens. See the "Resolved" note in `docs/STORY_SINGULARITY.md`.

## The one thing that matters most

**None of this has been compiled.** It was written in a container with no
Godot binary, so it has had static checking only — balanced syntax, verified
API names, verified autoload and signal signatures, verified that every
referenced asset exists on disk. That is not the same as opening.

Whoever has the editor: **open the project, and paste back whatever the
script errors panel prints.** That is worth more than any new feature right
now. Two real parse errors were already caught this way by inspection
(`char()` was removed in Godot 4; a sky shader had a spatial-only
`render_mode`) — assume more survived.

Opening also generates the `.import` sidecars for ~120 new asset files,
which do not exist yet.

## What changed, newest first

| Commit | What |
|---|---|
| `90db0b9` | `scripts/export_asset_prompts.py` — 664 generation jobs built from the game's own descriptions |
| `38247d4` | PvP missions wired to real game signals; `ContractsUI` |
| `2800125` | `PartyManager`, offline leaderboards, `PvpMissions`, `EntityVisual` |
| `d4842d9` | Locked Periliminal dungeons with unproven ranks |
| `de35212` | Realism pass — stylised bodies retired, photoscans in |
| `f752a62` | Walk-in venue interiors |
| `509eb11` | `SHIPPING.md` §3 corrected to reality |
| `5d488ea`, `358cc30` | Two Godot 4 API fixes |
| `f21e86e`, `5f7fc82` | `OmniDex` data + proposed roster mapping |

Three new autoloads are registered in `project.godot`: `DungeonManager`,
`PartyManager`, `PvpMissions`.

## Conventions followed — please keep to these

- **UI is built in code, not `.tscn`.** `contracts_ui.gd` follows
  `arena_hub_ui.gd`. No editor was available to author scenes, and code-built
  panels drop in with `add_child(X.new())`.
- **Interaction reads raw `KEY_E`.** The project has no `"interact"` input
  action registered; `is_action_pressed("interact")` fails at runtime. See
  `venue_interact.gd`.
- **Assets resolve through `AssetLibrary`'s slot ladder**, never `load()`
  directly: `entity_<id>` → `entity_<category>` → procedural. Same shape for
  characters: `metahuman_<race>` → `metahuman_npc` → PeriHuman.
- **`instance_variant(slot, seed)`** picks among `<slot>_a`, `<slot>_b`, …
  and falls back to the plain slot. Seed it with something stable (a peer id,
  a snapped position) so a thing keeps its appearance.
- **Gameplay signals stay un-lensed.** PVXC's danger ring, layer-exit doors
  and the dungeon seal deliberately look identical to every race — a party
  has to be able to point at one door and agree it is dangerous.

## Landmines

- **Do not re-wire the Kenney humanoids into live slots.** They are parked in
  `godot/assets/models/kenney_characters/` on purpose — chibi proportions
  against photoscanned surfaces. With those slots empty the resolver falls
  through to `PeriHumanRig`, which is the intended realistic path and the
  only one that can express a race's substance. They are kept for a
  deliberately stylised reality layer, not as fallbacks.
- **`mech_tps.glb` is not a human.** It is the Godot TPS-demo mech, 23 MB,
  formerly misfiled as `player_human.glb`. Do not restore that name.
- **Venues are now solid.** They previously had no collision at all and the
  player walked through them. If a hub places one across a road it will read
  as a wall — that is the new collision, not a regression in placement.
- **`build/` is gitignored.** `asset_jobs.jsonl` is derived from committed
  data; regenerate it, do not commit it.
- **Three race rosters exist and do not match** — see below (was
  documented as two; a full sweep of the codebase found a third).

## Open decisions that need a human

1. **Roster reconciliation.** `docs/OMNIDEX_MAPPING.md` pairs the Omni Dex
   races with the canon PeriHuman races: 9 confident, 6 arguable, 5 with no
   clean partner. Nothing in code reads the mapping until someone signs off,
   because it decides which body belongs to which race.
2. **A third, unreconciled race roster.** `docs/LORE_FOUNDATION.md` has a
   full 20-race "Light/Heavy, perceptual-lens" system (Luminant, Kinetic,
   Chronal, …) that neither `docs/OMNIDEX.md` nor any code knows about.
   Nothing reads it. Needs a decision: merge into the canon races, repurpose
   as a different axis entirely, or retire it. Flagged with a status note
   at the top of that doc so it stops reading as current canon in the
   meantime.
3. **PvP mission balance.** `pvp_missions.gd`'s 5 missions aren't random —
   reward:stake holds ~2.25-3x and prestige tracks rank*1.3 consistently —
   but that curve has never been validated against real playtime-to-reward
   data. Documented in a comment at the top of the file. Preserve the ratio
   if you retune amounts.
4. **Combat loot generation is a no-op.** `combat_system_realtime.gd`'s
   `end_combat()` always emits `entity_defeated` with an empty loot array —
   there's no loot table anywhere in the codebase yet. Nothing currently
   depends on that array having contents (`pvp_missions.gd`'s handler
   discards it), so it's silent, not broken — but a real drop system is
   unbuilt, not just unbalanced.
5. **~27 MB of remaining recoverable bloat.** `godot/assets` was ~200 MB
   against a Web export target; the 23 MB mislabeled `mech_tps.glb` has
   been deleted (nothing referenced it), leaving ~33% base64 overhead on
   embedded props and duplicate material sets in some photoscans per
   `SHIPPING.md` §3. Reversible — the fetch scripts re-pull everything —
   just not done yet.

## Known incomplete, and safe to pick up

- `ContractsUI` exists but is not reachable from any menu.
- `PartyManager` has no matchmaking; invites are by name.
- 378 of the 664 generation prompts come from dex text truncated with an
  ellipsis in the source data. Usable, but worth extending before paying for
  a batch. The exporter flags each one.
- `player_cat` / `npc_cat` remain procedural — no reachable CC0 cat model.
- Interior texture sets are installed but read by nothing outside venues.
- `scripts/fetch_osm_cities.py`'s 4 hub bboxes were widened tonight to
  actually reach their listed landmarks (Margaret Hunt Hill Bridge, Fort
  Worth Stockyards, UTA campus, Denton courthouse/water-tower cluster) —
  but regenerating `godot/world_data/osm/*.json` to pick up the change
  needs a live Overpass API call, which this sandbox's network policy
  blocks (confirmed: 403 from the proxy). Re-run the script somewhere with
  open network access.
- `TARGET_SPAN` in that same script isn't runtime-tunable — it's baked into
  the generated JSON at fetch time, not read by Godot at load. Same
  network blocker applies to seeing the effect of changing it.

## Regenerating things rather than hand-editing

| Script | Produces |
|---|---|
| `scripts/fetch_polyhaven_textures.sh` | 45 PBR maps (`RES=2k` for desktop-only) |
| `scripts/fetch_polyhaven_models.py` | photoscanned props + HDRI skies |
| `scripts/fetch_kenney_packs.sh` | CC0 packs, scraping the real zip URL |
| `scripts/export_asset_prompts.py` | `build/asset_jobs.{jsonl,md}` |
| `scripts/render_model_sheet.py` | PNG thumbnails of any GLB, for review |

`src/data/omni_dex.gd` was transcribed mechanically from the workbook. If the
workbook changes, re-export and re-transcribe — hand edits will be lost.
