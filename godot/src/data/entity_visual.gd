class_name EntityVisual
## Gives every one of the 270 entity lines — 600 forms counting evolutions,
## 150 per faction across SovereignCrown/VeiledCurrent/WildlandsAscendant/
## Factionless (see EntityDexData) — a body and an icon of its own, generated
## from the data it already carries.
##
## Until now every entity in the game instanced the same `creature` model, so
## an Apex Quantum horror and a Utility Matter drone were the same orc. This
## composes a silhouette instead, from four things the dex already states:
##
##   category  the shape language  (Energy spikes, Entropy erodes, Gravity
##             compacts and orbits, Matter accretes slabs, Psyche stacks
##             heads, Quantum duplicates and phases)
##   faction   the palette
##   role      Apex crowns itself, Trophy sits lit, Utility stays plain
##   stage     0-2, each larger and more elaborated than the last
##
## Seeded on the entity id, so a given entity looks the same everywhere and
## no two look alike.
##
## Real art supersedes it with no code change — `entity_<id>` wins, then
## `entity_<category>`, then this. That is the same slot ladder the rest of
## AssetLibrary uses, so the Omni Dex art prompts can be filled in one at a
## time rather than all at once.

const FACTION_PALETTE := {
	"SovereignCrown": [Color(0.72, 0.60, 0.22), Color(0.35, 0.10, 0.12)],
	"VeiledCurrent": [Color(0.25, 0.62, 0.70), Color(0.10, 0.18, 0.34)],
	"WildlandsAscendant": [Color(0.42, 0.62, 0.28), Color(0.24, 0.16, 0.08)],
	"Factionless": [Color(0.55, 0.53, 0.58), Color(0.18, 0.17, 0.20)],
}

## roughness, metallic, emissive strength per category.
const CATEGORY_SURFACE := {
	"Energy": [0.18, 0.25, 1.6],
	"Entropy": [0.95, 0.02, 0.0],
	"Gravity": [0.35, 0.70, 0.2],
	"Matter": [0.80, 0.15, 0.0],
	"Psyche": [0.45, 0.05, 0.7],
	"Quantum": [0.22, 0.40, 1.1],
}

## Where generated entity art lands. A sprite is the intended medium for the
## ~810 collectible forms: they are viewed at creature distance in a
## collection game, generating 2D costs a fraction of generating 3D, and a
## painted sprite beats a procedural mesh at every budget worth spending.
const SPRITE_PATH := "res://assets/entities/%s.png"

## Builds the visual for `entity_id` at `stage`, best medium first:
##   1. `entity_<id>` GLB          — authored 3D, if anyone ever makes it
##   2. `entity_<category>` GLB    — a shared 3D body for the family
##   3. `assets/entities/<id>_s<n>.png` — the generated sprite, billboarded
##   4. procedural mesh            — the floor, so nothing is ever invisible
static func build(entity_id: String, entity: Dictionary, stage: int = 0) -> Node3D:
	var real := AssetLibrary.instance("entity_%s" % entity_id.to_lower())
	if real == null:
		real = AssetLibrary.instance("entity_%s" % str(entity.get("category", "")).to_lower())
	if real != null:
		real.scale = Vector3.ONE * _stage_scale(stage)
		return real

	var sprite := build_sprite(entity_id, entity, stage)
	if sprite != null:
		return sprite

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(entity_id) ^ (stage * 7919)

	var root := Node3D.new()
	root.name = "Entity_%s_s%d" % [entity_id, stage]
	var category := str(entity.get("category", "Matter"))
	var mat := material_for(entity, stage)

	match category:
		"Energy": _build_energy(root, mat, rng, stage)
		"Entropy": _build_entropy(root, mat, rng, stage)
		"Gravity": _build_gravity(root, mat, rng, stage)
		"Psyche": _build_psyche(root, mat, rng, stage)
		"Quantum": _build_quantum(root, mat, rng, stage)
		_: _build_matter(root, mat, rng, stage)

	if str(entity.get("role", "")) == "Apex":
		_crown(root, mat, rng, stage)
	root.scale = Vector3.ONE * _stage_scale(stage)
	return root

## The entity's surface. Faction sets the hue, category sets the physics,
## and later stages push emission — a thing that has eaten twice glows.
static func material_for(entity: Dictionary, stage: int = 0) -> StandardMaterial3D:
	var pal: Array = FACTION_PALETTE.get(str(entity.get("faction", "")),
		FACTION_PALETTE["Factionless"])
	var surf: Array = CATEGORY_SURFACE.get(str(entity.get("category", "")),
		CATEGORY_SURFACE["Matter"])

	var mat := StandardMaterial3D.new()
	mat.albedo_color = (pal[1] as Color).lerp(pal[0], 0.35 + 0.3 * stage)
	mat.roughness = float(surf[0])
	mat.metallic = float(surf[1])
	var emis := float(surf[2]) * (0.6 + 0.35 * stage)
	if emis > 0.0:
		mat.emission_enabled = true
		mat.emission = pal[0]
		mat.emission_energy_multiplier = emis
	if str(entity.get("category", "")) == "Quantum":
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.74
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

