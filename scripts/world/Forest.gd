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
const SightScript := preload("res://scripts/systems/SightController.gd")

var _env: Environment
var _dir: DirectionalLight3D
var _world: WorldBuilder
var _transition_mat: ShaderMaterial
var _transition_rect: ColorRect
var _fireflies: GPUParticles3D
var _sky_mat: ProceduralSkyMaterial
var _beacon: Node3D
var _beacon_diamond: Node3D
var _player   # untyped: Player is accessed via duck-typing (teleport/fp_camera)
var _transformed := false
var _base_ambient_energy := 1.0          # natural ambient (depends on HDRI vs procedural sky)
var _transform_tweens: Array[Tween] = [] # tracked so a quick-load can cancel them
const _FIREFLY_BASE_AMOUNT := 80

func _ready() -> void:
	_build_environment()
	_world = WorldBuilder.new(_quality_density(), GameState.current_biome, _quality_cull_mult())
	var world_root := Node3D.new()
	world_root.name = "World"
	add_child(world_root)
	_world.build(world_root)
	_place_entities(world_root)
	_build_fireflies()
	_build_atmosphere_motes()
	_build_pond_sound()
	_build_transition_overlay()
	_build_beacon()
	_build_ui()
	_spawn_player()
	_build_vista_trigger()
	_build_pond_trigger()

	GameState.world_state_changed.connect(_on_world_changed)
	SettingsManager.graphics_changed.connect(_apply_graphics)
	_apply_graphics(SettingsManager.graphics_quality)

	if GameState.pending_load:
		_restore_save()
	elif GameState.current_biome == GameState.Biome.LOOMSTRATA:
		# Descended into the layer beneath — already magical, themed deeper.
		_transformed = true
		_apply_magical_palette(true)
		_reveal_hidden(true)
		GameState.broadcast()
		GameState.toast.emit("You descend. The Loomstrata hums beneath the forest.")
		# Auralis marks the arrival with a short orientation once the scene settles.
		get_tree().create_timer(2.0).timeout.connect(func():
			GameState.request_dialogue("Auralis", Content.LOOMSTRATA_ARRIVAL))
	else:
		GameState.broadcast()
		GameState.toast.emit("A quiet forest. A narrow trail. Something glows ahead.")
	AudioManager.play_ambience("loomstrata" if GameState.current_biome == GameState.Biome.LOOMSTRATA else "forest_day")
	AudioManager.play_music("layer" if GameState.world == GameState.World.FIRST_LAYER else "calm")
	_start_ambient_life()

# Occasional birdsong / wind gusts layered over the ambience bed.
var _amb_timer: Timer

func _start_ambient_life() -> void:
	_amb_timer = Timer.new()
	_amb_timer.one_shot = true
	add_child(_amb_timer)
	_amb_timer.timeout.connect(_ambient_tick)
	_amb_timer.start(randf_range(3.0, 6.0))

func _ambient_tick() -> void:
	if randf() < 0.6:
		AudioManager.play("bird", -14.0, randf_range(0.9, 1.2))
	else:
		AudioManager.play("wind", -16.0)
	_amb_timer.start(randf_range(5.0, 11.0))

