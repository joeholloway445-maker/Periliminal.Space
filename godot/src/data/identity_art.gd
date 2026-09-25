class_name IdentityArt
## Resolves a character build — race, sex, frame, mod — to its generated
## illustration in assets/entities/.
##
## Self-contained on purpose: the sprites are named by their Omni Dex id
## (crownless, lumenari, …), but the creator selects a race by breed id
## (tabby, …) or canon name (Lumenari, …). This carries the canon → Omni Dex map
## itself, so it works with the CanonRaces this repo already has and needs no
## other data file ported alongside it.
##
## Filenames (see the CATSINO.CASINO prompt pipeline that produced them).
## The original drop was JPEG data mislabeled as .png; the valid files were
## renamed to .jpg so Godot imports them.
##   crownless_m.jpg                 race + sex        (the base body)
##   crownless_m_bastion.jpg         + frame           (gear layer)
##   crownless_m_bastion_towering    + mod             (full stack)
##   crownless_f_swiftburner.jpg     race + sex + mod
##
## Lookup walks most-specific to least, so a build always resolves to the
## closest art that exists — the mod layer is ~95% generated, so a build
## whose exact mod is missing still shows the right race, sex and frame.

const DIR := "res://assets/entities/%s.jpg"
const CASINO_SKIN_DIR := "res://assets/characters/casino_skins/%s.jpg"

## Name aliases that also resolve to the Omni Dex ids the sprites use.
## Includes cat-breed names, the CATSINO/Liminal layer names, and a "Human"
## alias for every race so the Extraliminal framing also works.
const ALIASES := {
	# Cat breeds (Hyperliminal).
	"tabby": "lumenari", "siamese": "gutterkin", "maine_coon": "deepborne",
	"persian": "ashen_choir", "bengal": "veilstriders", "russian_blue": "chronarchs",
	"sphynx": "nullborn", "ragdoll": "thorned", "scottish_fold": "echoes",
	"abyssinian": "hollowed", "burmese": "riftspawn", "turkish_angora": "mirekin",
	"norwegian_forest": "sunspun", "birman": "coldmarrow", "tonkinese": "pulseborn",
	"devon_rex": "dreamflesh", "oriental": "crownless", "somali": "rotweavers",
	"manx": "glassborn", "savannah": "starfall",
	# CATSINO / Liminal layer names.
	"lumari": "lumenari", "ferox": "gutterkin", "aquis": "deepborne",
	"igni": "ashen_choir", "vex": "veilstriders", "azhul": "chronarchs",
	"nyx": "nullborn", "sylva": "thorned", "geara": "echoes",
	"etherea": "hollowed", "ferros": "riftspawn", "myco": "mirekin",
	"glyphe": "sunspun", "kryos": "coldmarrow", "volt": "pulseborn",
	"chimera": "dreamflesh", "keth": "crownless", "sanguis": "rotweavers",
	"petra": "glassborn", "astra": "starfall",
	# Periliminal "Prime" forms.
	"lumenari prime": "lumenari", "gutterkin prime": "gutterkin",
	"deepborne prime": "deepborne", "ashen choir prime": "ashen_choir",
	"veilstriders prime": "veilstriders", "chronarchs prime": "chronarchs",
	"nullborn prime": "nullborn", "thorned prime": "thorned",
	"echoes prime": "echoes", "hollowed prime": "hollowed",
	"riftspawn prime": "riftspawn", "mirekin prime": "mirekin",
	"sunspun prime": "sunspun", "coldmarrow prime": "coldmarrow",
	"pulseborn prime": "pulseborn", "dreamflesh prime": "dreamflesh",
	"crownless prime": "crownless", "rotweavers prime": "rotweavers",
	"glassborn prime": "glassborn", "starfall prime": "starfall",
}

static var _cache: Dictionary = {}

## Best available illustration for the build, or null. `race_id` may be a
## breed id, a canon name, or the Omni Dex id itself. `sex` is "male"/"female"
## (or "m"/"f"); anything else means "no preference", trying male then plain.
static func portrait(race_id: String, sex: String = "", frame_id: String = "",
		mod_id: String = "") -> Texture2D:
	var slug := _omnidex_id(race_id)
	if slug.is_empty():
		return null

	var key := "%s|%s|%s|%s" % [slug, sex, frame_id, mod_id]
	if _cache.has(key):
		return _cache[key]

	var sexes: Array = []
	var sl := sex.substr(0, 1).to_lower()
	if sl == "m" or sl == "f":
		sexes = [sl, "", ("f" if sl == "m" else "m")]
	elif not frame_id.is_empty() or not mod_id.is_empty():
		# Frame/mod art is always sex-prefixed in the drop (race_m_frame.jpg).
		# A sexless-first walk would fall straight through to the base
		# portrait and make every frame/mod pick look identical — so prefer
		# the sexed layers when a build layer is requested.
		sexes = ["m", "f", ""]
	else:
		sexes = ["", "m", "f"]

	for s in sexes:
		var suffix := "_" + str(s) if str(s) != "" else ""
		var f := "_" + frame_id if not frame_id.is_empty() else ""
		var m := "_" + mod_id if not mod_id.is_empty() else ""
		# Most-specific to least, with the MOD layer ranked above the FRAME
		# layer: every race ships <slug>_<sex>_<mod>.jpg, but no frame+mod
		# composite files exist — so the old order (frame before mod) let the
		# always-present frame art shadow the mod art and scrolling mods
		# looked identical. Mod body plans change more than frames, so when a
		# mod is requested it wins unless a true full-stack file exists.
		var candidates: Array[String] = []
		if not f.is_empty() and not m.is_empty():
			candidates.append(slug + suffix + f + m)
		if not m.is_empty():
			candidates.append(slug + suffix + m)
		if not f.is_empty():
			candidates.append(slug + suffix + f)
		candidates.append(slug + suffix)
		for candidate: String in candidates:
			var path: String = DIR % candidate
			if ResourceLoader.exists(path):
				var tex := load(path)
				if tex is Texture2D:
					_cache[key] = tex
					return tex
	_cache[key] = null
	return null

