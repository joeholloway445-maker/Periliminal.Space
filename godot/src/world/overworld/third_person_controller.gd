class_name ThirdPersonController
extends CharacterBody3D
## Third-person overworld controller. Movement feel adapted from Godot TPS
## demos. Visuals resolve through MetahumanCharacter (MetaHuman GLB → interim
## humanoid → CharacterRig) — never the old orange capsule on the ESO bar.

signal chunk_changed(coord: Vector2i)

const MAX_SPEED := 6.0
const SPRINT_SPEED := 10.5
const CROUCH_SPEED := 2.6
const ACCEL := 14.0
const DEACCEL := 14.0
const AIR_ACCEL_FACTOR := 0.5
const JUMP_VELOCITY := 9.0
const CAM_DISTANCE := 5.0
const CAM_HEIGHT := 2.2
const MOUSE_SENSITIVITY := 0.004

var _cam_yaw := 0.0
var _cam_pitch := -0.35
var _last_chunk := Vector2i(2147483647, 2147483647)

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _spring: SpringArm3D
var _camera: Camera3D
## Default to identity (humanoid / MetaHuman). Cat mode is the optional
## Catsino house skin when player_cat.glb is present.
var visual_mode := "identity"
var _visual_root: Node3D
var _collision: CollisionShape3D
var _crouched := false

# ── Procedural body animation state ──────────────────────────────────────
var _anim_time := 0.0
var _body_rot_target := 0.0
var _body_rot_current := 0.0
var _body_lean := Vector3.ZERO
var _was_moving := false

# Animation tuning
const BOB_FREQ := 10.0
const BOB_AMP := 0.04
const SPRINT_BOB_AMP := 0.07
const LEAN_ANGLE := 0.12
const BODY_ROT_SPEED := 8.0
const IDLE_BREATHE_AMP := 0.006
const IDLE_BREATHE_FREQ := 2.0

## actor_id used for combat-system lookups; target_id is set by whatever
## puts this controller into an encounter (lock-on, trigger volume).
@export var actor_id: String = "player"
var _ability_kit: Array[String] = []
var _target_id: String = "target_dummy"

func _ready() -> void:
	add_to_group("player")
	_ensure_collision()
	_build_body()
	_build_camera()
	_refresh_ability_kit()
	if has_node("/root/PlayerProfile"):
		var profile := get_node("/root/PlayerProfile")
		# PlayerProfile has no dedicated faction-changed signal — set_faction()
		# emits the general profile_updated, so re-resolve on every update.
		if profile.has_signal("profile_updated") and not profile.profile_updated.is_connected(_refresh_ability_kit):
			profile.profile_updated.connect(_refresh_ability_kit)

## Faction ability kit (slots 1-8, matching the combat UI hotbar and the
## ability_1..ability_8 input actions). Kits currently hold 4 abilities
## each (see CombatSystemRealtime.ABILITY_DATABASE), so slots 5-8 are
## empty until multi-kit loadouts (companion/skill unlocks) land.
func _refresh_ability_kit() -> void:
	var faction := "Factionless"
	if has_node("/root/PlayerProfile"):
		faction = str(get_node("/root/PlayerProfile").get("faction"))
	if faction == "":
		faction = "Factionless"
	_ability_kit = CombatSystemRealtime.abilities_for_faction(faction)
	if _ability_kit.is_empty():
		_ability_kit = CombatSystemRealtime.abilities_for_faction("Factionless")

func _ability_id_for_slot(slot: int) -> String:
	var index := slot - 1
	if index < 0 or index >= _ability_kit.size():
		return ""
	return _ability_kit[index]

## Set by whatever spawns/targets this controller in a real encounter.
func set_target(target_id: String) -> void:
	_target_id = target_id if target_id != "" else "target_dummy"

func _use_ability_slot(slot: int) -> void:
	var combat := get_node_or_null("/root/CombatRealtime")
	if combat == null:
		return
	var ability_id := _ability_id_for_slot(slot)
	if ability_id == "":
		return
	# CombatSystemRealtime models position abstractly as Vector2 (range/
	# distance only, not physics) — project our forward-aim point onto the
	# XZ plane rather than changing that system's type.
	var aim_point := global_transform.origin + (-global_transform.basis.z * 3.0)
	var target_pos_2d := Vector2(aim_point.x, aim_point.z)
	combat.player_positions[actor_id] = Vector2(global_transform.origin.x, global_transform.origin.z)
	combat.use_ability(actor_id, ability_id, _target_id, target_pos_2d)

