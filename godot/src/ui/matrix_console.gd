extends Control
class_name MatrixConsole
## Matrix Command Console — real-time status visualization for the
## Periliminal.Space cognitive matrix (HOPE · DREAM · VISION · APEX · KNOLL)
##
## Opens via F12 during gameplay or from the system menu. Shows live metrics
## for all five pillars with animated connection visualization, expanded
## detail panels, and a scrolling event log stream.
##
## Usage:
##   MatrixConsole.open()    # open as overlay
##   MatrixConsole.toggle()  # toggle open/closed

const PILLAR_COLORS := {
	"HOPE":  Color(0.4, 0.7, 1.0),   # sky blue
	"DREAM": Color(0.2, 0.9, 0.6),   # emerald
	"VISION": Color(1.0, 0.8, 0.2),  # gold
	"APEX":  Color(0.6, 0.3, 1.0),   # violet
	"KNOLL": Color(1.0, 0.3, 0.3),   # red
}
const PILLAR_ORDER := ["HOPE", "DREAM", "VISION", "APEX", "KNOLL"]
const BG_COLOR := Color(0.01, 0.0, 0.03)
const PANEL_BG := Color(0.06, 0.04, 0.10)
const TEXT_DIM := Color(0.4, 0.4, 0.5)
const TEXT_ACCENT := Color(0.2, 0.9, 0.6)
const TEXT_BRIGHT := Color(0.9, 0.9, 1.0)
const BORDER_COLOR := Color(0.15, 0.1, 0.25)

var _uptime_seconds: float = 0.0
var _log_lines: Array[Dictionary] = []
var _selected_pillar: String = "DREAM"
var _pillar_nodes: Dictionary = {}  # pillar_name → Panel
var _connection_lines: Array = []   # for _draw
var _pillar_positions: Dictionary = {}  # pillar_name → relative Vector2
var _pillar_viz: Control = null     # container for positioning reference
var _tweens: Array = []             # active visual tweens
var _data_stream_timer: float = 0.0
var _frame_count: int = 0

static var _instance: Control = null

## Open the console as a full-screen overlay on the current scene.
static func open() -> void:
	if _instance and is_instance_valid(_instance):
		_instance.queue_free()
		_instance = null
	var tree: SceneTree = Engine.get_main_loop()
	if not tree: return
	var console := preload("res://src/ui/matrix_console.gd").new()
	tree.root.add_child(console)
	_instance = console

## Toggle the console open/closed.
static func toggle() -> void:
	if _instance and is_instance_valid(_instance):
		_instance.queue_free()
		_instance = null
	else:
		open()

func _ready() -> void:
	name = "MatrixConsole"
	# Full-screen overlay
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1000

	_build_background()
	_build_title_bar()
	_build_pillar_pentagram()
	_build_detail_panel()
	_build_log_stream()
	_build_close_button()

	# Register F12 to toggle (won't double-register since we check)
	if not InputMap.has_action("toggle_matrix_console"):
		var ev := InputEventKey.new()
		ev.keycode = KEY_F12
		InputMap.add_action("toggle_matrix_console")
		InputMap.action_add_event("toggle_matrix_console", ev)

	_log("MATRIX CONSOLE INITIALIZED", "SYSTEM")
	_log("Monitoring: HOPE · DREAM · VISION · APEX · KNOLL", "SYSTEM")
	_log("All pillars responding", "SYSTEM")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_matrix_console"):
		toggle()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_uptime_seconds += delta
	_frame_count += 1

	# Update title bar every 10 frames
	if _frame_count % 10 == 0:
		_update_title_bar()
		_update_pillar_nodes()
		_update_detail_panel()

	# Push a sample log line every 2-3 seconds
	_data_stream_timer += delta
	if _data_stream_timer > 2.5 + (randf() * 1.5):
		_data_stream_timer = 0.0
		_push_sample_log()

	# Redraw connection lines occasionally for animation
	if _frame_count % 5 == 0 and _pillar_viz:
		_pillar_viz.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _instance == self:
			_instance = null

