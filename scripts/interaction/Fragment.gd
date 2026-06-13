class_name Fragment
extends Area3D
## Fragment of Truth
## A floating, rotating shard of simulation-light. Hidden in the natural
## forest; becomes visible and collectible once the world shifts to the First
## Layer. Collected by walking into it (proximity), with a small pickup burst.

@export var collected := false

var _visual: Node3D
var _spin := 0.0

func _ready() -> void:
	add_to_group("fragment")
	_build()
	body_entered.connect(_on_body_entered)
	GameState.world_state_changed.connect(_on_world_changed)
	_set_active(GameState.world == GameState.World.FIRST_LAYER and not collected)

func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var shard := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.35, 0.7, 0.35)
	shard.mesh = pm
	shard.material_override = MeshFactory.mat_emissive(Color(1.0, 0.82, 0.4), 3.5)
	_visual.add_child(shard)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.45)
	light.light_energy = 2.0
	light.omni_range = 4.0
	_visual.add_child(light)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	col.shape = shape
	add_child(col)

func _process(delta: float) -> void:
	if not visible:
		return
	_spin += delta
	_visual.rotation.y = _spin * 1.5
	_visual.position.y = 1.0 + sin(_spin * 2.0) * 0.15

func _set_active(active: bool) -> void:
	visible = active
	monitoring = active
	set_process(active)

func _on_world_changed(state: int) -> void:
	_set_active(state == GameState.World.FIRST_LAYER and not collected)

func _on_body_entered(body: Node) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	_set_active(false)
	GameState.collect_fragment()
	GameState.toast.emit("Fragment of Truth recovered  (%d/%d)" %
		[GameState.fragments, GameState.FRAGMENT_TOTAL])
