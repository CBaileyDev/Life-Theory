extends Node3D
## Forest (gameplay level controller)
## Assembles the environment, the procedural world, all entities/interactables,
## the player, and the full UI stack. Owns the two world states and the
## mushroom transformation sequence, applies graphics presets, and handles
## quick save / load.

const PlayerScript := preload("res://scripts/player/Player.gd")
const HUDScript := preload("res://scripts/ui/HUD.gd")
const DialogueScript := preload("res://scripts/ui/DialogueBox.gd")
const PauseScript := preload("res://scripts/ui/PauseMenu.gd")
const UpgradeScript := preload("res://scripts/ui/UpgradeMenu.gd")
const JournalScript := preload("res://scripts/ui/Journal.gd")

var _env: Environment
var _dir: DirectionalLight3D
var _world: WorldBuilder
var _transition_mat: ShaderMaterial
var _fireflies: GPUParticles3D
var _sky_mat: ProceduralSkyMaterial
var _beacon: Node3D
var _beacon_diamond: Node3D
var _player   # untyped: Player is accessed via duck-typing (teleport/fp_camera)
var _transformed := false

func _ready() -> void:
	_build_environment()
	_world = WorldBuilder.new(_quality_density())
	var world_root := Node3D.new()
	world_root.name = "World"
	add_child(world_root)
	_world.build(world_root)
	_place_entities(world_root)
	_build_fireflies()
	_build_transition_overlay()
	_build_beacon()
	_build_ui()
	_spawn_player()

	GameState.world_state_changed.connect(_on_world_changed)
	SettingsManager.graphics_changed.connect(_apply_graphics)
	_apply_graphics(SettingsManager.graphics_quality)

	if GameState.pending_load:
		_restore_save()
	else:
		GameState.broadcast()
		GameState.toast.emit("A quiet forest. A narrow trail. Something glows ahead.")
	AudioManager.play_ambience("forest_day")

# ------------------------------------------------------------- environment
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	_env = Environment.new()
	# Procedural sky for a soft forest-dusk horizon and nicer depth.
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sky_top_color = Color(0.10, 0.16, 0.22)
	_sky_mat.sky_horizon_color = Color(0.30, 0.34, 0.30)
	_sky_mat.ground_horizon_color = Color(0.16, 0.18, 0.15)
	_sky_mat.ground_bottom_color = Color(0.06, 0.08, 0.06)
	_sky_mat.sun_angle_max = 30.0
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	_env.sky = sky
	_env.background_mode = Environment.BG_SKY
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.35, 0.42, 0.40)
	_env.ambient_light_energy = 0.6
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.45, 0.55, 0.52)
	_env.fog_density = 0.018
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_exposure = 1.05
	_env.glow_enabled = true
	_env.glow_intensity = 0.6
	_env.glow_strength = 1.1
	_env.glow_bloom = 0.15
	_env.glow_hdr_threshold = 0.92
	# Cinematic colour grade (cheap GPU adjustment).
	_env.adjustment_enabled = true
	_env.adjustment_brightness = 1.02
	_env.adjustment_contrast = 1.06
	_env.adjustment_saturation = 1.16
	# Volumetric fog base config (enabled only on High in _apply_graphics).
	_env.volumetric_fog_density = 0.018
	_env.volumetric_fog_albedo = Color(0.55, 0.62, 0.60)
	_env.volumetric_fog_emission = Color(0.0, 0.0, 0.0)
	_env.volumetric_fog_gi_inject = 0.3
	we.environment = _env
	add_child(we)

	_dir = DirectionalLight3D.new()
	_dir.rotation_degrees = Vector3(-50, -120, 0)
	_dir.light_color = Color(0.98, 0.95, 0.86)
	_dir.light_energy = 1.0
	_dir.shadow_enabled = true
	add_child(_dir)

