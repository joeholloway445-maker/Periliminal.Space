class_name CharacterRig
extends Node3D
## Procedural articulate humanoid — a joint skeleton with skinned-looking
## capsule limbs. Unlike the static baked PeriHuman GLB this body has real
## limb joints, so frames/mods visibly resize the build and the preview runs
## a live idle animation (breathing chest, gentle arm sway, weight shift) —
## the creator finally "feels alive" and every frame/mod/slider pick moves
## or reshapes the body you're looking at.
##
## API-compatible with the legacy rig so existing callers keep working:
##   build_from_loadout(race, frame, mod)   # rebuild joints for a build
##   apply_appearance()                     # sliders: height/build + colors
##   .appearance / .sex / .perceived        # same as before

const TextureMaterials = preload("res://src/character/texture_materials.gd")

var _parts: Array[MeshInstance3D] = []

## When true, this rig represents ANOTHER being on the local player's
## client: it renders through the viewer's race lens and the RPS
## perception model (apparent scale, threat aura, loadout visibility).
## Leave false for the player's own preview — you see yourself as you are.
@export var perceived := false
## The other being's profile for perception (level/faction/alignment/stats).
var perceived_profile: Dictionary = {}
## Character-creator appearance sliders (height/build/colors) applied after
## build_from_loadout(). Set by MetahumanCharacter._rig_from_profile.
var appearance: Dictionary = {}
## Body sex ("m"/"f") — female rigs get slightly narrower proportions.
var sex: String = "m"

# Named joints (Node3D pivots) driven by the idle animation below.
var _pelvis: Node3D = null
var _chest: Node3D = null
var _arm_l: Node3D = null
var _arm_r: Node3D = null
var _leg_l: Node3D = null
var _leg_r: Node3D = null

# Shared materials so recoloring via sliders is cheap.
var _mat_skin: StandardMaterial3D = null
var _mat_hair: StandardMaterial3D = null
var _mat_eye: StandardMaterial3D = null
var _mat_outfit: StandardMaterial3D = null

var _elapsed := 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_elapsed += delta
	_idle(_elapsed)

## Breathing + subtle limb sway so the preview body feels alive.
func _idle(t: float) -> void:
	if _chest != null:
		_chest.rotation.x = sin(t * 1.6) * 0.045
	if _pelvis != null:
		_pelvis.rotation.z = sin(t * 0.7) * 0.02
		_pelvis.rotation.x = sin(t * 0.45) * 0.015
	if _arm_l != null and _arm_r != null:
		var sway := sin(t * 0.9) * 0.05
		_arm_l.rotation.z = sway + 0.06
		_arm_r.rotation.z = -sway - 0.06
		_arm_l.rotation.x = sin(t * 1.2) * 0.03
		_arm_r.rotation.x = -sin(t * 1.2) * 0.03
	if _leg_l != null and _leg_r != null:
		var step := sin(t * 0.6) * 0.015
		_leg_l.rotation.x = step
		_leg_r.rotation.x = -step

## Apply slider appearance (and sex proportions) to an already-built rig.
## Height scales Y, build scales X/Z, and the shared materials retint.
func apply_appearance() -> void:
	var h: float = clampf(float(appearance.get("height", 1.0)), 0.85, 1.2)
	var b: float = clampf(float(appearance.get("build", 1.0)), 0.8, 1.3)
	var s := Vector3(b, h, b)
	if sex == "f":
		s *= Vector3(0.94, 0.975, 0.94)
	scale = s

	var skin := Color(appearance.get("skin", "#d9a066"))
	var hair := Color(appearance.get("hair", "#2b1d12"))
	var eye := Color(appearance.get("eye", "#6b4c2a"))
	var outfit := Color(appearance.get("outfit", "#3a4a6a"))
	var glow: float = clampf(float(appearance.get("glow", 0.0)), 0.0, 1.0)
	if _mat_skin != null:
		_mat_skin.albedo_color = skin
		_apply_glow(_mat_skin, glow)
	if _mat_hair != null:
		_mat_hair.albedo_color = hair
	if _mat_eye != null:
		_mat_eye.albedo_color = eye
	if _mat_outfit != null:
		_mat_outfit.albedo_color = outfit

