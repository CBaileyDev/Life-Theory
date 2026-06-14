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
const SPAWN_CLEAR := 6.0   # keep trees/rocks this far from the spawn at all densities

# A still reflective pond carved into the terrain, left of the entrance path so
# it frames a quiet vista on the way in. The bowl is dug locally in height_at.
const POND := Vector3(-11.5, 0.0, 9.0)
const POND_R := 6.5
const POND_DEPTH := 2.0
const WATER_LEVEL := -0.55

# Cairn Ridge — a gentle climbable mound in the west spur, topped by an overlook
# that frames the layer below (the design's signature vista / "wow" moment).
const RIDGE := Vector3(-19.0, 0.0, -1.0)
const RIDGE_R := 11.0
const RIDGE_H := 6.5
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
var cull_mult := 1.0   # per-quality LOD distance multiplier (Low pulls foliage in)
var biome := 0   # GameState.Biome: 0 Quietwood, 1 Loomstrata

# Base distances (metres) at which each scatter category fades out (scaled by
# cull_mult). Distant alpha-tested grass/fern overdraw is the second-biggest
# foliage cost after draw-call count, so culling it cheaply recovers fill rate.
const CULL_TREE := 70.0
const CULL_SMALLTREE := 48.0
const CULL_ROCK := 48.0
const CULL_GROUND := 26.0

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
# Hand-sculpted originals (Blender, from scratch) — boulders + the giant
# Washington-style pine that towers over the canopy.
const ROCK_GLBS := ["mossy_granite"]
const GIANT_PINE_GLBS := ["quiet_giant"]
# A dense, wind-swayed grass carpet (own MultiMesh) is the floor's main life.
const GRASS_GLB := "grass_medium_01"
# Ground-cover scatter as a data table: [slug, count, scale_min, scale_max,
# y_offset]. Each type becomes one MultiMeshInstance3D (one draw batch for the
# whole world). Tuned per-asset because the source meshes vary wildly in size.
const GROUND_COVER := [
	["fern_02", 260, 0.55, 1.2, -0.05],
	["shrub_01", 70, 0.7, 1.3, -0.05],
	["nettle_plant", 70, 0.3, 0.6, -0.02],
	["dry_branches", 130, 0.6, 1.2, 0.0],
	["tree_stump_01", 22, 0.6, 1.1, -0.06],
	["ultraviolet_mushroom", 16, 0.8, 1.7, -0.02],   # Meshy AI glowing accents (now 26k tris)
]
var _tree_scenes: Array = []
var _smalltree_scenes: Array = []
var _rock_scenes: Array = []
var _giant_pine_scenes: Array = []
var _grass_scene: PackedScene = null
# Cache of extracted {mesh, xform} per PackedScene for MultiMesh building.
var _mm_cache := {}

func _init(quality_density := 1.0, biome_id := 0, lod_mult := 1.0) -> void:
	density = quality_density
	cull_mult = lod_mult
	biome = biome_id
	rng.seed = WORLD_SEED + biome * 101  # a distinct layout per biome
	_hnoise = FastNoiseLite.new()
	_hnoise.seed = WORLD_SEED
	_hnoise.frequency = 0.035
	_hnoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hnoise.fractal_octaves = 3
	# Scanned-PBR (CC0) materials with procedural fallback colours.
	_bark = MeshFactory.mat_pbr("bark", 0.5, Color(0.27, 0.20, 0.15))
	_rock = MeshFactory.mat_pbr("rock", 0.4, Color(0.30, 0.33, 0.36))
	# Splat terrain: Quietwood runs warm-green, the Loomstrata cooler/violet.
	var ground_tint := Color(1.06, 1.04, 0.92) if biome == 0 else Color(0.82, 0.86, 1.10)
	_ground_mat = MeshFactory.mat_terrain(ground_tint, PATH_HALF_WIDTH, -0.5, 18.5)
	# Several variants give natural colour variation; the Loomstrata runs cooler
	# and more violet (a deeper, stranger layer).
	var leaf_colors := [Color(0.12, 0.26, 0.15), Color(0.15, 0.30, 0.17),
			Color(0.10, 0.22, 0.13), Color(0.17, 0.32, 0.16)]
	if biome == 1:
		leaf_colors = [Color(0.16, 0.22, 0.30), Color(0.22, 0.20, 0.34),
			Color(0.12, 0.24, 0.28), Color(0.26, 0.24, 0.38)]
	for c in leaf_colors:
		_leaf_variants.append(MeshFactory.mat_foliage(c, 0.16))
	for c in [Color(0.14, 0.28, 0.16), Color(0.17, 0.31, 0.15)]:
		_bush_variants.append(MeshFactory.mat_foliage(c, 0.12))
	for c in [Color(0.20, 0.36, 0.18), Color(0.24, 0.40, 0.20), Color(0.18, 0.33, 0.16)]:
		_grass_variants.append(MeshFactory.mat_foliage(c, 0.22))
	_tree_scenes = _load_scenes(TREE_GLBS)
	_smalltree_scenes = _load_scenes(SMALLTREE_GLBS)
	_rock_scenes = _load_scenes(ROCK_GLBS)
	_giant_pine_scenes = _load_scenes(GIANT_PINE_GLBS)
	var grass_path := "res://assets/models/%s.glb" % GRASS_GLB
	if ResourceLoader.exists(grass_path):
		_grass_scene = load(grass_path)

