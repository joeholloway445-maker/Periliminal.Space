class_name ExtraliminalLayer
extends CanvasLayer
## Pokémon GO-style overlay layer. The player views a GPS-map of the area
## with 8 landmarks as pulsing POI markers. Walk (WASD / touch-drag) to a
## landmark → explore → encounter a wild entity → fight → capture chance.
## Guilds claim landmarks as halls; guild wars open a liminal door portal
## on the map.

# ── Landmark catalog ───────────────────────────────────────────────────────
const LANDMARK_NAMES: Dictionary = {
	"lm_fountain":       "Neon Fountain",
	"lm_old_bridge":     "Old Trinity Bridge",
	"lm_water_tower":    "Rusted Water Tower",
	"lm_drive_in":       "Abandoned Drive-In",
	"lm_grain_silo":     "Twin Grain Silos",
	"lm_stockyard_gate": "Stockyard Gate",
	"lm_planetarium":    "Planetarium Dome",
	"lm_ferris_wheel":   "Fairgrounds Ferris Wheel",
}

## Map pixel positions for each landmark (centered in a 600×800 area).
const LANDMARK_POS: Dictionary = {
	"lm_fountain":       Vector2(180.0,  200.0),
	"lm_old_bridge":     Vector2(480.0,  120.0),
	"lm_water_tower":    Vector2(130.0,  550.0),
	"lm_drive_in":       Vector2(530.0,  350.0),
	"lm_grain_silo":     Vector2( 70.0,  350.0),
	"lm_stockyard_gate": Vector2(320.0,  700.0),
	"lm_planetarium":    Vector2(250.0,  450.0),
	"lm_ferris_wheel":   Vector2(450.0,  580.0),
}

# ── Nodes ──────────────────────────────────────────────────────────────────
var _map_root: Control        # full-screen map container
var _player_dot: ColorRect    # the player marker
var _player_map_pos := Vector2(300.0, 400.0)  # pixel position on map
var _landmark_markers: Dictionary = {}  # landmark_id -> {control, label, pulse}
var _info_panel: Control      # tapped-landmark detail panel
var _encounter_active := false
var _current_entity: Dictionary = {}  # the roaming entity data for fight
var _current_lid: String = ""
var _just_won_at: String = ""  # landmark id where the player most recently won a fight
var _phone: PhoneHomeScreen
var _phone_toggle: Button

# ── Init ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	var LayerManager = AutoloadGate.get_node("LayerManager")
	var ExtraliminalManager = AutoloadGate.get_node("ExtraliminalManager")
	LayerManager.current_layer_id = "extraliminal"
	layer = 10

	_build_map_background()
	_build_landmark_markers()
	_build_player_dot()
	_build_info_panel()
	_build_phone_home_screen()
	_build_phone_toggle()

	# Connect to ExtraliminalManager signals
	ExtraliminalManager.landmark_claimed.connect(_on_landmark_claimed)
	ExtraliminalManager.guild_war_started.connect(_on_war_started)
	ExtraliminalManager.guild_war_resolved.connect(_on_war_resolved)

	set_process(true)
	set_process_input(true)

func _build_map_background() -> void:
	## Full-screen dark map with neon grid lines (GPS-app aesthetic).
	_map_root = Control.new()
	_map_root.name = "MapRoot"
	_map_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_map_root)

	# Dark background
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_root.add_child(bg)

	# Fog overlay — vignette
	var vignette := ColorRect.new()
	vignette.color = Color(0.0, 0.0, 0.0, 0.3)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_root.add_child(vignette)

	# Grid lines every 80px (subtle neon)
	var screen_size := get_viewport().get_visible_rect().size
	for x in range(0, int(screen_size.x) + 80, 80):
		var line := ColorRect.new()
		line.color = Color(0.15, 0.12, 0.25, 0.25)
		line.size = Vector2(1, screen_size.y)
		line.position = Vector2(x, 0)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_map_root.add_child(line)
	for y in range(0, int(screen_size.y) + 80, 80):
		var line := ColorRect.new()
		line.color = Color(0.15, 0.12, 0.25, 0.25)
		line.size = Vector2(screen_size.x, 1)
		line.position = Vector2(0, y)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_map_root.add_child(line)

	# Title
	var title := Label.new()
	title.text = "EXTRALIMINAL — THE OVERLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.75, 0.35, 0.95, 0.7)
	title.position = Vector2(0, 10)
	title.size = Vector2(screen_size.x, 30)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_root.add_child(title)

