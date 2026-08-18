class_name LiminalHallwayBuilder
extends Node3D

## Generates a procedural "backrooms"-style maze of narrow hallways with dim
## lighting for the Liminal layer.  Uses a recursive-backtracker (DFS) maze
## algorithm, then builds wall/floor/lighting children on a Node3D root.
##
## PERFORMANCE: All wall meshes are merged into a single ArrayMesh (~1 draw
## call) and a single ConcavePolygonShape3D collision body, dropping the node
## count from ~1500 to ~6.  Same for ceiling beams and door frames.
## Total maze construction: ~1-2 ms on desktop, ~3-5 ms on mobile.

const TextureMaterials = preload("res://src/character/texture_materials.gd")

# ---------------------------------------------------------------------------
#  Maze cell data
# ---------------------------------------------------------------------------

enum WallSide { N = 0, S = 1, E = 2, W = 3 }

class Cell:
	var x: int
	var z: int
	var visited: bool = false
	var walls: Array[bool] = [true, true, true, true]  # N, S, E, W

	func _init(p_x: int, p_z: int) -> void:
		x = p_x
		z = p_z

# ---------------------------------------------------------------------------
#  Public API
# ---------------------------------------------------------------------------

## Build a corridor-maze root node.
## @param seed_val:  deterministic seed
## @param maze_size: number of cells in each direction (recommended 20-30)
## @param hallway_width: width of corridors in world units (recommended 3-5)
## @param wall_height: height of walls (recommended 3-4)
## @param low_quality: if true, reduces light count and skips ceiling/door frames (mobile)
## @return a Node3D with all wall/floor/lighting children
static func build(
		seed_val: int,
		maze_size: int = 24,
		hallway_width: float = 4.0,
		wall_height: float = 3.5,
		low_quality: bool = false
) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "LiminalHallway"

	# ---- seeded RNG -------------------------------------------------------
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("liminal_hallway_" + str(seed_val))

	# ---- generate maze grid -----------------------------------------------
	var grid: Array[Array] = _generate_maze(maze_size, rng)

	# ---- world offset so the maze is centred at origin --------------------
	var half_extent: float = (maze_size - 1) * hallway_width * 0.5
	var hw: float = hallway_width

	# ---- floor ------------------------------------------------------------
	_build_floor(root, maze_size, hw, half_extent)

	# ---- walls (interior + outer perimeter) - merged mesh -----------------
	_build_walls_merged(root, grid, maze_size, hw, wall_height, half_extent)

	# ---- lighting ---------------------------------------------------------
	_build_lights(root, grid, maze_size, hw, wall_height, half_extent, rng, low_quality)

	# ---- ceiling beams - merged mesh (skipped on low quality / mobile) ----
	if not low_quality:
		_build_ceiling_beams_merged(root, grid, maze_size, hw, wall_height, half_extent, rng)

	# ---- door frames (always built — doors are our signature) --------------
	_build_door_frames_merged(root, grid, maze_size, hw, wall_height, half_extent, rng)

	return root

# ---------------------------------------------------------------------------
#  Maze generation - recursive backtracker (DFS with explicit stack)
# ---------------------------------------------------------------------------

static func _generate_maze(size: int, rng: RandomNumberGenerator) -> Array[Array]:
	## Returns a 2-D array [x][z] of Cell.
	var grid: Array[Array] = []
	grid.resize(size)
	for x in size:
		grid[x] = []
		grid[x].resize(size)
		for z in size:
			grid[x][z] = Cell.new(x, z)

	var stack: Array[Cell] = []
	var current: Cell = grid[0][0]
	current.visited = true
	stack.push_back(current)

	while stack.size() > 0:
		current = stack.back()
		var neighbors: Array[Cell] = _unvisited_neighbors(current, grid, size, rng)

		if neighbors.is_empty():
			stack.pop_back()
		else:
			var next_cell: Cell = neighbors[rng.randi_range(0, neighbors.size() - 1)]
			_remove_wall_between(current, next_cell)
			next_cell.visited = true
			stack.push_back(next_cell)

	return grid

