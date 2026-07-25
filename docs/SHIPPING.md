# Shipping checklist — plug, play, market

**v0.1 goal = AAA Game of the Year** for Periliminal.Space — realistic ESO
visual bar (`docs/VISUAL_DIRECTION_ESO.md`). Gate table: [`docs/V01_GOTY.md`](V01_GOTY.md).

## 1. Open it

Open `godot/project.godot` in **Godot 4.3+** (**Forward+** on desktop). First
open imports assets; hit Play. Boot: splash → login (or Play Offline) → title.
Drop MetaHuman GLBs into `godot/assets/models/` per the visual direction doc.

## 2. What's fully playable today

- **Casino floor**: slots, poker, blackjack, coin pusher, fortune wheel,
  scratch cards, puzzle — with quests, achievements, battlepass, gacha,
  daily rewards, shop, tournaments, leaderboards.
- **Racing**: 5 tracks with level unlocks, entry fees, offline simulation,
  local racing cups (bracket tournaments).
- **The PVXC**: staked survival runs, 6x/12x zones, fights, revenge
  ledger, house-recovery ledger, extraction.
- **The overworld + reality layers**: streamed procedural terrain,
  day/night sky, third-person cat, discovery/influence painting,
  territory war + Conqueror crown; liminal wander → periliminal pulls
  with full-wipe rules; subliminal apartment with UGC blueprint slots
  and invites; arena hub with all six modes queueable.
- **Identity**: 20 races x 20 frames x 20 mods, ascension second frame,
  the lens (visuals + audio per build), perception RPS, crowns (all 60),
  champion→god ladder, six currencies, ~600 entities faction-gated.
- **Soundtrack**: five original tracks context-mapped, live per-build
  ambience.

## 3. AAA graphics — the asset drop (no code changes needed)

Full shopping list (addons, shaders, audio, web-vs-native rules):
`docs/ASSET_SHOPPING_LIST.md`. Install web-safe Godot addons with
`bash scripts/install_addons.sh` (see `docs/ADDONS.md`).

The engine-side pipeline is done: `AssetLibrary` checks
`assets/models/<slot>.glb` for every visual slot and upgrades the whole
game automatically, keeping the identity-lens shading. The environment
already runs ACES tonemapping, SSAO, SSIL, volumetric fog, and glow.

**Done** — these slots are filled in the repo today (see
`godot/assets/models/ATTRIBUTION.md` for exact source file per model, all
CC0 from kenney.nl, no attribution legally required):

| Slot | Filled with |
|---|---|
| `creature.glb` | Kenney Mini Dungeon `character-orc` |
| `tree.glb`, `rock.glb` | Kenney Nature Kit |
| `crystal.glb` | Kenney Space Kit `rock_crystalsLargeA` |
| `ruin_pillar.glb` | Kenney Graveyard Kit `column-large` |
| `extraction_gate.glb` | Kenney Space Kit `gate_complex` |
| `harvest_node.glb` | Kenney Mini Dungeon `chest` |
| `apartment_prop.glb` | Kenney Furniture Kit `loungeSofa` |
| `npc_human.glb` | Kenney Blocky Characters `character-a` |

**Still open** — no free model was found that clearly fit (the
procedural fallback carries these until you have one):

| Get this | From | Rename into `godot/assets/models/` as |
|---|---|---|
| A rigged cat/creature character | **Quaternius "Animated Animals"** (quaternius.com, itch.io claim required) or Kenney "Animal Pack" | `player_cat.glb`, `npc_cat.glb` |

### Mega-city assets (DFW Metroplex hubs)

The mega-city is **fully functional procedurally today** — every hub
(Dallas, Fort Worth, Denton, Arlington) builds a real city on entry:
road grid, per-block buildings, streetlights + neon wired to the
day/night rig, and a per-district sound bed. All of the slots below are
now **filled** with real art from Kenney's City Kit family (Commercial /
Suburban / Industrial / Roads) — zero code changes needed, `MegaCityBuilder`
already asked `AssetLibrary` for each slot first and now finds them:

| Slot | Filled with |
|---|---|
| `city_tower.glb`, `city_lowrise.glb` | Kenney City Kit (Commercial) |
| `city_house.glb` | Kenney City Kit (Suburban) |
| `city_industrial.glb` | Kenney City Kit (Industrial) |
| `road_segment.glb`, `sidewalk.glb`, `streetlight.glb`, `neon_sign.glb` | Kenney City Kit (Roads) |
| `city_prop.glb` | Kenney City Kit (Suburban) `planter` |

Swap any of these for a different pick from the same packs (each is one
cherry-picked file out of 25-70+ per pack under
`godot/assets/models/ATTRIBUTION.md`'s linked sources) whenever you want
more variety per hub.

**Interchangeable textures** — drop PBR maps into `godot/assets/textures/`
named `<slot>_albedo.png` (+ `_normal`, `_rough`, `_metallic`,
`_emissive`). The city asks for: `facade_glass`, `facade_concrete`,
`facade_brick`, `facade_metal`, `asphalt`, `sidewalk`, `neon`. Any that
exist are used; the per-race identity lens still tints on top, so the same
wall is a different material on every player's client.

**Interchangeable sounds** — drop looped audio into `godot/assets/audio/`
as `<slot>.ogg`: `city_traffic`, `city_crowd`, `neon_hum`, `machine_hum`.
Absent slots are synthesized live (traffic rumble, crowd murmur, neon
buzz, machine drone) so the city is never silent.

Also worth grabbing (bigger lifts, still free):
- **godotengine/tps-demo** (github) — reference-quality character
  controller + IK setup to graft onto `player_cat.glb`.
- **TokisanGames/Terrain3D** (GDExtension) — heightmap terrain with
  texture splatting to replace `ProceduralTerrain` meshes for hero areas.
- An HDRI sky pack (polyhaven.com, CC0) — drop into `assets/environments/`
  and point `DayNightSky` at it for photoreal skies.

## 4. Before the store page

- [ ] Set a real webhook URL for `DiscordTicketClient` (UGC review).
- [ ] Point `AccountManager` at your production Nakama host (offline
      fallbacks keep everything playable without it).
- [ ] Wire `EconomyManager.purchase_coins()` to the platform IAP SDK.
- [ ] Replace `assets/ui/icon.png` with final key art.
- [ ] Age/market review: PVXC + real-money coins = gambling-adjacent;
      check store policies per region.
- [ ] Marketing hooks that are true today: "No two players ever see or
      hear the same game" (engine-enforced), "480,000+ build identities,"
      "60 crowns, one Conqueror," "the casino has a basement."

## 5. Known simulation stand-ins (honest list)

These play, but resolve by simulation until bespoke gameplay lands:
arena modes (survival/zombies/CTF), PVXC creature fights (stat rolls, not
action combat), racing (results sim, no drivable vehicles), and other
players (creatures/AI stand in until Nakama presence is wired). None of
them block a playable build; all of them are the post-marketing roadmap.
