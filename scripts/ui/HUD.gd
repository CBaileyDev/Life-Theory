extends CanvasLayer
## HUD
## Quest objective, fragment counter, health bar, interaction prompt, and
## transient toast messages. Pure-code, dark-fantasy styling. Listens to
## GameState so it always reflects the live run.

const BAR_W := 224.0
var _quest_label: Label
var _fragment_label: Label
var _fragment_panel: Control
var _prompt_label: Label
var _health_fill: Panel
var _health_label: Label
var _toast_label: Label
var _damage_vignette: ColorRect
var _dim_overlay: ColorRect
var _dim_tween: Tween
var _dmg_dir: Label
var _dmg_dir_tween: Tween
var _toast_tween: Tween
var _health_tween: Tween
var _stamina_fill: Panel
var _sight_box: VBoxContainer
var _lucidity_fill: Panel
var _desync_fill: Panel
var _reagent_label: Label
var _crosshair: Control
var _hitmarker: Label
var _death_overlay: ColorRect
var _death_label: Label
var _fps_label: Label
var _fps_accum := 0.0
var _fps_last := -1

func _ready() -> void:
	add_to_group("hud")
	_build()
	GameState.quest_step_changed.connect(_on_quest_changed)
	GameState.fragments_changed.connect(_on_fragments_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.toast.connect(show_toast)
	GameState.lucidity_changed.connect(_on_lucidity_changed)
	GameState.desync_changed.connect(_on_desync_changed)
	GameState.reagents_changed.connect(_on_reagents_changed)
	GameState.dim_applied.connect(_on_dim_applied)
	GameState.player_damaged.connect(_on_player_damaged_dir)
	SettingsManager.show_fps_changed.connect(_on_show_fps_changed)
	GameState.broadcast()

## Point a red wedge toward the attacker for ~0.9s (relative to where you face).
func _on_player_damaged_dir(_amount: float, from_pos: Vector3) -> void:
	if not _dmg_dir or from_pos == Vector3.INF:
		return
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	# Source in camera space: +x right, looking down -z. theta=0 → straight ahead.
	var local := cam.global_transform.affine_inverse() * from_pos
	var theta := atan2(local.x, -local.z)
	_dmg_dir.rotation = theta
	var c := get_viewport().get_visible_rect().size * 0.5
	_dmg_dir.position = c + Vector2(sin(theta), -cos(theta)) * 165.0 - _dmg_dir.size * 0.5
	_dmg_dir.modulate.a = 0.9
	if _dmg_dir_tween and _dmg_dir_tween.is_valid():
		_dmg_dir_tween.kill()
	_dmg_dir_tween = create_tween()
	_dmg_dir_tween.tween_property(_dmg_dir, "modulate:a", 0.0, 0.9)

func _on_dim_applied(duration: float) -> void:
	if not _dim_overlay or SettingsManager.reduce_motion:
		return
	if _dim_tween and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_overlay.color.a = 0.55
	_dim_tween = create_tween()
	_dim_tween.tween_property(_dim_overlay, "color:a", 0.0, maxf(duration, 0.3))

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Cinematic vignette (always-on, darkens the frame edges).
	var vg := GradientTexture2D.new()
	var vgrad := Gradient.new()
	vgrad.set_color(0, Color(0, 0, 0, 0))
	vgrad.set_color(1, Color(0, 0, 0, 0.42))
	vg.gradient = vgrad
	vg.fill = GradientTexture2D.FILL_RADIAL
	vg.fill_from = Vector2(0.5, 0.5)
	vg.fill_to = Vector2(1.0, 0.5)
	var vignette := TextureRect.new()
	vignette.texture = vg
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

	# Damage vignette (hidden until hurt).
	_damage_vignette = ColorRect.new()
	_damage_vignette.color = Color(0.6, 0.05, 0.05, 0.0)
	_damage_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_damage_vignette)

	# Dim overlay — a Dimmer's strike clouds your vision (darkens, then clears).
	_dim_overlay = ColorRect.new()
	_dim_overlay.color = Color(0.03, 0.04, 0.10, 0.0)
	_dim_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_dim_overlay)

	# Quest panel (top-left).
	var quest_panel := UITheme.make_panel()
	quest_panel.position = Vector2(20, 20)
	quest_panel.custom_minimum_size = Vector2(360, 0)
	root.add_child(quest_panel)
	var qbox := VBoxContainer.new()
	quest_panel.add_child(qbox)
	qbox.add_child(UITheme.make_label("THE FIRST LAYER", 14, UITheme.ACCENT))
	_quest_label = UITheme.make_label("", 17)
	_quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_label.custom_minimum_size = Vector2(328, 0)
	qbox.add_child(_quest_label)

	# Fragment counter (top-right).
	_fragment_panel = UITheme.make_panel()
	_fragment_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fragment_panel.position = Vector2(-200, 20)
	_fragment_panel.visible = false
	root.add_child(_fragment_panel)
	_fragment_label = UITheme.make_label("Fragments  0/3", 18, UITheme.GOLD)
	_fragment_panel.add_child(_fragment_label)

	# Health bar (bottom-left). Pin the BOTTOM edge ~20px above the screen bottom
	# and grow UPWARD, so it never clips off-screen as the Sight meters appear.
	var hp_panel := UITheme.make_panel()
	hp_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hp_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hp_panel.offset_left = 20
	hp_panel.offset_bottom = -20
	root.add_child(hp_panel)
	var hbox := VBoxContainer.new()
	hp_panel.add_child(hbox)
	hbox.add_theme_constant_override("separation", 5)
	_health_fill = UITheme.make_stat_bar(hbox, "Vitality", BAR_W, 14.0, Color(0.80, 0.30, 0.32))
	# Stamina bar (under health).
	_stamina_fill = _make_sub_bar(hbox, "Stamina", Color(0.40, 0.66, 0.80))
	# Sight meters (hidden until the Sight is unlocked).
	_sight_box = VBoxContainer.new()
	_sight_box.visible = false
	hbox.add_child(_sight_box)
	_lucidity_fill = _make_sub_bar(_sight_box, "Lucidity", Color(0.4, 0.85, 1.0))
	_desync_fill = _make_sub_bar(_sight_box, "Desync", Color(0.9, 0.3, 0.7))
	_reagent_label = UITheme.make_label("Lucid Caps  0    [Q] Sight  [R] use", 12, UITheme.GOLD)
	_sight_box.add_child(_reagent_label)

	# Directional damage indicator — a red wedge that points toward the attacker
	# (huge readability win with multiple enemies). Hidden until hit.
	_dmg_dir = UITheme.make_label("▲", 40, Color(1.0, 0.3, 0.3))
	_dmg_dir.set_anchors_preset(Control.PRESET_CENTER)
	_dmg_dir.custom_minimum_size = Vector2(48, 48)
	_dmg_dir.size = Vector2(48, 48)
	_dmg_dir.pivot_offset = Vector2(24, 24)
	_dmg_dir.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dmg_dir.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dmg_dir.modulate.a = 0.0
	root.add_child(_dmg_dir)

	# Crosshair (centre dot) + hitmarker.
	_crosshair = UITheme.make_crosshair()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.position = Vector2(-2.5, -2.5)
	root.add_child(_crosshair)
	_hitmarker = UITheme.make_label("✕", 28, Color(1.0, 0.5, 0.5))
	_hitmarker.set_anchors_preset(Control.PRESET_CENTER)
	_hitmarker.position = Vector2(-10, -18)
	_hitmarker.modulate.a = 0.0
	root.add_child(_hitmarker)

	# Interaction prompt (bottom-center).
	_prompt_label = UITheme.make_label("", 18, UITheme.ACCENT)
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.position = Vector2(0, -110)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_prompt_label)

	# Toast (center, fades).
	_toast_label = UITheme.make_label("", 22, UITheme.GOLD)
	_toast_label.set_anchors_preset(Control.PRESET_CENTER)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.modulate.a = 0.0
	root.add_child(_toast_label)

	# Death overlay (hidden until the player falls).
	# Death is the Forgetting smoothing you — a pale white wash, not a dark fade.
	_death_overlay = ColorRect.new()
	_death_overlay.color = Color(0.88, 0.89, 0.95, 0.0)
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_death_overlay)
	_death_label = UITheme.make_title("The Forgetting smooths the hurt away.", 34)
	_death_label.add_theme_color_override("font_color", Color(0.12, 0.13, 0.20))
	_death_label.set_anchors_preset(Control.PRESET_CENTER)
	_death_label.modulate.a = 0.0
	root.add_child(_death_label)

	# FPS counter (bottom-right; toggle with F3 or in Settings). Off by default.
	_fps_label = UITheme.make_label("", 14, UITheme.TEXT_DIM)
	_fps_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_fps_label.position = Vector2(-104, -30)
	_fps_label.custom_minimum_size = Vector2(84, 0)
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.visible = SettingsManager.show_fps
	root.add_child(_fps_label)

