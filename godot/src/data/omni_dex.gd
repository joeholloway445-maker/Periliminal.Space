class_name OmniDex
## The Master Omni Dex roster, transcribed from the design workbook
## (Races / Frames / Morph_Rigs sheets) into engine-readable data.
##
## This is the authored source of truth for the 20 x 20 x 20 = 8,000
## build identities. It is deliberately kept separate from
## `race_lore.gd` / `human_race_archetypes.gd`, which describe a
## DIFFERENT, earlier 20-race roster (Keth / Lumari / Vex / ...) that
## the PeriHuman genome system is currently keyed to. The two rosters
## have not been reconciled — see docs/OMNIDEX.md before wiring this
## into character creation.
##
## Faction ids here already match the PerceptionSystem RPS wheel
## (sovereign_crown > wildlands_ascendants > veiled_current > ...).

const RACES: Dictionary = {
	"lumenari": {
		"name": "Lumenari", "faction": "veiled_current",
		"stat_bonus": {"resonance": 2, "frequency": 1},
		"passive": "Radiant Pulse: Small AoE burst at max Focus",
		"drawback": "Focus -15% in darkness",
		"description": "Futuristic humanoid glowing with solar energy, sleek armor, ambient light aura.",
		"lore": "Lumenari bodies bank ambient light and release it in disciplined bursts. At peak Focus a Lumenari unleashes Radiant Pulse, a small AoE burst that scatters anything pressing too close — but the same light that empowers them gutters in darkness.",
	},
	"gutterkin": {
		"name": "Gutterkin", "faction": "sovereign_crown",
		"stat_bonus": {"power": 2, "agility": 1},
		"passive": "Hazard Conversion: Hazards restore Focus",
		"drawback": "Vitality Regen -10% in clean zones",
		"description": "Urban survivor humanoid, bio-urban mutation, toxic-stained clothing, gritty neon background.",
		"lore": "Forged in collapsed undercities, Gutterkin metabolisms turn hazard into harvest — Hazard Conversion lets contaminated terrain restore their Focus. Sterile, clean zones do the opposite, leaving them sluggish to regenerate.",
	},
	"deepborne": {
		"name": "Deepborne", "faction": "wildlands_ascendants",
		"stat_bonus": {"power": 2, "resonance": 1},
		"passive": "Pressure Pulse: Knockback when struck",
		"drawback": "Momentum -10% on surface",
		"description": "Abyssal humanoid, deep-sea armor with luminescent patterns.",
		"lore": "Deepborne carry trench pressure in their bones. Pressure Pulse knocks back anything that lands a hit on them, but that same density makes their footing unsteady the moment they surface.",
	},
	"ashen_choir": {
		"name": "Ashen Choir", "faction": "veiled_current",
		"stat_bonus": {"resonance": 2, "frequency": 1},
		"passive": "Sorrow Amplification: Ally damage boost",
		"drawback": "Incoming damage rises after ally death",
		"description": "Ethereal, smoky translucent humanoid, floating in dark mist.",
		"lore": "Ashen Choir grieve collectively — Sorrow Amplification channels loss into a swelling damage boost for every ally still standing. But when one of their own falls, the chorus cracks, and incoming damage rises in the silence that follows.",
	},
	"veilstriders": {
		"name": "Veilstriders", "faction": "sovereign_crown",
		"stat_bonus": {"agility": 2, "frequency": 1},
		"passive": "Phase Skip: 5% chance to ignore incoming hit",
		"drawback": "Minor random displacement under heavy damage",
		"description": "Phase-shifting humanoid, fragmented body, energy trails.",
		"lore": "Half-here at any given moment, Veilstriders have a five percent chance to simply not be where an attack lands. The same instability that saves them occasionally flings them a short, unwanted distance under heavy fire.",
	},
	"chronarchs": {
		"name": "Chronarchs", "faction": "wildlands_ascendants",
		"stat_bonus": {"resonance": 2, "frequency": 1},
		"passive": "Micro-Rewind: Corrects small movement error",
		"drawback": "Ability spam slows movement",
		"description": "Time-fractured humanoid with clockwork and floating temporal fragments.",
		"lore": "Chronarchs nudge their own timeline by a fraction of a second — Micro-Rewind quietly corrects a small movement error before it matters. Chaining too many abilities at once destabilizes that correction loop and slows them down.",
	},
	"nullborn": {
		"name": "Nullborn", "faction": "veiled_current",
		"stat_bonus": {"power": 1, "agility": 1, "resonance": 1},
		"passive": "Outcome Shift: Minor RNG skew",
		"drawback": "Influence reduced",
		"description": "Alien humanoid outside normal physics, asymmetrical features, surreal style.",
		"lore": "Nullborn exist slightly outside ordinary causality, and Outcome Shift quietly skews chance events in their favor. That same detachment from normal rules makes it hard for them to read or sway others.",
	},
	"thorned": {
		"name": "Thorned", "faction": "sovereign_crown",
		"stat_bonus": {"power": 2, "agility": 1},
		"passive": "Regrowth Armor: Accelerated wound regeneration",
		"drawback": "Fire Resistance -20%",
		"description": "Plant-symbiotic humanoid with vines and thorns, glowing pollen accents.",
		"lore": "Thorned wounds knit shut almost as fast as they open — Regrowth Armor lets their bark-like hide regenerate mid-fight. Fire finds them far less forgiving than it finds most.",
	},
	"echoes": {
		"name": "Echoes", "faction": "wildlands_ascendants",
		"stat_bonus": {"resonance": 2, "frequency": 1},
		"passive": "System Hack: Passively destabilizes nearby systems",
		"drawback": "EMP Vulnerability -15%",
		"description": "Digital humanoid, holographic patterns, circuit-like glowing tattoos",
		"lore": "Echoes run on borrowed code, slipping Passive System Hacks into nearby networks without a sound. But they are still code at heart, and an EMP leaves them stuttering far worse than flesh ever would.",
	},
	"hollowed": {
		"name": "Hollowed", "faction": "veiled_current",
		"stat_bonus": {"power": 1, "resonance": 1, "frequency": 1},
		"passive": "Extra Item Slot: Carries one additional item",
		"drawback": "Maintenance Drain (minor upkeep)",
		"description": "Biotech human, mechanical implants fused with flesh.",
		"lore": "Hollowed carry a body cavity retrofitted for storage — an Extra Item Slot that never weighs them down. The implants keeping them alive need constant minor upkeep, draining a little resource just to stay running.",
	},
	"riftspawn": {
		"name": "Riftspawn", "faction": "sovereign_crown",
		"stat_bonus": {"agility": 2, "power": 1},
		"passive": "Minor Gravity Pull: Pulls nearby targets slightly",
		"drawback": "Spatial instability",
		"description": "Dimensional humanoid, gravity-defying posture, cosmic rift energy.",
		"lore": "Riftspawn drag a sliver of broken space behind them, exerting a Minor Gravity Pull on anything nearby. That same torn geometry leaves them spatially unstable, prone to involuntary micro-shifts.",
	},
	"mirekin": {
		"name": "Mirekin", "faction": "wildlands_ascendants",
		"stat_bonus": {"power": 2, "resonance": 1},
		"passive": "Hive Awareness: Senses nearby allies through terrain",
		"drawback": "Momentum -10%",
		"description": "Swamp humanoid, muddy textured skin, amphibious features.",
		"lore": "Mirekin think as a hive when in numbers — Hive Awareness lets them sense allies through the swamp itself. Their bog-adapted gait, though, was never built for speed on open ground.",
	},
	"sunspun": {
		"name": "Sunspun", "faction": "veiled_current",
		"stat_bonus": {"agility": 2, "resonance": 1},
		"passive": "Radiant Burst: Burst damage at max Focus",
		"drawback": "Overheat risk",
		"description": "Solar-infused humanoid, golden energy streams, sun motif armor.",
		"lore": "Sunspun stockpile heat until they erupt in a Radiant Burst at max Focus, scorching anything caught nearby. The same buildup risks an overheat if they push their reserves too far.",
	},
	"coldmarrow": {
		"name": "Coldmarrow", "faction": "sovereign_crown",
		"stat_bonus": {"power": 2, "frequency": 1},
		"passive": "Freeze Aura: Slows nearby enemies",
		"drawback": "Momentum -15%",
		"description": "Ice elemental humanoid, crystalline body, frost mist",
		"lore": "A Freeze Aura trails every Coldmarrow, slowing anything that lingers too close. Their crystalline joints, however, were never built for quick footwork.",
	},
	"pulseborn": {
		"name": "Pulseborn", "faction": "wildlands_ascendants",
		"stat_bonus": {"agility": 2, "frequency": 1},
		"passive": "Shock Dash: AoE detonation on dash",
		"drawback": "Nervous Overload (self-damage on overuse)",
		"description": "Electrified humanoid, crackling energy flowing along body.",
		"lore": "Pulseborn convert stored charge into a Shock Dash that detonates in an AoE on arrival. Pushed too hard, that same current arcs back and burns its carrier.",
	},
	"dreamflesh": {
		"name": "Dreamflesh", "faction": "veiled_current",
		"stat_bonus": {"resonance": 1, "agility": 1, "frequency": 1},
		"passive": "Minor Morph Shift: Subtle adaptive reshaping",
		"drawback": "Sleep cycle fluctuation",
		"description": "Adaptive humanoid, soft glowing skin, subtle morphing features.",
		"lore": "Dreamflesh bodies are never quite finished — a Minor Morph Shift lets them subtly reshape on demand. That same unsettled biology leaves their sleep cycle erratic and hard to predict.",
	},
	"crownless": {
		"name": "Crownless", "faction": "sovereign_crown",
		"stat_bonus": {"resonance": 2, "power": 1},
		"passive": "Authority Override: Overrides nearby command structures",
		"drawback": "Faction hostility events",
		"description": "Political/faction humanoid, rugged appearance, emblematic robes.",
		"lore": "Crownless wield Authority Override, a presence that bends nearby command structures their way. That same defiance of hierarchy makes them a magnet for faction hostility wherever they go.",
	},
	"rotweavers": {
		"name": "Rotweavers", "faction": "wildlands_ascendants",
		"stat_bonus": {"power": 1, "frequency": 2},
		"passive": "Decay Conversion: Extra loot from decay/kills",
		"drawback": "Influence -10%",
		"description": "Decay-infused humanoid, fungus and rot patterns, skeletal features.",
		"lore": "Rotweavers turn ruin into resource — Decay Conversion Loot pulls extra salvage from anything that falls near them. Their unsettling presence, though, tends to sour any goodwill they might otherwise earn.",
	},
	"glassborn": {
		"name": "Glassborn", "faction": "veiled_current",
		"stat_bonus": {"power": 2, "resonance": 1},
		"passive": "Mirror Shield: Reflects a portion of incoming damage",
		"drawback": "Shatter threshold vulnerability",
		"description": "Crystalline humanoid, shard-like armor, prismatic lighting.",
		"lore": "A Mirror Shield wraps every Glassborn, throwing a portion of incoming damage straight back at its source. Push past their limit, though, and that same shell shatters outright.",
	},
	"starfall": {
		"name": "Starfall", "faction": "sovereign_crown",
		"stat_bonus": {"power": 1, "agility": 2},
		"passive": "Impact Entry: Fall damage becomes AoE",
		"drawback": "Meteor Reveal Burst (reveals position)",
		"description": "Celestial humanoid, cosmic energy trails, star-studded armor.",
		"lore": "Starfall turn their own fall damage into Impact Entry, an AoE shockwave on landing. The same meteoric arrival lights up the sky and gives away their position long before they hit the ground.",
	},
}

