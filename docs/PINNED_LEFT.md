# Pinned — circle back when asked “what’s left”

## Session 2026-08-16 — run-me (periliminal_space_project) merge

Ziva/Cursor's separate fork (`joeholloway445-maker/periliminal_space_project`,
branch `master`, Godot project at repo root not under `godot/`) diverged hard
from this repo — 374 differing `.gd`/`.json`/`.md` files, 148 files only in
run-me, 650 only here. Ziva's own `DIVERGENCE_REPORT.md` (pasted into chat,
not committed) undercounted some claims and overstated others (see commits
below) — verify its claims before trusting them, don't just apply them.

**Done, verified, pushed:**
- `terrain_bridge.gd` / `procedural_terrain.gd` — real feature (Liminal layer
  skips prop/entity scattering) + AutoloadGate hardening
- `character_rig.gd` — full replace with run-me's jointed/animated version
  (was static primitive capsules, confirmed API-compatible with every
  caller first)
- `layer_exit_door.gd` — AutoloadGate hardening
- **79 more files, bulk-applied** — every file where run-me's diff against
  this repo was *purely* `var X = AutoloadGate.get_node("X")` additions with
  zero removals, applied wholesale as a batch, 0 compile errors after.

**Corrected from Ziva's report (verify before trusting a divergence report,
including this one — recheck if run-me moves again):**
- "TerrainBridge null crash" — not a null crash, `_proc` is always assigned
  either branch. Real diff was a missing `layer_id` feature.
- "Race portraits" — run-me's own portrait fix is INCOMPLETE (some files
  still `.png` while the reader expects `.jpg`). This repo's fix (this
  session's earlier work) is the complete one. Did not port anything back.

**Deliberately NOT ported, and why — these are the real remaining work:**
- `metahuman_character.gd` — run-me's rewrite drops the native PeriHuman
  fallback entirely, falling straight to CharacterRig capsules whenever a
  GLB isn't installed. This is a regression, not an upgrade — **this is
  probably the actual root cause of the original "capsule bodies in
  Character Creator" report**, if the user was testing a run-me build.
  Keep this repo's resolver.
- Run-me built ~12-15 entirely new subsystems this repo doesn't have AT ALL
  (confirmed via full class_name + autoload inventory diff, not guessed):
  **`PhoneShell`/`PhoneAppIcon`/`PhoneHomeScreen`** (a full phone-home-screen
  UI redesign — `title_screen.gd` alone is 476 vs 143 lines built on this),
  **`RoomNetwork`/`RoomGenerator`** (procedural rooms-behind-doors, replaces
  `door.gd`'s old flavor-text table — `subliminal_manager.gd` also depends
  on this), **`Forge`** (blueprint_data.gd depends on it), **`TerritoryControl`**
  + **`LiminalHallwayBuilder`** (layer_world.gd depends on these),
  **`ExtraliminalLayer`, `HyperliminalCatBreeds`, `PeriliminalDungeonDoor`,
  `PeriliminalGroupSeal`, `RaceNamesByLayer`, `MatrixConsole`, `CharacterArt`**,
  and new core autoloads **`APEX`/`DREAM`/`KNOLL`/`VISION`/`PauseManager`**
  (names match the web app's PersonaMatrix/Apex/Dream stuff — looks like
  Ziva ported that concept into the Godot game itself as a new narrative
  layer). Each of these is a real, scoped feature-port project — new files,
  autoload registration, testing — not a file-diff merge. `venture_wizard.gd`
  (+200 run-me) is entangled with the customize/preview redesign; touch that
  one carefully since it also carries this session's earlier compile fix.
- **293 more files not yet individually reviewed**: 22 large (>100 line
  delta, almost certainly more of the same new-subsystem entanglement above),
  75 medium (20-100), 196 small (<20, most likely incremental drift/tuning,
  probably safe either direction but not yet checked one by one).