## Swap between house-cat presentation and the player's true identity form.
## Used by the PVXC 15-minute PvE ↔ PvP rotation.
func set_visual_mode(mode: String) -> void:
	if mode != "cat" and mode != "identity":
		mode = "cat"
	if mode == visual_mode and _visual_root != null and is_instance_valid(_visual_root):
		return
	visual_mode = mode
	_clear_visual()
	_ensure_collision()
	_build_body()

func _clear_visual() -> void:
	if _visual_root != null and is_instance_valid(_visual_root):
		_visual_root.queue_free()
	_visual_root = null
	# Drop leftover ear/mesh children from older builds (keep camera + collider).
	for c in get_children():
		if c == _spring or c == _collision:
			continue
		if c is SpringArm3D or c is CollisionShape3D:
			continue
		c.queue_free()

func _ensure_collision() -> void:
	if _collision != null and is_instance_valid(_collision):
		return
	_collision = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.2
	_collision.shape = capsule
	_collision.position.y = 0.6
	add_child(_collision)

func _build_body() -> void:
	if visual_mode == "identity":
		_build_identity_body()
		return
	_build_cat_body()

func _build_identity_body() -> void:
	var body := MetahumanCharacter.build_player("identity")
	_visual_root = body
	add_child(body)
	# Humanoid collider
	if _collision != null and _collision.shape is CapsuleShape3D:
		var cap := _collision.shape as CapsuleShape3D
		cap.height = 1.6
		cap.radius = 0.35
		_collision.position.y = 0.9

func _build_cat_body() -> void:
	var body := MetahumanCharacter.build_player("cat")
	_visual_root = body
	add_child(body)
	var humanoid := body is CharacterRig or AssetLibrary.has_asset("player_human") \
		or AssetLibrary.has_asset("metahuman_player")
	if _collision != null and _collision.shape is CapsuleShape3D:
		var cap := _collision.shape as CapsuleShape3D
		if humanoid and not AssetLibrary.has_asset("player_cat"):
			cap.height = 1.6
			cap.radius = 0.35
			_collision.position.y = 0.9
		else:
			cap.height = 1.2
			cap.radius = 0.4
			_collision.position.y = 0.6

func _build_camera() -> void:
	_spring = SpringArm3D.new()
	_spring.spring_length = CAM_DISTANCE
	_spring.position.y = CAM_HEIGHT
	_spring.collision_mask = 1
	add_child(_spring)

	_camera = Camera3D.new()
	_camera.current = true
	_spring.add_child(_camera)
	_update_camera_rotation()

## Public accessor so external systems (e.g. VehicleSeat handing camera
## control back on exit) don't need to guess this controller's internal
## node structure/paths.
func get_camera() -> Camera3D:
	return _camera

const TOUCH_LOOK_SENSITIVITY := 0.006

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not TouchControls.active():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_cam_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_cam_pitch = clampf(_cam_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.2, 0.4)
		_update_camera_rotation()

	for i in range(1, 9):
		if event.is_action_pressed("ability_%d" % i):
			_use_ability_slot(i)

## Touch look — read once a frame from TouchControls.look_delta, so mobile
## can pan the camera with a right-thumb drag without ever needing mouse
## capture. Consumed here so no other reader competes for the same drag.
func _apply_touch_look() -> void:
	if not TouchControls.active():
		return
	var d := TouchControls.consume_look_delta()
	if d.length_squared() < 1.0:
		return
	_cam_yaw -= d.x * TOUCH_LOOK_SENSITIVITY
	_cam_pitch = clampf(_cam_pitch - d.y * TOUCH_LOOK_SENSITIVITY, -1.2, 0.4)
	_update_camera_rotation()

func _update_camera_rotation() -> void:
	_spring.rotation = Vector3(_cam_pitch, _cam_yaw, 0.0)

