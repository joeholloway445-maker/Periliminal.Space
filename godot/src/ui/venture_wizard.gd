class_name VentureWizard
extends Control
## "Start New Venture" — old-school Mortal Kombat select-screen energy:
## a scrollable roster of portrait tiles, arrow keys or clicks to move the
## cursor, a big VS-style panel on the right showing whoever's highlighted,
## ENTER/click to lock it in and advance to the next roster (Race ->
## Faction -> Frame -> Mod -> name your fighter -> FIGHT, into the
## Liminal).

signal venture_started()

## Body sex lives on the RACE screen as a toggle (BODY: ♂ MALE / ♀ FEMALE) —
## one screen, one character. The remaining steps pick frame, mod, sliders, name.
const STEPS := ["race", "frame", "mod", "customize", "name"]

## Appearance slider ramp stops (continuous color ramps for the customize step).
const SKIN_RAMP: Array[Color] = [Color("#f6d7b0"), Color("#eec39a"), Color("#e0ac69"), Color("#c68642"), Color("#a05c2e"), Color("#7a4223")]
const HAIR_RAMP: Array[Color] = [Color("#0b0908"), Color("#2b1d12"), Color("#4a2c14"), Color("#6b4423"), Color("#9a6b3a"), Color("#c9a066"), Color("#e8d5b0")]
const EYE_RAMP: Array[Color] = [Color("#3a2a1a"), Color("#5a3a1a"), Color("#8a6a3a"), Color("#4a7a4a"), Color("#4a6a9a"), Color("#6a4a8a"), Color("#9a9aa0")]
const OUTFIT_RAMP: Array[Color] = [Color("#2a2e3a"), Color("#3a4a6a"), Color("#5a4a6a"), Color("#6a3a4a"), Color("#4a6a4a"), Color("#6a5a3a")]

var _step := 0
var _cursor := 0
var _picked: Dictionary = {}
var _appearance: Dictionary = {
	"height": 1.0, "build": 1.0,
	"skin": "#d9a066", "hair": "#2b1d12", "eye": "#6b4c2a",
	"outfit": "#3a4a6a", "glow": 0.0,
}
var _customize_panel: VBoxContainer = null

var _title: Label
var _roster_row: HBoxContainer
var _roster_scroll: ScrollContainer
var _preview_viewport: SubViewportContainer
var _preview_subviewport: SubViewport
var _preview_instance: Node3D
var _portrait_image: TextureRect  # authored identity portrait overlay
var _portrait: ColorRect  # fallback when viewport isn't ready
var _portrait_label: Label
var _detail: RichTextLabel
var _name_edit: LineEdit
var _confirm_btn: Button
var _back_btn: Button
var _tiles: Array[Button] = []
var _entries: Array = []
var _sex_row: HBoxContainer
var _sex_buttons: Array[Button] = []

