# Model & code attribution

All models below are CC0 (Creative Commons Zero / public domain) unless
noted otherwise — free for personal, educational, and commercial use, no
attribution legally required. Credited anyway because Kenney and the
Godot project earn it.

| File | Source | Pack | License |
|---|---|---|---|
| `player_human.glb`, `npc_human.glb`'s predecessor | [godotengine/tps-demo](https://github.com/godotengine/tps-demo) player model | — | MIT (Godot) |
| `city_prop.glb`, `ruin_pillar.glb`'s predecessor | godotengine/tps-demo level geometry | — | MIT |
| `city_tower.glb`, `city_lowrise.glb` | [Kenney — City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | `building-skyscraper-d`, `building-g` | CC0 |
| `city_house.glb` | [Kenney — City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | `building-type-e` | CC0 |
| `sidewalk.glb` | Kenney — City Kit (Suburban) | `path-long` | CC0 |
| `city_industrial.glb` | [Kenney — City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) | `building-m` | CC0 |
| `road_segment.glb`, `streetlight.glb`, `neon_sign.glb` | [Kenney — City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | `road-straight`, `light-square`, `sign-highway-detailed` | CC0 |
| `tree.glb` | [Kenney — Nature Kit](https://kenney.nl/assets/nature-kit) | `tree_detailed` | CC0 |
| `rock.glb` | Kenney — Nature Kit | `rock_largeA` | CC0 |
| `apartment_prop.glb` | [Kenney — Furniture Kit](https://kenney.nl/assets/furniture-kit) | `loungeSofa` | CC0 |
| `creature.glb`, `harvest_node.glb` | [Kenney — Mini Dungeon](https://kenney.nl/assets/mini-dungeon) | `character-orc`, `chest` | CC0 |
| `npc_human.glb` | [Kenney — Blocky Characters](https://kenney.nl/assets/blocky-characters) | `character-a` | CC0 |
| `ruin_pillar.glb` | [Kenney — Graveyard Kit](https://kenney.nl/assets/graveyard-kit) | `column-large` | CC0 |
| `extraction_gate.glb` | [Kenney — Space Kit](https://kenney.nl/assets/space-kit) | `gate_complex` | CC0 |
| `crystal.glb` | Kenney — Space Kit | `rock_crystalsLargeA` | CC0 |
| `rock_b.glb` | Terrain3D demo (Tokisan Games) | — | MIT |
| `npc_human_a.glb` … `npc_human_l.glb` | [Kenney — Mini Characters](https://kenney.nl/assets/mini-characters) | `character-female-a…f`, `character-male-a…f` | CC0 |
| `kenney_characters/blocky-a.glb` … `blocky-r.glb` | [Kenney — Blocky Characters](https://kenney.nl/assets/blocky-characters) | `character-a…r` | CC0 |
| `polyhaven/*.glb` (28 props) | [Poly Haven — Models](https://polyhaven.com/models) | see `scripts/fetch_polyhaven_models.py` | CC0 |

## Textures — `godot/assets/textures/`

45 PBR maps (albedo / normal / rough / metallic) covering every slot
`AssetLibrary.material()` reads, plus five interior sets. All from
[Poly Haven](https://polyhaven.com/textures), CC0. Re-fetch or change
resolution with `bash scripts/fetch_polyhaven_textures.sh` (`RES=2k` for a
desktop-only build); the slot→asset mapping lives in that script.

## HDRI skies — `godot/assets/environments/`

12 panoramas from [Poly Haven — HDRIs](https://polyhaven.com/hdris), CC0,
1k `.hdr`. `DayNightSky` cross-fades a day and a night plate through
`assets/shaders/hdri_day_night_sky.gdshader`, which re-applies the per-frame
identity tint so a photographic sky still differs per viewer. Swap which two
are used via `DayNightSky.day_hdri` / `night_hdri`; with none installed the
procedural sky carries the cycle exactly as before.

All Kenney packs above via [kenney.nl/assets](https://kenney.nl/assets) —
same source AssetLibrary/SHIPPING.md already pointed at. Each is a single
cherry-picked file out of a much larger pack (20-150+ models each); the
full packs aren't vendored, only what's wired to an `AssetLibrary` slot.

**Still open** (no free model found that clearly fit, or intentionally
left procedural): `player_cat.glb` / `npc_cat.glb` (no CC0 cat-creature
model turned up — the procedural `CharacterRig`/PeriHuman fallback still
carries this), `metahuman_player.glb` / `metahuman_npc.glb` (these are
meant to be *your own* MetaHuman exports per `docs/VISUAL_DIRECTION_ESO.md`,
not a stock download).

## Additional assets (parallel branch, merged in)

| File | Source | License |
|---|---|---|
| `metahuman_player.glb`, `peri_human_player.glb`, `player_human.glb` | [MPFB2](http://static.makehumancommunity.org/mpfb.html) + MakeHuman Community CC0 packs (system assets, skins, hair, shirts, pants, shoes) via `scripts/bake_mpfb_characters.py` | **CC0** |
| `metahuman_npc.glb`, `peri_human_npc.glb`, `npc_human.glb` | Same MPFB2 + CC0 wardrobe bake (female phenotype) | **CC0** |
| `osm2world_dallas.glb`, `osm2world_fort_worth.glb`, `osm2world_arlington.glb`, `osm2world_denton.glb` | Downtown geometry from © OpenStreetMap contributors via [OSM2World](https://osm2world.org/) (`scripts/bake_osm2world_cities.py`) | **ODbL** (geometry) |
| `variants/{metahuman_npc,peri_human_npc,npc_human}/variant_*.glb` | Same bases, skin/hair/cloth color variants | **CC0** |
| `player_cat.glb` / `npc_cat.glb` + cat variants | Procedural house-cat bake (`scripts/bake_visual_gaps.py`) | **CC0** (original) |
| `crystal.glb` + crystal variants | Procedural faceted crystal clusters (`scripts/bake_visual_gaps.py`) | **CC0** (original) |
| `creature.glb` + creature variants | [Quaternius Ultimate Monsters](https://quaternius.com/packs/ultimatemonsters.html) / [Animated Animals](https://quaternius.com/packs/ultimateanimatedanimals.html) (Demon/Yeti/Alien/Dino/Wolf/Fox) | **CC0** |
| `vehicle_aircraft_body.glb` | [Quaternius Ultimate Spaceships](https://quaternius.com/packs/ultimatespaceships.html) `Bob` | **CC0** |
| `interim/tps_player.glb` | [godotengine/tps-demo](https://github.com/godotengine/tps-demo) player (archive) | **CC-BY 3.0** |
| `interim/quaternius_*.glb` (if present) | Quaternius Ultimate Modular Males (earlier interim) | **CC0** |
| `rock.glb` | Terrain3D demo (Tokisan Games) | MIT |
| `rock_b.glb` | Terrain3D demo (Tokisan Games) | MIT |
| `vehicle_car_body.glb` (from `sedan.glb`) | [Kenney Car Kit](https://kenney.nl/assets/car-kit) | **CC0** |
| `vehicle_boat_body.glb` (from `boat-speed-a.glb`) | [Kenney Watercraft Kit](https://kenney.nl/assets/watercraft-kit) | **CC0** |
| `vehicle_spacecraft_body.glb` (from `craft_racer.glb`) | [Kenney Space Kit](https://kenney.nl/assets/space-kit) | **CC0** |
| `city_tower.glb` (from `building-skyscraper-c.glb`) | [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | **CC0** |
| `city_lowrise.glb` (from `building-e.glb`) | [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | **CC0** |
| `city_house.glb` (from `building-type-f.glb`) | [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | **CC0** |
| `city_industrial.glb` (from `building-e.glb`) | [Kenney City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) | **CC0** |
| `road_segment.glb` (from `road-straight.glb`) | [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | **CC0** |
| `sidewalk.glb` (from `tile-low.glb`) | [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | **CC0** |
| `streetlight.glb` (from `light-square.glb`) | [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | **CC0** |
| `city_prop.glb` (from `planter.glb`) | [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | **CC0** |
| `variants/city_tower/*.glb` (5 skyscrapers) | [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | **CC0** |
| `variants/city_lowrise/*.glb` (6 buildings) | [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | **CC0** |
| `variants/city_house/*.glb` (8 houses) | [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | **CC0** |
| `variants/city_industrial/*.glb` (8 buildings) | [Kenney City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) | **CC0** |
| `variants/city_prop/*.glb` (planter + 2 tree sizes) | [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | **CC0** |
| `variants/vehicle_car_body/*.glb` (sedan/sedan-sports/taxi/suv/police) | [Kenney Car Kit](https://kenney.nl/assets/car-kit) | **CC0** |
| `variants/vehicle_spacecraft_body/*.glb` (racer + 4 speeders) | [Kenney Space Kit](https://kenney.nl/assets/space-kit) | **CC0** |
| `tree.glb` + `variants/tree/*` | [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) pines / detailed trees | **CC0** |
| `rock` variants under `variants/rock/*` | [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) | **CC0** |
| `ruin_pillar.glb` + `variants/ruin_pillar/*` | [Kenney Castle Kit](https://kenney.nl/assets/castle-kit) pillars / walls | **CC0** |
| `extraction_gate.glb` | [Kenney Castle Kit](https://kenney.nl/assets/castle-kit) `gate.glb` | **CC0** |
| `city_door.glb` | [Kenney Castle Kit](https://kenney.nl/assets/castle-kit) `door.glb` | **CC0** |
| `apartment_prop.glb` + variants | [Kenney Furniture Kit](https://kenney.nl/assets/furniture-kit) | **CC0** |
| `harvest_node.glb` | [Kenney Furniture Kit](https://kenney.nl/assets/furniture-kit) `bookcaseClosedDoors.glb` | **CC0** |
| `neon_sign.glb` | [Kenney Furniture Kit](https://kenney.nl/assets/furniture-kit) `televisionModern.glb` (emissive board shell) | **CC0** |
| `godot/src/world/overworld/third_person_controller.gd` | Movement/camera physics pattern adapted from godotengine/tps-demo's `player/player.gd` (single-player rewrite, gun-robot/multiplayer scaffolding removed; ability-kit hotbar and cat/identity visual-mode switching are original) | MIT (code) |
| `godot/src/vehicles/land_vehicle.gd` | Steering/throttle model adapted from the official [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) `3d/truck_town` sample's `vehicles/vehicle.gd` (whole-repo MIT, no split code/asset license unlike tps-demo) — rewritten for our input map, procedural placeholder body/wheels, and VehicleSeat enter/exit instead of their multi-vehicle trailer/tow-truck rig | MIT (code) |
| `godot/src/vehicles/water_vehicle.gd`, `air_vehicle.gd`, `space_vehicle.gd` | Original — no equivalent official Godot demo exists for buoyancy or flight (unlike VehicleBody3D for land, Godot has no built-in boat/aircraft physics node), so these are from-scratch arcade models | MIT (code) |

**STATUS (2026-07-17): the human gap is CLOSED.** Real MPFB2/MakeHuman
bodies ship for both the player and NPCs — see the "MakeHuman-generated
humans" section at the bottom for the exact pipeline and file details.

**PeriHuman policy:** characters and NPCs **ship inside the game**. Players
never install Unreal, MakeHuman, DAZ, or Character Creator. Slots:

- `peri_human_player.glb` / `metahuman_player.glb` / `player_human.glb` — local player
- `peri_human_npc.glb` / `metahuman_npc.glb` / `npc_human.glb` — generic NPC
- `peri_human_<race_id>.glb` / `metahuman_<race_id>.glb` — optional per-race
- `variants/{metahuman_npc,peri_human_npc,npc_human}/*.glb` — NPC skin/hair/cloth
  and build (slim/average/athletic/heavy) variety, picked deterministically
  per NPC id via `AssetLibrary.instance_variant` / `MetahumanCharacter.build_npc(rng)`.

**Current look (studio bake):** MPFB2 humans with textured skin, eyes,
teeth, brows/lashes, hair, and fitted clothes (`scripts/bake_mpfb_characters.py`).
DFW hubs use OSM2World shells when `osm2world_<hub>.glb` is present.
Players never install Blender / MPFB / OSM2World. Archive: `interim/tps_player.glb`.

**Vehicle asset slots** (AssetLibrary.instance_or — drop a `.glb` in
`assets/models/` named for the slot, zero code changes needed):
- `vehicle_car_body.glb` — ✅ filled (Kenney Car Kit `sedan.glb`). Wheels
  stay procedural placeholders; swapping in a full external car rig with
  matching wheel positions is a deeper integration than a body-mesh swap,
  not yet wired.
- `vehicle_boat_body.glb` — ✅ filled (Kenney Watercraft Kit `boat-speed-a.glb`)
- `vehicle_spacecraft_body.glb` — ✅ filled (Kenney Space Kit `craft_racer.glb`)
- `vehicle_aircraft_body.glb` — ✅ filled (Quaternius Ultimate Spaceships `Bob`)

**City asset slots** (MegaCityBuilder / BuildingBuilder):
- `city_tower.glb` — ✅ filled (Kenney City Kit Commercial `building-skyscraper-c.glb`)
- `city_lowrise.glb` — ✅ filled (Kenney City Kit Commercial `building-e.glb`)
- `city_house.glb` — ✅ filled (Kenney City Kit Suburban `building-type-f.glb`)
- `city_industrial.glb` — ✅ filled (Kenney City Kit Industrial `building-e.glb`)
- `road_segment.glb` — ✅ filled (Kenney City Kit Roads `road-straight.glb`)
- `sidewalk.glb` — ✅ filled (Kenney City Kit Roads `tile-low.glb`)
- `streetlight.glb` — ✅ filled (Kenney City Kit Roads `light-square.glb`)
- `city_prop.glb` — ✅ filled (Kenney City Kit Suburban `planter.glb`)

**Resolved: `AssetLibrary.instance_variant(slot, rng)`** now picks
deterministically from a per-slot pool (`godot/data/asset_variants.json`
→ `assets/models/variants/<slot>/*.glb`), so the same city rebuilds
identically (same seed → same picks) while different buildings on the
same block use different meshes. `BuildingBuilder.build()`/`build_osm()`
thread the existing per-city `rng` through it; `BreakableProp` gets a
`variant_seed` set by its placer. `instance(slot)` / `instance_or()` are
unchanged and still work for every slot that has no variant pool.

Current pool sizes (all CC0, all from the packs below — well short of
what each pack actually ships, kept modest for repo size):

| Slot | Variants pulled in | Pack |
|---|---|---|
| `city_tower` | 5 of 5 skyscrapers | Kenney City Kit (Commercial) |
| `city_lowrise` | 6 of 14 buildings | Kenney City Kit (Commercial) |
| `city_house` | 8 of 21 houses | Kenney City Kit (Suburban) |
| `city_industrial` | 8 of 20 buildings | Kenney City Kit (Industrial) |
| `city_prop` | 3 (planter + 2 tree sizes) | Kenney City Kit (Suburban) |
| `vehicle_car_body` | 5 (sedan/sedan-sports/taxi/suv/police — same wheelbase class as the existing procedural wheel offsets) | Kenney Car Kit |
| `vehicle_spacecraft_body` | 5 (racer + 4 speeders) | Kenney Space Kit |
| `tree` | 6 pines / detailed trees | Kenney Nature Kit |
| `rock` | 5 rocks / tall stones | Kenney Nature Kit |
| `crystal` | 4 faceted gem clusters | Procedural bake |
| `creature` | 6 monsters/animals | Quaternius Monsters / Animals |
| `player_cat` / `npc_cat` | 3–4 fur variants | Procedural bake |
| `vehicle_aircraft_body` | 1 (Bob) | Quaternius Spaceships |
| `apartment_prop` | 6 furniture pieces | Kenney Furniture Kit |
| `ruin_pillar` | 5 castle pieces | Kenney Castle Kit |
| `metahuman_npc` / `peri_human_npc` | 5 skin/hair/cloth variants each | MPFB2/MakeHuman bake |
| `npc_human` | 5 skin/hair/cloth variants + 6 MakeHuman body builds (slim/average/athletic/heavy) | MPFB2/MakeHuman bake |

`road_segment`/`sidewalk` stay single-file on purpose — road tiles have
to interlock at fixed pivots/edges, and swapping them per-instance without
matching connector geometry would break the street grid, not just look
different. `vehicle_boat_body` also stays single-file (Watercraft Kit has
45 boats if a future pass wants to extend it the same way).

Further headroom in the same already-vetted CC0 packs, if a future pass
wants to go further:

| Pack | Total variants available | License |
|---|---|---|
| [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | 14 full buildings + 5 skyscrapers + 16 low-detail | CC0 |
| [Kenney City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) | 20 buildings + chimneys/tanks | CC0 |
| [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | 21 houses + fences/paths/trees | CC0 |
| [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | 70+ road/intersection/signage tiles | CC0 |
| [Kenney Car Kit](https://kenney.nl/assets/car-kit) | 13 vehicles (also delivery/truck/race — different wheelbase class, riskier to drop into the fixed wheel rig without visual QA) | CC0 |
| [Kenney Watercraft Kit](https://kenney.nl/assets/watercraft-kit) | 45 boats | CC0 |
| [Kenney Space Kit](https://kenney.nl/assets/space-kit) | 6 craft + full station/corridor kit | CC0 |

See `docs/VISUAL_DIRECTION_ESO.md`.

## Realism pass — stylised models retired from live slots

The Kenney humanoids and blocky props are CC0 and still in the repo under
`kenney_characters/`, but none of them occupy a live `AssetLibrary` slot any
more: their chibi/blocky proportions clash badly with the photoscanned
Poly Haven surfaces, and with the slots empty the resolver falls through to
`PeriHumanRig` — the parametric human — which is the realistic path and the
only one that can express a race's substance. Kept, not deleted: a
deliberately stylised reality layer would want exactly these.

| Was | Now | Why |
|---|---|---|
| `npc_human_a…l` (Kenney Mini Characters) | `kenney_characters/mini-a…l.glb` | chibi proportions |
| `npc_human.glb` (Kenney Blocky) | `kenney_characters/blocky-npc-legacy.glb` | blocky |
| `player_human.glb` (TPS demo) | `mech_tps.glb` | it is a mech, not a human |

Realistic fills added from [Poly Haven](https://polyhaven.com/models), CC0:

| Slot | Model |
|---|---|
| `city_door` | `rollershutter_door` |
| `landmark_longhorn_gate` | `large_iron_gate` |
| `city_prop_a…e` | `concrete_cat_statue`, `painted_wooden_bench`, `fire_hydrant`, `planter_box_01`, `wooden_picnic_table` |
| `ruin_pillar_a…c` | `gothic_statue`, `horse_statue_01`, `bronze_shark_statue` |

## Generated art — `godot/assets/entities/`

Generated with [Pollinations](https://pollinations.ai) (keyless, free) from
the prompts in `godot/data/entity_image_prompts/` and
`scripts/prompt_templates.py`, composed per `STYLE_BIBLE.md`. Reproduce or
extend with:

```bash
python3 scripts/prompt_templates.py --matrix --kind race --actions idle \
    --out build/race_batch.jsonl
python3 scripts/generate_assets.py --provider pollinations \
    --jobs build/race_batch.jsonl
```

Seeds are carried from the authored set where one exists, so a re-run
reproduces the same image and a single subject can be re-rolled alone.
Review the licence terms of whichever model Pollinations routes to before a
commercial release.

## MakeHuman-generated humans (2026-07-17 — the human gap is CLOSED)

| File | Source | License |
|---|---|---|
| `npc_human.glb`, `metahuman_player.glb`, `variants/npc_human/*.glb` (6 bodies) | Generated headlessly in this repo's pipeline: **MPFB v2.0.16** (MakeHuman Plugin For Blender, from extensions.blender.org, sha256-verified) running inside **bpy 5.0.1** (Blender as a Python module, PyPI). Parametric macro targets (gender/age/muscle/weight/proportions/height) baked per variant; helper cage stripped (13,380 verts each); real-world heights 1.64–1.84 m verified in the exported glTF accessors. | **CC0** — the MakeHuman project licenses characters exported with its tools as CC0; MPFB is GPL but its *output meshes* carry no license restriction. |

Details that matter to consumers:
- Materials are named `Skin` and `Outfit` — `NpcBody._apply_surface_tints`
  keys on those names: Skin gets the per-NPC natural skin-tone lerp,
  Outfit gets the archetype palette (brass barista / gunmetal authority /
  jewel-red lover / graphite archivist / violet reflection).
- Six builds ship in `variants/npc_human/` (f_slim/f_average/f_athletic/
  m_average/m_heavy/m_athletic); `NpcBody` picks one deterministically
  per NPC id via `AssetLibrary.instance_variant`. `npc_human.glb`
  (= m_average) remains the single-slot fallback; `metahuman_player.glb`
  (= m_athletic) upgrades the player from the tps-demo robot.
- Unrigged and unclothed-but-material-split (head/neck = Skin, below =
  fitted Outfit — reads as a bodysuit consistent with the identity-lens
  aesthetic). No skeletal animation exists in the game yet, so no rig is
  currently a non-loss; when animation lands, regenerate with MPFB's rig
  (`scripts/` pipeline can be re-run — see AGENTS.md).
- The tps-demo robot was `player_human.glb`; that file has since been
  deleted from the repo (misfiled name — it's a mech, not a human/robot —
  see the "Realism pass" table above). It survives only as `mech_tps.glb`,
  explicitly not restored under the `player_human` name.