# ------------------------------------------------------------- environment
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	_env = Environment.new()
	var sky := Sky.new()
	# Real image-based lighting: a CC0 HDRI panorama lights and reflects on the
	# whole scene (the biggest realism lever). Falls back to a procedural sky.
	# A clean daytime SKY panorama (not the old forest panorama, which made the
	# canopy open onto "a forest within a forest"). Real blue sky + clouds.
	var hdr_path := "res://assets/hdri/sky_day.hdr"
	if not ResourceLoader.exists(hdr_path):
		hdr_path = "res://assets/hdri/forest_sky.hdr"
	if ResourceLoader.exists(hdr_path):
		var psm := PanoramaSkyMaterial.new()
		psm.panorama = load(hdr_path)
		sky.sky_material = psm
		_sky_mat = null
		_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		_env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		# Fixed WARM fill, NOT sky-derived: the HDR-bright blue sky would otherwise
		# tint the shadowed forest floor blue (it read as see-through water).
		_env.ambient_light_color = Color(0.50, 0.52, 0.43)
		_env.ambient_light_sky_contribution = 0.0
		_env.ambient_light_energy = 1.0
		_base_ambient_energy = 1.0
	else:
		_sky_mat = ProceduralSkyMaterial.new()
		_sky_mat.sky_top_color = Color(0.10, 0.16, 0.22)
		_sky_mat.sky_horizon_color = Color(0.30, 0.34, 0.30)
		_sky_mat.ground_horizon_color = Color(0.16, 0.18, 0.15)
		_sky_mat.ground_bottom_color = Color(0.06, 0.08, 0.06)
		_sky_mat.sun_angle_max = 30.0
		sky.sky_material = _sky_mat
		_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		_env.ambient_light_color = Color(0.35, 0.42, 0.40)
		_env.ambient_light_energy = 0.6
		_base_ambient_energy = 0.6
	_env.sky = sky
	_env.background_mode = Environment.BG_SKY
	# Fog as a gentle DEPTH CUE, not a wall. Warm sage tint, low density, with
	# aerial perspective + sun in-scatter so distance reads as haze and the sun
	# side glows (cheap god-ray feel). The old teal 0.018 wall is gone.
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	_env.fog_light_color = Color(0.72, 0.74, 0.64)
	_env.fog_light_energy = 1.0
	_env.fog_density = 0.004
	_env.fog_sun_scatter = 0.16
	_env.fog_aerial_perspective = 0.5
	_env.fog_sky_affect = 0.3
	_env.tonemap_mode = Environment.TONE_MAPPER_AGX
	_env.tonemap_exposure = 1.1
	_env.tonemap_white = 6.0
	_env.glow_enabled = true
	_env.glow_intensity = 0.42
	_env.glow_strength = 1.0
	_env.glow_bloom = 0.06
	_env.glow_hdr_threshold = 1.05
	# Cinematic colour grade (cheap GPU adjustment).
	_env.adjustment_enabled = true
	_env.adjustment_brightness = 1.02
	_env.adjustment_contrast = 1.06
	_env.adjustment_saturation = 1.16
	# Volumetric fog base config (enabled only on High in _apply_graphics).
	# Density is deliberately LOW — at 0.018 the fog accumulated into an opaque
	# brown murk wall across a ~50 m horizontal sightline; 0.005 gives soft light
	# shafts in the mist without swallowing the view. Length is bounded too.
	_env.volumetric_fog_density = 0.005
	_env.volumetric_fog_length = 48.0
	_env.volumetric_fog_albedo = Color(0.62, 0.66, 0.60)
	_env.volumetric_fog_emission = Color(0.0, 0.0, 0.0)
	_env.volumetric_fog_gi_inject = 0.4
	# The Loomstrata is beneath the forest — its canopy opens onto void, not a
	# blue daytime sky. Dark background + no sky reflection; the cool magical
	# palette and the glowing wireframe seams read against the dark.
	if GameState.current_biome == GameState.Biome.LOOMSTRATA:
		_env.background_mode = Environment.BG_COLOR
		_env.background_color = Color(0.018, 0.014, 0.045)
		_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		_env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
		_env.ambient_light_energy = 0.7
	we.environment = _env
	add_child(we)

	_dir = DirectionalLight3D.new()
	# Low warm sun raking through the trees → long shadows + god-ray scatter.
	_dir.rotation_degrees = Vector3(-38, -115, 0)
	_dir.light_color = Color(1.0, 0.93, 0.78)
	_dir.light_energy = 1.5
	_dir.light_angular_distance = 1.2   # softer shadow penumbra
	_dir.shadow_enabled = true
	_dir.shadow_blur = 1.2
	# Bound the shadow frustum to just past the playable bowl (AREA 24 + giant ring
	# 26 + margin) so the PSSM splits pack sharp shadows into the area that matters
	# instead of spreading over the ~100m default — sharper + cheaper.
	_dir.directional_shadow_max_distance = 58.0
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

