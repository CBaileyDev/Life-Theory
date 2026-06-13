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
	_add_keys("quick_save", [KEY_F5])
	_add_keys("quick_load", [KEY_F9])
	_add_mouse("attack", MOUSE_BUTTON_LEFT)
	_add_mouse("cast", MOUSE_BUTTON_RIGHT)
	# ui_accept / ui_cancel already exist as engine defaults.

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
