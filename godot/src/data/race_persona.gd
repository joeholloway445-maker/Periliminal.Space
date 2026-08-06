class_name RacePersona
## Who a race IS, past what they look like. HumanRaceArchetypes gives each
## canon race a body and a material; this gives them a temperament, a way of
## MOVING, a voice, mannerisms, an aesthetic, and personality leanings — so a
## Volt reads as a jittery live-wire, a Ferros as a rigid martial snob, and a
## Keth as a hooded opportunist even before anyone speaks.
##
## Keyed by canon race name (CanonRaces.RACES), same register as
## HumanRaceArchetypes. Every field is optional; missing ones fall back to the
## neutral defaults in movement()/voice(), so an unlisted race is simply calm
## and average rather than broken.
##
## What is wired where:
##   movement{}  -> PeriHumanRig.apply_persona(): idle_energy, gait_cadence,
##                  posture_lean, swagger actually change how the body stands,
##                  fidgets, and walks.
##   voice{}     -> pitch/rasp/cadence for whatever plays a race's barks.
##   style[]     -> aesthetic tags a wardrobe/gallery layer can lean on
##                  (hood, ornament, tech, plate…).
##   mannerisms[], traits[], quirk -> flavor for dialogue, the Dex, and NPC AI.

const PERSONAS: Dictionary = {
	# Shadow-striders of the urban canyons — hooded opportunists, always
	# casing the room. The classic rogue/thief with a hacker streak.
	"Keth": {
		"element": "Shadow · urban stealth",
		"temperament": "watchful, terse, keeps to the edges",
		"movement": {"idle_energy": 0.85, "gait_cadence": 1.08, "posture_lean": 0.05, "swagger": 0.15},
		"voice": {"pitch": 0.97, "rasp": 0.35, "cadence": "clipped"},
		"style": ["hood", "layered", "muted", "utility"],
		"tech_affinity": 0.6,
		"mannerisms": ["scans for exits", "speaks low and short", "keeps hands near pockets"],
		"traits": ["furtive", "distrustful", "opportunistic"],
		"quirk": "Won't sit with their back to a door, and always knows where the money is.",
	},
	# Crystal-blooded and luminous — serene, vain about their own glow, a
	# touch aloof toward the dull-skinned.
	"Lumari": {
		"element": "Living light · refraction",
		"temperament": "serene, poised, quietly superior",
		"movement": {"idle_energy": 0.9, "gait_cadence": 0.96, "posture_lean": -0.06, "swagger": 0.25},
		"voice": {"pitch": 1.08, "rasp": 0.05, "cadence": "flowing"},
		"style": ["ornament", "translucent", "elegant", "pale"],
		"tech_affinity": 0.3,
		"mannerisms": ["tilts head to catch the light", "speaks in measured tones", "admires reflective surfaces"],
		"traits": ["vain", "graceful", "aloof"],
		"quirk": "Angles themselves toward any light source mid-conversation without noticing.",
	},
	# Phase-hunters, half here — detached, eerie, never quite committed to
	# the moment they're standing in.
	"Vex": {
		"element": "Phase · half-material",
		"temperament": "detached, elliptical, unsettlingly calm",
		"movement": {"idle_energy": 0.7, "gait_cadence": 0.9, "posture_lean": -0.02, "swagger": 0.05},
		"voice": {"pitch": 1.0, "rasp": 0.2, "cadence": "trailing"},
		"style": ["muted", "loose", "layered"],
		"tech_affinity": 0.4,
		"mannerisms": ["drifts mid-sentence", "reaches through things absently", "long pauses"],
		"traits": ["evasive", "dreamy", "slippery"],
		"quirk": "Answers the question you meant, not the one you asked, then loses interest.",
	},
	# Apex predators — dominant, loud, chest-out, take up the whole room.
	"Ferox": {
		"element": "Predation · raw dominance",
		"temperament": "brash, territorial, quick to challenge",
		"movement": {"idle_energy": 1.15, "gait_cadence": 1.02, "posture_lean": -0.05, "swagger": 0.7},
		"voice": {"pitch": 0.82, "rasp": 0.6, "cadence": "booming"},
		"style": ["scarred", "bare-armed", "trophy", "heavy"],
		"tech_affinity": 0.2,
		"mannerisms": ["squares up when talking", "rolls shoulders", "sizes everyone up"],
		"traits": ["aggressive", "proud", "impatient"],
		"quirk": "Treats every doorway as a threshold worth owning.",
	},
	# Probability-seers — cryptic and condescending, they've 'already seen'
	# how this goes. A quieter kind of snob.
	"Azhul": {
		"element": "Foresight · probability",
		"temperament": "cryptic, patient, faintly condescending",
		"movement": {"idle_energy": 0.75, "gait_cadence": 0.94, "posture_lean": -0.07, "swagger": 0.1},
		"voice": {"pitch": 1.02, "rasp": 0.1, "cadence": "deliberate"},
		"style": ["robed", "ornament", "topknot", "arcane"],
		"tech_affinity": 0.35,
		"mannerisms": ["finishes your sentences", "gazes past you", "sighs knowingly"],
		"traits": ["condescending", "composed", "fatalistic"],
		"quirk": "Prefaces advice with 'as I foresaw,' whether or not they did.",
	},
	# Forest biomancers — earthy, warm, communal, unhurried.
	"Sylva": {
		"element": "Growth · living network",
		"temperament": "warm, grounded, communal",
		"movement": {"idle_energy": 0.9, "gait_cadence": 0.92, "posture_lean": 0.02, "swagger": 0.2},
		"voice": {"pitch": 1.0, "rasp": 0.2, "cadence": "easy"},
		"style": ["organic", "layered", "earthen", "long-hair"],
		"tech_affinity": 0.15,
		"mannerisms": ["touches nearby plants", "speaks in seasons", "unhurried gestures"],
		"traits": ["nurturing", "patient", "rooted"],
		"quirk": "Names every living thing in the room before any of the people.",
	},
	# Cyber-engineers — tinkerers and hackers, focus jumps from thing to
	# thing, hands always busy. Fidgety-clever.
	"Geara": {
		"element": "Augmentation · machine-blur",
		"temperament": "restless, inventive, distractible",
		"movement": {"idle_energy": 1.3, "gait_cadence": 1.06, "posture_lean": 0.06, "swagger": 0.1},
		"voice": {"pitch": 1.05, "rasp": 0.25, "cadence": "rapid"},
		"style": ["tech", "utility", "wired", "goggles"],
		"tech_affinity": 1.0,
		"mannerisms": ["fidgets with a gadget", "trails off to inspect machinery", "talks with hands"],
		"traits": ["tinkering", "curious", "scattered"],
		"quirk": "Has already taken apart whatever you handed them before you finished the sentence.",
	},
	# Void nocturnal hunters — silent, still, then suddenly not.
	"Nyx": {
		"element": "Void · night predation",
		"temperament": "silent, watchful, coiled",
		"movement": {"idle_energy": 0.6, "gait_cadence": 1.0, "posture_lean": 0.03, "swagger": 0.05},
		"voice": {"pitch": 0.9, "rasp": 0.4, "cadence": "sparse"},
		"style": ["black", "hood", "smooth", "silent"],
		"tech_affinity": 0.3,
		"mannerisms": ["holds unnerving stillness", "moves without warning", "rarely blinks first"],
		"traits": ["patient", "predatory", "quiet"],
		"quirk": "Goes so still you forget they're there, then they're beside you.",
	},
	# Hydromancers — fluid, adaptable, easygoing, goes with the current.
	"Aquis": {
		"element": "Water · adaptation",
		"temperament": "easygoing, fluid, hard to rile",
		"movement": {"idle_energy": 0.9, "gait_cadence": 0.98, "posture_lean": 0.0, "swagger": 0.35},
		"voice": {"pitch": 1.02, "rasp": 0.1, "cadence": "lilting"},
		"style": ["flowing", "silken", "salt-tinged", "loose"],
		"tech_affinity": 0.3,
		"mannerisms": ["sways slightly", "shrugs off conflict", "rolls with interruptions"],
		"traits": ["adaptable", "calm", "elusive"],
		"quirk": "Never argues upstream — agrees, then does exactly what they meant to.",
	},
	# Pyromancers — hot-tempered, impulsive, all on the surface.
	"Igni": {
		"element": "Fire · volatility",
		"temperament": "impulsive, expressive, short-fused",
		"movement": {"idle_energy": 1.25, "gait_cadence": 1.1, "posture_lean": -0.03, "swagger": 0.4},
		"voice": {"pitch": 1.0, "rasp": 0.45, "cadence": "hot"},
		"style": ["ember", "bare-armed", "scorched", "bold"],
		"tech_affinity": 0.25,
		"mannerisms": ["gestures sharply", "flares up then cools", "paces when idle"],
		"traits": ["hot-headed", "passionate", "reckless"],
		"quirk": "Runs a few degrees too warm and gets visibly brighter when annoyed.",
	},
	# Cryomancers — patient, cold, methodical, deliberate. Ice-slow, ice-aloof.
	"Kryos": {
		"element": "Ice · patience",
		"temperament": "cold, methodical, unhurried",
		"movement": {"idle_energy": 0.55, "gait_cadence": 0.85, "posture_lean": -0.05, "swagger": 0.1},
		"voice": {"pitch": 0.95, "rasp": 0.15, "cadence": "glacial"},
		"style": ["pale", "layered", "frost", "long-hair"],
		"tech_affinity": 0.4,
		"mannerisms": ["long deliberate pauses", "measured movements", "unmoved by urgency"],
		"traits": ["patient", "detached", "exacting"],
		"quirk": "Answers every rushed question at exactly the same unbothered pace.",
	},
	# Fungal symbiotes — collective, mellow, half-tuned to the network.
	"Myco": {
		"element": "Spore · collective mind",
		"temperament": "mellow, communal, half-elsewhere",
		"movement": {"idle_energy": 0.7, "gait_cadence": 0.9, "posture_lean": 0.04, "swagger": 0.1},
		"voice": {"pitch": 0.98, "rasp": 0.3, "cadence": "murmuring"},
		"style": ["earthen", "soft", "textured", "muted"],
		"tech_affinity": 0.2,
		"mannerisms": ["says 'we' for themselves", "pauses to 'listen'", "gentle and slow"],
		"traits": ["collective", "placid", "distant"],
		"quirk": "Refers to themselves in the plural and means it literally.",
	},
	# Bioelectric — twitchy, fast, can't sit still. The live-wire / ADHD one.
	"Volt": {
		"element": "Current · live wire",
		"temperament": "jittery, fast-talking, always moving",
		"movement": {"idle_energy": 1.6, "gait_cadence": 1.18, "posture_lean": 0.05, "swagger": 0.2},
		"voice": {"pitch": 1.12, "rasp": 0.2, "cadence": "staccato"},
		"style": ["tech", "bright", "conductive", "sleek"],
		"tech_affinity": 0.85,
		"mannerisms": ["taps and bounces", "changes subject mid-thought", "quick head flicks"],
		"traits": ["hyperactive", "impatient", "quick-witted"],
		"quirk": "Three ideas ahead of the sentence they're currently saying.",
	},
	# Stone-forged, oldest race — ponderous, stubborn, ancient and gravelly.
	"Petra": {
		"element": "Stone · deep time",
		"temperament": "ponderous, stubborn, ancient",
		"movement": {"idle_energy": 0.45, "gait_cadence": 0.8, "posture_lean": 0.02, "swagger": 0.3},
		"voice": {"pitch": 0.78, "rasp": 0.55, "cadence": "slow"},
		"style": ["heavy", "carved", "weathered", "bald"],
		"tech_affinity": 0.1,
		"mannerisms": ["moves with weight", "long silences", "unmovable once set"],
		"traits": ["stubborn", "enduring", "grave"],
		"quirk": "Measures everything in ages and finds your hurry mildly amusing.",
	},
	# Hemomancers — intense, precise, controlled, quietly unsettling.
	"Sanguis": {
		"element": "Blood · precise control",
		"temperament": "intense, exacting, quietly unsettling",
		"movement": {"idle_energy": 0.85, "gait_cadence": 0.98, "posture_lean": -0.04, "swagger": 0.25},
		"voice": {"pitch": 0.94, "rasp": 0.25, "cadence": "precise"},
		"style": ["crimson", "fitted", "elegant", "sharp"],
		"tech_affinity": 0.35,
		"mannerisms": ["holds eye contact too long", "exact gestures", "notices your pulse"],
		"traits": ["controlled", "intense", "meticulous"],
		"quirk": "Compliments your circulation like others compliment a haircut.",
	},
	# Genetic mosaics — erratic, mercurial, no two moments alike.
	"Chimera": {
		"element": "Mosaic · instability",
		"temperament": "mercurial, unpredictable, mid-shift",
		"movement": {"idle_energy": 1.4, "gait_cadence": 1.05, "posture_lean": 0.0, "swagger": 0.4},
		"voice": {"pitch": 1.0, "rasp": 0.35, "cadence": "erratic"},
		"style": ["mismatched", "patchwork", "clashing", "bold"],
		"tech_affinity": 0.4,
		"mannerisms": ["mood turns fast", "contradicts themselves", "restless variety"],
		"traits": ["volatile", "inventive", "inconsistent"],
		"quirk": "Whatever they were a minute ago is not a safe assumption now.",
	},
	# Stellar descendants — dreamy, grandiose, gazing past the horizon.
	"Astra": {
		"element": "Star · cosmic distance",
		"temperament": "dreamy, grandiose, far-away",
		"movement": {"idle_energy": 0.8, "gait_cadence": 0.94, "posture_lean": -0.08, "swagger": 0.3},
		"voice": {"pitch": 1.05, "rasp": 0.1, "cadence": "grand"},
		"style": ["celestial", "flowing", "ornament", "deep-hued"],
		"tech_affinity": 0.4,
		"mannerisms": ["looks upward", "speaks in scale", "loses the thread to wonder"],
		"traits": ["grandiose", "distant", "romantic"],
		"quirk": "Relates every small problem to something enormous and very far away.",
	},
	# Iron warriors — rigid, martial, and proudly contemptuous of 'lesser
	# metals'. The disciplined, haughty bigot.
	"Ferros": {
		"element": "Iron · martial order",
		"temperament": "rigid, disciplined, contemptuous of the soft",
		"movement": {"idle_energy": 0.7, "gait_cadence": 0.96, "posture_lean": -0.1, "swagger": 0.45},
		"voice": {"pitch": 0.85, "rasp": 0.4, "cadence": "clipped"},
		"style": ["plate", "polished", "martial", "insignia"],
		"tech_affinity": 0.45,
		"mannerisms": ["stands at attention", "looks down their nose", "ranks everyone"],
		"traits": ["haughty", "disciplined", "prejudiced"],
		"quirk": "Sorts everyone they meet into worthy alloys and cheap tin.",
	},
	# Partly incorporeal — gentle, drifting, otherworldly and soft-spoken.
	"Etherea": {
		"element": "Ether · half-here",
		"temperament": "gentle, drifting, otherworldly",
		"movement": {"idle_energy": 0.65, "gait_cadence": 0.88, "posture_lean": -0.03, "swagger": 0.1},
		"voice": {"pitch": 1.1, "rasp": 0.05, "cadence": "airy"},
		"style": ["translucent", "pale", "flowing", "soft"],
		"tech_affinity": 0.2,
		"mannerisms": ["voice seems to come from off to the side", "fades in and out", "touches lightly"],
		"traits": ["gentle", "elusive", "serene"],
		"quirk": "You're never quite sure they've fully arrived, or left.",
	},
	# Rune-scribes — pedantic scholars, meticulous, insufferably precise.
	"Glyphe": {
		"element": "Rune · living inscription",
		"temperament": "pedantic, meticulous, scholarly",
		"movement": {"idle_energy": 0.75, "gait_cadence": 0.95, "posture_lean": -0.06, "swagger": 0.1},
		"voice": {"pitch": 1.0, "rasp": 0.15, "cadence": "precise"},
		"style": ["inscribed", "robed", "ordered", "ink-marked"],
		"tech_affinity": 0.5,
		"mannerisms": ["corrects your terms", "cites sources", "reads the room like a page"],
		"traits": ["pedantic", "precise", "superior"],
		"quirk": "Cannot let an imprecise word pass — will annotate you mid-sentence.",
	},
}

