# The Omni Dex roster — and the roster split it exposes

`src/data/omni_dex.gd` is the Master Omni Dex workbook (Races / Frames /
Morph_Rigs sheets) transcribed into engine-readable data: all 20 races, 20
frames, and 20 morph rigs, with their stat bonuses, passives, drawbacks,
descriptions and lore intact.

## The thing to decide before wiring it in

**There are two different 20-race rosters in this project, and they do not
match.** Nothing is broken today — they simply do not know about each other.

| | Omni Dex (`omni_dex.gd`) | In-engine (`race_lore.gd`, `human_race_archetypes.gd`) |
|---|---|---|
| Race ids | `lumenari`, `gutterkin`, `deepborne`, `veilstriders`, … | `Keth`, `Lumari`, `Vex`, `Ferox`, … |
| Stats | Power / Agility / Resonance / Frequency | pow / spd / res / sty / lck |
| Carries | faction, passive, drawback, lore, art prompt | body genes, skin tint, marking colour, PBR signature |
| Drives | nothing yet | `PeriHumanRig` — every rendered body |

The names rhyme in places (`lumenari` / `Lumari`) but the rosters are not a
renaming of each other: the Omni Dex set is faction-organised and
ability-led, the in-engine set is homeworld-organised and body-led.

**What already lines up:** Omni Dex faction ids
(`sovereign_crown`, `wildlands_ascendants`, `veiled_current`) are exactly the
three factions `perception_system.gd` runs its RPS wheel on, and each roster
is a clean 20. So these are two descriptions of the same intent, authored at
different times — not a conflict of design.

## Three ways to reconcile

1. **Omni Dex wins.** Re-key `human_race_archetypes.gd` to the 20 Omni Dex
   ids and port each one's body genes / skin tint / material signature onto
   its nearest counterpart. Biggest edit, but leaves one roster and the
   design workbook as the source of truth.
2. **Map between them.** Add a 20-to-20 id mapping so the Omni Dex supplies
   ability/lore data and the existing archetypes keep supplying bodies. No
   creative rewrite, but two rosters stay alive forever.
3. **They are different things.** Keep the Omni Dex as the *character-sheet*
   layer (what you can do) and the canon races as the *substance* layer (what
   you are made of). Legitimate — but then the 8,000 figure is really
   20 x 20 x 20 twice over, and that should be said out loud in the docs.

Option 1 is the one that leaves the codebase simplest. It is also the only
one that needs a human decision about which body belongs to which race, so
it is not something to do automatically.

## Using it now

`OmniDex` is safe to read from immediately — it is pure data with no
dependencies and nothing else reads it yet:

```gdscript
var r := OmniDex.race("veilstriders")
r.faction      # "sovereign_crown"
r.stat_bonus   # {"agility": 2, "frequency": 1}
r.passive      # "Phase Skip: 5% chance to ignore incoming hit"
r.drawback     # ...

OmniDex.races_in_faction("veiled_current")   # the RPS wheel's members
OmniDex.frame("skirmisher").role             # "Duelist"
OmniDex.morph_rig("heavy_siege").boon        # "+Stability"
```

Each entry also carries the workbook's `description` — these are written as
art prompts ("Futuristic humanoid glowing with solar energy, sleek armor,
ambient light aura"), which makes them directly usable as the brief for
per-race character art or for the `metahuman_<race_id>.glb` slots that
already outrank everything in `MetahumanCharacter`'s resolver.

## Regenerating

The transcription was mechanical (parse the exported HTML sheets, emit
GDScript). If the workbook changes, re-export it and re-run that pass rather
than hand-editing `omni_dex.gd` — hand edits will be lost on the next export.
