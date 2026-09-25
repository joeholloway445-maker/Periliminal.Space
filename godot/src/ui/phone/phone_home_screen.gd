class_name PhoneHomeScreen
extends Control
## GTA-style phone home screen for Periliminal.Space.
## Built procedurally so it works without a matching .tscn. Apps are icons
## that open full-screen panels; widgets live on a swipeable page above the
## grid. Designed for both desktop (mouse) and touch.

signal app_opened(app_id: String)
signal app_closed()

const APP_ICON_SIZE := 72.0
const APP_GRID_COLS := 4

var _phone_frame: PanelContainer
var _content: Control
var _widget_pages: TabContainer
var _app_grid: GridContainer
var _dock: HBoxContainer
var _active_app: Control

func _ready() -> void:
	_build_phone_shell()
	_build_widget_pages()
	_build_app_grid()
	_build_dock()
	_update_time()
	set_process(true)

func _process(_delta: float) -> void:
	_update_time()

func _phone_size() -> Vector2:
	var is_phone := PhoneUI.is_phone() if PhoneUI != null else false
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		viewport_size = Vector2(1080, 1920)
	var phone_w := minf(viewport_size.x - 32, 420 if is_phone else 460)
	var phone_h := viewport_size.y - (0 if is_phone else 64)
	return Vector2(phone_w, phone_h)

func _build_phone_shell() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var is_phone := PhoneUI.is_phone() if PhoneUI != null else false
	var shell := PhoneShell.build(self, is_phone, _phone_size())
	_phone_frame = shell.frame
	_content = shell.content

func _update_time() -> void:
	var time_lbl: Label = _content.get_meta("ShellTimeLabel") if _content.has_meta("ShellTimeLabel") else null
	if time_lbl == null:
		return
	var now := Time.get_time_dict_from_system()
	time_lbl.text = "%02d:%02d" % [now.hour, now.minute]

func _build_widget_pages() -> void:
	_widget_pages = TabContainer.new()
	_widget_pages.name = "WidgetPages"
	_widget_pages.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_widget_pages.offset_top = 44
	_widget_pages.offset_bottom = 44 + 220
	_widget_pages.tabs_visible = false
	_content.add_child(_widget_pages)

	_add_widget_page(_build_news_widget())
	_add_widget_page(_build_party_widget())

func _add_widget_page(content: Control) -> void:
	var page := MarginContainer.new()
	page.add_theme_constant_override("margin_left", 8)
	page.add_theme_constant_override("margin_right", 8)
	page.add_theme_constant_override("margin_top", 8)
	page.add_theme_constant_override("margin_bottom", 8)
	page.add_child(content)
	_widget_pages.add_child(page)

func _build_news_widget() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 0.85)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "📰 FEED"
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)
	vbox.add_child(header)

	var feed := VBoxContainer.new()
	feed.name = "NewsFeed"
	feed.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feed.add_theme_constant_override("separation", 6)
	vbox.add_child(feed)

	_populate_news_feed(feed)
	return panel

func _populate_news_feed(feed: VBoxContainer) -> void:
	var LiveOpsManager = AutoloadGate.get_node("LiveOpsManager")
	var Hope = AutoloadGate.get_node("Hope")
	for c in feed.get_children():
		c.queue_free()

	var items: Array[Dictionary] = []
	if LiveOpsManager != null and LiveOpsManager.has_method("get_active_events"):
		for ev: Variant in LiveOpsManager.get_active_events():
			var d: Dictionary = {}
			if ev is Dictionary:
				d = ev as Dictionary
			elif ev != null and ev.has_method("to_dict"):
				d = ev.to_dict() as Dictionary
			var ev_name: String = str(d.get("name", ""))
			if not ev_name.is_empty():
				items.append({"icon": "⭐", "text": ev_name})

	items.append({"icon": "🌐", "text": "Periliminal.Space — six realities, one of you."})
	items.append({"icon": "🐈", "text": "Paws Vegas crowd: %d cats on the floor." % _crowd_count()})
	items.append({"icon": "💛", "text": "Hope stage: %s (bond %d)." % [_hope_stage_name(), Hope.bond if Hope != null else 0]})

	for item in items.slice(0, 5):
		var row := HBoxContainer.new()
		var icon := Label.new()
		icon.text = str(item.get("icon", "•"))
		row.add_child(icon)
		var lbl := Label.new()
		lbl.text = str(item.get("text", ""))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(lbl)
		feed.add_child(row)