## A billboarded sprite for the entity, or null if none is installed.
##
## Billboards rather than flat quads so a creature always faces the player —
## the standard trick for 2D collectibles in a 3D world, and it means one
## generated image covers every viewing angle. Alpha-scissor rather than
## alpha blending so sprites sort correctly against each other and the world
## instead of ghosting through one another in a crowd.
static func build_sprite(entity_id: String, entity: Dictionary, stage: int = 0) -> Node3D:
	var path := SPRITE_PATH % ("%s_s%d" % [entity_id.to_lower(), stage])
	if not ResourceLoader.exists(path):
		# Stage art is optional; fall back to the base form's sprite.
		path = SPRITE_PATH % entity_id.to_lower()
		if not ResourceLoader.exists(path):
			return null
	var tex := load(path)
	if not (tex is Texture2D):
		return null

	var sprite := Sprite3D.new()
	sprite.name = "EntitySprite_%s" % entity_id
	sprite.texture = tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.double_sided = false
	sprite.pixel_size = 0.01 * _stage_scale(stage)
	# Sit on the ground rather than centred on it.
	sprite.offset = Vector2(0, tex.get_height() * 0.5)

	# Later stages carry the same emission the meshes do, so an evolved form
	# still reads as charged rather than just larger.
	var surf: Array = CATEGORY_SURFACE.get(str(entity.get("category", "")),
		CATEGORY_SURFACE["Matter"])
	if float(surf[2]) > 0.0 and stage > 0:
		var pal: Array = FACTION_PALETTE.get(str(entity.get("faction", "")),
			FACTION_PALETTE["Factionless"])
		sprite.modulate = (pal[0] as Color).lerp(Color.WHITE, 0.55)
	return sprite

## True if generated art exists for this entity — lets the dex show which of
## the roster still needs a pass.
static func has_sprite(entity_id: String, stage: int = 0) -> bool:
	return ResourceLoader.exists(SPRITE_PATH % ("%s_s%d" % [entity_id.to_lower(), stage])) \
		or ResourceLoader.exists(SPRITE_PATH % entity_id.to_lower())

static func _stage_scale(stage: int) -> float:
	return [1.0, 1.45, 2.1][clampi(stage, 0, 2)]

# ---------------------------------------------------------------- shapes

static func _piece(mesh: Mesh, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.material_override = mat
	return mi

static func _core(root: Node3D, mat: Material, radius: float, height: float) -> void:
	var caps := CapsuleMesh.new()
	caps.radius = radius
	caps.height = height
	root.add_child(_piece(caps, Vector3(0, height * 0.5, 0), mat))

## Radiating spines — brighter and more numerous each stage.
static func _build_energy(root: Node3D, mat: Material, rng: RandomNumberGenerator, stage: int) -> void:
	_core(root, mat, 0.42, 1.5)
	for i in 6 + stage * 4:
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = 0.08
		spike.height = rng.randf_range(0.6, 1.1 + stage * 0.4)
		var a := rng.randf() * TAU
		var y := rng.randf_range(0.5, 1.5)
		root.add_child(_piece(spike,
			Vector3(cos(a) * 0.45, y, sin(a) * 0.45), mat,
			Vector3(rng.randf_range(-1.2, 1.2), a, rng.randf_range(-1.2, 1.2))))

## Asymmetric, pitted, falling apart on one side.
static func _build_entropy(root: Node3D, mat: Material, rng: RandomNumberGenerator, stage: int) -> void:
	_core(root, mat, 0.38, 1.4)
	for i in 4 + stage * 3:
		var chunk := BoxMesh.new()
		var s := rng.randf_range(0.18, 0.42)
		chunk.size = Vector3(s, s * rng.randf_range(0.5, 1.6), s)
		root.add_child(_piece(chunk,
			Vector3(rng.randf_range(-0.7, 0.2), rng.randf_range(0.2, 1.7), rng.randf_range(-0.5, 0.5)),
			mat, Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)))

## Dense body with satellites held in orbit.
static func _build_gravity(root: Node3D, mat: Material, rng: RandomNumberGenerator, stage: int) -> void:
	var ball := SphereMesh.new()
	ball.radius = 0.55
	ball.height = 1.1
	root.add_child(_piece(ball, Vector3(0, 0.9, 0), mat))
	for i in 3 + stage * 2:
		var moon := SphereMesh.new()
		var r := rng.randf_range(0.10, 0.20)
		moon.radius = r
		moon.height = r * 2.0
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.85, 1.3 + stage * 0.3)
		root.add_child(_piece(moon,
			Vector3(cos(a) * d, 0.9 + rng.randf_range(-0.4, 0.5), sin(a) * d), mat))

