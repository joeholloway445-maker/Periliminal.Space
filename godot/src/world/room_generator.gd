class_name RoomGenerator
extends Node

const TextureMaterials = preload("res://src/character/texture_materials.gd")
## Generates procedural 3D interior rooms from a seed + RFM profile.
## Called by LiminalDoor when a player walks through, or by RoomNetwork
## to pre-generate connected rooms. Returns a PackedScene ready for
## change_scene_to_file().
##
## Architecture:
##   - Room shape is deterministic from seed (rect / L / T / cross / circle)
##   - Materials tinted by the DISCOVERER's RFM (race texture_type + color)
##   - Every VIEWER's IdentityLens re-tints on top at load time
##   - Light/fog/audio driven by discoverer's FrameSensorium
##   - Props picked from a pool, placed deterministically
##   - At least one exit door (Area3D) leading to another room or back to Liminal

const SAVE_BASE := "user://rooms"

# ── Shape definitions ──────────────────────────────────────────────────────
## Each shape returns an array of wall segments + floor tiles. Every segment
## is {pos:Vector3, size:Vector3, rotation:float, type:String} where type is
## "wall", "floor", or "ceiling". Rotation in radians (0 or PI/2 typically).
enum Shape {RECT, L, T, CROSS, CIRCLE}

# ── Prop pool ──────────────────────────────────────────────────────────────
const PROP_POOL: Array[Dictionary] = [
	{id="table",    size=Vector3(1.2, 0.1, 0.8), color=Color(0.5, 0.35, 0.2), y=0.05},
	{id="chair",    size=Vector3(0.4, 0.5, 0.4), color=Color(0.4, 0.3, 0.2), y=0.25},
	{id="pedestal", size=Vector3(0.3, 0.6, 0.3), color=Color(0.6, 0.55, 0.5), y=0.3},
	{id="bookshelf",size=Vector3(0.8, 1.2, 0.3), color=Color(0.35, 0.25, 0.15), y=0.6},
	{id="crystal",  size=Vector3(0.2, 0.4, 0.2), color=Color(0.2, 0.6, 0.8), y=0.2},
	{id="mirror",   size=Vector3(0.6, 0.8, 0.05), color=Color(0.8, 0.8, 0.9), y=0.4},
	{id="torch",    size=Vector3(0.1, 0.6, 0.1), color=Color(0.6, 0.4, 0.2), y=0.3},
	{id="urn",      size=Vector3(0.25, 0.35, 0.25), color=Color(0.55, 0.5, 0.4), y=0.175},
]

# ── Public API ─────────────────────────────────────────────────────────────

## Generate a room PackedScene. seed = deterministic per-door seed.
## rfm = {race, frame, mod, faction, identity_seed, sensorium:{...}, sound_profile:{...}}
static func generate(room_id: String, seed_val: int, rfm: Dictionary) -> PackedScene:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var room := Node3D.new()
	room.name = "Room_%s" % room_id
	room.set_script(preload("res://src/world/room_instance.gd"))
	room.set("room_id", room_id)

	var shape := _pick_shape(rng)
	var dimensions := _pick_dimensions(rng)
	var sensorium: Dictionary = rfm.get("sensorium", {})
	if sensorium.is_empty():
		sensorium = FrameSensorium.of(rfm.get("frame", "flux"))
	var discoverer_race: String = rfm.get("race", "tabby")
	var discoverer_color: Color = _race_color(discoverer_race)
	var sound_prof: Dictionary = rfm.get("sound_profile", {})

	_build_walls(room, shape, dimensions, discoverer_race, discoverer_color, rng)
	_build_floor(room, shape, dimensions, discoverer_race, discoverer_color)
	_build_ceiling(room, shape, dimensions, discoverer_race, discoverer_color)
	_build_lighting(room, sensorium)
	_build_fog(room, sensorium)
	_build_props(room, dimensions, rng, discoverer_race, discoverer_color)
	_build_exit_door(room, dimensions, rfm)
	_build_ambient_audio(room, sound_prof, rfm)

	return _pack(room)

