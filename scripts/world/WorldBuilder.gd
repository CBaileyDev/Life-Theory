class_name WorldBuilder
extends RefCounted
## WorldBuilder
## Procedurally composes the forest: ground, a readable dirt path leading from
## the spawn to a central clearing, dense trees/rocks/foliage around the edges,
## invisible boundaries, plus the *hidden* magical layer (luminous trail
## markers and glowing tree runes) that is revealed after the transformation.
## Deterministic via a seed so the layout is consistent run to run.

const WORLD_SEED := 13377
const AREA := 24.0          # half-extent of the playable square
const CLEARING_RADIUS := 9.5
const PATH_HALF_WIDTH := 2.6

# Terrain: gentle rolling hills that flatten toward the clearing and the path
# so gameplay space stays readable.
const HEIGHT_AMP := 2.4
const FLAT_RADIUS := 10.5    # fully flat inside this radius
const BLEND_RADIUS := 18.0   # full height beyond this radius
var _hnoise: FastNoiseLite

# Key locations (shared with the Forest controller for entity placement).
const SPAWN := Vector3(0, 2.0, 18.0)
const SHRINE_POS := Vector3(0, 0, -2.0)
const AURALIS_POS := Vector3(6.0, 0, 3.0)
const WISP_HOME := Vector3(-8.0, 0, -7.0)
const STAG_POS := Vector3(11.0, 0, -11.0)
const FRAGMENT_POS := [
	Vector3(-7.0, 0, -6.0),
	Vector3(7.5, 0, -5.5),
	Vector3(-1.0, 0, -12.0),
]

var rng := RandomNumberGenerator.new()
var density := 1.0

# Outputs collected during build.
var trail_markers: Array[Node3D] = []
var rune_quads: Array[MeshInstance3D] = []

# Shared materials (created once).
var _bark: Material
var _rock: Material
var _ground_mat: Material
var _leaf_variants: Array = []
var _bush_variants: Array = []
var _grass_variants: Array = []

# Photoscanned CC0 model scenes (decimated). Empty arrays => primitive fallback.
const TREE_GLBS := ["pine_tree_01", "fir_tree_01", "tree_small_02"]
const SMALLTREE_GLBS := ["fir_sapling_medium"]
const ROCK_GLBS := ["rock_moss_set_01", "rock_07"]
const GROUND_GLBS := ["fern_02", "grass_medium_01", "shrub_01", "tree_stump_01"]
var _tree_scenes: Array = []
var _smalltree_scenes: Array = []
var _rock_scenes: Array = []
var _ground_scenes: Array = []

func _init(quality_density := 1.0) -> void:
	density = quality_density
	rng.seed = WORLD_SEED
	_hnoise = FastNoiseLite.new()
	_hnoise.seed = WORLD_SEED
	_hnoise.frequency = 0.035
	_hnoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hnoise.fractal_octaves = 3
	# Scanned-PBR (CC0) materials with procedural fallback colours.
	_bark = MeshFactory.mat_pbr("bark", 0.5, Color(0.27, 0.20, 0.15))
	_rock = MeshFactory.mat_pbr("rock", 0.4, Color(0.30, 0.33, 0.36))
	_ground_mat = MeshFactory.mat_pbr("ground", 0.12, Color(0.13, 0.19, 0.10))
	# Several green variants give the canopy/foliage natural colour variation.
	for c in [Color(0.12, 0.26, 0.15), Color(0.15, 0.30, 0.17),
			Color(0.10, 0.22, 0.13), Color(0.17, 0.32, 0.16)]:
		_leaf_variants.append(MeshFactory.mat_foliage(c, 0.16))
	for c in [Color(0.14, 0.28, 0.16), Color(0.17, 0.31, 0.15)]:
		_bush_variants.append(MeshFactory.mat_foliage(c, 0.12))
	for c in [Color(0.20, 0.36, 0.18), Color(0.24, 0.40, 0.20), Color(0.18, 0.33, 0.16)]:
		_grass_variants.append(MeshFactory.mat_foliage(c, 0.22))
	_tree_scenes = _load_scenes(TREE_GLBS)
	_smalltree_scenes = _load_scenes(SMALLTREE_GLBS)
	_rock_scenes = _load_scenes(ROCK_GLBS)
	_ground_scenes = _load_scenes(GROUND_GLBS)

func _load_scenes(slugs: Array) -> Array:
	var out: Array = []
	for s in slugs:
		var path := "res://assets/models/%s.glb" % s
		if ResourceLoader.exists(path):
			out.append(load(path))
	return out

func _pick(arr: Array):
	return arr[rng.randi_range(0, arr.size() - 1)]

