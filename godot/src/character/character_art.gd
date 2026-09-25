class_name CharacterArt
## Character-creation concept art slots. Identity-frame art lives in
## res://assets/characters/frames/frame_<id>.jpg and morph-rig art in
## res://assets/characters/mods/morph_<id>.jpg. These are the authored
## portraits shown by VentureWizard and the OmniDex Frames/Mods tabs.
##
## Race art is not wired here yet: res://assets/characters/races/<name>/
## folders are empty slot placeholders until race portraits exist.
## Missing art returns null so callers fall back to their colored tile.

static var _cache: Dictionary = {}

## Identity frame portrait. Returns null when frame_<id>.jpg is absent.
static func frame_icon(frame_id: String, size: int = 64) -> ImageTexture:
	return _art("res://assets/characters/frames/frame_%s.jpg" % frame_id, size)

## Morph rig portrait. Returns null when morph_<id>.jpg is absent.
static func mod_icon(mod_id: String, size: int = 64) -> ImageTexture:
	return _art("res://assets/characters/mods/morph_%s.jpg" % mod_id, size)

## Shared loader with per-size cache. Missing files return null once.
static func _art(path: String, size: int) -> ImageTexture:
	var key := "%s_%d" % [path, size]
	if _cache.has(key):
		return _cache[key]
	if not ResourceLoader.exists(path):
		_cache[key] = null
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		_cache[key] = null
		return null
	var img := tex.get_image()
	if img == null:
		_cache[key] = null
		return null
	if img.get_width() != size or img.get_height() != size:
		img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	var out := ImageTexture.create_from_image(img)
	_cache[key] = out
	return out