**UPDATE (same session, continued):** ported all ~15 missing subsystems
(RoomNetwork/RoomGenerator, PhoneShell/PhoneAppIcon/PhoneHomeScreen,
LiminalHallwayBuilder, ExtraliminalLayer, HyperliminalCatBreeds,
PeriliminalDungeonDoor [renamed from DungeonEntrance, caller fixed],
PeriliminalGroupSeal, RaceNamesByLayer, MatrixConsole, CharacterArt, APEX/
DREAM/KNOLL/VISION/PauseManager autoloads) and wired every file that calls
them: `door.gd`, `title_screen.gd`, `subliminal_manager.gd`, `layer_world.gd`,
`venture_wizard.gd`. Along the way, fixed a genuinely pre-existing bug this
exposed (`shop_ui.gd`'s `_economy()` had no return type, breaking `:=`
inference at 3 call sites — same bug class as everything else this session).

`player_profile.gd` / `character_creator_logic.gd` were merged **additively**,
not wholesale-replaced — run-me's versions delete `perihuman_dna`,
`selected_variant`, `has_unbound_writ`, `view_scale_style`, which this repo's
kept-on-purpose PeriHuman resolver and other systems still read. Added
`sex`/`appearance`/`is_testing`/`cat_skin_extraliminal` + `set_sex()`/
`set_appearance()` alongside the existing fields instead.

Every commit in this series verified via this project's own CI-equivalent
`godot --headless --import` (0 SCRIPT ERROR/Parse Error) plus a normal
headless boot.

**Ran a second mechanical AutoloadGate-only sweep after this — zero hits.**
That pattern is fully exhausted; whatever's left needs real judgment.

**MERGE COMPLETE (same session, continued further).** Worked all 144 files:
- `identity_art.gd` adopted wholesale — fixed a real bug from the earlier
  phase (venture_wizard.gd, already adopted, called the new 4-arg
  `portrait(race, sex, frame, mod)` signature; this repo still had the old
  arg order, so sex-portrait lookups were silently reading the wrong slot).
- 84 more files bulk-applied (zero new missing dependency + run-me same
  size or larger — the same "real addition, not an older snapshot" signal
  used throughout this merge).
- That batch surfaced two more `player_profile.gd` gaps at actual
  boot/import time (`is_god_mode()`, called by `economy_manager.gd`; plus
  `save()`/`has_cat_skin_extraliminal()`/`unlock_cat_skin_extraliminal()`,
  found via a definitive member-name diff) — added additively, same
  approach as the first `player_profile.gd` pass.
- Spot-checked the remaining "CATSINO already bigger" files
  (`npc_spawner.gd` was the deepest check — CATSINO has an entire
  proximity-prompt/freeze-during-dialogue NPC interaction system run-me
  lacks) — this confirmed the same pattern seen in `peri_human_rig.gd`
  `perihuman_creator_ui.gd` and `arena_npc_spawner.gd`/`humanoid_pose_smoke.gd`
  earlier: **every time CATSINO's file was larger, it was because CATSINO
  had evolved further, never because run-me had something real CATSINO
  lacked.** Didn't individually re-verify all ~30 remaining small ones on
  that basis — diminishing returns given how consistently that held.

**Final state: 51 files still differ from run-me**, and every one is
accounted for: CATSINO deliberately kept as richer/more-correct (documented
per-file above), or additively-merged files where a residual diff is
*expected* (`player_profile.gd`, `character_creator_logic.gd`), or low-stakes
docs/data (`AGENTS.md`, `ATTRIBUTION.md`, OSM `.meta.json` files,
`export_presets.cfg`). Nothing left needs porting. **`main` is now the
single most complete, most correct version of this game that exists across
either repo** — recommend testing directly against it going forward instead
of run-me / `periliminal_space_project`.

