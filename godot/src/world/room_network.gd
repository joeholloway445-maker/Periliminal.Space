extends Node
## Autoloaded as "RoomNetwork". Manages the room connection graph.
## Every LiminalDoor position maps to a persistent room. Rooms connect
## to each other (90% local, 10% wormhole). Guilds can claim rooms.

signal room_created(room_id: String)
signal room_claimed(room_id: String, guild: String)

const SAVE_PATH := "user://rooms.json"

var _rooms: Dictionary = {}  # room_id -> Dictionary
var _door_map: Dictionary = {}  # door_id -> room_id
var _exit_index: Dictionary = {}  # room_id -> int (next exit index to try)


func _ready() -> void:
	call_deferred("_load")


# ── Public API ─────────────────────────────────────────────────────────────

## Get existing room_id for a door position, or create one.
## door_pos: world position of the door
## door_id: unique door string
## opener_rfm: {race, frame, mod, faction, identity_seed, sensorium:{...}, sound_profile:{...}}
## Returns room_id string.
func get_or_create(door_pos: Vector3, door_id: String, opener_rfm: Dictionary) -> String:
	if _door_map.has(door_id):
		return _door_map[door_id]

	var room_id: String = _generate_room_id(door_id)
	var rng_seed: int = hash(door_id + str(opener_rfm.get("identity_seed", 0)))

	var room_data: Dictionary = {
		"seed": rng_seed,
		"pos": [door_pos.x, door_pos.z],
		"exits": [],
		"author_rfm": {
			"race": opener_rfm.get("race", ""),
			"frame": opener_rfm.get("frame", ""),
			"mod": opener_rfm.get("mod", ""),
			"faction": opener_rfm.get("faction", ""),
		},
		"owner_guild": "",
		"saved_as_tscn": false,
		"claimed_by_guild": false,
	}

	_rooms[room_id] = room_data
	_door_map[door_id] = room_id
	_generate_exits(room_id)
	_save()
	room_created.emit(room_id)
	return room_id


## Get room data by room_id.
## Returns {room_id, seed, pos:[x,z], exits:[], author_rfm:{}, owner_guild:"",
##          saved_as_tscn:bool, claimed_by_guild:bool}
func get_room(room_id: String) -> Dictionary:
	var data: Dictionary = _rooms.get(room_id, {})
	if data.is_empty():
		return {}
	var result: Dictionary = data.duplicate()
	result["room_id"] = room_id
	return result


## Get exit room_ids for a room (0-3 exits).
func get_exits(room_id: String) -> Array[String]:
	var data: Dictionary = _rooms.get(room_id, {})
	if data.is_empty():
		return []
	var raw: Array = data.get("exits", [])
	var result: Array[String] = []
	for e in raw:
		result.append(str(e))
	return result


## Register that a guild has claimed this room as their hall.
func claim_room_as_guild(room_id: String, guild: String) -> bool:
	var data: Dictionary = _rooms.get(room_id, {})
	if data.is_empty():
		return false
	data["claimed_by_guild"] = true
	data["owner_guild"] = guild
	_save()
	room_claimed.emit(room_id, guild)
	return true


## Register that a player has saved this room as a backdoor.
func save_room_as_backdoor(room_id: String) -> bool:
	var data: Dictionary = _rooms.get(room_id, {})
	if data.is_empty():
		return false
	data["saved_as_tscn"] = true
	_save()
	return true


## Called when a player walks through a room's exit door (from room_instance.gd's
## body_entered signal). Routes them to the connected room or back to the Liminal.
func on_exit_door_entered(room_id: String, body: Node) -> void:
	var data: Dictionary = _rooms.get(room_id, {})
	if data.is_empty():
		call_deferred("_transition_to", "liminal", true)
		return

	var exits: Array = data.get("exits", [])
	if exits.is_empty():
		call_deferred("_transition_to", "liminal", true)
		return

	# Cycle through exits, skipping the room they are currently in
	var idx: int = _exit_index.get(room_id, 0)
	var start_idx: int = idx
	var tried: int = 0
	var found_exit: String = ""

	while tried < exits.size():
		var candidate: String = str(exits[idx])
		if candidate != room_id:
			found_exit = candidate
			break
		idx = (idx + 1) % exits.size()
		tried += 1

	if found_exit.is_empty():
		call_deferred("_transition_to", "liminal", true)
		return

	# Advance cycle index for next time
	_exit_index[room_id] = (idx + 1) % exits.size()

	# Try loading the room scene
	var scene_path: String = "user://rooms/%s.tscn" % found_exit
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		# Regenerate via RoomGenerator
		var exit_data: Dictionary = _rooms.get(found_exit, {})
		if not exit_data.is_empty():
			var rfm: Dictionary = exit_data.get("author_rfm", {}).duplicate()
			rfm["identity_seed"] = exit_data.get("seed", 0)
			rfm["sensorium"] = {}
			rfm["sound_profile"] = {}
			var scene: PackedScene = RoomGenerator.generate(found_exit, exit_data.get("seed", 0), rfm)
			var room_dir := DirAccess.open("user://")
			if room_dir and not room_dir.dir_exists("rooms"):
				room_dir.make_dir("rooms")
			ResourceSaver.save(scene, scene_path)
			if ResourceLoader.exists(scene_path):
				get_tree().change_scene_to_file(scene_path)
			else:
				call_deferred("_transition_to", "liminal", true)


