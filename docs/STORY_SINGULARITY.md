# Main Storyline — The Theory of Everything

> Status: **premise locked, beats open.** The core concept below is the
> established main storyline. What's still open is the specific plot —
> quests, characters, scenes, the exact order things are revealed. Everything
> here is built as data buckets so those specifics can be poured in later
> without touching code, and so DLC can extend it without touching existing
> entries.

## The premise

Long before humanity found the casino floor, the Liminal's first finders
discovered **the Theory of Everything** — one law underlying every reality
layer, subliminal to periliminal. It implied something enormous: fuse the
layers, and whoever held that fusion would hold a shared, total state.
**Godhood, in effect, achievable and shared.**

They never agreed on whether to take it. Instead of pursuing the fusion
together, the finders fought over **whose claim the layers were** — and while
they fought, the moment passed, unresolved. What's left, generations later,
are two answers to the same question, still being argued:

- **The Solution of Everything** (singularity, "the Convergence") — the
  layers were always meant to resolve into one total, shared state. Collapse
  isn't loss, it's arrival. Sought, not feared.
- **The Solution of Nothing** (anti-singularity, "the Divergence" — **the
  twist**) — fusing everything into one loses everything it fused. Nothing
  collapsed is nothing lost; the many must be allowed to stay many.

*(The wordplay is the point: it's the Theory of Everything, so its two
answers are named to match — Everything, or Nothing.)*

Between them: the **Seekers**, still chasing the Theory itself without yet
committing to which Solution it justifies, and **the Between**, who never had
a stake in the argument and just want to survive the layers.

## Two separate conflicts, on purpose

This story runs on **two axes that don't collapse into each other**:

1. **The Theory war** (`STANCE_OF` — singularity / anti_singularity / seeker /
   unaligned) — ancient, cosmic, and **between the races themselves**. It's
   about what reality-fusion means and whether it should happen.
2. **The faction war** — three factions, `SovereignCrown` /
   `WildlandsAscendant` / `VeiledCurrent` — recent and **human**. The
   factions *are* the ignorance and ego this story is actually about: rather
   than understand what the Liminal's finders had discovered, humanity moved
   to **claim** it — three competing claims on layers no one could really
   own. **`Factionless` is not a fourth faction** — it's the unpledged
   status every character starts in, with its own entity pool to play and
   collect from before committing. The commitment, once made, is permanent:
   a character who pledges to a faction cannot swap to another or fall back
   to Factionless (`PlayerProfile.set_faction()` enforces this in code).
   Factionless exists so new or undecided players still have somewhere to
   play, not as a fourth ideology sitting beside the other three.

A race's Theory stance and its historical faction tie are independent —
a race tied to SovereignCrown by claim can still privately hold the Solution
of Nothing. That gap is deliberate story texture: institutional loyalty and
personal belief don't have to agree, and that tension is free plot material.

## Origins: not every race is from the same world

Races are grouped into **origins** — distinct cradle-realities that only
became neighbors once the Liminal connected them (`ORIGIN_OF`,
`src/data/persona_buckets.gd`):

| Origin | Races | Character |
|---|---|---|
| The Ash-Forged | Igni, Sanguis, Ferros, Ferox | volcanic forge-world; martial, severe, quick to claim territory |
| The Void-Between | Nyx, Vex, Etherea, Keth | the gap between worlds; patient, watchful, half-arrived |
| The Verdant Cradle | Sylva, Myco, Aquis | living networked biosphere; communal, slow to anger |
| The Glass Reaches | Lumari, Kryos, Petra | ancient crystal/glacial world; measures time like distance |
| The Storm-Wrought | Volt, Geara, Chimera | perpetual-storm world; fused with the current instead of hiding from it |
| The Starfall Expanse | Astra, Azhul, Glyphe | close to the sky's edge; contemplative, drawn to big patterns |

Origins carry a **relation graph** (`ORIGIN_RELATIONS`) — ally / rival /
enemy / neutral, sparse and provisional. Two races from the same origin are
automatic allies; an unset pair defaults to neutral. This is the seam for
storylines where some races complement each other and others contradict —
independent of who agrees on the Theory. It's already live in dialogue:
`RacePersona.relation()` colours NPC disposition toward the player by a small
amount before either side says a word (`ui/npc_dialogue_ui.gd`).

## Multiple layers, multiple storylines

There are six reality layers (`docs/LORE_FOUNDATION.md`), and a player
spends most of any session in one or two of them — so this isn't one linear
main quest, it's **one myth underneath six local storylines**. The Theory of
Everything / Solution of Everything vs Nothing is the throughline that
eventually threads all six together; it is not a seventh plot competing with
them, and it doesn't require a player to have touched every layer to matter
in the one or two they actually play.