func _apply_glow(m: StandardMaterial3D, glow: float) -> void:
	if glow > 0.0:
		m.emission = m.albedo_color
		m.emission_energy_multiplier = glow
	else:
		m.emission = Color.BLACK
		m.emission_energy_multiplier = 0.0

func build_from_loadout(race: Dictionary, frame: Dictionary, mod: Dictionary = {}) -> void:
	var IdentityLens = AutoloadGate.get_node("IdentityLens")
	clear()
	if race.is_empty() or frame.is_empty():
		return

	var heavy: bool = frame.get("frame_type", frame.get("type", "light")) == "heavy"
	var sm := 1.22 if heavy else 1.0
	var thick := 0.155 if heavy else 0.10
	var mod_scale := Vector3.ONE
	if not mod.is_empty():
		mod_scale = _scale_from_mod(mod.get("id", ""))

	# The other-being read, scaled by the RPS model.
	if perceived and not perceived_profile.is_empty():
		var seen: Dictionary = IdentityLens.perceive_being(
			perceived_profile, race.get("primary_color", Color.WHITE))
		scale *= seen.view.apparent_scale

	var skin_mat := _make_mat(race, Color("#d9a066"))
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = Color("#2b1d12")
	hair_mat.roughness = 0.75
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color("#6b4c2a")
	eye_mat.roughness = 0.1
	eye_mat.metallic = 0.1
	var outfit_mat := _make_mat(race, Color("#3a4a6a"))
	if perceived and not perceived_profile.is_empty():
		if not IdentityLens.perceive_being(perceived_profile, Color.WHITE).view.loadout_visible:
			skin_mat.albedo_color = Color(0.05, 0.05, 0.08)
			outfit_mat.albedo_color = Color(0.05, 0.05, 0.08)
	_mat_skin = skin_mat
	_mat_hair = hair_mat
	_mat_eye = eye_mat
	_mat_outfit = outfit_mat

	# ── Pelvis / hips ─────────────────────────────────────────────────────
	_pelvis = Node3D.new()
	_pelvis.name = "Pelvis"
	_pelvis.position = Vector3(0, 1.0, 0)
	add_child(_pelvis)
	var hips := _add_capsule(_pelvis, Vector3(0, -0.06, 0),
		Vector2(0.20 * sm, 0.30 * sm), outfit_mat)
	hips.name = "Hips"

	# ── Chest / torso + shoulders + neck + head ───────────────────────────
	_chest = Node3D.new()
	_chest.name = "Chest"
	_chest.position = Vector3(0, 0.30 * mod_scale.y, 0)
	_pelvis.add_child(_chest)
	var torso := _add_capsule(_chest, Vector3(0, 0.0, 0),
		Vector2(0.21 * sm, 0.46 * sm), outfit_mat)
	torso.name = "Torso"

	var span := 0.33 * sm
	_arm_l = Node3D.new()
	_arm_l.name = "ShoulderL"
	_arm_l.position = Vector3(-span, 0.10, 0)
	_chest.add_child(_arm_l)
	_arm_r = Node3D.new()
	_arm_r.name = "ShoulderR"
	_arm_r.position = Vector3(span, 0.10, 0)
	_chest.add_child(_arm_r)
	_build_arm(_arm_l, sm, thick, skin_mat)
	_build_arm(_arm_r, sm, thick, skin_mat)
	_neck_and_head(_chest, sm, skin_mat, hair_mat, eye_mat, mod_scale)

	# ── Legs ──────────────────────────────────────────────────────────────
	_leg_l = Node3D.new()
	_leg_l.name = "HipL"
	_leg_l.position = Vector3(-0.12 * sm, -0.02, 0)
	_pelvis.add_child(_leg_l)
	_leg_r = Node3D.new()
	_leg_r.name = "HipR"
	_leg_r.position = Vector3(0.12 * sm, -0.02, 0)
	_pelvis.add_child(_leg_r)
	_build_leg(_leg_l, sm, thick, skin_mat)
	_build_leg(_leg_r, sm, thick, skin_mat)

	apply_appearance()

