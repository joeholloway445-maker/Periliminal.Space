extends SceneTree
## Headless smoke test for PeriHuman NPC Generation and Spawning.
## Spawns 5 NPCs via PeriHumanNPCGenerator, asserts DNA + genes,
## builds PeriHumanRig instances, prints success, and exits 0.

const NPCGen = preload("res://scripts/PeriHumanNPCGenerator.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[smoke_perihuman_npc] Starting PeriHuman NPC smoke test...")
	var templates: Array[Dictionary] = NPCGen.load_templates()
	if templates.is_empty():
		push_error("[smoke_perihuman_npc] Templates empty!")
		quit(1)
		return

	for i in range(5):
		var arch: Dictionary = templates[i % templates.size()]
		var arch_id: String = str(arch.get("id", "barista"))
		var npc_dict: Dictionary = NPCGen.generate_single_npc(arch_id, i + 500)
		
		assert(not npc_dict.is_empty(), "NPC dictionary must not be empty")
		assert(npc_dict.has("dna"), "NPC dictionary must contain 'dna'")
		var dna_dict: Dictionary = npc_dict["dna"]
		assert(dna_dict.has("genes"), "DNA dictionary must contain 'genes'")
		assert(not dna_dict["genes"].is_empty(), "Genes must not be empty")
		
		# Build DNA object and rig
		var dna: HumanDNA = HumanDNA.from_dict(dna_dict)
		assert(dna != null, "HumanDNA.from_dict must return valid instance")
		
		var rig: PeriHumanRig = PeriHumanRig.new()
		root.add_child(rig)
		rig.apply_dna(dna)
		
		var skeleton: Skeleton3D = rig.get_node_or_null("Skeleton3D")
		if skeleton == null and rig.get("_skeleton") != null:
			skeleton = rig.get("_skeleton")
		assert(skeleton != null and skeleton.get_bone_count() > 0, "Rig must have valid skeleton")
		
		print("[smoke_perihuman_npc] Spawned NPC %d: %s | Archetype: %s | DNA genes: %d | Bones: %d" % [
			i + 1, npc_dict.get("name", ""), arch_id, dna_dict["genes"].size(), skeleton.get_bone_count()
		])
		rig.queue_free()

	print("[smoke_perihuman_npc] SUCCESS: 5 PeriHuman NPCs spawned and verified.")
	quit(0)