## Layer-aware portrait. Rules:
##   Extraliminal           -> human core sprite; cat-skin only with permission
##   Hyperliminal PvE       -> casino cat-skin
##   Hyperliminal PvP       -> fighter core sprite
##   Liminal/Supraliminal/Periliminal -> core reality sprites
##   Subliminal             -> uses `subliminal_prefers_cat_skin` if available
static func portrait_for_layer(race_id: String, layer: String, sex: String = "",
		frame_id: String = "", mod_id: String = "", is_pvp: bool = false,
		cat_skin_permission: bool = false, subliminal_cat_skin: bool = false) -> Texture2D:
	var lower_layer := layer.to_lower()
	match lower_layer:
		"hyperliminal":
			if not is_pvp:
				var cat := _casino_skin(race_id, sex, frame_id, mod_id)
				if cat != null:
					return cat
		"extraliminal":
			if cat_skin_permission:
				var cat := _casino_skin(race_id, sex, frame_id, mod_id)
				if cat != null:
					return cat
		"subliminal":
			if subliminal_cat_skin:
				var cat := _casino_skin(race_id, sex, frame_id, mod_id)
				if cat != null:
					return cat
	# Default: deeper layers, Hyperliminal PvP, and unskinned fallbacks use
	# the core reality sprites.
	return portrait(race_id, sex, frame_id, mod_id)


## Best-effort cat-skin portrait. Returns null if the file does not exist.
static func _casino_skin(race_id: String, sex: String, frame_id: String,
		mod_id: String) -> Texture2D:
	var slug := _omnidex_id(race_id)
	if slug.is_empty():
		return null
	var sl := sex.substr(0, 1).to_lower()
	if sl != "m" and sl != "f":
		sl = "m"
	var suffix := "_" + sl
	var f := "_" + frame_id if not frame_id.is_empty() else ""
	var m := "_" + mod_id if not mod_id.is_empty() else ""
	for candidate: String in [slug + suffix + f + m, slug + suffix + f,
			slug + suffix + m, slug + suffix]:
		var path: String = CASINO_SKIN_DIR % candidate
		if ResourceLoader.exists(path):
			var tex := load(path)
			if tex is Texture2D:
				return tex
	return null

static func has_portrait(race_id: String) -> bool:
	return portrait(race_id) != null

static func has_casino_skin(race_id: String, sex: String = "") -> bool:
	return _casino_skin(race_id, sex, "", "") != null

## Drop-in TextureRect for a build, or null when no art exists so a caller
## can keep whatever it drew before.
static func portrait_rect(race_id: String, sex: String = "", frame_id: String = "",
		mod_id: String = "", min_size := Vector2(240, 240)) -> TextureRect:
	var tex := portrait(race_id, sex, frame_id, mod_id)
	if tex == null:
		return null
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = min_size
	return rect

## Resolve any race id form to the Omni Dex slug the sprites use.
## Accepts OmniDex id, canon name, breed name, CATSINO name, or Human.
static func _omnidex_id(race_id: String) -> String:
	if race_id.is_empty():
		return ""
	var key := race_id.to_lower()
	# Already an Omni Dex id? (a sprite file exists for it directly)
	if ResourceLoader.exists(DIR % key):
		return key
	# Any alias (breed, CATSINO, Prime form, etc.)
	if ALIASES.has(key):
		return str(ALIASES[key])
	# Human is a valid Extraliminal alias for every race.
	if key == "human":
		return "lumenari"
	# Canon name -> OmniDex via lowercased/underscored transform.
	var canon := key.replace(" ", "_")
	if ResourceLoader.exists(DIR % canon):
		return canon
	# Breed id -> canon -> OmniDex.
	if CanonRaces:
		var canon_name := CanonRaces.canon_for_id(race_id)
		canon = canon_name.to_lower().replace(" ", "_")
		if ResourceLoader.exists(DIR % canon):
			return canon
	return ""
