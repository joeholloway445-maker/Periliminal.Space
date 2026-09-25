extends SceneTree
## Headless NPC spawner harness for PeriHuman characters.
## Takes generated NPC dicts, constructs HumanDNA from dict["dna"],
## instantiates PeriHumanRig, prints id + dna keys, and exits 0.

const NPCGen = preload("res://scripts/PeriHumanNPCGenerator.gd")

func _initialize() -> void:
	call_deferred("_run_headless_spawn")

func _ready() -> void:
	call_deferred("_run_headless_spawn")

func _run_headless_spawn() -> void:
	print("[npc_spawner] Starting headless NPC spawn test (3 NPCs)...")
	var archetypes := ["barista", "authority", "smuggler"]
	
	for i in range(3):
		var arch_id: String = archetypes[i % archetypes.size()]
		var npc_dict: Dictionary = NPCGen.generate_single_npc(arch_id, i + 999)
		var rig: PeriHumanRig = spawn_from_dict(npc_dict, root)
		assert(rig != null, "Spawned rig must not be null")
		
		var dna_dict: Dictionary = npc_dict.get("dna", {})
		print("[npc_spawner] Spawned NPC #%d: ID=%s | Archetype=%s | DNA keys=%s" % [
			i + 1,
			str(npc_dict.get("id", "")),
			str(npc_dict.get("archetype", "")),
			str(dna_dict.keys())
		])
		rig.queue_free()

	print("[npc_spawner] SUCCESS: 3 NPCs spawned from DNA dictionaries.")
	quit(0)

static func spawn_from_dict(npc_dict: Dictionary, parent: Node = null) -> PeriHumanRig:
	var dna_dict: Dictionary = npc_dict.get("dna", {})
	var dna: HumanDNA = HumanDNA.from_dict(dna_dict)
	if dna == null:
		push_error("[npc_spawner] Failed to parse HumanDNA from dictionary")
		return null

	var rig := PeriHumanRig.new()
	if parent != null:
		parent.add_child(rig)
	rig.apply_dna(dna)
	return rig
