# Proposed roster mapping — Omni Dex ↔ canon races

A **proposal, not a decision.** `docs/OMNIDEX.md` explains the split; this
converts it from "work out the reconciliation" into "approve or adjust this
table." Nothing in code reads it — it stays prose until you sign off, because
picking which body belongs to which race is a creative call.

Read it as: *if the Omni Dex race were rendered by the PeriHuman genome
system today, whose body would it borrow?* The right-hand column is what
already carries a skin tint, marking colour, PBR signature and body genes.

## Confident — the concept is the same thing twice

These pair on their defining mechanic, not just a similar name.

| Omni Dex | Passive / nature | Canon race | Why |
|---|---|---|---|
| `lumenari` | Radiant Pulse, gutters in darkness | **Lumari** | Crystal-blooded bioluminescence; already `emissive 0.9, metallic 0.3` |
| `veilstriders` | Phase Skip — ignore an incoming hit | **Vex** | Phase-capable, semi-material; already `translucent, opacity 0.88` |
| `coldmarrow` | Freeze Aura, slows nearby enemies | **Kryos** | Glacier-world cryomancer |
| `pulseborn` | Shock Dash, AoE detonation | **Volt** | Bioelectric, conductive strands |
| `thorned` | Regrowth Armor — accelerated wound regen | **Sylva** | Forest biomancer, accelerates growth |
| `mirekin` | Hive Awareness — senses allies through the network | **Myco** | Fungal symbiote, continuous spore network |
| `dreamflesh` | Minor Morph Shift — adaptive reshaping | **Chimera** | Unstable phenotype; already the `chaotic` archetype |
| `starfall` | Impact Entry — fall damage becomes AoE | **Astra** | Stellar descendants, fell from orbit |
| `deepborne` | Pressure Pulse — knockback when struck | **Aquis** | Hydromancer, pressure as a weapon |

## Reasonable — defensible, but you may disagree

| Omni Dex | Passive / nature | Canon race | Why, and the doubt |
|---|---|---|---|
| `echoes` | System Hack — destabilises nearby systems | **Geara** | Cyber-integrated engineers. Could equally be `Glyphe` if "echo" is meant as inscription, not machine |
| `chronarchs` | Micro-Rewind — corrects movement error | **Azhul** | Psionic probability-readers. Time vs probability is close but not identical |
| `crownless` | Authority Override | **Ferox** | Apex dominance. But "crownless" reads as *denied* authority, which may be the opposite of Ferox's |
| `gutterkin` | Hazard Conversion — hazards restore Focus | **Keth** | Both undercity-evolved. Keth is stealth-led, Gutterkin is toxicity-led — shared habitat, different adaptation |
| `glassborn` | Mirror Shield — reflects incoming damage | **Petra** | Both mineral-bodied. `Ferros` (metallic dermal plating) is an equally good fit for a reflective shell |
| `rotweavers` | Decay Conversion — extra loot from kills | **Sanguis** | Hemomancy is the nearest body-horror axis, but decay ≠ blood; this one is weak |

## Unresolved — five Omni Dex races, five canon races, no clean pairing

| Omni Dex left over | Canon left over |
|---|---|
| `ashen_choir` — Sorrow Amplification, ally damage boost | **Igni** — pyromancer, volcanic calderas |
| `nullborn` — Outcome Shift, minor RNG skew | **Nyx** — void-touched, manipulates light |
| `hollowed` — Extra Item Slot | **Etherea** — partially incorporeal |
| `riftspawn` — Minor Gravity Pull | **Ferros** — iron-blooded, dermal plating |
| `sunspun` — Radiant Burst at max Focus | **Glyphe** — rune-scribe, living inscription |

Some of these nearly work (`sunspun`→Igni on radiance; `nullborn`→Nyx on
void; `hollowed`→Etherea on incorporeality) but each collides with a pairing
above, so they are left open rather than forced. `riftspawn`↔`Ferros` in
particular has no shared concept at all — it is only what remains.

## What this implies

Nine confident pairs out of twenty means the two rosters are **roughly two
thirds the same design**, re-authored. That supports option 1 in
`OMNIDEX.md` (Omni Dex wins, port the bodies across) more than option 3
(treat them as separate layers) — you would be porting ~15 workable bodies
and authoring ~5 new ones, not maintaining forty races forever.

Practical order if you take option 1:

1. Correct this table — the "reasonable" and "unresolved" rows are the only
   ones needing real thought.
2. Re-key `human_race_archetypes.gd` to Omni Dex ids, carrying each canon
   race's `genes` / `skin_tint` / `marking_color` / `skin_material` onto its
   mapped partner.
3. Author the ~5 unmapped races fresh — their Omni Dex `description` fields
   are already written as art prompts and give the visual brief directly.
4. `CanonRaces.canon_for_id()` becomes the one place the translation lives,
   so nothing else in the engine needs to change.