func _load_scenes(slugs: Array) -> Array:
	var out: Array = []
	for s in slugs:
		var path := "res://assets/models/%s.glb" % s
		if ResourceLoader.exists(path):
			out.append(load(path))
	return out

func _pick(arr: Array):
	return arr[rng.randi_range(0, arr.size() - 1)]

func build(parent: Node3D) -> void:
	_build_ground(parent)
	_build_water(parent)
	_build_boundary(parent)
	_scatter_giant_pines(parent)
	_scatter_trees(parent)
	_scatter_understory(parent)
	_scatter_rocks(parent)
	_build_logs(parent)
	_scatter_grass_carpet(parent)
	_scatter_grass_tufts(parent)
	_scatter_foliage(parent)
	_build_wrong_tree(parent)
	_build_overlook(parent)
	_build_lilies(parent)
	_build_light_shafts(parent)
	if biome == 1:
		_build_seams(parent)
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
	radial = smoothstep(0.0, 1.0, radial)   # ease the rise out of the flat zone
	# Flatten the entrance path corridor as well.
	if z > -1.0 and z < 19.0:
		var pflat := clampf((absf(x) - (PATH_HALF_WIDTH + 1.0)) / 3.0, 0.0, 1.0)
		radial = minf(radial, pflat)
	# Two octaves of rolling ground: fine detail + broad swells. A gentle rim
	# berm lifts toward the boundary so the clearing reads as a nestled bowl
	# (natural occlusion + a framed treeline, per the world design).
	var detail := _hnoise.get_noise_2d(x, z) * HEIGHT_AMP
	var swell := _hnoise.get_noise_2d(x * 0.28 + 100.0, z * 0.28 + 100.0) * (HEIGHT_AMP * 1.5)
	var rim := smoothstep(AREA * 0.55, AREA * 1.05, d) * 2.6
	var h := (detail + swell + rim) * radial
	# Carve the pond bowl locally so the water has a basin to sit in.
	var pd := Vector2(x - POND.x, z - POND.z).length()
	if pd < POND_R:
		h -= (1.0 - smoothstep(0.0, POND_R, pd)) * POND_DEPTH
	# Cairn Ridge: a gentle mound (walkable slope) rising to the west overlook.
	# Biome 0 only — terracing the mound in the Loomstrata could make it unclimbable.
	if biome == 0:
		var rd := Vector2(x - RIDGE.x, z - RIDGE.z).length()
		if rd < RIDGE_R:
			h += (1.0 - smoothstep(0.0, RIDGE_R, rd)) * RIDGE_H
	# Loomstrata: the world stops pretending to be nature. Quantise the rolling
	# ground into flat FAULT-TERRACES — resolution loss reads as faceting. The
	# clearing/path stay flat (h≈0 → floors to 0), so traversal is unaffected.
	if biome == 1:
		h = floor(h / 0.45) * 0.45   # gentle terraces — jumpable steps, no traps
	return h