func _neck_and_head(parent: Node3D, sm: float, skin_mat: StandardMaterial3D,
		hair_mat: StandardMaterial3D, eye_mat: StandardMaterial3D, mod_scale: Vector3) -> void:
	var neck := Node3D.new()
	neck.name = "Neck"
	neck.position = Vector3(0, 0.30 * mod_scale.y, 0)
	parent.add_child(neck)
	var head := _add_sphere(neck, Vector3(0, 0.16 * sm, 0), 0.15 * sm, skin_mat)
	head.name = "Head"
	var hair := _add_sphere(neck, Vector3(0, 0.19 * sm, 0.01), 0.152 * sm, hair_mat)
	hair.name = "Hair"
	hair.scale = Vector3(1.05, 0.92, 1.05)
	_add_sphere(neck, Vector3(-0.05 * sm, 0.17 * sm, 0.145 * sm), 0.022 * sm, eye_mat).name = "EyeR"
	_add_sphere(neck, Vector3(0.05 * sm, 0.17 * sm, 0.145 * sm), 0.022 * sm, eye_mat).name = "EyeL"

func _build_arm(pivot: Node3D, sm: float, thick: float, skin_mat: StandardMaterial3D) -> void:
	_add_capsule(pivot, Vector3(0, -0.13 * sm, 0), Vector2(thick, 0.26 * sm), skin_mat).name = "UpperArm"
	var elbow := Node3D.new()
	elbow.name = "Elbow"
	elbow.position = Vector3(0, -0.26 * sm, 0)
	pivot.add_child(elbow)
	_add_capsule(elbow, Vector3(0, -0.12 * sm, 0), Vector2(thick * 0.9, 0.24 * sm), skin_mat).name = "Forearm"
	_add_sphere(elbow, Vector3(0, -0.27 * sm, 0), thick * 0.85, skin_mat).name = "Hand"

func _build_leg(pivot: Node3D, sm: float, thick: float, skin_mat: StandardMaterial3D) -> void:
	_add_capsule(pivot, Vector3(0, -0.24 * sm, 0), Vector2(thick + 0.02, 0.48 * sm), skin_mat).name = "Thigh"
	var knee := Node3D.new()
	knee.name = "Knee"
	knee.position = Vector3(0, -0.48 * sm, 0)
	pivot.add_child(knee)
	_add_capsule(knee, Vector3(0, -0.23 * sm, 0), Vector2(thick + 0.01, 0.46 * sm), skin_mat).name = "Shin"
	_add_capsule(knee, Vector3(0, -0.49 * sm, -0.04 * sm), Vector2(thick * 0.95, 0.16 * sm), skin_mat).name = "Foot"

func _make_mat(race: Dictionary, fallback: Color) -> StandardMaterial3D:
	var m := TextureMaterials.build_material(race.get("texture_type", ""), race.get("primary_color", Color.WHITE))
	if m is StandardMaterial3D:
		m.albedo_color = fallback
		m.metallic = 0.0
		return m
	var sm := StandardMaterial3D.new()
	sm.albedo_color = fallback
	sm.roughness = 0.62
	return sm

func _add_capsule(parent: Node3D, pos: Vector3, r_and_h: Vector2, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = r_and_h.x
	mesh.height = r_and_h.y
	return _add_part(parent, mesh, pos, mat)

func _add_sphere(parent: Node3D, pos: Vector3, radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add_part(parent, mesh, pos, mat)

func _add_part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = mat
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	_parts.append(instance)
	return instance

func clear() -> void:
	for part in _parts:
		if is_instance_valid(part):
			part.queue_free()
	_parts.clear()
	_pelvis = null
	_chest = null
	_arm_l = null
	_arm_r = null
	_leg_l = null
	_leg_r = null
	_mat_skin = null
	_mat_hair = null
	_mat_eye = null
	_mat_outfit = null
	for child in get_children():
		child.queue_free()

func _scale_from_mod(mod_id: String) -> Vector3:
	match mod_id:
		"towering", "colossus":
			return Vector3(1.0, 1.35, 1.0)
		"compact":
			return Vector3(0.85, 0.8, 0.85)
		"elastic", "serpentine":
			return Vector3(0.95, 1.18, 0.95)
		_:
			return Vector3.ONE