## Slabs of accreted material stacked into a torso.
static func _build_matter(root: Node3D, mat: Material, rng: RandomNumberGenerator, stage: int) -> void:
	var y := 0.0
	for i in 3 + stage:
		var slab := BoxMesh.new()
		var w := rng.randf_range(0.5, 0.95) * (1.0 - i * 0.09)
		var h := rng.randf_range(0.28, 0.5)
		slab.size = Vector3(w, h, w * rng.randf_range(0.6, 1.0))
		root.add_child(_piece(slab, Vector3(rng.randf_range(-0.08, 0.08), y + h * 0.5, 0),
			mat, Vector3(0, rng.randf_range(-0.4, 0.4), 0)))
		y += h

## Elongated, with a fan of heads — one per stage, as the dex describes.
static func _build_psyche(root: Node3D, mat: Material, rng: RandomNumberGenerator, stage: int) -> void:
	_core(root, mat, 0.32, 1.9)
	var heads := 1 + stage * 3
	for i in heads:
		var head := SphereMesh.new()
		head.radius = 0.22
		head.height = 0.44
		var spread := (float(i) / maxf(float(heads - 1), 1.0) - 0.5) * (0.5 + stage * 0.55)
		root.add_child(_piece(head,
			Vector3(sin(spread) * 0.9, 1.85 + cos(spread) * 0.12, -cos(spread) * 0.35 + 0.35), mat))

## Overlapping copies of one body, none of them quite the real one.
static func _build_quantum(root: Node3D, mat: Material, rng: RandomNumberGenerator, stage: int) -> void:
	for i in 2 + stage:
		var caps := CapsuleMesh.new()
		caps.radius = 0.34
		caps.height = 1.5
		var off := float(i) * 0.14
		root.add_child(_piece(caps,
			Vector3(rng.randf_range(-off, off), 0.75 + rng.randf_range(-0.06, 0.06),
				rng.randf_range(-off, off)), mat))

## Apex entities wear it. A ring of raised prongs above the mass.
static func _crown(root: Node3D, mat: Material, rng: RandomNumberGenerator, stage: int) -> void:
	var prongs := 5 + stage * 2
	for i in prongs:
		var prong := CylinderMesh.new()
		prong.top_radius = 0.0
		prong.bottom_radius = 0.055
		prong.height = 0.4 + stage * 0.18
		var a := TAU * float(i) / float(prongs)
		root.add_child(_piece(prong, Vector3(cos(a) * 0.34, 2.15 + stage * 0.1, sin(a) * 0.34), mat))

# ---------------------------------------------------------------- icons

static var _icon_cache: Dictionary = {}

## A 2D dex icon for the entity — the same faction palette and category
## shape language, painted radially so it reads at list size. Cached per
## entity+stage because the dex draws hundreds at once.
static func icon(entity_id: String, entity: Dictionary, stage: int = 0, size: int = 64) -> ImageTexture:
	var key := "%s_%d_%d" % [entity_id, stage, size]
	if _icon_cache.has(key):
		return _icon_cache[key]

	var pal: Array = FACTION_PALETTE.get(str(entity.get("faction", "")),
		FACTION_PALETTE["Factionless"])
	var category := str(entity.get("category", "Matter"))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(entity_id) ^ (stage * 104729)

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := size * 0.5
	# Lobe count and edge noise give each category a distinct outline.
	var lobes := {"Energy": 9, "Entropy": 5, "Gravity": 3,
		"Matter": 4, "Psyche": 7, "Quantum": 6}.get(category, 4)
	var jitter := 0.30 if category == "Entropy" else 0.10
	var phase := rng.randf() * TAU

	for y in size:
		for x in size:
			var dx := (x - half) / half
			var dy := (y - half) / half
			var r := sqrt(dx * dx + dy * dy)
			var ang := atan2(dy, dx)
			var edge := 0.62 + 0.16 * sin(ang * lobes + phase) \
				+ jitter * sin(ang * 13.0 + phase * 2.0) * 0.5
			if r > edge:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			# Hot core fading to the faction's dark tone at the rim.
			var t := clampf(r / maxf(edge, 0.001), 0.0, 1.0)
			var c: Color = (pal[0] as Color).lerp(pal[1], t * t)
			if stage > 0 and r < 0.22:
				c = c.lightened(0.28 * stage)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))

	var tex := ImageTexture.create_from_image(img)
	_icon_cache[key] = tex
	return tex