`LAYER_ARCS` (`src/data/persona_buckets.gd`) gives each layer a `hook` — one
line for where that layer's local story starts and how it touches the
Theory war — read through `PersonaBuckets.layer_arc_hook(layer_id)`:

| Layer | Local story is about... |
|---|---|
| Subliminal (The Base) | the daily loop being subtly wrong — the first thread most players pull |
| Liminal (The Thresholds) | fractured people caught mid-loop, some old enough to remember the discovery |
| Supraliminal (The Surface) | the faction war as policy — SovereignCrown's "perfected" layer made concrete |
| Hyperliminal (The Casino) | neutral ground where every faction's and origin's money ends up regardless of allegiance |
| Extraliminal (The Territory) | the claim fight made spatial — guild warfare over ground nobody actually owns |
| Periliminal (The Gauntlet) | personalized to the player's own Hope profile — where the Solution question stops being ideology and gets asked of *you* |

Same convention as everywhere else in this doc: the table above is
machinery and placement, not written plot. Filling in an actual storyline
for one layer never requires touching the other five, and a DLC layer or
sub-region just needs one more `LAYER_ARCS` entry.

## How the player enters it: race, faction, and the Unbound Writ

Most races were historically claimed by one of the three human factions
(`RACE_FACTION_OF`). By default, **picking your race recommends and limits
your faction to that tie** — Factionless is always open (it needs no
unbinding). To pledge to a *different* claim faction than your race's
history, you need an **Unbound Writ** (`item_database.gd`, id
`unbound_writ`) — earned through play, price 0, not sold. It's the fictional
answer to "any race, any faction": refusing to be reduced to the one label
your race was assigned is, in miniature, the Solution of Nothing. That's the
deliberate difference from a cash-shop alliance unlock — the mechanic *is*
the theme, not a bypass of it.

Implemented in `ui/venture_wizard.gd`'s faction step: your race's tie is
pre-selected and marked "recommended"; other claim factions show locked
(🔒) until the Writ is held; Factionless is never locked — because staying
Factionless isn't a step in this wizard at all, it's simply what happens if
you never spend the pledge. Whichever of the three factions you do confirm
at creation is that character's faction for good.

## Adding to this — DLC / future content

Everything is additive-only constants in `src/data/persona_buckets.gd`. A new
race, origin, or relation never requires editing an existing entry:

| To add... | Do this |
|---|---|
| A DLC race using an existing origin | `ORIGIN_OF["NewRace"] = "ash_forged"` (etc.) |
| A DLC race with a new homeworld | Add an entry to `ORIGINS`, then point `ORIGIN_OF` at it |
| A relation between two origins | One `ORIGIN_RELATIONS` entry, `"originA|originB": "enemy"` |
| A race's Theory stance | `STANCE_OF["NewRace"] = "seeker"` (etc.) |
| A race's faction tie | `RACE_FACTION_OF["NewRace"] = "VeiledCurrent"` (or omit for Factionless) |
| Bespoke dialogue for one race | `RACE_OVERRIDES["NewRace"]["story"] = [...]` (or barks/musings/taunts/…) |
| A whole new DLC storyline arc | A new stance or channel — one `CHANNELS`/`CHANNEL_AXIS` entry |
| A DLC reality layer or sub-region's storyline | One `LAYER_ARCS` entry |

Nothing downstream needs to know a new race, origin, or stance exists ahead
of time — every consumer (dialogue, Dex, creator, barks) reads through the
same handful of resolver functions.

## Open for the next pass (plot, not premise)

The concept above is settled. Still open, whenever you're ready to write it:

- The actual scene/order of the Liminal's discovery — who found it, when,
  and what the first fight over it looked like.
- Named leaders/figures for the Solution of Everything and Solution of
  Nothing movements (currently thematic, unnamed).
- Whether the player is pushed toward a stance by their race/faction, or
  earns the choice through the main quest.
- Specific origin rivalries beyond the provisional relation graph — any of
  them can be promoted from "flavor" to an actual plot beat.
- **Which one of the 20 canon races is the actual, literal Human race.**
  None of `RACES` in `src/data/canon_races.gd` is currently written as
  baseline-human — every entry in `human_race_archetypes.gd` carries a
  signature non-human trait (Ferros is metal-plated, Vex is translucent,
  Etherea is partly incorporeal, and so on). The faction war is framed
  throughout this doc as specifically **humanity's** ego and ignorance, not
  every race's — so which single race that indicts, and how the other 19
  relate to a conflict that was never really theirs, is a load-bearing fact
  this doc can't guess at. Blocks writing the origin/faction lore accurately
  for real until answered.
