extends Control
class_name TitleScreen
## Front door after login. Styled like the in-game phone home screen:
## a centered phone frame with widgets, app icons, and a dock.

var _content_ref: Control = null

func _ready() -> void:
	var MusicManager = AutoloadGate.get_node("MusicManager")
	MusicManager.play_context("theme")
	_build_phone_ui()

func _build_phone_ui() -> void:
	var PlayerProfile = AutoloadGate.get_node("PlayerProfile")
	var b := PhoneUI.boost()
	var is_phone := PhoneUI.is_phone()

	# Phone chrome (wallpaper, bezel, status bar, home indicator).
	var shell := PhoneShell.build(self, is_phone, Vector2(
		minf(get_viewport().get_visible_rect().size.x, 560 if is_phone else 520),
		get_viewport().get_visible_rect().size.y))
	var content: Control = shell.content
	_content_ref = content
	_update_time()
	var time_tween := create_tween().set_loops()
	time_tween.tween_callback(_update_time).set_delay(1.0)

	# Brand widget.
	var widget := PanelContainer.new()
	widget.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	widget.offset_top = 44
	widget.offset_bottom = 44 + 160
	var wstyle := StyleBoxFlat.new()
	wstyle.bg_color = Color(0.12, 0.1, 0.18, 0.85)
	wstyle.corner_radius_top_left = 18
	wstyle.corner_radius_top_right = 18
	wstyle.corner_radius_bottom_left = 18
	wstyle.corner_radius_bottom_right = 18
	widget.add_theme_stylebox_override("panel", wstyle)
	content.add_child(widget)

	var brand_box := VBoxContainer.new()
	brand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_box.add_theme_constant_override("separation", 8)
	widget.add_child(brand_box)

	var emblem := LogoEmblem.new()
	emblem.custom_minimum_size = Vector2(80, 80)
	brand_box.add_child(emblem)

	var title := Label.new()
	title.text = "PERILIMINAL.SPACE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	brand_box.add_child(title)

	var tagline := Label.new()
	tagline.text = "Six realities. One of you."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.modulate = Color(0.7, 0.6, 0.9)
	tagline.add_theme_font_size_override("font_size", 14)
	brand_box.add_child(tagline)

	# News ticker.
	var news := _build_news_ticker()
	news.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	news.offset_top = 216
	news.offset_bottom = 216 + 80
	content.add_child(news)

	# App grid.
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 310
	scroll.offset_bottom = -120
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	scroll.add_child(grid)

	var apps: Array[Dictionary] = [
		{"id": "new", "emoji": "⚔️", "label": "New Venture", "color": Color(0.25, 0.5, 0.35), "fn": func(): get_tree().change_scene_to_file("res://scenes/ui/venture_wizard.tscn")},
		{"id": "continue", "emoji": "🌀", "label": "Continue", "color": Color(0.2, 0.35, 0.55), "fn": _continue_expedition},
		{"id": "omnidex", "emoji": "📖", "label": "OmniDex", "color": Color(0.35, 0.25, 0.55), "fn": _toggle_omni_dex},
		{"id": "daily", "emoji": "🎁", "label": "Daily", "color": Color(0.5, 0.35, 0.2), "fn": _open_daily},
		{"id": "quests", "emoji": "📜", "label": "Quests", "color": Color(0.25, 0.4, 0.5), "fn": _open_quests},
		{"id": "leaderboard", "emoji": "🏆", "label": "Leaderboard", "color": Color(0.6, 0.45, 0.15), "fn": _open_leaderboard},
		{"id": "shop", "emoji": "🛒", "label": "Shop", "color": Color(0.35, 0.5, 0.3), "fn": _open_shop},
		{"id": "battlepass", "emoji": "🎟️", "label": "Pass", "color": Color(0.5, 0.25, 0.5), "fn": _open_battlepass},
		{"id": "guild", "emoji": "🏰", "label": "Guild", "color": Color(0.45, 0.25, 0.55), "fn": _open_guild},
		{"id": "hope", "emoji": "💛", "label": "Hope", "color": Color(0.75, 0.55, 0.15), "fn": _open_hope},
		{"id": "calendar", "emoji": "📅", "label": "Calendar", "color": Color(0.2, 0.45, 0.55), "fn": _open_calendar},
		{"id": "settings", "emoji": "⚙️", "label": "Settings", "color": Color(0.3, 0.3, 0.35), "fn": func(): get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")},
		{"id": "info", "emoji": "ℹ️", "label": "Info", "color": Color(0.4, 0.35, 0.25), "fn": _show_info},
		{"id": "proto", "emoji": "🧪", "label": "Prototype", "color": Color(0.5, 0.2, 0.45), "fn": _start_prototype_spine},
	]
	for spec in apps:
		var icon := PhoneAppIcon.new()
		icon.setup(str(spec.id), str(spec.emoji), str(spec.label), Color(spec.color))
		icon.pressed.connect(spec.fn)
		grid.add_child(icon)

	# Dock: Hope is one of the four most-checked apps.
	var dock := HBoxContainer.new()
	dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_top = -100
	dock.offset_bottom = -20
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 24)
	content.add_child(dock)
	for spec in [apps[0], apps[1], apps[9], apps[2]]:
		var icon := PhoneAppIcon.new()
		icon.setup(str(spec.id), str(spec.emoji), str(spec.label), Color(spec.color))
		icon.custom_minimum_size = Vector2(72, 72)
		icon.pressed.connect(spec.fn)
		dock.add_child(icon)

	# Disable Continue if no expedition.
	var continue_icon := _find_app_icon(grid, "continue")
	if continue_icon != null and not PlayerProfile.has_expedition:
		continue_icon.disabled = true
		continue_icon.tooltip_text = "No expedition yet — start a new venture first."