static func _unvisited_neighbors(
		cell: Cell,
		grid: Array[Array],
		size: int,
		_rng: RandomNumberGenerator
) -> Array[Cell]:
	var result: Array[Cell] = []
	# East
	if cell.x + 1 < size and not grid[cell.x + 1][cell.z].visited:
		result.push_back(grid[cell.x + 1][cell.z])
	# West
	if cell.x - 1 >= 0 and not grid[cell.x - 1][cell.z].visited:
		result.push_back(grid[cell.x - 1][cell.z])
	# South (positive Z in 3D)
	if cell.z + 1 < size and not grid[cell.x][cell.z + 1].visited:
		result.push_back(grid[cell.x][cell.z + 1])
	# North (negative Z in 3D)
	if cell.z - 1 >= 0 and not grid[cell.x][cell.z - 1].visited:
		result.push_back(grid[cell.x][cell.z - 1])
	# Shuffle for randomness
	result.shuffle()
	return result

static func _remove_wall_between(a: Cell, b: Cell) -> void:
	var dx: int = b.x - a.x
	var dz: int = b.z - a.z
	if dx == 1:
		a.walls[WallSide.E] = false
		b.walls[WallSide.W] = false
	elif dx == -1:
		a.walls[WallSide.W] = false
		b.walls[WallSide.E] = false
	elif dz == 1:
		a.walls[WallSide.S] = false
		b.walls[WallSide.N] = false
	elif dz == -1:
		a.walls[WallSide.N] = false
		b.walls[WallSide.S] = false

# ---------------------------------------------------------------------------
#  Floor - single BoxMesh (already efficient)
# ---------------------------------------------------------------------------

static func _build_floor(
		root: Node3D,
		maze_size: int,
		hw: float,
		half_extent: float
) -> void:
	var floor_node := MeshInstance3D.new()
	floor_node.name = "Floor"
	floor_node.position = Vector3(0.0, -0.05, 0.0)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(maze_size * hw, 0.1, maze_size * hw)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.roughness = 0.7
	mat.metallic = 0.1
	mesh.material = mat

	floor_node.mesh = mesh
	root.add_child(floor_node)
	floor_node.owner = root

	# Collision
	var static_body := StaticBody3D.new()
	static_body.name = "FloorCollision"
	static_body.position = Vector3(0.0, -0.05, 0.0)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(maze_size * hw, 0.1, maze_size * hw)
	shape.shape = box_shape

	static_body.add_child(shape)
	shape.owner = static_body
	root.add_child(static_body)
	static_body.owner = root

# ---------------------------------------------------------------------------
#  Walls - single merged ArrayMesh + per-segment BoxShape3D collision boxes.
#  Box-vs-capsule is drastically faster than ConcavePolygonShape3D.
# ---------------------------------------------------------------------------

static func _build_walls_merged(
		root: Node3D,
		grid: Array[Array],
		maze_size: int,
		hw: float,
		wall_height: float,
		half_extent: float
) -> void:
	var wall_mat: StandardMaterial3D = TextureMaterials.build_material(
		"morphic",
		Color(0.22, 0.22, 0.25)
	)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Single StaticBody3D with per-segment BoxShape3D collision boxes
	var phys_body := StaticBody3D.new()
	phys_body.name = "WallCollision"

	# -- Interior walls: check each cell's East and South -------------------
	for x in maze_size:
		for z in maze_size:
			var cell: Cell = grid[x][z]

			# East wall (between this cell and x+1)
			if cell.walls[WallSide.E] and x < maze_size - 1:
				var pos := Vector3(
					(x + 0.5) * hw - half_extent,
					wall_height * 0.5,
					z * hw - half_extent
				)
				var size := Vector3(hw, wall_height, 0.3)
				_add_box_to_surface(st, pos, size)
				_add_wall_collision(phys_body, pos, size)

			# South wall (between this cell and z+1)
			if cell.walls[WallSide.S] and z < maze_size - 1:
				var pos := Vector3(
					x * hw - half_extent,
					wall_height * 0.5,
					(z + 0.5) * hw - half_extent
				)
				var size := Vector3(hw, wall_height, 0.3)
				_add_box_to_surface(st, pos, size)
				_add_wall_collision(phys_body, pos, size)

	# -- Outer perimeter walls ----------------------------------------------
	# North edge (z = 0)
	for x in maze_size:
		var pos := Vector3(
			x * hw - half_extent,
			wall_height * 0.5,
			-0.5 * hw - half_extent
		)
		var peri_size := Vector3(hw, wall_height, 0.3)
		_add_box_to_surface(st, pos, peri_size)
		_add_wall_collision(phys_body, pos, peri_size)

	# South edge (z = maze_size - 1)
	for x in maze_size:
		var pos := Vector3(
			x * hw - half_extent,
			wall_height * 0.5,
			(maze_size - 1 + 0.5) * hw - half_extent
		)
		var peri_size := Vector3(hw, wall_height, 0.3)
		_add_box_to_surface(st, pos, peri_size)
		_add_wall_collision(phys_body, pos, peri_size)

	# West edge (x = 0) - thin in X, wide in Z
	for z in maze_size:
		var pos := Vector3(
			-0.5 * hw - half_extent,
			wall_height * 0.5,
			z * hw - half_extent
		)
		var peri_size := Vector3(0.3, wall_height, hw)
		_add_box_to_surface(st, pos, peri_size)
		_add_wall_collision(phys_body, pos, peri_size)

	# East edge (x = maze_size - 1)
	for z in maze_size:
		var pos := Vector3(
			(maze_size - 1 + 0.5) * hw - half_extent,
			wall_height * 0.5,
			z * hw - half_extent
		)
		var peri_size := Vector3(0.3, wall_height, hw)
		_add_box_to_surface(st, pos, peri_size)
		_add_wall_collision(phys_body, pos, peri_size)

	# Generate normals and commit the merged visual mesh
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null:
		push_error("LiminalHallwayBuilder: failed to build wall mesh")
		return

	# Assign material
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, wall_mat)

	# Single MeshInstance3D for visuals
	var mi := MeshInstance3D.new()
	mi.name = "Walls"
	mi.mesh = mesh
	root.add_child(mi)
	mi.owner = root

	# Physics body with per-segment BoxShape3D children
	root.add_child(phys_body)
	phys_body.owner = root

