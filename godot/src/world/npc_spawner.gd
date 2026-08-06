class_name NPCSpawner
extends Node3D
## Spawns NPCs from WorldLoader (includes both handcrafted and generated NPCs).
## Supports LOD: full-detail near player, impostors far away.
## Integrates with NPCManager for lifecycle management.

@export var district_id: String = "paw_vegas"
@export var max_npcs_in_district: int = 50  # Lazy-load limit

const INTERACTION_RADIUS := 2.5
const LOD_DISTANCE_NEAR := 30.0

var _spawned_npcs: Dictionary = {}  # npc_id -> Node3D instance
var _player_position := Vector3.ZERO

func _ready() -> void:
	if WorldLoader.districts.is_empty():
		await WorldLoader.world_loaded

	# Get player reference for LOD updates
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_player_position = player.global_position
		NPCManager.set_player(player)

	_spawn_npcs()

func _spawn_npcs() -> void:
	# Get NPCs in this district, respecting LOD distance
	var npc_list := NPCManager.get_npcs_in_district(district_id, _player_position)

	# Limit to max_npcs_in_district for performance
	var to_spawn := npc_list.slice(0, mini(max_npcs_in_district, npc_list.size()))

	for npc_data in to_spawn:
		if npc_data.get("lod_level", 0) < 2:  # Skip impostors for now
			_create_npc(npc_data)

func _create_npc(data: Dictionary) -> void:
	var npc_id: String = data.get("id", "npc")

	# Avoid duplicates
	if npc_id in _spawned_npcs:
		return

	var pos = data.get("position", {})
	var root := Node3D.new()
	root.name = npc_id
	root.position = Vector3(pos.get("x", 0.0), pos.get("y", 0.0), pos.get("z", 0.0))
	add_child(root)

	# Every citizen belongs to a race — it drives their name, voice, and the
	# in-character things they mutter as you pass.
	var canon := RacePersona.canon_for_npc(data)
	var display_name := str(data.get("name", ""))
	if display_name.is_empty():
		display_name = RaceNameGen.name_for_npc(data)

	# Visual: label with NPC name and emoji
	var label := Label3D.new()
	label.text = "%s\n%s" % [data.get("emoji", "🐱"), display_name]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.008
	label.position = Vector3(0, 1.8, 0)
	label.modulate = RacePersona.mood_color(canon) if not canon.is_empty() else Color.WHITE
	root.add_child(label)

	# Ambient barks: this citizen mutters in character on a timer, voiced when
	# you're close enough to hear.
	if not canon.is_empty():
		var barker := PersonaBarker.new()
		root.add_child(barker)
		barker.setup(canon, 2.1)

	# Interaction collider
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = INTERACTION_RADIUS
	shape.shape = sphere
	area.add_child(shape)
	root.add_child(area)

	# Connect interaction to dialogue system
	area.body_entered.connect(func(body):
		if body.is_in_group("player"):
			var ui := get_tree().get_first_node_in_group("npc_dialogue_ui")
			if ui and ui.has_method("open_for_npc"):
				ui.open_for_npc(npc_id)
	)

	# Wire into ambient_npc if this becomes a persistent NPC
	if data.get("recruitable_as", ""):
		var ambient := AmbientNpc.new()
		ambient.npc_id = npc_id
		ambient.persona_module = "ambient"
		ambient.persona_role = data.get("role", "npc")
		ambient.daily_task = data.get("daily_schedule", "wandering")
		ambient.recruitable_as = data.get("recruitable_as", "")
		ambient.canon = canon  # persona reshapes its wander tempo in _ready
		root.add_child(ambient)

	_spawned_npcs[npc_id] = root
	NPCManager.register_instance(npc_id, root)

func _process(_delta: float) -> void:
	# Update player position for LOD calculations
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_player_position = player.global_position
