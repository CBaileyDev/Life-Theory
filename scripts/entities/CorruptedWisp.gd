class_name CorruptedWisp
extends CharacterBody3D
## Corrupted Wisp — hostile creature AI
## A drifting orb of corrupted simulation-light. Hidden until the world
## shifts. Simple but complete state machine:
##   IDLE   - bobs/patrols around its home point
##   CHASE  - player detected within DETECT_RANGE; floats toward them
##   ATTACK - within ATTACK_RANGE; deals damage on a cooldown
##   DEAD   - plays a burst and despawns
## Has health and takes damage from melee swings and magic pulses.

enum State { IDLE, CHASE, ATTACK, DEAD }

const DETECT_RANGE := 14.0
const ATTACK_RANGE := 2.2
const MOVE_SPEED := 3.4
const HOVER_HEIGHT := 1.6
const ATTACK_DAMAGE := 12.0
const ATTACK_COOLDOWN := 1.1
const MAX_HEALTH := 100.0

var state := State.IDLE
var health := MAX_HEALTH
var _home := Vector3.ZERO
var _attack_timer := 0.0
var _alerted := false
var _patrol_angle := 0.0

var _core: MeshInstance3D
var _core_mat: StandardMaterial3D
var _light: OmniLight3D
var _player: Node3D

func _ready() -> void:
	add_to_group("enemy")
	_home = global_position
	_build()
	GameState.world_state_changed.connect(_on_world_changed)
	_set_active(GameState.world == GameState.World.FIRST_LAYER)

func _build() -> void:
	_core = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.9
	_core.mesh = sm
	_core_mat = MeshFactory.mat_emissive(Color(0.8, 0.25, 0.55), 3.0)
	_core.material_override = _core_mat
	add_child(_core)

	# Jagged shards orbiting the core.
	for i in 4:
		var shard := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.2, 0.5, 0.2)
		shard.mesh = pm
		shard.material_override = MeshFactory.mat_emissive(Color(0.6, 0.15, 0.7), 2.5)
		var ang := TAU * i / 4.0
		shard.position = Vector3(cos(ang) * 0.7, 0, sin(ang) * 0.7)
		shard.rotation.z = ang
		_core.add_child(shard)

	_light = OmniLight3D.new()
	_light.light_color = Color(0.9, 0.3, 0.6)
	_light.light_energy = 2.0
	_light.omni_range = 6.0
	add_child(_light)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	col.shape = shape
	add_child(col)

func _set_active(active: bool) -> void:
	visible = active
	set_physics_process(active)
	set_process(active)
	for c in get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = not active
	if active:
		global_position = _home + Vector3.UP * HOVER_HEIGHT

func _on_world_changed(s: int) -> void:
	_set_active(s == GameState.World.FIRST_LAYER and state != State.DEAD)

func _process(delta: float) -> void:
	# Spin the shards for life.
	if _core:
		_core.rotation.y += delta * 1.5

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_player = _get_player()
	var dist := INF
	if _player:
		dist = global_position.distance_to(_player.global_position)

	match state:
		State.IDLE:
			_patrol(delta)
			if dist < DETECT_RANGE:
				_enter_chase()
		State.CHASE:
			_chase(delta)
			if dist <= ATTACK_RANGE:
				state = State.ATTACK
			elif dist > DETECT_RANGE * 1.4:
				state = State.IDLE
				_alerted = false
		State.ATTACK:
			_face_player()
			if dist > ATTACK_RANGE * 1.2:
				state = State.CHASE
			elif _attack_timer <= 0.0:
				_do_attack()

	move_and_slide()
	_clamp_hover(delta)

func _patrol(delta: float) -> void:
	_patrol_angle += delta * 0.6
	var target := _home + Vector3(cos(_patrol_angle) * 3.0, HOVER_HEIGHT, sin(_patrol_angle) * 3.0)
	var to := target - global_position
	velocity = velocity.move_toward(to * 1.5, 4.0 * delta)

func _enter_chase() -> void:
	state = State.CHASE
	if not _alerted:
		_alerted = true
		AudioManager.play("wisp_alert")

func _chase(delta: float) -> void:
	if not _player:
		return
	var to := _player.global_position - global_position
	to.y = 0
	velocity = velocity.move_toward(to.normalized() * MOVE_SPEED, 8.0 * delta)
	_face_player()

func _face_player() -> void:
	if not _player:
		return
	var target := Vector3(_player.global_position.x, global_position.y, _player.global_position.z)
	if target.distance_to(global_position) > 0.05:
		look_at(target, Vector3.UP)

func _do_attack() -> void:
	_attack_timer = ATTACK_COOLDOWN
	GameState.damage_player(ATTACK_DAMAGE)
	# Quick lunge pulse.
	_core_mat.emission_energy_multiplier = 6.0
	var t := create_tween()
	t.tween_property(_core_mat, "emission_energy_multiplier", 3.0, 0.3)

func _clamp_hover(delta: float) -> void:
	# Keep it floating near hover height with a gentle bob.
	var bob := sin(Time.get_ticks_msec() / 1000.0 * 2.0) * 0.1
	var target_y := _home.y + HOVER_HEIGHT + bob
	global_position.y = lerpf(global_position.y, target_y, clampf(delta * 4.0, 0, 1))

func take_damage(amount: float, _source: Node) -> void:
	if state == State.DEAD:
		return
	health -= amount
	AudioManager.play("wisp_damage")
	# Hit flash.
	_core_mat.emission = Color(1.0, 0.9, 0.9)
	var t := create_tween()
	t.tween_property(_core_mat, "emission", Color(0.8, 0.25, 0.55), 0.2)
	if not _alerted:
		_enter_chase()
	if health <= 0.0:
		_die()

func _die() -> void:
	state = State.DEAD
	AudioManager.play("wisp_death")
	_spawn_death_burst()
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 0.4)
	t.tween_callback(queue_free)

func _spawn_death_burst() -> void:
	var p := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.UP
	mat.spread = 180.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -2, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	mat.color = Color(0.9, 0.4, 0.7)
	p.process_material = mat
	var dm := QuadMesh.new()
	dm.size = Vector2(0.2, 0.2)
	p.draw_pass_1 = dm
	p.amount = 40
	p.lifetime = 1.0
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = true
	p.global_position = global_position
	get_tree().current_scene.add_child(p)
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)

func _get_player() -> Node3D:
	var n := get_tree().get_nodes_in_group("player")
	return n[0] if n.size() > 0 else null