const DEFAULT_MOVEMENT := {
	"idle_energy": 1.0, "gait_cadence": 1.0, "posture_lean": 0.0, "swagger": 0.2,
}
const DEFAULT_VOICE := {"pitch": 1.0, "rasp": 0.2, "cadence": "even"}

## A broad "mood" per race — the shared temperament bucket its ambient chatter
## and greetings are drawn from, so bark writing scales without twenty bespoke
## pools while each race still sounds like itself (its own voice, mannerisms,
## and quirk sit on top).
const MOOD_OF := {
	"Keth": "furtive", "Lumari": "proud", "Vex": "dreamy", "Ferox": "brash",
	"Azhul": "cryptic", "Sylva": "warm", "Geara": "hyper", "Nyx": "grim",
	"Aquis": "calm", "Igni": "brash", "Kryos": "cold", "Myco": "calm",
	"Volt": "hyper", "Petra": "stoic", "Sanguis": "grim", "Chimera": "hyper",
	"Astra": "dreamy", "Ferros": "proud", "Etherea": "dreamy", "Glyphe": "pedantic",
}

## Idle/ambient chatter — what a wandering NPC of this mood mutters to no one.
const MOOD_BARKS := {
	"furtive": ["Nothing to see here.", "...who's asking?", "Keep moving.",
		"I didn't see anything.", "Eyes on the exits."],
	"proud": ["Mind the finish.", "You may look. Briefly.", "Quality, obviously.",
		"Do try to keep up.", "Standards, darling."],
	"dreamy": ["...where was I?", "The light's strange today.", "Mm. Far away.",
		"Did you feel that?", "...oh. You're still here."],
	"brash": ["Out of my way.", "You want something?", "Ha! Weak.",
		"Step up or step off.", "That all you got?"],
	"cryptic": ["I already knew you'd pass.", "It ends as it must.", "Curious. As foreseen.",
		"You'll understand later.", "The odds favor silence."],
	"warm": ["Good to see you.", "Growing nicely, isn't it?", "Take care out there.",
		"Sit a while.", "The garden remembers you."],
	"hyper": ["Hi-hi-hey! Busy busy.", "Ooh what's that— nevermind.", "Quickquick, no time!",
		"Didyouseethat? Never mind!", "Three things at once, easy."],
	"grim": ["Don't.", "It never lasts.", "Everything ends.",
		"You'll learn.", "...still here, then."],
	"calm": ["It flows.", "No rush.", "All in time.",
		"Easy does it.", "We drift."],
	"cold": ["...", "Patience.", "In due course.",
		"The cold keeps.", "You're early. Or late. No matter."],
	"pedantic": ["Technically incorrect.", "Actually, the term is—", "Cite your source.",
		"Imprecise, but close.", "Let me correct that."],
	"stoic": ["Mm.", "Time enough.", "Stone endures.",
		"It has been longer.", "Your hurry amuses me."],
}