func _build_fireflies() -> void:
	_fireflies = GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(12, 3, 12)
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.gravity = Vector3.ZERO
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.5
	mat.color = Color(1.0, 0.9, 0.55, 0.8)
	_fireflies.process_material = mat
	var qm := QuadMesh.new()
	qm.size = Vector2(0.08, 0.08)
	_fireflies.draw_pass_1 = qm
	var fmat := MeshFactory.mat_emissive(Color(1.0, 0.9, 0.5), 4.0, true)
	qm.material = fmat
	_fireflies.amount = 80
	_fireflies.lifetime = 6.0
	_fireflies.position = Vector3(0, 2, 0)
	add_child(_fireflies)

# --------------------------------------------------------------- entities
func _on_ground(pos: Vector3, lift := 0.0) -> Vector3:
	return Vector3(pos.x, _world.height_at(pos.x, pos.z) + lift, pos.z)

func _place_entities(root: Node3D) -> void:
	var shrine := MushroomShrine.new()
	shrine.position = _on_ground(WorldBuilder.SHRINE_POS)
	root.add_child(shrine)

	var auralis := Auralis.new()
	auralis.position = _on_ground(WorldBuilder.AURALIS_POS)
	root.add_child(auralis)

	# A small pack of wisps makes the encounter a real fight.
	var wisp_offsets := [Vector3.ZERO, Vector3(4, 0, 2), Vector3(-3, 0, 4)]
	for off in wisp_offsets:
		var wisp := CorruptedWisp.new()
		wisp.position = _on_ground(WorldBuilder.WISP_HOME + off)
		root.add_child(wisp)

	var stag := LuminousStag.new()
	stag.position = _on_ground(WorldBuilder.STAG_POS, 0.5)
	root.add_child(stag)

	var fi := 0
	for fp in WorldBuilder.FRAGMENT_POS:
		var frag := Fragment.new()
		frag.position = _on_ground(fp)
		frag.index = fi
		root.add_child(frag)
		fi += 1

# ------------------------------------------------------------------- UI
func _build_ui() -> void:
	add_child(HUDScript.new())
	add_child(DialogueScript.new())
	add_child(UpgradeScript.new())
	add_child(JournalScript.new())
	add_child(PauseScript.new())

func _build_transition_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_mat = ShaderMaterial.new()
	var sh := load("res://shaders/screen_transition.gdshader")
	if sh:
		_transition_mat.shader = sh
		_transition_mat.set_shader_parameter("progress", 0.0)
		rect.material = _transition_mat
	layer.add_child(rect)

func _build_beacon() -> void:
	# A glowing vertical beam + bobbing diamond that marks the current
	# objective in 3D (no 2D projection needed; reads correctly off-screen as
	# a glow the player turns toward). Shown only in the First Layer.
	_beacon = Node3D.new()
	_beacon.name = "ObjectiveBeacon"
	add_child(_beacon)
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.18
	cm.height = 16.0
	beam.mesh = cm
	beam.material_override = MeshFactory.mat_emissive(Color(1.0, 0.85, 0.45, 0.5), 2.0, true)
	beam.position.y = 8.0
	_beacon.add_child(beam)
	_beacon_diamond = MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.35
	dm.height = 0.9
	dm.radial_segments = 4
	dm.rings = 2
	_beacon_diamond.mesh = dm
	_beacon_diamond.material_override = MeshFactory.mat_emissive(Color(1.0, 0.9, 0.5), 3.5, true)
	_beacon_diamond.position.y = 2.4
	_beacon.add_child(_beacon_diamond)
	_beacon.visible = false

func _process(delta: float) -> void:
	if not _beacon:
		return
	var pos = _objective_position()
	if pos == null or not _transformed:
		_beacon.visible = false
		return
	_beacon.visible = true
	_beacon.global_position = Vector3(pos.x, _world.height_at(pos.x, pos.z), pos.z)
	var tt := Time.get_ticks_msec() / 1000.0
	_beacon_diamond.position.y = 2.4 + sin(tt * 2.0) * 0.25
	_beacon_diamond.rotation.y += delta * 2.0

