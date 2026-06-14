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
const DODGE_SPEED := 12.5
const DODGE_TIME := 0.32
const DODGE_IFRAMES := 0.24
const DODGE_COST := 28.0
const DODGE_COOLDOWN := 0.6

var _dodge_timer := 0.0     # >0 while a dodge is in progress
var _dodge_cd := 0.0
var _dodge_dir := Vector3.ZERO
var fov_cinematic := false   # when true, scripted FOV tweens own the camera FOV

func set_fov_cinematic(on: bool) -> void:
	fov_cinematic = on

var _stamina := STAMINA_MAX
var _sprint_toggled := false
var _dead := false   # true during the death/respawn window: no input, no actions

var _yaw := 0.0
var _pitch := 0.0
var _trauma := 0.0
var _bob_t := 0.0
var _weapon_kick := Vector3.ZERO    # transient recoil offset, added on top of bob
var _base_fov := 75.0               # the settings FOV; sprint kicks above it
var _is_sprinting := false
var _was_on_floor := true
var _prev_fall := 0.0               # downward speed last frame, for landing impact
var _hitstop := false
const _HEAD_BASE := Vector3(0, 1.65, 0)
const _WEAPON_BASE := Vector3(0.32, -0.28, -0.55)
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
var weapon_mesh: Node3D
var _hud   # untyped: HUD is accessed via duck-typing (set_prompt/flash_damage)

const ProjectileScene := preload("res://scripts/combat/Projectile.gd")
const RootbladeScene := preload("res://assets/models/rootblade.glb")
const SeekerScene := preload("res://assets/models/seeker.glb")

# Third-person avatar (the Seeker) + its held blade. Built in _ready, shown only
# in third-person. The mesh is rigid, so motion is sold procedurally (bob/lean/
# swing) rather than skeletal animation.
var tp_body: Node3D
var tp_sword: Node3D
var _body_anim_t := 0.0

func _ready() -> void:
	add_to_group("player")
	_build_body()
	_build_camera_rig()
	_build_weapon()
	_build_tp_body()
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
	spring.spring_length = 4.2
	spring.position = Vector3(0.45, 0.18, 0)
	spring.margin = 0.35
	head.add_child(spring)
	tp_camera = Camera3D.new()
	tp_camera.name = "TPCamera"
	tp_camera.fov = 75.0
	tp_camera.position.z = 0.0
	tp_camera.rotation_degrees = Vector3(-7.0, 0.0, 0.0)   # frame the Seeker from above
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
	# The Ancient Rootblade — grief crystallised: a knotted root grip, a pale
	# crystalline leaf-blade veined with living teal light, and a glowing seed at
	# the pommel. A high-res mesh sculpted in Blender, held as the first-person
	# view-model at the lower-right, tilted for a natural ready pose.
	weapon_pivot = Node3D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector3(0.38, -0.32, -0.58)
	weapon_pivot.rotation_degrees = Vector3(8, -10, 5)
	fp_camera.add_child(weapon_pivot)

	var rb := RootbladeScene.instantiate()
	rb.name = "RootbladeModel"
	# The blade points +Y (up) in model space; held grip-down at the pivot.
	rb.scale = Vector3.ONE * 0.56
	rb.rotation_degrees = Vector3(-14.0, 0.0, 0.0)   # tip pitched slightly forward
	rb.position = Vector3(0.0, 0.02, 0.0)
	weapon_pivot.add_child(rb)
	weapon_mesh = rb

func _build_tp_body() -> void:
	# The Seeker — a hooded forest-mystic, the body the player sees in third
	# person. Parented to the root so it yaws with the player but never pitches
	# with the look. A second Rootblade is set into the right hand.
	tp_body = Node3D.new()
	tp_body.name = "SeekerBody"
	add_child(tp_body)

	var seeker := SeekerScene.instantiate()
	seeker.name = "SeekerModel"
	# Blender +Y forward → Godot -Z forward, matching the player's facing.
	seeker.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	tp_body.add_child(seeker)

	# Rootblade gripped in the right hand. The hand sits forward-right of the
	# chest in model space; values mirror the Seeker's sculpted hand position.
	tp_sword = RootbladeScene.instantiate()
	tp_sword.name = "SeekerBlade"
	tp_sword.position = Vector3(-0.14, 1.02, 0.40)
	tp_sword.rotation_degrees = Vector3(-18.0, 0.0, -22.0)
	tp_body.add_child(tp_sword)

# ------------------------------------------------------------------ camera
func _apply_camera_mode(third_person: bool) -> void:
	if third_person:
		tp_camera.current = true
		weapon_pivot.visible = false
		if tp_body:
			tp_body.visible = true
	else:
		fp_camera.current = true
		weapon_pivot.visible = true
		if tp_body:
			tp_body.visible = false