func _ready() -> void:
	var MusicManager = AutoloadGate.get_node("MusicManager")
	MusicManager.play_context("theme")
	_build_ui()
	_render_step()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Responsive: on a phone window the fixed desktop sizes would shrink to
	# thumb-nails and clip, so scale the preview up and stack vertically.
	var phone: bool = PhoneUI != null and PhoneUI.is_phone()
	var bs: float = PhoneUI.px(1.0) if (phone and PhoneUI != null) else 1.0
	var vw: float = get_viewport_rect().size.x
	var preview_sz: float = (minf(vw - 40.0, 520.0) if phone else 340.0)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", int(32 * bs))
	root.add_child(_title)

	# Body sex toggle — on the race screen, not a separate step.
	_sex_row = HBoxContainer.new()
	_sex_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_sex_row.add_theme_constant_override("separation", 8)
	root.add_child(_sex_row)
	var sex_lbl := Label.new()
	sex_lbl.text = "BODY:"
	sex_lbl.add_theme_font_size_override("font_size", 16)
	_sex_row.add_child(sex_lbl)
	for sid: String in ["m", "f"]:
		var sex_btn := Button.new()
		sex_btn.text = "♂ MALE" if sid == "m" else "♀ FEMALE"
		sex_btn.custom_minimum_size = Vector2(150 * bs, 40 * bs)
		sex_btn.pressed.connect(func():
			_picked["sex"] = sid
			_sync_sex_row()
			_update_portrait())
		_sex_row.add_child(sex_btn)
		_sex_buttons.append(sex_btn)

	var mid: BoxContainer = (VBoxContainer.new() if phone else HBoxContainer.new())
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 20)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(mid)

	# ---- big preview panel (the 3D body IS the preview) ----
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2((preview_sz if phone else 360), 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL if phone else Control.SIZE_SHRINK_BEGIN
	if phone:
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(left)

	var preview_wrapper := Control.new()
	preview_wrapper.custom_minimum_size = Vector2(preview_sz, preview_sz)
	preview_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(preview_wrapper)

	_preview_viewport = SubViewportContainer.new()
	_preview_viewport.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_wrapper.add_child(_preview_viewport)

	var viewport_px := int(clampi(int(preview_sz), 160, 1024))
	_preview_subviewport = SubViewport.new()
	_preview_subviewport.size = Vector2(viewport_px, viewport_px)
	_preview_subviewport.transparent_bg = true
	_preview_subviewport.msaa_3d = Viewport.MSAA_2X
	_preview_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview_viewport.add_child(_preview_subviewport)

	var preview_scene := load("res://scenes/character/character_preview.tscn")
	_preview_instance = preview_scene.instantiate()
	_preview_subviewport.add_child(_preview_instance)

	# Kept but never overlays the body anymore (see _update_portrait).
	_portrait_image = TextureRect.new()
	_portrait_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_image.visible = false
	preview_wrapper.add_child(_portrait_image)

	_portrait = ColorRect.new()
	_portrait.custom_minimum_size = Vector2(preview_sz, 24)
	_portrait.size = Vector2(preview_sz, 24)
	_portrait.visible = true  # accent bar below the 3D viewport
	left.add_child(_portrait)

	_portrait_label = Label.new()
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", int(26 * bs))
	left.add_child(_portrait_label)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.custom_minimum_size = Vector2(preview_sz, (140 if phone else 200))
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL if phone else Control.SIZE_SHRINK_BEGIN
	left.add_child(_detail)

	# ---- roster strip ----
	_roster_scroll = ScrollContainer.new()
	_roster_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(_roster_scroll)
	_roster_row = HBoxContainer.new()
	_roster_row.add_theme_constant_override("separation", 10)
	_roster_scroll.add_child(_roster_row)

	# Customize step panel (sliders) — replaces the roster strip.
	_customize_panel = _build_customize_panel()
	_customize_panel.visible = false
	mid.add_child(_customize_panel)

	# ---- bottom controls ----
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 16)
	root.add_child(controls)

	_back_btn = Button.new()
	_back_btn.text = "◀ Back"
	_back_btn.custom_minimum_size = Vector2(120 * bs, 44 * bs)
	_back_btn.pressed.connect(_go_back)
	controls.add_child(_back_btn)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Name your fighter"
	_name_edit.custom_minimum_size = Vector2(260 * bs, 44 * bs)
	_name_edit.visible = false
	_name_edit.text_submitted.connect(func(_text): _confirm_step())
	controls.add_child(_name_edit)

	_confirm_btn = Button.new()
	_confirm_btn.text = "SELECT ▶"
	_confirm_btn.custom_minimum_size = Vector2(160 * bs, 44 * bs)
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
	var step: String = STEPS[_step]
	_back_btn.visible = true
	_name_edit.visible = step == "name"
	_confirm_btn.text = "FIGHT ⚔️" if step == "name" else "SELECT ▶"
	_roster_scroll.visible = step in ["race", "frame", "mod"]
	_customize_panel.visible = step == "customize"
	_sex_row.visible = step == "race"
	_sync_sex_row()
	_portrait.visible = true

	match step:
		"race":
			_title.text = "CHOOSE YOUR RACE"
			_entries = RaceDataCharacter.RACES.map(func(r): return {
				"id": r.id, "name": OmniDexRegistry.race_display_name(str(r.id)), "color": r.primary_color,
				"blurb": RaceLore.get_lore(OmniDexRegistry.race_display_name(str(r.id))).get("description", r.lore),
				"stats": "POW %d  RES %d  SPD %d  LCK %d  STY %d" % [r.pow, r.res, r.spd, r.lck, r.sty],
			})
		"frame":
			_title.text = "CHOOSE YOUR FRAME"
			# Periliminal identity frames from hdv_lore — 20 frames (10 light
			# + 10 heavy). Each has a unique combat role and exclusive stat.
			# The full description comes from role + mobility + combat_style.
			const FrameData = preload("res://hdv_lore/src/data/frame_data.gd")
			_entries = FrameData.FRAMES.map(func(f): return {
				"id": f.id,
				"name": f.name,
				"color": _hash_color(f.id),
				"type": f.frame_type,
				"role": f.get("role", ""),
				"blurb": "%s\n%s\n\n%s" % [
					f.get("role", ""), f.get("mobility", ""), f.get("combat_style", "")],
				"stats": "AGI %d  POW %d  RES %d  FREQ %d" % [
					f.stats.get("agility", 5), f.stats.get("power", 5),
					f.stats.get("resonance", 5), f.stats.get("frequency", 5)],
				"exclusive": "%s: %s" % [f.get("exclusive_stat_name", ""), f.get("exclusive_stat_effect", "")],
			})
		"mod":
			_title.text = "CHOOSE YOUR MORPH RIG"
			# Morph Rig mods from hdv_lore — 20 body plans with rich visual
			# descriptions, gameplay bonuses, and drawbacks.
			_entries = MorphRigData.RIGS.map(func(r): return {
				"id": r.id, "name": OmniDexRegistry.mod_display_name(str(r.id)), "color": _hash_color(r.id),
				"blurb": r.desc if not r.desc.is_empty() else "%s / %s" % [r.bonus, r.drawback],
				"stats": "%s / %s" % [r.bonus, r.drawback],
			})
		"name":
			_title.text = "NAME YOUR FIGHTER"
			_render_final_preview()
			return
	_cursor = 0
	_build_roster()
	_update_portrait()