## Greeting lines by mood — the first thing this race says when engaged.
const MOOD_GREETINGS := {
	"furtive": ["...you. What do you want?", "Make it quick.", "Didn't expect company."],
	"proud": ["You have my attention. Briefly.", "Well. Look who it is.", "Speak, then."],
	"dreamy": ["Oh... hello. Were you here long?", "Mm? A visitor.", "You drifted in too."],
	"brash": ["What.", "You need something or not?", "Make it worth my time."],
	"cryptic": ["I wondered when you'd come.", "As expected. Sit.", "You're right on schedule."],
	"warm": ["Ah, welcome, welcome!", "Good to see a friendly face.", "Come, sit with me."],
	"hyper": ["Heyheyhey! What's up what's up?", "Oh! You! Hi! What's new?", "Fast now, talk talk!"],
	"grim": ["...what.", "You shouldn't have come.", "Speak and go."],
	"calm": ["Peace. What brings you?", "Ah. You found me.", "Come, no hurry."],
	"cold": ["...State your business.", "You have a moment. Use it.", "Well?"],
	"pedantic": ["Yes? Be precise.", "You have a question. Phrase it correctly.", "Ah. Do go on — accurately."],
	"stoic": ["You again. Sit.", "Time enough for you.", "Speak, small one."],
}

