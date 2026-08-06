class_name VentureWizard
extends Control
## "Start New Venture" — old-school Mortal Kombat select-screen energy:
## a scrollable roster of portrait tiles, arrow keys or clicks to move the
## cursor, a big VS-style panel on the right showing whoever's highlighted,
## ENTER/click to lock it in and advance to the next roster (Race ->
## Faction -> Frame -> Mod -> name your fighter -> FIGHT, into the
## Liminal).

signal venture_started()

const STEPS := ["race", "look", "faction", "frame", "mod", "name"]
const FACTIONS := ["Factionless", "SovereignCrown", "WildlandsAscendant", "VeiledCurrent"]
const FACTION_COLORS := {
	"Factionless": Color(0.6, 0.6, 0.65), "SovereignCrown": Color(0.85, 0.7, 0.25),
	"WildlandsAscendant": Color(0.35, 0.75, 0.35), "VeiledCurrent": Color(0.4, 0.55, 0.9),
}
const FACTION_LORE := {
	"Factionless": "No banner, no leash. You start in Arlington and answer to no crown.",
	"SovereignCrown": "Dallas's iron court. Order, hierarchy, and a throne that remembers everyone who knelt.",
	"WildlandsAscendant": "Denton's wild ascendance. Growth, transformation, no ceiling on what you become.",
	"VeiledCurrent": "Fort Worth's undertow. Secrets, phase, the space between one moment and the next.",
}

var _step := 0
var _cursor := 0
var _picked: Dictionary = {}

var _title: Label
var _roster_row: HBoxContainer
var _roster_scroll: ScrollContainer
var _portrait: ColorRect
## Generated illustration layered over the colour block. The ColorRect stays
## as the backing plate, so a race with no art yet still reads as its colour
## instead of leaving a hole.
var _portrait_art: TextureRect
var _portrait_label: Label
var _detail: RichTextLabel
var _name_edit: LineEdit
var _confirm_btn: Button
var _back_btn: Button
var _tiles: Array[Button] = []
var _entries: Array = []

func _ready() -> void:
	MusicManager.play_context("theme")
	_build_ui()
	_render_step()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	root.add_child(_title)

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 20)
	root.add_child(mid)

	# ---- big VS-style portrait panel ----
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(360, 0)
	mid.add_child(left)
	_portrait = ColorRect.new()
	_portrait.custom_minimum_size = Vector2(340, 340)
	left.add_child(_portrait)
	_portrait_art = TextureRect.new()
	_portrait_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_art.visible = false
	_portrait.add_child(_portrait_art)
	_portrait_label = Label.new()
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", 26)
	left.add_child(_portrait_label)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.custom_minimum_size = Vector2(340, 200)
	left.add_child(_detail)

	# ---- roster strip ----
	_roster_scroll = ScrollContainer.new()
	_roster_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(_roster_scroll)
	_roster_row = HBoxContainer.new()
	_roster_row.add_theme_constant_override("separation", 10)
	_roster_scroll.add_child(_roster_row)

	# ---- bottom controls ----
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 16)
	root.add_child(controls)

	_back_btn = Button.new()
	_back_btn.text = "◀ Back"
	_back_btn.pressed.connect(_go_back)
	controls.add_child(_back_btn)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Name your fighter"
	_name_edit.custom_minimum_size = Vector2(260, 40)
	_name_edit.visible = false
	controls.add_child(_name_edit)

	_confirm_btn = Button.new()
	_confirm_btn.text = "SELECT ▶"
	_confirm_btn.custom_minimum_size = Vector2(160, 44)
	_confirm_btn.pressed.connect(_confirm_step)
	controls.add_child(_confirm_btn)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	root.add_child(spacer)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT, KEY_A:
				_move_cursor(-1)
			KEY_RIGHT, KEY_D:
				_move_cursor(1)
			KEY_ENTER, KEY_SPACE:
				if not _name_edit.visible:
					_confirm_step()

