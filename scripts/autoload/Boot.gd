extends Node
## Boot
## Registers the input map in code (instead of serializing it into
## project.godot) so the action set is robust across Godot 4.x point
## releases and easy to audit. Runs first because it is the first autoload.

func _enter_tree() -> void:
	_add_keys("move_forward", [KEY_W, KEY_UP])
	_add_keys("move_back", [KEY_S, KEY_DOWN])
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_SPACE])
	_add_keys("sprint", [KEY_SHIFT])
	_add_keys("interact", [KEY_E])
	_add_keys("sight", [KEY_Q, KEY_F])
	_add_keys("use_reagent", [KEY_R])
	_add_keys("inventory", [KEY_TAB, KEY_I])
	_add_keys("pause", [KEY_ESCAPE])
	_add_keys("camera_toggle", [KEY_C])
	_add_keys("dodge", [KEY_CTRL])
	_add_keys("quick_save", [KEY_F5])
	_add_keys("quick_load", [KEY_F9])
	_add_keys("toggle_fps", [KEY_F3])
	_add_mouse("attack", MOUSE_BUTTON_LEFT)
	_add_mouse("cast", MOUSE_BUTTON_RIGHT)
	# ui_accept / ui_cancel already exist as engine defaults.

	# ---- Gamepad (the InputMap stays the single source of truth) ----
	# Movement on the left stick; look on the right stick (read in Player).
	_add_joy_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_joy_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_joy_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_joy_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)
	_add_joy_button("jump", JOY_BUTTON_A)
	_add_joy_button("sprint", JOY_BUTTON_LEFT_STICK)
	_add_joy_button("interact", JOY_BUTTON_X)
	_add_joy_button("sight", JOY_BUTTON_Y)
	_add_joy_button("use_reagent", JOY_BUTTON_DPAD_UP)
	_add_joy_button("inventory", JOY_BUTTON_BACK)
	_add_joy_button("pause", JOY_BUTTON_START)
	_add_joy_button("camera_toggle", JOY_BUTTON_RIGHT_STICK)
	_add_joy_button("dodge", JOY_BUTTON_B)
	_add_joy_button("attack", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_axis("attack", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_joy_button("cast", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_axis("cast", JOY_AXIS_TRIGGER_LEFT, 1.0)
	# Make the menus controller-navigable too.
	_add_joy_event("ui_accept", JOY_BUTTON_A)
	_add_joy_event("ui_cancel", JOY_BUTTON_B)

func _add_keys(action: String, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for code in keycodes:
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		InputMap.action_add_event(action, ev)

func _add_mouse(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)

func _add_joy_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)

# Alias for readability when adding to engine-default ui_* actions.
func _add_joy_event(action: String, button: int) -> void:
	_add_joy_button(action, button)

func _add_joy_axis(action: String, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)