func _make_sub_bar(parent: VBoxContainer, label: String, color: Color) -> Panel:
	return UITheme.make_stat_bar(parent, label, BAR_W, 11.0, color)

func _bar_sb(bar: Panel) -> StyleBoxFlat:
	return bar.get_theme_stylebox("panel") as StyleBoxFlat

# ---------------------------------------------------------------- fps counter
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fps"):
		SettingsManager.toggle_show_fps()
		get_viewport().set_input_as_handled()

func _on_show_fps_changed(on: bool) -> void:
	if _fps_label:
		_fps_label.visible = on
		_fps_last = -1  # force a refresh next frame

func _process(delta: float) -> void:
	if not _fps_label or not _fps_label.visible:
		return
	# Throttle to ~5 Hz; only touch the label (a string alloc) when it changes.
	_fps_accum += delta
	if _fps_accum < 0.2:
		return
	_fps_accum = 0.0
	var fps := int(round(Engine.get_frames_per_second()))
	if fps == _fps_last:
		return
	_fps_last = fps
	_fps_label.text = "%d FPS" % fps
	# Green = comfortably above target, gold = around the 30 fps floor, red = below.
	var col := Color(0.55, 0.85, 0.55)
	if fps < 30:
		col = Color(0.9, 0.4, 0.4)
	elif fps < 50:
		col = UITheme.GOLD
	_fps_label.add_theme_color_override("font_color", col)

