class_name MushroomShrine
extends StaticBody3D
## MushroomShrine
## The ancient shrine + glowing mushroom at the heart of the clearing.
## First interaction activates the mushroom (triggering the transformation
## into the First Layer). Later, it is the return point where the player
## communes to choose an upgrade. Interaction is detected by the player's ray
## (group "interactable").

var _cap: MeshInstance3D
var _light: OmniLight3D
var _cap_mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("interactable")
	_build()
	GameState.world_state_changed.connect(_on_world_changed)
	_refresh_glow()

func _build() -> void:
	var stone_mat := MeshFactory.mat_standard(Color(0.27, 0.30, 0.28), 0.95)
	var moss_mat := MeshFactory.mat_standard(Color(0.18, 0.33, 0.22), 0.95)

	# Ring of standing stones.
	for i in 5:
		var ang := TAU * i / 5.0
		var stone := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, randf_range(1.2, 1.8), 0.5)
		stone.mesh = bm
		stone.material_override = stone_mat
		stone.position = Vector3(cos(ang) * 2.2, bm.size.y * 0.5, sin(ang) * 2.2)
		stone.rotation.y = ang
		add_child(stone)

	# Central plinth.
	var plinth := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.7
	pm.bottom_radius = 0.9
	pm.height = 0.6
	plinth.mesh = pm
	plinth.material_override = moss_mat
	plinth.position.y = 0.3
	add_child(plinth)

	# Mushroom stem.
	var stem := MeshInstance3D.new()
	var stm := CylinderMesh.new()
	stm.top_radius = 0.12
	stm.bottom_radius = 0.16
	stm.height = 0.7
	stem.mesh = stm
	stem.material_override = MeshFactory.mat_standard(Color(0.85, 0.82, 0.7), 0.6)
	stem.position.y = 0.6 + 0.35
	add_child(stem)

	# Glowing cap.
	_cap = MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.32
	cm.height = 0.42
	_cap.mesh = cm
	_cap_mat = MeshFactory.mat_emissive(Color(0.45, 0.95, 0.85), 2.2)
	_cap.material_override = _cap_mat
	_cap.position.y = 0.6 + 0.75
	_cap.scale.y = 0.7
	add_child(_cap)

	_light = OmniLight3D.new()
	_light.light_color = Color(0.5, 1.0, 0.85)
	_light.light_energy = 1.5
	_light.omni_range = 6.0
	_light.position.y = 1.4
	add_child(_light)

	# Interaction collision.
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 2.2
	col.shape = shape
	col.position.y = 1.0
	add_child(col)

func _process(delta: float) -> void:
	# Gentle pulsing bob for the cap.
	if _cap:
		var t := Time.get_ticks_msec() / 1000.0
		_cap.position.y = 1.35 + sin(t * 1.5) * 0.04
		if _light:
			_light.light_energy = 1.4 + sin(t * 2.0) * 0.3

func get_prompt() -> String:
	if not GameState.mushroom_activated:
		return "[E]  Touch the glowing mushroom"
	if GameState.quest_step == GameState.Step.RETURN_SHRINE:
		return "[E]  Commune with the shrine"
	return ""

func interact(_player: Node) -> void:
	if not GameState.mushroom_activated:
		GameState.request_dialogue("", Content.SHRINE_FIRST_TOUCH)
		GameState.activate_mushroom()
	elif GameState.quest_step == GameState.Step.RETURN_SHRINE:
		GameState.reach_shrine()

func _on_world_changed(_state: int) -> void:
	_refresh_glow()

func _refresh_glow() -> void:
	if GameState.world == GameState.World.FIRST_LAYER:
		_cap_mat.emission_energy_multiplier = 4.5
		_cap_mat.emission = Color(0.6, 1.0, 0.8)
		if _light:
			_light.light_energy = 3.0
