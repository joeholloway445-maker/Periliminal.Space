class_name UINav
## Shared navigation helpers for overlay UIs opened from the main menu.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"

static func add_back_button(host: Node, target_scene: String = TITLE_SCREEN, label: String = "⬅ Close") -> Button:
	if host == null:
		return null
	if host.has_node("UINavBack"):
		return host.get_node("UINavBack") as Button
	var back := Button.new()
	back.name = "UINavBack"
	back.text = label
	back.z_index = 100
	back.position = Vector2(12, 12)
	
	back.pressed.connect(func() -> void:
		if not host.is_inside_tree():
			return
		# If the host is a child of the root, it's the main scene. Otherwise it's an overlay.
		if host.get_parent() == host.get_tree().root:
			if ResourceLoader.exists(target_scene):
				host.get_tree().change_scene_to_file(target_scene)
		else:
			host.queue_free()
	)
	
	host.add_child(back)
	return back
