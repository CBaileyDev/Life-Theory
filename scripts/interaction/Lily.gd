class_name Lily
extends Area3D
## Stillwater Lily — a quiet-places reward for the Sight economy. Found floating
## on the pond; walking into one restores Lucidity and purges Desync (the
## counterweight to over-using the Sight). No inventory/input needed.

var _used := false
var _t := 0.0
var _visual: Node3D

func _ready() -> void:
	add_to_group("lily")
	_build()
	body_entered.connect(_on_body)

func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.32
	cm.bottom_radius = 0.32
	cm.height = 0.04
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = MeshFactory.mat_emissive(Color(0.9, 0.96, 1.0), 2.2, true)
	_visual.add_child(mi)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.8, 0.9, 1.0)
	glow.light_energy = 1.1
	glow.omni_range = 3.2
	_visual.add_child(glow)
	var col := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.1
	col.shape = sh
	add_child(col)

func _process(delta: float) -> void:
	if _visual:
		_t += delta
		_visual.position.y = sin(_t * 1.5) * 0.04   # gentle bob on the water

func _on_body(b: Node) -> void:
	if _used or not b.is_in_group("player"):
		return
	_used = true
	GameState.add_lucidity(35.0)
	GameState.add_desync(-45.0)
	AudioManager.play("fragment_pickup", -3.0, 1.3)
	GameState.toast.emit("A Stillwater Lily dissolves. The fraying eases.")
	var sp := MeshFactory.spark(Color(0.8, 0.95, 1.0), 16, 3.0, 0.1)
	get_tree().current_scene.add_child(sp)
	sp.global_position = global_position
	queue_free()