# ── Shape & dimensions ────────────────────────────────────────────────────

static func _pick_shape(rng: RandomNumberGenerator) -> int:
	var shapes := [Shape.RECT, Shape.L, Shape.T, Shape.CROSS, Shape.CIRCLE]
	return shapes[rng.randi() % shapes.size()]

static func _pick_dimensions(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"w": rng.randf_range(6.0, 12.0),
		"d": rng.randf_range(6.0, 12.0),
		"h": rng.randf_range(3.0, 5.0),
	}

## Primary color for a race id (fallback chain).
static func _race_color(race_id: String) -> Color:
	var race := RaceDataCharacter.get_race(race_id)
	if race.has("primary_color") and race.primary_color is Color:
		return race.primary_color
	# Sensible fallbacks by race name substring
	var rl := race_id.to_lower()
	if "lumen" in rl:      return Color(0.9, 0.85, 1.0)
	if "umbra" in rl:      return Color(0.15, 0.1, 0.25)
	if "starfall" in rl:   return Color(0.3, 0.4, 0.9)
	if "ember" in rl:      return Color(0.9, 0.4, 0.2)
	if "cinder" in rl:     return Color(0.5, 0.25, 0.1)
	if "dust" in rl:       return Color(0.6, 0.55, 0.4)
	if "void" in rl:       return Color(0.05, 0.05, 0.15)
	if "echo" in rl:       return Color(0.7, 0.8, 0.9)
	if "wild" in rl:       return Color(0.3, 0.6, 0.3)
	if "abyss" in rl:      return Color(0.05, 0.1, 0.2)
	if "glimmer" in rl:    return Color(0.85, 0.9, 0.7)
	if "hollow" in rl:     return Color(0.35, 0.3, 0.25)
	if "glacier" in rl:    return Color(0.75, 0.85, 1.0)
	if "thorn" in rl:      return Color(0.3, 0.5, 0.2)
	if "flux" in rl:       return Color(0.6, 0.6, 0.7)
	if "veil" in rl:       return Color(0.6, 0.55, 0.75)
	return Color(0.5, 0.5, 0.6)

# ── Construction helpers ──────────────────────────────────────────────────

