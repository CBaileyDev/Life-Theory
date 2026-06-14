extends SceneTree
## Headless GLB structure inspector. Run:
##   godot --headless --script res://tools/inspect_glb.gd
## Prints, per model, the MeshInstance3D descendants and their surface/material
## counts so the MultiMesh scatter system knows how to extract meshes.

func _initialize() -> void:
	var slugs := ["pine_tree_01", "fir_tree_01", "tree_small_02", "fir_sapling_medium",
			"rock_moss_set_01", "rock_07", "fern_02", "grass_medium_01", "shrub_01",
			"tree_stump_01", "moss_01", "nettle_plant", "dry_branches", "mushroom_01"]
	for s in slugs:
		var path := "res://assets/models/%s.glb" % s
		if not ResourceLoader.exists(path):
			print("MISSING: ", s)
			continue
		var scn := load(path) as PackedScene
		var inst := scn.instantiate()
		var meshes := []
		_collect(inst, meshes)
		print("=== %s ===  meshinstances=%d" % [s, meshes.size()])
		for m in meshes:
			var mi: MeshInstance3D = m
			var surf := mi.mesh.get_surface_count() if mi.mesh else 0
			var tris := 0
			if mi.mesh:
				for si in surf:
					var arr = mi.mesh.surface_get_arrays(si)
					if arr and arr[Mesh.ARRAY_VERTEX]:
						tris += arr[Mesh.ARRAY_VERTEX].size()
			var mat_names := []
			for si in surf:
				var mt = mi.get_active_material(si)
				mat_names.append(mt.resource_name if mt else "<none>")
			print("   - %s surfaces=%d verts=%d mats=%s aabb=%s" % [mi.name, surf, tris, str(mat_names), str(mi.mesh.get_aabb().size) if mi.mesh else "?"])
		inst.free()
	quit()

func _collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)
