extends Node3D
## Quick single-asset viewer (dev tool). Frames one GLB with sky + key light and
## screenshots it from a 3/4 angle. Run:
##   ASSET=res://assets/models/void_colossus.glb ASSET_TAG=colossus \
##     godot --path . tools/AssetView.tscn

func _ready() -> void:
	var path := OS.get_environment("ASSET")
	var tag := OS.get_environment("ASSET_TAG")
	if tag == "":
		tag = "asset"
	# Environment: real HDRI sky for image-based lighting.
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var hdr := "res://assets/hdri/sky_day.hdr"
	if ResourceLoader.exists(hdr):
		var psm := PanoramaSkyMaterial.new()
		psm.panorama = load(hdr)
		sky.sky_material = psm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.4
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42.0, -38.0, 0.0)
	key.light_energy = 1.4
	add_child(key)

	var scn := (load(path) as PackedScene).instantiate()
	add_child(scn)
	await get_tree().process_frame
	# Compute combined AABB.
	var aabb := _aabb_of(scn)
	var center := aabb.get_center()
	var radius := maxf(aabb.size.length() * 0.5, 0.5)
	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)               # must be in-tree before look_at
	cam.current = true
	var dir := Vector3(0.45, 0.18, 1.0).normalized()
	cam.global_position = center + dir * radius * 2.4
	cam.look_at(center, Vector3.UP)

	for i in 30:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/shots"))
	get_viewport().get_texture().get_image().save_png("res://tools/shots/%s.png" % tag)
	print("ASSETVIEW saved: ", tag)
	get_tree().quit()

func _aabb_of(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for c in _all(n):
		if c is VisualInstance3D:
			var a: AABB = (c as VisualInstance3D).get_aabb()
			a = (c as Node3D).global_transform * a
			if first:
				box = a; first = false
			else:
				box = box.merge(a)
	return box

func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