func _build_landmark_markers() -> void:
	var ExtraliminalManager = AutoloadGate.get_node("ExtraliminalManager")
	## Pulse-icon marker for each landmark, clickable.
	for lm_data in ExtraliminalManager.LANDMARKS:
		var lm: Dictionary = lm_data
		var lid: String = str(lm.get("id", ""))
		if lid.is_empty():
			continue
		var lname: String = str(LANDMARK_NAMES.get(lid, lm.get("name", lid)))
		var pos: Vector2 = LANDMARK_POS.get(lid, Vector2(300, 400))

		# Container (hit area)
		var ctr := Control.new()
		ctr.name = "LM_%s" % lid
		ctr.position = pos - Vector2(24, 24)
		ctr.size = Vector2(48, 48)
		ctr.mouse_filter = Control.MOUSE_FILTER_STOP
		_map_root.add_child(ctr)

		# Icon — a glowing ring
		var ring := ColorRect.new()
		ring.name = "Ring"
		ring.color = Color(0.8, 0.5, 1.0, 0.6)
		ring.size = Vector2(36, 36)
		ring.position = Vector2(6, 6)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctr.add_child(ring)

		# Inner dot
		var dot := ColorRect.new()
		dot.color = Color(0.95, 0.85, 0.6, 0.9)
		dot.size = Vector2(12, 12)
		dot.position = Vector2(18, 18)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctr.add_child(dot)

		# Label below
		var label := Label.new()
		label.text = lname
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.modulate = Color(0.85, 0.85, 0.9, 0.7)
		label.position = Vector2(-30, 50)
		label.size = Vector2(108, 20)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctr.add_child(label)

		# Claim badge (hidden until claimed)
		var badge := ColorRect.new()
		badge.name = "Badge"
		badge.color = Color(0.75, 0.35, 0.95, 0.7)
		badge.size = Vector2(8, 8)
		badge.position = Vector2(40, 4)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.visible = false
		ctr.add_child(badge)

		# War portal icon (hidden until war active)
		var war_icon := Label.new()
		war_icon.name = "WarIcon"
		war_icon.text = "⚔"
		war_icon.add_theme_font_size_override("font_size", 24)
		war_icon.modulate = Color(1.0, 0.2, 0.2, 0.0)  # zero alpha until visible
		war_icon.position = Vector2(44, -12)
		war_icon.size = Vector2(30, 30)
		war_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctr.add_child(war_icon)

		# Click to explore
		ctr.gui_input.connect(_on_landmark_tap.bind(lid))

		_landmark_markers[lid] = {
			"ctr": ctr,
			"ring": ring,
			"label": label,
			"badge": badge,
			"war_icon": war_icon,
			"pos": pos,
		}

func _build_player_dot() -> void:
	## Your GPS marker — WASD moves it around the map.
	_player_dot = ColorRect.new()
	_player_dot.name = "PlayerDot"
	_player_dot.color = Color(0.3, 0.85, 1.0, 0.95)
	_player_dot.size = Vector2(14, 14)
	_player_dot.position = _player_map_pos - Vector2(7, 7)
	_player_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_root.add_child(_player_dot)

	# Outer ring
	var ring := ColorRect.new()
	ring.name = "PlayerRing"
	ring.color = Color(0.3, 0.85, 1.0, 0.2)
	ring.size = Vector2(32, 32)
	ring.position = _player_map_pos - Vector2(16, 16) - Vector2(1, 1)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_root.add_child(ring)