## Build a MeshInstance3D with a box and discoverer-tinted material.
static func _make_wall(
	pos: Vector3, size: Vector3, rotation: float,
	race_id: String, base_color: Color
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var race := RaceDataCharacter.get_race(race_id)
	var tex_type: String = race.get("texture_type", "morphic")
	var lens_color: Color = race.get("primary_color", base_color)
	box.material = TextureMaterials.build_material(tex_type, lens_color.lerp(base_color, 0.3))
	mi.mesh = box
	mi.position = pos
	mi.rotation.y = rotation
	return mi

static func _make_floor(
	pos: Vector3, size: Vector3,
	race_id: String, base_color: Color
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var race := RaceDataCharacter.get_race(race_id)
	var tex_type: String = race.get("texture_type", "morphic")
	var lens_color: Color = race.get("primary_color", base_color)
	# Floor is darker/more grounded
	box.material = TextureMaterials.build_material(tex_type, lens_color.lerp(base_color, 0.15).darkened(0.3))
	mi.mesh = box
	mi.position = pos
	return mi

static func _make_ceiling(
	pos: Vector3, size: Vector3,
	race_id: String, base_color: Color
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var race := RaceDataCharacter.get_race(race_id)
	var tex_type: String = race.get("texture_type", "morphic")
	var lens_color: Color = race.get("primary_color", base_color)
	# Ceiling is lighter
	box.material = TextureMaterials.build_material(tex_type, lens_color.lerp(base_color, 0.5).lightened(0.2))
	mi.mesh = box
	mi.position = pos
	return mi

# ── Room builders ─────────────────────────────────────────────────────────

static func _build_walls(
	parent: Node3D, shape: int, dim: Dictionary,
	race_id: String, base_color: Color, rng: RandomNumberGenerator
) -> void:
	var w: float = dim.get("w", 8.0)
	var d: float = dim.get("d", 8.0)
	var h: float = dim.get("h", 4.0)
	var thickness: float = 0.15

	match shape:
		Shape.RECT:
			# Four walls at cardinal edges
			parent.add_child(_make_wall(Vector3(0, h/2, -d/2), Vector3(w, h, thickness), 0.0, race_id, base_color))       # back
			parent.add_child(_make_wall(Vector3(0, h/2, d/2),  Vector3(w, h, thickness), 0.0, race_id, base_color))       # front
			parent.add_child(_make_wall(Vector3(-w/2, h/2, 0), Vector3(thickness, h, d), 0.0, race_id, base_color))      # left
			parent.add_child(_make_wall(Vector3(w/2, h/2, 0),  Vector3(thickness, h, d), 0.0, race_id, base_color))      # right
		Shape.L:
			# Main rectangle: back, left-front segment, right, plus dividing wall
			parent.add_child(_make_wall(Vector3(0, h/2, -d/2), Vector3(w, h, thickness), 0.0, race_id, base_color))
			parent.add_child(_make_wall(Vector3(-w/4, h/2, d/4), Vector3(thickness, h, d/2), 0.0, race_id, base_color))
			parent.add_child(_make_wall(Vector3(w/2, h/2, 0), Vector3(thickness, h, d), 0.0, race_id, base_color))
			var split := w * 0.35
			parent.add_child(_make_wall(Vector3(-w/2 + split, h/2, 0), Vector3(thickness, h, d), 0.0, race_id, base_color))
		Shape.T:
			# T-shaped: back wall, front-left/right, center dividing wall
			parent.add_child(_make_wall(Vector3(0, h/2, -d/2), Vector3(w, h, thickness), 0.0, race_id, base_color))
			parent.add_child(_make_wall(Vector3(-w/3, h/2, d/2), Vector3(w*0.55, h, thickness), 0.0, race_id, base_color))
			parent.add_child(_make_wall(Vector3(w/3, h/2, d/2), Vector3(w*0.55, h, thickness), 0.0, race_id, base_color))
			parent.add_child(_make_wall(Vector3(0, h/2, 0), Vector3(thickness, h, d*0.5), 0.0, race_id, base_color))
		Shape.CROSS:
			# Cross: four outer walls + internal cross walls
			parent.add_child(_make_wall(Vector3(0, h/2, -d/2), Vector3(w, h, thickness), 0.0, race_id, base_color))
			parent.add_child(_make_wall(Vector3(0, h/2, d/2), Vector3(w, h, thickness), 0.0, race_id, base_color))
			parent.add_child(_make_wall(Vector3(-w/2, h/2, 0), Vector3(thickness, h, d), 0.0, race_id, base_color))
			parent.add_child(_make_wall(Vector3(w/2, h/2, 0), Vector3(thickness, h, d), 0.0, race_id, base_color))
			# Internal dividers
			parent.add_child(_make_wall(Vector3(0, h/2, 0), Vector3(thickness, h, d*0.6), 0.0, race_id, base_color))
			var cross_arm := rng.randf_range(0.25, 0.4)
			parent.add_child(_make_wall(Vector3(0, h/2, -d*cross_arm), Vector3(w*0.5, h, thickness), 0.0, race_id, base_color))
			parent.add_child(_make_wall(Vector3(0, h/2, d*cross_arm), Vector3(w*0.5, h, thickness), 0.0, race_id, base_color))
		Shape.CIRCLE:
			# Approximate circle with 8-segment octagon walls
			var radius := minf(w, d) * 0.45
			var seg_count := 8
			for i in seg_count:
				var angle := i * TAU / seg_count
				var nx := cos(angle)
				var nz := sin(angle)
				var seg_w := radius * 2 * sin(PI / seg_count)
				var cx := nx * radius
				var cz := nz * radius
				parent.add_child(_make_wall(
					Vector3(cx, h/2, cz),
					Vector3(seg_w, h, thickness),
					-angle,
					race_id, base_color
				))

static func _build_floor(
	parent: Node3D, shape: int, dim: Dictionary,
	race_id: String, base_color: Color
) -> void:
	var w: float = dim.get("w", 8.0)
	var d: float = dim.get("d", 8.0)
	var floor_mesh := _make_floor(Vector3(0, 0.01, 0), Vector3(w, 0.05, d), race_id, base_color)
	parent.add_child(floor_mesh)
	# Add a StaticBody for physics collision
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, 0.1, d)
	cs.shape = box
	sb.add_child(cs)
	sb.position = Vector3(0, -0.025, 0)
	parent.add_child(sb)

static func _build_ceiling(
	parent: Node3D, shape: int, dim: Dictionary,
	race_id: String, base_color: Color
) -> void:
	var w: float = dim.get("w", 8.0)
	var d: float = dim.get("d", 8.0)
	var h: float = dim.get("h", 4.0)
	var ceiling_mesh := _make_ceiling(Vector3(0, h, 0), Vector3(w, 0.05, d), race_id, base_color)
	parent.add_child(ceiling_mesh)

static func _build_lighting(parent: Node3D, sensorium: Dictionary) -> void:
	var light := OmniLight3D.new()
	light.light_color = sensorium.get("light", Color(0.8, 0.8, 1.0))
	light.light_energy = sensorium.get("energy", 1.0)
	light.light_indirect_energy = 1.5
	light.omni_range = 16.0
	light.position = Vector3(0, sensorium.get("fog", 0.15) * 8.0 + 3.0, 0)
	parent.add_child(light)

	# Rim light (softer, opposite)
	var rim := OmniLight3D.new()
	rim.light_color = sensorium.get("light", Color(0.8, 0.8, 1.0)).darkened(0.4)
	rim.light_energy = sensorium.get("energy", 1.0) * 0.3
	rim.omni_range = 10.0
	rim.position = Vector3(0, 0.5, -sensorium.get("fog", 0.15) * 6.0 - 3.0)
	parent.add_child(rim)

static func _build_fog(parent: Node3D, sensorium: Dictionary) -> void:
	var env := WorldEnvironment.new()
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = sensorium.get("light", Color(0.8, 0.8, 1.0)).darkened(0.5)
	sky.sky_horizon_color = sensorium.get("light", Color(0.8, 0.8, 1.0)).darkened(0.7)
	sky.ground_horizon_color = Color(0.05, 0.05, 0.08)
	sky.ground_bottom_color = Color(0.02, 0.0, 0.03)
	var sky_instance := Sky.new()
	sky_instance.sky_material = sky
	env.environment = Environment.new()
	env.environment.sky = sky_instance
	env.environment.background_mode = Environment.BG_SKY
	env.environment.ambient_light_color = sensorium.get("light", Color(0.8, 0.8, 1.0)).darkened(0.6)
	env.environment.ambient_light_energy = 0.4
	var fog_density := sensorium.get("fog", 0.1)
	env.environment.fog_enabled = true
	env.environment.fog_density = fog_density * 0.03
	env.environment.fog_light_color = sensorium.get("light", Color(0.8, 0.8, 1.0))
	parent.add_child(env)

static func _build_props(
	parent: Node3D, dim: Dictionary, rng: RandomNumberGenerator,
	race_id: String, base_color: Color
) -> void:
	var count: int = rng.randi_range(3, 8)
	var margin: float = 1.5
	var w: float = dim.get("w", 8.0) * 0.5 - margin
	var d: float = dim.get("d", 8.0) * 0.5 - margin
	var used_positions: Array[Vector3] = []

	for i in count:
		var prop_def: Dictionary = PROP_POOL[rng.randi() % PROP_POOL.size()]
		# Deterministic placement, avoid overlaps
		var attempts := 0
		var pos: Vector3
		var ok := false
		while not ok and attempts < 10:
			pos = Vector3(
				rng.randf_range(-w, w),
				prop_def.y,
				rng.randf_range(-d, d)
			)
			ok = true
			for used in used_positions:
				if used.distance_to(pos) < 1.0:
					ok = false
					break
			attempts += 1
		if not ok:
			continue
		used_positions.append(pos)

		var mi := MeshInstance3D.new()
		var shape_mesh := BoxMesh.new()
		shape_mesh.size = prop_def.size

		# Tint prop with discoverer's race color
		var race := RaceDataCharacter.get_race(race_id)
		var tex_type: String = race.get("texture_type", "morphic")
		var lens_color: Color = race.get("primary_color", base_color)
		var prop_color: Color = prop_def.color.lerp(lens_color, 0.15)
		shape_mesh.material = TextureMaterials.build_material(tex_type, prop_color)
		mi.mesh = shape_mesh
		mi.position = pos
		mi.rotation.y = rng.randf_range(0, TAU)
		parent.add_child(mi)

		# Some props get an aura glow (crystal, torch, mirror)
		if prop_def.id in ["crystal", "torch"]:
			var glow := OmniLight3D.new()
			glow.light_color = prop_def.color
			glow.light_energy = 0.4
			glow.omni_range = 2.0
			glow.position = pos + Vector3(0, prop_def.y + 0.2, 0)
			parent.add_child(glow)

static func _build_exit_door(parent: Node3D, dim: Dictionary, rfm: Dictionary) -> void:
	var h: float = dim.get("h", 4.0)
	var door := Area3D.new()
	door.name = "ExitDoor"
	door.input_ray_pickable = true

	# Door frame (mesh)
	var frame_w := 0.9
	var frame_h := 2.0
	var frame := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(frame_w, frame_h, 0.08)
	var race_id: String = rfm.get("race", "tabby")
	var base_color := _race_color(race_id)
	var race := RaceDataCharacter.get_race(race_id)
	var tex_type: String = race.get("texture_type", "morphic")
	var lens_color: Color = race.get("primary_color", base_color)
	box.material = TextureMaterials.build_material(tex_type, lens_color.lightened(0.2))
	frame.mesh = box
	frame.position = Vector3(0, frame_h/2, dim.get("d", 8.0)/2 - 0.1)
	door.add_child(frame)

	# Collision shape for interaction
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.5
	cs.shape = sph
	cs.position = frame.position
	door.add_child(cs)

	door.body_entered.connect(_on_door_body_entered.bind(rfm))
	parent.add_child(door)

static func _on_door_body_entered(body: Node, rfm: Dictionary) -> void:
	if body is CharacterBody3D:
		var tree := body.get_tree()
		if tree == null:
			return
		var room_node := body.get_parent()
		var room_id := ""
		if room_node != null and room_node.has_method("get_room_id"):
			room_id = str(room_node.get_room_id())
		# Delegate to RoomNetwork for exit resolution
		var network := tree.root.get_node_or_null("/root/RoomNetwork") as Node
		if network != null and network.has_method("on_exit_door_entered"):
			network.call("on_exit_door_entered", room_id, body)

static func _build_ambient_audio(parent: Node3D, sound_prof: Dictionary, rfm: Dictionary) -> void:
	var player := AudioStreamPlayer3D.new()
	player.name = "RoomAmbience"

	# Use the sensorium's mode/tempo/timbre to pick a generated ambience
	var mode_str := str(sound_prof.get("mode", "ionian"))
	var tempo := float(sound_prof.get("tempo", 80.0))
	player.pitch_scale = tempo / 80.0
	player.max_distance = 20.0
	player.unit_db = -12.0

	# Generate a simple sine-wave hum based on mode
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 1.0
	player.stream = stream
	parent.add_child(player)

# ── Final packing ──────────────────────────────────────────────────────────

static func _pack(root: Node3D) -> PackedScene:
	var scene := PackedScene.new()
	scene.pack(root)
	root.queue_free()
	return scene