func _crowd_count() -> int:
	var DistrictManager = AutoloadGate.get_node("DistrictManager")
	if DistrictManager != null and DistrictManager.has_method("get_player_count"):
		return int(DistrictManager.get_player_count(DistrictManager.District.PAW_VEGAS))
	return 0

func _hope_stage_name() -> String:
	var Hope = AutoloadGate.get_node("Hope")
	if Hope == null:
		return "Flicker"
	return str(Hope.stage().get("name", "Flicker"))

func _build_party_widget() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.14, 0.12, 0.85)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🎭 PARTY"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var list := VBoxContainer.new()
	list.name = "PartyList"
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(list)
	_refresh_party_list(list)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(actions)

	var create_btn := Button.new()
	create_btn.text = "Create"
	create_btn.pressed.connect(func():
		var PartyManager = AutoloadGate.get_node("PartyManager")
		if PartyManager != null:
			PartyManager.create()
			_refresh_party_list(list))
	actions.add_child(create_btn)

	var invite_row := HBoxContainer.new()
	var invite_input := LineEdit.new()
	invite_input.placeholder_text = "Invite player"
	invite_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	invite_row.add_child(invite_input)
	var invite_btn := Button.new()
	invite_btn.text = "Invite"
	invite_btn.pressed.connect(func():
		var PartyManager = AutoloadGate.get_node("PartyManager")
		var NotificationUI = AutoloadGate.get_node("NotificationUI")
		var target := invite_input.text.strip_edges()
		if target == "" or PartyManager == null:
			return
		var result: Dictionary = PartyManager.add_member(target)
		if bool(result.get("ok", false)):
			NotificationUI.notify_info("%s joined the party." % target)
			invite_input.text = ""
		else:
			NotificationUI.notify_error(str(result.get("reason", "Could not invite.")))
		_refresh_party_list(list))
	invite_row.add_child(invite_btn)
	vbox.add_child(invite_row)

	var leave_btn := Button.new()
	leave_btn.text = "Leave"
	leave_btn.pressed.connect(func():
		var PartyManager = AutoloadGate.get_node("PartyManager")
		if PartyManager != null:
			PartyManager.leave()
			_refresh_party_list(list))
	actions.add_child(leave_btn)

	return panel

func _refresh_party_list(list: VBoxContainer) -> void:
	var PartyManager = AutoloadGate.get_node("PartyManager")
	for c in list.get_children():
		c.queue_free()
	var members: Array[String] = []
	if PartyManager != null:
		members = PartyManager.members()
	if members.is_empty():
		members = ["local_player"]
	for m in members:
		var lbl := Label.new()
		lbl.text = "• %s" % m
		lbl.add_theme_font_size_override("font_size", 14)
		list.add_child(lbl)