func _build_info_panel() -> void:
	## Bottom panel shown when a landmark is tapped.
	_info_panel = Control.new()
	_info_panel.name = "InfoPanel"
	var screen_size := get_viewport().get_visible_rect().size
	_info_panel.position = Vector2(0, screen_size.y)
	_info_panel.size = Vector2(screen_size.x, 0)
	_info_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_info_panel.visible = false
	_map_root.add_child(_info_panel)

	# Background
	var bg := ColorRect.new()
	bg.name = "InfoBG"
	bg.color = Color(0.08, 0.08, 0.15, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_child(bg)

	# Entity name
	var name_label := Label.new()
	name_label.name = "EntityName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.modulate = Color(0.95, 0.85, 0.6)
	name_label.position = Vector2(0, 20)
	name_label.size = Vector2(_info_panel.size.x, 40)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_child(name_label)

	# Rarity / stage info
	var info_label := Label.new()
	info_label.name = "InfoText"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.modulate = Color(0.7, 0.7, 0.8)
	info_label.position = Vector2(0, 60)
	info_label.size = Vector2(_info_panel.size.x, 30)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_child(info_label)

	# Fight button
	var fight := Button.new()
	fight.name = "FightBtn"
	fight.text = "⚔ FIGHT"
	fight.custom_minimum_size = Vector2(200, 50)
	fight.position = Vector2(_info_panel.size.x * 0.5 - 100, 110)
	fight.add_theme_font_size_override("font_size", 20)
	fight.pressed.connect(_on_fight)
	_info_panel.add_child(fight)

	# Claim button (hidden until player wins a fight here)
	var claim := Button.new()
	claim.name = "ClaimBtn"
	claim.text = "🏴 CLAIM LANDMARK"
	claim.custom_minimum_size = Vector2(200, 50)
	claim.position = Vector2(_info_panel.size.x * 0.5 - 100, 110)
	claim.add_theme_font_size_override("font_size", 18)
	claim.modulate = Color(1.0, 0.85, 0.4)
	claim.pressed.connect(_on_claim_landmark)
	claim.visible = false
	_info_panel.add_child(claim)

	# Close button
	var close := Button.new()
	close.name = "CloseBtn"
	close.text = "X"
	close.custom_minimum_size = Vector2(36, 36)
	close.position = Vector2(_info_panel.size.x - 44, 8)
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(_close_info)
	_info_panel.add_child(close)

func _build_phone_home_screen() -> void:
	## GTA-style phone overlay — this IS the Extraliminal UI.
	_phone = PhoneHomeScreen.new()
	_phone.name = "PhoneHomeScreen"
	_phone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_phone.app_opened.connect(_on_phone_app_opened)
	add_child(_phone)

func _build_phone_toggle() -> void:
	## Floating button to bring the phone back up when hidden.
	_phone_toggle = Button.new()
	_phone_toggle.name = "PhoneToggle"
	_phone_toggle.text = "📱"
	_phone_toggle.custom_minimum_size = Vector2(48, 48)
	_phone_toggle.position = Vector2(get_viewport().get_visible_rect().size.x - 64, 16)
	_phone_toggle.add_theme_font_size_override("font_size", 22)
	_phone_toggle.pressed.connect(_show_phone)
	_map_root.add_child(_phone_toggle)

func _show_phone() -> void:
	_phone.visible = true
	_phone_toggle.visible = false

func _hide_phone() -> void:
	_phone.visible = false
	_phone_toggle.visible = true

func _on_phone_app_opened(app_id: String) -> void:
	if app_id == "map":
		_hide_phone()
	elif app_id == "periliminal":
		# The phone already triggers the transition; just hide the UI.
		_hide_phone()

# ── Input — WASD moves the player dot on the map ──────────────────────────
func _input(event: InputEvent) -> void:
	if _encounter_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var screen_size := get_viewport().get_visible_rect().size
		match event.keycode:
			KEY_W, KEY_UP:
				_player_map_pos.y = maxf(_player_map_pos.y - 12, 20.0)
			KEY_S, KEY_DOWN:
				_player_map_pos.y = minf(_player_map_pos.y + 12, screen_size.y - 20)
			KEY_A, KEY_LEFT:
				_player_map_pos.x = maxf(_player_map_pos.x - 12, 20.0)
			KEY_D, KEY_RIGHT:
				_player_map_pos.x = minf(_player_map_pos.x + 12, screen_size.x - 20)
		_update_player_dot()

	# Touch-drag to move player (mobile style)
	if event is InputEventScreenDrag:
		var touch_pos: Vector2 = event.position
		_player_map_pos = touch_pos
		_update_player_dot()

# ── Update ─────────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	_animate_pulses()
	_check_proximity()

func _update_player_dot() -> void:
	_player_dot.position = _player_map_pos - Vector2(7, 7)
	# Find and move the ring
	for c in _map_root.get_children():
		if c is ColorRect and c.name == "PlayerRing":
			c.position = _player_map_pos - Vector2(16, 16) - Vector2(1, 1)
			break

var _pulse_time := 0.0
var _encounter_flash: ColorRect = null

func _animate_pulses() -> void:
	_pulse_time += 0.04
	var pulse := 0.6 + sin(_pulse_time) * 0.25
	for lid in _landmark_markers.keys():
		var m: Dictionary = _landmark_markers[lid]
		var ring := m["ring"] as ColorRect
		if ring == null:
			continue
		ring.modulate = Color(0.8, 0.5, 1.0, pulse)

func _check_proximity() -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	## Auto-hint when player is near a landmark.
	if _info_panel.visible or _encounter_active:
		return
	for lid in LANDMARK_POS.keys():
		var dist := _player_map_pos.distance_to(LANDMARK_POS[lid])
		if dist < 40.0:
			NotificationUI.notify_info("📌 %s is near — tap it to explore." % LANDMARK_NAMES.get(lid, lid))
			return

# ── Landmark interaction ───────────────────────────────────────────────────
func _on_landmark_tap(event: InputEvent, lid: String) -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _encounter_active:
		return

	# Check proximity — must be within 60px of the landmark to interact
	var dist := _player_map_pos.distance_to(LANDMARK_POS[lid])
	if dist > 60.0:
		NotificationUI.notify_info("Too far — walk closer to %s." % LANDMARK_NAMES.get(lid, lid))
		return

	_current_lid = lid
	_show_landmark_info(lid)

func _show_landmark_info(lid: String) -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	var ExtraliminalManager = AutoloadGate.get_node("ExtraliminalManager")
	## Slide up the info panel with encounter / claim options.
	var lname: String = LANDMARK_NAMES.get(lid, lid)
	var owner = ExtraliminalManager.landmark_owner(lid)
	var guild := _my_guild()

	# Spawn a roaming entity for this landmark
	var entity = ExtraliminalManager.spawn_wild_entity(lid)
	if entity.is_empty():
		NotificationUI.notify_info("Nothing stirs at %s right now." % lname)
		return

	_current_entity = entity

	_info_panel.visible = true
	var screen_size := get_viewport().get_visible_rect().size
	_info_panel.size = Vector2(screen_size.x, 180)
	_info_panel.position = Vector2(0, screen_size.y - 180)

	var name_lbl := _info_panel.get_node("EntityName") as Label
	var info_lbl := _info_panel.get_node("InfoText") as Label
	var fight_btn := _info_panel.get_node("FightBtn") as Button
	var close_btn := _info_panel.get_node("CloseBtn") as Button

	if name_lbl == null or info_lbl == null or fight_btn == null:
		return

	var ent_name: String = str(entity.get("name", "???"))
	var ent_rarity: int = int(entity.get("rarity", 1))
	var stage: int = randi() % 2 + 1
	var rarity_blocks: Array[String] = ["⬜", "🟩", "🟦", "🟪", "🟧"]
	var rarity_label: String = rarity_blocks[clampi(ent_rarity - 1, 0, 4)]
	var owner_str := " — [%s]" % owner if owner != "" else ""
	name_lbl.text = "%s %s  —  %s%s" % [rarity_label, ent_name, lname, owner_str]
	info_lbl.text = "Stage %d  •  %s" % [stage, _category_string(entity)]

	fight_btn.text = "⚔ FIGHT"
	fight_btn.disabled = false

	# Show claim button if player just won here
	var claim_btn := _info_panel.get_node("ClaimBtn") as Button
	if claim_btn != null:
		if owner == "" and guild != "" and _just_won_at == lid:
			claim_btn.visible = true
			fight_btn.visible = false
		else:
			claim_btn.visible = false

func _category_string(entity: Dictionary) -> String:
	var cat := str(entity.get("category", ""))
	match cat:
		"Matter": return "🧱 Material Entity"
		"Energy": return "⚡ Energy Entity"
		"Essence": return "🌀 Essence Entity"
		_: return "Wild Entity"

func _on_claim_landmark() -> void:
	var EconomyManager = AutoloadGate.get_node("EconomyManager")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	var ExtraliminalManager = AutoloadGate.get_node("ExtraliminalManager")
	## Claim the current landmark for the player's guild.
	if _current_lid.is_empty():
		return
	var guild := _my_guild()
	if guild.is_empty():
		NotificationUI.notify_error("You need a guild to claim a landmark.")
		return
	var ok = ExtraliminalManager.claim_landmark(_current_lid, guild)
	if ok:
		NotificationUI.notify_win("🏴 %s claimed for %s!" % [LANDMARK_NAMES.get(_current_lid, _current_lid), guild])
		# Reward: prestige + tokens for the claim (territory PvP resource)
		EconomyManager.earn_currency("prestige", 15, "extraliminal_landmark_claim")
		EconomyManager.earn_currency("tokens", 10, "extraliminal_landmark_claim")
		_just_won_at = ""
	else:
		NotificationUI.notify_error("Someone already claimed this landmark.")
	_close_info()

func _close_info() -> void:
	_info_panel.visible = false
	var screen_size := get_viewport().get_visible_rect().size
	_info_panel.position = Vector2(0, screen_size.y)
	_info_panel.size = Vector2(screen_size.x, 0)
	_current_entity = {}
	_current_lid = ""

func _on_fight() -> void:
	## Start the Pokémon GO-style encounter with battle UI.
	if _current_entity.is_empty():
		return

	_encounter_active = true
	var entity: Dictionary = _current_entity.duplicate()
	var lid: String = _current_lid
	_close_info()  # hide the landmark info panel
	_current_entity = entity  # restore after close_info clears it
	_current_lid = lid  # restore lid
	_show_encounter_screen()

func _show_encounter_screen() -> void:
	var PlayerProfile = AutoloadGate.get_node("PlayerProfile")
	## Build (or show) the battle overlay.
	if _encounter_root == null:
		_build_encounter_ui()

	var entity: Dictionary = _current_entity
	var ent_name: String = str(entity.get("name", "entity"))
	var ent_rarity: int = int(entity.get("rarity", 1))
	var cat: String = str(entity.get("category", "Energy"))

	# Reset encounter state
	_encounter_entity_hp = 30 + ent_rarity * 8 + randi() % 10
	_encounter_entity_max_hp = _encounter_entity_hp
	_encounter_player_hp = 80 + PlayerProfile.level * 2
	_encounter_player_max_hp = _encounter_player_hp
	_encounter_player_ap = 8 + PlayerProfile.level * 2
	_encounter_stage = randi() % 2 + 1
	_encounter_doing_animation = false

	# Update labels
	var e_name: Label = _encounter_root.get_node("EntityName") as Label
	var e_hp: Label = _encounter_root.get_node("EntityHP") as Label
	var e_bar: TextureProgressBar = _encounter_root.get_node("EntityHPBar") as TextureProgressBar
	var p_name: Label = _encounter_root.get_node("PlayerName") as Label
	var p_hp: Label = _encounter_root.get_node("PlayerHP") as Label
	var p_bar: TextureProgressBar = _encounter_root.get_node("PlayerHPBar") as TextureProgressBar
	var status: Label = _encounter_root.get_node("StatusText") as Label
	var sprite_rect: ColorRect = _encounter_root.get_node("EntitySprite") as ColorRect

	if e_name:   e_name.text = "%s  Stage %d" % [ent_name, _encounter_stage]
	if e_hp:     e_hp.text = "HP %d/%d" % [_encounter_entity_hp, _encounter_entity_max_hp]
	if e_bar:    e_bar.max_value = _encounter_entity_max_hp; e_bar.value = _encounter_entity_hp
	if p_name:   p_name.text = "YOU  Lv.%d" % PlayerProfile.level
	if p_hp:     p_hp.text = "HP %d/%d" % [_encounter_player_hp, _encounter_player_max_hp]
	if p_bar:    p_bar.max_value = _encounter_player_max_hp; p_bar.value = _encounter_player_hp
	if status:   status.text = "A wild %s appears!" % ent_name
	if sprite_rect:
		# Color the entity sprite based on category
		match cat:
			"Matter":   sprite_rect.color = Color(0.6, 0.35, 0.2)
			"Energy":   sprite_rect.color = Color(0.3, 0.6, 0.9)
			"Essence":  sprite_rect.color = Color(0.7, 0.3, 0.8)
			_:          sprite_rect.color = Color(0.5, 0.5, 0.5)

	_encounter_root.visible = true

func _build_encounter_ui() -> void:
	## Create the full battle screen overlay.
	_encounter_root = Control.new()
	_encounter_root.name = "EncounterScreen"
	_encounter_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_encounter_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_encounter_root.visible = false
	_map_root.add_child(_encounter_root)

	var screen_size := get_viewport().get_visible_rect().size

	# Dark backdrop
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.06, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encounter_root.add_child(bg)

	# ── Entity area (top half) ──────────────────────────────────────────────
	# Entity "sprite" — big colored rectangle (placeholder for actual art)
	var sprite := ColorRect.new()
	sprite.name = "EntitySprite"
	sprite.size = Vector2(120, 120)
	sprite.position = Vector2(screen_size.x * 0.5 - 60, 60)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encounter_root.add_child(sprite)

	# Entity name
	var e_name := Label.new()
	e_name.name = "EntityName"
	e_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_name.add_theme_font_size_override("font_size", 22)
	e_name.modulate = Color(0.95, 0.85, 0.6)
	e_name.position = Vector2(0, 200)
	e_name.size = Vector2(screen_size.x, 30)
	e_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encounter_root.add_child(e_name)

	# Entity HP bar
	var e_bar := TextureProgressBar.new()
	e_bar.name = "EntityHPBar"
	e_bar.position = Vector2(screen_size.x * 0.15, 240)
	e_bar.size = Vector2(screen_size.x * 0.7, 18)
	e_bar.fill_mode = 0  # left-to-right
	e_bar.tint_under = Color(0.15, 0.05, 0.05)
	e_bar.tint_progress = Color(0.9, 0.15, 0.15)
	e_bar.modulate = Color(0.9, 0.9, 0.9)
	e_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encounter_root.add_child(e_bar)

	# Entity HP text
	var e_hp := Label.new()
	e_hp.name = "EntityHP"
	e_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_hp.add_theme_font_size_override("font_size", 14)
	e_hp.modulate = Color(0.85, 0.85, 0.85)
	e_hp.position = Vector2(0, 258)
	e_hp.size = Vector2(screen_size.x, 20)
	e_hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encounter_root.add_child(e_hp)

	# ── Status text (middle) ───────────────────────────────────────────────
	var status := Label.new()
	status.name = "StatusText"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 18)
	status.modulate = Color(1.0, 1.0, 1.0, 0.8)
	status.position = Vector2(0, screen_size.y * 0.38)
	status.size = Vector2(screen_size.x, 30)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encounter_root.add_child(status)

	# ── Player area (bottom third) ──────────────────────────────────────────
	# Player name
	var p_name := Label.new()
	p_name.name = "PlayerName"
	p_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_name.add_theme_font_size_override("font_size", 18)
	p_name.modulate = Color(0.3, 0.85, 1.0)
	p_name.position = Vector2(0, screen_size.y * 0.55)
	p_name.size = Vector2(screen_size.x, 24)
	p_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encounter_root.add_child(p_name)

	# Player HP bar
	var p_bar := TextureProgressBar.new()
	p_bar.name = "PlayerHPBar"
	p_bar.position = Vector2(screen_size.x * 0.15, screen_size.y * 0.55 + 28)
	p_bar.size = Vector2(screen_size.x * 0.7, 18)
	p_bar.fill_mode = 0
	p_bar.tint_under = Color(0.05, 0.05, 0.15)
	p_bar.tint_progress = Color(0.15, 0.7, 0.9)
	p_bar.modulate = Color(0.9, 0.9, 0.9)
	p_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encounter_root.add_child(p_bar)

	# Player HP text
	var p_hp := Label.new()
	p_hp.name = "PlayerHP"
	p_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_hp.add_theme_font_size_override("font_size", 14)
	p_hp.modulate = Color(0.85, 0.85, 0.85)
	p_hp.position = Vector2(0, screen_size.y * 0.55 + 46)
	p_hp.size = Vector2(screen_size.x, 20)
	p_hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encounter_root.add_child(p_hp)

	# ── Buttons ─────────────────────────────────────────────────────────────
	# ATTACK button (big, center)
	var attack_btn := Button.new()
	attack_btn.name = "AttackBtn"
	attack_btn.text = "⚔ ATTACK"
	attack_btn.custom_minimum_size = Vector2(180, 56)
	attack_btn.position = Vector2(screen_size.x * 0.5 - 90, screen_size.y * 0.7)
	attack_btn.add_theme_font_size_override("font_size", 22)
	attack_btn.pressed.connect(_on_encounter_attack)
	_encounter_root.add_child(attack_btn)

	# FLEE button
	var flee_btn := Button.new()
	flee_btn.name = "FleeBtn"
	flee_btn.text = "🏃 FLEE"
	flee_btn.custom_minimum_size = Vector2(120, 40)
	flee_btn.position = Vector2(screen_size.x * 0.5 - 60, screen_size.y * 0.7 + 70)
	flee_btn.add_theme_font_size_override("font_size", 16)
	flee_btn.modulate = Color(0.7, 0.7, 0.7)
	flee_btn.pressed.connect(_on_encounter_flee)
	_encounter_root.add_child(flee_btn)

