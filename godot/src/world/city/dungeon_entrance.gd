class_name PeriliminalDungeonDoor
extends Node3D
## A sealed Periliminal door inside an ordinary Metroplex building.
##
## Reads as wrong before you reach it: a doorway with no room behind it, lit
## from underneath, with a plate that will not tell you how hard it is until
## somebody has survived it. Step into the ring for the requirement; press E
## with a party that satisfies it to drop into the run.
##
## Placed by CityVenues-style cell coordinates (see DungeonData). The run
## itself is PeriliminalRuns' — this is the door, the gate and the sign.

const FRAME_W := 3.6
const FRAME_H := 4.6

var dungeon_id := ""
var player: Node3D
## Filled by a party-finder before attempt_entry(); empty means solo.
var party_members: Array = []

var _plate: Label3D
var _seal: MeshInstance3D
var _armed := false

func setup(id: String, p: Node3D) -> void:
	dungeon_id = id
	player = p

func _ready() -> void:
	var d := DungeonData.get_dungeon(dungeon_id)
	if d.is_empty():
		return
	_build_frame()
	_build_seal()
	_build_plate(d)
	_build_ring(d)

## A heavy doorframe — deliberately not matching the building it is in.
func _build_frame() -> void:
	var mat := AssetLibrary.material("facade_metal", Color(0.28, 0.26, 0.34), 0.25, 0.75, 0.35)
	for spec in [
		[Vector3(0.4, FRAME_H, 0.5), Vector3(-FRAME_W * 0.5, FRAME_H * 0.5, 0)],
		[Vector3(0.4, FRAME_H, 0.5), Vector3(FRAME_W * 0.5, FRAME_H * 0.5, 0)],
		[Vector3(FRAME_W + 0.4, 0.4, 0.5), Vector3(0, FRAME_H, 0)],
	]:
		var body := StaticBody3D.new()
		body.position = spec[1]
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = spec[0]
		mi.mesh = box
		mi.material_override = mat
		body.add_child(mi)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = spec[0]
		cs.shape = shape
		body.add_child(cs)
		add_child(body)

## The seal itself: a flat plane of not-quite-anything. Left un-lensed on
## purpose — like PVXC's danger ring and the layer-exit doors, a sealed
## descent has to read identically to every player regardless of race, or
## parties cannot point at the same door and agree it is dangerous.
func _build_seal() -> void:
	_seal = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(FRAME_W - 0.2, FRAME_H - 0.3)
	_seal.mesh = quad
	_seal.position = Vector3(0, (FRAME_H - 0.3) * 0.5, 0.1)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.02, 0.09, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.15, 0.75)
	mat.emission_energy_multiplier = 1.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_seal.material_override = mat
	add_child(_seal)

	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 0.6, 0.9)
	glow.light_color = Color(0.55, 0.2, 0.85)
	glow.light_energy = 2.0
	glow.omni_range = 9.0
	add_child(glow)

## The plate. Rank stays "?" until somebody has beaten this descent.
func _build_plate(d: Dictionary) -> void:
	var DungeonManager = AutoloadGate.get_node("DungeonManager")
	_plate = Label3D.new()
	_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plate.font_size = 64
	_plate.outline_size = 10
	_plate.position.y = FRAME_H + 1.1
	_plate.modulate = Color(0.85, 0.7, 1.0)
	add_child(_plate)
	_refresh_plate(d)

	if DungeonManager:
		DungeonManager.rank_confirmed.connect(func(id: String, _r: int):
			if id == dungeon_id:
				_refresh_plate(DungeonData.get_dungeon(dungeon_id)))

func _refresh_plate(d: Dictionary) -> void:
	var DungeonManager = AutoloadGate.get_node("DungeonManager")
	if _plate == null:
		return
	var rank := "Rank ?"
	if DungeonManager:
		rank = DungeonManager.rank_text(dungeon_id)
	_plate.text = "%s\n%s\n%s" % [str(d.get("name", dungeon_id)), rank,
		DungeonData.requirement_text(d)]

func _build_ring(d: Dictionary) -> void:
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 7.0
	cs.shape = sph
	area.add_child(cs)
	add_child(area)

	area.body_entered.connect(func(b: Node3D):
		var NotificationUI = AutoloadGate.get_node("NotificationUI")
		if b != player:
			return
		_armed = true
		var blurb := str(d.get("blurb", ""))
		if NotificationUI:
			NotificationUI.notify_info("%s — %s" % [str(d.get("name", "")), blurb]))

	area.body_exited.connect(func(b: Node3D):
		if b == player:
			_armed = false)

func _unhandled_input(event: InputEvent) -> void:
	# Raw KEY_E, matching VenueInteract — the project has no "interact"
	# input action registered, so is_action_pressed() would fail at runtime.
	if not _armed:
		return
	if not (event is InputEventKey and event.pressed and not event.echo
			and event.keycode == KEY_E):
		return
	attempt_entry()

## Checks the gate, then hands off to PeriliminalRuns. Kept public so a
## party-finder UI can trigger it without faking an input event.
func attempt_entry() -> void:
	var PlayerProfile = AutoloadGate.get_node("PlayerProfile")
	var DungeonManager = AutoloadGate.get_node("DungeonManager")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	var PeriliminalRuns = AutoloadGate.get_node("PeriliminalRuns")
	var LayerManager = AutoloadGate.get_node("LayerManager")
	var party := _party()
	var level := 1
	var keys: Array = []
	if PlayerProfile:
		level = int(PlayerProfile.level)
		# Keys are inventory items; until an inventory category exists for
		# them the gate reads an optional profile list, so keyed dungeons
		# stay sealed rather than silently opening for everyone.
		var k: Variant = PlayerProfile.get("dungeon_keys")
		if k is Array:
			keys = k

	var check: Dictionary = {"ok": true, "reason": ""}
	if DungeonManager:
		check = DungeonManager.can_enter(dungeon_id, party, level, keys)
	if not bool(check.ok):
		if NotificationUI:
			NotificationUI.notify_info(str(check.reason))
		return

	if NotificationUI:
		NotificationUI.notify_info("The seal gives. %s opens." %
			str(DungeonData.get_dungeon(dungeon_id).get("name", "")))
	_open_seal()
	# Attribute the run that follows to this dungeon, so walking back out
	# counts as the clear that proves its rank.
	if DungeonManager:
		DungeonManager.begin_dungeon(dungeon_id)
	if PeriliminalRuns:
		PeriliminalRuns.begin_run(_party_ids(party))
	if LayerManager:
		LayerManager.transition_to("periliminal", true)

## Party membership: PartyManager when one is formed, an explicit override
## for a party-finder UI, solo otherwise. The gate decides whether the group
## that turns up is enough.
func _party() -> Array:
	var PartyManager = AutoloadGate.get_node("PartyManager")
	if not party_members.is_empty():
		return party_members
	if PartyManager:
		return PartyManager.members()
	return [_self_id()]

func _party_ids(party: Array) -> Array[String]:
	var out: Array[String] = []
	for p in party:
		out.append(str(p))
	return out

func _self_id() -> String:
	var PlayerProfile = AutoloadGate.get_node("PlayerProfile")
	if PlayerProfile and str(PlayerProfile.get("username")) != "":
		return str(PlayerProfile.username)
	return "player"

func _open_seal() -> void:
	if _seal == null:
		return
	var tw := create_tween()
	tw.tween_property(_seal, "scale", Vector3(1, 0.02, 1), 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