func _build_customize_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 14)

	var hint := Label.new()
	hint.text = "Fine-tune your body. The 3D preview updates live."
	hint.modulate = Color(0.7, 0.7, 0.85)
	panel.add_child(hint)

	var sliders: Array[Dictionary] = [
		{"key": "height", "label": "HEIGHT", "min": 0.85, "max": 1.2, "step": 0.01},
		{"key": "build", "label": "BUILD", "min": 0.8, "max": 1.3, "step": 0.01},
		{"key": "skin", "label": "SKIN TONE", "ramp": SKIN_RAMP},
		{"key": "hair", "label": "HAIR COLOR", "ramp": HAIR_RAMP},
		{"key": "eye", "label": "EYE COLOR", "ramp": EYE_RAMP},
		{"key": "outfit", "label": "OUTFIT", "ramp": OUTFIT_RAMP},
		{"key": "glow", "label": "RACE GLOW", "min": 0.0, "max": 1.0, "step": 0.02},
	]
	for spec in sliders:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lbl := Label.new()
		lbl.text = str(spec.label)
		lbl.custom_minimum_size = Vector2(110, 0)
		lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(lbl)

		var slider := HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(220, 0)
		row.add_child(slider)

		var value_lbl := Label.new()
		value_lbl.custom_minimum_size = Vector2(72, 0)
		value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(value_lbl)
		panel.add_child(row)

		var key: String = str(spec.key)
		var ramp: Array = []
		if spec.has("ramp"):
			slider.min_value = 0.0
			slider.max_value = 1.0
			slider.step = 0.01
			ramp = spec.ramp
			slider.value = _ramp_t(str(_appearance.get(key, "#d9a066")), ramp)
			value_lbl.text = str(_appearance.get(key, ""))
		else:
			slider.min_value = float(spec.min)
			slider.max_value = float(spec.max)
			slider.step = float(spec.step)
			slider.value = float(_appearance.get(key, spec.min))
			value_lbl.text = "%.2f" % float(slider.value)

		slider.value_changed.connect(func(v: float):
			if spec.has("ramp"):
				var color := _ramp_color(ramp, v)
				_appearance[key] = "#" + color.to_html(false)
				value_lbl.text = _appearance[key]
			else:
				_appearance[key] = v
				value_lbl.text = "%.2f" % v
			if _preview_instance != null:
				_preview_instance.apply_appearance(_appearance))
	return panel

## Map a hex color back to its closest position on a ramp (for slider init).
func _ramp_t(color_hex: String, ramp: Array) -> float:
	var target := Color(color_hex)
	var best := 0.0
	var best_dist := INF
	for i in ramp.size():
		var c: Color = ramp[i]
		var dr := target.r - c.r
		var dg := target.g - c.g
		var db := target.b - c.b
		var d := dr * dr + dg * dg + db * db
		if d < best_dist:
			best_dist = d
			best = float(i) / float(ramp.size() - 1)
	return best

func _ramp_color(ramp: Array, t: float) -> Color:
	var clamped := clampf(t, 0.0, 1.0)
	var pos := clamped * float(ramp.size() - 1)
	var lo := int(floor(pos))
	var hi := mini(lo + 1, ramp.size() - 1)
	return ramp[lo].lerp(ramp[hi], pos - floor(pos))

