class_name Player
extends CharacterBody3D
## Player controller
## Smooth WASD movement with acceleration, mouse-look, sprint, jump,
## raycast interaction, melee combat, and an unlockable magic pulse.
## First-person by default with an optional third-person camera (toggle C
## or Settings). All input is engine-native (actions registered in Boot.gd).

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.5
const ACCEL := 12.0
const DECEL := 16.0
const JUMP_VELOCITY := 5.2
const MOUSE_PITCH_MIN := -1.4
const MOUSE_PITCH_MAX := 1.4
const ATTACK_RANGE := 3.0
const ATTACK_COOLDOWN := 0.45
const FALL_RESET_Y := -25.0
const STAMINA_MAX := 100.0
const STAMINA_DRAIN := 24.0
const STAMINA_REGEN := 16.0

var _stamina := STAMINA_MAX

var _yaw := 0.0
var _pitch := 0.0
var _trauma := 0.0
const _HEAD_BASE := Vector3(0, 1.65, 0)
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _attack_timer := 0.0
var _cast_timer := 0.0
var _step_timer := 0.0
var _spawn_point := Vector3(0, 2, 18)
var _interact_target = null   # untyped: interactables are called via duck-typing

# Built in _ready
var head: Node3D
var fp_camera: Camera3D
var spring: SpringArm3D
var tp_camera: Camera3D
var ray: RayCast3D
var weapon_pivot: Node3D
var weapon_mesh: MeshInstance3D
var _hud   # untyped: HUD is accessed via duck-typing (set_prompt/flash_damage)

const ProjectileScene := preload("res://scripts/combat/Projectile.gd")

func _ready() -> void:
	add_to_group("player")
	_build_body()
	_build_camera_rig()
	_build_weapon()
	_apply_camera_mode(SettingsManager.third_person)
	_apply_fov(SettingsManager.fov)
	SettingsManager.camera_mode_changed.connect(_apply_camera_mode)
	SettingsManager.fov_changed.connect(_apply_fov)
	GameState.player_died.connect(_on_died)
	GameState.player_damaged.connect(_on_damaged)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_hud = _first_in_group("hud")

func set_spawn(p: Vector3) -> void:
	_spawn_point = p

func get_yaw() -> float:
	return _yaw

func teleport(p: Vector3, yaw := 0.0) -> void:
	global_position = p
	_yaw = yaw
	rotation.y = _yaw
	velocity = Vector3.ZERO

# --------------------------------------------------------------- construction
func _build_body() -> void:
	var col := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.4
	caps.height = 1.8
	col.shape = caps
	col.position.y = 0.9
	add_child(col)

func _build_camera_rig() -> void:
	head = Node3D.new()
	head.name = "Head"
	head.position.y = 1.65
	add_child(head)

	fp_camera = Camera3D.new()
	fp_camera.name = "FPCamera"
	fp_camera.fov = 75.0
	head.add_child(fp_camera)

	spring = SpringArm3D.new()
	spring.name = "SpringArm"
	spring.spring_length = 4.0
	spring.position = Vector3(0.6, 0.2, 0)
	head.add_child(spring)
	tp_camera = Camera3D.new()
	tp_camera.name = "TPCamera"
	tp_camera.fov = 75.0
	tp_camera.position.z = 0.0
	spring.add_child(tp_camera)

	ray = RayCast3D.new()
	ray.name = "InteractRay"
	ray.target_position = Vector3(0, 0, -ATTACK_RANGE - 1.0)
	ray.enabled = true
	fp_camera.add_child(ray)

	# Soft personal light so the First Layer stays readable at night.
	var lantern := OmniLight3D.new()
	lantern.light_color = Color(0.7, 0.82, 1.0)
	lantern.light_energy = 0.55
	lantern.omni_range = 12.0
	head.add_child(lantern)

func _build_weapon() -> void:
	# The Ancient Rootblade: a simple stone/wood blade held at the lower-right.
	weapon_pivot = Node3D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector3(0.32, -0.28, -0.55)
	fp_camera.add_child(weapon_pivot)

	weapon_mesh = MeshInstance3D.new()
	var blade := BoxMesh.new()
	blade.size = Vector3(0.06, 0.5, 0.06)
	weapon_mesh.mesh = blade
	weapon_mesh.material_override = MeshFactory.mat_standard(Color(0.55, 0.43, 0.28), 0.7)
	weapon_mesh.position.y = 0.22
	weapon_pivot.add_child(weapon_mesh)

	var guard := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.18, 0.04, 0.06)
	guard.mesh = gm
	guard.material_override = MeshFactory.mat_emissive(Color(0.4, 0.8, 0.7), 1.2)
	weapon_pivot.add_child(guard)

# ------------------------------------------------------------------ camera
func _apply_camera_mode(third_person: bool) -> void:
	if third_person:
		tp_camera.current = true
		weapon_pivot.visible = false
	else:
		fp_camera.current = true
		weapon_pivot.visible = true

func _toggle_camera() -> void:
	SettingsManager.set_third_person(not SettingsManager.third_person)

func _apply_fov(fov: float) -> void:
	if fp_camera:
		fp_camera.fov = fov
	if tp_camera:
		tp_camera.fov = fov

# --------------------------------------------------------------- camera shake
func _on_damaged(amount: float) -> void:
	_trauma = minf(_trauma + clampf(amount / 30.0, 0.2, 0.7), 1.0)