func _build_ground(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := AREA + 4.0
	var step := 1.0   # finer grid → smoother slope shading for the splat shader
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

	# Collision: a HeightMapShape3D (solid heightfield), NOT a trimesh. A
	# zero-thickness concave trimesh can't reliably depenetrate the player's
	# capsule — it falls through the surface and wedges below it (is_on_floor
	# never becomes true, so the player can't move). A heightfield gives the
	# capsule a stable, walkable floor. Sampled on a 1-unit grid from height_at.
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var hm := HeightMapShape3D.new()
	var n := int(half * 2.0) + 1            # samples per side (1-unit cells)
	var c := half                            # grid is centred on the origin
	hm.map_width = n
	hm.map_depth = n
	var data := PackedFloat32Array()
	data.resize(n * n)
	for j in n:
		for i in n:
			data[j * n + i] = height_at(float(i) - c, float(j) - c)
	hm.map_data = data
	col.shape = hm
	body.add_child(col)
	parent.add_child(body)

# -------------------------------------------------------------------- water
func _build_water(parent: Node3D) -> void:
	_build_pond_bed(parent)
	var mi := MeshInstance3D.new()
	mi.name = "Pond"
	var pm := PlaneMesh.new()
	pm.size = Vector2(POND_R * 2.3, POND_R * 2.3)
	mi.mesh = pm
	mi.position = Vector3(POND.x, WATER_LEVEL, POND.z)
	mi.material_override = MeshFactory.mat_water(biome)
	parent.add_child(mi)

## A pale sandy bed laid into the pond basin so the clear turquoise water reads
## bright (Trunk Bay over white sand) rather than tinting dark forest floor. The
## disc follows the carved bowl (sampled from height_at) a few cm above the
## terrain. Quietwood only — the Loomstrata pool stays a cold, bottomless dark.
func _build_pond_bed(parent: Node3D) -> void:
	if biome != 0:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 12
	var segs := 28
	var center := Vector3(POND.x, height_at(POND.x, POND.z) + 0.05, POND.z)
	var ringpts: Array = []
	for ri in range(1, rings + 1):
		var rr := POND_R * 1.04 * float(ri) / rings
		var row: Array = []
		for si in range(segs):
			var a := TAU * float(si) / segs
			var x := POND.x + cos(a) * rr
			var z := POND.z + sin(a) * rr
			row.append(Vector3(x, height_at(x, z) + 0.05, z))
		ringpts.append(row)
	var first: Array = ringpts[0]
	for si in range(segs):
		var n := (si + 1) % segs
		st.add_vertex(center); st.add_vertex(first[n]); st.add_vertex(first[si])
	for ri in range(1, rings):
		var a0: Array = ringpts[ri - 1]
		var a1: Array = ringpts[ri]
		for si in range(segs):
			var n := (si + 1) % segs
			st.add_vertex(a0[si]); st.add_vertex(a0[n]); st.add_vertex(a1[n])
			st.add_vertex(a0[si]); st.add_vertex(a1[n]); st.add_vertex(a1[si])
	st.generate_normals()
	var bed := MeshInstance3D.new()
	bed.name = "PondBed"
	bed.mesh = st.commit()
	var sand := MeshFactory.mat_standard(Color(0.82, 0.75, 0.56), 0.92)
	sand.cull_mode = BaseMaterial3D.CULL_DISABLED   # lit from above through water
	bed.material_override = sand
	parent.add_child(bed)

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
# Every scatter category is now drawn as MultiMeshInstance3D(s) — one GPU batch
# per source mesh instead of one Node3D + draw call per prop. This both collapses
# draw-call overhead (the headline optimization) and lets density climb into the
# thousands for a genuinely lush floor at a fraction of the old cost.

## Giant Washington-state pines — hand-sculpted ~20 m conifers that tower over
## the canopy and ring the clearing (avoid_clearing keeps the centre open, so
## they frame the bowl as a wall of giants). Culled far out since they read as
## landmarks. A tall trunk collider stops the player walking through them.
func _scatter_giant_pines(parent: Node3D) -> void:
	if _giant_pine_scenes.is_empty():
		return
	var biome_mult := 0.55 if biome == 1 else 1.0
	# The realistic card pines (~53k tris, alpha-MASK foliage) are heavier than the
	# old flat cones, so a trimmed count + the GLB's generated LODs keep the dense
	# treeline affordable.
	var count := int(46 * density * biome_mult)
	_scatter_mm(parent, _giant_pine_scenes, count, 0.85, 1.5, {
		"avoid_clearing": true, "avoid_path": true, "avoid_pond": true,
		"cull": CULL_TREE * 1.9, "cell_size": 14.0,
		# Distant landmark silhouettes — skip the shadow pass (huge mesh × many).
		"cast_shadow": GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"col_radius": 0.7, "col_height": 16.0, "y_offset": -0.2,
		"ring_min": 15.0, "ring_max": 26.0,
	})

func _scatter_trees(parent: Node3D) -> void:
	if _tree_scenes.is_empty():
		_scatter_trees_primitive(parent)
		return
	var biome_mult := 0.7 if biome == 1 else 1.0
	var count := int(100 * density * biome_mult)
	_scatter_mm(parent, _tree_scenes, count, 0.85, 1.3, {
		"avoid_clearing": true, "avoid_path": true, "cull": CULL_TREE,
		"col_radius": 0.45, "col_height": 9.0,
		"sapling_scenes": _smalltree_scenes, "sapling_chance": 0.22,
		"sapling_col_radius": 0.3, "sapling_col_height": 4.0,
	})

## A dense, cheap understory of small trees/shrubs (tree_small_02 ~3k verts)
## fills the gaps between the heavy hero firs so the forest reads full, not bare.
func _scatter_understory(parent: Node3D) -> void:
	var path := "res://assets/models/tree_small_02.glb"
	if not ResourceLoader.exists(path):
		return
	var biome_mult := 0.7 if biome == 1 else 1.0
	var count := int(80 * density * biome_mult)
	_scatter_mm(parent, [load(path)], count, 0.6, 1.5, {
		"avoid_clearing": true, "avoid_path": true, "cull": CULL_SMALLTREE,
		"col_radius": 0.3, "col_height": 2.0,
	})

## A scatter of fallen mossy logs — forest-floor detail you can be blocked by.
func _build_logs(parent: Node3D) -> void:
	var count := int(11 * density)
	var body := StaticBody3D.new()
	body.name = "LogCollision"
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 8:
		attempts += 1
		var p := _random_point()
		if _in_clearing(p) or _on_path(p):
			continue
		var gy := height_at(p.x, p.z)
		if gy < WATER_LEVEL + 0.2:
			continue
		var length := rng.randf_range(2.6, 5.2)
		var radius := rng.randf_range(0.22, 0.4)
		# Lay the cylinder (default Y-axis) horizontal: rotate 90° about Z, then yaw.
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3(0, 0, 1), PI * 0.5)
		var xf := Transform3D(basis, Vector3(p.x, gy + radius * 0.55, p.z))
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = radius * 0.82
		cm.bottom_radius = radius
		cm.height = length
		cm.radial_segments = 8
		mi.mesh = cm
		mi.material_override = _bark
		mi.transform = xf
		parent.add_child(mi)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(radius * 1.7, length, radius * 1.7)
		cs.shape = box
		cs.transform = xf
		body.add_child(cs)
		placed += 1
	parent.add_child(body)