func _build_app_grid() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "AppScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 270
	scroll.offset_bottom = -80
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)

	_app_grid = GridContainer.new()
	_app_grid.name = "AppGrid"
	# 4 columns clips on narrow portrait phones; drop to 3 so every app stays on-screen.
	_app_grid.columns = (3 if (PhoneUI != null and PhoneUI.is_phone()) else APP_GRID_COLS)
	_app_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_app_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_app_grid.add_theme_constant_override("h_separation", 16)
	_app_grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(_app_grid)

	_add_app("omnidex", "📖", "OmniDex", Color(0.2, 0.35, 0.6), _open_omnidex)
	_add_app("map", "🗺️", "Map", Color(0.15, 0.5, 0.35), _open_map)
	_add_app("contacts", "👥", "Contacts", Color(0.4, 0.3, 0.55), _open_contacts)
	_add_app("party", "🎭", "Party", Color(0.25, 0.45, 0.4), _open_party)
	_add_app("chat", "💬", "Messages", Color(0.35, 0.35, 0.35), _open_chat)
	_add_app("hope", "💛", "Hope", Color(0.75, 0.55, 0.15), _open_hope)
	_add_app("casino", "🎰", "Casino", Color(0.55, 0.2, 0.55), _open_casino)
	_add_app("subliminal", "🚪", "Apartment", Color(0.45, 0.35, 0.25), _open_subliminal)
	_add_app("periliminal", "🔴", "Descend", Color(0.6, 0.1, 0.1), _open_periliminal)
	_add_app("guild", "🏰", "Guild", Color(0.45, 0.25, 0.55), _open_guild)
	_add_app("leaderboard", "🏆", "Leaderboard", Color(0.6, 0.45, 0.15), _open_leaderboard)
	_add_app("quests", "📜", "Quests", Color(0.25, 0.4, 0.5), _open_quests)
	_add_app("daily", "🎁", "Daily", Color(0.5, 0.35, 0.2), _open_daily)
	_add_app("calendar", "📅", "Calendar", Color(0.2, 0.45, 0.55), _open_calendar)
	_add_app("battlepass", "🎟️", "Pass", Color(0.5, 0.25, 0.5), _open_battlepass)
	_add_app("shop", "🛒", "Shop", Color(0.35, 0.5, 0.3), _open_shop)
	_add_app("settings", "⚙️", "Settings", Color(0.3, 0.3, 0.35), _open_settings)

func _add_app(id: String, emoji: String, label: String, color: Color, callback: Callable) -> void:
	var icon := PhoneAppIcon.new()
	icon.setup(id, emoji, label, color)
	icon.pressed.connect(func():
		app_opened.emit(id)
		callback.call())
	_app_grid.add_child(icon)

func _build_dock() -> void:
	_dock = HBoxContainer.new()
	_dock.name = "Dock"
	_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dock.offset_top = -72
	_dock.offset_bottom = -8
	_dock.alignment = BoxContainer.ALIGNMENT_CENTER
	_dock.add_theme_constant_override("separation", 24)
	_content.add_child(_dock)

	var dock_apps: Array[Dictionary] = [
		{"id": "omnidex", "emoji": "📖", "label": "Dex", "color": Color(0.2, 0.35, 0.6)},
		{"id": "map", "emoji": "🗺️", "label": "Map", "color": Color(0.15, 0.5, 0.35)},
		{"id": "hope", "emoji": "💛", "label": "Hope", "color": Color(0.75, 0.55, 0.15)},
		{"id": "chat", "emoji": "💬", "label": "Chat", "color": Color(0.35, 0.35, 0.35)},
	]
	for spec in dock_apps:
		var icon := PhoneAppIcon.new()
		icon.setup(str(spec.id), str(spec.emoji), str(spec.label), Color(spec.color))
		icon.custom_minimum_size = Vector2(56, 56)
		icon.pressed.connect(func():
			app_opened.emit(str(spec.id))
			_launch_app(str(spec.id)))
		_dock.add_child(icon)

func _launch_app(id: String) -> void:
	match id:
		"omnidex": _open_omnidex()
		"map": _open_map()
		"contacts": _open_contacts()
		"party": _open_party()
		"chat": _open_chat()
		"hope": _open_hope()
		"casino": _open_casino()
		"subliminal": _open_subliminal()
		"periliminal": _open_periliminal()
		"guild": _open_guild()
		"leaderboard": _open_leaderboard()
		"quests": _open_quests()
		"daily": _open_daily()
		"calendar": _open_calendar()
		"battlepass": _open_battlepass()
		"shop": _open_shop()
		"settings": _open_settings()

func _open_app_panel(title: String, content: Control) -> void:
	_close_active_app()
	var panel := PanelContainer.new()
	panel.name = "AppPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = 36
	panel.offset_bottom = -8
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style)
	_content.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var top := HBoxContainer.new()
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_lbl)
	var close := Button.new()
	close.text = "✕"
	close.pressed.connect(_close_active_app)
	top.add_child(close)
	vbox.add_child(top)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	scroll.add_child(content)

	_active_app = panel