## Slow daytime pollen/dust drifting through the air — specks that catch the
## sun and give the volume of the forest weight. Cheap; one GPUParticles batch.
## Positional water ambience at the pond — grows audible as you approach it.
func _build_pond_sound() -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = SfxSynth.water_loop()
	p.bus = "Ambience"
	p.unit_size = 5.0
	p.max_distance = 24.0
	p.volume_db = -9.0
	p.position = Vector3(WorldBuilder.POND.x, WorldBuilder.WATER_LEVEL + 0.2, WorldBuilder.POND.z)
	add_child(p)
	p.play()

func _build_atmosphere_motes() -> void:
	var motes := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(24, 6, 24)
	mat.direction = Vector3(0.4, -0.2, 0.1)   # a faint prevailing drift
	mat.spread = 80.0
	mat.gravity = Vector3(0.1, -0.15, 0.0)
	mat.initial_velocity_min = 0.05
	mat.initial_velocity_max = 0.25
	mat.scale_min = 0.5
	mat.scale_max = 1.4
	mat.color = Color(0.95, 0.9, 0.72, 0.5)
	motes.process_material = mat
	var qm := QuadMesh.new()
	qm.size = Vector2(0.05, 0.05)
	qm.material = MeshFactory.mat_emissive(Color(1.0, 0.95, 0.78), 2.2, true)
	motes.draw_pass_1 = qm
	motes.amount = 220
	motes.lifetime = 12.0
	motes.preprocess = 6.0   # already drifting when the scene opens
	motes.position = Vector3(0, 5, 0)
	add_child(motes)

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

	# A mixed pack — two Corrupted Wisps and one Dimmer (blinds you) — so the
	# fight has a priority target and isn't three identical threats.
	var wisp_specs := [[Vector3.ZERO, false], [Vector3(4, 0, 2), false], [Vector3(-3, 0, 4), true]]
	for spec in wisp_specs:
		var w: CorruptedWisp = Dimmer.new() if spec[1] else CorruptedWisp.new()
		w.position = _on_ground(WorldBuilder.WISP_HOME + spec[0])
		root.add_child(w)
		w.set_height_sampler(_world.height_at)

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
	add_child(SightScript.new())
	add_child(JournalScript.new())
	add_child(PauseScript.new())