func _update_time() -> void:
	if not is_instance_valid(self) or _content_ref == null:
		return
	var time_lbl: Label = _content_ref.get_meta("ShellTimeLabel") if _content_ref.has_meta("ShellTimeLabel") else null
	if time_lbl == null:
		return
	var now := Time.get_time_dict_from_system()
	time_lbl.text = "%02d:%02d" % [now.hour, now.minute]

func _find_app_icon(grid: GridContainer, id: String) -> PhoneAppIcon:
	for c in grid.get_children():
		if c is PhoneAppIcon and c.app_id == id:
			return c
	return null

func _build_news_ticker() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14, 0.8)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	var header := Label.new()
	header.text = "📰 Updates"
	header.add_theme_font_size_override("font_size", 14)
	vbox.add_child(header)
	var ticker := Label.new()
	ticker.name = "Ticker"
	ticker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ticker.add_theme_font_size_override("font_size", 12)
	ticker.modulate = Color(0.8, 0.8, 0.9)
	var lines: Array[String] = _news_lines()
	ticker.text = "\n".join(lines)
	vbox.add_child(ticker)
	return panel

func _news_lines() -> Array[String]:
	var LiveOpsManager = AutoloadGate.get_node("LiveOpsManager")
	var lines: Array[String] = [
		"Welcome to Periliminal.Space — the Catsino is just one layer.",
	]
	if LiveOpsManager != null and LiveOpsManager.has_method("get_active_events"):
		for ev: Variant in LiveOpsManager.get_active_events():
			var d: Dictionary = {}
			if ev is Dictionary:
				d = ev as Dictionary
			elif ev != null and ev.has_method("to_dict"):
				d = ev.to_dict() as Dictionary
			var ev_name: String = str(d.get("name", ""))
			if not ev_name.is_empty():
				lines.append("⭐ Live event: %s" % ev_name)
	lines.append("New: phone home screen, party seals, and PVXC cage.")
	return lines

func _continue_expedition() -> void:
	var LayerManager = AutoloadGate.get_node("LayerManager")
	if not LayerManager.transition_to("subliminal"):
		get_tree().change_scene_to_file("res://scenes/layers/subliminal.tscn")

