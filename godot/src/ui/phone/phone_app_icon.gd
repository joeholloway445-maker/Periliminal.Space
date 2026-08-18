class_name PhoneAppIcon
extends Button
## Rounded app icon for the phone home screen. Shows an emoji + label.

var app_id: String = ""

func setup(p_id: String, emoji: String, label: String, color: Color) -> void:
	app_id = p_id
	custom_minimum_size = Vector2(80, 104)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(72, 72)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style)
	vbox.add_child(panel)

	var emoji_lbl := Label.new()
	emoji_lbl.text = emoji
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.add_theme_font_size_override("font_size", 36)
	emoji_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(emoji_lbl)

	var text_lbl := Label.new()
	text_lbl.text = label
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(text_lbl)

	var btn_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", btn_style)
	add_theme_stylebox_override("hover", btn_style)
	add_theme_stylebox_override("pressed", btn_style)
	add_theme_stylebox_override("focus", btn_style)

	pressed.connect(_play_click)

func _play_click() -> void:
	var stream := AssetLibrary.sound("ui_click")
	if stream == null:
		return
	var playable: AudioStream = stream.duplicate() if stream.has_method("duplicate") else stream
	if playable is AudioStreamOggVorbis:
		(playable as AudioStreamOggVorbis).loop = false
	elif playable is AudioStreamWAV:
		(playable as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	var player := AudioStreamPlayer.new()
	player.stream = playable
	player.bus = "Master"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