# ---------------------------------------------------------------------------
#  Low-level: add a single box (6 faces, 12 triangles) to a SurfaceTool.
#  Vertices are ordered correctly for generate_normals() to figure out
#  the outward-facing normals.
# ---------------------------------------------------------------------------

static func _add_box_to_surface(st: SurfaceTool, pos: Vector3, size: Vector3) -> void:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var px := pos.x
	var py := pos.y
	var pz := pos.z

	# 8 corners of the box (outward-facing winding)
	var c0 := Vector3(px - hx, py - hy, pz - hz)  # back-bottom-left
	var c1 := Vector3(px + hx, py - hy, pz - hz)  # back-bottom-right
	var c2 := Vector3(px + hx, py + hy, pz - hz)  # back-top-right
	var c3 := Vector3(px - hx, py + hy, pz - hz)  # back-top-left
	var c4 := Vector3(px - hx, py - hy, pz + hz)  # front-bottom-left
	var c5 := Vector3(px + hx, py - hy, pz + hz)  # front-bottom-right
	var c6 := Vector3(px + hx, py + hy, pz + hz)  # front-top-right
	var c7 := Vector3(px - hx, py + hy, pz + hz)  # front-top-left

	# 6 faces x 2 triangles each
	st.add_triangle_fan(PackedVector3Array([c4, c5, c6, c7]))   # front  (Z+)
	st.add_triangle_fan(PackedVector3Array([c1, c0, c3, c2]))   # back   (Z-)
	st.add_triangle_fan(PackedVector3Array([c7, c6, c2, c3]))   # top    (Y+)
	st.add_triangle_fan(PackedVector3Array([c0, c1, c5, c4]))   # bottom (Y-)
	st.add_triangle_fan(PackedVector3Array([c5, c1, c2, c6]))   # right  (X+)
	st.add_triangle_fan(PackedVector3Array([c0, c4, c7, c3]))   # left   (X-)

