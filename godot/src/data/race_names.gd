class_name RaceNames
## One substance, many names — what a race is CALLED depends on which depth
## you are standing in.
##
## This is the answer to the two-roster split (docs/OMNIDEX.md): the Omni Dex
## roster and the canon roster were never two sets of races, they are two
## registers of naming for the same twenty substances. You are Crownless —
## that is what you are, and what almost everyone calls you. The Metroplex
## files you as a Terran on a work visa because its forms have no box for
## Crownless. The Liminal, older and set in its ways, still says Keth.
##
## It fits what the lens already does. A being's appearance is a function of
## who is looking; this makes its NAME a function of where you are looking
## from. Nobody is lying — a Terran and a Keth are the same person, filed by
## two bureaucracies that disagree about what matters.
##
## Registers:
##   civil       Hyperliminal / Supraliminal — casino floor and Metroplex
##               paperwork. Mundane, administrative, deliberately boring.
##   true        THE PRIMARY NAME. The Omni Dex register — ability-led, what
##               a thing demonstrably is. This is what players call each
##               other and what the UI shows by default.
##   canon       The old working roster (Keth, Lumari, ...), kept because it
##               is the id every body, gene and material keys on, and because
##               it still reads as the Liminal's own older vocabulary.
##
## `canon` is the id everything else keys on (bodies, genes, materials). The
## other two are display strings only, so renaming is free and no gameplay
## data moves.

## Omni Dex names are the default everywhere; the civil register is the
## paperwork name the mundane layers use, and the canon register survives as
## the Liminal's older vocabulary.
const LAYER_REGISTER := {
	"hyperliminal": "civil",
	"supraliminal": "civil",
	"liminal": "canon",
	"subliminal": "true",
	"extraliminal": "true",
	"periliminal": "true",
}

## With no layer context, show the Omni Dex name.
const DEFAULT_REGISTER := "true"

## canon id -> {civil, true}. `true` names come from the Omni Dex roster;
## pairings marked PROVISIONAL below are the ones docs/OMNIDEX_MAPPING.md
## could not settle on concept alone, and are safe to reassign — they are
## names, not stat merges, so swapping one costs nothing.
const NAMES := {
	# --- settled: the concept is the same thing named twice ---
	"Keth":    {"civil": "Terran",    "true": "crownless"},
	"Lumari":  {"civil": "Solaran",   "true": "lumenari"},
	"Vex":     {"civil": "Transient", "true": "veilstriders"},
	"Kryos":   {"civil": "Borean",    "true": "coldmarrow"},
	"Volt":    {"civil": "Dynamo",    "true": "pulseborn"},
	"Sylva":   {"civil": "Arborist",  "true": "thorned"},
	"Myco":    {"civil": "Cultivar",  "true": "mirekin"},
	"Chimera": {"civil": "Composite", "true": "dreamflesh"},
	"Astra":   {"civil": "Orbital",   "true": "starfall"},
	"Aquis":   {"civil": "Littoral",  "true": "deepborne"},
	# --- PROVISIONAL: defensible, not settled ---
	"Geara":   {"civil": "Technician", "true": "echoes"},
	"Azhul":   {"civil": "Augur",      "true": "chronarchs"},
	"Ferox":   {"civil": "Rangeborn",  "true": "gutterkin"},
	"Petra":   {"civil": "Quarryman",  "true": "glassborn"},
	"Sanguis": {"civil": "Hemate",     "true": "rotweavers"},
	"Igni":    {"civil": "Calderan",   "true": "ashen_choir"},
	"Nyx":     {"civil": "Nocturne",   "true": "nullborn"},
	"Etherea": {"civil": "Revenant",   "true": "hollowed"},
	"Ferros":  {"civil": "Ironside",   "true": "riftspawn"},
	"Glyphe":  {"civil": "Scrivener",  "true": "sunspun"},
}

## The name this race wears in `layer_id`. Falls back to the canon name, so
## an unmapped race or an unknown layer degrades to something correct.
static func display(canon_id: String, layer_id: String = "") -> String:
	var entry: Dictionary = NAMES.get(canon_id, {})
	if entry.is_empty():
		return canon_id
	var register := str(LAYER_REGISTER.get(layer_id, DEFAULT_REGISTER))
	if register == "canon":
		return canon_id
	var name := str(entry.get(register, ""))
	if name.is_empty():
		return canon_id
	# Omni Dex ids are snake_case; present them as words.
	return name.replace("_", " ").capitalize() if register == "true" else name

## The name for whatever layer the player is standing in right now.
static func current(canon_id: String) -> String:
	var layer := ""
	if LayerManager:
		layer = str(LayerManager.current_layer_id)
	return display(canon_id, layer)

## Every name a race answers to, for the dex and the profile screen.
static func all_names(canon_id: String) -> Dictionary:
	var entry: Dictionary = NAMES.get(canon_id, {})
	return {
		"civil": str(entry.get("civil", canon_id)),
		"canon": canon_id,
		"true": display(canon_id, "periliminal"),
	}

## Reverse lookup: any register's name back to the canon id, so search and
## chat can accept whichever name a player happens to know.
static func canon_for(any_name: String) -> String:
	var needle := any_name.strip_edges().to_lower().replace(" ", "_")
	for canon in NAMES:
		if str(canon).to_lower() == needle:
			return str(canon)
		var e: Dictionary = NAMES[canon]
		if str(e.get("civil", "")).to_lower() == needle:
			return str(canon)
		if str(e.get("true", "")).to_lower() == needle:
			return str(canon)
	return ""

## The Omni Dex entry a race resolves to, so its passive/drawback/faction can
## be read without duplicating that data here.
static func omni_dex_entry(canon_id: String) -> Dictionary:
	var true_id := str(NAMES.get(canon_id, {}).get("true", ""))
	if true_id.is_empty():
		return {}
	return OmniDex.race(true_id)