func _hash_color(seed_str: String) -> Color:
	var h := hash(seed_str)
	return Color.from_hsv(float(h % 360) / 360.0, 0.55, 0.85)

func _build_roster() -> void:
	for c in _roster_row.get_children():
		c.queue_free()
	_tiles.clear()
	var step: String = STEPS[_step]
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(96, 96)
		# Authored concept art wins over the flat color tile for frames/mods.
		# The art is stacked above the name via a child VBox so the portrait
		# isn't squeezed beside the label.
		var art: Texture2D = null
		match step:
			"frame":
				art = CharacterArt.frame_icon(str(e.id), 64)
			"mod":
				art = CharacterArt.mod_icon(str(e.id), 64)
			"sex":
				art = IdentityArt.portrait(str(_picked.get("race", "")), str(e.id))
		if art != null:
			var stack := VBoxContainer.new()
			stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var art_rect := TextureRect.new()
			art_rect.texture = art
			art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stack.add_child(art_rect)
			var name_label := Label.new()
			name_label.text = str(e.name)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_label.add_theme_font_size_override("font_size", 12)
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stack.add_child(name_label)
			tile.add_child(stack)
		else:
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
	_portrait_label.text = str(e.name).to_upper()
	var extra := ""
	if e.has("type") and not e.get("type", "").is_empty():
		extra = "[%s] " % e.type.to_upper()
	if e.has("exclusive") and not e.get("exclusive", "").is_empty():
		extra += "★ %s" % e.exclusive
	_detail.text = "%s\n\n[color=#ffd88a]%s[/color]" % [e.get("blurb", ""), e.get("stats", "")]
	if not extra.is_empty():
		_detail.text += "\n\n" + extra

	# Update the 3D preview with the currently selected race/sex/frame/mod.
	var step: String = STEPS[_step]
	var cur_sex: String = str(_picked.get("sex", "m"))
	match step:
		"race":
			_preview_instance.preview(str(e.id), _picked.get("frame", ""), _picked.get("mod", ""), cur_sex, _appearance)
		"frame":
			_preview_instance.preview(_picked.get("race", ""), str(e.id), _picked.get("mod", ""), cur_sex, _appearance)
		"mod":
			_preview_instance.preview(_picked.get("race", ""), _picked.get("frame", ""), str(e.id), cur_sex, _appearance)
		"customize":
			_preview_instance.preview(_picked.get("race", ""), _picked.get("frame", ""), _picked.get("mod", ""), cur_sex, _appearance)
		_:
			_preview_instance.preview(_picked.get("race", ""), _picked.get("frame", ""), _picked.get("mod", ""), cur_sex, _appearance)

	# The 3D body IS the preview. The shipped PeriHuman GLB is a static bake
	# that can't show frame/mod/slider changes, so the wizard shows the live
	# articulated rig — there is deliberately NO 2D portrait layered on top
	# anymore (it duplicated the body and froze the "dead" look you saw).
	# Roster tiles keep their concept-art thumbnails as the pick targets.
	if _portrait_image != null:
		_portrait_image.visible = false
		_portrait_image.offset_bottom = 0.0
	if _preview_viewport != null:
		_preview_viewport.visible = true

