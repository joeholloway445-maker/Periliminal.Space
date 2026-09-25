class_name PeriHumanNPCGenerator
extends SceneTree

const TEMPLATES_PATH := "res://data/npc_templates.json"

static var _cached_templates: Array[Dictionary] = []
static var _cached_raw_data: Dictionary = {}

static func load_templates() -> Array[Dictionary]:
	if not _cached_templates.is_empty():
		return _cached_templates
	if not FileAccess.file_exists(TEMPLATES_PATH):
		push_error("[PeriHumanNPCGenerator] Template file not found: " + TEMPLATES_PATH)
		return []
	var f = FileAccess.open(TEMPLATES_PATH, FileAccess.READ)
	if f == null:
		push_error("[PeriHumanNPCGenerator] Failed to open template file.")
		return []
	var text: String = f.get_as_text()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("[PeriHumanNPCGenerator] JSON parse error: " + json.get_error_message())
		return []
	var data = json.data
	if data is Dictionary:
		_cached_raw_data = data
		var archs = data.get("archetypes", [])
		if archs is Array:
			for a in archs:
				if a is Dictionary:
					_cached_templates.append(a)
	return _cached_templates

static func generate_single_npc(archetype_id: String = "", seed_val: int = 0) -> Dictionary:
	var templates = load_templates()
	if templates.is_empty():
		return {}

	var rng = RandomNumberGenerator.new()
	if seed_val != 0:
		rng.seed = seed_val
	else:
		rng.randomize()

	var arch: Dictionary = {}
	if not archetype_id.is_empty():
		for t in templates:
			if str(t.get("id", "")) == archetype_id:
				arch = t
				break
	if arch.is_empty():
		arch = templates[rng.randi() % templates.size()]
		archetype_id = str(arch.get("id", "wanderer"))

	# Pick Canon Race, Frame, Mod
	var race_name: String = str(CanonRaces.RACES[rng.randi() % CanonRaces.RACES.size()])
	var frame_keys = HumanFrameArchetypes.FRAMES.keys()
	var frame_id: String = str(frame_keys[rng.randi() % frame_keys.size()]) if not frame_keys.is_empty() else ""
	var mod_keys = HumanModArchetypes.MODS.keys()
	var mod_id: String = str(mod_keys[rng.randi() % mod_keys.size()]) if not mod_keys.is_empty() else ""

	var dna: HumanDNA = HumanIdentity.build(race_name, frame_id, mod_id, seed_val)
	var traits: Dictionary = arch.get("traits", {})

	# 1. Age range -> gene 'age' (0..1, lerp 18..80)
	var age_range: Dictionary = traits.get("age", {"min": 20, "max": 50})
	var raw_age: float = rng.randf_range(float(age_range.get("min", 20)), float(age_range.get("max", 50)))
	var norm_age: float = clampf((raw_age - 18.0) / (80.0 - 18.0), 0.0, 1.0)
	dna.set_gene("age", norm_age)

	# 2. Build list -> gene 'build' + 'muscle'
	var builds: Array = traits.get("build", ["average"])
	var chosen_build: String = str(builds[rng.randi() % builds.size()]).to_lower()
	var build_val := 0.45
	var muscle_val := 0.40
	match chosen_build:
		"slim":
			build_val = 0.25
			muscle_val = 0.20
		"average":
			build_val = 0.45
			muscle_val = 0.40
		"athletic":
			build_val = 0.55
			muscle_val = 0.65
		"muscular":
			build_val = 0.70
			muscle_val = 0.85
	dna.set_gene("build", build_val)
	dna.set_gene("muscle", muscle_val)

	# 3. Skin tones -> gene 'skin_melanin'
	var skin_tones: Array = traits.get("skin_tones", ["medium"])
	var chosen_tone: String = str(skin_tones[rng.randi() % skin_tones.size()]).to_lower()
	var melanin := 0.50
	match chosen_tone:
		"pale": melanin = 0.10
		"fair": melanin = 0.15
		"olive": melanin = 0.40
		"medium": melanin = 0.50
		"tan": melanin = 0.55
		"dark": melanin = 0.75
		"deep": melanin = 0.90
	dna.set_gene("skin_melanin", melanin)

	# 4. Hair styles -> HumanDNA.HAIR_STYLES only
	var available_styles: Array = traits.get("hair_styles", HumanDNA.HAIR_STYLES)
	var valid_styles: Array[String] = []
	for s in available_styles:
		var st := str(s).to_lower()
		if st in HumanDNA.HAIR_STYLES:
			valid_styles.append(st)
	if valid_styles.is_empty():
		valid_styles.assign(HumanDNA.HAIR_STYLES)
	dna.hair_style = valid_styles[rng.randi() % valid_styles.size()]

	# Hair colors
	var hair_colors: Array = traits.get("hair_colors", ["brown"])
	var chosen_color_name: String = str(hair_colors[rng.randi() % hair_colors.size()]).to_lower()
	match chosen_color_name:
		"black": dna.hair_color = Color("0d0d10")
		"brown": dna.hair_color = Color("3d261a")
		"blonde": dna.hair_color = Color("d9c68c")
		"auburn": dna.hair_color = Color("8c3b1a")
		"grey": dna.hair_color = Color("8a8a94")
		"white": dna.hair_color = Color("e0e0ea")
		"red": dna.hair_color = Color("9e2a14")
		"purple": dna.hair_color = Color("5c2673")
		_: dna.hair_color = Color("291c12")

	# Freckles / stubble only if archetype explicitly asks
	if traits.has("freckles"):
		dna.set_gene("freckles", float(traits["freckles"]))
	if traits.has("stubble"):
		dna.set_gene("stubble", float(traits["stubble"]))

	# Pick Name
	var first_name := "Citizen"
	var last_name := "Periliminal"
	var name_pools: Dictionary = _cached_raw_data.get("name_pools", {})
	if not name_pools.is_empty():
		var neutral: Array = name_pools.get("first_names_neutral", [])
		var fem: Array = name_pools.get("first_names_feminine", [])
		var masc: Array = name_pools.get("first_names_masculine", [])
		var all_firsts := neutral + fem + masc
		if not all_firsts.is_empty():
			first_name = str(all_firsts[rng.randi() % all_firsts.size()])
		var lasts: Array = name_pools.get("last_names", [])
		if not lasts.is_empty():
			last_name = str(lasts[rng.randi() % lasts.size()])

	var full_name := "%s %s" % [first_name, last_name]
	dna.display_name = full_name
	var npc_id := "npc_%s_%d" % [archetype_id, abs(seed_val) if seed_val != 0 else rng.randi() % 100000]

	return {
		"id": npc_id,
		"archetype": archetype_id,
		"name": full_name,
		"dna": dna.to_dict(),
		"race": race_name,
		"frame": frame_id,
		"mod": mod_id
	}

