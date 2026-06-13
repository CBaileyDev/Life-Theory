class_name Auralis
extends StaticBody3D
## Auralis — the forest guide
## A luminous deer-like spirit of light, mist, and geometric simulation
## patterns. Hidden in the natural forest; fades into being after the
## transformation. Floats gently and offers short, atmospheric dialogue that
## advances the quest the first time the player speaks to it.

var _body_root: Node3D
var _spin := 0.0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("guide")
	_build()
	GameState.world_state_changed.connect(_on_world_changed)
	_set_visible_state(GameState.world == GameState.World.FIRST_LAYER)

func _build() -> void:
	_body_root = Node3D.new()
	add_child(_body_root)
	var mat := MeshFactory.mat_emissive(Color(0.5, 0.9, 1.0, 0.85), 2.8, true)

	# Torso
	_add_part(BoxMesh.new(), mat, Vector3(0.5, 0.5, 1.3), Vector3(0, 1.3, 0))
	# Neck
	_add_part(BoxMesh.new(), mat, Vector3(0.3, 0.7, 0.3), Vector3(0, 1.75, -0.65), Vector3(deg_to_rad(-35), 0, 0))
	# Head
	_add_part(BoxMesh.new(), mat, Vector3(0.3, 0.3, 0.5), Vector3(0, 2.1, -0.95))
	# Legs
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_add_part(BoxMesh.new(), mat, Vector3(0.12, 0.9, 0.12),
				Vector3(sx * 0.18, 0.55, sz * 0.5))
	# Antlers (geometric, branching)
	for sx in [-1, 1]:
		_add_part(BoxMesh.new(), mat, Vector3(0.06, 0.5, 0.06),
			Vector3(sx * 0.12, 2.4, -0.95), Vector3(0, 0, deg_to_rad(sx * 20)))
		_add_part(BoxMesh.new(), mat, Vector3(0.06, 0.25, 0.06),
			Vector3(sx * 0.28, 2.6, -0.95), Vector3(0, 0, deg_to_rad(sx * 45)))

	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.9, 1.0)
	light.light_energy = 2.5
	light.omni_range = 8.0
	light.position.y = 1.6
	_body_root.add_child(light)

	# Drifting motes of light.
	var aura := MeshFactory.make_aura(Color(0.55, 0.92, 1.0), 30, 0.5, 1.0, 0.08)
	aura.position.y = 1.2
	_body_root.add_child(aura)

	# Interaction collision.
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.4, 2.6, 2.0)
	col.shape = shape
	col.position.y = 1.3
	add_child(col)

func _add_part(mesh: Mesh, mat: Material, size: Vector3, pos: Vector3, rot := Vector3.ZERO) -> void:
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	_body_root.add_child(mi)

func _process(delta: float) -> void:
	_spin += delta
	_body_root.position.y = sin(_spin * 1.2) * 0.12
	_body_root.rotation.y = sin(_spin * 0.4) * 0.25

func _set_visible_state(active: bool) -> void:
	visible = active
	set_process(active)
	# Disable interaction collision when hidden.
	for c in get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = not active

func _on_world_changed(state: int) -> void:
	var appearing := state == GameState.World.FIRST_LAYER and not visible
	_set_visible_state(state == GameState.World.FIRST_LAYER)
	if appearing:
		AudioManager.play("guide_appear")

func get_prompt() -> String:
	if GameState.world != GameState.World.FIRST_LAYER:
		return ""
	return "[E]  Speak with Auralis"

func interact(_player: Node) -> void:
	var lines: Array
	if not GameState.guide_met:
		lines = Content.AURALIS_FIRST
	elif GameState.quest_complete:
		lines = Content.AURALIS_DONE
	else:
		# Hint scales with how many fragments remain.
		lines = Content.AURALIS_HINTS[clampi(GameState.fragments, 0, 2)]
	GameState.request_dialogue("Auralis", lines)
	GameState.meet_guide()
