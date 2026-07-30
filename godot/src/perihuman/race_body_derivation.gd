class_name RaceBodyDerivation
## Makes the twenty races read as twenty different SHAPES, not one shape in
## twenty colours.
##
## The archetypes in `human_race_archetypes.gd` carry hand-authored gene
## nudges, but unevenly: Ferox has nine, Aquis and Chimera have one each, and
## seven more have two. A race with one nudge is a default human with a tint,
## which defeats the point — at silhouette distance you cannot tell it from
## the next one.
##
## Rather than invent proportions by hand for twenty species, this derives a
## baseline body from what the lore ALREADY commits to: each race's
## `affinity_stats` (race_lore.gd). A power race is broad and heavy; a speed
## race is light and long-limbed; a resilience race is dense and low; style
## bends toward the elongated and fine-boned; luck toward the wiry and
## asymmetric.
##
## The derived baseline is applied FIRST and the authored nudges land on top,
## because `HumanIdentity._apply_layer` adds rather than overwrites. So Ferox
## keeps every one of its nine authored traits and simply starts from a
## heavier frame; Aquis, which authored almost nothing, gets a real body
## instead of the default one.
##
## Nothing here overrides an artist. It only fills the silence.

## Per affinity stat: the gene deltas one point of that affinity implies.
## Values are deliberately modest — two affinities stack, and the authored
## layer still has to be able to push against them.
const AFFINITY_BODY := {
	"pow": {
		"build": 0.14, "muscle": 0.18, "shoulder_width": 0.13,
		"jaw_width": 0.08, "brow_depth": 0.06, "neck_thickness": 0.10,
	},
	"spd": {
		"build": -0.12, "muscle": -0.04, "leg_length": 0.13,
		"waist": -0.09, "cheek_fullness": -0.07, "height": 0.05,
	},
	"res": {
		"build": 0.16, "muscle": 0.09, "height": -0.08,
		"neck_thickness": 0.12, "jaw_width": 0.06, "waist": 0.07,
	},
	"sty": {
		"height": 0.09, "leg_length": 0.08, "cheekbone_height": 0.12,
		"cheekbone_width": -0.06, "waist": -0.07, "nose_width": -0.05,
	},
	"lck": {
		"build": -0.06, "eye_size": 0.09, "eye_spacing": 0.05,
		"ear_size": 0.07, "chin_protrusion": -0.05,
	},
}

## Genes we are willing to touch. Anything a race authored explicitly is
## skipped, so this never argues with a deliberate choice.
static func derive(canon_name: String) -> Dictionary:
	var lore := RaceLore.get_lore(canon_name)
	var affinities: Array = lore.get("affinity_stats", [])
	if affinities.is_empty():
		return {}

	var authored: Dictionary = HumanRaceArchetypes.RACES.get(canon_name, {}).get("genes", {})
	var out: Dictionary = {}

	# First affinity is the dominant one and counts for more.
	var weight := 1.0
	for stat in affinities:
		var table: Dictionary = AFFINITY_BODY.get(str(stat), {})
		for gene in table:
			# An authored value is a decision; leave it alone entirely.
			if authored.has(gene):
				continue
			out[gene] = float(out.get(gene, 0.0)) + float(table[gene]) * weight
		weight *= 0.65

	return out

## The archetype with its derived baseline folded in, ready to hand to
## HumanIdentity. Colours, materials and hair are passed through untouched.
static func archetype_with_body(canon_name: String) -> Dictionary:
	var base: Dictionary = HumanRaceArchetypes.RACES.get(canon_name, {})
	if base.is_empty():
		return {}
	var derived := derive(canon_name)
	if derived.is_empty():
		return base

	var merged := base.duplicate(true)
	var genes: Dictionary = merged.get("genes", {}).duplicate()
	for gene in derived:
		genes[gene] = float(genes.get(gene, 0.0)) + float(derived[gene])
	merged["genes"] = genes
	return merged

## How much shape a race actually gets, authored plus derived. Useful as a
## sanity readout: if any race is still near zero, it will look generic.
static func shape_budget(canon_name: String) -> float:
	var total := 0.0
	for g in archetype_with_body(canon_name).get("genes", {}).values():
		total += absf(float(g))
	return total