func _toggle_camera() -> void:
	SettingsManager.set_third_person(not SettingsManager.third_person)

func _apply_fov(fov: float) -> void:
	_base_fov = fov
	if fp_camera:
		fp_camera.fov = fov
	if tp_camera:
		tp_camera.fov = fov

# --------------------------------------------------------------- camera shake
func _on_damaged(amount: float, _from_pos: Vector3) -> void:
	if SettingsManager.reduce_motion:
		return
	_trauma = minf(_trauma + clampf(amount / 30.0, 0.2, 0.7) * SettingsManager.screen_shake, 1.0)

func _process(delta: float) -> void:
	if not head:
		return
	_gamepad_look(delta)
	if _trauma > 0.0:
		_trauma = maxf(_trauma - delta * 1.6, 0.0)
		var amt := _trauma * _trauma
		head.position = _HEAD_BASE + Vector3(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * 0.14 * amt
	elif head.position != _HEAD_BASE:
		head.position = _HEAD_BASE
	# View-model bob while moving on the ground, plus transient swing recoil.
	if weapon_pivot and weapon_pivot.visible:
		var bob := Vector3.ZERO
		if not SettingsManager.reduce_motion:
			var hspeed := Vector2(velocity.x, velocity.z).length()
			var walk := clampf(hspeed / WALK_SPEED, 0.0, 1.6)
			_bob_t += delta * (10.0 if hspeed > WALK_SPEED + 0.5 else 7.0) * walk
			var amt := walk * 0.018
			bob = Vector3(sin(_bob_t) * amt, absf(sin(_bob_t * 2.0)) * amt, 0.0)
		_weapon_kick = _weapon_kick.lerp(Vector3.ZERO, clampf(delta * 12.0, 0, 1))
		weapon_pivot.position = _WEAPON_BASE + bob + _weapon_kick
	# Sprint FOV kick — a subtle speed sell that settles back when you slow.
	# Suspended while a cinematic owns the FOV (transformation / vista).
	if fp_camera and not SettingsManager.reduce_motion and not fov_cinematic:
		var want := _base_fov + (8.0 if _is_sprinting else 0.0)
		fp_camera.fov = lerpf(fp_camera.fov, want, clampf(delta * 8.0, 0, 1))
	# Third-person avatar: rigid mesh, motion sold procedurally.
	if tp_body and tp_body.visible:
		_animate_tp_body(delta)

# Procedural life for the Seeker in third person: a stride bounce + forward lean
# while moving, a slow breathing bob when idle. The robe hides the lack of leg
# articulation, so a rocking stride reads as walking without a skeleton.
func _animate_tp_body(delta: float) -> void:
	if SettingsManager.reduce_motion:
		tp_body.position = Vector3.ZERO
		tp_body.rotation = Vector3.ZERO
		return
	var hspeed := Vector2(velocity.x, velocity.z).length()
	var moving := hspeed > 0.4
	var run := clampf(hspeed / WALK_SPEED, 0.0, 1.8)
	var freq := 7.5 if hspeed > WALK_SPEED + 0.5 else 5.2
	_body_anim_t += delta * (freq if moving else 1.5)
	var bob_amt := (0.055 * run) if moving else 0.012
	tp_body.position = Vector3(0.0, absf(sin(_body_anim_t)) * bob_amt, 0.0)
	var lean := deg_to_rad(8.0) * clampf(run, 0.0, 1.0) if moving else 0.0
	tp_body.rotation.x = lerpf(tp_body.rotation.x, lean, clampf(delta * 8.0, 0.0, 1.0))
	tp_body.rotation.z = sin(_body_anim_t) * deg_to_rad(2.5) * run

# Right-stick look (gamepad). Mouse look stays in _unhandled_input; this runs
# every frame so analog aiming is smooth and framerate-scaled.
func _gamepad_look(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or _dead:
		return
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look.length_squared() < 0.0004:
		return
	var sens := SettingsManager.mouse_sensitivity * 3.2
	var inv := -1.0 if SettingsManager.invert_y else 1.0
	_yaw -= look.x * sens * delta
	_pitch -= look.y * sens * delta * inv
	_pitch = clampf(_pitch, MOUSE_PITCH_MIN, MOUSE_PITCH_MAX)
	rotation.y = _yaw
	head.rotation.x = _pitch

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
	elif _dead:
		return  # no combat/interaction while down
	elif event.is_action_pressed("attack"):
		_attack()
	elif event.is_action_pressed("cast"):
		_cast()
	elif event.is_action_pressed("dodge"):
		_dodge()
	elif event.is_action_pressed("camera_toggle"):
		_toggle_camera()
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("sprint") and SettingsManager.sprint_toggle:
		_sprint_toggled = not _sprint_toggled

# ----------------------------------------------------------------- movement
func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_cast_timer = maxf(_cast_timer - delta, 0.0)
	_dodge_cd = maxf(_dodge_cd - delta, 0.0)

	# Dodge: a brief i-frame burst in the move (or backward) direction. Overrides
	# normal movement while active; gravity + collisions still resolve.
	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		if _dodge_timer <= DODGE_TIME - DODGE_IFRAMES:
			GameState.player_invuln = false
		if not is_on_floor():
			velocity.y -= _gravity * delta
		var ds := DODGE_SPEED * clampf(_dodge_timer / DODGE_TIME, 0.3, 1.0)
		velocity.x = _dodge_dir.x * ds
		velocity.z = _dodge_dir.z * ds
		move_and_slide()
		_update_interaction()
		if _dodge_timer <= 0.0:
			GameState.player_invuln = false
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta
	if not _dead and is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	# No movement input while down — gravity/collision still run so the body
	# settles, but the player can't walk, sprint, or jump until they respawn.
	var input_dir := Vector2.ZERO if _dead else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var sprint_held := _sprint_toggled if SettingsManager.sprint_toggle else Input.is_action_pressed("sprint")
	var wants_sprint := sprint_held and input_dir.y < 0.0
	var sprinting := wants_sprint and _stamina > 1.0
	_is_sprinting = sprinting and dir.length() > 0.1
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

	if not is_on_floor():
		_prev_fall = -velocity.y
	move_and_slide()
	# Landing impact: thud + camera dip when hitting ground after a real fall.
	if is_on_floor() and not _was_on_floor and _prev_fall > 5.0:
		_on_land(_prev_fall)
	_was_on_floor = is_on_floor()

	_update_interaction()
	_update_footsteps(delta)
	if global_position.y < FALL_RESET_Y:
		_respawn()

func _on_land(speed: float) -> void:
	AudioManager.play("footstep", -3.0, 0.7)
	if SettingsManager.reduce_motion:
		return
	_trauma = minf(_trauma + clampf(speed / 18.0, 0.1, 0.5) * SettingsManager.screen_shake, 1.0)
	_weapon_kick += Vector3(0.0, -0.06, 0.0) * clampf(speed / 12.0, 0.3, 1.2)

func _update_footsteps(delta: float) -> void:
	var hspeed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and hspeed > 0.6:
		_step_timer -= delta
		if _step_timer <= 0.0:
			AudioManager.play(_surface_step_cue(), -8.0, randf_range(0.9, 1.12))
			_step_timer = 0.34 if hspeed > WALK_SPEED + 0.5 else 0.5
	else:
		_step_timer = 0.0

## Pick a footstep timbre from what's underfoot: stone when standing on a scatter
## boulder, dirt on the entrance path corridor, grass everywhere else.
func _surface_step_cue() -> String:
	var floor_col = get_last_slide_collision()
	if floor_col:
		var c = floor_col.get_collider()
		if c is Node and (c as Node).name == "ScatterCollision":
			return "step_rock"
	var p := global_position
	if absf(p.x) < WorldBuilder.PATH_HALF_WIDTH + 1.0 and p.z > 0.0 and p.z < 18.5:
		return "step_dirt"
	return "step_grass"

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
	if _hud and _hud.has_method("set_crosshair_active"):
		_hud.set_crosshair_active(target != null)

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
	# Hit detection: every enemy inside a forward cone and in range that the swing
	# can actually reach (not blocked by a tree/rock/wall). It's a cleave, so more
	# than one wisp can be struck at once.
	var origin := fp_camera.global_position
	var forward := -fp_camera.global_transform.basis.z
	var enemies := get_tree().get_nodes_in_group("enemy")
	# Exclude self + every enemy body so the line-of-sight ray only stops on world
	# geometry — otherwise a wisp's own collider would always "block" the ray.
	var exclude: Array[RID] = [get_rid()]
	for e in enemies:
		if e is CollisionObject3D:
			exclude.append((e as CollisionObject3D).get_rid())
	var landed := false
	for enemy in enemies:
		if not (enemy is Node3D) or not enemy.has_method("take_damage"):
			continue
		var to: Vector3 = enemy.global_position - origin
		if to.length() <= ATTACK_RANGE and forward.dot(to.normalized()) > 0.55:
			if _has_line_of_sight(origin, enemy.global_position, exclude):
				enemy.take_damage(GameState.melee_damage, self)
				landed = true
				_combat_impact(enemy.global_position + Vector3(0, 0.9, 0), 0.22)
	if landed:
		if _hud and _hud.has_method("hitmarker"):
			_hud.hitmarker()
		_do_hitstop(0.06)   # crisp moment of contact

# Shared combat-impact feedback: a spark burst at the hit point + camera shake.
func _combat_impact(pos: Vector3, shake_amt: float) -> void:
	var s := MeshFactory.spark(Color(0.78, 0.96, 0.86), 22, 5.0, 0.16)
	get_tree().current_scene.add_child(s)
	s.global_position = pos
	if not SettingsManager.reduce_motion:
		_trauma = minf(_trauma + shake_amt * SettingsManager.screen_shake, 1.0)

# A brief real-time freeze on contact for weighty hits (skipped on reduce-motion).
func _do_hitstop(dur: float) -> void:
	if _hitstop or SettingsManager.reduce_motion:
		return
	_hitstop = true
	Engine.time_scale = 0.06
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop = false

func _has_line_of_sight(from: Vector3, to: Vector3, exclude: Array[RID]) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = exclude
	q.collide_with_areas = false
	# Empty result => nothing solid between the swing and the enemy.
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

## A stamina-costed dodge with i-frames: burst in the move direction (or
## backward if standing still). Pairs with the wisps' telegraphed strikes and
## the Dimmer's blind. GameState.player_invuln gates incoming damage.
func _dodge() -> void:
	if _dead or _dodge_timer > 0.0 or _dodge_cd > 0.0 or _stamina < DODGE_COST:
		return
	_stamina -= DODGE_COST
	_dodge_timer = DODGE_TIME
	_dodge_cd = DODGE_COOLDOWN
	GameState.player_invuln = true
	AudioManager.play("dodge", -6.0, randf_range(0.95, 1.12))
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	if dir.length() < 0.1:
		dir = transform.basis.z   # no input → dodge backward (+local z is behind)
	_dodge_dir = dir.normalized()
	if not SettingsManager.reduce_motion:
		_trauma = minf(_trauma + 0.1 * SettingsManager.screen_shake, 1.0)
		_weapon_kick += Vector3(0.0, 0.04, 0.06)

func _swing_weapon() -> void:
	if weapon_pivot and weapon_pivot.visible:
		# Recoil kick (settles via _process) layered under the arcing swing.
		_weapon_kick += Vector3(-0.02, 0.03, 0.12)
		var t := create_tween()
		t.tween_property(weapon_pivot, "rotation_degrees:z", -70.0, 0.08)
		t.tween_property(weapon_pivot, "rotation_degrees:z", 0.0, 0.22)
	# Third-person overhand chop on the held Rootblade.
	if tp_body and tp_body.visible and tp_sword:
		var base := Vector3(-18.0, 0.0, -22.0)
		var t2 := create_tween()
		t2.tween_property(tp_sword, "rotation_degrees", base + Vector3(86.0, -28.0, 44.0), 0.09)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t2.tween_property(tp_sword, "rotation_degrees", base, 0.26)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

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
	# Cast kickback (lighter than a melee swing) + a muzzle spark.
	_weapon_kick += Vector3(0.0, 0.02, 0.09)
	if not SettingsManager.reduce_motion:
		_trauma = minf(_trauma + 0.12 * SettingsManager.screen_shake, 1.0)
	var s := MeshFactory.spark(Color(0.5, 0.9, 1.0), 12, 3.0, 0.13)
	get_tree().current_scene.add_child(s)
	s.global_position = origin + forward * 0.4

# ------------------------------------------------------------------- death
func _on_died() -> void:
	# Brief delay then respawn at the last safe point (forgiving prototype).
	_dead = true
	velocity = Vector3.ZERO
	if _hud and _hud.has_method("flash_damage"):
		_hud.flash_damage(true)
	if _hud and _hud.has_method("show_death"):
		_hud.show_death()
	await get_tree().create_timer(1.6).timeout
	_respawn()

func _respawn() -> void:
	teleport(_spawn_point, _yaw)
	GameState.revive_full()
	_dead = false
	_dodge_timer = 0.0
	GameState.player_invuln = false
	_stamina = STAMINA_MAX
	if _hud and _hud.has_method("flash_damage"):
		_hud.flash_damage(false)
	if _hud and _hud.has_method("hide_death"):
		_hud.hide_death()

# --------------------------------------------------------------------- util
func _first_in_group(g: String) -> Node:
	var n := get_tree().get_nodes_in_group(g)
	return n[0] if n.size() > 0 else null
