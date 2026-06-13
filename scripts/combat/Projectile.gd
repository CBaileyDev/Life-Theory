class_name MagicPulse
extends Area3D
## Magic pulse projectile (Simulation Pulse upgrade).
## A glowing orb that flies forward, damages the first Corrupted Wisp it
## touches, and despawns. Built fully in code; no scene file required.

const SPEED := 22.0
const LIFETIME := 2.5
const DAMAGE := 45.0

var _dir := Vector3.FORWARD
var _life := LIFETIME
var _source: Node = null

func launch(origin: Vector3, dir: Vector3, source: Node) -> void:
	global_position = origin
	_dir = dir.normalized()
	_source = source

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	mesh.mesh = sm
	mesh.material_override = MeshFactory.mat_emissive(Color(0.5, 0.9, 1.0), 4.0)
	add_child(mesh)

	var glow := OmniLight3D.new()
	glow.light_color = Color(0.5, 0.9, 1.0)
	glow.light_energy = 2.5
	glow.omni_range = 4.0
	add_child(glow)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	global_position += _dir * SPEED * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_hit(other) -> void:
	if other == _source:
		return
	if other.is_in_group("enemy") and other.has_method("take_damage"):
		other.take_damage(DAMAGE, _source)
		queue_free()
	elif other is StaticBody3D:
		queue_free()