func _load_scene_instance(path: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	return packed.instantiate()

func _open_daily() -> void:
	var daily := DailyRewardPopup.new()
	daily.name = "DailyRewardApp"
	add_child(daily)

func _open_quests() -> void:
	var qu := _load_scene_instance("res://scenes/ui/quest.tscn") as Control
	if qu != null:
		add_child(qu)

func _open_leaderboard() -> void:
	var lb := _load_scene_instance("res://scenes/ui/leaderboard.tscn") as Control
	if lb != null:
		add_child(lb)

func _open_shop() -> void:
	var shop := ShopUI.new()
	add_child(shop)

func _open_battlepass() -> void:
	var bp := _load_scene_instance("res://scenes/ui/battlepass.tscn") as Control
	if bp != null:
		add_child(bp)

func _open_guild() -> void:
	var panel := _build_guild_panel()
	add_child(panel)

func _build_guild_panel() -> Control:
	var GuildManager = AutoloadGate.get_node("GuildManager")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 400)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var top := HBoxContainer.new()
	var title := Label.new()
	title.text = "🏰 Guild"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := Button.new()
	close.text = "✕"
	close.pressed.connect(panel.queue_free)
	top.add_child(close)
	vbox.add_child(top)

	if GuildManager != null and GuildManager.in_guild():
		var g: Dictionary = GuildManager.guild
		var name_lbl := Label.new()
		name_lbl.text = "%s [%s]" % [g.get("name", ""), g.get("tag", "")]
		name_lbl.add_theme_font_size_override("font_size", 16)
		vbox.add_child(name_lbl)
		var motd := Label.new()
		motd.text = "MOTD: %s" % g.get("motd", "No message set.")
		motd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		motd.modulate = Color(0.75, 0.75, 0.85)
		vbox.add_child(motd)
		var members_title := Label.new()
		members_title.text = "Members"
		members_title.add_theme_font_size_override("font_size", 15)
		vbox.add_child(members_title)
		var members: Dictionary = g.get("members", {})
		for member_id in members.keys():
			var rank_idx: int = int(members.get(member_id, 0))
			var ranks: Array = g.get("ranks", ["Recruit"])
			var rank: String = ranks[clampi(rank_idx, 0, ranks.size() - 1)] if ranks.size() > 0 else "Recruit"
			var lbl := Label.new()
			lbl.text = "%s — %s" % [member_id, rank]
			vbox.add_child(lbl)
		var leave_btn := Button.new()
		leave_btn.text = "Leave Guild"
		leave_btn.pressed.connect(func():
			if GuildManager != null and GuildManager.has_method("disband"):
				GuildManager.disband()
				NotificationUI.notify_info("You left the guild.")
				panel.queue_free()
				_open_guild())
		vbox.add_child(leave_btn)
	else:
		var create_row := HBoxContainer.new()
		var name_input := LineEdit.new()
		name_input.placeholder_text = "Guild name"
		name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		create_row.add_child(name_input)
		var tag_input := LineEdit.new()
		tag_input.placeholder_text = "Tag"
		tag_input.custom_minimum_size = Vector2(60, 0)
		create_row.add_child(tag_input)
		var create_btn := Button.new()
		create_btn.text = "Create"
		create_btn.pressed.connect(func():
			if GuildManager != null and GuildManager.has_method("create_guild"):
				var ok = await GuildManager.create_guild(name_input.text.strip_edges(), tag_input.text.strip_edges())
				if ok:
					NotificationUI.notify_win("Guild chartered!")
					panel.queue_free()
					_open_guild()
				else:
					NotificationUI.notify_error("Could not charter guild.")
			else:
				NotificationUI.notify_error("Guild system offline."))
		create_row.add_child(create_btn)
		vbox.add_child(create_row)
		var join_hint := Label.new()
		join_hint.text = "Invite codes are shared by guild officers."
		join_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		join_hint.modulate = Color(0.65, 0.65, 0.75)
		vbox.add_child(join_hint)
	return panel