func _close_active_app() -> void:
	if _active_app != null and is_instance_valid(_active_app):
		_active_app.queue_free()
		_active_app = null
	app_closed.emit()

# ── App callbacks ───────────────────────────────────────────────────────────

func _open_omnidex() -> void:
	_close_active_app()
	var dex := OmniDexUI.new()
	dex.name = "OmniDexApp"
	_add_canvas_layer_app(dex)

func _add_canvas_layer_app(layer: CanvasLayer) -> void:
	layer.layer = 20
	_content.add_child(layer)
	_active_app = Control.new()
	_active_app.name = "CanvasLayerAppProxy"
	var close := Button.new()
	close.text = "✕ Close"
	close.position = Vector2(_content.size.x - 90, 8)
	close.pressed.connect(func():
		layer.queue_free()
		_active_app.queue_free()
		_active_app = null
		app_closed.emit())
	_active_app.add_child(close)
	_content.add_child(_active_app)

func _open_map() -> void:
	_close_active_app()

func _open_contacts() -> void:
	var SocialManager = AutoloadGate.get_node("SocialManager")
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "👥 Contacts"
	header.add_theme_font_size_override("font_size", 18)
	root.add_child(header)

	var friend_list: Array[Dictionary] = []
	if SocialManager != null:
		friend_list = SocialManager.friend_list.duplicate()
	if friend_list.is_empty():
		var empty := Label.new()
		empty.text = "No friends yet. Add a player by username."
		empty.modulate = Color(0.7, 0.7, 0.8)
		root.add_child(empty)
	else:
		for f in friend_list:
			var user_id: String = str(f.get("id", ""))
			var username: String = str(f.get("username", user_id))
			var online: bool = SocialManager != null and SocialManager.online_friends.has(user_id)
			var row := HBoxContainer.new()
			var status := Label.new()
			status.text = "🟢" if online else "⚫"
			row.add_child(status)
			var lbl := Label.new()
			lbl.text = username
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lbl)
			var msg := Button.new()
			msg.text = "Msg"
			msg.pressed.connect(func():
				_open_chat_with(username))
			row.add_child(msg)
			root.add_child(row)

	var add_row := HBoxContainer.new()
	var add_input := LineEdit.new()
	add_input.placeholder_text = "Add friend by username"
	add_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(add_input)
	var add_btn := Button.new()
	add_btn.text = "Add"
	add_btn.pressed.connect(func():
		var AccountManager = AutoloadGate.get_node("AccountManager")
		var NotificationUI = AutoloadGate.get_node("NotificationUI")
		var name := add_input.text.strip_edges()
		if name.is_empty():
			return
		var online: bool = AccountManager != null and AccountManager.is_authenticated
		if online and SocialManager != null and SocialManager.has_method("add_friend"):
			SocialManager.add_friend(name)
			NotificationUI.notify_info("Friend request sent to %s." % name)
		else:
			NotificationUI.notify_error("Not connected. Friend requests need a live session."))
	add_row.add_child(add_btn)
	root.add_child(add_row)

	_open_app_panel("Contacts", root)

func _open_chat_with(username: String) -> void:
	_close_active_app()
	var chat := ChatUI.new()
	chat.name = "ChatApp"
	chat.set_meta("target_user", username)
	_add_canvas_layer_app(chat)

func _open_party() -> void:
	_open_app_panel("Party", _build_party_widget())

func _open_chat() -> void:
	_close_active_app()
	var chat := ChatUI.new()
	chat.name = "ChatApp"
	_add_canvas_layer_app(chat)