const FRAMES: Dictionary = {
	"skirmisher": {
		"name": "Skirmisher", "role": "Duelist", "frame_type": "light",
		"stats": {"agility": 8, "power": 5, "resonance": 4, "frequency": 6},
		"description": "Sharp, weight-forward bursts with a small shield and blade always ready",
		"best_for": "Duel combat, mobility burst",
		"passive": "Precision: Movement crit scaling",
	},
	"strider": {
		"name": "Strider", "role": "Scout", "frame_type": "light",
		"stats": {"agility": 9, "power": 3, "resonance": 4, "frequency": 7},
		"description": "Forward-leaning sprint that compounds the longer it runs",
		"best_for": "Speed scaling",
		"passive": "Velocity: Dash cooldown compresses with sustained motion",
	},
	"skybound": {
		"name": "Skybound", "role": "Aerialist", "frame_type": "light",
		"stats": {"agility": 8, "power": 4, "resonance": 5, "frequency": 6},
		"description": "Wind-trailing vertical lift with jet-assisted hops",
		"best_for": "Air dominance",
		"passive": "Lift: Jump cooldown reduces with airtime",
	},
	"flicker": {
		"name": "Flicker", "role": "Blink Duelist", "frame_type": "light",
		"stats": {"agility": 9, "power": 4, "resonance": 6, "frequency": 5},
		"description": "Short-range blinks that leave fragmented afterimages",
		"best_for": "Short-range teleport combat",
		"passive": "Phase Charge: Blink chain multiplier",
	},
	"marshal": {
		"name": "Marshal", "role": "Tactician", "frame_type": "light",
		"stats": {"agility": 6, "power": 5, "resonance": 7, "frequency": 5},
		"description": "Measured, commanding stride backed by holographic displays",
		"best_for": "Tactical AI leadership",
		"passive": "Command: NPC efficiency",
	},
	"bloom": {
		"name": "Bloom", "role": "Adaptive Combatant", "frame_type": "light",
		"stats": {"agility": 7, "power": 4, "resonance": 6, "frequency": 6},
		"description": "Light-footed drift, leaving a trail of drifting spores",
		"best_for": "Adaptive combat",
		"passive": "Mutation Rate: Resistance shifts",
	},
	"rewind": {
		"name": "Rewind", "role": "Time Controller", "frame_type": "light",
		"stats": {"agility": 7, "power": 3, "resonance": 8, "frequency": 6},
		"description": "Soft glowing trails that bend slightly out of sync with motion",
		"best_for": "Micro time control",
		"passive": "Temporal Thread: Undo window",
	},
	"conduit": {
		"name": "Conduit", "role": "Energy Caster", "frame_type": "light",
		"stats": {"agility": 6, "power": 4, "resonance": 7, "frequency": 7},
		"description": "Dynamic casting pose with arcs flowing limb to limb",
		"best_for": "Energy cycling",
		"passive": "Flux: Cooldown compression",
	},
	"shade": {
		"name": "Shade", "role": "Assassin", "frame_type": "light",
		"stats": {"agility": 8, "power": 6, "resonance": 4, "frequency": 4},
		"description": "Low, crouched approach that vanishes into shadow",
		"best_for": "Assassination",
		"passive": "Obscurity: Stealth-to-crit scaling",
	},
	"fabricator": {
		"name": "Fabricator", "role": "Engineer", "frame_type": "light",
		"stats": {"agility": 6, "power": 4, "resonance": 5, "frequency": 8},
		"description": "Ready-to-build stance, tool limbs unfolding on approach",
		"best_for": "Deployables & traps",
		"passive": "Assembly: Build speed multiplier",
	},
	"bastion": {
		"name": "Bastion", "role": "Defender", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 9, "resonance": 4, "frequency": 3},
		"description": "Plants and holds, near-immovable once set",
		"best_for": "Area defense",
		"passive": "Fortitude: Damage reduction while stationary",
	},
	"juggernaut": {
		"name": "Juggernaut", "role": "Bruiser", "frame_type": "heavy",
		"stats": {"agility": 3, "power": 9, "resonance": 3, "frequency": 3},
		"description": "Slow build into an unstoppable charge",
		"best_for": "Charge devastation",
		"passive": "Impact: Momentum converts to AoE",
	},
	"gravemind": {
		"name": "Gravemind", "role": "Controller", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 7, "resonance": 6, "frequency": 3},
		"description": "Grounded yet imposing, orbiting magnetic orbs",
		"best_for": "Pull, slam, anti-air",
		"passive": "Gravity: CC strength scaling",
	},
	"riftbreaker": {
		"name": "Riftbreaker", "role": "Disruptor", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 7, "resonance": 7, "frequency": 3},
		"description": "Imposing stance ringed by dimensional cracks",
		"best_for": "Map distortion",
		"passive": "Spatial Integrity: Portal durability",
	},
	"sovereign": {
		"name": "Sovereign", "role": "Territory Holder", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 7, "resonance": 8, "frequency": 2},
		"description": "Commanding, near-seated stance that rarely advances",
		"best_for": "Zone ownership",
		"passive": "Dominion: Territory yield",
	},
	"worldroot": {
		"name": "Worldroot", "role": "Terraformer", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 8, "resonance": 5, "frequency": 4},
		"description": "Grounded stance, roots spreading wider the longer it stands",
		"best_for": "Environmental takeover",
		"passive": "Spread: Terrain conversion rate",
	},
	"epoch": {
		"name": "Epoch", "role": "Time Warden", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 6, "resonance": 9, "frequency": 3},
		"description": "Gravitational distortions ripple around every step",
		"best_for": "Macro time control",
		"passive": "Chrono Weight: Time dilation",
	},
	"overlord": {
		"name": "Overlord", "role": "Detonator", "frame_type": "heavy",
		"stats": {"agility": 1, "power": 9, "resonance": 6, "frequency": 2},
		"description": "Imposing and static, power core glowing brighter the longer it charges",
		"best_for": "Energy detonation",
		"passive": "Overheat: Cataclysm multiplier",
	},
	"obscura": {
		"name": "Obscura", "role": "Veilkeeper", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 6, "resonance": 8, "frequency": 3},
		"description": "Static, cloak rippling with area concealment energy",
		"best_for": "Mass stealth control",
		"passive": "Veil Density: Area concealment",
	},
	"architect": {
		"name": "Architect", "role": "Fortifier", "frame_type": "heavy",
		"stats": {"agility": 1, "power": 8, "resonance": 4, "frequency": 6},
		"description": "Construction-ready stance, structural plating locking into place",
		"best_for": "Fortress building",
		"passive": "Infrastructure: Structure durability",
	},
}