# ── Encounter battle state ────────────────────────────────────────────────
var _encounter_root: Control = null
var _encounter_entity_hp := 40
var _encounter_entity_max_hp := 40
var _encounter_player_hp := 100
var _encounter_player_max_hp := 100
var _encounter_player_ap := 10
var _encounter_stage := 1
var _encounter_doing_animation := false

func _on_encounter_attack() -> void:
	var PlayerProfile = AutoloadGate.get_node("PlayerProfile")
	## Player taps ATTACK — deal damage, then entity retaliates.
	if _encounter_doing_animation:
		return
	_encounter_doing_animation = true

	# Disable buttons during the exchange
	_set_encounter_buttons_disabled(true)

	# ── Player attacks first ──
	var dmg := clampi(_encounter_player_ap + randi() % 6 - 3, 1, 99)
	_encounter_entity_hp = maxi(_encounter_entity_hp - dmg, 0)
	_flash_overlay(Color(0.9, 0.6, 0.2, 0.25))
	_set_status_text("You strike for %d damage!" % dmg)
	_update_encounter_bars()
	await get_tree().create_timer(0.6).timeout

	if _encounter_entity_hp <= 0:
		_on_encounter_won()
		return

	# ── Entity retaliates ──
	var e_dmg := clampi(int(_encounter_stage * 5 + PlayerProfile.level * 0.5 + randi() % 4 - 2), 1, 50)
	_encounter_player_hp = maxi(_encounter_player_hp - e_dmg, 0)
	_flash_overlay(Color(0.8, 0.15, 0.15, 0.2))
	_set_status_text("The entity strikes back for %d damage!" % e_dmg)
	_update_encounter_bars()
	await get_tree().create_timer(0.6).timeout

	if _encounter_player_hp <= 0:
		_on_encounter_lost()
		return

	_set_encounter_buttons_disabled(false)
	_encounter_doing_animation = false