func _move_cursor(dir: int) -> void:
	if _entries.is_empty():
		return
	_cursor = wrapi(_cursor + dir, 0, _entries.size())
	_update_portrait()
	for i in _tiles.size():
		_tiles[i].modulate = Color.WHITE if i == _cursor else Color(0.6, 0.6, 0.65)

# ---------------------------------------------------------------- steps

func _render_step() -> void:
	var step := STEPS[_step]
	_back_btn.visible = _step > 0
	_name_edit.visible = step == "name"
	_confirm_btn.text = "FIGHT ⚔️" if step == "name" else "SELECT ▶"
	_roster_scroll.visible = step != "name"
	_portrait.visible = true

	match step:
		"race":
			_title.text = "CHOOSE YOUR RACE"
			_entries = RaceDataCharacter.RACES.map(func(r): return {
				"id": r.id, "name": OmniDexRegistry.race_display_name(str(r.id)), "color": r.primary_color,
				"blurb": r.lore, "stats": "POW %d  RES %d  SPD %d  LCK %d  STY %d" % [r.pow, r.res, r.spd, r.lck, r.sty],
			})
		"look":
			_title.text = "CHOOSE YOUR STARTING LOOK"
			# Eight distinct individuals of the chosen race. The pick reshapes
			# the PeriHuman rig (build/age/features via VariantPresets), and its
			# portrait — when generated — previews that body. Every race offers
			# all eight even before its full gallery is generated, because the
			# variant drives the actual skeleton, not just the picture.
			_entries = VariantPresets.IDS.map(func(v): return {
				"id": v, "name": VariantPresets.label(v), "color": _hash_color(v),
				"blurb": VariantPresets.blurb(v), "stats": "",
			})
		"faction":
			_title.text = "PLEDGE YOUR BANNER"
			_entries = FACTIONS.map(func(f): return {
				"id": f, "name": f, "color": FACTION_COLORS[f], "blurb": FACTION_LORE[f], "stats": "",
			})
		"frame":
			_title.text = "CHOOSE YOUR FRAME"
			# Selection stores Hyperliminal sensorium ids (FrameModData).
			# Display names resolve through OmniDexRegistry (exactly 20).
			_entries = FrameModData.FRAMES.map(func(f): return {
				"id": f.id,
				"name": OmniDexRegistry.frame_display_name(str(f.id)),
				"color": _hash_color(f.id),
				"blurb": f.lore, "stats": f.desc,
			})
		"mod":
			_title.text = "CHOOSE YOUR MORPH RIG"
			_entries = MorphRigData.RIGS.map(func(r): return {
				"id": r.id, "name": OmniDexRegistry.mod_display_name(str(r.id)), "color": _hash_color(r.id),
				"blurb": r.desc, "stats": "%s / %s" % [r.bonus, r.drawback],
			})
		"name":
			_title.text = "NAME YOUR FIGHTER"
			_render_final_preview()
			return
	_cursor = 0
	_build_roster()
	_update_portrait()

func _hash_color(seed_str: String) -> Color:
	var h := hash(seed_str)
	return Color.from_hsv(float(h % 360) / 360.0, 0.55, 0.85)

func _build_roster() -> void:
	for c in _roster_row.get_children():
		c.queue_free()
	_tiles.clear()
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(96, 96)
		tile.text = str(e.name)
		tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var mat := StyleBoxFlat.new()
		mat.bg_color = e.color
		mat.set_corner_radius_all(6)
		tile.add_theme_stylebox_override("normal", mat)
		tile.pressed.connect(func():
			_cursor = i
			_update_portrait()
			for t in _tiles: t.modulate = Color(0.6, 0.6, 0.65)
			tile.modulate = Color.WHITE)
		_roster_row.add_child(tile)
		_tiles.append(tile)
	if not _tiles.is_empty():
		_tiles[0].modulate = Color.WHITE

