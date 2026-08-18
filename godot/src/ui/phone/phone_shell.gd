class_name PhoneShell
extends RefCounted
## Shared phone chrome for the GTA-style phone screens: night-city
## wallpaper, bezel + side buttons (desktop only), status bar with
## time / signal / battery, and a home indicator pill. Both
## PhoneHomeScreen and TitleScreen build their phone through this so the
## two always read as the same device.

const STATUS_TOP := 8
const STATUS_H := 26

## Build the full phone look under `root`. Returns
## { "frame": PanelContainer, "content": Control } — apps/widgets go into
## `content`. The wallpaper is drawn behind content automatically.
static func build(root: Control, is_phone: bool, size: Vector2) -> Dictionary:
	var out: Dictionary = {}
	var vp := root.get_viewport().get_visible_rect().size

	# Dark backdrop behind the device.
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.01, 0.028)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# Device frame.
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	frame.custom_minimum_size = size
	frame.size = size
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.06, 0.06, 0.08)
	frame_style.border_color = Color(0.17, 0.17, 0.22)
	frame_style.border_width_left = 8
	frame_style.border_width_right = 8
	frame_style.border_width_top = 8
	frame_style.border_width_bottom = 8
	frame_style.corner_radius_top_left = 36
	frame_style.corner_radius_top_right = 36
	frame_style.corner_radius_bottom_left = 36
	frame_style.corner_radius_bottom_right = 36
	frame.add_theme_stylebox_override("panel", frame_style)
	root.add_child(frame)

	# Night-city wallpaper inside the frame (below content).
	var wallpaper := _Wallpaper.new()
	wallpaper.name = "Wallpaper"
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(wallpaper)

	# Content inset.
	var content := Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 12
	content.offset_right = -12
	content.offset_top = 12
	content.offset_bottom = -12
	frame.add_child(content)

	_add_status_bar(content)
	_add_home_indicator(content)

	# Bezel side buttons (desktop only — they sell the phone look).
	if not is_phone:
		var fx: float = (vp.x - size.x) / 2.0
		var fy: float = (vp.y - size.y) / 2.0
		_add_side_button(root, fx - 12.0, fy + size.y * 0.26, 10.0, 46.0)
		_add_side_button(root, fx - 12.0, fy + size.y * 0.26 + 58.0, 10.0, 46.0)
		_add_side_button(root, fx + size.x + 2.0, fy + size.y * 0.2, 10.0, 64.0)

	out["frame"] = frame
	out["content"] = content
	return out

static func _add_status_bar(content: Control) -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_top = STATUS_TOP
	bar.offset_bottom = STATUS_TOP + STATUS_H
	content.add_child(bar)

	var time_lbl := Label.new()
	time_lbl.name = "ShellTimeLabel"
	time_lbl.add_theme_font_size_override("font_size", 14)
	time_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	bar.add_child(time_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	bar.add_child(right)
	for i in 4:
		var seg := ColorRect.new()
		seg.custom_minimum_size = Vector2(3, 3.0 + float(i) * 2.0)
		seg.size_flags_vertical = Control.SIZE_SHRINK_END
		seg.color = Color(0.92, 0.95, 1.0) if i < 3 else Color(0.92, 0.95, 1.0, 0.35)
		right.add_child(seg)
	var net := Label.new()
	net.text = "5G"
	net.add_theme_font_size_override("font_size", 11)
	net.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	right.add_child(net)
	_build_battery(right)

	content.set_meta("ShellTimeLabel", time_lbl)

static func _build_battery(parent: HBoxContainer) -> void:
	var bat := PanelContainer.new()
	var outline := StyleBoxFlat.new()
	outline.bg_color = Color(0, 0, 0, 0)
	outline.border_color = Color(0.92, 0.95, 1.0, 0.85)
	outline.border_width_left = 1
	outline.border_width_right = 1
	outline.border_width_top = 1
	outline.border_width_bottom = 1
	outline.corner_radius_top_left = 3
	outline.corner_radius_top_right = 3
	outline.corner_radius_bottom_left = 3
	outline.corner_radius_bottom_right = 3
	bat.add_theme_stylebox_override("panel", outline)
	bat.custom_minimum_size = Vector2(22, 11)
	parent.add_child(bat)
	var fill := ColorRect.new()
	fill.color = Color(0.55, 0.92, 0.62)
	fill.custom_minimum_size = Vector2(16, 7)
	fill.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	bat.add_child(fill)
	var nub := ColorRect.new()
	nub.color = Color(0.92, 0.95, 1.0, 0.85)
	nub.custom_minimum_size = Vector2(2, 4)
	nub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	nub.offset_left = 23
	nub.offset_right = 25
	bat.add_child(nub)

static func _add_home_indicator(content: Control) -> void:
	var pill := PanelContainer.new()
	pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	pill.offset_left = -55
	pill.offset_right = 55
	pill.offset_top = -9
	pill.offset_bottom = -3
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.9)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	pill.add_theme_stylebox_override("panel", style)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(pill)