const MORPH_RIGS: Dictionary = {
	"heavy_siege": {
		"name": "Heavy Siege", "boon": "+Stability", "cost": "-Momentum",
		"description": "Reinforced plating across a slow, towering industrial silhouette",
		"visual": "Massive skeletal frame, reinforced plating, slow but stable, industrial fantasy aesthetic.",
	},
	"swiftburner": {
		"name": "Swiftburner", "boon": "+Acceleration", "cost": "-Control",
		"description": "Elongated legs trailing kinetic energy at speed",
		"visual": "Light skeletal frame, elongated legs, agile posture, kinetic energy trails, fast-motion effect.",
	},
	"multi_limbed": {
		"name": "Multi-Limbed", "boon": "+Aux Action Slot", "cost": "-Energy Stability",
		"description": "Extra functional limbs folded into a complex action-ready pose",
		"visual": "Humanoid with multiple functional limbs, balanced mechanics, complex action-ready pose.",
	},
	"towering": {
		"name": "Towering", "boon": "+Intimidation Radius", "cost": "-Evasion",
		"description": "Vertically exaggerated proportions with an intimidating presence",
		"visual": "Extremely tall skeletal frame, intimidating proportions, vertical emphasis, epic fantasy setting.",
	},
	"compact": {
		"name": "Compact", "boon": "+Evasion", "cost": "-AoE Reach",
		"description": "Short, dense build held in a low crouched stance",
		"visual": "Short, dense skeletal frame, high agility, crouched action stance, futuristic environment.",
	},
	"elastic": {
		"name": "Elastic", "boon": "+Melee Range", "cost": "None",
		"description": "Stretching, elongated limbs caught mid exaggerated motion",
		"visual": "Flexible elongated skeletal frame, stretching limbs, exaggerated motion pose, dynamic style.",
	},
	"floating_core": {
		"name": "Floating Core", "boon": "+Vertical Mastery", "cost": "-Traction",
		"description": "A suspended central core held aloft in a floating posture",
		"visual": "Levitation-based frame, suspended central core, floating posture, mystical sci-fi lighting.",
	},
	"split_form": {
		"name": "Split Form", "boon": "+Decoy", "cost": "-Focus Regen",
		"description": "A dual-body silhouette mirrored by an energy separation effect",
		"visual": "Skeletal frame divided into dual-body segments, mirrored action pose, energy separation effects.",
	},
	"inverted_spine": {
		"name": "Inverted Spine", "boon": "+Backstab Damage", "cost": "-Front Defense",
		"description": "An inverted spine giving a back-heavy, off-kilter stance",
		"visual": "Unusual upside-down spine skeletal structure, back-heavy action stance, dark fantasy setting.",
	},
	"modular": {
		"name": "Modular", "boon": "+Item Slot", "cost": "-Vitality Regen",
		"description": "Interchangeable mechanical parts in a tool-equipped posture",
		"visual": "Interchangeable skeletal parts, mechanical modular design, tool-equipped posture, workshop background.",
	},
	"armored": {
		"name": "Armored", "boon": "+Mitigation", "cost": "-Momentum",
		"description": "Tank-like heavy plating across a battle-ready stance",
		"visual": "Heavily plated skeletal frame, tank-like proportions, battle-ready stance, dark industrial environment.",
	},
	"lithe": {
		"name": "Lithe", "boon": "+Dodge Window", "cost": "-Stability",
		"description": "A slim silhouette blurred by constant evasive motion",
		"visual": "Slim skeletal frame, high dodge emphasis, dynamic motion blur, agile pose.",
	},
	"tendril": {
		"name": "Tendril", "boon": "+CC Duration", "cost": "-Burst Damage",
		"description": "Organic tendrils extending outward from the frame",
		"visual": "Skeletal frame with organic tendrils extending from body, CC-focused stance, shadowy environment.",
	},
	"rooted": {
		"name": "Rooted", "boon": "+Control Strength", "cost": "No Dash",
		"description": "Skeletal roots anchoring the lower body to the ground",
		"visual": "Lower body anchored, strong grounded posture, skeletal roots extending, earthy setting.",
	},
	"hover_strider": {
		"name": "Hover Strider", "boon": "No Fall Damage", "cost": "-Stamina Regen",
		"description": "An aerodynamic frame held in a constant hovering pose",
		"visual": "Floating skeletal frame, aerodynamic form, hovering pose, sci-fi sky background.",
	},
	"centroid": {
		"name": "Centroid", "boon": "+5% All Stats", "cost": "None",
		"description": "Perfectly symmetric, neutral proportions in a balanced stance",
		"visual": "Balanced skeletal frame, neutral proportions, symmetric action pose, bright neutral environment.",
	},
	"shardform": {
		"name": "Shardform", "boon": "+Reflect", "cost": "Shatter Risk",
		"description": "Reflective angular shards protruding from the frame",
		"visual": "Crystalline skeletal frame, reflective shards protruding, angular pose, high fantasy lighting.",
	},
	"quadruped": {
		"name": "Quadruped", "boon": "+Sprint Speed", "cost": "No Dual-Wield",
		"description": "A low, four-legged stance built for sprinting",
		"visual": "Four-legged skeletal frame, low center of gravity, sprinting pose, rugged terrain environment.",
	},
	"serpentine": {
		"name": "Serpentine", "boon": "+Immobilize Resist", "cost": "-Jump Height",
		"description": "A long, coiled frame moving with snake-like flexibility",
		"visual": "Long, flexible skeletal frame, snake-like movement, coiled action stance, mystical background.",
	},
	"colossus": {
		"name": "Colossus", "boon": "+Control", "cost": "-Momentum",
		"description": "Gigantic towering proportions in a slow, imposing pose",
		"visual": "Gigantic skeletal frame, towering proportions, slow imposing pose, epic battle environment.",
	},
}

