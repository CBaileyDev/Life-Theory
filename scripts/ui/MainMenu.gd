extends Control
## MainMenu
## Atmospheric title screen: gradient sky, drifting firefly particles, the
## title/subtitle, and Start / Continue / Settings / Quit. Entry point of the
## game (set as the main scene in project.godot).

var _settings: SettingsPanel
var _menu_box: Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	_build()
	AudioManager.play_ambience("forest_day")

func _build() -> void:
	# Vertical gradient background (deep forest dusk).
	var grad := Gradient.new()
	grad.set_color(0, Color(0.03, 0.05, 0.08))
	grad.set_color(1, Color(0.07, 0.12, 0.10))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(tr)

	# Live 3D forest backdrop (drawn over the gradient fallback).
	add_child(MenuBackdrop.new())

	# Readability scrim over the bright backdrop: darker top & bottom, clear in
	# the middle, so the title and buttons read while the forest still shows.
	var sg := Gradient.new()
	sg.offsets = PackedFloat32Array([0.0, 0.32, 0.7, 1.0])
	sg.colors = PackedColorArray([
		Color(0.02, 0.04, 0.05, 0.62), Color(0.02, 0.04, 0.05, 0.18),
		Color(0.02, 0.04, 0.05, 0.22), Color(0.02, 0.04, 0.05, 0.6)])
	var stex := GradientTexture2D.new()
	stex.gradient = sg
	stex.fill_from = Vector2(0, 0)
	stex.fill_to = Vector2(0, 1)
	var scrim := TextureRect.new()
	scrim.texture = stex
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	# Drifting fireflies for atmosphere.
	var fireflies := CPUParticles2D.new()
	fireflies.amount = 60
	fireflies.lifetime = 8.0
	fireflies.position = Vector2(640, 720)
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(700, 30)
	fireflies.direction = Vector2(0, -1)
	fireflies.spread = 30.0
	fireflies.gravity = Vector2(0, -10)
	fireflies.initial_velocity_min = 10.0
	fireflies.initial_velocity_max = 30.0
	fireflies.scale_amount_min = 1.0
	fireflies.scale_amount_max = 3.0
	fireflies.color = Color(0.9, 0.85, 0.5, 0.7)
	add_child(fireflies)

	# Title block.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_menu_box = center

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	center.add_child(v)
	v.add_child(UITheme.make_title("THE FIRST LAYER", 64))
	var sub := UITheme.make_title("A Magical Forest Simulation Mystery", 22)
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	v.add_child(sub)
	v.add_child(_spacer(28))

	var start_btn := UITheme.make_button("Start Game", 300)
	v.add_child(_center_button(start_btn, _start_game))
	if SaveManager.has_save():
		v.add_child(_center_button(UITheme.make_button("Continue", 300), _continue_game))
	v.add_child(_center_button(UITheme.make_button("Settings", 300), _open_settings))
	v.add_child(_center_button(UITheme.make_button("Quit", 300), func(): get_tree().quit()))
	# Keyboard/gamepad navigation starts on Start Game.
	start_btn.grab_focus.call_deferred()

	v.add_child(_spacer(20))
	var hint := UITheme.make_label(
		"WASD move · Mouse look · Shift sprint · E interact · LMB attack · Tab menu · Esc pause",
		13, UITheme.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)

func _start_game() -> void:
	AudioManager.play("ui_click")
	GameState.reset_run()
	GameState.pending_load = false
	get_tree().change_scene_to_file("res://scenes/Loading.tscn")

func _continue_game() -> void:
	AudioManager.play("ui_click")
	GameState.pending_load = true
	get_tree().change_scene_to_file("res://scenes/Loading.tscn")

func _open_settings() -> void:
	AudioManager.play("ui_click")
	_menu_box.hide()
	_settings = SettingsPanel.new()
	var on_closed := func():
		_settings.queue_free()
		_settings = null
		_menu_box.show()
	_settings.closed.connect(on_closed)
	add_child(_settings)

# ------------------------------------------------------------------- helpers
func _center_button(b: Button, cb: Callable) -> Control:
	b.pressed.connect(cb)
	var c := CenterContainer.new()
	c.add_child(b)
	return c

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