func _on_encounter_flee() -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	## Player flees the encounter.
	_encounter_doing_animation = true
	_set_status_text("You fled the encounter!")
	_flash_overlay(Color(0.3, 0.3, 0.5, 0.3))
	await get_tree().create_timer(0.8).timeout
	_hide_encounter_screen()
	NotificationUI.notify_info("You retreated safely.")
	_end_encounter()

func _on_encounter_won() -> void:
	var EconomyManager = AutoloadGate.get_node("EconomyManager")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	_set_status_text("✦ Defeated! Attempting bond...")
	_flash_overlay(Color(0.9, 0.8, 0.3, 0.35))
	await get_tree().create_timer(1.0).timeout

	var entity: Dictionary = _current_entity
	var ent_name: String = str(entity.get("name", "entity"))
	var ent_rarity: int = int(entity.get("rarity", 1))

	# Capture roll via CaptureSystem
	var capture_system := get_node_or_null("/root/CaptureSystem")
	var captured := false
	if capture_system != null and capture_system.has_method("attempt_capture"):
		captured = await capture_system.call("attempt_capture", entity)

	if captured:
		_set_status_text("✦ %s bonded with you!" % ent_name)
		_flash_overlay(Color(0.3, 0.9, 0.3, 0.3))
		NotificationUI.notify_win("✦ %s bonded with you!" % ent_name)
		EconomyManager.earn_currency("prestige", ent_rarity * 3, "extraliminal_bond")
	else:
		_set_status_text("Bond failed — %s retreats. Try again!" % ent_name)
		NotificationUI.notify_info("%s defeated but not yet bonded. Hope tilts fate next time." % ent_name)

	EconomyManager.earn_currency("fragments", 5 + ent_rarity * 2, "extraliminal_encounter")
	EconomyManager.earn_currency("cat_coins", 10 + ent_rarity * 5, "extraliminal_encounter")
	EconomyManager.earn_currency("prestige", 2 + ent_rarity * 2, "extraliminal_encounter")

	await get_tree().create_timer(1.5).timeout

	# Mark for claim — next time the player taps this landmark show CLAIM
	if _current_lid != "" and captured:
		_just_won_at = _current_lid

	_hide_encounter_screen()
	_end_encounter()

