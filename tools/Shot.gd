extends Node3D
## Shot — offscreen visual-verification harness.
## Builds the real environment + WorldBuilder world (no player/UI), then captures
## a set of screenshots from fixed cinematic camera angles and quits. Lets the
## developer SEE terrain/graphics changes without a human at the keyboard.
##
## Run:  godot --path . tools/Shot.tscn
## Args (optional, via OS env):
##   SHOT_BIOME=0|1     which biome to build (default 0)
##   SHOT_MAGICAL=1     apply the magical palette
##   SHOT_TAG=name      filename prefix (default "shot")
## Output: tools/shots/<tag>_<angle>.png

var _world

func _ready() -> void:
	var biome := int(_env_int("SHOT_BIOME", 0))
	var magical := _env_int("SHOT_MAGICAL", 0) == 1
	var tag := OS.get_environment("SHOT_TAG")
	if tag == "":
		tag = "shot"

	_build_environment(magical, biome)
	var dens := 1.0
	if OS.get_environment("SHOT_DENSITY") != "":
		dens = float(OS.get_environment("SHOT_DENSITY"))
	_world = WorldBuilder.new(dens, biome, 1.0)
	var root := Node3D.new()
	root.name = "World"
	add_child(root)
	_world.build(root)
	if magical:
		for m in _world.trail_markers:
			m.visible = true
		for q in _world.rune_quads:
			q.visible = true

	var cam := Camera3D.new()
	cam.fov = 70.0
	cam.current = true
	add_child(cam)

	await get_tree().process_frame
	# Let shaders compile, async textures stream in, fog/GI settle.
	for i in 30:
		await get_tree().process_frame

	var dir := "res://tools/shots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))

	# A set of framings that exercise the terrain + scatter + sky.
	var shots := [
		{"name": "path", "pos": Vector3(0, 2.6, 16.0), "look": Vector3(0, 1.2, -4.0)},
		{"name": "clearing", "pos": Vector3(0, 2.4, 9.0), "look": Vector3(0, 1.0, -6.0)},
		{"name": "vista", "pos": Vector3(15, 13.0, 15.0), "look": Vector3(0, 0.0, 0.0)},
		{"name": "ground", "pos": Vector3(3, 1.7, 12.0), "look": Vector3(6, 0.6, 2.0)},
		{"name": "eye", "pos": Vector3(-4, 1.7, 8.0), "look": Vector3(4, 1.4, -6.0)},
		{"name": "spawn", "pos": Vector3(0, 1.65, 17.74), "look": Vector3(0, 1.55, 0.0)},
		{"name": "spawnabove", "pos": Vector3(7, 7, 22), "look": Vector3(0, 0.5, 16.0)},
		{"name": "pond", "pos": Vector3(-2.0, 2.6, 15.0), "look": Vector3(-11.5, -0.4, 9.0)},
		{"name": "pondlow", "pos": Vector3(-6.0, 0.6, 14.0), "look": Vector3(-12.0, -0.5, 7.0)},
		{"name": "inpond", "pos": Vector3(-11.5, 0.1, 12.5), "look": Vector3(-11.5, -0.6, 6.0)},
		{"name": "grasslow", "pos": Vector3(2.0, 0.45, 13.0), "look": Vector3(-4.0, 0.3, 6.0)},
		{"name": "skyup", "pos": Vector3(0, 2.0, 10.0), "look": Vector3(0, 14.0, 0.0)},
		{"name": "downgrass", "pos": Vector3(4.0, 1.7, 13.0), "look": Vector3(3.6, 0.0, 11.5)},
		{"name": "downpond", "pos": Vector3(-7.0, 1.7, 12.0), "look": Vector3(-8.0, -0.4, 10.5)},
	]
	for s in shots:
		cam.position = s["pos"]
		cam.look_at(s["look"], Vector3.UP)
		for i in 4:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var path := "%s/%s_%s.png" % [dir, tag, s["name"]]
		img.save_png(path)
		print("SHOT saved: ", path)

	# Quantify the scene cost (draw calls collapse hugely under MultiMesh).
	for i in 4:
		await get_tree().process_frame
	print("PERF draw_calls=%d  primitives=%d  fps=%.0f  objects=%d" % [
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.TIME_FPS),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	get_tree().quit()

func _env_int(key: String, def: int) -> int:
	var v := OS.get_environment(key)
	return int(v) if v != "" else def

func _build_environment(magical: bool, _biome: int) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var hdr_path := "res://assets/hdri/sky_day.hdr"
	if ResourceLoader.exists(hdr_path):
		var psm := PanoramaSkyMaterial.new()
		psm.panorama = load(hdr_path)
		sky.sky_material = psm
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		# Warm FIXED fill (sky_contribution 0): the HDR-bright blue sky otherwise
		# dominates the ambient and tints the shadowed forest floor blue.
		env.ambient_light_color = Color(0.50, 0.52, 0.43)
		env.ambient_light_energy = 1.0
		env.ambient_light_sky_contribution = 0.0
	else:
		var psm := ProceduralSkyMaterial.new()
		sky.sky_material = psm
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.35, 0.42, 0.40)
		env.ambient_light_energy = 0.6
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.72, 0.74, 0.64) if not magical else Color(0.40, 0.46, 0.66)
	env.fog_light_energy = 1.0
	env.fog_density = 0.0045 if not magical else 0.008
	env.fog_sun_scatter = 0.3 if not magical else 0.15
	env.fog_aerial_perspective = 0.55
	env.fog_sky_affect = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.1
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.07
	env.adjustment_saturation = 1.18 if not magical else 1.28
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 2.0
	we.environment = env
	add_child(we)

	var d := DirectionalLight3D.new()
	d.rotation_degrees = Vector3(-38, -115, 0) if not magical else Vector3(-50, -120, 0)
	d.light_color = Color(1.0, 0.93, 0.78) if not magical else Color(0.6, 0.72, 0.98)
	d.light_energy = 1.5 if not magical else 0.85
	d.light_angular_distance = 1.2
	d.shadow_enabled = true
	d.shadow_blur = 1.2
	d.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(d)