func _scatter_rocks(parent: Node3D) -> void:
	if _rock_scenes.is_empty():
		return
	var count := int(48 * density)
	# Boulders block the player with an accurate convex hull of their actual mesh
	# (a fixed cylinder let the player walk through the wide photoscan rocks).
	_scatter_mm(parent, _rock_scenes, count, 0.7, 2.0, {
		"avoid_path": true, "cull": CULL_ROCK,
		"convex_collision": true, "y_offset": -0.1,
	})

func _scatter_grass_carpet(parent: Node3D) -> void:
	if _grass_scene == null:
		return
	# Thousands of lightweight grass cards in one MultiMesh, wind-swayed via a
	# dedicated alpha-tested shader that reads each instance's world origin. The
	# card mesh (~18 verts) keeps the carpet cheap where the 7k-vert photoscan
	# clump would not (see make_grass_card_mesh).
	var mat := MeshFactory.mat_grass_card(_grass_scene, biome)
	if mat == null:
		return
	var count := int(8000 * density)
	_scatter_mm(parent, [_grass_scene], count, 0.7, 1.7, {
		"cull": CULL_GROUND * 1.4, "y_offset": -0.04, "cell_size": 8.0,
		"mesh": MeshFactory.make_grass_card_mesh(),
		"material_override": mat,
		"vary_color": true,
		"cast_shadow": GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	})

## Hand-sculpted 3D grass clumps (folded blades) scattered close to the player
## as a richer foreground layer over the cheap distant card carpet. Short cull
## keeps the heavier geometry only where it's seen up close.
func _scatter_grass_tufts(parent: Node3D) -> void:
	var path := "res://assets/models/grass_tuft_01.glb"
	if not ResourceLoader.exists(path):
		return
	var count := int(800 * density)
	_scatter_mm(parent, [load(path)], count, 0.7, 1.6, {
		"cull": CULL_GROUND, "y_offset": -0.03,
		"cast_shadow": GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	})

func _scatter_foliage(parent: Node3D) -> void:
	if _grass_scene == null and _tree_scenes.is_empty():
		_scatter_foliage_primitive(parent)
		return
	var biome_mult := 0.85 if biome == 1 else 1.0
	for entry in GROUND_COVER:
		var slug: String = entry[0]
		var path := "res://assets/models/%s.glb" % slug
		if not ResourceLoader.exists(path):
			continue
		var scene: PackedScene = load(path)
		var count := int(entry[1] * density * biome_mult)
		_scatter_mm(parent, [scene], count, entry[2], entry[3], {
			"cull": CULL_GROUND, "y_offset": entry[4],
			"cast_shadow": GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		})

