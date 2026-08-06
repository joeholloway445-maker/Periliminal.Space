# Main Storyline Scaffold — The Theory of Everything

> Status: **SCAFFOLD, not canon.** This file wires the *machinery* for the
> main storyline so races, dialogue, and the Dex can reference it — but the
> actual plot is yours to write. Every assignment and line here is a provisional
> default chosen to be safe and easily overridden. Nothing downstream hard-codes
> a plot point; changing this file cannot break code.

## The premise (as given)

The through-line is **The Theory of Everything** — the idea that a single law
underlies every reality layer (subliminal → periliminal). Two movements form
around what that means:

- **The Singularity** — reality is resolving toward one point; all layers,
  all beings, collapse into a single unified state. Its believers seek that
  convergence.
- **The Anti-Singularity (the twist)** — the counter-movement: that collapse
  into one is not unity but an *ending*. The many must remain many. It exists
  to resist the Convergence.

Between them sit the **Seekers** (who chase the Theory for its own sake, not yet
committed to what to *do* with it) and **the Between** (who take no side and
just want to survive the layers).

## Where it lives in code

Everything routes through one axis in `src/data/persona_buckets.gd`:

| Piece | What it is |
|---|---|
| `STANCE_OF[canon]` | each race's stance id — **provisional**, derived from element |
| `STANCE_LABEL` / `STANCE_BLURB` | display name + one-paragraph description per stance |
| `STORY[stance]` | the line pool a race speaks about the conflict (thematic, fillable) |
| `RACE_OVERRIDES[canon]["story"]` | bespoke story lines for a specific race |

Read it through `RacePersona.stance()` / `stance_label()` / `stance_blurb()`,
or pull a line with `RacePersona.line("story", canon, seed)`. The Dex persona
block (`ui/omni_dex_ui.gd`) and the creator persona panel already surface the
stance, and ambient NPC barks mix in a story line now and then.

## Provisional stance assignments

Chosen from each race's existing element/lore — **change any of them freely.**

- **The Convergence (singularity):** Geara, Volt, Ferros, Myco
- **The Divergence (anti_singularity):** Sylva, Aquis, Ferox, Chimera
- **The Seekers:** Azhul, Glyphe, Astra, Lumari, Sanguis
- **The Between (unaligned):** Keth, Nyx, Vex, Etherea, Kryos, Igni, Petra

## How to make it *your* story

1. **Set the stances** — edit `STANCE_OF`. That single map decides who's on
   which side; movement, voice, and mannerisms already come from the persona.
2. **Rewrite the tone** — edit `STANCE_LABEL` / `STANCE_BLURB` to match the
   names and framing you actually want (e.g. if the Anti-Singularity has a
   proper in-world name).
3. **Pour in the plot lines** — replace the placeholder `STORY[stance]` pools
   with real dialogue, or give key races bespoke lines via `RACE_OVERRIDES`.
4. **Add a channel if you need one** — e.g. a `"prophecy"` or `"faction_pitch"`
   channel is just another entry in `CHANNELS` + `CHANNEL_AXIS`; no new code.

Because it's a bucket engine, the *structure* is fixed and safe while the
*content* is entirely yours — so building this out now can't paint the
storyline into a corner. When you're ready, hand me the real framing (names,
who sides with whom, key beats) and I'll fill the buckets and wire it into
quests/factions.

## Open questions for you (so the buckets get filled right)

- Does the Anti-Singularity have an in-world name, or is "the Divergence" it?
- Do the four factions (SovereignCrown / WildlandsAscendant / VeiledCurrent /
  Factionless) map onto these stances, or is the Theory conflict orthogonal to
  faction?
- Is the player pushed toward a stance, or do they choose — and can they change?
