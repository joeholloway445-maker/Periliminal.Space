class_name VariantPresets
## The eight starting-appearance variants, as HumanDNA gene deltas.
##
## The generated gallery (scripts/prompt_templates.py VARIANTS) shows eight
## distinct individuals per race so a player picks a starting look. This is
## the OTHER half of that: the same eight, expressed as proportion nudges, so
## the pick shapes the real PeriHuman RIG — its build, height, age, features —
## not just the portrait shown next to it. A "broad weathered veteran" pick
## produces a broad, heavy, older skeleton with functioning limbs, because
## the variant drives the genome HumanSkeletonBuilder reads.
##
## Deltas are applied on top of the race archetype and the affinity-derived
## body (RaceBodyDerivation), so a variant flavours the individual without
## erasing what the race is. Gene ids match HumanDNA; unknown ids are ignored
## by nudge_gene, so this stays safe if the gene set changes.
##
## Keyed by the variant id the gallery filenames use (v1..v8).

const PRESETS := {
	"v1": {  # lean and youthful, wiry, sharp features, close-cropped hair
		"genes": {"build": -0.16, "muscle": -0.06, "age": -0.28,
			"cheek_fullness": -0.12, "jaw_width": -0.05, "leg_length": 0.06},
		"hair_style": "short",
	},
	"v2": {  # powerfully built and broad, heavy muscle, scarred, weathered
		"genes": {"build": 0.22, "muscle": 0.26, "neck_thickness": 0.16,
			"jaw_width": 0.16, "shoulder_width": 0.18, "age": 0.32, "stubble": 0.4},
		"hair_style": "buzz",
	},
	"v3": {  # tall and gaunt, long-limbed, hollow-cheeked, ascetic
		"genes": {"height": 0.20, "build": -0.16, "leg_length": 0.16,
			"arm_length": 0.13, "cheek_fullness": -0.22, "eye_depth": 0.13,
			"cheekbone_height": 0.12},
		"hair_style": "long",
	},
	"v4": {  # compact and dense, low, rounded heavy features, shaved head
		"genes": {"height": -0.16, "build": 0.16, "muscle": 0.10,
			"cheek_fullness": 0.16, "neck_thickness": 0.12, "jaw_width": 0.08},
		"hair_style": "buzz",
	},
	"v5": {  # middle-aged and hard-worn, sinewy, grey, broken nose
		"genes": {"age": 0.42, "muscle": 0.06, "cheek_fullness": -0.08,
			"nose_width": 0.08, "brow_depth": 0.08},
	},
	"v6": {  # striking and unusually beautiful, fine symmetrical features
		"genes": {"cheekbone_height": 0.16, "cheekbone_width": -0.08,
			"jaw_width": -0.06, "eye_size": 0.06, "age": -0.12,
			"lip_fullness": 0.10},
		"hair_style": "long",
	},
	"v7": {  # young and unproven, softer unfinished features
		"genes": {"age": -0.36, "cheek_fullness": 0.12, "build": -0.06,
			"jaw_width": -0.08, "brow_depth": -0.06},
		"hair_style": "short",
	},
	"v8": {  # ancient and formidable, deeply lined, ritual-marked
		"genes": {"age": 0.60, "cheek_fullness": -0.14, "brow_depth": 0.12,
			"freckles": 0.4, "cheekbone_height": 0.10},
	},
}

const IDS := ["v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8"]

static func has(variant_id: String) -> bool:
	return PRESETS.has(variant_id)

## The archetype layer for a variant (genes + optional hair), ready to hand
## to HumanIdentity._apply_layer. Empty for an unknown or blank id.
static func layer(variant_id: String) -> Dictionary:
	return PRESETS.get(variant_id, {})

## A short human label for the creator's gallery tiles.
static func label(variant_id: String) -> String:
	return {
		"v1": "Youth", "v2": "Veteran", "v3": "Ascetic", "v4": "Bulwark",
		"v5": "Worn", "v6": "Radiant", "v7": "Untried", "v8": "Elder",
	}.get(variant_id, variant_id)

## A one-line description for the creator's detail panel, matching the body
## each preset produces.
static func blurb(variant_id: String) -> String:
	return {
		"v1": "Lean and youthful — wiry, sharp-featured, quick on their feet.",
		"v2": "Powerfully built and broad — heavy muscle, scarred and weathered.",
		"v3": "Tall and gaunt — long-limbed, hollow-cheeked, ascetic.",
		"v4": "Compact and dense — low, heavy, immovable.",
		"v5": "Middle-aged and hard-worn — sinewy, grey, unbreakable.",
		"v6": "Striking and unusually beautiful — fine, symmetrical features.",
		"v7": "Young and unproven — softer, unfinished, everything still ahead.",
		"v8": "Ancient and formidable — deeply lined, ritual-marked, undimmed.",
	}.get(variant_id, "")
