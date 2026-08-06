class_name PeriHumanRig
extends Node3D
## A living PeriHuman — the assembled runtime character:
##   Skeleton3D (humanoid, retarget-ready) + skinned morphable body mesh
##   + eyes (procedural iris) + hairstyle + brows, all grown from HumanDNA.
##
## Feature parity targets vs. Epic's MetaHuman runtime:
##   - DNA-driven body/face        -> apply_dna()
##   - Facial rig                  -> blend shapes (blink/jaw_open/smile/
##                                    brow_raise) via set_expression()
##   - Idle life                   -> procedural breathing, blinking,
##                                    eye saccades, head micro-motion
##   - Locomotion                  -> procedural walk/run gait driven by
##                                    set_locomotion(0..1); no clips needed
##   - LODs                        -> set_lod(0..2), optional auto_lod
##   - Animation retargeting       -> standard humanoid bone names
##
## Usage:
##   var rig := PeriHumanRig.new()
##   rig.dna = HumanPresets.by_name("Freja")   # or HumanDNA.random(id)
##   add_child(rig)                            # builds on _ready
##   rig.set_expression("smile", 0.6)

@export var auto_idle := true
## When true, distance to the current camera picks the LOD tier.
@export var auto_lod := false

var dna: HumanDNA

var _skeleton: Skeleton3D
var _body: MeshInstance3D
var _head_pivot: Node3D
var _eyes: Array[Node3D] = []
var _lod := 0
var _mesh_cache: Dictionary = {}   # lod -> {mesh, meta, hair, brows}
var _expression: Dictionary = {}   # user-set persistent morph targets
var _chest_idx := -1
var _head_idx := -1
var _chest_rest := Vector3.ZERO
## Locomotion bones + the neutral hip height, cached so the procedural gait
## (see _walk_pose) doesn't look them up every frame.
var _hips_idx := -1
var _spine_idx := -1
var _l_leg := -1
var _r_leg := -1
var _l_calf := -1
var _r_calf := -1
var _l_arm := -1
var _r_arm := -1
var _hips_rest := Vector3.ZERO
## 0 = standing, 1 = full run. The controller sets the target each frame via
## set_locomotion(); _loco eases toward it so starts/stops aren't a snap, and
## _gait is the walk-cycle phase advanced at a cadence that scales with speed.
var locomotion_target := 0.0
var _loco := 0.0
var _gait := 0.0
var _loco_active := false
var _time := 0.0
var _blink_phase := -1.0
var _next_blink := 2.0
var _next_saccade := 1.0
var _lod_check := 0.0
## Set by apply_perception() when this rig represents ANOTHER being on the
## local player's client (see IdentityLens.perceive_being) — "" means this
## is the local player's own body, rendered as-is with no view-scale style.
var _perceived_style := ""
var _glitch_mat: StandardMaterial3D
var _glitch_base_energy := 0.0

func _ready() -> void:
	if dna == null:
		dna = HumanDNA.new()
	if _skeleton == null:
		apply_dna(dna)

## Grow (or regrow) the whole human from a genome.
func apply_dna(new_dna: HumanDNA, lod: int = 0) -> void:
	dna = new_dna
	_mesh_cache.clear()
	if _skeleton != null:
		_skeleton.queue_free()
	_eyes.clear()

	var rig := HumanSkeletonBuilder.build(dna)
	_skeleton = rig.skeleton
	add_child(_skeleton)
	_chest_idx = rig.bones["Chest"]
	_head_idx = rig.bones["Head"]
	_chest_rest = _skeleton.get_bone_rest(_chest_idx).origin
	_hips_idx = rig.bones.get("Hips", -1)
	_spine_idx = rig.bones.get("Spine", -1)
	_l_leg = rig.bones.get("LeftUpperLeg", -1)
	_r_leg = rig.bones.get("RightUpperLeg", -1)
	_l_calf = rig.bones.get("LeftLowerLeg", -1)
	_r_calf = rig.bones.get("RightLowerLeg", -1)
	_l_arm = rig.bones.get("LeftUpperArm", -1)
	_r_arm = rig.bones.get("RightUpperArm", -1)
	_hips_rest = _skeleton.get_bone_rest(_hips_idx).origin if _hips_idx >= 0 else Vector3.ZERO

	_body = MeshInstance3D.new()
	_body.name = "Body"
	_skeleton.add_child(_body)  # MeshInstance3D.skeleton defaults to ".."
	_body.skin = _skeleton.create_skin_from_rest_transforms()
	_body.material_override = HumanMaterials.skin(dna)
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	# Everything head-mounted rides a bone attachment so it follows animation.
	var attach := BoneAttachment3D.new()
	attach.name = "HeadAttachment"
	_skeleton.add_child(attach)
	attach.bone_name = "Head"
	_head_pivot = Node3D.new()
	_head_pivot.name = "HeadPivot"
	attach.add_child(_head_pivot)
	var head_joint: Vector3 = rig.joints["head"]
	var head_center: Vector3 = rig.joints["head_center"]
	_head_pivot.position = head_center - head_joint

	_rig_data = rig
	set_lod(lod, true)
	_build_eyes()
	_apply_expression_values()