func _on_encounter_lost() -> void:
	var EconomyManager = AutoloadGate.get_node("EconomyManager")
	var PlayerProfile = AutoloadGate.get_node("PlayerProfile")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	_set_status_text("💀 You collapsed! Returning to the map...")
	_flash_overlay(Color(0.8, 0.05, 0.05, 0.4))
	PlayerProfile.health = maxi(PlayerProfile.health - 15, 0)
	NotificationUI.notify_error("The entity overwhelmed you.")
	# Token cost to respawn at the landmark
	var revive_cost := 5
	if EconomyManager.get_balance("cat_coins") >= revive_cost:
		EconomyManager.spend_currency_local("cat_coins", revive_cost, "extraliminal_revive")
		NotificationUI.notify_info("Lost %d coins — you revive at the landscape below." % revive_cost)
	else:
		NotificationUI.notify_info("You have no coins to spare — return when you have some.")

	await get_tree().create_timer(1.5).timeout
	_hide_encounter_screen()
	_end_encounter()
	PlayerProfile.health -= 5

func _set_status_text(text: String) -> void:
	var status := _encounter_root.get_node("StatusText") as Label
	if status != null:
		status.text = text

func _set_encounter_buttons_disabled(disabled: bool) -> void:
	var atk := _encounter_root.get_node("AttackBtn") as Button
	var flee := _encounter_root.get_node("FleeBtn") as Button
	if atk:  atk.disabled = disabled
	if flee: flee.disabled = disabled