# ------------------------------------------------------------------ external
func set_prompt(text: String) -> void:
	if _prompt_label:
		_prompt_label.text = text

func set_stamina(frac: float) -> void:
	if _stamina_fill:
		_stamina_fill.size.x = BAR_W * clampf(frac, 0.0, 1.0)

func _on_lucidity_changed(lucidity: float, maxv: float) -> void:
	if _lucidity_fill:
		_lucidity_fill.size.x = BAR_W * clampf(lucidity / maxv, 0.0, 1.0)
	_refresh_sight_vis()

func _on_desync_changed(desync: float, maxv: float) -> void:
	if _desync_fill:
		var r := clampf(desync / maxv, 0.0, 1.0)
		_desync_fill.size.x = BAR_W * r
		# Redden toward a warning as Desync nears the world-fray threshold.
		if r > 0.65:
			_bar_sb(_desync_fill).bg_color = Color(0.9, 0.3, 0.7).lerp(Color(1.0, 0.12, 0.12), (r - 0.65) / 0.35)
		else:
			_bar_sb(_desync_fill).bg_color = Color(0.9, 0.3, 0.7)

func _on_reagents_changed(count: int) -> void:
	if _reagent_label:
		_reagent_label.text = "Lucid Caps  %d    [Q] Sight  [R] use" % count
	_refresh_sight_vis()

func _refresh_sight_vis() -> void:
	if _sight_box:
		_sight_box.visible = GameState.sight_unlocked

func set_crosshair_active(active: bool) -> void:
	if not _crosshair:
		return
	if active:
		_crosshair.modulate = UITheme.GOLD
		_crosshair.size = Vector2(8, 8)
		_crosshair.position = Vector2(-4, -4)
	else:
		_crosshair.modulate = Color(1, 1, 1, 1)
		_crosshair.size = Vector2(5, 5)
		_crosshair.position = Vector2(-2.5, -2.5)

func hitmarker() -> void:
	if not _hitmarker:
		return
	_hitmarker.modulate.a = 1.0
	_hitmarker.scale = Vector2(1.4, 1.4)
	var t := create_tween().set_parallel(true)
	t.tween_property(_hitmarker, "modulate:a", 0.0, 0.3)
	t.tween_property(_hitmarker, "scale", Vector2.ONE, 0.3)

func show_death() -> void:
	var t := create_tween()
	t.tween_property(_death_overlay, "color:a", 0.85, 0.4)
	t.parallel().tween_property(_death_label, "modulate:a", 1.0, 0.4)

func hide_death() -> void:
	var t := create_tween()
	t.tween_property(_death_overlay, "color:a", 0.0, 0.6)
	t.parallel().tween_property(_death_label, "modulate:a", 0.0, 0.6)

func show_toast(text: String) -> void:
	_toast_label.text = text
	_toast_label.modulate.a = 1.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.8)

func flash_damage(persist: bool) -> void:
	if persist:
		_damage_vignette.color.a = 0.5
	else:
		var t := create_tween()
		t.tween_property(_damage_vignette, "color:a", 0.0, 0.5)

# ------------------------------------------------------------------- signals
func _on_quest_changed(_step: int, text: String) -> void:
	_quest_label.text = text

func _on_fragments_changed(collected: int, total: int) -> void:
	_fragment_label.text = "Fragments  %d/%d" % [collected, total]
	_fragment_panel.visible = GameState.quest_step >= GameState.Step.COLLECT_FRAGMENTS or collected > 0

func _on_health_changed(health: float, max_health: float) -> void:
	var frac := clampf(health / maxf(max_health, 1.0), 0.0, 1.0)
	# Smoothly animate the bar width and shift colour green -> red as it drops.
	if _health_tween and _health_tween.is_valid():
		_health_tween.kill()
	_health_tween = create_tween().set_parallel(true)
	_health_tween.tween_property(_health_fill, "size:x", BAR_W * frac, 0.25)
	var col := Color(0.80, 0.24, 0.28).lerp(Color(0.46, 0.76, 0.46), frac)
	_health_tween.tween_property(_bar_sb(_health_fill), "bg_color", col, 0.25)
	# Brief red pulse when taking damage.
	if frac < 1.0:
		_damage_vignette.color.a = (1.0 - frac) * 0.35
		var t := create_tween()
		t.tween_property(_damage_vignette, "color:a", 0.0, 0.4)