func _build_transition_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	_transition_rect = ColorRect.new()
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The transition shader reads the screen texture (forces a back-buffer copy +
	# fullscreen pass). It only runs for ~1.5s during the transformation, so keep
	# the rect hidden — and therefore skipped — the rest of the time.
	_transition_rect.visible = false
	_transition_mat = ShaderMaterial.new()
	var sh := load("res://shaders/screen_transition.gdshader")
	if sh:
		_transition_mat.shader = sh
		_transition_mat.set_shader_parameter("progress", 0.0)
		_transition_rect.material = _transition_mat
	layer.add_child(_transition_rect)

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

var _combat_music_on := false
var _music_check_t := 0.0

func _process(delta: float) -> void:
	_update_combat_music(delta)
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

## Crossfade to the tense combat theme while any wisp is actively hunting, and
## back to the layer theme once the clearing is safe again. Polled (cheap), only
## in the First Layer where wisps exist.
func _update_combat_music(delta: float) -> void:
	if GameState.world != GameState.World.FIRST_LAYER:
		return
	_music_check_t -= delta
	if _music_check_t > 0.0:
		return
	_music_check_t = 0.6
	var hostile := false
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is CorruptedWisp and (e.state == CorruptedWisp.State.CHASE or e.state == CorruptedWisp.State.ATTACK):
			hostile = true
			break
	if hostile and not _combat_music_on:
		_combat_music_on = true
		AudioManager.play_music("combat")
	elif not hostile and _combat_music_on:
		_combat_music_on = false
		AudioManager.play_music("layer")

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

var _vista_seen := false

## A trigger on the Cairn-Ridge overlook: the first time the player climbs to it,
## Auralis names the seam below (the framed-vista beat). Quietwood only.
func _build_vista_trigger() -> void:
	if GameState.current_biome != GameState.Biome.QUIETWOOD:
		return
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 4.5
	cs.shape = sph
	area.add_child(cs)
	area.position = Vector3(WorldBuilder.RIDGE.x,
		_world.height_at(WorldBuilder.RIDGE.x, WorldBuilder.RIDGE.z) + 1.5, WorldBuilder.RIDGE.z)
	add_child(area)
	area.body_entered.connect(func(b: Node) -> void:
		if _vista_seen or not b.is_in_group("player"):
			return
		_vista_seen = true
		GameState.request_dialogue("Auralis", Content.VISTA_REVEAL)
		GameState.toast.emit("A seam in the world, far below."))

var _pond_seen := false

## Auralis muses the first time the player reaches the quiet pond (Quietwood).
func _build_pond_trigger() -> void:
	if GameState.current_biome != GameState.Biome.QUIETWOOD:
		return
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 6.0
	cs.shape = sph
	area.add_child(cs)
	area.position = Vector3(WorldBuilder.POND.x, WorldBuilder.WATER_LEVEL + 1.0, WorldBuilder.POND.z)
	add_child(area)
	area.body_entered.connect(func(b: Node) -> void:
		if _pond_seen or not b.is_in_group("player"):
			return
		_pond_seen = true
		GameState.request_dialogue("Auralis", Content.POND_MUSING))

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
	AudioManager.play_music("layer")
	AudioManager.play("mushroom_transform")
	AudioManager.play("magic_hum", -4.0)
	_burst_at_shrine()
	# Camera FOV punch — claim the FOV from the sprint-FOV lerp for the beat, then
	# release it (ending at the player's real FOV setting, not a hardcoded value).
	var cam = _player.get("fp_camera") if _player else null
	if cam and _player and _player.has_method("set_fov_cinematic"):
		_player.set_fov_cinematic(true)
		var ct := _track(create_tween())
		ct.tween_property(cam, "fov", 96.0, 0.3).set_trans(Tween.TRANS_SINE)
		ct.tween_property(cam, "fov", SettingsManager.fov, 1.0).set_trans(Tween.TRANS_SINE)
		ct.tween_callback(func(): if _player: _player.set_fov_cinematic(false))
	# Screen distortion + flash, palette swap at the peak.
	var t := _track(create_tween())
	t.tween_method(_set_transition, 0.0, 1.0, 0.35)
	t.tween_callback(_apply_magical_palette)
	t.tween_callback(_reveal_hidden)
	t.tween_interval(0.1)
	t.tween_method(_set_transition, 1.0, 0.0, 1.3)
	t.tween_callback(_show_title_card)

func _track(t: Tween) -> Tween:
	_transform_tweens.append(t)
	return t

func _kill_transform_tweens() -> void:
	for t in _transform_tweens:
		if t and t.is_valid():
			t.kill()
	_transform_tweens.clear()

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
	if _transition_rect:
		_transition_rect.visible = v > 0.001
	if _transition_mat:
		_transition_mat.set_shader_parameter("progress", v)

func _apply_magical_palette(instant := false) -> void:
	# Cooler, denser, more luminous. Tweened during the live transformation;
	# applied instantly when restoring a save that's already in the First Layer.
	if instant:
		_dir.light_color = Color(0.6, 0.72, 0.98)
		_dir.light_energy = 0.85
		_env.fog_light_color = Color(0.40, 0.46, 0.66)
		_env.fog_density = 0.008
		_env.fog_sun_scatter = 0.15
		_env.ambient_light_color = Color(0.30, 0.36, 0.52)
		_env.ambient_light_energy = 0.6
		if _sky_mat:
			_sky_mat.sky_top_color = Color(0.10, 0.06, 0.20)
			_sky_mat.sky_horizon_color = Color(0.24, 0.20, 0.42)
			_sky_mat.ground_horizon_color = Color(0.14, 0.12, 0.24)
	else:
		var t := _track(create_tween().set_parallel(true))
		t.tween_property(_dir, "light_color", Color(0.6, 0.72, 0.98), 1.0)
		t.tween_property(_dir, "light_energy", 0.85, 1.0)
		t.tween_property(_env, "fog_light_color", Color(0.40, 0.46, 0.66), 1.0)
		t.tween_property(_env, "fog_density", 0.008, 1.0)
		t.tween_property(_env, "ambient_light_color", Color(0.30, 0.36, 0.52), 1.0)
		t.tween_property(_env, "ambient_light_energy", 0.55, 1.5)
		if _sky_mat:
			t.tween_property(_sky_mat, "sky_top_color", Color(0.10, 0.06, 0.20), 1.5)
			t.tween_property(_sky_mat, "sky_horizon_color", Color(0.24, 0.20, 0.42), 1.5)
			t.tween_property(_sky_mat, "ground_horizon_color", Color(0.14, 0.12, 0.24), 1.5)
	_env.glow_intensity = 0.95
	_env.adjustment_saturation = 1.28
	_env.volumetric_fog_emission = Color(0.16, 0.10, 0.30)
	_env.volumetric_fog_albedo = Color(0.45, 0.50, 0.66)
	# Fireflies turn cool and denser. Absolute count (not *1.5 each call) so a
	# load doesn't keep multiplying the swarm.
	var ppm := _fireflies.process_material as ParticleProcessMaterial
	if ppm:
		ppm.color = Color(0.6, 0.85, 1.0, 0.85)
	_fireflies.amount = int(_FIREFLY_BASE_AMOUNT * 1.5)

## Instantly restore the natural (pre-transformation) look — used when a save
## from the natural forest is loaded after the world had already turned magical.
func _apply_natural_palette() -> void:
	_dir.light_color = Color(1.0, 0.93, 0.78)
	_dir.light_energy = 1.5
	_env.fog_light_color = Color(0.72, 0.74, 0.64)
	_env.fog_density = 0.0045
	_env.fog_sun_scatter = 0.3
	_env.ambient_light_color = Color(0.50, 0.52, 0.43)
	_env.ambient_light_energy = _base_ambient_energy
	_env.glow_intensity = 0.6
	_env.adjustment_saturation = 1.16
	_env.volumetric_fog_emission = Color(0.0, 0.0, 0.0)
	_env.volumetric_fog_albedo = Color(0.55, 0.62, 0.60)
	if _sky_mat:
		_sky_mat.sky_top_color = Color(0.10, 0.16, 0.22)
		_sky_mat.sky_horizon_color = Color(0.30, 0.34, 0.30)
		_sky_mat.ground_horizon_color = Color(0.16, 0.18, 0.15)
	var ppm := _fireflies.process_material as ParticleProcessMaterial
	if ppm:
		ppm.color = Color(1.0, 0.9, 0.55, 0.8)
	_fireflies.amount = _FIREFLY_BASE_AMOUNT

func _reveal_hidden(instant := false) -> void:
	for i in _world.trail_markers.size():
		var m: Node3D = _world.trail_markers[i]
		m.visible = true
		if instant:
			m.scale = Vector3.ONE
		else:
			m.scale = Vector3(0.1, 0.1, 0.1)
			var tw := _track(create_tween())
			tw.tween_interval(i * 0.03)
			tw.tween_property(m, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for q in _world.rune_quads:
		q.visible = true

## Re-hide the magical layer (trail markers + runes) — used when a natural-world
## save is loaded after the layer had been revealed.
func _hide_hidden() -> void:
	for m in _world.trail_markers:
		m.visible = false
	for q in _world.rune_quads:
		q.visible = false

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

func _quality_cull_mult() -> float:
	# How far scatter renders before fading out. Low pulls foliage in to recover
	# fill rate on weak GPUs; High extends draw distance for desktop cards.
	var q := SettingsManager.graphics_quality
	if q == SettingsManager.Quality.LOW:
		return 0.6
	elif q == SettingsManager.Quality.HIGH:
		return 1.15
	return 0.85

func _apply_graphics(quality: int) -> void:
	var vp := get_viewport()
	if quality == SettingsManager.Quality.LOW:
		_dir.shadow_enabled = false
		_env.glow_enabled = false
		_env.ssao_enabled = false
		_env.volumetric_fog_enabled = false
		vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.use_taa = false
	elif quality == SettingsManager.Quality.HIGH:
		_dir.shadow_enabled = true
		# Four-split PSSM @ 2048 — crisp shadows for desktop GPUs.
		_dir.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		RenderingServer.directional_shadow_atlas_set_size(2048, true)
		_env.glow_enabled = true
		_env.ssao_enabled = true
		# Volumetric fog is intentionally OFF: even at low density it accumulated
		# into an opaque brown murk across the forest's long sightlines. Soft light
		# shafts come from fog_sun_scatter instead — god-rays without the murk.
		_env.volumetric_fog_enabled = false
		# 2X MSAA + TAA instead of 4X: TAA resolves sub-pixel foliage shimmer far
		# better than MSAA (which barely helps alpha-tested edges) and is cheaper.
		vp.msaa_3d = Viewport.MSAA_2X
		vp.use_taa = true
	else:  # Medium (default)
		_dir.shadow_enabled = true
		# Two-split @ 1536 — roughly half the shadow cost of High's 4 splits while
		# still reading as real grounded shadows.
		_dir.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		RenderingServer.directional_shadow_atlas_set_size(1536, true)
		_env.glow_enabled = true
		_env.ssao_enabled = false
		_env.volumetric_fog_enabled = false
		vp.msaa_3d = Viewport.MSAA_2X
		vp.use_taa = false
	# Note: foliage/tree density is chosen at build time via _quality_density();
	# changing quality mid-run updates lighting/AA immediately and full density
	# on the next entry to the forest. Render scale is a separate user lever
	# (SettingsManager.render_scale) so presets never fight the Render Scale slider.

# ---------------------------------------------------------------- save/load
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save"):
		SaveManager.save_game()
		GameState.toast.emit("Progress saved.")
	elif event.is_action_pressed("quick_load"):
		_restore_save()
		GameState.toast.emit("Progress loaded.")

func _restore_save() -> void:
	# Cancel any in-flight transformation tweens first so a mid-transformation
	# quick-load can't keep animating over the freshly-loaded state.
	_kill_transform_tweens()
	var data := SaveManager.load_game()
	if data.is_empty():
		GameState.broadcast()
		return
	GameState.from_dict(data)
	if data.has("player_position") and _player:
		_player.teleport(data["player_position"], data.get("player_yaw", 0.0))
	# Restore which specific fragments were already collected. collected_ids is the
	# single source of truth (see GameState.from_dict / SaveManager).
	for f in get_tree().get_nodes_in_group("fragment"):
		if f.index in GameState.collected_ids:
			f.set_collected_silently()
	# Snap the world look to the loaded state INSTANTLY (both directions), so
	# loading never replays the animation nor strands the magical palette.
	_set_transition(0.0)
	if GameState.world == GameState.World.FIRST_LAYER:
		_transformed = true
		_apply_magical_palette(true)
		_reveal_hidden(true)
	else:
		_transformed = false
		_apply_natural_palette()
		_hide_hidden()
	GameState.broadcast()
