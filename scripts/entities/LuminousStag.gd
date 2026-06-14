class_name LuminousStag
extends CharacterBody3D
## Luminous Stag — passive ambient creature
## Watches the player from a distance and flees if approached. Adds life to
## the First Layer without combat. Optional creature from the brief.

const FLEE_RANGE := 8.0
const FLEE_SPEED := 6.0
const WANDER_SPEED := 1.5

var _home := Vector3.ZERO
var _body_root: Node3D
var _wander_target := Vector3.ZERO
var _wander_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	add_to_group("wildlife")
	_home = global_position
	_wander_target = _home
	_build()
	GameState.world_state_changed.connect(_on_world_changed)
	_set_active(GameState.world == GameState.World.FIRST_LAYER)

# Generated mesh is normalised to ~2.0 units tall, centred on origin. Scale to a
# ~2.2 m elk and lift so the feet rest at the body origin (matching the capsule).
# Tune STAG_SCALE if the stag reads too large/small in-engine.
const STAG_SCALE := 1.1

func _build() -> void:
	_body_root = Node3D.new()
	add_child(_body_root)
	# Prefer the generated mystical Luminous Stag (baked violet-blue emissive);
	# fall back to the primitive blockout if the asset is missing.
	var model_path := "res://assets/models/stag_spirit_glow.glb"
	if ResourceLoader.exists(model_path):
		var model := (load(model_path) as PackedScene).instantiate() as Node3D
		model.scale = Vector3.ONE * STAG_SCALE
		model.position.y = STAG_SCALE   # feet (local -1 * scale) up to the origin
		_body_root.add_child(model)
	else:
		_build_primitive_body()
	var light := OmniLight3D.new()
	light.light_color = Color(0.62, 0.78, 1.0)   # violet-blue First-Layer glow
	light.light_energy = 1.6
	light.omni_range = 5.5
	light.position.y = 1.4
	_body_root.add_child(light)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 2.0
	col.shape = shape
	col.position.y = 1.0
	add_child(col)

## Primitive blockout fallback (used only if the GLB is unavailable).
func _build_primitive_body() -> void:
	var mat := MeshFactory.mat_emissive(Color(0.7, 1.0, 0.7, 0.9), 2.0, true)
	_part(mat, Vector3(0.5, 0.5, 1.2), Vector3(0, 1.2, 0))          # torso
	_part(mat, Vector3(0.3, 0.6, 0.3), Vector3(0, 1.6, -0.6), Vector3(deg_to_rad(-30), 0, 0))  # neck
	_part(mat, Vector3(0.28, 0.28, 0.45), Vector3(0, 1.95, -0.85))  # head
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_part(mat, Vector3(0.1, 0.85, 0.1), Vector3(sx * 0.18, 0.52, sz * 0.45))

func _part(mat: Material, size: Vector3, pos: Vector3, rot := Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	_body_root.add_child(mi)

func _set_active(active: bool) -> void:
	visible = active
	set_physics_process(active)
	for c in get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = not active

func _on_world_changed(s: int) -> void:
	_set_active(s == GameState.World.FIRST_LAYER)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var player := _get_player()
	var horiz := Vector3.ZERO
	if player and global_position.distance_to(player.global_position) < FLEE_RANGE:
		var away := global_position - player.global_position
		away.y = 0
		horiz = away.normalized() * FLEE_SPEED
		_face(global_position + horiz)
	else:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(3.0, 6.0)
			var a := randf() * TAU
			_wander_target = _home + Vector3(cos(a), 0, sin(a)) * randf_range(2.0, 7.0)
		var to := _wander_target - global_position
		to.y = 0
		if to.length() > 0.5:
			horiz = to.normalized() * WANDER_SPEED
			_face(_wander_target)
	velocity.x = horiz.x
	velocity.z = horiz.z
	move_and_slide()

func _face(target: Vector3) -> void:
	var flat := Vector3(target.x, global_position.y, target.z)
	if flat.distance_to(global_position) > 0.01:
		look_at(flat, Vector3.UP)

func _get_player() -> Node3D:
	var n := get_tree().get_nodes_in_group("player")
	return n[0] if n.size() > 0 else null