func _open_hope() -> void:
	var Hope = AutoloadGate.get_node("Hope")
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "💛 Hope"
	header.add_theme_font_size_override("font_size", 20)
	root.add_child(header)

	if Hope == null:
		var err := Label.new()
		err.text = "Hope is not awake."
		root.add_child(err)
		_open_app_panel("Hope", root)
		return

	var stage = Hope.stage()
	var stage_lbl := Label.new()
	stage_lbl.text = "%s (bond %d)" % [stage.get("name", "Flicker"), Hope.bond]
	stage_lbl.add_theme_font_size_override("font_size", 16)
	root.add_child(stage_lbl)

	var desc := Label.new()
	desc.text = str(stage.get("desc", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(0.85, 0.8, 0.6)
	root.add_child(desc)

	var axes := Label.new()
	axes.text = "Aggression %.0f%% · Caution %.0f%% · Curiosity %.0f%% · Greed %.0f%%" % [
		Hope.profile.aggression * 100, Hope.profile.caution * 100,
		Hope.profile.curiosity * 100, Hope.profile.greed * 100]
	axes.add_theme_font_size_override("font_size", 12)
	axes.modulate = Color(0.7, 0.75, 0.85)
	root.add_child(axes)

	var care_row := HBoxContainer.new()
	care_row.alignment = BoxContainer.ALIGNMENT_CENTER
	care_row.add_theme_constant_override("separation", 8)
	root.add_child(care_row)

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
			var NotificationUI = AutoloadGate.get_node("NotificationUI")
			Hope.gain_bond(5, "care_%s" % drive)
			var current: float = float(Hope.profile.get(drive, 0.0))
			Hope.profile[drive] = clampf(current + delta * 0.05, 0.0, 1.0)
			NotificationUI.notify_info("Hope %s. Bond +5." % str(care.label).to_lower()))
		care_row.add_child(btn)

	var synergy_title := Label.new()
	synergy_title.text = "Synergies"
	synergy_title.add_theme_font_size_override("font_size", 15)
	root.add_child(synergy_title)

	for line in Hope.synergy_lines():
		var line_lbl := Label.new()
		line_lbl.text = "• %s" % line.get("name", "Unknown")
		line_lbl.add_theme_font_size_override("font_size", 13)
		root.add_child(line_lbl)

	_open_app_panel("Hope", root)

func _open_casino() -> void:
	var lobby := GameLobbyUI.new()
	_open_app_panel("Paws Vegas", lobby)

func _open_subliminal() -> void:
	var LayerManager = AutoloadGate.get_node("LayerManager")
	_close_active_app()
	if LayerManager != null:
		LayerManager.transition_to("subliminal")

func _open_periliminal() -> void:
	var PartyManager = AutoloadGate.get_node("PartyManager")
	var PeriliminalRuns = AutoloadGate.get_node("PeriliminalRuns")
	var LayerManager = AutoloadGate.get_node("LayerManager")
	_close_active_app()
	var members: Array[String] = []
	if PartyManager != null:
		members = PartyManager.members()
	else:
		members = ["local_player"]
	if PeriliminalRuns != null:
		PeriliminalRuns.begin_run(members)
	if LayerManager != null:
		LayerManager.transition_to("periliminal", true)

func _open_settings() -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	if ResourceLoader.exists("res://scenes/ui/settings.tscn"):
		get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")
	else:
		NotificationUI.notify_error("Settings app is not installed.")

func _open_guild() -> void:
	var GuildManager = AutoloadGate.get_node("GuildManager")
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "🏰 Guild"
	header.add_theme_font_size_override("font_size", 20)
	root.add_child(header)

	if GuildManager != null and GuildManager.in_guild():
		var g: Dictionary = GuildManager.guild
		var name_lbl := Label.new()
		name_lbl.text = "%s [%s]" % [g.get("name", ""), g.get("tag", "")]
		name_lbl.add_theme_font_size_override("font_size", 16)
		root.add_child(name_lbl)

		var motd := Label.new()
		motd.text = "MOTD: %s" % g.get("motd", "No message set.")
		motd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		motd.modulate = Color(0.75, 0.75, 0.85)
		root.add_child(motd)

		var members_title := Label.new()
		members_title.text = "Members"
		members_title.add_theme_font_size_override("font_size", 15)
		root.add_child(members_title)

		var members: Dictionary = g.get("members", {})
		for member_id in members.keys():
			var rank_idx: int = int(members.get(member_id, 0))
			var ranks: Array = g.get("ranks", ["Recruit"])
			var rank: String = ranks[clampi(rank_idx, 0, ranks.size() - 1)] if ranks.size() > 0 else "Recruit"
			var row := HBoxContainer.new()
			var lbl := Label.new()
			lbl.text = "%s — %s" % [member_id, rank]
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lbl)
			root.add_child(row)

		var leave_btn := Button.new()
		leave_btn.text = "Leave Guild"
		leave_btn.pressed.connect(func():
			var NotificationUI = AutoloadGate.get_node("NotificationUI")
			if GuildManager != null and GuildManager.has_method("disband"):
				GuildManager.disband()
				NotificationUI.notify_info("You left the guild.")
				_close_active_app()
				_open_guild())
		root.add_child(leave_btn)
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
			var NotificationUI = AutoloadGate.get_node("NotificationUI")
			if GuildManager != null and GuildManager.has_method("create_guild"):
				var ok = await GuildManager.create_guild(name_input.text.strip_edges(), tag_input.text.strip_edges())
				if ok:
					NotificationUI.notify_win("Guild chartered!")
					_close_active_app()
					_open_guild()
				else:
					NotificationUI.notify_error("Could not charter guild.")
			else:
				NotificationUI.notify_error("Guild system offline."))
		create_row.add_child(create_btn)
		root.add_child(create_row)

		var join_row := HBoxContainer.new()
		var join_input := LineEdit.new()
		join_input.placeholder_text = "Invite code from a guild officer"
		join_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		join_row.add_child(join_input)
		var join_btn := Button.new()
		join_btn.text = "Join"
		join_btn.pressed.connect(func():
			var NotificationUI = AutoloadGate.get_node("NotificationUI")
			# Local guild invites are handled through SubliminalManager invite codes or direct officer invites.
			NotificationUI.notify_info("Invite codes are shared by guild officers. Create your own guild if you do not have one."))
		join_row.add_child(join_btn)
		root.add_child(join_row)

	_open_app_panel("Guild", root)

