class_name RemotePlayer
extends Node3D
## Another player (or offline ghost) in the world. Default presentation is
## the casino house cat; PVXC PvP phase swaps to a perceived CharacterRig
## (race/frame silhouette) so fights happen as yourselves.

var peer_id := ""
var profile: Dictionary = {}
## "cat" or "identity" — mirrors ThirdPersonController.visual_mode.
var visual_mode := "identity"
var _body_root: Node3D
var _plate: Label3D
## PeriHuman body + last position, so this remote player's legs walk/run at
## the speed it's actually travelling on screen (measured from position deltas,
## since remote motion arrives as position updates, not a velocity).
var _peri_rig: PeriHumanRig
var _barker: PersonaBarker
var _last_pos: Vector3
var _has_last := false

func setup(id: String, p: Dictionary, mode: String = "identity") -> void:
	peer_id = id
	profile = p
	set_visual_mode(mode)

func set_visual_mode(mode: String) -> void:
	if mode != "cat" and mode != "identity":
		mode = "cat"
	visual_mode = mode
	if _body_root != null and is_instance_valid(_body_root):
		_body_root.queue_free()
	_body_root = null
	if _plate != null and is_instance_valid(_plate):
		_plate.queue_free()
	_plate = null
	_rebuild_body()

func _rebuild_body() -> void:
	var seen: Dictionary = IdentityLens.perceive_being(profile, Color(0.7, 0.6, 0.5))
	scale = Vector3.ONE * float(seen.view.get("apparent_scale", 1.0))

	var race_id := str(profile.get("race_id", ""))
	# peer id seeds the body pick so a race-less peer keeps one appearance
	# instead of re-rolling every time they stream back into view.
	var body := MetahumanCharacter.build_npc(visual_mode, race_id, peer_id.hash())
	# MetahumanCharacter.build_npc's default body is a PeriHumanRig (a whole
	# skeleton+skin hierarchy, not a bare mesh) — `is MeshInstance3D` never
	# matched it, so the perceived material/view-scale style silently never
	# applied to remote PeriHumans. apply_perception() is the fix.
	if body is PeriHumanRig:
		body.apply_perception(seen.view, seen.material)
	elif body is MeshInstance3D:
		body.material_override = seen.material
	_body_root = body
	_peri_rig = body if body is PeriHumanRig else null
	_has_last = false
	add_child(body)

	# Other players mutter in character too, so the world isn't full of silent
	# mannequins. Only when we can tell their race.
	if _barker != null and is_instance_valid(_barker):
		_barker.queue_free()
		_barker = null
	if not race_id.is_empty():
		_barker = PersonaBarker.new()
		add_child(_barker)
		_barker.setup(RacePersona.canon_for_id(race_id), 2.2)

	_plate = Label3D.new()
	_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plate.position.y = 2.2
	_plate.font_size = 48
	_plate.outline_size = 8
	if seen.view.get("loadout_visible", true):
		_plate.text = peer_id.trim_prefix("ghost_").replace("_", " ")
		_plate.modulate = seen.view.get("aura_color", Color.WHITE)
	else:
		_plate.text = "???" # outclassed: you don't get their name either
		_plate.modulate = Color(0.4, 0.4, 0.45)
	add_child(_plate)

## Drive the gait from how far the body actually moved on screen this frame,
## normalised against the sprint speed a local player tops out at — so a
## remote player walking looks like walking and sprinting looks like sprinting.
func _process(delta: float) -> void:
	if _peri_rig == null or not is_instance_valid(_peri_rig):
		return
	if not _has_last:
		_last_pos = global_position
		_has_last = true
		return
	var moved := Vector2(global_position.x - _last_pos.x, global_position.z - _last_pos.z).length()
	_last_pos = global_position
	var speed := moved / maxf(delta, 0.0001)
	_peri_rig.set_locomotion(speed / ThirdPersonController.BASE_SPRINT_SPEED)

func move_to(pos: Vector3, terrain = null) -> void:
	var target := pos
	if terrain != null and terrain.has_method("height_at"):
		target.y = terrain.height_at(pos.x, pos.z) + 0.1
	# Smooth toward the reported position.
	global_position = global_position.lerp(target, 0.2)
