# Periliminal.Space: The Universe

> **Status: early concept doc, partially superseded.** The six reality
> layers below match current canon (see `LAYER_ARCS` in
> `src/data/persona_buckets.gd` and `docs/STORY_SINGULARITY.md`) and are
> still good. Two things below are NOT current canon and should be read as
> historical brainstorming, not source of truth:
>
> 1. **"Four Ideologies" (factions), including Factionless as a peer.**
>    There are three real factions — SovereignCrown, WildlandsAscendant,
>    VeiledCurrent. Factionless is the unjoined starting status every
>    character begins in, not a fourth ideology with its own leader and
>    questline; see `docs/STORY_SINGULARITY.md` and
>    `src/character/player_profile.gd` (`set_faction()` is permanent once
>    left). The rich Factionless material below (the Oracle, the Wanderer,
>    the Thief) is still usable — just as flavor for what an unpledged
>    character encounters, not as a fourth faction's leadership.
> 2. **A third, unreconciled "Light/Heavy, perceptual-lens" race roster**
>    (Luminant, Kinetic, Chronal, …) used to live in this doc, distinct from
>    both the in-engine canon races (`Keth`, `Lumari`, `Vex`, … in
>    `src/data/canon_races.gd`) and the Omni Dex roster (`lumenari`,
>    `gutterkin`, … in `src/data/omni_dex.gd` — see `docs/OMNIDEX.md` for
>    that pair's own reconciliation status). No code ever read it, so it's
>    been removed rather than carried forward as dead weight — see the
>    "Race" section below.

## The Canonical Universe: Superposition

Periliminal.Space is set in **Dallas-Fort Worth, 2087** — but not THE Dallas-Fort Worth. At some point in history (intentionally vague; hidden in quest rewards for Sash/Oracle factions), reality **fractured** into six simultaneous, overlapping layers of existence. No apocalypse, no visible cataclysm — just a *spreading inconsistency* that no one can quite explain. By 2087, the layering is complete and permanent.

### The Six Realities (Reality Layers)

Each layer is internally coherent but distinct. A street exists in all six, but which Dallas is it? The answer depends on which layer *you* currently inhabit:

1. **Subliminal** (The Base / Sleepwalking): Contemporary 2087 DFW — office parks, strip malls, apartments, highways. This is "normal," but something is *off*. People move through routines without full agency. You wake at your apartment and must return nightly. Liminal doors are hidden, requiring observation and luck. Entities are weakest here; most are "sleeping" echoes. **Theme**: Mundane horror of repetition.

2. **Liminal** (Between-Spaces / Thresholds): The hallways, stairwells, parking garages, and non-places that exist *between* buildings. In Liminal, a single hallway can stretch for kilometers, or loop infinitely. NPCs here are fractured versions of Subliminal people, caught in loops or degraded into archetypal roles. Time doesn't pass coherently. **Theme**: Liminal Space creepypasta realized as gameplay. Procedurally generated non-Euclidean zones.

3. **Supraliminal** (The Surface / Clarity): A "perfected" version of DFW — same geography, but buildings are newer, streets cleaner, NPCs are hyper-competent and *unsettlingly aware*. Hidden doors lead here from Subliminal. Authority figures (police, corporate executives, HOA board members) are more present and more threatening. Entities are staged and released deliberately by unseen forces. **Theme**: Authoritarian perfection. Corporate synergy. Everything looks good on paper.

4. **Hyperliminal** (The Casino): Catsino.Casino exists here — a sprawling, gravity-defying fortress of gambling, spectacle, and excess. Time moves differently (subjective experience). Luck is a *tangible resource* that can be gambled away. NPCs are colorful, amoral hustlers. The place never closes. Winning feels addictive; losing feels survivable. Entities serve as house muscle or entertainment. **Theme**: GTA Vice City meets Las Vegas fever dream. Hedonism and entropy.

5. **Extraliminal** (The Territory): The real-world geography of DFW overlaid with *invisible guild territory markers*. Think Pokémon GO's map, but instead of gyms, there are seeded hideouts. Here, guild politics are visible as colored zone claims, entity defenders as wandering warband soldiers. Weather and lighting shift based on faction control. This is where large-scale conflict *actually* happens. **Theme**: Faction warfare, territory control, emergent player-driven politics.

6. **Periliminal** (The Gauntlet): A 7–15 minute randomized psychological maze pulled from *your specific player profile*. No exit except death or the blessing door (which only opens after surviving a minimum depth). Entities are tier-1 apex predators. The gauntlet's layout, encounters, and traps are tuned to exploit your Hope profile's weaknesses. **Theme**: Psychological horror tailored to *you*. Personalized hell.

---

## The Factions: Three Ideologies, One Fractured Reality
(plus Factionless — the unaligned status every character starts in, not a
fourth ideology; see the status note at the top of this doc)

Each faction emerged to *explain and control* the layering. They don't just disagree about policy—they disagree about whether the layers are a *feature* or a *bug*, and who should govern them.

### **Sovereign Crown** (Order / Rationality / Control)

**Belief**: The layering is a natural phenomenon that can be *systematized*. Reality needs hierarchy and rules. They've built a court system, a bureaucracy, and a technological infrastructure to manage the six layers like a multi-dimensional kingdom.

**Symbol**: A crown over a blueprint. **Color**: Gold and silver. **Homeworld**: Supraliminal's gleaming financial district.

**Motivation (Marvel angle)**: Like S.H.I.E.L.D. — a well-intentioned order that believes the world *needs* control. But their control is *always* subtly authoritarian. They tag entities with inhibitor collars. They audit which doors you're allowed to enter. They've almost convinced themselves that surveillance equals safety.

**Motivation (Harry Potter angle)**: Like the Ministry of Magic — they've created bureaucratic systems to enforce magical law, but the Ministry is fundamentally concerned with *image* over substance. Entities that might expose the secret are suppressed. Mages (high-level players) are registered and monitored. Muggle-borns (factionless or Wildlands players) are suspect.

**Key Leader**: Magistra Lena Kross — a charismatic technocrat who genuinely believes central planning can *perfect* reality. She's charming, competent, and *dangerous* because she's not cartoonishly evil.

**Conflict Hooks**:
- The Sovereign Crown's "integration protocols" are suppressing genuine accounts of Periliminal. They've rebranded it as a shared delusion, a mass psychogenic illness. Official Crown press releases call it the "Consensus Instability Syndrome."
- Crown researchers are *harvesting* Periliminal echoes—fragments of players' own psychological material—to build predictive models. This is both research and surveillance.
- Faction questline: Uncover whether Kross *actually* knows what Periliminal is, or if she's as confused as everyone else but too proud to admit it.

---

### **Veiled Current** (Mystery / Acceptance / Surrender)

**Belief**: The layering is *intentional* — a message from something beyond human understanding. Stop trying to control it. Accept it. Learn to *navigate* it through intuition and ritual rather than reason. The layers speak; those who listen can benefit.

**Symbol**: A hand releasing water; waves flowing in opposite directions. **Color**: Indigo, silver, black. **Homeworld**: Liminal's deepest, most twisted non-Euclidean zones.

**Motivation (Marvel angle)**: Like the Mystics in Doctor Strange — they understand that reality is more pliable than science admits. But they're also *fatalistic*. The universe does what it wants; wisdom is accepting your role in it, not fighting it.

**Motivation (Harry Potter angle)**: Like the Luna Lovegood faction — they see patterns others miss. They're not crazy; they're just operating on a different wavelength. But their acceptance borders on passivity. "If you can't beat the basilisk, befriend it" can get you killed.

**Motivation (GTA angle)**: Like the street philosophers and spiritual hustlers in GTA's underbelly — they offer a *different narrative* than corporate rationalism. Some are genuine mystics; others are con artists. The line is blurry.

**Key Leader**: The Veiled Heart (title, not name) — a deliberately obscured figure who communicates via prophecy, tarot, and dreams. No one has seen their face. Some claim they're not even a single person; the Veiled Heart is a *collective consciousness* distributed through Liminal's deepest zones.

**Conflict Hooks**:
- Veiled Current members accidentally *summon* things while conducting rituals. The ritual is supposed to just harmonize with the layers; instead, it opens doors to things that should stay closed.
- Their fatalism makes them appear complicit in Periliminal's horrors. A player might discover that Veiled Current *knows* the true nature of the gauntlet and refuses to warn others.
- Faction questline: Is the Veiled Heart actually receiving messages, or manufacturing them to maintain control and mystique?

---

### **Wildlands Ascendant** (Freedom / Chaos / Adaptation)

**Belief**: The layering is an *opportunity*. Ditch the old world's rules. Out here, in the liminal spaces and wild frontiers, you can build something new. No governments, no corporations—just natural selection and those strong enough to survive. This is a *second chance*.

**Symbol**: A jagged, sprouting tree breaking through concrete. **Color**: Green, rust, earth tones. **Homeworld**: Liminal's forests, Subliminal's untamed green spaces, Extraliminal's wilderness zones.

**Motivation (Marvel angle)**: Like the Hellfire Club or worse — they believe civilization is a cage, and the layers give you permission to escape it. Some are anarchists with a genuine vision; others are just raiders with philosophy.

**Motivation (Harry Potter angle)**: Like the Death Eaters — they believe in a *natural hierarchy* based on power and bloodline (or in this case, rarity and faction). Those with the strongest entities, the clearest frames, should rule. Survival of the fittest.

**Motivation (GTA angle)**: Like the gang life — respect is currency, territory is wealth, and the strongest crew writes the laws. There's genuine community here, but it's predicated on domination.

**Key Leader**: The Spore Prophet — a figure so altered by exposure to Liminal and Periliminal that their original body is barely recognizable. They claim that humanity *will* adapt to the layers, but the process is going to hurt. They welcome that hurt because it means growth.

**Conflict Hooks**:
- Wildlands' "natural selection" philosophy leads to deliberate culling. They push factionless players into Periliminal not to help them, but to see if they die. If they survive, they're Wildlands material. If they die, they were "too weak anyway."
- Wildlands entities are more aggressive, less controlled, and more likely to go rogue. A player might befriend a Wildlands entity only to have it lured away by a wild pack.
- Faction questline: The Spore Prophet is becoming something non-human. Discover whether that's liberation or corruption.

---

### **Factionless** (Uncertainty / Survival / Authenticity)

**Belief**: None of the above have it figured out. Maybe nobody does. Factionless players are independent agents, scavengers, and experimenters. Some are philosophers; some are just trying to stay alive.

**Symbol**: None — or all of them at once. An eclipse. A blank slate. **Color**: Shifts depending on context. **Homeworld**: The forgotten spaces — Subliminal's abandoned houses, Liminal's dead ends, Supraliminal's maintenance tunnels.

**Motivation (Marvel angle)**: Like independent heroes — they don't have backing, but they have *authenticity*. They can make moral choices without committee approval.

**Motivation (Harry Potter angle)**: Like Dumbledore (at his best) — wisdom without dogmatism. Accept mystery without surrendering agency.

**Motivation (GTA angle)**: Like the player character in GTA — you write your own story. You're not part of anyone's organization, so you're free to betray anyone, ally with anyone, and reinvent yourself constantly.

**Key Leader(s)**: There is no central leader. Factionless players look to each other, to discovered texts, to their own Hope profiles for guidance. But there are *recognized voices*: the Oracle (who speaks in riddles from the deepest Periliminal), the Wanderer (who maps the non-Euclidean zones), the Thief (who steals faction secrets and distributes them freely).

**Conflict Hooks**:
- Factionless players are *targets* for all three factions—useful but uncontrolled.
- The Oracle's riddles sometimes contradict each other, leading factionless players into traps.
- Faction questline: Survive long enough to discover whether Factionless is a legitimate third path or just slow death.

---

## Race

Superseded — see `docs/STORY_SINGULARITY.md` and `src/data/canon_races.gd`
for the real 20 canon races (Keth, Lumari, Vex, …). The "perceptual lens"
roster (Luminant, Kinetic, Chronal, …) that used to live here was a third,
unreconciled race system nothing in code ever read; removed rather than
carried forward as dead weight.

## Frames (20 Options): Your Senses & Mood

The **frame** you choose is already defined in `FrameSensorium` — each frame is a complete sensory and emotional perspective on reality. I'm expanding the *lore* behind each one:

### Light Frames (Clarity, Openness, Presence)

1. **Veil**: The world is holding its breath. You perceive wonder and mystery. In Liminal, you're calm; in Periliminal, you're centered. Entities seem *sympathetic*. Associated with Mysticism, Femininity, Intuitive Magic.
   - *Lore*: You wear the veil between worlds naturally. You're a natural for Veiled Current recruitment. NPCs open up to you without trying. Entities see you as a peer, not a threat. **Quest Hook**: A ghost NPC in Liminal keeps trying to tell you something through the veil.

2. **Zephyr**: Wind and clarity. You perceive freedom and possibility. Fast, light, and aware of movement. Associated with Youth, Escape, Adventure.
   - *Lore*: You are momentum embodied. You can't stay still; you're always moving. This makes you excellent at exploration but terrible at commitment. NPCs see you as an outsider. **Quest Hook**: A windstorm in Liminal is trying to *carry* you somewhere. Follow it?

3. **Viper**: Venom and sharpness. You perceive danger and opportunity. Enemies seem obvious; allies are harder to spot. Associated with Predation, Cunning, Self-Interest.
   - *Lore*: You are a weapon. Entities respect your sharpness; NPCs are wary of you. Wildlands Ascendant offers you better contracts. **Quest Hook**: A venom-dripping entity will only deal with you—others, it ignores.

4. **Phantom**: Half-there. You perceive absence and delay. Sound arrives late; information lags. You're isolated even in crowds. Associated with Dissociation, Loneliness, Observation.
   - *Lore*: You are not fully here. This makes you hard to detect but hard to connect with. You can slip past encounters, but relationships are difficult. **Quest Hook**: A phantom NPC keeps visiting you, but only you can see it. Why?

5. **Crimson**: War-red. You perceive conflict and passion. Everything is a battle or a lover. Calm moments feel *wrong* to you. Associated with War, Passion, Blood-debt.
   - *Lore*: You are a born combatant. Entities bond easily to you (you understand them). But civilians fear you. Sovereign Crown offers you military roles. **Quest Hook**: A voice in Subliminal keeps whispering battlefield strategies to you.

6. **Glacial**: Ice-white clarity. You perceive cold truth. Illusions shatter in your presence. Emotionally distant but intellectually sharp. Associated with Logic, Clarity, Detachment.
   - *Lore*: You are ice. You see through deception; NPCs can't lie to you effectively. But they also avoid you. Sovereign Crown sees you as an investigator. **Quest Hook**: A frozen NPC in Liminal is starting to thaw. What will they say?

7. **Bolt**: Overexposed white-hot. You perceive intensity and urgency. Everything is *now*. You're hyper-aware but burn out easily. Associated with Action, Urgency, Exhaustion.
   - *Lore*: You are always running at max. Combat bonuses; social penalties. You live fast. NPCs see you as unreliable. **Quest Hook**: An entity made of pure lightning challenges you to a race through Liminal.

8. **Soul**: Warm rose. You perceive companionship and care. You bond deeply with entities and NPCs. Conflict hurts more. Associated with Love, Connection, Vulnerability.
   - *Lore*: You are a natural healer and nurturer. Your entities are fiercely loyal. But you suffer if you lose them. **Quest Hook**: An NPC you bonded with has vanished into Periliminal. Will you follow?

9. **Cinder**: Ember-glow from below. You perceive slow burn and acceptance. You don't rush; you'll wait as long as it takes. Warm, inviting, patient. Associated with Endurance, Warmth, Acceptance.
   - *Lore*: You are a long fire. You're hard to anger but impossible to put out. NPCs trust you; entities see you as a guardian. **Quest Hook**: A dying flame in Liminal asks you to keep it alive. How?

10. **Flux**: Light that re-decides. You perceive contradiction and possibility. Nothing is fixed; everything could be otherwise. Harmonies never resolve. Associated with Change, Paradox, Fluidity.
    - *Lore*: You are a living contradiction. You can hold opposing ideas at once. NPCs find you unsettling but necessary. You're the faction mediator. **Quest Hook**: A reality-warping entity offers you a deal to change something fundamental about yourself.

### Heavy Frames (Power, Grounding, Presence)

11. **Bastion**: Fortress amber. You perceive safety and structure. Strong and protective. Slow but unshakeable. Associated with Defense, Duty, Stronghold.
    - *Lore*: You are a fortress. Entities bond to you for protection; NPCs gather around you. You're a natural leader. Sovereign Crown loves you. **Quest Hook**: Your fortress is being slowly eroded by something in Periliminal.

12. **Tremor**: Dust-brown, sub-bass. You perceive impact and ground-truth. Heavy-hitting, affecting everything around you. Associated with Power, Consequence, Disruption.
    - *Lore*: You are an earthquake. Everything trembles around you. NPCs respect you; entities fear you. Wildlands sees you as leadership material. **Quest Hook**: A tremor in Liminal is building. You feel it before anyone else. Will you warn them?

13. **Behemoth**: Granite grey, endless drone. You perceive massive, slow forces. You move like a mountain. Incredibly slow, incredibly strong. Associated with Inevitability, Scale, Patience.
    - *Lore*: You are inevitability. Things move around you; you move through them. NPCs get out of your way; entities submit. Extraliminal favors you. **Quest Hook**: A behemoth entity wakes up. It's moving toward something. Follow it?

14. **Bulwark**: Shield-blue steadiness. You perceive loyalty and structure. Defensive, reliable, steady. Associated with Protection, Stability, Rank.
    - *Lore*: You are a shield. Entities and NPCs naturally fall in line behind you. You're a born commander. **Quest Hook**: Your shield is cracking. What's on the other side?

15. **Ignis**: Furnace orange. You perceive burn and drive. Hot, relentless, consuming. Associated with Destruction, Power, Transformation.
    - *Lore*: You are a furnace. Everything fed into you transforms. NPCs respect your power; entities bond for your strength. Wildlands wants you. **Quest Hook**: The furnace inside you is getting hotter. Can you control it?

16. **Glaci**: Permafrost blue, frozen chimes. You perceive deep cold and crystallization. Hard, sharp, fixed. Associated with Rigidity, Clarity, Isolation.
    - *Lore*: You are ice-deep. NPCs find you cold; entities respect your sharpness. You're perfect for espionage. **Quest Hook**: Something is melting your frozen heart. Is that good or bad?

17. **Surge**: Capacitor yellow, pulse rhythm. You perceive buildup and release. Energy-charged, rhythmic, powerful bursts. Associated with Potential, Rhythm, Overload.
    - *Lore*: You are building energy. You can store power and release it in bursts. NPCs see you as intense. **Quest Hook**: Your surge is building faster than normal. What happens when you hit capacity?

18. **Siege**: Rampart bronze, metal strikes. You perceive assault and endurance. Fortress-and-army perception. Associated with War, Walls, Attrition.
    - *Lore*: You are a siege engine. You grind through obstacles. NPCs see you as relentless. Wildlands and Sovereign Crown both want you. **Quest Hook**: A siege is happening in Supraliminal. Do you break it or build it?

19. **Blight**: Sickly green, decay faster. You perceive corruption and entropy. Things break down around you. Associated with Decay, Plague, Transformation.
    - *Lore*: You are rot embodied. This seems negative, but decay is also *change*. Things around you transform rapidly. Veiled Current sees potential in you. **Quest Hook**: The blight inside you is growing. Can you weaponize it?

20. **Ossian**: Old ivory, bone knocks. You perceive age and history. Slow, resonant, ancient. Associated with History, Wisdom, Death.
    - *Lore*: You are old even if you're young. You hear echoes. NPCs trust your judgment; entities see you as an elder. **Quest Hook**: The ghosts in Liminal are getting *louder*. They want you to know something.

---

## Mods (20 Options): How You Interact

**Mod** is the system layer—how you *interface* with reality. Each mod is a playstyle and a philosophical stance. (These are currently undefined in code; I'm creating them wholesale.)

1. **Null**: Vanilla mode. No augmentation. You are baseline. Associated with Authenticity, Humanity, Groundedness.

2. **Surge**: Overclock. Everything you do is faster, hotter, more intense. Cooldowns are shorter; burnout is faster. Associated with Speed-running, Optimization, Overload.

3. **Sync**: Harmony. You and your entities are more connected. You can feel their damage; they can feel your intent. Associated with Partnership, Empathy, Feedback Loop.

4. **Wraith**: Ghost. You're harder to detect. Stealth bonuses. But people have trouble remembering you exist. Associated with Infiltration, Invisibility, Loneliness.

5. **Titanium**: Reinforced. You're harder to break. Damage reduction. But you move slower. Associated with Tank, Endurance, Stubbornness.

6. **Psychic**: Telepathy. You can "hear" nearby entities and NPCs' surface thoughts. They feel oddly read. Associated with Mind-control, Intrusion, Violation.

7. **Reflex**: Predictive. You can see the next 2 seconds slightly ahead of time. Not actual time travel—just intuition made visible. Associated with Destiny, Fate, Determinism.

8. **Wildcard**: Chaos. Everything about you is random and unpredictable. Your allies can't rely on you; neither can your enemies. Associated with Entropy, Wildness, Unpredictability.

9. **Mirage**: Illusion. Your true form is hidden. NPCs and entities see a different version of you. Associated with Deception, Identity-fluidity, Roleplaying.

10. **Archive**: Memory. Everything you experience is recorded perfectly. You can review past conversations and events in detail. Associated with Scholarship, Obsession, Stalking.

11. **Pulse**: Rhythm. Your presence affects reality like a heartbeat. Reality warps slightly around you in a cyclical pattern. Associated with Presence, Domination, Rhythm.

12. **Whisper**: Subtle. You're quiet. Stealth, but also the ability to slip influence into conversations. NPCs forget they were influenced by you. Associated with Manipulation, Subtlety, Charm.

13. **Void**: Absence-Based. You create pocket spaces. You can store items, hide, and carry more than physically possible. Associated with Hermione's bag, Mary Poppins, Pocket dimension.

14. **Scar**: Marked. You carry visible marks of every entity you've caught or every place you've been. You're more recognizable; NPCs know you. Associated with Identity, Fame, Notoriety.

15. **Symbiote**: Merged. Your entities aren't summoned; they're *integrated* into your body. You can "wear" them and use their abilities directly. Associated with Venom, Possession, Fusion.

16. **Amplify**: Resonance. Your abilities affect larger areas. Entities have better range. But you're more vulnerable to counterattacks. Associated with AoE, Area Control, Exposure.

17. **Siphon**: Drain. You can drain energy from entities and NPCs around you. You heal as you damage. But you're *visible* doing it, and it's disturbing. Associated with Vampirism, Parasitism, Feeding.

18. **Calcify**: Crystallization. Everything you touch becomes crystalline. You can build structures; you can trap enemies. But you're slowing down Liminal's corruption of yourself. Associated with Control, Stasis, Crystalization.

19. **Bloom**: Growth. Life spreads around you. Vines grow, plants thrive, allies heal automatically. But growth is invasive. Associated with Life, Infection, Reclamation.

20. **Echo**: Resonance. Every action you take echoes through the layers. NPCs in distant locations hear rumors about you immediately. Reputation spreads; so do accusations. Associated with Legend, Notoriety, Butterfly effect.

---

## Next Steps

The next documents will detail:

- **NPC Archetypes**: Recurring personalities whose fates are tied to player choices.
- **Quest Hooks by Faction**: Specific storylines that reward faction alignment.
- **Periliminal Psychology**: How the gauntlet targets your specific Hope profile.
- **Layer Lore**: Deep history of each layer and what its "real purpose" might be.
- **Entity Lore**: Why these specific 144 entities exist, what they represent, their evolutionary meaning.
