# Race Persona System

Each of the 20 canon races is a *kind of person*, not just a body and a
palette. One data file describes who they are; a handful of consumers turn that
description into how they look, move, sound, act, and are named. Everything is
keyed on the canon race name (`CanonRaces.RACES`), the same id bodies, genes,
and materials already use — so a race resolves the same way everywhere.

## The data — `src/data/race_persona.gd`

`RacePersona.PERSONAS[canon]` holds, per race:

| Field | Drives |
|---|---|
| `temperament`, `traits`, `quirk`, `element` | Dex + creator + wizard flavor text; `disposition_bias()` |
| `mannerisms` | stage-direction cues seasoned into dialogue |
| `movement{}` | `idle_energy`, `gait_cadence`, `posture_lean`, `swagger` → the rig |
| `voice{}` | `pitch`, `rasp`, `cadence` → the synthesized voice |
| `style[]`, `tech_affinity` | aesthetic tags (hood/plate/tech…) for wardrobe/gallery |

Pooled content (chatter, greetings, musings, taunts, farewells, flirts, story
lines, mood colours) lives in **`src/data/persona_buckets.gd`** — a shared,
tag-keyed template engine. A race maps to one tag per axis (`MOOD_OF` for
temperament channels, `STANCE_OF` for the story axis), so a dozen mood buckets
cover all twenty races and adding a race is just picking tags — no new prose.
`RACE_OVERRIDES[canon][channel]` gives a specific race bespoke lines that win
over the shared bucket. This is memory-light: pools are shared constants, not
per-instance copies. `RacePersona` delegates all pooled content to it
(`bark_line`, `greeting_line`, `line(channel,…)`, `mood_color`, `stance…`).

**Adding content:** new channel → add its pool + a `CHANNELS`/`CHANNEL_AXIS`
entry; unique lines for one race → `RACE_OVERRIDES`; retune a whole temperament
→ edit its bucket once and every race on that tag updates.

**Story axis:** the Theory of Everything storyline (Solution of Everything /
Solution of Nothing) is a first-class stance axis here — see
`docs/STORY_SINGULARITY.md` for the premise. **Origins** (`ORIGIN_OF`,
`ORIGINS`, `ORIGIN_RELATIONS`) are a separate axis: not every race is from
the same world, and races from allied/rival/enemy origins colour NPC
disposition toward the player before a word is spoken
(`RacePersona.relation()`, wired in `ui/npc_dialogue_ui.gd`). **Faction ties**
(`RACE_FACTION_OF`) are a third, independent axis — see the story doc for why
factions and Theory stance are deliberately not the same thing, and how the
Unbound Writ (`item_database.gd`) lets a player pledge outside their race's
historical claim.

Key helpers: `movement()/movement_for_id()`, `voice()`, `describe()/short()`,
`mannerism_cue()`, `bark_line()`, `greeting_line()`, `disposition_bias()`,
`mood()/mood_color()`, `canon_for_id()/canon_for_npc()`.

## Movement — `src/perihuman/peri_human_rig.gd`

`PeriHumanRig.apply_persona(movement)` sets four modifiers the procedural
idle + gait already read:

- **idle_energy** — fidget/sway/blink/saccade rate when standing (Volt twitches, Kryos is nearly still)
- **gait_cadence** — step tempo (Volt quick, Petra lumbering)
- **posture_lean** — held even at a standstill (Ferros leans back proud, Keth hunches furtive)
- **swagger** — hip roll + shoulder sway + lateral sway while walking

Stamped on player and NPC bodies in `character/metahuman_character.gd`
(`_native_player` / `_native_npc`).

## Voice — `src/audio/persona_voice.gd`

`PersonaVoice` is an asset-free "chittering" blip voice (Animal-Crossing
style). The waveform is synthesized in code from `voice{}` — pitch and rasp
shape the timbre, cadence sets tick rate and wobble. No audio files.

Consumers:
- **NPC dialogue** (`ui/npc_dialogue_ui.gd`) — NPC line blips as it types; the
  player's social moves blip in the player's own race voice.
- **Ambient/emote barks** (`world/persona_barker.gd`) — voiced when in earshot.
- **Creator studio** — a "🔊 Hear Voice" button.
- **Venture wizard** — a greeting blip as you browse races, and the new
  fighter's first words on FIGHT.

## Mannerisms & barks — `world/persona_barker.gd`

`PersonaBarker` floats a short in-character line above a character and voices
it when near the player. `auto = true` self-paces (world NPCs, tempo scaled by
idle_energy); `auto = false` + `say()` is the player's emote channel.

- **World NPCs** (`world/npc_spawner.gd`) get a barker + a mood-tinted,
  race-flavored name.
- **Remote players** (`multiplayer/remote_player.gd`) bark too.
- **The player** (`world/overworld/third_person_controller.gd`) — `V` greets
  (voice + smile), `B` taunts; runs off the player's own persona.
- **Ambient wander** (`world/ambient_npc.gd`) — jittery races pace fast and
  rarely stand still; ponderous ones amble and linger.
- **Dialogue** (`ui/npc_dialogue_ui.gd`) — lines are seasoned with a
  `mannerism_cue()` (deterministic per NPC+node, ~2 of every 3 lines), and the
  opening falls back to a race greeting when there's no rumor to lead with.

## Naming — `src/data/race_name_gen.gd`

`RaceNameGen` builds names from six phonetic families (umbral / ember / iron /
astral / verdant / arc) so a name *sounds* like its race. Used by
`world/npc_generator.gd` for the abstract layers (the mundane city keeps human
names) and by the spawner whenever a name is missing. Deterministic per id.

## Disposition & the Dex

- `disposition_bias(canon)` nudges first impressions: warm/gentle races open up
  faster, haughty/cold ones make you earn it (`ui/npc_dialogue_ui.gd`).
- The **Master Omni Dex** (`ui/omni_dex_ui.gd`) shows a Persona block per race —
  temperament, mannerisms, quirk, and voice summary.

## Adding or tuning a race

1. Edit its entry in `RacePersona.PERSONAS` (or its `MOOD_OF` bucket).
2. Movement/voice/mannerisms/disposition/name all follow automatically — no
   consumer needs touching.
3. In-editor, the creator studio's Persona panel + "Hear Voice" + gait slider
   are the fastest way to eyeball and ear-check the result.