# ─── UI Builders ────────────────────────────────────────────────────────────

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Subtle scanline overlay
	var scanlines := ColorRect.new()
	scanlines.color = Color(0.0, 0.0, 0.0, 0.08)
	scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanlines.material = ShaderMaterial.new()
	var shader_path := "res://src/ui/matrix_scanline.gdshader"
	if ResourceLoader.exists(shader_path):
		scanlines.material.shader = ResourceLoader.load(shader_path)
	add_child(scanlines)

	# Ambient glow — subtle color shifts
	var glow := ColorRect.new()
	glow.name = "AmbientGlow"
	glow.color = Color(0.15, 0.05, 0.25, 0.12)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var t := create_tween().set_loops()
	t.tween_property(glow, "color", Color(0.05, 0.15, 0.25, 0.10), 6.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(glow, "color", Color(0.15, 0.05, 0.25, 0.14), 6.0).set_trans(Tween.TRANS_SINE)

func _build_title_bar() -> void:
	var bar := Panel.new()
	bar.name = "TitleBar"
	bar.custom_minimum_size = Vector2(0, 48)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 0)
	bar.add_theme_stylebox_override("panel", _make_style(PANEL_BG, BORDER_COLOR, 0, false, 0))
	add_child(bar)

	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 24)
	bar.add_child(layout)

	# Title
	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "⚡ PERILIMINAL.SPACE — COGNITIVE MATRIX CONSOLE"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", TEXT_BRIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(title)

	# Status
	var status := Label.new()
	status.name = "StatusLabel"
	status.text = "◆ ALL PILLARS NOMINAL"
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", TEXT_ACCENT)
	layout.add_child(status)

	# Uptime
	var uptime := Label.new()
	uptime.name = "UptimeLabel"
	uptime.text = "UP: 00:00:00"
	uptime.add_theme_font_size_override("font_size", 12)
	uptime.add_theme_color_override("font_color", TEXT_DIM)
	uptime.custom_minimum_size = Vector2(120, 0)
	layout.add_child(uptime)

func _build_pillar_pentagram() -> void:
	# Wrapper to hold the pentagram visualization
	var viz := Control.new()
	viz.name = "PillarViz"
	viz.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 48)
	viz.custom_minimum_size = Vector2(0, 360)
	add_child(viz)

	# Layout: APEX at top center, the others arranged in curved pentagram below
	# Using pixel positions relative to viz size (we'll recalc in _resized)
	var center_x := 0.50
	var center_y := 0.48
	var rx := 0.30
	var ry := 0.38

	var pos_ratios := {
		"APEX":   Vector2(center_x, center_y - ry * 0.85),
		"HOPE":   Vector2(center_x - rx * 0.72, center_y - ry * 0.25),
		"KNOLL":  Vector2(center_x + rx * 0.72, center_y - ry * 0.25),
		"DREAM":  Vector2(center_x - rx * 0.45, center_y + ry * 0.80),
		"VISION": Vector2(center_x + rx * 0.45, center_y + ry * 0.80),
	}

	# Store connection pairs for _draw
	_connection_lines = [
		["APEX", "HOPE"], ["APEX", "KNOLL"], ["APEX", "DREAM"], ["APEX", "VISION"],
		["HOPE", "DREAM"], ["HOPE", "VISION"],
		["KNOLL", "DREAM"], ["KNOLL", "VISION"],
		["DREAM", "VISION"],
	]

	# Wait one frame so sizes resolve, then position panels
	_build_pillar_panels_deferred.call_deferred(viz, pos_ratios)
	_pillar_positions = pos_ratios
	_pillar_viz = viz

func _build_pillar_panels_deferred(viz: Control, pos_ratios: Dictionary) -> void:
	if not viz or not is_instance_valid(viz):
		return
	var vs: Vector2 = viz.size
	if vs.x < 100:
		# Not sized yet — try again next frame
		_build_pillar_panels_deferred.call_deferred(viz, pos_ratios)
		return

	for pillar in PILLAR_ORDER:
		var ratio: Vector2 = pos_ratios[pillar]
		var px := ratio.x * vs.x - 90.0  # half panel width
		var py := ratio.y * vs.y - 37.0  # half panel height
		var panel := _make_pillar_panel(pillar)
		panel.position = Vector2(maxf(4, px), maxf(4, py))
		viz.add_child(panel)
		_pillar_nodes[pillar] = panel

	# Connect viz.draw to render connection lines using actual panel positions
	viz.draw.connect(_on_viz_draw.bind(viz))

