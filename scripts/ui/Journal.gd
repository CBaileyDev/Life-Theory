extends CanvasLayer
## Journal (Codex / Inventory / state tracking)
## Opened with Tab / I. Freezes the game and shows tabbed pages: live Status
## (objective, recovered lore, seeker stats) plus a Codex (Story, Characters,
## Bestiary, Sight & Items) drawn from the design bible.

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
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(UITheme.make_title("Journal", 32))

	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(700, 460)
	tabs.add_theme_font_size_override("font_size", 15)
	v.add_child(tabs)
	_add_tab(tabs, "Status", _status_tab())
	_add_tab(tabs, "Story", _codex_tab(Codex.STORY))
	_add_tab(tabs, "Characters", _codex_tab(Codex.CHARACTERS))
	_add_tab(tabs, "Bestiary", _codex_tab(Codex.BESTIARY))
	_add_tab(tabs, "Sight & Items", _codex_tab(Codex.SIGHT_ITEMS))

	var close := UITheme.make_button("Close  [Tab]", 220)
	close.pressed.connect(_close)
	var cc := CenterContainer.new()
	cc.add_child(close)
	v.add_child(cc)

func _add_tab(tabs: TabContainer, title: String, content: Control) -> void:
	content.name = title
	tabs.add_child(content)

func _scroll(v: VBoxContainer) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(690, 430)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_theme_constant_override("separation", 12)
	sc.add_child(v)
	return sc

func _status_tab() -> Control:
	var v := VBoxContainer.new()
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
	var path: String = GameState.selected_upgrade if GameState.selected_upgrade != "" else "Unchosen"
	v.add_child(_body("Max Vitality: %d   ·   Melee: %d   ·   Sprint x%.2f"
		% [int(GameState.max_health), int(GameState.melee_damage), GameState.sprint_multiplier]))
	v.add_child(_body("Simulation Pulse: %s   ·   Forest Essence: %d"
		% ["Unlocked" if GameState.magic_unlocked else "Locked", GameState.forest_essence]))
	v.add_child(_body("The Sight: %s   ·   Lucid Caps: %d"
		% ["Awakened" if GameState.sight_unlocked else "Dormant", GameState.sight_reagents]))
	v.add_child(_body("Path: %s" % path.capitalize()))
	return _scroll(v)

func _codex_tab(entries: Array) -> Control:
	var v := VBoxContainer.new()
	for e in entries:
		v.add_child(_heading(e["t"]))
		v.add_child(_body(e["b"]))
	return _scroll(v)

func _heading(text: String) -> Label:
	return UITheme.make_label(text, 17, UITheme.ACCENT)

func _body(text: String) -> Label:
	var l := UITheme.make_label(text, 15, UITheme.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(650, 0)
	return l