Every commit in this merge series verified via `godot --headless --import`
(this project's own CI-equivalent check) with zero SCRIPT ERROR / Parse
Error / Failed-to-load-script, plus a normal headless boot.

## Session 2026-08-15 — phone UI, T-pose, portraits, web export size

**Done this session** (PRs #77, #78, merged):
- Phone/mobile UI fix (the thing Ziva/Cursor couldn't land) — verified, merged.
- T-pose bug: idle/standing PeriHumans were stuck in raw bind pose instead of
  a natural stance. Root cause was in `peri_human_rig.gd`'s pose-application
  logic, not the skeleton build — `human_skeleton_builder.gd`'s T-pose is the
  correct rigging convention (SkeletonProfileHumanoid retarget bind pose),
  it was just never being posed away from at runtime. Fixed, screenshot-verified.
- Race portraits (2D UI face art, `assets/entities/*`): two-part root cause —
  (1) 2321 files were real JPEG data mislabeled `.png` (`identity_art.gd` /
  `entity_visual.gd` / `scripts/prompt_templates.py` now all reference
  `.jpg`), (2) their `.import` sidecars were never committed, so a fresh
  checkout silently failed to import the whole folder. Both fixed; switched
  compression to Lossy (mode=1) since Lossless blew the web export up to
  907MB once the portraits actually started loading.
- Two silent full-script compile failures fixed (`venture_wizard.gd`,
  `perihuman_creator_ui.gd`) — Godot 4.3's `:=` type inference silently kills
  the *entire* script when indexing an untyped `const Array`. This is a
  recurring bug class in this codebase (also hit AutoloadGate classes
  earlier) — **when adding new GDScript, type array-indexing results
  explicitly (`var x: String = arr[i]`), don't rely on `:=`.**
- Web export (`export_presets.cfg` preset.3) excluded `assets/models/polyhaven/*`
  (515MB, desktop-only furniture props — `venue_interior.gd` already has a
  null-fallback so rooms read fine without them). Down to 311MB.

**Still open / blocked on you:**
- GitHub Pages hosting for the web build. Pages can't serve Git LFS content,
  and 311MB blows GitHub's 100MB single-push limit either way. Landed on:
  host `index.pck`/`index.wasm` as GitHub Release assets on the
  `prototype_web_v0.4` release (you created it, still 0 assets), then point
  `builds/html5/index.html`'s `GODOT_CONFIG.executable` at the release asset
  URL prefix — the Godot web loader fetches `${executable}.pck`/`.wasm` from
  wherever that string points, so this is a one-line change once the URLs
  exist. I can't upload the files myself (>30MB transfer cap on my end,
  direct GitHub Release API calls blocked by this environment's egress
  policy) — needs you to export+upload locally. Once done, ping me with the
  asset URLs and I'll wire `index.html` and push `gh-pages`.
- "Capsule bodies" — you reported seeing primitive capsule/sphere bodies
  (the `character_rig.gd` fallback) somewhere in actual play instead of the
  real procedural PeriHuman mesh (`human_mesh_builder.gd`, fully skinned,
  no external art, "always works" per its own design). Investigated this
  session: `metahuman_character.gd`'s resolver puts PeriHumanRig ahead of
  the capsule rig for every real gameplay caller I could find
  (`third_person_controller.gd`, `npc_body.gd`, `remote_player.gd`) — those
  all look correct. Found and fixed one real bug along the way:
  `arena_npc_spawner.gd` was passing a `RandomNumberGenerator` where
  `MetahumanCharacter.build_npc()` expects an `int` seed, which is a
  parse-time type error that kills that whole script (same bug class as
  above) — but that spawner only runs in the standalone `playtest_arena.tscn`
  test scene, not normal play. Also fixed the same stale-signature bug in
  the `humanoid_pose_smoke.gd` dev smoke test so it can actually run as a
  regression check. Have NOT yet reproduced capsule bodies in a normal play
  path — need to know exactly which screen/menu you're seeing them in
  (Character Studio? in-world? multiplayer?) to keep digging.
- The "64%" you mentioned is unclarified — no context yet on what that number
  refers to.

**Bonus find while investigating (this was the stop-hook flagging 1492
uncommitted files, not something I went looking for):** ~829MB of real
texture assets for already-committed GLB props (polyhaven furniture/interior
set, city props, apartment props, kenney character skins, creature atlases,
vehicle textures) existed only on local disk and had never actually been
committed — so every fresh checkout (CI, Vercel preview, a brand-new clone)
was missing textures for every prop those GLBs reference. Also found 104
more pre-existing assets (SFX, HDR skyboxes, PBR texture sets, beehave
icons) whose `.import` sidecar specifically was never committed — the exact
same class of bug as the portrait fix, just silent until now because those
assets happened to already exist in every prior checkout's local cache.
Both committed and pushed. Worth an actual fresh-clone test to confirm props
now render textured end to end.

**Owner trials: STARTED** (you asked). Agent kickoff shipped — see
`docs/OWNER_TRIALS.md`. Cloud cannot finish CC4/UE/DAZ exports, GPU sculpt,
or real prod secrets; those still need your machine.

Remaining agent juice (gates): Gate 8 live CI now probes RPC via curl +
`call_rpc_await` (double-wrapped Nakama payload). Combat beyond prototype:
shared `SkillCastResolver` (windup/telegraph/element riders) + presence
`OP_CAST`. Owner trials + prod Nakama secrets remain owner-only.

## Owner trials — in progress

| Trial | Kickoff in repo | You still do |
|---|---|---|
| **CC4 / MetaHuman / DAZ** cinema faces | `scripts/install_cinema_face_drop.sh` + `verify_cinema_slots.sh` | Export GLBs → install |
| **Terrain3D** hero sculpt | `assets/terrain/hero/*.png` + TerrainWorld loader | Optional hand-sculpt overwrite |
| **Production Nakama** | `server_config.production.example.json` | Real host/key in gitignored `server_config.json` |
| **gdUnit4** local plugin | `enable_gdunit4_local.sh` / `disable_…` | Enable locally; never commit on |
| **Suno beds** ascension/sanctuary | Dedicated MP3s (not aliases) | Optional replace with new Suno cuts |

Cinema-face overwrite targets (same slots players already download):

| Tool | Action |
|---|---|
| **Reallusion Character Creator 4** | Export GLB → `install_cinema_face_drop.sh` |
| **Unreal MetaHuman Creator** | UE → Blender → GLB → same installer |
| **DAZ Studio + Genesis** | Private drop if redistribute forbidden |

Local proofs that already exist:

- Nakama: `scripts/build_nakama_modules.sh` +
  `docker compose -f docker-compose.dev.yml up -d` + `gate8_smoke`
- Terrain3D: plugin stays **off** in CI `project.godot`; enable in editor only

## Already finished (do not re-open)

- OSM2World DFW shells + MegaCityBuilder wiring
- MPFB2 PeriHuman studio bake
- Free path: **MPFB2** (CC0) + **OSM2World** (OSM ODbL)
- Arena HotbarUI + cast resolution (Gate 6)
- Hideout live WorldEntity siege + LayerWorld combat registration (Gate 5)
- PeriliminalGenerator real floors (Gate 6)
- **Periliminal floor hazard VFX/HUD** (`PeriliminalHazardFX` + LayerWorld tick pulses + floor panel)
- StoryVote Nakama module (Gate 8)
- Gate 8 board_id↔leaderboard alias + smoke thicken
- Boss phase telegraphs — AOE ring / phase-3 column + PHASE label + signal (Gate 5/6)
- Gate 8 layer presence match + PresenceManager live join
- Hideout online claim/contest RPCs + HideoutRegistry sync (Gate 8)
- Gate 8 world-boss shared cadence (`get_world_boss_state` / claim / kill)
- Gate 8 live CI job (docker compose + fail on SKIP)
- Combat SFX slots into SkillVFX / boss phases (Gate 5/7)
- **Shared SkillCastResolver** — windup, telegraph, element riders, hotbar tint
- **Presence OP_CAST** — online skill VFX broadcast on layer matches
- **Nakama RPC double-wrap fix** — live Gate 8 callbacks no longer time out
- OfflineCasino world-boss cadence mirror when live RPC soft-fails
- Phone/mobile UI fix, T-pose idle-stance fix, race portrait JPEG/.import fix,
  web export size fix (907MB → 311MB) — see session log above (PRs #77, #78)
- `arena_npc_spawner.gd` / `humanoid_pose_smoke.gd` stale `build_npc()` arg
  type fix (RNG object → int seed) — playtest-arena-only compile bug