func _make_pillar_panel(pillar: String) -> Panel:
	var color: Color = PILLAR_COLORS.get(pillar, Color.WHITE)
	var panel := Panel.new()
	panel.name = "Pillar_%s" % pillar
	panel.custom_minimum_size = Vector2(180, 74)
	panel.add_theme_stylebox_override("panel", _make_style(PANEL_BG, color, 1, true, 6))

	# Position as percentage of parent
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 2)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	panel.add_child(layout)

	# Header row: status dot + name
	var header := HBoxContainer.new()
	layout.add_child(header)

	var dot := ColorRect.new()
	dot.name = "StatusDot"
	dot.color = color
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(dot)

	var name_label := Label.new()
	name_label.text = pillar
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	header.add_child(name_label)

	# Metric rows
	var metrics := VBoxContainer.new()
	metrics.name = "Metrics"
	layout.add_child(metrics)

	return panel

func _update_pillar_nodes() -> void:
	var Hope = AutoloadGate.get_node("Hope")
	var DREAM = AutoloadGate.get_node("DREAM")
	var VISION = AutoloadGate.get_node("VISION")
	var APEX = AutoloadGate.get_node("APEX")
	var KNOLL = AutoloadGate.get_node("KNOLL")
	var now: float = Time.get_unix_time_from_system()

	# HOPE metrics
	var hope_node = _pillar_nodes.get("HOPE")
	if hope_node and Hope:
		_set_pillar_metrics(hope_node, [
			"bond: %s (%d)" % [Hope.stage().get("name", "?"), Hope.bond],
			"drives: %s" % _format_drives(Hope.combat_profile()),
		])

	# DREAM metrics
	var dream_node = _pillar_nodes.get("DREAM")
	if dream_node and DREAM:
		var summary: Dictionary = DREAM.get_matrix_summary()
		var avg_entropy: float = summary.get("average_entropy", 0.0)
		var tracked: int = summary.get("total_tracked", 0)
		var actions: int = summary.get("total_actions", 0)
		_set_pillar_metrics(dream_node, [
			"entropy: %.3f" % avg_entropy,
			"tracked: %d users" % tracked,
			"actions: %d" % actions,
		])

	# VISION metrics
	var vision_node = _pillar_nodes.get("VISION")
	if vision_node and VISION:
		var summary: Dictionary = VISION.get_matrix_summary()
		var dots: int = summary.get("total_dots", 0)
		var potential: float = summary.get("average_potential", 0.0)
		var hest: float = summary.get("average_hesitation_ms", 0.0)
		_set_pillar_metrics(vision_node, [
			"dots: %d" % dots,
			"potential: %.2f" % potential,
			"hesitation: %.0fms" % hest,
		])

	# APEX metrics
	var apex_node = _pillar_nodes.get("APEX")
	if apex_node and APEX:
		var summary: Dictionary = APEX.get_matrix_summary()
		_set_pillar_metrics(apex_node, [
			"load: %.2f" % summary.get("system_load", 0.0),
			"pending: %d" % summary.get("pending_delegations", 0),
			"responses: %d" % summary.get("total_responses_logged", 0),
		])

	# KNOLL metrics
	var knoll_node = _pillar_nodes.get("KNOLL")
	if knoll_node and KNOLL:
		var summary: Dictionary = KNOLL.get_matrix_summary()
		_set_pillar_metrics(knoll_node, [
			"allowed: %d" % summary.get("allowed_flows", 0),
			"blocked: %d" % summary.get("blocked_flows", 0),
			"lockdowns: %d" % summary.get("active_lockdowns", 0),
		])