func _open_hope() -> void:
	var Hope = AutoloadGate.get_node("Hope")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	if Hope == null:
		NotificationUI.notify_error("Hope is not awake.")
		return
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 420)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var top := HBoxContainer.new()
	var title := Label.new()
	title.text = "💛 Hope"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := Button.new()
	close.text = "✕"
	close.pressed.connect(panel.queue_free)
	top.add_child(close)
	vbox.add_child(top)

	var stage = Hope.stage()
	var stage_lbl := Label.new()
	stage_lbl.text = "%s (bond %d)" % [stage.get("name", "Flicker"), Hope.bond]
	stage_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(stage_lbl)

	var desc := Label.new()
	desc.text = str(stage.get("desc", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(0.85, 0.8, 0.6)
	vbox.add_child(desc)

	var axes := Label.new()
	axes.text = "Aggression %.0f%% · Caution %.0f%% · Curiosity %.0f%% · Greed %.0f%%" % [
		Hope.profile.aggression * 100, Hope.profile.caution * 100,
		Hope.profile.curiosity * 100, Hope.profile.greed * 100]
	axes.add_theme_font_size_override("font_size", 12)
	axes.modulate = Color(0.7, 0.75, 0.85)
	vbox.add_child(axes)

	var care_row := HBoxContainer.new()
	care_row.alignment = BoxContainer.ALIGNMENT_CENTER
	care_row.add_theme_constant_override("separation", 8)
	vbox.add_child(care_row)
	for care in [
		{"label": "Attend", "drive": "boredom", "delta": -1},
		{"label": "Console", "drive": "fear", "delta": -1},
		{"label": "Celebrate", "drive": "curiosity", "delta": 1},
	]:
		var btn := Button.new()
		btn.text = str(care.label)
		var drive: String = str(care.drive)
		var delta: int = int(care.delta)
		btn.pressed.connect(func():
			Hope.gain_bond(5, "care_%s" % drive)
			var current: float = float(Hope.profile.get(drive, 0.0))
			Hope.profile[drive] = clampf(current + delta * 0.05, 0.0, 1.0)
			NotificationUI.notify_info("Hope %s. Bond +5." % str(care.label).to_lower()))
		care_row.add_child(btn)

	add_child(panel)

func _open_calendar() -> void:
	var LiveOpsManager = AutoloadGate.get_node("LiveOpsManager")
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 420)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var top := HBoxContainer.new()
	var title := Label.new()
	title.text = "📅 Calendar"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := Button.new()
	close.text = "✕"
	close.pressed.connect(panel.queue_free)
	top.add_child(close)
	vbox.add_child(top)

	var now := Time.get_datetime_dict_from_system()
	var date_lbl := Label.new()
	date_lbl.text = "Server day: %04d-%02d-%02d" % [now.year, now.month, now.day]
	date_lbl.modulate = Color(0.75, 0.75, 0.85)
	vbox.add_child(date_lbl)

	var events_title := Label.new()
	events_title.text = "Active Events"
	events_title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(events_title)

	if LiveOpsManager != null and LiveOpsManager.has_method("get_active_events"):
		var events: Array = LiveOpsManager.get_active_events()
		if events.is_empty():
			var none := Label.new()
			none.text = "No active events."
			none.modulate = Color(0.65, 0.65, 0.65)
			vbox.add_child(none)
		else:
			for ev: Variant in events:
				var d: Dictionary = {}
				if ev is Dictionary:
					d = ev as Dictionary
				elif ev != null and ev.has_method("to_dict"):
					d = ev.to_dict() as Dictionary
				var row := HBoxContainer.new()
				var icon := Label.new()
				icon.text = "⭐"
				row.add_child(icon)
				var lbl := Label.new()
				lbl.text = "%s — ends %s" % [d.get("name", "Event"), d.get("ends_at", "?")]
				lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(lbl)
				vbox.add_child(row)
	else:
		var offline := Label.new()
		offline.text = "LiveOps offline."
		offline.modulate = Color(0.65, 0.65, 0.65)
		vbox.add_child(offline)

	add_child(panel)

func _start_prototype_spine() -> void:
	var LayerManager = AutoloadGate.get_node("LayerManager")
	var PlayerProfile = AutoloadGate.get_node("PlayerProfile")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	LayerManager.enable_prototype_mode(true)
	if not PlayerProfile.has_expedition:
		PlayerProfile.set_race(PlayerProfile.selected_race_id)
		PlayerProfile.set_frame("veil")
		PlayerProfile.set_mod("catalyst")
		PlayerProfile.set_faction("Factionless")
		PlayerProfile.has_expedition = true
		PlayerProfile._save()
	NotificationUI.notify_info("Prototype spine armed. Walk the Metroplex archway — the Between is already watching.")
	LayerManager.transition_to("liminal", true)

func _toggle_omni_dex() -> void:
	if get_node_or_null("OmniDex") != null:
		return
	var dex := OmniDexUI.new()
	dex.name = "OmniDex"
	add_child(dex)

func _show_info() -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	NotificationUI.notify_info("Periliminal.Space — a psychology XRMMORPG across six reality layers. The Catsino is one of them, not the main game. City streets: © OpenStreetMap contributors (ODbL).")