var _rig_data: Dictionary = {}

## Swap mesh detail tier (0 = hero, 2 = crowd). Skeleton and eyes persist.
func set_lod(lod: int, force: bool = false) -> void:
	lod = clampi(lod, 0, HumanMeshBuilder.LOD_COUNT - 1)
	if lod == _lod and not force:
		return
	_lod = lod
	if not _mesh_cache.has(lod):
		var built := HumanMeshBuilder.build_body(dna, _rig_data, lod)
		_mesh_cache[lod] = {
			"mesh": built.mesh,
			"meta": built.meta,
			"hair": HumanMeshBuilder.build_hair(dna, _rig_data.measure, lod),
			"brows": HumanMeshBuilder.build_brows(dna, _rig_data.measure),
		}
	var entry: Dictionary = _mesh_cache[lod]
	_body.mesh = entry.mesh
	_apply_expression_values()
	_build_head_dressing(entry)

func _build_head_dressing(entry: Dictionary) -> void:
	for child in _head_pivot.get_children():
		if child.name != "Eyes":
			child.queue_free()
	if entry.hair != null:
		var hair := MeshInstance3D.new()
		hair.name = "Hair"
		hair.mesh = entry.hair
		hair.material_override = HumanMaterials.hair(dna.hair_color)
		hair.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_head_pivot.add_child(hair)
	if dna.get_gene("brow_thickness") > 0.05:
		var brows := MeshInstance3D.new()
		brows.name = "Brows"
		brows.mesh = entry.brows
		brows.material_override = HumanMaterials.hair(dna.hair_color.darkened(0.25))
		_head_pivot.add_child(brows)

func _build_eyes() -> void:
	var eyes_root := Node3D.new()
	eyes_root.name = "Eyes"
	_head_pivot.add_child(eyes_root)
	var meta: Dictionary = _mesh_cache[_lod].meta
	var head_center: Vector3 = meta.head_center
	var eye_r: float = meta.eye_radius
	for side in ["l", "r"]:
		var eye := Node3D.new()
		eye.name = "Eye_" + side
		eye.position = (meta.eyes[side] as Vector3) - head_center
		eyes_root.add_child(eye)
		var ball := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = eye_r
		sphere.height = eye_r * 2.0
		sphere.radial_segments = 16
		sphere.rings = 8
		ball.mesh = sphere
		ball.material_override = HumanMaterials.eyeball()
		eye.add_child(ball)
		var iris := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * eye_r * 1.35
		iris.mesh = quad
		iris.material_override = HumanMaterials.iris(dna.eye_color)
		iris.position = Vector3(0, 0, eye_r * 0.92)
		eye.add_child(iris)
		_eyes.append(eye)

# ------------------------------------------------------------ perception

