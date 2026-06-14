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
const KNOCKBACK := 6.5

var state := State.IDLE
var health := MAX_HEALTH
# Archetype palette — subclasses (e.g. Dimmer) override these before super._ready().
var core_color := Color(0.8, 0.25, 0.55)
var shard_color := Color(0.6, 0.15, 0.7)
var light_col := Color(0.9, 0.3, 0.6)
var aura_color := Color(0.75, 0.2, 0.5)
var _home := Vector3.ZERO
var _attack_timer := 0.0
var _alerted := false
var _patrol_angle := 0.0
var _stuck_timer := 0.0          # how long CHASE has made no headway (anti-wedge)
var _last_xz := Vector2.ZERO
var _height_sampler := Callable() # optional terrain height(x,z) so hover follows slopes

var _core: MeshInstance3D
var _core_mat: StandardMaterial3D
var _core_tween: Tween           # the wind-up tween, killed on death so scale stays monotonic
var _light: OmniLight3D
var _player: Node3D
var _seam: MeshInstance3D         # weak-seam: revealed by the Sight, struck for bonus damage

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
	_core_mat = MeshFactory.mat_emissive(core_color, 3.0)
	_core.material_override = _core_mat
	add_child(_core)

	# Jagged shards orbiting the core.
	for i in 4:
		var shard := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.2, 0.5, 0.2)
		shard.mesh = pm
		shard.material_override = MeshFactory.mat_emissive(shard_color, 2.5)
		var ang := TAU * i / 4.0
		shard.position = Vector3(cos(ang) * 0.7, 0, sin(ang) * 0.7)
		shard.rotation.z = ang
		_core.add_child(shard)

	# Weak-seam: a glowing mark on the core, hidden until the Sight is opened
	# (group "sight_only", toggled by SightController). Striking the wisp while
	# the Sight is open exposes the seam for heavy bonus damage — see take_damage.
	_seam = MeshInstance3D.new()
	var seam_q := QuadMesh.new()
	seam_q.size = Vector2(0.55, 0.55)
	_seam.mesh = seam_q
	_seam.material_override = MeshFactory.mat_emissive(Color(0.45, 1.0, 0.95, 0.9), 4.5, true)
	_seam.position = Vector3(0.0, 0.0, 0.46)
	_seam.visible = false
	_core.add_child(_seam)
	_seam.add_to_group("sight_only")

	_light = OmniLight3D.new()
	_light.light_color = light_col
	_light.light_energy = 2.0
	_light.omni_range = 6.0
	add_child(_light)

	# Sinking corrupted embers.
	add_child(MeshFactory.make_aura(aura_color, 18, -0.25, 0.55, 0.08))

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	col.shape = shape
	add_child(col)

## Lets the level feed the wisp a terrain height function so it hovers over
## slopes instead of clipping into them when it leaves its (flat) home.
func set_height_sampler(c: Callable) -> void:
	_height_sampler = c

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
	# Gate detection/attack on HORIZONTAL distance — the wisp hovers ~1.6m up, so
	# 3D distance would shorten its effective reach and jitter with the bob.
	var dist := INF
	if _player:
		dist = _horiz_dist(_player.global_position)

	match state:
		State.IDLE:
			_patrol(delta)
			if dist < DETECT_RANGE:
				_enter_chase()
		State.CHASE:
			_chase(delta)
			_update_stuck(delta)
			if dist <= ATTACK_RANGE:
				state = State.ATTACK
			elif dist > DETECT_RANGE * 1.4 or _stuck_timer > 2.0:
				# Lost the player, or wedged against geometry with no headway.
				state = State.IDLE
				_stuck_timer = 0.0
		State.ATTACK:
			_face_player()
			if dist > ATTACK_RANGE * 1.2:
				state = State.CHASE
			elif _attack_timer <= 0.0:
				_do_attack()

	move_and_slide()
	_clamp_hover(delta)