# ----------------------------------------------------- MultiMesh scatter engine
## Scatter `count` copies of one or more source GLBs as MultiMeshInstance3D(s)
## (one per distinct source mesh). Honours clearing/path avoidance, terrain
## drop, optional cylinder collision, distance culling and a material override.
func _scatter_mm(parent: Node3D, scenes: Array, count: int, smin: float, smax: float,
		opts := {}) -> void:
	if scenes.is_empty():
		return
	var avoid_clearing: bool = opts.get("avoid_clearing", false)
	var avoid_path: bool = opts.get("avoid_path", false)
	var y_off: float = opts.get("y_offset", -0.05)
	var col_r: float = opts.get("col_radius", 0.0)
	var col_h: float = opts.get("col_height", 0.0)
	var saplings: Array = opts.get("sapling_scenes", [])
	var sap_chance: float = opts.get("sapling_chance", 0.0)
	# Optional annulus placement: scatter in a ring [ring_min, ring_max] from the
	# centre instead of the whole square — used to ring the world with giants.
	var ring_min: float = opts.get("ring_min", 0.0)
	var ring_max: float = opts.get("ring_max", AREA - 1.0)
	# Spatial chunking: bucket placements into a grid of cells so each cell becomes
	# its own MultiMeshInstance and frustum-culls independently (turning away from
	# a cell stops paying for it). cell -> {scene -> Array[Transform3D]}.
	var cell_size: float = opts.get("cell_size", 12.0)
	var buckets := {}                # PackedScene -> { Vector2i cell -> Array[Transform3D] }
	var all_by_scn := {}             # PackedScene -> Array[Transform3D] (for collision)
	var cols: Array = []             # [pos, radius, height] cylinders
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 6:
		attempts += 1
		var p: Vector3
		if ring_min > 0.0:
			var ang := rng.randf_range(0.0, TAU)
			# sqrt keeps the distribution area-uniform across the annulus
			var rr := sqrt(rng.randf_range(ring_min * ring_min, ring_max * ring_max))
			p = Vector3(cos(ang) * rr, 0.0, sin(ang) * rr)
		else:
			p = _random_point()
		if avoid_clearing and _in_clearing(p):
			continue
		if avoid_path and _on_path(p):
			continue
		if opts.get("avoid_pond", false) and Vector2(p.x - POND.x, p.z - POND.z).length() < POND_R + 4.0:
			continue
		# Trees/rocks (which set avoid_path) also stay clear of the spawn so the
		# player never wakes up wedged inside a boulder/trunk at high density.
		if avoid_path and Vector2(p.x - SPAWN.x, p.z - SPAWN.z).length() < SPAWN_CLEAR:
			continue
		# Nothing grows underwater; edge plants just above the line read as reeds.
		if height_at(p.x, p.z) < WATER_LEVEL + 0.1:
			continue
		# Keep the overlook a clean vantage (no grass/trees blocking the vista).
		if Vector2(p.x - RIDGE.x, p.z - RIDGE.z).length() < 5.5:
			continue
		p.y = height_at(p.x, p.z) + y_off
		var scn: PackedScene = _pick(scenes)
		var cr := col_r
		var ch := col_h
		if sap_chance > 0.0 and not saplings.is_empty() and rng.randf() < sap_chance:
			scn = _pick(saplings)
			cr = opts.get("sapling_col_radius", col_r)
			ch = opts.get("sapling_col_height", col_h)
		var yaw := rng.randf_range(0.0, TAU)
		var s := rng.randf_range(smin, smax)
		var xf := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), p)
		var cell := Vector2i(int(floor((p.x + AREA) / cell_size)), int(floor((p.z + AREA) / cell_size)))
		if not buckets.has(scn):
			buckets[scn] = {}
			all_by_scn[scn] = []
		if not buckets[scn].has(cell):
			buckets[scn][cell] = []
		buckets[scn][cell].append(xf)
		all_by_scn[scn].append(xf)
		if cr > 0.0:
			cols.append([p, cr * s, ch * s])
		placed += 1
	for scn in buckets:
		for cell in buckets[scn]:
			_build_mm(parent, scn, buckets[scn][cell], opts)
		if opts.get("convex_collision", false):
			_build_convex_collision(parent, scn, all_by_scn[scn])
	if not cols.is_empty():
		_build_collision(parent, cols)