## Applies another client's view of THIS rig — the material + view-scale
## style IdentityLens.perceive_being() already computed for this being on
## the local viewer's screen (race lens, RPS aura, glitchy/holographic/
## shadowy/off). Call after apply_dna() whenever this rig represents
## someone else (a remote player, an NPC) rather than the local player's
## own body. `mat` replaces the plain skin material outright, same as
## CharacterRig's `perceived` path does for the capsule rig.
##
## Deliberately does NOT touch `scale` — apparent_scale (view.apparent_scale)
## is the caller's to apply whichever way it already places this rig
## (RemotePlayer, for one, scales its own root rather than the rig).
func apply_perception(view: Dictionary, mat: StandardMaterial3D) -> void:
	_perceived_style = str(view.get("style", ""))
	if _body == null or mat == null:
		return
	_body.material_override = mat
	_glitch_mat = mat if _perceived_style == "glitchy" else null
	_glitch_base_energy = mat.emission_energy_multiplier if mat.emission_enabled else 0.0

# ------------------------------------------------------------- expressions

## Persistent expression control, e.g. set_expression("smile", 0.7).
## Morph names: see HumanMeshBuilder.MORPHS.
func set_expression(morph: String, value: float) -> void:
	_expression[morph] = clampf(value, 0.0, 1.0)
	_apply_expression_values()

func _apply_expression_values() -> void:
	if _body == null or _body.mesh == null:
		return
	for morph in HumanMeshBuilder.MORPHS:
		var idx := _body.find_blend_shape_by_name(morph)
		if idx < 0:
			continue
		var v: float = _expression.get(morph, 0.0)
		if morph == "blink":
			v = maxf(v, _blink_amount())
		_body.set_blend_shape_value(idx, v)

func _blink_amount() -> float:
	if _blink_phase < 0.0:
		return 0.0
	# 0.14s triangular envelope.
	var t := _blink_phase / 0.14
	return 1.0 - absf(t * 2.0 - 1.0)

# ----------------------------------------------------------------- locomotion

## Drive the walk/run cycle. `amount` is 0 (standing) .. 1 (full sprint) —
## the overworld controller passes horizontal speed normalised by its sprint
## speed. The rig eases toward it, so there's no need to smooth on the caller
## side. Values above 1 just cap out at the run pose.
func set_locomotion(amount: float) -> void:
	locomotion_target = clampf(amount, 0.0, 1.0)

## Procedural gait: contralateral leg/arm swing with knee flex, a little
## pelvis twist and forward lean, and a twice-per-stride vertical bob. All
## amplitudes scale from a walk to a run with _loco, and the whole thing
## fades to the rest pose as the character stops, so it blends seamlessly
## with the idle breathing that runs on the spine/head above it.
func _walk_pose(delta: float) -> void:
	if _l_leg < 0:
		return
	_loco = move_toward(_loco, locomotion_target, delta * 4.5)
	if _loco <= 0.001:
		if _loco_active:
			_reset_walk_bones()
			_loco_active = false
		return
	_loco_active = true

	# Cadence rises with speed; a full cycle is two steps.
	_gait = fmod(_gait + delta * TAU * lerpf(1.15, 2.7, _loco), TAU)
	var s := sin(_gait)

	var leg_amp := lerpf(0.16, 0.62, _loco)
	var arm_amp := lerpf(0.06, 0.34, _loco)
	var knee_amp := lerpf(0.26, 0.98, _loco)
	var droop := lerpf(0.0, 0.55, _loco)  # T-pose arms fall to the sides at speed

	# Thighs swing opposite each other about the sideways (X) axis.
	_pose_x(_l_leg, s * leg_amp)
	_pose_x(_r_leg, -s * leg_amp)
	# Knees flex on the forward-swing half of each leg's cycle (they only bend
	# one way), so the foot lifts as it comes through.
	_pose_x(_l_calf, -knee_amp * maxf(0.0, sin(_gait)))
	_pose_x(_r_calf, -knee_amp * maxf(0.0, sin(_gait + PI)))
	# Arms: droop from the T-pose down to the sides, then counter-swing about
	# the vertical (Y) — the arm opposite each leg goes forward.
	_skeleton.set_bone_pose_rotation(_l_arm,
		Quaternion(Basis.from_euler(Vector3(0.0, -s * arm_amp, -droop))))
	_skeleton.set_bone_pose_rotation(_r_arm,
		Quaternion(Basis.from_euler(Vector3(0.0, s * arm_amp, droop))))

	# Pelvis: yaw twist with the stride, plus a slight forward lean into a run
	# on the spine that counter-rotates the twist so the chest stays square-ish.
	if _spine_idx >= 0:
		_skeleton.set_bone_pose_rotation(_spine_idx,
			Quaternion(Basis.from_euler(Vector3(lerpf(0.0, 0.13, _loco), -s * 0.05 * _loco, 0.0))))
	_skeleton.set_bone_pose_rotation(_hips_idx,
		Quaternion(Vector3(0, 1, 0), s * 0.06 * _loco))
	# Vertical bob: the body lifts twice per stride, at each foot plant.
	var bob := -0.012 * _loco * (0.5 - 0.5 * cos(2.0 * _gait))
	_skeleton.set_bone_pose_position(_hips_idx, _hips_rest + Vector3(0, bob, 0))