func _set_pillar_metrics(panel: Panel, metrics: Array[String]) -> void:
	var layout := panel.get_node_or_null("Layout")
	if not layout: return
	var metrics_container := layout.get_node_or_null("Metrics") as VBoxContainer
	if not metrics_container: return

	# Update or create metric labels
	for i in range(maxi(metrics.size(), metrics_container.get_child_count())):
		if i < metrics.size():
			var label: Label = null
			if i < metrics_container.get_child_count():
				label = metrics_container.get_child(i) as Label
			if not label:
				label = Label.new()
				label.add_theme_font_size_override("font_size", 11)
				label.add_theme_color_override("font_color", TEXT_DIM)
				metrics_container.add_child(label)
			label.text = metrics[i]
		else:
			# Remove excess labels
			if i < metrics_container.get_child_count():
				metrics_container.get_child(i).queue_free()

func _update_title_bar() -> void:
	var bar := get_node_or_null("TitleBar")
	if not bar: return

	var uptime_label := bar.get_node_or_null("UptimeLabel") as Label
	if uptime_label:
		var hours: int = int(_uptime_seconds) / 3600
		var mins: int = (int(_uptime_seconds) % 3600) / 60
		var secs: int = int(_uptime_seconds) % 60
		uptime_label.text = "UP: %02d:%02d:%02d" % [hours, mins, secs]

	var fps_label := bar.get_node_or_null("FPSLabel") as Label
	if not fps_label:
		fps_label = Label.new()
		fps_label.name = "FPSLabel"
		fps_label.add_theme_font_size_override("font_size", 11)
		fps_label.add_theme_color_override("font_color", TEXT_DIM)
		fps_label.custom_minimum_size = Vector2(60, 0)
		bar.get_node("Layout").add_child(fps_label)
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _build_detail_panel() -> void:
	var panel := Panel.new()
	panel.name = "DetailPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE, 0)
	panel.position = Vector2(0, 388)
	panel.custom_minimum_size = Vector2(size.x * 0.65, 0)
	panel.add_theme_stylebox_override("panel", _make_style(PANEL_BG, BORDER_COLOR, 1, false, 4))

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)

	# Tab bar for pillar selection
	var tabs := HBoxContainer.new()
	tabs.name = "PillarTabs"
	tabs.add_theme_constant_override("separation", 4)
	layout.add_child(tabs)

	for pillar in PILLAR_ORDER:
		var btn := Button.new()
		btn.name = "Tab_%s" % pillar
		btn.text = pillar
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", PILLAR_COLORS[pillar])
		btn.add_theme_color_override("font_pressed_color", PILLAR_COLORS[pillar])
		btn.pressed.connect(_on_pillar_tab_pressed.bind(pillar))
		tabs.add_child(btn)

	# Content area
	var content := VBoxContainer.new()
	content.name = "DetailContent"
	content.add_theme_constant_override("separation", 4)
	layout.add_child(content)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Data fields will be populated dynamically in _update_detail_panel