func _horiz_dist(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()

func _update_stuck(delta: float) -> void:
	# Accumulate time while CHASE barely moves the wisp (wedged on a trunk).
	var xz := Vector2(global_position.x, global_position.z)
	if xz.distance_to(_last_xz) < 0.06:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
		_last_xz = xz

func _patrol(delta: float) -> void:
	_patrol_angle += delta * 0.6
	var target := _home + Vector3(cos(_patrol_angle) * 3.0, HOVER_HEIGHT, sin(_patrol_angle) * 3.0)
	var to := target - global_position
	velocity = velocity.move_toward(to * 1.5, 4.0 * delta)

func _enter_chase() -> void:
	state = State.CHASE
	_stuck_timer = 0.0
	_last_xz = Vector2(global_position.x, global_position.z)
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
	# Telegraphed wind-up: a rising whine + hot warning flare + swell, then strike.
	# Damage only lands if the player is still in range, so it can be dodged.
	AudioManager.play("wisp_alert", -12.0, 1.6)
	_core_mat.emission_energy_multiplier = 6.0
	_core_mat.emission = Color(1.0, 0.55, 0.2)
	_core_tween = create_tween()
	_core_tween.tween_property(_core, "scale", Vector3(1.5, 1.5, 1.5), 0.22).set_trans(Tween.TRANS_SINE)
	_core_tween.tween_callback(_strike)
	_core_tween.tween_property(_core, "scale", Vector3.ONE, 0.22)
	_core_tween.parallel().tween_property(_core_mat, "emission_energy_multiplier", 3.0, 0.3)
	_core_tween.parallel().tween_property(_core_mat, "emission", core_color, 0.3)

func _strike() -> void:
	if state == State.DEAD:
		return
	# Horizontal check so the hover offset doesn't rob the strike of its reach.
	if _player and _horiz_dist(_player.global_position) <= ATTACK_RANGE * 1.3:
		_strike_effect()

## What landing a hit does. Base wisp deals damage; subclasses override (the
## Dimmer blinds instead of dealing full damage).
func _strike_effect() -> void:
	GameState.damage_player(ATTACK_DAMAGE * SettingsManager.enemy_damage_mult(), global_position)

func _clamp_hover(delta: float) -> void:
	# Keep it floating near hover height with a gentle bob. Follow the terrain
	# under the wisp (if a height sampler was provided) so it doesn't sink into
	# slopes when it chases the player away from its flat home.
	var bob := sin(Time.get_ticks_msec() / 1000.0 * 2.0) * 0.1
	var ground := _home.y
	if _height_sampler.is_valid():
		ground = _height_sampler.call(global_position.x, global_position.z)
	var target_y := ground + HOVER_HEIGHT + bob
	global_position.y = lerpf(global_position.y, target_y, clampf(delta * 4.0, 0, 1))

func take_damage(amount: float, source) -> void:
	if state == State.DEAD:
		return
	# Sight-struck: the weak-seam is exposed → heavy bonus damage + extra stagger.
	# This is the core "fight better by seeing the truth (but it wears you down)" loop.
	var weak := GameState.sight_active
	if weak:
		amount *= GameState.sight_weakpoint_mult
	health -= amount
	AudioManager.play("wisp_damage", -2.0 if weak else -6.0, 1.15 if weak else 1.0)
	DamageNumber.spawn(get_tree().current_scene,
		global_position + Vector3(0, 0.9, 0), amount,
		Color(0.5, 1.0, 0.95) if weak else Color(1.0, 0.85, 0.9))
	if weak:
		var sp := MeshFactory.spark(Color(0.5, 1.0, 0.95), 24, 5.5, 0.16)
		get_tree().current_scene.add_child(sp)
		sp.global_position = global_position + Vector3(0, 0.5, 0)
	# Knockback away from the attacker (harder on a weak-seam hit).
	if source is Node3D:
		var dir: Vector3 = global_position - source.global_position
		dir.y = 0.0
		if dir.length() > 0.01:
			velocity += dir.normalized() * (KNOCKBACK * (1.6 if weak else 1.0))
	# Hit flash.
	_core_mat.emission = Color(1.0, 0.9, 0.9)
	var t := create_tween()
	t.tween_property(_core_mat, "emission", core_color, 0.2)
	if not _alerted:
		_enter_chase()
	if health <= 0.0:
		_die()

func _die() -> void:
	state = State.DEAD
	AudioManager.play("wisp_death")
	GameState.forest_essence += 15
	GameState.toast.emit("Corrupted Wisp dissolved.  +15 Essence")
	_spawn_death_burst()
	var sp := MeshFactory.spark(Color(0.95, 0.4, 0.7), 26, 5.5, 0.18)
	get_tree().current_scene.add_child(sp)
	sp.global_position = global_position
	# Stop any in-flight wind-up so the core doesn't pop mid-dissolve.
	if _core_tween and _core_tween.is_valid():
		_core_tween.kill()
	_core_mat.emission_energy_multiplier = 7.0
	# A brief overload flare-and-pop before the dissolve — the kill reads as earned.
	var t := create_tween()
	t.tween_property(_core, "scale", Vector3(1.7, 1.7, 1.7), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector3.ZERO, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
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
	var pos := global_position
	get_tree().current_scene.add_child(p)
	p.global_position = pos   # must be set AFTER entering the tree, not before
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)

func _get_player() -> Node3D:
	var n := get_tree().get_nodes_in_group("player")
	return n[0] if n.size() > 0 else null
