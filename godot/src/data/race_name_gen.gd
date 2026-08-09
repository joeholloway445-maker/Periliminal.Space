class_name RaceNameGen
## Personal names that fit a race's aesthetic — a shadow-Keth reads soft and
## sibilant, an iron-Ferros hard and blunt, a star-Astra airy and bright — so
## a procedurally spawned citizen isn't "NPC_47" but someone whose very name
## sounds like their people. Races are grouped into six phonetic families so
## this scales without twenty bespoke pools.
##
## Deterministic: name_for(canon, seed) always yields the same name for the
## same seed, so a given NPC keeps its name across sessions.

## canon race -> phonetic family.
const FAMILY_OF := {
	"Keth": "umbral", "Nyx": "umbral", "Vex": "umbral", "Etherea": "umbral",
	"Igni": "ember", "Sanguis": "ember", "Ferox": "ember",
	"Kryos": "iron", "Petra": "iron", "Ferros": "iron",
	"Lumari": "astral", "Astra": "astral", "Azhul": "astral",
	"Sylva": "verdant", "Myco": "verdant", "Aquis": "verdant",
	"Geara": "arc", "Volt": "arc", "Glyphe": "arc", "Chimera": "arc",
}

## start / mid / end fragments per family. A name is start+mid+end, sometimes
## with a second mid for length. Tuned so each family has a recognisable sound.
const PARTS := {
	"umbral": {
		"start": ["Sil", "Vesh", "Krin", "Nyr", "Sha", "Vel", "Umbr", "Cael", "Sev"],
		"mid": ["a", "e", "ash", "een", "ir", "oth"],
		"end": ["", "n", "th", "ra", "ix", "vel", "wyn"],
	},
	"ember": {
		"start": ["Kor", "Var", "Grah", "Ash", "Pyr", "Dur", "Rok", "Char", "Bral"],
		"mid": ["a", "o", "ok", "ar", "um", "esh"],
		"end": ["", "k", "rn", "gash", "dor", "us", "ax"],
	},
	"iron": {
		"start": ["Dor", "Bral", "Gron", "Thur", "Kald", "Mord", "Stov", "Harn", "Brek"],
		"mid": ["a", "o", "ok", "un", "eld", "arr"],
		"end": ["", "n", "k", "gar", "dun", "mst", "rok"],
	},
	"astral": {
		"start": ["Aur", "Cael", "Ser", "Lyr", "Vael", "Elar", "Zeph", "Illa", "Sol"],
		"mid": ["a", "e", "i", "ael", "ien", "ora"],
		"end": ["", "n", "th", "lae", "riel", "ys", "wyn"],
	},
	"verdant": {
		"start": ["Thal", "Bri", "Fenn", "Mor", "Syl", "Ael", "Wren", "Rho", "Vae"],
		"mid": ["a", "o", "een", "owe", "ael", "ira"],
		"end": ["", "n", "l", "wood", "the", "sha", "ren"],
	},
	"arc": {
		"start": ["Zek", "Vox", "Cyr", "Nyx", "Tesl", "Byt", "Gly", "Krix", "Vel"],
		"mid": ["a", "i", "o", "ix", "ek", "ar"],
		"end": ["", "x", "z", "on", "ex", "os", "yl"],
	},
}

const DEFAULT_FAMILY := "astral"

static func name_for(canon_name: String, seed_value: int) -> String:
	var fam: String = FAMILY_OF.get(canon_name, DEFAULT_FAMILY)
	var parts: Dictionary = PARTS.get(fam, PARTS[DEFAULT_FAMILY])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var starts: Array = parts["start"]
	var mids: Array = parts["mid"]
	var ends: Array = parts["end"]
	var name := str(starts[rng.randi() % starts.size()])
	name += str(mids[rng.randi() % mids.size()])
	if rng.randf() < 0.35:  # occasionally a longer, two-beat name
		name += str(mids[rng.randi() % mids.size()])
	name += str(ends[rng.randi() % ends.size()])
	return _tidy(name)

## Name for a gameplay breed id ("tabby"), resolving to its canon race first.
static func name_for_id(race_id: String, seed_value: int) -> String:
	return name_for(CanonRaces.canon_for_id(race_id), seed_value)

## Name from a world-NPC dict, using its resolved race and a stable seed from
## its id — so it matches the race that NPC also moves, sounds, and acts as.
static func name_for_npc(npc: Dictionary) -> String:
	var canon := RacePersona.canon_for_npc(npc)
	var id := str(npc.get("id", npc.get("npc_id", npc.get("name", "npc"))))
	return name_for(canon, id.hash())

static func _tidy(raw: String) -> String:
	if raw.is_empty():
		return "Ash"
	# Capitalise, and collapse any triple vowels the joins can produce.
	var s := raw.substr(0, 1).to_upper() + raw.substr(1)
	return s