func _build_mm(parent: Node3D, scene: PackedScene, placements: Array, opts: Dictionary) -> void:
	var local := Transform3D.IDENTITY
	var mesh = opts.get("mesh", null)   # explicit mesh (e.g. cheap grass card) wins
	if mesh == null:
		var data := _extract(scene)
		if data.is_empty():
			return
		mesh = data["mesh"]
		local = data["xform"]
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var vary: bool = opts.get("vary_color", false)
	mm.use_colors = vary
	mm.mesh = mesh
	mm.instance_count = placements.size()
	for i in placements.size():
		mm.set_instance_transform(i, (placements[i] as Transform3D) * local)
		if vary:
			# Natural per-clump variation: greener-to-yellow, brighter-to-darker.
			var v := rng.randf_range(0.68, 1.12)
			mm.set_instance_color(i, Color(v * rng.randf_range(0.82, 1.0), v, v * rng.randf_range(0.74, 0.92)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = opts.get("cast_shadow", GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	var ov = opts.get("material_override", null)
	if ov:
		mmi.material_override = ov
	var cull: float = opts.get("cull", 0.0)
	if cull > 0.0:
		var d := cull * cull_mult
		mmi.visibility_range_end = d
		mmi.visibility_range_end_margin = d * 0.15
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(mmi)

## Lightweight shared collision body holding one cylinder per heavy prop.
func _build_collision(parent: Node3D, cols: Array) -> void:
	var body := StaticBody3D.new()
	body.name = "ScatterCollision"
	for entry in cols:
		var p: Vector3 = entry[0]
		var cs := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = entry[1]
		shape.height = entry[2]
		cs.shape = shape
		cs.position = Vector3(p.x, p.y + entry[2] * 0.5, p.z)
		body.add_child(cs)
	parent.add_child(body)

## Accurate per-instance collision from each prop's actual mesh (a simplified
## convex hull, cached per source scene). Used for boulders so the player can't
## walk through them. The hull is in mesh-local space, so each instance's shape
## transform is placement * the GLB's local transform.
var _convex_cache := {}

func _build_convex_collision(parent: Node3D, scene: PackedScene, placements: Array) -> void:
	if not _convex_cache.has(scene):
		var d := _extract(scene)
		_convex_cache[scene] = d["mesh"].create_convex_shape(true, true) if not d.is_empty() else null
	var shape = _convex_cache[scene]
	if shape == null:
		return
	var local: Transform3D = _extract(scene)["xform"]
	var body := StaticBody3D.new()
	body.name = "RockCollision"
	for xf in placements:
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.transform = (xf as Transform3D) * local
		body.add_child(cs)
	parent.add_child(body)

## Extract the first MeshInstance3D's mesh + its transform-relative-to-root from
## a GLB, cached so each model is instanced/walked only once.
func _extract(scene: PackedScene) -> Dictionary:
	if _mm_cache.has(scene):
		return _mm_cache[scene]
	var inst := scene.instantiate()
	var mi := _find_mesh(inst)
	var data := {}
	if mi and mi.mesh:
		# Force alpha-BLEND foliage (PolyHaven twigs/leaves/grass) to alpha-SCISSOR:
		# scissor writes depth in the prepass, gets early-Z, sorts for free and casts
		# crisp opaque shadows — a big fill/overdraw win on the most-instanced meshes.
		var mesh: Mesh = mi.mesh
		for si in mesh.get_surface_count():
			var sm := mesh.surface_get_material(si)
			if sm is BaseMaterial3D and (sm as BaseMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
				(sm as BaseMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				(sm as BaseMaterial3D).alpha_scissor_threshold = 0.5
		data = {"mesh": mesh, "xform": _local_xform(mi, inst)}
	inst.free()
	_mm_cache[scene] = data
	return data

func _find_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _find_mesh(c)
		if r:
			return r
	return null

func _local_xform(mi: Node3D, root: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = mi
	while n != null and n != root:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf

# ----------------------------------------------------- primitive fallbacks
# Used only when the GLB set is absent (keeps the prototype runnable bare).
func _scatter_trees_primitive(parent: Node3D) -> void:
	var count := int(140 * density)
	for i in count:
		var p := _random_point()
		if _in_clearing(p) or _on_path(p):
			continue
		p.y = height_at(p.x, p.z)
		var tree := MeshFactory.make_tree(rng, _bark, _pick(_leaf_variants))
		tree.position = p
		parent.add_child(tree)

func _scatter_foliage_primitive(parent: Node3D) -> void:
	for i in int(90 * density):
		var p := _random_point()
		if _on_path(p):
			continue
		p.y = height_at(p.x, p.z)
		var b := MeshFactory.make_bush(rng, _pick(_bush_variants))
		b.position = p
		parent.add_child(b)
	for i in int(220 * density):
		var p := _random_point()
		p.y = height_at(p.x, p.z)
		var g := MeshFactory.make_grass_tuft(rng, _pick(_grass_variants))
		g.position = p
		parent.add_child(g)

# A single hidden "wrong tree" in the forest ring — struck with the Rootblade it
## dissolves into Essence + a truth (the S2 secret from the design map).
func _build_wrong_tree(parent: Node3D) -> void:
	var wt := WrongTree.new()
	var p := Vector3(-16.0, 0.0, -9.0)
	wt.position = Vector3(p.x, height_at(p.x, p.z), p.z)
	parent.add_child(wt)

## Soft god-ray shafts angled like the sun through the canopy, around the
## clearing rim. Quietwood only (the Loomstrata runs cool/void).
func _build_light_shafts(parent: Node3D) -> void:
	if biome != 0:
		return
	var sh := load("res://shaders/light_shaft.gdshader") as Shader
	if sh == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = sh
	# A few subtle shafts, all sharing the sun's azimuth so they read as real
	# crepuscular rays rather than a chaotic fan. The volumetric fog does the rest.
	var sun_yaw := deg_to_rad(40.0)
	for i in 4:
		var ang := TAU * i / 4.0 + rng.randf_range(-0.2, 0.2)
		var r := CLEARING_RADIUS * rng.randf_range(0.45, 0.95)
		var x := cos(ang) * r
		var z := sin(ang) * r
		var quad := MeshInstance3D.new()
		var qm := QuadMesh.new()
		var hgt := rng.randf_range(11.0, 14.0)
		qm.size = Vector2(rng.randf_range(1.8, 2.8), hgt)
		quad.mesh = qm
		quad.material_override = mat
		quad.position = Vector3(x, height_at(x, z) + hgt * 0.42, z)
		# Consistent sun-aligned lean (dir light pitches ~-38°), small yaw jitter.
		quad.rotation = Vector3(deg_to_rad(rng.randf_range(-26.0, -20.0)),
				sun_yaw + rng.randf_range(-0.3, 0.3), 0.0)
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(quad)

## Stillwater Lilies floating on the pond — pick them up to purge Desync.
func _build_lilies(parent: Node3D) -> void:
	if biome != 0:
		return
	var spots := [Vector3(-10.5, 0, 8.0), Vector3(-13.0, 0, 10.0), Vector3(-9.5, 0, 11.0)]
	for s in spots:
		var lily := Lily.new()
		lily.position = Vector3(s.x, WATER_LEVEL + 0.04, s.z)
		parent.add_child(lily)

## The Cairn-Ridge overlook: a flat stone at the mound's peak and — in the
## Quietwood — a distant glowing RIFT (a huge wireframe seam + monolith
## silhouettes) beyond the boundary that previews the Loomstrata below. The
## Forest controller fires Auralis's vista line when the player reaches it.
func _build_overlook(parent: Node3D) -> void:
	var top := Vector3(RIDGE.x, height_at(RIDGE.x, RIDGE.z), RIDGE.z)
	var slab := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4.5, 0.5, 4.5)
	slab.mesh = bm
	slab.material_override = _rock
	slab.position = top + Vector3(0, 0.15, 0)
	parent.add_child(slab)
	var body := StaticBody3D.new()
	body.name = "OverlookCollision"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = bm.size
	cs.shape = box
	cs.position = slab.position
	body.add_child(cs)
	parent.add_child(body)
	if biome != 0:
		return
	# A DISTANT, fog-shrouded glimpse of the layer below — far beyond the western
	# treeline and set low, so from the overlook it reads as a faint rift on the
	# horizon, not a wall. Dialogue does the rest.
	var rift_c := Vector3(-78.0, -16.0, -1.0)
	var grid_sh := load("res://shaders/seam_grid.gdshader") as Shader
	var seam := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(26.0, 15.0)
	seam.mesh = qm
	if grid_sh:
		var sm := ShaderMaterial.new()
		sm.shader = grid_sh
		sm.set_shader_parameter("grid_color", Vector3(0.40, 0.62, 0.95))
		sm.set_shader_parameter("cells", 12.0)
		sm.set_shader_parameter("intensity", 1.5)
		seam.material_override = sm
	else:
		seam.material_override = MeshFactory.mat_emissive(Color(0.4, 0.62, 0.95), 1.4, true)
	seam.position = rift_c + Vector3(0, 9.0, 0)
	seam.rotation.y = deg_to_rad(90.0)
	parent.add_child(seam)
	# Dark monolith silhouettes rising from the rift (faintly lit, ominous).
	var mono_mat := MeshFactory.mat_emissive(Color(0.16, 0.22, 0.42), 0.35)
	for i in 7:
		var mono := MeshInstance3D.new()
		var mb := BoxMesh.new()
		var mh := rng.randf_range(7.0, 16.0)
		mb.size = Vector3(rng.randf_range(2.0, 4.5), mh, rng.randf_range(2.0, 4.5))
		mono.mesh = mb
		mono.material_override = mono_mat
		mono.position = rift_c + Vector3(rng.randf_range(-12.0, 8.0), mh * 0.5 - 2.0, rng.randf_range(-14.0, 14.0))
		parent.add_child(mono)

# ------------------------------------------------------------ Loomstrata seams
## The machinery showing through nature: floating glowing wireframe seams and
## raw untextured grey blockout monoliths along the rim — "the simulation drops
## its textures." Only built in the Loomstrata (biome 1).
func _build_seams(parent: Node3D) -> void:
	var grid_sh := load("res://shaders/seam_grid.gdshader") as Shader
	# Floating grid seams.
	for i in 26:
		var p := _random_point()
		if _in_clearing(p):
			continue
		var quad := MeshInstance3D.new()
		var qm := QuadMesh.new()
		var sz := rng.randf_range(1.6, 4.2)
		qm.size = Vector2(sz, sz)
		quad.mesh = qm
		if grid_sh:
			var sm := ShaderMaterial.new()
			sm.shader = grid_sh
			sm.set_shader_parameter("grid_color", Vector3(0.4, 0.7, 1.0) if rng.randf() < 0.6 else Vector3(0.7, 0.45, 1.0))
			sm.set_shader_parameter("cells", rng.randf_range(3.0, 7.0))
			quad.material_override = sm
		else:
			quad.material_override = MeshFactory.mat_emissive(Color(0.4, 0.7, 1.0), 2.0, true)
		quad.position = Vector3(p.x, height_at(p.x, p.z) + rng.randf_range(0.4, 4.0), p.z)
		quad.rotation = Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(0.0, TAU), rng.randf_range(-0.6, 0.6))
		parent.add_child(quad)
	# Ancient runed standing-stones (hand-sculpted menhirs, glowing sigil + mossy
	# crown), half-sunk and tilted — replacing the old grey blockout boxes.
	var mono_path := "res://assets/models/rune_monolith_01.glb"
	var mono_scene: PackedScene = load(mono_path) if ResourceLoader.exists(mono_path) else null
	var grey := MeshFactory.mat_standard(Color(0.32, 0.33, 0.38), 0.95)
	var body := StaticBody3D.new()
	body.name = "MonolithCollision"
	for i in 14:
		var p := _random_point()
		if _in_clearing(p) or _on_path(p):
			continue
		var gy := height_at(p.x, p.z)
		var s := rng.randf_range(0.8, 1.7)
		# Turn the runed face (-Z in Godot) toward the clearing centre, with a
		# little jitter and a slight lean, so the sigils watch inward.
		var face := atan2(p.x, p.z) + rng.randf_range(-0.4, 0.4)
		var rot := Basis.from_euler(Vector3(rng.randf_range(-0.1, 0.1),
				face, rng.randf_range(-0.1, 0.1)))
		var pos := Vector3(p.x, gy - 0.18 * s, p.z)   # plant the base into the ground
		if mono_scene:
			var mono := mono_scene.instantiate()
			mono.transform = Transform3D(rot.scaled(Vector3(s, s, s)), pos)
			parent.add_child(mono)
		else:
			var mb := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(1.15, 3.6, 0.62) * s
			mb.mesh = bm
			mb.material_override = grey
			mb.transform = Transform3D(rot, pos + rot.y * (1.8 * s))
			parent.add_child(mb)
		# Collision: a box hull of the slab (≈1.15 × 3.6 × 0.62 at scale 1).
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.15, 3.6, 0.62) * s
		cs.shape = box
		cs.transform = Transform3D(rot, pos + rot.y * (1.8 * s))
		body.add_child(cs)
	parent.add_child(body)

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
