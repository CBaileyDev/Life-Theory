extends CanvasLayer
## PauseMenu
## Toggled with Escape. Freezes gameplay (tree paused), frees the mouse, and
## offers Resume / Settings / Main Menu / Quit. Runs with process_mode ALWAYS
## so it keeps working while the tree is paused.

var _root: Control
var _menu: Control
var _settings: SettingsPanel
var _is_open := false
var _resume_btn: Button

func _ready() -> void:
	add_to_group("pause")
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide_menu()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(UITheme.fullscreen_dim())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_menu = center

	var panel := UITheme.make_panel()
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UITheme.make_title("Paused", 38))
	v.add_child(_spacer(10))
	_resume_btn = _button("Resume", resume)
	v.add_child(_resume_btn)
	v.add_child(_button("Settings", _open_settings))
	v.add_child(_button("Return to Main Menu", _to_main_menu))
	v.add_child(_button("Quit", _quit))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _settings and _settings.visible:
			_close_settings()
		elif _is_open:
			resume()
		else:
			open()
		get_viewport().set_input_as_handled()

# --------------------------------------------------------------------- state
func open() -> void:
	_is_open = true
	visible = true
	_menu.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_duck_audio(true)
	if _resume_btn:
		_resume_btn.grab_focus.call_deferred()

func resume() -> void:
	_is_open = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_duck_audio(false)
	hide_menu()

## Quiet the world while paused (set bus volumes directly — tweens don't advance
## while the tree is paused, so this is instant). UI bus stays up for clicks.
func _duck_audio(on: bool) -> void:
	for b in ["Music", "Ambience", "SFX"]:
		var idx := AudioServer.get_bus_index(b)
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx, -18.0 if on else 0.0)

func hide_menu() -> void:
	visible = false
	_is_open = false

# ------------------------------------------------------------------ settings
func _open_settings() -> void:
	_menu.hide()
	_settings = SettingsPanel.new()
	_settings.closed.connect(_close_settings)
	add_child(_settings)

func _close_settings() -> void:
	if _settings:
		_settings.queue_free()
		_settings = null
	_menu.show()

# -------------------------------------------------------------------- nav
func _to_main_menu() -> void:
	get_tree().paused = false
	_duck_audio(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _quit() -> void:
	get_tree().quit()

# -------------------------------------------------------------------- helpers
func _button(text: String, cb: Callable) -> Button:
	var b := UITheme.make_button(text, 320)
	var wrapped := func():
		AudioManager.play("ui_click")
		cb.call()
	b.pressed.connect(wrapped)
	return b

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