func _render_final_preview() -> void:
	var stats := CharacterCreatorLogic.build_starting_stats(_picked.race, "Factionless", _picked.frame)
	var canon_name := OmniDexRegistry.race_display_name(str(_picked.race))
	_portrait.color = RaceDataCharacter.get_race(_picked.race).get("primary_color", Color.WHITE)
	_portrait_label.text = canon_name.to_upper()
	var lore_desc := RaceLore.get_lore(canon_name).get("description", "")
	var frame_name: String = str(_picked.get("frame_name", "?"))
	var frame_desc := ""
	var frame_exclusive := ""
	const FrameData = preload("res://hdv_lore/src/data/frame_data.gd")
	var hdv_frame := FrameData.by_id(str(_picked.frame))
	if not hdv_frame.is_empty():
		frame_name = str(hdv_frame.get("name", frame_name))
		var role := str(hdv_frame.get("role", ""))
		var mobility := str(hdv_frame.get("mobility", ""))
		var combat := str(hdv_frame.get("combat_style", ""))
		frame_desc = "%s\n%s\n%s" % [role, mobility, combat]
		var excl_name := str(hdv_frame.get("exclusive_stat_name", ""))
		var excl_eff := str(hdv_frame.get("exclusive_stat_effect", ""))
		if not excl_name.is_empty():
			frame_exclusive = "★ %s: %s" % [excl_name, excl_eff]
	_detail.text = "[b]%s[/b] — Factionless — [b]%s[/b]\n\n%s\n\nPOW %d  RES %d  SPD %d  LCK %d  STY %d" % [
		canon_name, frame_name,
		lore_desc,
		stats.pow, stats.res, stats.spd, stats.lck, stats.sty,
	]
	if not frame_desc.is_empty():
		_detail.text += "\n\n[i]%s[/i]" % frame_desc
	if not frame_exclusive.is_empty():
		_detail.text += "\n" + frame_exclusive
	# Show mod stats at the bottom if one is picked.
	if _picked.has("mod") and not str(_picked.get("mod", "")).is_empty():
		var mod_id := str(_picked.mod)
		var mod_data := MorphRigData.by_id(mod_id)
		if not mod_data.is_empty():
			_detail.text += "\n\nMod: %s (%s / %s)" % [
				str(mod_data.get("name", mod_id)),
				str(mod_data.get("bonus", "")),
				str(mod_data.get("drawback", "")),
			]
	# Final 3D preview with all selections applied.
	_preview_instance.preview(_picked.get("race", ""), _picked.get("frame", ""),
		_picked.get("mod", ""), str(_picked.get("sex", "m")), _appearance)

func _confirm_step() -> void:
	var PlayerProfile = AutoloadGate.get_node("PlayerProfile")
	print("[VentureWizard] _confirm_step called, step=", STEPS[_step])
	var step: String = STEPS[_step]
	if step == "name":
		var cat_name := _name_edit.text.strip_edges()
		print("[VentureWizard] name='", cat_name, "' len=", cat_name.length())
		if not CharacterCreatorLogic.validate_name(cat_name):
			_detail.text += "\n\n[color=#ff6666]⚠️ Enter a valid name (2-20 letters/numbers, no spaces).[/color]"
			print("[VentureWizard] name validation FAILED")
			return
		# All players begin Factionless — they join a faction later by
		# visiting one of the main faction cities.
		print("[VentureWizard] name valid, calling apply_creation")
		CharacterCreatorLogic.apply_creation(_picked.race, "Factionless", _picked.frame, cat_name,
			str(_picked.get("sex", "m")), _appearance)
		print("[VentureWizard] apply_creation done, calling set_mod")
		PlayerProfile.set_mod(_picked.mod)
		print("[VentureWizard] set_mod done, emitting venture_started")
		venture_started.emit()
		# A new venture starts in the wilds, not the safety of the Subliminal.
		# change_scene_to_file is deferred to end-of-frame by the engine, so
		# the wizard is not destroyed while its call stack is still alive.
		_do_transition_to_liminal()
		return

	if step == "customize":
		# Sliders already wrote into _appearance live; nothing to confirm.
		_step += 1
		_render_step()
		return

	if _entries.is_empty():
		return
	var e: Dictionary = _entries[_cursor]
	match step:
		"race":
			_picked["race"] = e.id
			_picked["race_name"] = e.name
		"frame":
			_picked["frame"] = e.id
			_picked["frame_name"] = e.name
		"mod":
			_picked["mod"] = e.id
	_step += 1
	_render_step()


func _sync_sex_row() -> void:
	if _sex_buttons.is_empty():
		return
	for i in _sex_buttons.size():
		var sid := "m" if i == 0 else "f"
		_sex_buttons[i].modulate = Color.WHITE if str(_picked.get("sex", "m")) == sid else Color(0.5, 0.5, 0.6)

func _go_back() -> void:
	if _step <= 0:
		# At the very first screen, Back leaves the creator for the title.
		if ResourceLoader.exists("res://scenes/ui/title_screen.tscn"):
			get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
		return
	_step -= 1
	_render_step()

func _do_transition_to_liminal() -> void:
	var LayerManager = AutoloadGate.get_node("LayerManager")
	## Transition to the Liminal layer. Called directly from _confirm_step;
	## change_scene_to_file defers the actual scene swap to end-of-frame so
	## the wizard's call stack finishes cleanly.
	print("[VentureWizard] _do_transition_to_liminal BEGIN")
	var err = LayerManager.transition_to("liminal", true)
	print("[VentureWizard] _do_transition_to_liminal returned err=", err)
	if not err:
		push_error("VentureWizard: transition_to(liminal) failed")
