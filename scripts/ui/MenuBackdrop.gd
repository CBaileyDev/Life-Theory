class_name MenuBackdrop
extends SubViewportContainer
## MenuBackdrop
## A live 3D view of the REAL game world behind the main menu: the same
## procedural WorldBuilder forest (splat terrain, photoscanned trees, MultiMesh
## grass), warm image-based lighting and a glowing shrine mushroom, filmed by a
## slow cinematic camera drifting through the mist. Rendered at half resolution
## behind the opaque menu, so the second 3D world stays cheap.

var _cam: Camera3D
var _world: WorldBuilder
var _t := 0.0

func _ready() -> void:
	stretch = true
	stretch_shrink = 2   # half-res; it sits behind the menu
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_build_world(vp)

func _build_world(vp: SubViewport) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var hdr := "res://assets/hdri/sky_day.hdr"
	if not ResourceLoader.exists(hdr):
		hdr = "res://assets/hdri/forest_sky.hdr"
	if ResourceLoader.exists(hdr):
		var psm := PanoramaSkyMaterial.new()
		psm.panorama = load(hdr)
		sky.sky_material = psm
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		env.ambient_light_color = Color(0.50, 0.52, 0.43)
		env.ambient_light_sky_contribution = 0.0
		env.ambient_light_energy = 1.0
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
	env.fog_light_color = Color(0.70, 0.73, 0.62)
	env.fog_density = 0.012   # a touch mistier than gameplay, for mood
	env.fog_sun_scatter = 0.4
	env.fog_aerial_perspective = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.15
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.07
	env.adjustment_saturation = 1.2
	we.environment = env
	vp.add_child(we)

	var dir := DirectionalLight3D.new()
	dir.rotation_degrees = Vector3(-32, -100, 0)   # low, raking light shafts
	dir.light_color = Color(1.0, 0.92, 0.76)
	dir.light_energy = 1.6
	dir.light_angular_distance = 1.2
	dir.shadow_enabled = true
	dir.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	vp.add_child(dir)

	# The real procedural forest, at reduced density (it's only a backdrop).
	_world = WorldBuilder.new(0.55, 0, 0.8)
	var root := Node3D.new()
	root.name = "BackdropWorld"
	vp.add_child(root)
	_world.build(root)

	# Glowing shrine mushroom centrepiece, dropped onto the terrain.
	var sh := WorldBuilder.SHRINE_POS
	var sy := _world.height_at(sh.x, sh.z)
	var cap := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 0.85
	cap.mesh = sm
	cap.material_override = MeshFactory.mat_emissive(Color(0.5, 1.0, 0.85), 4.0)
	cap.position = Vector3(sh.x, sy + 1.1, sh.z)
	root.add_child(cap)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.5, 1.0, 0.85)
	glow.light_energy = 4.0
	glow.omni_range = 11.0
	glow.position = Vector3(sh.x, sy + 1.4, sh.z)
	root.add_child(glow)
	var aura := MeshFactory.make_aura(Color(0.6, 1.0, 0.85), 44, 0.6, 1.5, 0.11)
	aura.position = Vector3(sh.x, sy + 0.6, sh.z)
	root.add_child(aura)

	# Drifting fireflies for life.
	var fp := MeshFactory.make_aura(Color(1.0, 0.9, 0.55), 60, 0.25, 9.0, 0.07)
	fp.position = Vector3(0, sy + 2.5, 4)
	root.add_child(fp)

	_cam = Camera3D.new()
	_cam.fov = 58.0
	vp.add_child(_cam)
	_cam.current = true

func _process(delta: float) -> void:
	# Force the container to fill the screen. Relying on anchors alone left it at
	# size (0,0) in some parent layouts, collapsing the SubViewport to 2x2.
	var vpr := get_viewport_rect().size
	if size != vpr:
		size = vpr
	if not _cam or not _world:
		return
	_t += delta
	# Slow cinematic orbit INSIDE the open clearing around the glowing shrine, so
	# the frame reads: shrine-glow foreground, sunlit misty treeline behind. The
	# clearing is tree-free (radius 9.5), so the camera never clips a trunk.
	var ang := _t * 0.06
	var r := 5.5 + sin(_t * 0.11) * 0.8
	var sh := WorldBuilder.SHRINE_POS
	var sy := _world.height_at(sh.x, sh.z)
	var cx := sh.x + cos(ang) * r
	var cz := sh.z + sin(ang) * r
	var cy := sy + 2.1 + sin(_t * 0.3) * 0.25
	_cam.position = Vector3(cx, cy, cz)
	_cam.look_at(Vector3(sh.x, sy + 1.9, sh.z), Vector3.UP)