func _physics_process(delta: float) -> void:
	var Proprioception = AutoloadGate.get_node("Proprioception")
	var DiscoveryManager = AutoloadGate.get_node("DiscoveryManager")
	_apply_touch_look()
	velocity.y -= _gravity * delta

	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Touch devices: the virtual joystick overrides/merges with keys.
	if TouchControls.move_vector.length() > 0.05:
		input_2d = TouchControls.move_vector
	var cam_basis := Basis(Vector3.UP, _cam_yaw)
	var dir := (cam_basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()

	# Crouch: hold Ctrl/C (or the touch posture button). Slower, lower.
	var want_crouch := Input.is_action_pressed("crouch") or TouchControls.crouch_held
	if want_crouch != _crouched:
		_crouched = want_crouch
		if is_instance_valid(_visual_root):
			var tw := create_tween()
			tw.tween_property(_visual_root, "scale:y", 0.55 if _crouched else 1.0, 0.12)

	var sprinting := Input.is_action_pressed("sprint") or TouchControls.sprint_held
	var target_speed := SPRINT_SPEED if sprinting else MAX_SPEED
	if _crouched:
		target_speed = CROUCH_SPEED
	var accel := (ACCEL if dir.dot(Vector3(velocity.x, 0, velocity.z)) > 0.0 else DEACCEL)
	if not is_on_floor():
		accel *= AIR_ACCEL_FACTOR

	var flat := Vector3(velocity.x, 0.0, velocity.z)
	flat = flat.move_toward(dir * target_speed, accel * delta)
	velocity.x = flat.x
	velocity.z = flat.z

	if is_on_floor() and not _crouched \
			and (Input.is_action_just_pressed("jump") or TouchControls.consume_jump()):
		velocity.y = JUMP_VELOCITY
	# Touch E replay moved to TouchControls._process() itself (always
	# running regardless of whether this controller's _physics_process is
	# enabled — it gets disabled while piloting a vehicle, which would
	# otherwise silently break the touch exit-vehicle button).

	move_and_slide()
	# Rotate the visual body to face movement direction with leans/bobs.
	# Uses the actual velocity (not just input) so momentum slides still animate.
	_apply_body_animation(delta, dir)

	# Body memory: gait, turns and posture feed Proprioception every frame.
	Proprioception.feed(delta, _cam_yaw,
		Vector2(velocity.x, velocity.z).length(),
		input_2d.y > 0.5, input_2d.y < -0.5,
		_crouched, is_on_floor())

	var coord = DiscoveryManager.world_pos_to_chunk(global_position)
	if coord != _last_chunk:
		_last_chunk = coord
		chunk_changed.emit(coord)

	# Fell through the world — recover to spawn height.
	if global_position.y < -50.0:
		global_position = Vector3(global_position.x, 30.0, global_position.z)
		velocity = Vector3.ZERO

# ── Procedural body animation ────────────────────────────────────────────
## Rotates the visual body to face the movement direction, adds lean, bob,
## and sway so the character looks alive instead of gliding. Works with
## any body type (GLB, CharacterRig, PeriHumanRig) and doesn't require
## animation clips or a skeleton.
func _apply_body_animation(delta: float, input_dir: Vector3) -> void:
	if not is_instance_valid(_visual_root):
		return

	_anim_time += delta

	var speed: float = Vector3(velocity.x, 0.0, velocity.z).length()
	var moving: bool = speed > 0.15
	var airborne: bool = not is_on_floor()
	var is_sprinting: bool = speed > MAX_SPEED * 0.85 and moving

	# ── Body rotation: smoothly face the movement direction ─────────
	if moving:
		var move_dir := Vector3(velocity.x, 0.0, velocity.z).normalized()
		_body_rot_target = atan2(move_dir.x, move_dir.z)
		_was_moving = true
	elif _was_moving:
		# Keep facing the last movement direction while decelerating
		pass

	_body_rot_current = lerp_angle(_body_rot_current, _body_rot_target, BODY_ROT_SPEED * delta)

	# ── Body lean: tilt forward when moving, back when airborne ─────
	var target_lean_x := 0.0
	if airborne:
		target_lean_x = LEAN_ANGLE * 0.4  # lean back slightly when airborne
	elif moving and not _crouched:
		target_lean_x = -LEAN_ANGLE * (speed / SPRINT_SPEED)  # lean forward

	_body_lean.x = lerp(_body_lean.x, target_lean_x, BODY_ROT_SPEED * delta * 0.5)

	# ── Vertical bob and side sway ──────────────────────────────────
	var bob := 0.0
	var sway := 0.0

	if moving and not airborne and not _crouched:
		var freq := BOB_FREQ * (1.5 if is_sprinting else 1.0)
		var amp := SPRINT_BOB_AMP if is_sprinting else BOB_AMP
		bob = sin(_anim_time * freq) * amp
		sway = sin(_anim_time * freq * 0.5) * amp * 0.4
	elif _crouched:
		# Subtle crouch shift — lower center of mass
		bob = 0.0
		sway = 0.0
	else:
		# Idle breathing — subtle rise and fall
		bob = sin(_anim_time * IDLE_BREATHE_FREQ) * IDLE_BREATHE_AMP
		sway = 0.0

	# ── Apply to visual root ────────────────────────────────────────
	# Set position Y (bob) but don't override the downward offset from crouch
	_visual_root.position.y = bob

	# Apply rotation: yaw faces movement, pitch is lean, roll is sway
	_visual_root.rotation.y = _body_rot_current
	_visual_root.rotation.x = _body_lean.x
	_visual_root.rotation.z = sway