func _update_detail_panel() -> void:
	var Hope = AutoloadGate.get_node("Hope")
	var DREAM = AutoloadGate.get_node("DREAM")
	var VISION = AutoloadGate.get_node("VISION")
	var APEX = AutoloadGate.get_node("APEX")
	var KNOLL = AutoloadGate.get_node("KNOLL")
	var panel := get_node_or_null("DetailPanel")
	if not panel: return
	var content := panel.get_node_or_null("Layout/DetailContent") as VBoxContainer
	if not content: return

	var data_lines: Array[String] = []
	var pillar: String = _selected_pillar

	match pillar:
		"HOPE":
			if Hope:
				var profile: Dictionary = Hope.combat_profile()
				data_lines = [
					"STAGE: %s (bond: %d)" % [Hope.stage().get("name", "?"), Hope.bond],
					"AGGRESSION: %.2f" % profile.get("aggression", 0.0),
					"CAUTION: %.2f" % profile.get("caution", 0.0),
					"CURIOSITY: %.2f" % profile.get("curiosity", 0.0),
					"DOMINANT DRIVE: %s" % profile.get("dominant_drive", "?"),
					"SYNERGY LINES: %d" % Hope.synergy_lines().size(),
				]
		"DREAM":
			if DREAM:
				var summary: Dictionary = DREAM.get_matrix_summary()
				data_lines = [
					"USERS TRACKED: %d" % summary.get("total_tracked", 0),
					"TOTAL ACTIONS: %d" % summary.get("total_actions", 0),
					"AVERAGE ENTROPY: %.4f" % summary.get("average_entropy", 0.0),
					"ENTROPY WINDOW: %d" % DREAM.ENTROPY_WINDOW_SIZE,
					"HMM STATES: %d" % DREAM.HMM_STATE_COUNT,
					"DRIFT THRESHOLD: %.2f" % DREAM.DRIFT_THRESHOLD,
				]
				var states: Dictionary = summary.get("states", {})
				for s in states:
					data_lines.append("  %s: %d" % [s.to_upper(), states[s]])
		"VISION":
			if VISION:
				var summary: Dictionary = VISION.get_matrix_summary()
				data_lines = [
					"USERS TRACKED: %d" % summary.get("total_users_tracked", 0),
					"TOTAL DOTS: %d" % summary.get("total_dots", 0),
					"AVERAGE POTENTIAL: %.3f" % summary.get("average_potential", 0.0),
					"AVERAGE HESITATION: %.0fms" % summary.get("average_hesitation_ms", 0.0),
					"TOTAL HESITATIONS: %d" % summary.get("total_hesitations", 0),
					"MAX DOTS PER USER: %d" % VISION.MAX_DOTS_PER_USER,
				]
		"APEX":
			if APEX:
				var summary: Dictionary = APEX.get_matrix_summary()
				data_lines = [
					"SYSTEM LOAD: %.2f" % summary.get("system_load", 0.0),
					"PENDING DELEGATIONS: %d" % summary.get("pending_delegations", 0),
					"ACTIVE DELEGATIONS: %d" % summary.get("active_delegations", 0),
					"USERS WITH HISTORY: %d" % summary.get("users_with_history", 0),
					"TOTAL RESPONSES: %d" % summary.get("total_responses_logged", 0),
					"PRIORITY LEVELS: %d" % APEX.Priority.size(),
				]
		"KNOLL":
			if KNOLL:
				var summary: Dictionary = KNOLL.get_matrix_summary()
				data_lines = [
					"STATUS: %s" % summary.get("status", "?"),
					"ALLOWED FLOWS: %d" % summary.get("allowed_flows", 0),
					"BLOCKED FLOWS: %d" % summary.get("blocked_flows", 0),
					"TOTAL LOGGED: %d" % summary.get("total_flows_logged", 0),
					"ACTIVE LOCKDOWNS: %d" % summary.get("active_lockdowns", 0),
					"LAYERS MONITORED: %d" % summary.get("layers_monitored", 0),
				]
				var locked: Array = summary.get("locked_layers", [])
				if locked.size() > 0:
					data_lines.append("  LOCKED: %s" % ", ".join(locked))

	# Clear and rebuild detail content
	for child in content.get_children():
		child.queue_free()

	# Header for selected pillar
	var header := Label.new()
	header.text = "── %s ──" % pillar
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", PILLAR_COLORS.get(pillar, Color.WHITE))
	content.add_child(header)

	for line in data_lines:
		var label := Label.new()
		label.text = line
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", TEXT_DIM)
		content.add_child(label)

func _on_pillar_tab_pressed(pillar: String) -> void:
	_selected_pillar = pillar
	_log("Focus shifted to %s" % pillar, "SYSTEM")
	_update_detail_panel()

func _build_log_stream() -> void:
	var panel := Panel.new()
	panel.name = "LogPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE, Control.PRESET_MODE_MINSIZE, 0)
	panel.position = Vector2(0, 388)
	panel.custom_minimum_size = Vector2(size.x * 0.33, 0)
	panel.add_theme_stylebox_override("panel", _make_style(PANEL_BG, BORDER_COLOR, 1, false, 4))

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	layout.add_theme_constant_override("separation", 2)
	panel.add_child(layout)

	# Header
	var header := Label.new()
	header.text = "EVENT LOG"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", TEXT_ACCENT)
	layout.add_child(header)

	# Scrollable log
	var scroll := ScrollContainer.new()
	scroll.name = "LogScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var log_box := VBoxContainer.new()
	log_box.name = "LogBox"
	log_box.add_theme_constant_override("separation", 1)
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(log_box)