func _load_scene_instance(path: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	return packed.instantiate()

func _open_leaderboard() -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	var lb := _load_scene_instance("res://scenes/ui/leaderboard.tscn") as Control
	if lb == null:
		NotificationUI.notify_error("Leaderboard unavailable.")
		return
	_open_app_panel("Leaderboard", lb)

func _open_quests() -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	var qu := _load_scene_instance("res://scenes/ui/quest.tscn") as Control
	if qu == null:
		NotificationUI.notify_error("Quest log unavailable.")
		return
	_open_app_panel("Quests", qu)

func _open_daily() -> void:
	var daily := DailyRewardPopup.new()
	daily.name = "DailyRewardApp"
	_close_active_app()
	_content.add_child(daily)
	_active_app = daily
	app_opened.emit("daily")

func _open_calendar() -> void:
	var LiveOpsManager = AutoloadGate.get_node("LiveOpsManager")
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "📅 Calendar"
	header.add_theme_font_size_override("font_size", 20)
	root.add_child(header)

	var now := Time.get_datetime_dict_from_system()
	var date_lbl := Label.new()
	date_lbl.text = "Server day: %04d-%02d-%02d" % [now.year, now.month, now.day]
	date_lbl.modulate = Color(0.75, 0.75, 0.85)
	root.add_child(date_lbl)

	var events_title := Label.new()
	events_title.text = "Active Events"
	events_title.add_theme_font_size_override("font_size", 15)
	root.add_child(events_title)

	if LiveOpsManager != null and LiveOpsManager.has_method("get_active_events"):
		var events: Array = LiveOpsManager.get_active_events()
		if events.is_empty():
			var none := Label.new()
			none.text = "No active events."
			none.modulate = Color(0.65, 0.65, 0.65)
			root.add_child(none)
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
				root.add_child(row)
	else:
		var offline := Label.new()
		offline.text = "LiveOps offline."
		offline.modulate = Color(0.65, 0.65, 0.65)
		root.add_child(offline)

	_open_app_panel("Calendar", root)

func _open_battlepass() -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	var bp := _load_scene_instance("res://scenes/ui/battlepass.tscn") as Control
	if bp == null:
		NotificationUI.notify_error("Battle Pass unavailable.")
		return
	_open_app_panel("Battle Pass", bp)

func _open_shop() -> void:
	var shop := ShopUI.new()
	_open_app_panel("Shop", shop)