# ── Internal helpers ───────────────────────────────────────────────────────

## Generates a unique room_id from a door identifier.
func _generate_room_id(door_id: String) -> String:
	var ts: int = Time.get_ticks_usec()
	return "room_%d_%d" % [absi(hash(door_id + str(ts))), ts % 10000]


## Generates 1-3 exit connections for a room.
## 90% chance each exit connects to an existing room within 50 units.
## 10% chance each exit is a "wormhole" — connects to any random existing room.
## Creates new rooms for exits that don't connect to existing ones.
func _generate_exits(room_id: String) -> void:
	var data: Dictionary = _rooms.get(room_id, {})
	if data.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = data["seed"]

	var exit_count: int = rng.randi_range(1, 3)
	var exits: Array[String] = []
	var room_pos: Array = data.get("pos", [0.0, 0.0])
	var pos_vec := Vector2(float(room_pos[0]), float(room_pos[1]))

	for i in exit_count:
		var exit_id: String = ""
		var is_wormhole: bool = rng.randf() < 0.1

		if is_wormhole and not _rooms.is_empty():
			# Wormhole: connect to a random existing room
			var keys: Array = _rooms.keys()
			var chosen: String = str(keys[rng.randi() % keys.size()])
			if chosen != room_id:
				exit_id = chosen

		if exit_id.is_empty():
			# Local: find existing rooms within 50 units
			var close_rooms: Array[String] = []
			for rid: String in _rooms.keys():
				if rid == room_id:
					continue
				var other: Dictionary = _rooms[rid]
				var other_pos: Array = other.get("pos", [0.0, 0.0])
				var dist := Vector2(float(other_pos[0]), float(other_pos[1])).distance_to(pos_vec)
				if dist <= 50.0:
					close_rooms.append(rid)

			if not close_rooms.is_empty() and rng.randf() < 0.9:
				exit_id = close_rooms[rng.randi() % close_rooms.size()]

		if exit_id.is_empty():
			# Create a new room for this exit
			exit_id = _create_exit_room(room_id, i, rng)

		if not exit_id.is_empty():
			exits.append(exit_id)

	data["exits"] = exits


## Creates a new room entry for an exit that doesn't exist yet.
## Positions it near the source room with a random offset.
func _create_exit_room(source_room_id: String, _index: int, rng: RandomNumberGenerator) -> String:
	var source_data: Dictionary = _rooms.get(source_room_id, {})
	if source_data.is_empty():
		return ""

	# Generate a unique room_id
	var exit_id: String = "room_%d_%d" % [absi(rng.randi()), rng.randi() % 10000]
	while _rooms.has(exit_id):
		exit_id = "room_%d_%d" % [absi(rng.randi()), rng.randi() % 10000]

	var source_pos: Array = source_data.get("pos", [0.0, 0.0])
	var offset_x: float = rng.randf_range(-30.0, 30.0)
	var offset_z: float = rng.randf_range(-30.0, 30.0)

	var room_data: Dictionary = {
		"seed": hash(exit_id + str(source_data.get("seed", 0))),
		"pos": [float(source_pos[0]) + offset_x, float(source_pos[1]) + offset_z],
		"exits": [],
		"author_rfm": source_data.get("author_rfm", {}).duplicate(),
		"owner_guild": "",
		"saved_as_tscn": false,
		"claimed_by_guild": false,
	}

	_rooms[exit_id] = room_data
	room_created.emit(exit_id)
	return exit_id


# ── Persistence ────────────────────────────────────────────────────────────

## Serialize room graph to JSON.
func _save() -> void:
	var data: Dictionary = {
		"rooms": _rooms,
		"door_map": _door_map,
	}
	var json: String = JSON.stringify(data)
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(json)


## Deserialize room graph from JSON.
func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		_rooms = parsed.get("rooms", {})
		_door_map = parsed.get("door_map", {})


# ── Layer transition helper ───────────────────────────────────────────────

## Wraps LayerManager.transition_to for deferred invocation.
## Using call_deferred avoids Godot 4.7 limitations with lambdas in
## deferred calls. Do not call directly; use call_deferred("_transition_to", ...).
func _transition_to(layer_id: String, pulled: bool = false) -> void:
	var LayerManager = AutoloadGate.get_node("LayerManager")
	LayerManager.transition_to(layer_id, pulled)
