class_name VenueInterior
## The inside of a walk-up venue — a real room you can walk into, not a
## facade with a UI behind it.
##
## Builds a hollow shell (floor, ceiling, four walls with a doorway gap on
## the storefront face), dresses it with photoscanned props, and lights it.
## Every surface goes through `AssetLibrary.material()`, so the interior
## textures are used when installed and the per-race identity lens tints on
## top either way — the same bank lobby is marble to one player and grown
## biotech to another.
##
## Called by CityVenues when no `venue_<kind>` storefront asset is installed.
## With one installed, that asset is trusted to carry its own interior.
##
## Room is built in local space around the venue origin, matching the shell
## footprint CityVenues used before: x -7..7, z -6..6, y 0..7, doorway on
## the +Z face where CityDoor sits.

const HALF_X := 7.0
const HALF_Z := 6.0
const HEIGHT := 7.0
const WALL := 0.4
## Wide enough to walk through without catching on the frame.
const DOOR_GAP := 3.4

## Floor surface per venue — the one place each interior reads distinctly
## before any props are placed.
const FLOOR_SLOT := {
	"bank": "interior_marble",
	"wager_hall": "interior_carpet",
	"market": "interior_tile",
	"armorer": "interior_floor",
	"blacksmith": "interior_floor",
	"stockyards": "interior_floor",
}

## Photoscanned dressing per venue, as (model, local position, y-rotation).
## Models resolve through AssetLibrary, so a missing file is simply skipped.
const PROPS := {
	"market": [
		["wooden_crate_02", Vector3(-4.5, 0, -3.5), 0.0],
		["plastic_crate_01", Vector3(-4.2, 0, -1.6), 0.6],
		["barrel_03", Vector3(4.6, 0, -3.8), 0.0],
		["planter_box_01", Vector3(4.4, 0, 2.6), 0.0],
	],
	"bank": [
		["dining_table", Vector3(0, 0, -2.4), 0.0],
		["dining_chair_02", Vector3(-1.6, 0, -1.0), 3.14],
		["dining_chair_02", Vector3(1.6, 0, -1.0), 3.14],
		["drawer_cabinet", Vector3(-5.4, 0, -4.2), 1.57],
	],
	"armorer": [
		["old_military_crate", Vector3(-4.8, 0, -3.0), 0.3],
		["industrial_storage_cart", Vector3(4.4, 0, -2.2), 0.0],
		["plastic_crate_01", Vector3(-4.4, 0, 1.2), 0.0],
	],
	"blacksmith": [
		["barrel_stove", Vector3(-4.6, 0, -3.4), 0.0],
		["wooden_barrels_01", Vector3(4.6, 0, -3.2), 0.0],
		["old_military_crate", Vector3(3.9, 0, 1.8), 0.9],
	],
	"wager_hall": [
		["sofa_02", Vector3(-3.8, 0, -3.6), 0.0],
		["coffee_table_round_01", Vector3(-3.8, 0, -1.4), 0.0],
		["bar_chair_round_01", Vector3(4.2, 0, -2.6), 0.0],
		["bar_chair_round_01", Vector3(4.2, 0, 0.2), 0.0],
	],
	"stockyards": [
		["wooden_crate_02", Vector3(-5.2, 0, -4.0), 0.0],
		["barrel_03", Vector3(5.0, 0, -4.0), 0.0],
	],
}

