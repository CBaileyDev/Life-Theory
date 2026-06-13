class_name MenuBackdrop
extends SubViewportContainer
## MenuBackdrop
## A live 3D forest behind the main menu: a slow orbiting camera over a small
## ring of swaying trees and a glowing shrine mushroom, with fog and bloom.
## Reuses MeshFactory so it shares the game's look. Cheap (a dozen trees).

var _cam: Camera3D
var _angle := 0.0

func _ready() -> void:
	stretch = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_2X
	add_child(vp)
	_build_world(vp)

func _build_world(vp: SubViewport) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.38, 0.5)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.3, 0.4, 0.5)
	env.fog_density = 0.04
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	we.environment = env
	vp.add_child(we)

	var dir := DirectionalLight3D.new()
	dir.rotation_degrees = Vector3(-45, -110, 0)
	dir.light_color = Color(0.6, 0.72, 0.98)
	dir.light_energy = 0.9
	vp.add_child(dir)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var bark := MeshFactory.mat_standard(Color(0.22, 0.16, 0.12), 0.9)
	for i in 14:
		var ang := TAU * i / 14.0 + rng.randf_range(-0.2, 0.2)
		var radius := rng.randf_range(6.5, 10.0)
		var leaf := MeshFactory.mat_foliage(Color(0.12, 0.26, 0.16), 0.18)
		var tree := MeshFactory.make_tree(rng, bark, leaf)
		tree.position = Vector3(cos(ang) * radius, -0.5, sin(ang) * radius)
		vp.add_child(tree)

	# Glowing centrepiece mushroom.
	var cap := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 0.8
	cap.mesh = sm
	cap.material_override = MeshFactory.mat_emissive(Color(0.5, 1.0, 0.85), 4.0)
	cap.position = Vector3(0, 1.3, 0)
	vp.add_child(cap)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.5, 1.0, 0.85)
	glow.light_energy = 3.0
	glow.omni_range = 9.0
	glow.position = Vector3(0, 1.4, 0)
	vp.add_child(glow)
	vp.add_child(MeshFactory.make_aura(Color(0.6, 1.0, 0.85), 40, 0.6, 1.4, 0.1))

	_cam = Camera3D.new()
	_cam.fov = 60.0
	vp.add_child(_cam)

func _process(delta: float) -> void:
	if not _cam:
		return
	_angle += delta * 0.08
	_cam.position = Vector3(cos(_angle) * 11.0, 3.2 + sin(_angle * 0.5) * 0.6, sin(_angle) * 11.0)
	_cam.look_at(Vector3(0, 1.4, 0), Vector3.UP)