func _update_portrait() -> void:
	if _entries.is_empty():
		return
	var e: Dictionary = _entries[_cursor]
	_portrait.color = e.color
	if STEPS[_step] == "look":
		# Preview this variant on the race already chosen, so the panel shows
		# the individual the pick produces (or the plain race art as fallback).
		_show_variant_art(str(_picked.get("race", "")), str(e.get("id", "")))
	else:
		_show_art(str(e.get("id", "")))
	_portrait_label.text = str(e.name).to_upper()
	_detail.text = "%s\n\n[color=#ffd88a]%s[/color]" % [e.get("blurb", ""), e.get("stats", "")]

func _render_final_preview() -> void:
	var stats := CharacterCreatorLogic.build_starting_stats(_picked.race, _picked.faction, _picked.frame)
	var sensorium := FrameSensorium.of(_picked.frame)
	_portrait.color = RaceDataCharacter.get_race(_picked.race).get("primary_color", Color.WHITE)
	# Final preview knows the whole build, so it can ask for the exact stack.
	_show_art(str(_picked.race), str(_picked.get("frame", "")), str(_picked.get("mod", "")))
	_portrait_label.text = str(_picked.get("race_name", "?")).to_upper()
	var look := str(_picked.get("variant", ""))
	var look_line := " (%s)" % VariantPresets.label(look) if not look.is_empty() else ""
	_detail.text = "%s%s | %s | %s\n\nPOW %d  RES %d  SPD %d  LCK %d  STY %d\n\n%s" % [
		_picked.get("race_name", "?"), look_line, _picked.faction, _picked.get("frame_name", "?"),
		stats.pow, stats.res, stats.spd, stats.lck, stats.sty, sensorium.desc,
	]

func _confirm_step() -> void:
	var step := STEPS[_step]
	if step == "name":
		var cat_name := _name_edit.text.strip_edges()
		if not CharacterCreatorLogic.validate_name(cat_name):
			_detail.text += "\n\n[color=#ff6666]⚠️ Enter a valid name (2-20 letters/numbers, no spaces).[/color]"
			return
		CharacterCreatorLogic.apply_creation(_picked.race, _picked.faction, _picked.frame, cat_name)
		PlayerProfile.set_mod(_picked.mod)
		PlayerProfile.set_variant(str(_picked.get("variant", "")))
		venture_started.emit()
		# A new venture starts in the wilds, not the safety of the
		# Subliminal — thrown straight into the Liminal.
		LayerManager.transition_to("liminal", true)
		return

	if _entries.is_empty():
		return
	var e: Dictionary = _entries[_cursor]
	match step:
		"race":
			_picked["race"] = e.id
			_picked["race_name"] = e.name
		"look":
			_picked["variant"] = e.id
		"faction":
			_picked["faction"] = e.id
		"frame":
			_picked["frame"] = e.id
			_picked["frame_name"] = e.name
		"mod":
			_picked["mod"] = e.id
	_step += 1
	_render_step()

func _go_back() -> void:
	if _step <= 0:
		return
	_step -= 1
	_render_step()

## Layers generated art over the colour plate when any exists for this
## build. Anything without art (frames and mods chosen before a race, say)
## simply keeps the colour block.
func _show_art(race_id: String, frame_id: String = "", mod_id: String = "") -> void:
	if _portrait_art == null:
		return
	var tex := IdentityArt.portrait(race_id, frame_id, mod_id)
	_portrait_art.texture = tex
	_portrait_art.visible = tex != null
	# Label is hard to read over a busy illustration; dim the plate instead
	# of hiding the name.
	_portrait_label.modulate = Color(1, 1, 1, 0.85) if tex != null else Color.WHITE

## Same as _show_art but for a specific starting-look variant, falling back to
## the plain race illustration when that variant was not generated.
func _show_variant_art(race_id: String, variant_id: String) -> void:
	if _portrait_art == null:
		return
	var tex := IdentityArt.variant_portrait(race_id, variant_id)
	_portrait_art.texture = tex
	_portrait_art.visible = tex != null
	_portrait_label.modulate = Color(1, 1, 1, 0.85) if tex != null else Color.WHITE