func _objective_position():
	var step := GameState.quest_step
	if step == GameState.Step.FOLLOW_TRAIL or step == GameState.Step.MEET_GUIDE:
		return WorldBuilder.AURALIS_POS
	elif step == GameState.Step.COLLECT_FRAGMENTS:
		return _nearest_fragment()
	elif step == GameState.Step.RETURN_SHRINE:
		return WorldBuilder.SHRINE_POS
	return null

func _nearest_fragment():
	var origin := Vector3.ZERO
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		origin = players[0].global_position
	var best = null
	var best_d := INF
	for f in get_tree().get_nodes_in_group("fragment"):
		if f.collected:
			continue
		var d: float = origin.distance_to(f.global_position)
		if d < best_d:
			best_d = d
			best = f.global_position
	return best

func _spawn_player() -> void:
	_player = PlayerScript.new()
	add_child(_player)
	var spawn := _on_ground(WorldBuilder.SPAWN, 1.5)
	_player.teleport(spawn, 0.0)  # yaw 0 -> forward is -Z, toward the clearing
	_player.set_spawn(spawn)

# --------------------------------------------------------- transformation
func _on_world_changed(state: int) -> void:
	if state == GameState.World.FIRST_LAYER and not _transformed:
		_play_transformation()

func _play_transformation() -> void:
	_transformed = true
	AudioManager.play("mushroom_transform")
	AudioManager.play("magic_hum", -4.0)
	_burst_at_shrine()
	# Camera FOV punch.
	var cam = _player.get("fp_camera") if _player else null
	if cam:
		var ct := create_tween()
		ct.tween_property(cam, "fov", 95.0, 0.3)
		ct.tween_property(cam, "fov", 75.0, 0.9)
	# Screen distortion + flash, palette swap at the peak.
	var t := create_tween()
	t.tween_method(_set_transition, 0.0, 1.0, 0.35)
	t.tween_callback(_apply_magical_palette)
	t.tween_callback(_reveal_hidden)
	t.tween_interval(0.1)
	t.tween_method(_set_transition, 1.0, 0.0, 1.3)
	t.tween_callback(_show_title_card)

