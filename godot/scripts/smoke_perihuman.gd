extends SceneTree

func _init() -> void:
	print("[smoke_perihuman] Starting PeriHuman headless smoke test...")
	var dna: HumanDNA = HumanIdentity.build("FEROX", "BASTION", "BERSERKER_CHIP", 42)
	assert(dna != null, "DNA build must not return null")
	print("[smoke_perihuman] Built DNA: %s (%d genes)" % [dna.display_name, dna.genes.size()])
	assert(dna.genes.size() > 0, "DNA genes must not be empty")

	var rig := PeriHumanRig.new()
	root.add_child(rig)
	rig.apply_dna(dna)

	# Verify non-empty skeleton
	var skeleton: Skeleton3D = null
	for child in rig.get_children():
		if child is Skeleton3D:
			skeleton = child
			break
	if skeleton == null and rig.get("_skeleton") != null:
		skeleton = rig.get("_skeleton")
	
	assert(skeleton != null, "Skeleton3D must exist on rig")
	var bone_count := skeleton.get_bone_count()
	print("[smoke_perihuman] PASS: Non-empty skeleton verified with %d bones." % bone_count)
	assert(bone_count > 0, "Skeleton must have bones")

	# Verify 3 LODs (0, 1, 2)
	var body: MeshInstance3D = skeleton.get_node_or_null("Body") as MeshInstance3D
	assert(body != null, "Body MeshInstance3D must exist under skeleton")
	for lod in range(3):
		rig.set_lod(lod, true)
		var body_mesh: ArrayMesh = body.mesh as ArrayMesh
		assert(body_mesh != null, "Body mesh at LOD %d must exist" % lod)
		var surface_count := body_mesh.get_surface_count()
		assert(surface_count > 0, "Body mesh at LOD %d must have surfaces" % lod)
		var vert_count := 0
		var arrays := body_mesh.surface_get_arrays(0)
		if arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] != null:
			vert_count = arrays[Mesh.ARRAY_VERTEX].size()
		print("[smoke_perihuman] PASS: LOD %d generated (surfaces=%d, verts=%d)" % [lod, surface_count, vert_count])
		assert(vert_count > 0, "LOD %d must have vertices" % lod)

	rig.queue_free()
	print("[smoke_perihuman] SUCCESS: All PeriHuman headless checks passed clean.")
	quit(0)