func _pose_x(bone_idx: int, angle: float) -> void:
	if bone_idx >= 0:
		_skeleton.set_bone_pose_rotation(bone_idx, Quaternion(Vector3(1, 0, 0), angle))

## Settle every locomotion-driven bone back to its rest pose in one pass, so a
## character that stops mid-stride doesn't freeze holding a step.
func _reset_walk_bones() -> void:
	for b in [_l_leg, _r_leg, _l_calf, _r_calf, _l_arm, _r_arm, _spine_idx]:
		if b >= 0:
			_skeleton.set_bone_pose_rotation(b, Quaternion.IDENTITY)
	if _hips_idx >= 0:
		_skeleton.set_bone_pose_rotation(_hips_idx, Quaternion.IDENTITY)
		_skeleton.set_bone_pose_position(_hips_idx, _hips_rest)

# ------------------------------------------------------------------ idle life

func _process(delta: float) -> void:
	if auto_lod:
		_lod_check -= delta
		if _lod_check <= 0.0:
			_lod_check = 0.5
			var vp := get_viewport()
			var cam: Camera3D = vp.get_camera_3d() if vp != null else null
			if cam != null:
				var dist := cam.global_position.distance_to(global_position)
				set_lod(0 if dist < 5.0 else (1 if dist < 12.0 else 2))
	if _glitch_mat != null:
		# Broken-signal flicker: emission jumps between dim and overbright
		# on a jittery cadence — the one style with a live per-frame tell,
		# since this rig already runs an idle process loop either way.
		var jitter := sin(Time.get_ticks_msec() * 0.03 + get_instance_id() % 100) \
			* sin(Time.get_ticks_msec() * 0.011)
		_glitch_mat.emission_enabled = true
		_glitch_mat.emission_energy_multiplier = maxf(0.0, _glitch_base_energy + jitter * 0.8)
	if _skeleton == null:
		return
	_time += delta

	# Walking/running is a separate layer from idle life — it drives the
	# legs/arms/pelvis and runs whether or not idle breathing is on, so a
	# rig with auto_idle off still animates when it moves.
	_walk_pose(delta)

	if not auto_idle:
		return

	# Breathing: the chest rises ~4mm on a slow sine.
	var breath := sin(_time * 1.7) * 0.004
	_skeleton.set_bone_pose_position(_chest_idx, _chest_rest + Vector3(0, breath, breath * 0.5))

	# Head micro-motion: barely-there drift sells "alive" more than anything.
	var sway := Basis.from_euler(Vector3(
		sin(_time * 0.43) * 0.015, sin(_time * 0.31) * 0.03, sin(_time * 0.57) * 0.008))
	_skeleton.set_bone_pose_rotation(_head_idx, Quaternion(sway))

	# Blinking.
	if _blink_phase >= 0.0:
		_blink_phase += delta
		if _blink_phase >= 0.14:
			_blink_phase = -1.0
		_apply_expression_values()
	else:
		_next_blink -= delta
		if _next_blink <= 0.0:
			_blink_phase = 0.0
			_next_blink = randf_range(1.8, 5.5)

	# Eye saccades: quick small refixations, both eyes together.
	_next_saccade -= delta
	if _next_saccade <= 0.0:
		_next_saccade = randf_range(0.6, 2.4)
		var yaw := randf_range(-0.07, 0.07)
		var pitch := randf_range(-0.04, 0.04)
		for eye in _eyes:
			eye.rotation = Vector3(pitch, yaw, 0)