static func _add_side_button(root: Control, x: float, y: float, w: float, h: float) -> void:
	var b := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.13)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	b.add_theme_stylebox_override("panel", style)
	b.position = Vector2(x, y)
	b.size = Vector2(w, h)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(b)

## Night-city wallpaper: sky gradient, stars, moon, skyline with lit
## windows, neon horizon, and a camera punch-hole.
class _Wallpaper:
	extends Control
	var _rng := RandomNumberGenerator.new()

	func _ready() -> void:
		_rng.seed = 7
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x <= 0 or size.y <= 0:
			return
		var sky := Gradient.new()
		sky.offsets = PackedFloat32Array([0.0, 0.5, 0.72, 1.0])
		sky.colors = PackedColorArray([
			Color(0.03, 0.02, 0.08),
			Color(0.08, 0.05, 0.2),
			Color(0.26, 0.12, 0.42),
			Color(0.05, 0.05, 0.12),
		])
		var steps := 28
		for i in steps:
			var t := float(i) / float(steps - 1)
			var y := size.y * t
			draw_rect(Rect2(0, y, size.x, size.y / steps + 1.0), sky.sample(t), true)

		# Stars (upper sky only).
		for i in 52:
			var sx := _rng.randf() * size.x
			var sy := _rng.randf() * size.y * 0.5
			var a := 0.15 + _rng.randf() * 0.55
			draw_circle(Vector2(sx, sy), 0.8 + _rng.randf() * 1.4, Color(1, 1, 1, a))

		# Moon with soft halo.
		var moon_pos := Vector2(size.x * 0.78, size.y * 0.1)
		draw_circle(moon_pos, 44.0, Color(1.0, 0.95, 0.85, 0.07))
		draw_circle(moon_pos, 30.0, Color(1.0, 0.97, 0.9, 0.1))
		draw_circle(moon_pos, 20.0, Color(0.96, 0.94, 1.0, 0.95))
		draw_circle(moon_pos + Vector2(-6, -4), 4.5, Color(0.9, 0.88, 0.97, 0.5))
		draw_circle(moon_pos + Vector2(5, 6), 3.0, Color(0.9, 0.88, 0.97, 0.4))

		# Skyline silhouette with lit windows.
		var base_y := size.y * 0.74
		var x := 0.0
		while x < size.x:
			var bw := 28.0 + _rng.randf() * 48.0
			var bh := 26.0 + _rng.randf() * 120.0
			var col := Color(0.035, 0.03, 0.075).lerp(Color(0.1, 0.06, 0.17), _rng.randf())
			draw_rect(Rect2(x, base_y - bh, bw, bh + size.y - base_y), col, true)
			var wcols := int(bw / 6.0)
			var wrows := int(bh / 8.0)
			for wy in wrows:
				for wx in wcols:
					if _rng.randf() < 0.13:
						var win := Color(1.0, 0.85, 0.4, 0.4 + _rng.randf() * 0.5)
						draw_rect(Rect2(x + 3.0 + wx * 6.0, base_y - bh + 4.0 + wy * 8.0, 2.5, 3.5), win, true)
			x += bw + 2.0

		# Neon horizon line.
		draw_line(Vector2(0, base_y + 1), Vector2(size.x, base_y + 1), Color(0.65, 0.3, 0.95, 0.55), 2.0)
		draw_line(Vector2(0, base_y + 4), Vector2(size.x, base_y + 4), Color(0.3, 0.6, 0.95, 0.3), 1.0)

		# Camera punch-hole.
		draw_circle(Vector2(size.x * 0.5, 20), 6.5, Color(0.0, 0.0, 0.0, 0.9))
		draw_arc(Vector2(size.x * 0.5, 20), 9.0, 0.0, TAU, 24, Color(0.25, 0.25, 0.32, 0.6), 1.5)
