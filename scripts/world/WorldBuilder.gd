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
var _bark: StandardMaterial3D
var _leaf: StandardMaterial3D
var _rock: StandardMaterial3D
var _bush: StandardMaterial3D
var _grass: StandardMaterial3D

func _init(quality_density := 1.0) -> void:
	density = quality_density
	rng.seed = WORLD_SEED
	_bark = MeshFactory.mat_standard(Color(0.27, 0.20, 0.15), 0.9)
	_leaf = MeshFactory.mat_standard(Color(0.13, 0.27, 0.16), 0.95)
	_rock = MeshFactory.mat_standard(Color(0.30, 0.33, 0.36), 0.85)
	_bush = MeshFactory.mat_standard(Color(0.16, 0.30, 0.18), 0.95)
	_grass = MeshFactory.mat_standard(Color(0.22, 0.38, 0.20), 0.95)

func build(parent: Node3D) -> void:
	_build_ground(parent)
	_build_path(parent)
	_build_boundary(parent)
	_scatter_trees(parent)
	_scatter_rocks(parent)
	_scatter_foliage(parent)
	_build_trail(parent)
	_build_runes(parent)

# -------------------------------------------------------------------- ground
func _build_ground(parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	var pm := PlaneMesh.new()
	pm.size = Vector2(AREA * 2.4, AREA * 2.4)
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	mi.mesh = pm
	mi.material_override = MeshFactory.mat_standard(Color(0.12, 0.17, 0.11), 1.0)
	parent.add_child(mi)

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(AREA * 2.4, 1.0, AREA * 2.4)
	col.shape = shape
	col.position.y = -0.5
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
	var count := int(140 * density)
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 6:
		attempts += 1
		var p := _random_point()
		if _in_clearing(p) or _on_path(p):
			continue
		var tree := MeshFactory.make_tree(rng, _bark, _leaf)
		tree.position = p
		parent.add_child(tree)
		placed += 1

func _scatter_rocks(parent: Node3D) -> void:
	var count := int(35 * density)
	for i in count:
		var p := _random_point()
		if _on_path(p):
			continue
		var rock := MeshFactory.make_rock(rng, _rock)
		rock.position = p
		parent.add_child(rock)

func _scatter_foliage(parent: Node3D) -> void:
	var bushes := int(90 * density)
	for i in bushes:
		var p := _random_point()
		if _on_path(p):
			continue
		var b := MeshFactory.make_bush(rng, _bush)
		b.position = p
		parent.add_child(b)
	var tufts := int(220 * density)
	for i in tufts:
		var p := _random_point()
		var g := MeshFactory.make_grass_tuft(rng, _grass)
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
			marker.position = pos + Vector3(0, 0.04, 0)
			marker.visible = false
			container.add_child(marker)
			trail_markers.append(marker)

func _build_runes(parent: Node3D) -> void:
	# Glowing rune quads that fade in on trees/rocks ringing the clearing.
	var rune_shader := load("res://shaders/rune_glow.gdshader")
	for i in 10:
		var ang := TAU * i / 10.0
		var radius := CLEARING_RADIUS + rng.randf_range(0.5, 2.0)
		var pos := Vector3(cos(ang) * radius, rng.randf_range(1.5, 3.0), sin(ang) * radius)
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

# ---------------------------------------------------------------------- utils
func _random_point() -> Vector3:
	return Vector3(rng.randf_range(-AREA + 1, AREA - 1), 0, rng.randf_range(-AREA + 1, AREA - 1))

func _in_clearing(p: Vector3) -> bool:
	return Vector2(p.x, p.z).length() < CLEARING_RADIUS

func _on_path(p: Vector3) -> bool:
	return absf(p.x) < PATH_HALF_WIDTH and p.z > 0.0 and p.z < 18.5
