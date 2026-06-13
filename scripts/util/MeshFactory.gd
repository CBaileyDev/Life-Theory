class_name MeshFactory
extends RefCounted
## MeshFactory
## Builds the entire forest from engine primitives + custom materials so the
## prototype ships with zero binary art assets while still reading as an
## intentional, composed scene (good silhouettes, layered canopies, mossy
## stone, glowing artifacts). All meshes/materials are Godot-native and
## therefore identical on macOS and Windows.

# ---------------------------------------------------------------- materials
static var _foliage_shader: Shader = null
static var _ground_shader: Shader = null

static func _foliage() -> Shader:
	if _foliage_shader == null:
		_foliage_shader = load("res://shaders/foliage_wind.gdshader")
	return _foliage_shader

static func _ground() -> Shader:
	if _ground_shader == null:
		_ground_shader = load("res://shaders/ground.gdshader")
	return _ground_shader

## Wind-swaying foliage material. Falls back to a plain material if the shader
## is unavailable, so the world always renders.
static func mat_foliage(color: Color, strength := 0.15, rough := 0.92) -> Material:
	var sh := _foliage()
	if sh == null:
		return mat_standard(color, rough)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("albedo", Vector3(color.r, color.g, color.b))
	m.set_shader_parameter("roughness", rough)
	m.set_shader_parameter("sway_strength", strength)
	return m

## Scanned-PBR triplanar material from the CC0 texture sets in assets/textures/
## (<prefix>_albedo/_normal/_rough .jpg). Falls back to a flat colour if the
## textures are not installed, so the project always runs.
static func mat_pbr(prefix: String, scale := 1.0, fallback := Color(0.5, 0.5, 0.5)) -> Material:
	var base := "res://assets/textures/" + prefix
	if not ResourceLoader.exists(base + "_albedo.jpg"):
		return mat_standard(fallback, 1.0)
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base + "_albedo.jpg")
	if ResourceLoader.exists(base + "_normal.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(base + "_normal.jpg")
		m.normal_scale = 1.0
	if ResourceLoader.exists(base + "_rough.jpg"):
		m.roughness_texture = load(base + "_rough.jpg")
	m.roughness = 1.0
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	return m

static func mat_ground(moss: Color, dirt: Color) -> Material:
	var sh := _ground()
	if sh == null:
		return mat_standard(moss, 1.0)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("moss", Vector3(moss.r, moss.g, moss.b))
	m.set_shader_parameter("dirt", Vector3(dirt.r, dirt.g, dirt.b))
	return m

static func mat_standard(color: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m

## A soft particle aura (rising motes / sinking embers) for magical beings.
static func make_aura(color: Color, amount := 24, rise := 0.5, radius := 0.9, size := 0.09) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = radius
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 25.0
	mat.gravity = Vector3(0, rise, 0)
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.45
	mat.color = color
	p.process_material = mat
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	qm.material = mat_emissive(color, 3.5, true)
	p.draw_pass_1 = qm
	p.amount = amount
	p.lifetime = 2.2
	return p

static func mat_emissive(color: Color, energy := 2.0, transparent := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = color.a
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

# ------------------------------------------------------------------- trees
static func make_tree(rng: RandomNumberGenerator, bark: Material, leaf: Material) -> Node3D:
	var root := Node3D.new()
	root.name = "Tree"
	var height := rng.randf_range(5.0, 9.0)
	var trunk_r := rng.randf_range(0.28, 0.5)

	# Trunk
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = trunk_r * 0.7
	tm.bottom_radius = trunk_r
	tm.height = height
	tm.radial_segments = 6
	trunk.mesh = tm
	trunk.material_override = bark
	trunk.position.y = height * 0.5
	root.add_child(trunk)

	# Canopy: 2-3 stacked cones for a stylised conifer silhouette.
	var layers := rng.randi_range(2, 3)
	var base_y := height * 0.55
	for i in layers:
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		var spread := rng.randf_range(2.6, 3.6) * (1.0 - float(i) / (layers + 1))
		cm.bottom_radius = spread
		cm.height = rng.randf_range(2.4, 3.2)
		cm.radial_segments = 7
		cone.mesh = cm
		cone.material_override = leaf
		cone.position.y = base_y + i * (cm.height * 0.55)
		root.add_child(cone)

	# Trunk collision so the player cannot walk through trees.
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = trunk_r + 0.15
	shape.height = height
	col.shape = shape
	col.position.y = height * 0.5
	body.add_child(col)
	root.add_child(body)

	root.rotation.y = rng.randf_range(0.0, TAU)
	var s := rng.randf_range(0.8, 1.25)
	root.scale = Vector3(s, s, s)
	return root

# ------------------------------------------------------------------- rocks
static func make_rock(rng: RandomNumberGenerator, mat: Material) -> Node3D:
	var root := Node3D.new()
	root.name = "Rock"
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(rng.randf_range(0.8, 2.2), rng.randf_range(0.6, 1.4), rng.randf_range(0.8, 2.2))
	mi.mesh = bm
	mi.material_override = mat
	mi.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0, TAU), rng.randf_range(-0.3, 0.3))
	mi.position.y = bm.size.y * 0.35
	root.add_child(mi)

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = bm.size
	col.shape = shape
	col.position = mi.position
	col.rotation = mi.rotation
	body.add_child(col)
	root.add_child(body)
	return root

# --------------------------------------------------------------- vegetation
static func make_bush(rng: RandomNumberGenerator, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = rng.randf_range(0.5, 1.1)
	sm.height = sm.radius * 1.6
	sm.radial_segments = 6
	sm.rings = 4
	mi.mesh = sm
	mi.material_override = mat
	mi.position.y = sm.radius * 0.5
	mi.scale.y = rng.randf_range(0.6, 0.9)
	return mi

static func make_grass_tuft(rng: RandomNumberGenerator, mat: Material) -> MeshInstance3D:
	# A few crossed quads to suggest grass without a foliage system.
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(rng.randf_range(0.2, 0.45), rng.randf_range(0.4, 0.9), 0.05)
	mi.mesh = pm
	mi.material_override = mat
	mi.position.y = pm.size.y * 0.5
	mi.rotation.y = rng.randf_range(0, TAU)
	return mi
