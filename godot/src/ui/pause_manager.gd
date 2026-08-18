extends Node

var _pause_ui: CanvasLayer
var _is_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_ui = CanvasLayer.new()
	_pause_ui.layer = 100
	_pause_ui.visible = false
	add_child(_pause_ui)
	_build_ui()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().current_scene and get_tree().current_scene.name == "TitleScreen":
			return # Don't pause on title screen
		toggle_pause()

func toggle_pause() -> void:
	_is_paused = !_is_paused
	get_tree().paused = _is_paused
	_pause_ui.visible = _is_paused
	
	if _is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		# Let the active controller/game manager handle returning to captured if needed.
		pass

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_ui.add_child(bg)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)
	
	var panel := PanelContainer.new()
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	var resume_btn := Button.new()
	resume_btn.text = "Resume Game"
	resume_btn.add_theme_font_size_override("font_size", 24)
	resume_btn.pressed.connect(toggle_pause)
	vbox.add_child(resume_btn)
	
	var options_btn := Button.new()
	options_btn.text = "Options"
	options_btn.add_theme_font_size_override("font_size", 24)
	options_btn.pressed.connect(_on_options_pressed)
	vbox.add_child(options_btn)
	
	var quit_btn := Button.new()
	quit_btn.text = "Save & Quit to Title"
	quit_btn.add_theme_font_size_override("font_size", 24)
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

func _on_quit_pressed() -> void:
	toggle_pause()
	if get_tree().current_scene:
		get_tree().change_scene_to_file("res://scenes/ui/splash.tscn")

func _on_options_pressed() -> void:
	if ResourceLoader.exists("res://scenes/ui/settings.tscn"):
		var settings = load("res://scenes/ui/settings.tscn").instantiate()
		# Add to the pause UI so it renders above it.
		_pause_ui.add_child(settings)
