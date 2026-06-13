extends CanvasLayer
## Journal (Inventory / state tracking)
## Opened with Tab / I. Freezes the game and shows the quest objective, the
## Fragments of Truth recovered (with their revealed lore), the seeker's current
## stats, and chosen path. This is the brief's "simple state-tracking UI".

var _open := false

func _ready() -> void:
	add_to_group("journal")
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	if _open:
		_close()
	else:
		_open_journal()

func _open_journal() -> void:
	_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rebuild()
	visible = true
	AudioManager.play("ui_click")

func _close() -> void:
	_open = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false

func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	add_child(UITheme.fullscreen_dim())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UITheme.make_panel()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	v.add_child(UITheme.make_title("Journal", 34))
	v.add_child(_heading("Objective"))
	v.add_child(_body(GameState.STEP_TEXT[GameState.quest_step]))

	v.add_child(_heading("Fragments of Truth  (%d/%d)" % [GameState.fragments, GameState.FRAGMENT_TOTAL]))
	if GameState.collected_ids.is_empty():
		v.add_child(_body("None recovered yet. They shimmer once the world has shifted."))
	else:
		var ids := GameState.collected_ids.duplicate()
		ids.sort()
		for id in ids:
			var lines: Array = Content.FRAGMENT_LINES[clampi(int(id), 0, 2)]
			v.add_child(_body("◈  " + "  ".join(PackedStringArray(lines))))

	v.add_child(_heading("The Seeker"))
	var magic := "Unlocked" if GameState.magic_unlocked else "Locked"
	var path := GameState.selected_upgrade if GameState.selected_upgrade != "" else "Unchosen"
	v.add_child(_body("Max Vitality: %d" % int(GameState.max_health)))
	v.add_child(_body("Melee Damage: %d" % int(GameState.melee_damage)))
	v.add_child(_body("Sprint Bonus: x%.2f" % GameState.sprint_multiplier))
	v.add_child(_body("Simulation Pulse: %s" % magic))
	v.add_child(_body("Forest Essence: %d" % GameState.forest_essence))
	v.add_child(_body("Path: %s" % path.capitalize().replace("_", " ")))

	v.add_child(_spacer(8))
	var close := UITheme.make_button("Close  [Tab]", 220)
	close.pressed.connect(_close)
	var cc := CenterContainer.new()
	cc.add_child(close)
	v.add_child(cc)

func _heading(text: String) -> Label:
	var l := UITheme.make_label(text, 16, UITheme.ACCENT)
	return l

func _body(text: String) -> Label:
	var l := UITheme.make_label(text, 15, UITheme.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(560, 0)
	return l

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