func _process(delta: float) -> void:
	if not head:
		return
	if _trauma > 0.0:
		_trauma = maxf(_trauma - delta * 1.6, 0.0)
		var amt := _trauma * _trauma
		head.position = _HEAD_BASE + Vector3(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * 0.14 * amt
	elif head.position != _HEAD_BASE:
		head.position = _HEAD_BASE

# ------------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := SettingsManager.mouse_sensitivity * 0.01
		var inv := -1.0 if SettingsManager.invert_y else 1.0
		_yaw -= event.relative.x * sens
		_pitch -= event.relative.y * sens * inv
		_pitch = clampf(_pitch, MOUSE_PITCH_MIN, MOUSE_PITCH_MAX)
		rotation.y = _yaw
		head.rotation.x = _pitch
	elif event.is_action_pressed("attack"):
		_attack()
	elif event.is_action_pressed("cast"):
		_cast()
	elif event.is_action_pressed("camera_toggle"):
		_toggle_camera()
	elif event.is_action_pressed("interact"):
		_try_interact()

# ----------------------------------------------------------------- movement
func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_cast_timer = maxf(_cast_timer - delta, 0.0)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var wants_sprint := Input.is_action_pressed("sprint") and input_dir.y < 0.0
	var sprinting := wants_sprint and _stamina > 1.0
	if sprinting:
		_stamina = maxf(_stamina - STAMINA_DRAIN * delta, 0.0)
	else:
		_stamina = minf(_stamina + STAMINA_REGEN * delta, STAMINA_MAX)
	if _hud and _hud.has_method("set_stamina"):
		_hud.set_stamina(_stamina / STAMINA_MAX)
	var target_speed := (SPRINT_SPEED * GameState.sprint_multiplier) if sprinting else WALK_SPEED
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	if dir.length() > 0.01:
		horizontal = horizontal.move_toward(dir * target_speed, ACCEL * delta)
	else:
		horizontal = horizontal.move_toward(Vector3.ZERO, DECEL * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()

	_update_interaction()
	_update_footsteps(delta)
	if global_position.y < FALL_RESET_Y:
		_respawn()

func _update_footsteps(delta: float) -> void:
	var hspeed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and hspeed > 0.6:
		_step_timer -= delta
		if _step_timer <= 0.0:
			AudioManager.play("footstep", -8.0, randf_range(0.9, 1.1))
			_step_timer = 0.34 if hspeed > WALK_SPEED + 0.5 else 0.5
	else:
		_step_timer = 0.0

# -------------------------------------------------------------- interaction
func _update_interaction() -> void:
	var target = null
	if ray.is_colliding():
		var c = ray.get_collider()
		if c and c.is_in_group("interactable") and c.has_method("get_prompt"):
			target = c
	_interact_target = target
	if _hud and _hud.has_method("set_prompt"):
		_hud.set_prompt(target.get_prompt() if target else "")

func _try_interact() -> void:
	if _interact_target and _interact_target.has_method("interact"):
		_interact_target.interact(self)

# ------------------------------------------------------------------ combat
func _attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = ATTACK_COOLDOWN
	AudioManager.play("player_attack")
	_swing_weapon()
	# Hit detection: nearest enemy inside a forward cone.
	var origin := fp_camera.global_position
	var forward := -fp_camera.global_transform.basis.z
	var landed := false
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node3D) or not enemy.has_method("take_damage"):
			continue
		var to: Vector3 = enemy.global_position - origin
		if to.length() <= ATTACK_RANGE and forward.dot(to.normalized()) > 0.55:
			enemy.take_damage(GameState.melee_damage, self)
			landed = true
	if landed and _hud and _hud.has_method("hitmarker"):
		_hud.hitmarker()

func _swing_weapon() -> void:
	if not weapon_pivot.visible:
		return
	var t := create_tween()
	t.tween_property(weapon_pivot, "rotation_degrees:z", -70.0, 0.08)
	t.tween_property(weapon_pivot, "rotation_degrees:z", 0.0, 0.22)

func _cast() -> void:
	if not GameState.magic_unlocked or _cast_timer > 0.0:
		return
	_cast_timer = 0.8
	AudioManager.play("magic_cast")
	var proj := ProjectileScene.new()
	get_tree().current_scene.add_child(proj)
	var origin := fp_camera.global_position - fp_camera.global_transform.basis.z * 0.5
	var forward := -fp_camera.global_transform.basis.z
	proj.launch(origin, forward, self)

# ------------------------------------------------------------------- death
func _on_died() -> void:
	# Brief delay then respawn at the last safe point (forgiving prototype).
	if _hud and _hud.has_method("flash_damage"):
		_hud.flash_damage(true)
	if _hud and _hud.has_method("show_death"):
		_hud.show_death()
	await get_tree().create_timer(1.6).timeout
	_respawn()

func _respawn() -> void:
	teleport(_spawn_point, _yaw)
	GameState.revive_full()
	_stamina = STAMINA_MAX
	if _hud and _hud.has_method("flash_damage"):
		_hud.flash_damage(false)
	if _hud and _hud.has_method("hide_death"):
		_hud.hide_death()

# --------------------------------------------------------------------- util
func _first_in_group(g: String) -> Node:
	var n := get_tree().get_nodes_in_group(g)
	return n[0] if n.size() > 0 else null