func _show_title_card() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.modulate.a = 0.0
	layer.add_child(root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	center.add_child(v)
	v.add_child(UITheme.make_title("THE FIRST LAYER", 60))
	var sub := UITheme.make_title(Content.TITLE_CARD_SUB, 20)
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	v.add_child(sub)
	var t := create_tween()
	t.tween_property(root, "modulate:a", 1.0, 0.9)
	t.tween_interval(2.4)
	t.tween_property(root, "modulate:a", 0.0, 1.1)
	t.tween_callback(layer.queue_free)

func _set_transition(v: float) -> void:
	if _transition_mat:
		_transition_mat.set_shader_parameter("progress", v)

func _apply_magical_palette() -> void:
	# Cooler, denser, more luminous.
	var t := create_tween().set_parallel(true)
	t.tween_property(_dir, "light_color", Color(0.6, 0.72, 0.98), 1.0)
	t.tween_property(_dir, "light_energy", 0.7, 1.0)
	t.tween_property(_env, "fog_light_color", Color(0.35, 0.42, 0.62), 1.0)
	t.tween_property(_env, "fog_density", 0.028, 1.0)
	t.tween_property(_env, "ambient_light_color", Color(0.30, 0.36, 0.52), 1.0)
	if _sky_mat:
		t.tween_property(_sky_mat, "sky_top_color", Color(0.10, 0.06, 0.20), 1.5)
		t.tween_property(_sky_mat, "sky_horizon_color", Color(0.24, 0.20, 0.42), 1.5)
		t.tween_property(_sky_mat, "ground_horizon_color", Color(0.14, 0.12, 0.24), 1.5)
	_env.glow_intensity = 0.95
	_env.adjustment_saturation = 1.28
	_env.volumetric_fog_emission = Color(0.16, 0.10, 0.30)
	_env.volumetric_fog_albedo = Color(0.45, 0.50, 0.66)
	# Fireflies turn cool and multiply.
	var ppm := _fireflies.process_material as ParticleProcessMaterial
	if ppm:
		ppm.color = Color(0.6, 0.85, 1.0, 0.85)
		_fireflies.amount = int(_fireflies.amount * 1.5)

func _reveal_hidden() -> void:
	for i in _world.trail_markers.size():
		var m: Node3D = _world.trail_markers[i]
		m.visible = true
		m.scale = Vector3(0.1, 0.1, 0.1)
		var tw := create_tween()
		tw.tween_interval(i * 0.03)
		tw.tween_property(m, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for q in _world.rune_quads:
		q.visible = true

func _burst_at_shrine() -> void:
	var p := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.UP
	mat.spread = 180.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -1.5, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.4
	mat.color = Color(0.6, 1.0, 0.85)
	p.process_material = mat
	var qm := QuadMesh.new()
	qm.size = Vector2(0.25, 0.25)
	qm.material = MeshFactory.mat_emissive(Color(0.6, 1.0, 0.85), 4.0, true)
	p.draw_pass_1 = qm
	p.amount = 120
	p.lifetime = 1.6
	p.one_shot = true
	p.explosiveness = 0.85
	p.emitting = true
	p.position = WorldBuilder.SHRINE_POS + Vector3(0, 1.2, 0)
	add_child(p)
	get_tree().create_timer(2.5).timeout.connect(p.queue_free)

# ------------------------------------------------------------- graphics
func _quality_density() -> float:
	var q := SettingsManager.graphics_quality
	if q == SettingsManager.Quality.LOW:
		return 0.55
	elif q == SettingsManager.Quality.HIGH:
		return 1.2
	return 0.85

func _apply_graphics(quality: int) -> void:
	var vp := get_viewport()
	if quality == SettingsManager.Quality.LOW:
		_dir.shadow_enabled = false
		_env.glow_enabled = false
		_env.ssao_enabled = false
		_env.volumetric_fog_enabled = false
		vp.msaa_3d = Viewport.MSAA_DISABLED
	elif quality == SettingsManager.Quality.HIGH:
		_dir.shadow_enabled = true
		_env.glow_enabled = true
		_env.ssao_enabled = true
		_env.volumetric_fog_enabled = true   # soft light shafts in the mist
		vp.msaa_3d = Viewport.MSAA_4X
	else:  # Medium (default)
		_dir.shadow_enabled = true
		_env.glow_enabled = true
		_env.ssao_enabled = false
		_env.volumetric_fog_enabled = false
		vp.msaa_3d = Viewport.MSAA_2X
	# Note: foliage/tree density is chosen at build time via _quality_density();
	# changing quality mid-run updates lighting/AA immediately and full density
	# on the next entry to the forest.

# ---------------------------------------------------------------- save/load
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save"):
		SaveManager.save_game()
		GameState.toast.emit("Progress saved.")
	elif event.is_action_pressed("quick_load"):
		_restore_save()
		GameState.toast.emit("Progress loaded.")

func _restore_save() -> void:
	var data := SaveManager.load_game()
	if data.is_empty():
		GameState.broadcast()
		return
	GameState.from_dict(data)
	if data.has("player_position") and _player:
		_player.teleport(data["player_position"], data.get("player_yaw", 0.0))
	# Restore which specific fragments were already collected.
	var collected: Array = data.get("fragments_collected", [])
	if collected.size() > 0:
		for f in get_tree().get_nodes_in_group("fragment"):
			if f.index in collected:
				f.set_collected_silently()
	# If we load into the First Layer, snap the palette/hidden layer on without
	# replaying the transformation animation.
	if GameState.world == GameState.World.FIRST_LAYER:
		_transformed = true
		_apply_magical_palette()
		_reveal_hidden()
	GameState.broadcast()