static func mood(canon_name: String) -> String:
	return str(MOOD_OF.get(canon_name, "calm"))

## A soft tint for a race's floating name/bark labels, so temperament reads at
## a glance in the crowd. Kept light so text stays legible on it.
const MOOD_COLOR := {
	"furtive": Color(0.72, 0.74, 0.82), "proud": Color(0.95, 0.86, 0.55),
	"dreamy": Color(0.78, 0.80, 0.98), "brash": Color(0.96, 0.62, 0.5),
	"cryptic": Color(0.80, 0.68, 0.95), "warm": Color(0.7, 0.9, 0.65),
	"hyper": Color(0.7, 0.95, 0.98), "grim": Color(0.72, 0.66, 0.7),
	"calm": Color(0.72, 0.86, 0.92), "cold": Color(0.78, 0.9, 0.98),
	"pedantic": Color(0.86, 0.82, 0.7), "stoic": Color(0.8, 0.78, 0.72),
}

static func mood_color(canon_name: String) -> Color:
	return MOOD_COLOR.get(mood(canon_name), Color.WHITE)

## An idle/ambient bark for a wandering NPC, drawn from its mood pool with an
## occasional signature quirk mixed in. Seeded so a given tick is reproducible.
static func bark_line(canon_name: String, seed_value: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var p: Dictionary = PERSONAS.get(canon_name, {})
	# One in five barks is the race's signature quirk, delivered as an aside.
	if p.has("quirk") and rng.randf() < 0.2:
		return str(p["quirk"])
	var pool: Array = MOOD_BARKS.get(mood(canon_name), MOOD_BARKS["calm"])
	return str(pool[rng.randi() % pool.size()])

## A greeting for this race, for dialogue openings — its temperament's hello.
static func greeting_line(canon_name: String, seed_value: int = 0) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else canon_name.hash()
	var pool: Array = MOOD_GREETINGS.get(mood(canon_name), MOOD_GREETINGS["calm"])
	return str(pool[rng.randi() % pool.size()])

static func get_persona(canon_name: String) -> Dictionary:
	return PERSONAS.get(canon_name, {})

## Resolve a canon race from either a canon name or a gameplay breed id.
static func canon_for_id(race_id: String) -> String:
	if race_id.is_empty():
		return ""
	if PERSONAS.has(race_id):
		return race_id
	return CanonRaces.canon_for_id(race_id)

## Movement modifiers for PeriHumanRig.apply_persona(), by canon race. Always
## a full dict — an unlisted race gets the neutral defaults.
static func movement(canon_name: String) -> Dictionary:
	var p: Dictionary = PERSONAS.get(canon_name, {})
	var m: Dictionary = DEFAULT_MOVEMENT.duplicate()
	for k in p.get("movement", {}):
		m[k] = p["movement"][k]
	return m

## Movement modifiers resolved from a gameplay breed id ("tabby"), for callers
## that hold the cat-breed id rather than the canon name.
static func movement_for_id(race_id: String) -> Dictionary:
	if race_id.is_empty():
		return DEFAULT_MOVEMENT.duplicate()
	return movement(CanonRaces.canon_for_id(race_id))

## The canon race for a world NPC. Honors an explicit canon/race/species field
## if the NPC data carries one; otherwise assigns a stable race from the NPC's
## id so the same NPC always speaks and acts as the same race, world to world.
static func canon_for_npc(npc: Dictionary) -> String:
	for key in ["canon", "race", "race_id", "species", "breed"]:
		var v := str(npc.get(key, ""))
		if v.is_empty():
			continue
		if PERSONAS.has(v):
			return v
		var c := CanonRaces.canon_for_id(v)
		if PERSONAS.has(c):
			return c
	var id := str(npc.get("id", npc.get("npc_id", npc.get("name", ""))))
	if id.is_empty():
		return ""
	var races: Array = CanonRaces.RACES
	return str(races[abs(id.hash()) % races.size()])

## A single mannerism as a stage-direction cue ("scans for exits"), chosen
## deterministically from `seed_value` so a given NPC+line always shows the
## same one but different lines vary. Empty when the race has no mannerisms.
static func mannerism_cue(canon_name: String, seed_value: int) -> String:
	var p: Dictionary = PERSONAS.get(canon_name, {})
	var m: Array = p.get("mannerisms", [])
	if m.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return str(m[rng.randi() % m.size()])

## How predisposed this race is to like you before anything happens — a small
## starting nudge on disposition. Warm/gentle temperaments open up faster;
## haughty/prejudiced/cold ones make you earn it. Bounded to [-18, +18] so it
## flavours first impressions without overriding how you actually treat them.
const _WARM_TRAITS := ["nurturing", "warm", "gentle", "easygoing", "adaptable",
	"serene", "collective", "romantic", "curious", "passionate"]
const _COLD_TRAITS := ["haughty", "prejudiced", "condescending", "aloof", "superior",
	"pedantic", "distrustful", "detached", "grave", "predatory", "controlled", "volatile"]

static func disposition_bias(canon_name: String) -> int:
	var p: Dictionary = PERSONAS.get(canon_name, {})
	var traits: Array = p.get("traits", [])
	var bias := 0
	for t in traits:
		if t in _WARM_TRAITS:
			bias += 6
		elif t in _COLD_TRAITS:
			bias -= 6
	return clampi(bias, -18, 18)

static func voice(canon_name: String) -> Dictionary:
	var p: Dictionary = PERSONAS.get(canon_name, {})
	var v: Dictionary = DEFAULT_VOICE.duplicate()
	for k in p.get("voice", {}):
		v[k] = p["voice"][k]
	return v

## A compact one-to-two line tag for roster/select screens: element,
## temperament, and the signature quirk. Accepts breed id or canon name.
static func short(race_id_or_canon: String) -> String:
	var canon := race_id_or_canon
	if not PERSONAS.has(canon):
		canon = CanonRaces.canon_for_id(race_id_or_canon)
	var p: Dictionary = PERSONAS.get(canon, {})
	if p.is_empty():
		return ""
	var out := "%s — %s." % [str(p.get("element", canon)), str(p.get("temperament", ""))]
	if p.has("quirk"):
		out += " " + str(p["quirk"])
	return out

## A short, readable persona summary for the creator / Dex — temperament,
## a couple of mannerisms, and the signature quirk. Accepts breed id or canon.
static func describe(race_id_or_canon: String) -> String:
	var canon := race_id_or_canon
	if not PERSONAS.has(canon):
		canon = CanonRaces.canon_for_id(race_id_or_canon)
	var p: Dictionary = PERSONAS.get(canon, {})
	if p.is_empty():
		return ""
	var lines: Array = []
	lines.append("%s — %s" % [str(p.get("element", canon)), str(p.get("temperament", ""))])
	var traits: Array = p.get("traits", [])
	if not traits.is_empty():
		lines.append("Tends toward: " + ", ".join(traits))
	var manner: Array = p.get("mannerisms", [])
	if not manner.is_empty():
		lines.append("Mannerisms: " + ", ".join(manner))
	if p.has("quirk"):
		lines.append(str(p["quirk"]))
	return "\n".join(lines)
