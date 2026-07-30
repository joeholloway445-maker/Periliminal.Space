class_name IdentityArt
## Finds the generated illustration for a build — race, race+frame, or
## race+frame+mod — so creator screens and the dex can show art instead of
## a text label.
##
## Generated files live in `assets/entities/` and are named by how they were
## composed (see scripts/prompt_templates.py):
##
##   crownless.png                 race alone
##   crownless_m.png               race, male
##   crownless_f_bastion.png       race, female, wearing the Bastion frame
##   crownless_m_bastion_towering  …and reshaped by the Towering rig
##
## Lookup walks from most specific to least, so a build always resolves to
## the closest art that exists: the exact stack if it was generated, then the
## race+frame, then the sexed race, then the plain race, then nothing. That
## means the creator fills in as generation progresses rather than needing
## the whole 8,000-image matrix before it shows anything.

const DIR := "res://assets/entities/%s.png"

static var _cache: Dictionary = {}

## The best available illustration for this build, or null.
##
## `race_id` may be a gameplay breed id or a canon name — both resolve via
## RaceNames, so callers do not have to know which register they hold.
static func portrait(race_id: String, frame_id: String = "", mod_id: String = "",
		sex: String = "") -> Texture2D:
	var slug := _race_slug(race_id)
	if slug.is_empty():
		return null

	var key := "%s|%s|%s|%s" % [slug, frame_id, mod_id, sex]
	if _cache.has(key):
		return _cache[key]

	var s := "_" + sex.substr(0, 1) if not sex.is_empty() else ""
	var f := "_" + frame_id if not frame_id.is_empty() else ""
	var m := "_" + mod_id if not mod_id.is_empty() else ""

	# Most specific first; each fallback drops one layer.
	for candidate in [
		slug + s + f + m,
		slug + s + f,
		slug + f,
		slug + s,
		slug,
	]:
		var path := DIR % candidate
		if ResourceLoader.exists(path):
			var tex := load(path)
			if tex is Texture2D:
				_cache[key] = tex
				return tex
	_cache[key] = null
	return null

## True if any art exists for this race at all — lets a screen decide
## between showing an image and keeping its text-only layout.
static func has_portrait(race_id: String) -> bool:
	return portrait(race_id) != null

## The Omni Dex id the art is filed under. Accepts a breed id ("tabby"), a
## canon name ("Keth"), or the Omni Dex id itself ("crownless").
static func _race_slug(race_id: String) -> String:
	if race_id.is_empty():
		return ""
	# Already an Omni Dex id?
	if ResourceLoader.exists(DIR % race_id.to_lower()):
		return race_id.to_lower()
	var canon := race_id
	if CanonRaces and CanonRaces.canon_for_id(race_id) != "":
		canon = CanonRaces.canon_for_id(race_id)
	var entry: Dictionary = RaceNames.NAMES.get(canon, {})
	return str(entry.get("true", "")).to_lower()

## Drop-in TextureRect for a build, sized and letterboxed. Returns null when
## no art exists, so a caller can fall back to whatever it drew before.
static func portrait_rect(race_id: String, frame_id: String = "",
		mod_id: String = "", sex: String = "", min_size := Vector2(220, 220)) -> TextureRect:
	var tex := portrait(race_id, frame_id, mod_id, sex)
	if tex == null:
		return null
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = min_size
	return rect