## Instance a model scene, wrap it with a random yaw/scale and optional trunk
## collision so the player can't walk through it.
func _spawn_model(scene: PackedScene, pos: Vector3, smin: float, smax: float,
		col_radius := 0.0, col_height := 0.0) -> Node3D:
	var root := Node3D.new()
	root.add_child(scene.instantiate())
	root.position = pos
	root.rotation.y = rng.randf_range(0.0, TAU)
	var s := rng.randf_range(smin, smax)
	root.scale = Vector3(s, s, s)
	if col_radius > 0.0:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = col_radius
		shape.height = col_height
		col.shape = shape
		col.position.y = col_height * 0.5
		body.add_child(col)
		root.add_child(body)
	return root

func build(parent: Node3D) -> void:
	_build_ground(parent)
	_build_path(parent)
	_build_boundary(parent)
	_scatter_trees(parent)
	_scatter_rocks(parent)
	_scatter_foliage(parent)
	_build_trail(parent)
	_build_runes(parent)
	_build_sight_glyphs(parent)

# -------------------------------------------------------------------- ground
## Sampleable terrain height. Flat in the clearing and along the entrance path,
## rolling toward the edges. Used both to build the mesh and to drop every
## object/entity onto the surface.
func height_at(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var radial := clampf((d - FLAT_RADIUS) / (BLEND_RADIUS - FLAT_RADIUS), 0.0, 1.0)
	# Flatten the entrance path corridor as well.
	if z > -1.0 and z < 19.0:
		var pflat := clampf((absf(x) - (PATH_HALF_WIDTH + 1.0)) / 3.0, 0.0, 1.0)
		radial = minf(radial, pflat)
	return _hnoise.get_noise_2d(x, z) * HEIGHT_AMP * radial

func _build_ground(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := AREA + 4.0
	var step := 1.6
	var cols := int((half * 2.0) / step)
	for ix in cols:
		for iz in cols:
			var x0 := -half + ix * step
			var z0 := -half + iz * step
			var x1 := x0 + step
			var z1 := z0 + step
			var v00 := Vector3(x0, height_at(x0, z0), z0)
			var v10 := Vector3(x1, height_at(x1, z0), z0)
			var v01 := Vector3(x0, height_at(x0, z1), z1)
			var v11 := Vector3(x1, height_at(x1, z1), z1)
			st.add_vertex(v00); st.add_vertex(v01); st.add_vertex(v11)
			st.add_vertex(v00); st.add_vertex(v11); st.add_vertex(v10)
	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = mesh
	mi.material_override = _ground_mat
	parent.add_child(mi)

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = mesh.create_trimesh_shape()
	body.add_child(col)
	parent.add_child(body)

# ---------------------------------------------------------------------- path
func _build_path(parent: Node3D) -> void:
	# A mossy strip from the spawn (z=18) to the clearing (z=0).
	var mi := MeshInstance3D.new()
	mi.name = "Path"
	var pm := PlaneMesh.new()
	pm.size = Vector2(PATH_HALF_WIDTH * 2.0, 19.0)
	mi.mesh = pm
	mi.material_override = MeshFactory.mat_standard(Color(0.24, 0.21, 0.15), 1.0)
	mi.position = Vector3(0, 0.02, 9.0)
	parent.add_child(mi)

# ------------------------------------------------------------------ boundary
func _build_boundary(parent: Node3D) -> void:
	# Four invisible walls keep the player inside the playable area.
	var positions := [
		[Vector3(0, 5, -AREA), Vector3(AREA * 2, 10, 1)],
		[Vector3(0, 5, AREA), Vector3(AREA * 2, 10, 1)],
		[Vector3(-AREA, 5, 0), Vector3(1, 10, AREA * 2)],
		[Vector3(AREA, 5, 0), Vector3(1, 10, AREA * 2)],
	]
	for entry in positions:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = entry[1]
		col.shape = shape
		body.position = entry[0]
		body.add_child(col)
		parent.add_child(body)

# ------------------------------------------------------------------- scatter
func _scatter_trees(parent: Node3D) -> void:
	var use_models: bool = _tree_scenes.size() > 0
	# Photoscanned trees are heavier than primitives, so use fewer of them.
	var count := int((90 if use_models else 140) * density)
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 6:
		attempts += 1
		var p := _random_point()
		if _in_clearing(p) or _on_path(p):
			continue
		p.y = height_at(p.x, p.z)
		var tree: Node3D
		if use_models:
			# Occasional sapling for understory variation.
			if _smalltree_scenes.size() > 0 and rng.randf() < 0.25:
				tree = _spawn_model(_pick(_smalltree_scenes), p, 0.8, 1.4, 0.3, 3.0)
			else:
				tree = _spawn_model(_pick(_tree_scenes), p, 0.85, 1.3, 0.45, 7.0)
		else:
			tree = MeshFactory.make_tree(rng, _bark, _pick(_leaf_variants))
			tree.position = p
		parent.add_child(tree)
		placed += 1

func _scatter_rocks(parent: Node3D) -> void:
	var count := int(35 * density)
	for i in count:
		var p := _random_point()
		if _on_path(p):
			continue
		p.y = height_at(p.x, p.z)
		var rock: Node3D
		if _rock_scenes.size() > 0:
			rock = _spawn_model(_pick(_rock_scenes), p, 0.7, 1.8)
		else:
			rock = MeshFactory.make_rock(rng, _rock)
			rock.position = p
		parent.add_child(rock)

func _scatter_foliage(parent: Node3D) -> void:
	# Ground cover: photoscanned ferns/grass/shrubs/stumps if available.
	if _ground_scenes.size() > 0:
		var clumps := int(160 * density)
		for i in clumps:
			var p := _random_point()
			p.y = height_at(p.x, p.z)
			parent.add_child(_spawn_model(_pick(_ground_scenes), p, 0.7, 1.5))
	else:
		var bushes := int(90 * density)
		for i in bushes:
			var p := _random_point()
			if _on_path(p):
				continue
			p.y = height_at(p.x, p.z)
			var b := MeshFactory.make_bush(rng, _pick(_bush_variants))
			b.position = p
			parent.add_child(b)
		var tufts := int(220 * density)
		for i in tufts:
			var p := _random_point()
			p.y = height_at(p.x, p.z)
			var g := MeshFactory.make_grass_tuft(rng, _pick(_grass_variants))
			g.position = p
			parent.add_child(g)

# ------------------------------------------------------- hidden magical layer
func _build_trail(parent: Node3D) -> void:
	# A luminous trail of runed stones looping through the clearing, connecting
	# the shrine to Auralis and on toward the fragments. Hidden until revealed.
	var waypoints := [SHRINE_POS, Vector3(2, 0, 0), AURALIS_POS,
		FRAGMENT_POS[1], Vector3(0, 0, -8), FRAGMENT_POS[2], FRAGMENT_POS[0]]
	var trail_mat := MeshFactory.mat_emissive(Color(0.55, 0.85, 1.0), 3.0, true)
	var container := Node3D.new()
	container.name = "LuminousTrail"
	parent.add_child(container)
	for i in range(waypoints.size() - 1):
		var a: Vector3 = waypoints[i]
		var b: Vector3 = waypoints[i + 1]
		var steps := int(a.distance_to(b) / 1.4)
		for s in range(steps):
			var t := float(s) / maxf(steps, 1)
			var pos: Vector3 = a.lerp(b, t)
			var marker := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.35
			cm.bottom_radius = 0.35
			cm.height = 0.06
			marker.mesh = cm
			marker.material_override = trail_mat
			marker.position = Vector3(pos.x, height_at(pos.x, pos.z) + 0.05, pos.z)
			marker.visible = false
			container.add_child(marker)
			trail_markers.append(marker)

func _build_runes(parent: Node3D) -> void:
	# Glowing rune quads that fade in on trees/rocks ringing the clearing.
	var rune_shader := load("res://shaders/rune_glow.gdshader")
	for i in 10:
		var ang := TAU * i / 10.0
		var radius := CLEARING_RADIUS + rng.randf_range(0.5, 2.0)
		var rx := cos(ang) * radius
		var rz := sin(ang) * radius
		var pos := Vector3(rx, height_at(rx, rz) + rng.randf_range(1.5, 3.0), rz)
		var quad := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.2, 1.2)
		quad.mesh = qm
		if rune_shader:
			var sm := ShaderMaterial.new()
			sm.shader = rune_shader
			sm.set_shader_parameter("glow_color", Vector3(0.7, 0.55, 1.0))
			quad.material_override = sm
		else:
			quad.material_override = MeshFactory.mat_emissive(Color(0.7, 0.55, 1.0), 3.0, true)
		quad.visible = false
		parent.add_child(quad)
		# Face the centre of the clearing (node must be in-tree for look_at).
		quad.look_at_from_position(pos, Vector3(0, pos.y, 0), Vector3.UP)
		rune_quads.append(quad)

# Hidden "truth-glyphs" — invisible until the player opens the Sight, then they
# float through the trees as glowing marks of the simulation beneath.
func _build_sight_glyphs(parent: Node3D) -> void:
	var mat := MeshFactory.mat_emissive(Color(0.6, 0.95, 1.0, 0.9), 4.0, true)
	for i in 18:
		var p := _random_point()
		var glyph := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.8, 0.8)
		glyph.mesh = qm
		glyph.material_override = mat
		glyph.position = Vector3(p.x, height_at(p.x, p.z) + rng.randf_range(1.0, 3.0), p.z)
		glyph.rotation.y = rng.randf_range(0.0, TAU)
		glyph.visible = false
		parent.add_child(glyph)
		glyph.add_to_group("sight_only")

# ---------------------------------------------------------------------- utils
func _random_point() -> Vector3:
	return Vector3(rng.randf_range(-AREA + 1, AREA - 1), 0, rng.randf_range(-AREA + 1, AREA - 1))

func _in_clearing(p: Vector3) -> bool:
	return Vector2(p.x, p.z).length() < CLEARING_RADIUS

func _on_path(p: Vector3) -> bool:
	return absf(p.x) < PATH_HALF_WIDTH and p.z > 0.0 and p.z < 18.5