func _log(text: String, source: String = "SYSTEM") -> void:
	var entry := {
		"timestamp": Time.get_unix_time_from_system(),
		"text": text,
		"source": source,
	}
	_log_lines.append(entry)
	if _log_lines.size() > 200:
		_log_lines.pop_front()

	# Update log display if console is built
	var log_box := get_node_or_null("LogPanel/Layout/LogScroll/LogBox") as VBoxContainer
	if not log_box: return

	var label := Label.new()
	var color: Color = PILLAR_COLORS.get(source, TEXT_DIM)
	label.text = "> %s" % text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_box.add_child(label)

	# Auto-scroll to bottom
	var scroll := get_node_or_null("LogPanel/Layout/LogScroll") as ScrollContainer
	if scroll:
		await get_tree().process_frame
		scroll.scroll_vertical = int(maxf(0, log_box.size.y - scroll.size.y))

	# Remove excess log labels
	while log_box.get_child_count() > 80:
		log_box.get_child(0).queue_free()

func _push_sample_log() -> void:
	if _log_lines.size() < 5: return  # Don't spam before real data flows

	var sources := ["HOPE", "DREAM", "VISION", "APEX", "KNOLL"]
	var source: String = sources[randi() % sources.size()]
	var messages := {
		"HOPE": [
			"memory continuum stable",
			"profile snapshot stored",
			"bond tick recorded",
		],
		"DREAM": [
			"entropy calculation complete",
			"HMM state updated",
			"trajectory prediction refreshed",
			"drift check: nominal",
		],
		"VISION": [
			"dot registered",
			"hesitation logged: %.0fms" % (500.0 + randf() * 4000.0),
			"potential shift detected",
			"observation window refreshed",
		],
		"APEX": [
			"delegation queued",
			"environment response determined",
			"orchestration cycle complete",
			"system load: %.2f" % (randf() * 0.5),
		],
		"KNOLL": [
			"data flow validated",
			"boundary check passed",
			"layer isolation: nominal",
		],
	}

	var msg_list: Array = messages.get(source, ["heartbeat"])
	var msg: String = msg_list[randi() % msg_list.size()]
	_log(msg, source)

func _build_close_button() -> void:
	var btn := Button.new()
	btn.name = "CloseButton"
	btn.text = "✕ CLOSE"
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	btn.pressed.connect(func(): toggle())
	btn.position = Vector2(size.x - 110, 8)
	add_child(btn)

func _on_viz_draw(viz: Control) -> void:
	var cols := PILLAR_COLORS
	for pair in _connection_lines:
		var a_panel: Control = _pillar_nodes.get(pair[0])
		var b_panel: Control = _pillar_nodes.get(pair[1])
		if not a_panel or not b_panel:
			continue

		# Get center of each panel in viz-local coordinates
		var from := a_panel.position + a_panel.size * 0.5
		var to := b_panel.position + b_panel.size * 0.5
		var mid := (from + to) * 0.5

		var color: Color = cols.get(pair[0], Color.WHITE)
		color.a = 0.12 + 0.08 * sin(_uptime_seconds * 0.5 + float(_connection_lines.find(pair)) * 0.5)

		viz.draw_line(from, to, color, 1.0, true)
		# Pulse dot at midpoint
		var pulse: float = 0.3 + 0.7 * absf(sin(_uptime_seconds * 2.0 + float(_connection_lines.find(pair)) * 1.5))
		viz.draw_circle(mid, 3.0 * pulse, Color(color.r, color.g, color.b, 0.5 * pulse))

func _make_style(bg: Color, border: Color, border_width: int = 1, rounded: bool = true, corner_radius: int = 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = border_width
	s.border_width_right = border_width
	s.border_width_top = border_width
	s.border_width_bottom = border_width
	if rounded:
		s.corner_radius_top_left = corner_radius
		s.corner_radius_top_right = corner_radius
		s.corner_radius_bottom_left = corner_radius
		s.corner_radius_bottom_right = corner_radius
	return s

func _format_drives(profile: Dictionary) -> String:
	var parts: Array[String] = []
	for d in ["fear", "lust", "boredom", "anxiety"]:
		var val: float = profile.get(d, 0.0)
		if val > 0.05:
			parts.append("%s:%.0f" % [d.left(3), val * 100])
	return " ".join(parts)
