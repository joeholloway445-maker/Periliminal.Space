# Model attribution

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

**Target:** replace humanoids with **your MetaHuman GLB exports** at:
- `metahuman_player.glb` (local player identity)
- `metahuman_npc.glb` (generic NPC)
- `metahuman_<race_id>.glb` optional per-race variants

See `docs/VISUAL_DIRECTION_ESO.md`.