## Builds the interior for `kind` and returns its root (already positioned in
## venue-local space — add it straight to the venue root).
static func build(kind: String, tint: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Interior"

	var floor_slot := str(FLOOR_SLOT.get(kind, "interior_floor"))
	var floor_mat := AssetLibrary.material(floor_slot, tint.lightened(0.15), 0.18, 0.0, 0.75)
	var wall_mat := AssetLibrary.material("interior_wall", tint.darkened(0.3), 0.22, 0.0, 0.85)
	# The ceiling shares the wall set but reads darker, so the room has a top
	# without needing a sixth texture slot.
	var ceil_mat := AssetLibrary.material("interior_wall", tint.darkened(0.6), 0.22, 0.0, 0.9)

	# Floor and ceiling.
	root.add_child(_slab(Vector3(HALF_X * 2.0, WALL, HALF_Z * 2.0),
		Vector3(0, -WALL * 0.5, 0), floor_mat, "Floor"))
	root.add_child(_slab(Vector3(HALF_X * 2.0, WALL, HALF_Z * 2.0),
		Vector3(0, HEIGHT, 0), ceil_mat, "Ceiling"))

	# Side and back walls.
	root.add_child(_slab(Vector3(WALL, HEIGHT, HALF_Z * 2.0),
		Vector3(-HALF_X, HEIGHT * 0.5, 0), wall_mat, "WallLeft"))
	root.add_child(_slab(Vector3(WALL, HEIGHT, HALF_Z * 2.0),
		Vector3(HALF_X, HEIGHT * 0.5, 0), wall_mat, "WallRight"))
	root.add_child(_slab(Vector3(HALF_X * 2.0, HEIGHT, WALL),
		Vector3(0, HEIGHT * 0.5, -HALF_Z), wall_mat, "WallBack"))

	# Storefront wall, split around the doorway so the CityDoor opening is
	# actually walkable rather than a painted-on rectangle.
	var side := (HALF_X * 2.0 - DOOR_GAP) * 0.5
	var offset := (DOOR_GAP + side) * 0.5
	root.add_child(_slab(Vector3(side, HEIGHT, WALL),
		Vector3(-offset, HEIGHT * 0.5, HALF_Z), wall_mat, "WallFrontL"))
	root.add_child(_slab(Vector3(side, HEIGHT, WALL),
		Vector3(offset, HEIGHT * 0.5, HALF_Z), wall_mat, "WallFrontR"))
	# Lintel above the doorway.
	root.add_child(_slab(Vector3(DOOR_GAP, HEIGHT - 3.2, WALL),
		Vector3(0, HEIGHT - (HEIGHT - 3.2) * 0.5, HALF_Z), wall_mat, "WallFrontTop"))

	_dress(root, kind, tint)
	_light(root, tint, kind)
	return root

## A textured box with matching collision. Interiors need real walls — the
## old solid-box storefronts had no collision at all, so the player walked
## straight through them.
static func _slab(size: Vector3, pos: Vector3, mat: StandardMaterial3D, name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos

	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	body.add_child(mi)

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return body

static func _dress(root: Node3D, kind: String, tint: Color) -> void:
	var list: Array = PROPS.get(kind, [])
	for entry in list:
		var model := AssetLibrary.instance("polyhaven/%s" % str(entry[0]))
		if model == null:
			continue  # prop pack not installed — room still reads fine bare
		model.position = entry[1]
		model.rotation.y = float(entry[2])
		root.add_child(model)

## Industrial trades get a bare hanging lamp; civic rooms get a fitting.
const CEILING_FIXTURE := {
	"blacksmith": "hanging_industrial_lamp",
	"armorer": "hanging_industrial_lamp",
	"stockyards": "caged_hanging_light",
	"market": "modern_ceiling_lamp_01",
	"bank": "modern_ceiling_lamp_01",
	"wager_hall": "modern_ceiling_lamp_01",
}

## Warm interior fill so stepping inside is not stepping into a black box.
## Tinted by the venue so each interior still reads as itself at a glance,
## and hung under a real fixture so the light has a visible source.
static func _light(root: Node3D, tint: Color, kind: String = "") -> void:
	var fixture := AssetLibrary.instance("polyhaven/%s" % str(CEILING_FIXTURE.get(kind, "")))
	if fixture != null:
		fixture.position = Vector3(0, HEIGHT - 0.1, -1.0)
		root.add_child(fixture)

	var lamp := OmniLight3D.new()
	lamp.name = "InteriorLight"
	lamp.position = Vector3(0, HEIGHT - 1.2, -1.0)
	lamp.light_color = tint.lightened(0.45)
	lamp.light_energy = 2.4
	lamp.omni_range = 20.0
	lamp.shadow_enabled = not RenderCaps.is_compatibility()
	root.add_child(lamp)

	# A dimmer second source near the door stops the entrance reading as a
	# dark slot from outside.
	var door_lamp := OmniLight3D.new()
	door_lamp.name = "DoorLight"
	door_lamp.position = Vector3(0, HEIGHT - 2.0, HALF_Z - 1.5)
	door_lamp.light_color = tint.lightened(0.6)
	door_lamp.light_energy = 1.2
	door_lamp.omni_range = 11.0
	root.add_child(door_lamp)