# Add a BoxShape3D CollisionShape3D child to a StaticBody3D for one wall segment.
# Box-vs-capsule collision is the fastest option for CharacterBody3D.move_and_slide().
static func _add_wall_collision(body: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = pos
	body.add_child(cs)

# ---------------------------------------------------------------------------
#  Lighting - dim ambient omni lights
# ---------------------------------------------------------------------------

static func _build_lights(
		root: Node3D,
		grid: Array[Array],
		maze_size: int,
		hw: float,
		wall_height: float,
		half_extent: float,
		rng: RandomNumberGenerator,
		low_quality: bool
) -> void:
	var total_cells: int = maze_size * maze_size
	var light_spacing: int = 32 if low_quality else 16
	var light_count: int = maxi(1, total_cells / light_spacing)

	# Collect all visited (path) cells
	var path_cells: Array[Cell] = []
	for x in maze_size:
		for z in maze_size:
			if grid[x][z].visited:
				path_cells.push_back(grid[x][z])
	path_cells.shuffle()

	var placed: int = 0
	for cell in path_cells:
		if placed >= light_count:
			break
		var pos := Vector3(
			cell.x * hw + hw * 0.5 - half_extent,
			0.5,
			cell.z * hw + hw * 0.5 - half_extent
		)
		var omni := OmniLight3D.new()
		omni.light_color = Color(0.5, 0.5, 0.7)
		omni.light_energy = 0.6
		omni.omni_range = 5.0
		omni.position = pos
		root.add_child(omni)
		omni.owner = root
		placed += 1

# ---------------------------------------------------------------------------
#  Ceiling beams - merged mesh (visual only, no physics)
# ---------------------------------------------------------------------------

static func _build_ceiling_beams_merged(
		root: Node3D,
		grid: Array[Array],
		maze_size: int,
		hw: float,
		wall_height: float,
		half_extent: float,
		rng: RandomNumberGenerator
) -> void:
	var beam_mat: StandardMaterial3D = TextureMaterials.build_material(
		"morphic",
		Color(0.18, 0.18, 0.22)
	)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var beam_count: int = 0
	for x in maze_size:
		for z in maze_size:
			if not grid[x][z].visited:
				continue
			if x % 3 == 0:
				# Beam spans the full hallway width along Z
				var pos := Vector3(
					x * hw - half_extent,
					wall_height,
					z * hw + hw * 0.5 - half_extent
				)
				_add_box_to_surface(st, pos, Vector3(0.15, 0.1, hw))
				beam_count += 1
			if z % 3 == 0:
				var pos := Vector3(
					x * hw + hw * 0.5 - half_extent,
					wall_height,
					z * hw - half_extent
				)
				_add_box_to_surface(st, pos, Vector3(hw, 0.1, 0.15))
				beam_count += 1

	if beam_count == 0:
		return

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return

	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, beam_mat)

	var mi := MeshInstance3D.new()
	mi.name = "CeilingBeams"
	mi.mesh = mesh
	root.add_child(mi)
	mi.owner = root

# ---------------------------------------------------------------------------
#  Door frames - merged mesh (visual only)
# ---------------------------------------------------------------------------

static func _build_door_frames_merged(
		root: Node3D,
		grid: Array[Array],
		maze_size: int,
		hw: float,
		wall_height: float,
		half_extent: float,
		rng: RandomNumberGenerator
) -> void:
	var frame_mat: StandardMaterial3D = TextureMaterials.build_material(
		"morphic",
		Color(0.15, 0.12, 0.18)
	)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var frame_count: int = 0

	for x in maze_size:
		for z in maze_size:
			var cell: Cell = grid[x][z]
			# Place a door frame at ~30% of open passages
			if cell.walls[WallSide.E] == false and x < maze_size - 1:
				if rng.randf() < 0.3:
					var pos := Vector3(
						(x + 0.5) * hw - half_extent,
						wall_height * 0.5,
						z * hw - half_extent
					)
					_add_box_to_surface(st, pos, Vector3(0.2, wall_height * 0.8, 0.5))
					frame_count += 1
			if cell.walls[WallSide.S] == false and z < maze_size - 1:
				if rng.randf() < 0.3:
					var pos := Vector3(
						x * hw - half_extent,
						wall_height * 0.5,
						(z + 0.5) * hw - half_extent
					)
					_add_box_to_surface(st, pos, Vector3(0.5, wall_height * 0.8, 0.2))
					frame_count += 1

	if frame_count == 0:
		return

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return

	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, frame_mat)

	var mi := MeshInstance3D.new()
	mi.name = "DoorFrames"
	mi.mesh = mesh
	root.add_child(mi)
	mi.owner = root

# ---------------------------------------------------------------------------
#  Mobile quality helper
# ---------------------------------------------------------------------------

## Quick heuristic: returns true on touchscreen devices (phones/tablets)
## where we should reduce visual complexity (fewer lights, no ceiling
## beams or door frames).
static func is_low_quality_device() -> bool:
	return DisplayServer.is_touchscreen_available()
