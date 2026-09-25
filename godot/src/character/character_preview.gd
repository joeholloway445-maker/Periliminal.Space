extends Node3D
## Hosts the animated, build-responsive CharacterRig preview for the
## VentureWizard character creator. The shipped PeriHuman GLB is a static
## baked mesh (no Skeleton3D/AnimationPlayer), so it can't reshape for
## frames/mods nor move its limbs — this preview uses the procedural
## articulated rig instead: every frame/mod/sex/slider pick visibly resizes
## the body and a live idle animation keeps the limbs moving.

@onready var _rig: Node3D = $CharacterRig
var race_id: String = ""
var frame_id: String = ""
var mod_id: String = ""
var sex: String = "m"
var _appearance: Dictionary = {}

func _ready() -> void:
	refresh()

func refresh() -> void:
	if _rig == null:
		return
	var loadout := CharacterCreatorLogic.build_loadout(race_id, frame_id, mod_id)
	# Always show a body — before any frame is picked we default to a light
	# frame so the Race step isn't an empty black box.
	if loadout.get("frame", {}).is_empty():
		loadout["frame"] = {"id": "", "frame_type": "light", "name": "Default"}
	if loadout.get("race", {}).is_empty():
		loadout["race"] = {"id": "", "primary_color": "#d9a066", "texture_type": ""}
	_rig.visible = true
	if _rig is CharacterRig:
		var rig := _rig as CharacterRig
		rig.scale = Vector3.ONE
		rig.build_from_loadout(loadout.get("race", {}), loadout.get("frame", {}), loadout.get("mod", {}))
		rig.appearance = _appearance.duplicate()
		rig.sex = sex
		rig.apply_appearance()
	else:
		_rig.build_from_loadout(loadout.get("race", {}), loadout.get("frame", {}), loadout.get("mod", {}))

func preview(new_race_id: String, new_frame_id: String, new_mod_id: String = "",
		new_sex: String = "", new_appearance: Dictionary = {}) -> void:
	race_id = new_race_id
	frame_id = new_frame_id
	mod_id = new_mod_id
	if not new_sex.is_empty():
		sex = new_sex
	if not new_appearance.is_empty():
		_appearance = new_appearance.duplicate()
	refresh()

## Live slider feedback without a full rebuild: re-apply scale + colors.
func apply_appearance(new_appearance: Dictionary) -> void:
	_appearance = new_appearance.duplicate()
	if _rig != null and _rig is CharacterRig:
		var rig := _rig as CharacterRig
		rig.appearance = _appearance.duplicate()
		rig.sex = sex
		rig.apply_appearance()