static func export_npcs_to_json(path: String, count: int) -> void:
	var npcs := []
	for i in range(count):
		npcs.append(generate_single_npc("", 1000 + i))
	var json_str := JSON.stringify(npcs, "  ")
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(json_str)
		f.close()

func _init() -> void:
	print("[PeriHumanNPCGenerator] Running unit test harness...")
	var templates = load_templates()
	print("[PeriHumanNPCGenerator] Loaded %d archetypes." % templates.size())
	assert(templates.size() >= 20, "Archetype count must be >= 20")

	var smoke_results: Array[Dictionary] = []
	var sample_archetypes := ["barista", "archivist", "authority", "bounty_hunter", "gladiator"]
	for i in range(5):
		var target_arch: String = sample_archetypes[i] if i < sample_archetypes.size() else ""
		var npc = generate_single_npc(target_arch, 4242 + i)
		assert(not npc.is_empty(), "Generated NPC must not be empty")
		assert(npc.has("dna"), "NPC dict must contain 'dna'")
		var dna_dict: Dictionary = npc["dna"]
		assert(dna_dict.has("genes"), "DNA dict must contain 'genes'")
		var genes: Dictionary = dna_dict["genes"]
		assert(not genes.is_empty(), "DNA genes must not be empty")
		assert(dna_dict.has("hair_style"), "DNA must have hair_style")
		assert(dna_dict["hair_style"] in HumanDNA.HAIR_STYLES, "Hair style must be valid")
		assert(dna_dict.has("hair_color"), "DNA must have hair_color")
		smoke_results.append(npc)
		print("[PeriHumanNPCGenerator] PASS: NPC %d [%s / %s / %s] DNA validated." % [i, npc["id"], npc["archetype"], npc["name"]])

	# Write smoke file to /tmp/npc_smoke.json (or local fallback)
	var tmp_dir: String = "C:/tmp" if OS.get_name() == "Windows" else "/tmp"
	var write_paths: Array[String] = [tmp_dir + "/npc_smoke.json", "user://npc_smoke.json"]
	for p in write_paths:
		var dir: String = p.get_base_dir()
		if not dir.is_empty() and not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		var f = FileAccess.open(p, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(smoke_results, "  "))
			f.close()
			print("[PeriHumanNPCGenerator] Wrote smoke output to: %s" % p)

	print("[PeriHumanNPCGenerator] ALL CHECKS PASSED SUCCESSFULLY.")
	quit(0)