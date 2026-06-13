extends CanvasLayer
## HUD
## Quest objective, fragment counter, health bar, interaction prompt, and
## transient toast messages. Pure-code, dark-fantasy styling. Listens to
## GameState so it always reflects the live run.

var _quest_label: Label
var _fragment_label: Label
var _fragment_panel: Control
var _prompt_label: Label
var _health_fill: ColorRect
var _health_label: Label
var _toast_label: Label
var _damage_vignette: ColorRect
var _toast_tween: Tween
var _health_tween: Tween
var _stamina_fill: ColorRect
var _crosshair: Control
var _hitmarker: Label
var _death_overlay: ColorRect
var _death_label: Label

func _ready() -> void:
	add_to_group("hud")
	_build()
	GameState.quest_step_changed.connect(_on_quest_changed)
	GameState.fragments_changed.connect(_on_fragments_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.toast.connect(show_toast)
	GameState.broadcast()

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

	# Health bar (bottom-left).
	var hp_panel := UITheme.make_panel()
	hp_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hp_panel.position = Vector2(20, -70)
	root.add_child(hp_panel)
	var hbox := VBoxContainer.new()
	hp_panel.add_child(hbox)
	_health_label = UITheme.make_label("Vitality", 13, UITheme.TEXT_DIM)
	hbox.add_child(_health_label)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.1, 0.04, 0.05, 0.9)
	bar_bg.custom_minimum_size = Vector2(220, 16)
	hbox.add_child(bar_bg)
	_health_fill = ColorRect.new()
	_health_fill.color = Color(0.7, 0.25, 0.30)
	_health_fill.position = Vector2.ZERO
	_health_fill.size = Vector2(220, 16)
	bar_bg.add_child(_health_fill)
	# Stamina bar (under health).
	_stamina_fill = _make_sub_bar(hbox, "Stamina", Color(0.35, 0.6, 0.75))

	# Crosshair (centre dot) + hitmarker.
	_crosshair = ColorRect.new()
	_crosshair.color = Color(0.9, 0.95, 0.95, 0.5)
	_crosshair.custom_minimum_size = Vector2(4, 4)
	_crosshair.size = Vector2(4, 4)
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.position = Vector2(-2, -2)
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
	_death_overlay = ColorRect.new()
	_death_overlay.color = Color(0.02, 0.0, 0.02, 0.0)
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_death_overlay)
	_death_label = UITheme.make_title("The forest reclaims you...", 34)
	_death_label.set_anchors_preset(Control.PRESET_CENTER)
	_death_label.modulate.a = 0.0
	root.add_child(_death_label)

func _make_sub_bar(parent: VBoxContainer, label: String, color: Color) -> ColorRect:
	parent.add_child(UITheme.make_label(label, 13, UITheme.TEXT_DIM))
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.09, 0.9)
	bg.custom_minimum_size = Vector2(220, 12)
	parent.add_child(bg)
	var fill := ColorRect.new()
	fill.color = color
	fill.position = Vector2.ZERO
	fill.size = Vector2(220, 12)
	bg.add_child(fill)
	return fill

# ------------------------------------------------------------------ external
func set_prompt(text: String) -> void:
	if _prompt_label:
		_prompt_label.text = text

func set_stamina(frac: float) -> void:
	if _stamina_fill:
		_stamina_fill.size.x = 220.0 * clampf(frac, 0.0, 1.0)

func set_crosshair_active(active: bool) -> void:
	if not _crosshair:
		return
	if active:
		_crosshair.color = UITheme.GOLD
		_crosshair.size = Vector2(7, 7)
		_crosshair.position = Vector2(-3.5, -3.5)
	else:
		_crosshair.color = Color(0.9, 0.95, 0.95, 0.5)
		_crosshair.size = Vector2(4, 4)
		_crosshair.position = Vector2(-2, -2)

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
	_health_tween.tween_property(_health_fill, "size:x", 220.0 * frac, 0.25)
	var col := Color(0.78, 0.22, 0.26).lerp(Color(0.45, 0.74, 0.45), frac)
	_health_tween.tween_property(_health_fill, "color", col, 0.25)
	# Brief red pulse when taking damage.
	if frac < 1.0:
		_damage_vignette.color.a = (1.0 - frac) * 0.35
		var t := create_tween()
		t.tween_property(_damage_vignette, "color:a", 0.0, 0.4)
