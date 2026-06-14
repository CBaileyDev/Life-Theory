extends Node
## Generic scene screenshotter for verifying full screens (menu/splash/loading).
## Run: SCENE=res://scenes/MainMenu.tscn SHOT_TAG=menu godot --path . tools/SceneShot.tscn
## Loads the scene, waits SHOT_SECS (default 4) for live backdrops to build/settle,
## then saves tools/shots/<tag>.png and quits.

func _ready() -> void:
	var path := OS.get_environment("SCENE")
	if path == "":
		path = "res://scenes/MainMenu.tscn"
	var tag := OS.get_environment("SHOT_TAG")
	if tag == "":
		tag = "scene"
	var secs := 4.0
	if OS.get_environment("SHOT_SECS") != "":
		secs = float(OS.get_environment("SHOT_SECS"))
	if OS.get_environment("SHOT_QUALITY") != "":
		SettingsManager.set_quality(int(OS.get_environment("SHOT_QUALITY")))
	var scn := (load(path) as PackedScene).instantiate()
	add_child(scn)
	if OS.get_environment("SHOT_TP") == "1":
		await get_tree().process_frame
		SettingsManager.set_third_person(true)
	var elapsed := 0.0
	while elapsed < secs:
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	for i in 3:
		await get_tree().process_frame
	# Diagnostic: where did the player/camera end up?
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var pl = players[0]
		var cam := get_viewport().get_camera_3d()
		print("[PROBE] player_pos=%s on_floor=%s cam_pos=%s cam_fwd=%s" % [
			str(pl.global_position), str(pl.is_on_floor() if pl.has_method("is_on_floor") else "?"),
			str(cam.global_position) if cam else "no_cam",
			str(-cam.global_transform.basis.z) if cam else "?"])
		if cam:
			var from := cam.global_position
			var to := from - cam.global_transform.basis.z * 6.0
			var q := PhysicsRayQueryParameters3D.create(from, to)
			var hit: Dictionary = pl.get_world_3d().direct_space_state.intersect_ray(q)
			if hit.is_empty():
				print("[PROBE] forward ray: NOTHING within 6m")
			else:
				var c = hit.get("collider")
				print("[PROBE] forward ray HIT %s (%s) at %s dist=%.2f" % [
					c.name if c else "?", c.get_class() if c else "?", str(hit.position), from.distance_to(hit.position)])
	if OS.get_environment("SHOT_FREECAM") == "1" and players.size() > 0:
		var pl2 = players[0]
		var freecam := Camera3D.new()
		freecam.fov = 70.0
		add_child(freecam)
		freecam.global_position = pl2.global_position + Vector3(0, 1.65, 0)
		freecam.look_at(pl2.global_position + Vector3(0, 1.55, -6.0), Vector3.UP)
		freecam.current = true
		for i in 4:
			await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/shots"))
	var img := get_viewport().get_texture().get_image()
	var out := "res://tools/shots/%s.png" % tag
	img.save_png(out)
	print("SCENESHOT saved: ", out)
	get_tree().quit()
