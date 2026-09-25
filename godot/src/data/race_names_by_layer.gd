class_name RaceNamesByLayer
## Each reality layer frames the same 20 underlying races through its own
## culture. The sprites on disk are keyed by OmniDex id (lumenari, …); this
## table provides the display name a given layer uses for that id.
##
## Extraliminal    = human lineages of the surface world
## Hyperliminal    = cat breeds (the Catsino house skin)
## Superliminal    = canon Periliminal roster (Lumenari, Ashen Choir, …)
## Liminal         = CATSINO alternate roster (Lumari, Igni, …)
## Periliminal     = evolved / culminated forms
## Subliminal      = self- or Hope-designated (no fixed roster)

## Canonical OmniDex ids, order-matched to CanonRaces.RACES.
const OMNIDEX_IDS: Array[String] = [
	"lumenari", "gutterkin", "deepborne", "ashen_choir", "veilstriders",
	"chronarchs", "nullborn", "thorned", "echoes", "hollowed",
	"riftspawn", "mirekin", "sunspun", "coldmarrow", "pulseborn",
	"dreamflesh", "crownless", "rotweavers", "glassborn", "starfall",
]

## Human lineages of the surface world, each marked by a tattoo tradition
## that unconsciously echoes the deeper race it will become in lower layers.
const EXTRALIMINAL_NAMES := {
	"lumenari": "Dayborn", "gutterkin": "Undercity",
	"deepborne": "Trenchwise", "ashen_choir": "Embermarked",
	"veilstriders": "Mistwalkers", "chronarchs": "Dustkeepers",
	"nullborn": "Unmarked", "thorned": "Briarbound",
	"echoes": "Hollowecho", "hollowed": "Glassvein",
	"riftspawn": "Riftsired", "mirekin": "Bogsworn",
	"sunspun": "Goldthread", "coldmarrow": "Frostbound",
	"pulseborn": "Wireheart", "dreamflesh": "Softwake",
	"crownless": "Kinless", "rotweavers": "Graveweaver",
	"glassborn": "Mirrorborn", "starfall": "Skytouched",
}

## Tattoo motifs for the Extraliminal human lineages. These describe the
## surface-world ink that marks each lineage; the art pipeline can use them
## as prompts when generating portraits.
const EXTRALIMINAL_TATTOOS := {
	"lumenari": "sun-ray collar, warm gold ink",
	"gutterkin": "sewer-map sleeve, phosphor green",
	"deepborne": "abyssal wave across the back, bioluminescent blue",
	"ashen_choir": "burn-scar mandala, ember orange",
	"veilstriders": "fog coils around the wrists, silver-grey",
	"chronarchs": "cracked clock gears on the hands, rust brown",
	"nullborn": "blank skin, a single erased line",
	"thorned": "black rose thorns up the spine",
	"echoes": "sound-wave ribs, pale violet",
	"hollowed": "cracked porcelain patchwork, bone white",
	"riftspawn": "jagged lightning fork on the chest, violet-black",
	"mirekin": "moss and rot spirals on the shoulders, swamp green",
	"sunspun": "thread-of-gold circuit on the forearms",
	"coldmarrow": "frost fern on the sternum, ice blue",
	"pulseborn": "heartbeat line with copper wire inlay",
	"dreamflesh": "soft watercolor stains, shifting pastels",
	"crownless": "broken crown at the nape, inked in ash",
	"rotweavers": "decay lace gloves, sepia and black",
	"glassborn": "shattered mirror shard on the palm, chrome ink",
	"starfall": "meteor trails down the side, white ink",
}

