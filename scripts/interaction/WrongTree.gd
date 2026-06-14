class_name WrongTree
extends StaticBody3D
## WrongTree — a secret. It looks like an ordinary small tree, but it is the
## world dressed in bark. Struck with the Rootblade (or a Pulse) it dissolves
## into Forest Essence and a truth, rewarding the "strike a tree that is too
## still" lore. In the "enemy" group so Player._attack / the Pulse hit it via
## take_damage(); it never moves and never attacks, so the combat-music poller
## (which checks `is CorruptedWisp`) ignores it.

var _hp := 55.0
var _dissolved := false
var _visual: Node3D

func _ready() -> void:
	add_to_group("enemy")
	_build()

func _build() -> void:
	var path := "res://assets/models/tree_small_02.glb"
	if ResourceLoader.exists(path):
		_visual = (load(path) as PackedScene).instantiate()
		var s := 1.1
		_visual.scale = Vector3(s, s, s)
		add_child(_visual)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 4.0
	col.shape = shape
	col.position.y = 2.0
	add_child(col)

func take_damage(amount: float, _source) -> void:
	if _dissolved:
		return
	_hp -= amount
	AudioManager.play("wisp_damage", -5.0, 0.8)
	if _visual:
		# A shudder — the lie flinching.
		var t := create_tween()
		t.tween_property(_visual, "rotation:z", deg_to_rad(4.0), 0.05)
		t.tween_property(_visual, "rotation:z", 0.0, 0.18)
	if _hp <= 0.0:
		_dissolve()

func _dissolve() -> void:
	_dissolved = true
	var sp := MeshFactory.spark(Color(0.6, 0.95, 1.0), 40, 6.0, 0.2)
	get_tree().current_scene.add_child(sp)
	sp.global_position = global_position + Vector3(0, 1.5, 0)
	GameState.forest_essence += 25
	GameState.toast.emit("The tree was never a tree.  +25 Forest Essence")
	GameState.request_dialogue("Auralis", Content.WRONG_TREE)
	AudioManager.play("mushroom_transform", -8.0)
	if _visual:
		var t := create_tween()
		t.tween_property(_visual, "scale", Vector3(0.01, 1.4, 0.01), 0.4).set_trans(Tween.TRANS_BACK)
		t.tween_callback(queue_free)
	else:
		queue_free()
