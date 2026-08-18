class_name PeriliminalGroupSeal
extends Area3D
## A sealed descent into the Periliminal for groups forming in the Metroplex
## or the Extraliminal overlay. Unlike PeriliminalDungeonDoor, this has no
## dungeon rank, key, or level gate — it simply takes the current party (or
## a solo player) into a generated-then-static Periliminal run.

signal entered(party: Array[String])

var player: Node3D
var seal_id := ""

var _armed := false
var _plate: Label3D

func setup(p_seal_id: String, p_player: Node3D) -> void:
	seal_id = p_seal_id
	player = p_player

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 1
	_build_visuals()
	_build_ring()
	_update_plate()

func _build_visuals() -> void:
	# Dark portal plane.
	var seal := MeshInstance3D.new()
	seal.name = "SealMesh"
	var quad := QuadMesh.new()
	quad.size = Vector2(3.2, 4.4)
	seal.mesh = quad
	seal.position = Vector3(0, 2.2, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.02, 0.09, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.15, 0.75)
	mat.emission_energy_multiplier = 1.6
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	seal.material_override = mat
	add_child(seal)

	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 0.6, 0.9)
	glow.light_color = Color(0.65, 0.2, 0.85)
	glow.light_energy = 2.0
	glow.omni_range = 9.0
	add_child(glow)

	# Frame.
	var frame_mat := AssetLibrary.material("facade_metal", Color(0.28, 0.26, 0.34), 0.25, 0.75, 0.35)
	for spec in [
		[Vector3(0.4, 4.6, 0.5), Vector3(-1.8, 2.3, 0)],
		[Vector3(0.4, 4.6, 0.5), Vector3(1.8, 2.3, 0)],
		[Vector3(4.0, 0.4, 0.5), Vector3(0, 4.6, 0)],
	]:
		var body := StaticBody3D.new()
		body.position = spec[1]
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = spec[0]
		mi.mesh = box
		mi.material_override = frame_mat
		body.add_child(mi)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = spec[0]
		cs.shape = shape
		body.add_child(cs)
		add_child(body)

	_plate = Label3D.new()
	_plate.name = "Plate"
	_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plate.font_size = 64
	_plate.outline_size = 10
	_plate.position.y = 5.6
	_plate.modulate = Color(0.85, 0.7, 1.0)
	add_child(_plate)

func _build_ring() -> void:
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 5.0
	cs.shape = sph
	add_child(cs)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _update_plate() -> void:
	var PartyManager = AutoloadGate.get_node("PartyManager")
	if _plate == null:
		return
	var party_size = PartyManager.size() if PartyManager != null else 1
	var label := "GROUP SEAL" if party_size > 1 else "SOLO SEAL"
	_plate.text = "PERILIMINAL\n%s\n[Press E]" % label

func _on_body_entered(body: Node3D) -> void:
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	if body != player:
		return
	_armed = true
	_update_plate()
	if NotificationUI:
		NotificationUI.notify_info("A seal hums beneath the street. The Periliminal opens for whoever steps through together.")

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		_armed = false

func _unhandled_input(event: InputEvent) -> void:
	if not _armed:
		return
	if not (event is InputEventKey and event.pressed and not event.echo
			and event.keycode == KEY_E):
		return
	_enter()

func _enter() -> void:
	var PartyManager = AutoloadGate.get_node("PartyManager")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	var PeriliminalRuns = AutoloadGate.get_node("PeriliminalRuns")
	var LayerManager = AutoloadGate.get_node("LayerManager")
	var members: Array[String] = []
	if PartyManager != null:
		members = PartyManager.members()
	else:
		members = ["local_player"]
	if NotificationUI:
		NotificationUI.notify_info("The seal gives. The Periliminal takes %d." % members.size())
	entered.emit(members)
	if PeriliminalRuns != null:
		PeriliminalRuns.begin_run(members)
	if LayerManager != null:
		LayerManager.transition_to("periliminal", true)