## Layer keys are the lowercase names LayerManager uses.
const LAYERS := {
	"extraliminal": EXTRALIMINAL_NAMES,
	"hyperliminal": {
		# Cat-breed ids from RaceDataCharacter, mapped to their canon race.
		"lumenari": "Tabby", "gutterkin": "Siamese", "deepborne": "Maine Coon",
		"ashen_choir": "Persian", "veilstriders": "Bengal", "chronarchs": "Russian Blue",
		"nullborn": "Sphynx", "thorned": "Ragdoll", "echoes": "Scottish Fold",
		"hollowed": "Abyssinian", "riftspawn": "Burmese", "mirekin": "Turkish Angora",
		"sunspun": "Norwegian Forest", "coldmarrow": "Birman", "pulseborn": "Tonkinese",
		"dreamflesh": "Devon Rex", "crownless": "Oriental", "rotweavers": "Somali",
		"glassborn": "Manx", "starfall": "Savannah",
	},
	"superliminal": {
		# Canon Periliminal names from CanonRaces.
		"lumenari": "Lumenari", "gutterkin": "Gutterkin", "deepborne": "Deepborne",
		"ashen_choir": "Ashen Choir", "veilstriders": "Veilstriders", "chronarchs": "Chronarchs",
		"nullborn": "Nullborn", "thorned": "Thorned", "echoes": "Echoes",
		"hollowed": "Hollowed", "riftspawn": "Riftspawn", "mirekin": "Mirekin",
		"sunspun": "Sunspun", "coldmarrow": "Coldmarrow", "pulseborn": "Pulseborn",
		"dreamflesh": "Dreamflesh", "crownless": "Crownless", "rotweavers": "Rotweavers",
		"glassborn": "Glassborn", "starfall": "Starfall",
	},
	"liminal": {
		# CATSINO alternate roster.
		"lumenari": "Lumari", "gutterkin": "Ferox", "deepborne": "Aquis",
		"ashen_choir": "Igni", "veilstriders": "Vex", "chronarchs": "Azhul",
		"nullborn": "Nyx", "thorned": "Sylva", "echoes": "Geara",
		"hollowed": "Etherea", "riftspawn": "Ferros", "mirekin": "Myco",
		"sunspun": "Glyphe", "coldmarrow": "Kryos", "pulseborn": "Volt",
		"dreamflesh": "Chimera", "crownless": "Keth", "rotweavers": "Sanguis",
		"glassborn": "Petra", "starfall": "Astra",
	},
	"periliminal": {
		# Culminated / evolved forms.
		"lumenari": "Lumenari Prime", "gutterkin": "Gutterkin Prime", "deepborne": "Deepborne Prime",
		"ashen_choir": "Ashen Choir Prime", "veilstriders": "Veilstriders Prime", "chronarchs": "Chronarchs Prime",
		"nullborn": "Nullborn Prime", "thorned": "Thorned Prime", "echoes": "Echoes Prime",
		"hollowed": "Hollowed Prime", "riftspawn": "Riftspawn Prime", "mirekin": "Mirekin Prime",
		"sunspun": "Sunspun Prime", "coldmarrow": "Coldmarrow Prime", "pulseborn": "Pulseborn Prime",
		"dreamflesh": "Dreamflesh Prime", "crownless": "Crownless Prime", "rotweavers": "Rotweavers Prime",
		"glassborn": "Glassborn Prime", "starfall": "Starfall Prime",
	},
}

## Display name for a race in a given layer. Returns the OmniDex id itself for
## Subliminal (self/Hope-designated) and for any unknown layer.
static func name_for(layer: String, omnidex_id: String) -> String:
	var lower_layer := layer.to_lower()
	if lower_layer == "subliminal":
		return omnidex_id
	var table: Dictionary = LAYERS.get(lower_layer, {})
	return str(table.get(omnidex_id, omnidex_id))

## Tattoo descriptor for an Extraliminal lineage, or "" for other layers/ids.
static func tattoo_for(omnidex_id: String) -> String:
	return str(EXTRALIMINAL_TATTOOS.get(omnidex_id, ""))

## All 20 names for a layer, in canonical order.
static func names_for(layer: String) -> Array[String]:
	var out: Array[String] = []
	for id in OMNIDEX_IDS:
		out.append(name_for(layer, id))
	return out

## Reverse lookup: which OmniDex id does this layer-specific name map to?
## Returns "" when the name isn't found (e.g. Subliminal freeform names).
static func omnidex_for(layer: String, layer_name: String) -> String:
	var lower_layer := layer.to_lower()
	if lower_layer == "subliminal":
		return ""
	var table: Dictionary = LAYERS.get(lower_layer, {})
	for id in table:
		if str(table[id]) == layer_name:
			return str(id)
	return ""