func _update_encounter_bars() -> void:
	var e_hp := _encounter_root.get_node("EntityHP") as Label
	var e_bar := _encounter_root.get_node("EntityHPBar") as TextureProgressBar
	var p_hp := _encounter_root.get_node("PlayerHP") as Label
	var p_bar := _encounter_root.get_node("PlayerHPBar") as TextureProgressBar
	if e_hp:   e_hp.text = "HP %d/%d" % [_encounter_entity_hp, _encounter_entity_max_hp]
	if e_bar:  e_bar.max_value = _encounter_entity_max_hp; e_bar.value = _encounter_entity_hp
	if p_hp:   p_hp.text = "HP %d/%d" % [_encounter_player_hp, _encounter_player_max_hp]
	if p_bar:  p_bar.max_value = _encounter_player_max_hp; p_bar.value = _encounter_player_hp

func _hide_encounter_screen() -> void:
	if _encounter_root != null:
		_encounter_root.visible = false

func _flash_overlay(color: Color) -> void:
	## Brief full-screen flash for encounter feedback.
	if _encounter_flash == null:
		_encounter_flash = ColorRect.new()
		_encounter_flash.name = "EncounterFlash"
		_encounter_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_encounter_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Attach to whichever root is active
		var parent := _encounter_root if (_encounter_root != null and _encounter_root.visible) else _map_root
		parent.add_child(_encounter_flash)
	_encounter_flash.color = color
	var tw := create_tween()
	tw.tween_property(_encounter_flash, "color", Color(color.r, color.g, color.b, 0.0), 0.6)