## Omni Dex axes onto the unified stat set. Power and Agility are the same
## axes the engine already called pow and spd, so they merge rather than
## duplicate; Resonance and Frequency are genuinely new and keep their own
## keys. Returns engine-shaped {pow, spd, rsn, frq, ...} deltas.
const AXIS_MAP := {
	"power": "pow", "agility": "spd",
	"resonance": "rsn", "frequency": "frq",
	"vitality": "res", "focus": "rsn",
}

## A race's stat_bonus translated into the engine's keys, scaled so an Omni
## Dex point (1-2) reads like the engine's bonuses rather than vanishing
## against a base of 50.
static func stat_bonus_merged(race_id: String, per_point: int = 4) -> Dictionary:
	var out: Dictionary = {}
	for axis in race(race_id).get("stat_bonus", {}):
		var key := str(AXIS_MAP.get(str(axis), ""))
		if key.is_empty():
			continue
		out[key] = int(out.get(key, 0)) + int(race(race_id).stat_bonus[axis]) * per_point
	return out

static func race(id: String) -> Dictionary:
	return RACES.get(id, {})

static func frame(id: String) -> Dictionary:
	return FRAMES.get(id, {})

static func morph_rig(id: String) -> Dictionary:
	return MORPH_RIGS.get(id, {})

## Every race sharing a faction, for the RPS perception wheel.
static func races_in_faction(faction_id: String) -> Array[String]:
	var out: Array[String] = []
	for rid in RACES:
		if str(RACES[rid].get("faction", "")) == faction_id:
			out.append(str(rid))
	return out
