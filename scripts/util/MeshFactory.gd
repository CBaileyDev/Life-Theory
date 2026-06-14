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

static func _foliage() -> Shader:
	if _foliage_shader == null:
		_foliage_shader = load("res://shaders/foliage_wind.gdshader")
	return _foliage_shader

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

## Multi-layer splat terrain material (grass / forest-floor / cliff blended by
## slope + macro noise + a worn path mask). Uses the CC0 sets in
## assets/textures/<layer>_albedo|normal|rough.jpg. Falls back to a flat ground
## material if the grass set is missing, so the project always runs.
static func mat_terrain(tint := Color(1, 1, 1), path_half := 2.6,
		path_zmin := 0.0, path_zmax := 18.5) -> Material:
	var sh := load("res://shaders/terrain.gdshader") as Shader
	if sh == null or not ResourceLoader.exists("res://assets/textures/grass_albedo.jpg"):
		return mat_pbr("ground", 0.12, Color(0.13, 0.19, 0.10))
	var m := ShaderMaterial.new()
	m.shader = sh
	for layer in ["grass", "floor", "cliff"]:
		m.set_shader_parameter(layer + "_albedo", load("res://assets/textures/%s_albedo.jpg" % layer))
		m.set_shader_parameter(layer + "_normal", load("res://assets/textures/%s_normal.jpg" % layer))
		m.set_shader_parameter(layer + "_rough", load("res://assets/textures/%s_rough.jpg" % layer))
	m.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	m.set_shader_parameter("path_half_width", path_half)
	m.set_shader_parameter("path_z_min", path_zmin)
	m.set_shader_parameter("path_z_max", path_zmax)
	return m

## Wind-swayed alpha-tested grass material for the MultiMesh carpet. Reuses the
## grass GLB's own albedo+alpha texture (read off its surface material), so it
## stays correct even if the texture filename changes. Returns null on failure,
## in which case the carpet falls back to the GLB's native (static) material.
static func mat_grass_card(scene: PackedScene, biome := 0) -> Material:
	var sh := load("res://shaders/grass_card.gdshader") as Shader
	if sh == null:
		return null
	var inst := scene.instantiate()
	var mi := _first_mesh(inst)
	var tex: Texture2D = null
	if mi:
		var m = mi.get_active_material(0)
		if m is StandardMaterial3D:
			tex = (m as StandardMaterial3D).albedo_texture
	inst.free()
	if tex == null:
		return null
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("albedo_tex", tex)
	mat.set_shader_parameter("tint", Vector3(1.0, 1.0, 0.92) if biome == 0 else Vector3(0.82, 0.86, 1.10))
	return mat

## A lightweight grass tuft: three crossed quads (~18 verts) UV-mapped to the
## grass-clump billboards in the bottom row of grass_medium_01's atlas. Used for
## the dense MultiMesh carpet — a 7k-vert photoscan mesh ×thousands tanks the
## vertex count; this gives the same lush read for ~400x fewer verts.
static func make_grass_card_mesh(width := 0.6, height := 0.45) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Two of the cleaner full-tuft regions from the atlas bottom row.
	var tufts := [Rect2(0.20, 0.785, 0.19, 0.135), Rect2(0.585, 0.785, 0.20, 0.135)]
	var angles := [0.0, PI / 3.0, 2.0 * PI / 3.0]
	for i in angles.size():
		var a: float = angles[i]
		var uv: Rect2 = tufts[i % tufts.size()]
		var dir := Vector3(cos(a), 0.0, sin(a)) * (width * 0.5)
		var up := Vector3(0.0, height, 0.0)
		var bl := -dir
		var br := dir
		var tl := -dir + up
		var tr := dir + up
		var n := Vector3(0.0, 1.0, 0.0)   # up normal → even, sky-lit grass
		var uvbl := Vector2(uv.position.x, uv.position.y + uv.size.y)
		var uvbr := Vector2(uv.position.x + uv.size.x, uv.position.y + uv.size.y)
		var uvtl := Vector2(uv.position.x, uv.position.y)
		var uvtr := Vector2(uv.position.x + uv.size.x, uv.position.y)
		st.set_normal(n); st.set_uv(uvbl); st.add_vertex(bl)
		st.set_normal(n); st.set_uv(uvbr); st.add_vertex(br)
		st.set_normal(n); st.set_uv(uvtr); st.add_vertex(tr)
		st.set_normal(n); st.set_uv(uvbl); st.add_vertex(bl)
		st.set_normal(n); st.set_uv(uvtr); st.add_vertex(tr)
		st.set_normal(n); st.set_uv(uvtl); st.add_vertex(tl)
	return st.commit()

static func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r:
			return r
	return null

## Reflective pond water (ripple + fresnel shader, with a flat translucent
## fallback). Loomstrata water runs colder/darker.
static func mat_water(biome := 0) -> Material:
	var sh := load("res://shaders/water.gdshader") as Shader
	if sh == null:
		var fm := StandardMaterial3D.new()
		fm.albedo_color = Color(0.08, 0.22, 0.26, 0.78)
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.roughness = 0.06
		return fm
	var m := ShaderMaterial.new()
	m.shader = sh
	if biome == 1:
		# The Loomstrata pool runs cold and starless — no tropical sand glow.
		m.set_shader_parameter("shallow_color", Vector3(0.12, 0.22, 0.36))
		m.set_shader_parameter("deep_color", Vector3(0.02, 0.05, 0.13))
		m.set_shader_parameter("foam_color", Vector3(0.55, 0.62, 0.78))
		m.set_shader_parameter("sky_color", Vector3(0.30, 0.34, 0.50))
		m.set_shader_parameter("clarity", 0.5)
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

## A one-shot impact spark burst (combat hits, projectile impacts). Self-frees
## when the burst finishes. Add it to the scene and set its global_position.
static func spark(color: Color, amount := 20, speed := 4.5, size := 0.16) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.12
	mat.direction = Vector3.UP
	mat.spread = 120.0
	mat.initial_velocity_min = speed * 0.4
	mat.initial_velocity_max = speed
	mat.gravity = Vector3(0, -7.0, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.0
	mat.damping_min = 2.0
	mat.damping_max = 5.0
	mat.color = color
	p.process_material = mat
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	qm.material = mat_emissive(color, 4.5, true)
	p.draw_pass_1 = qm
	p.amount = amount
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	p.finished.connect(p.queue_free)
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