func _end_encounter() -> void:
	_encounter_active = false
	_encounter_doing_animation = false
	_current_entity = {}
	_current_lid = ""

# ── Claim / Guild war ──────────────────────────────────────────────────────
func _on_landmark_claimed(lid: String, guild: String) -> void:
	## Update the marker badge.
	if not _landmark_markers.has(lid):
		return
	var m: Dictionary = _landmark_markers[lid]
	var badge := m["badge"] as ColorRect
	if badge != null:
		badge.visible = true
		badge.color = Color.from_hsv(float(hash(guild) % 360) / 360.0, 0.7, 0.8)

func _on_war_started(lid: String, _attacker: String, _defender: String) -> void:
	## Show war icon on the marker.
	if not _landmark_markers.has(lid):
		return
	var m: Dictionary = _landmark_markers[lid]
	var war_icon := m["war_icon"] as Label
	if war_icon != null:
		war_icon.modulate = Color(1.0, 0.2, 0.2, 1.0)

func _on_war_resolved(lid: String, _winner: String) -> void:
	## Hide war icon.
	if not _landmark_markers.has(lid):
		return
	var m: Dictionary = _landmark_markers[lid]
	var war_icon := m["war_icon"] as Label
	if war_icon != null:
		war_icon.modulate = Color(1.0, 0.2, 0.2, 0.0)

func _my_guild() -> String:
	var GuildManager = AutoloadGate.get_node("GuildManager")
	if not GuildManager.in_guild():
		return ""
	return str(GuildManager.guild.get("name", ""))

func _exit_to_liminal() -> void:
	var LayerManager = AutoloadGate.get_node("LayerManager")
	LayerManager.transition_to("liminal")

func _on_descend_pressed() -> void:
	var LayerManager = AutoloadGate.get_node("LayerManager")
	var PeriliminalRuns = AutoloadGate.get_node("PeriliminalRuns")
	var PartyManager = AutoloadGate.get_node("PartyManager")
	var members: Array[String] = []
	if PartyManager != null:
		members = PartyManager.members()
	else:
		members = ["local_player"]
	if PeriliminalRuns != null:
		PeriliminalRuns.begin_run(members)
	if LayerManager != null:
		LayerManager.transition_to("periliminal", true)

func _refresh_descend_button(_members: Array) -> void:
	var PartyManager = AutoloadGate.get_node("PartyManager")
	var btn := _map_root.get_node_or_null("DescendBtn") as Button
	if btn == null:
		return
	var party_size = PartyManager.size() if PartyManager != null else 1
	btn.text = "🔴 Descend (%s)" % ("party" if party_size > 1 else "solo")

# ── Encounter overlay for mobile ──────────────────────────────────────────
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _info_panel.visible:
			_close_info()
		else:
			_exit_to_liminal()
