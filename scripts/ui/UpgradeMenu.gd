extends CanvasLayer
## UpgradeMenu
## Shown after the player returns to the shrine with all fragments. Offers the
## four upgrades from the brief; choosing one applies it immediately
## (via GameState), shows confirmation, then returns to play.

const UPGRADES := [
	{"id": "heart_of_bark", "name": "Heart of Bark",
		"desc": "Roots run deep. Increase your maximum vitality (+60)."},
	{"id": "fleet_hidden_path", "name": "Fleet of the Hidden Path",
		"desc": "The trail carries you. Sprint noticeably faster."},
	{"id": "rootblade_strength", "name": "Rootblade Strength",
		"desc": "The Ancient Rootblade strikes harder (+40 melee damage)."},
	{"id": "simulation_pulse", "name": "Simulation Pulse",
		"desc": "Glimpse the code beneath. Unlock a magic pulse — Right-Click to cast."},
]

var _panel_v: VBoxContainer

func _ready() -> void:
	add_to_group("upgrade")
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.upgrade_menu_requested.connect(open)
	visible = false

func open() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_choices()

func _build_choices() -> void:
	_clear()
	var dim := UITheme.fullscreen_dim()
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UITheme.make_panel()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	_panel_v = VBoxContainer.new()
	_panel_v.add_theme_constant_override("separation", 12)
	panel.add_child(_panel_v)

	_panel_v.add_child(UITheme.make_title("Choose Your Path", 34))
	_panel_v.add_child(UITheme.make_label("\"%s\"" % Content.UPGRADE_INTRO, 16, UITheme.TEXT_DIM))
	_panel_v.add_child(_spacer(8))

	for up in UPGRADES:
		_panel_v.add_child(_make_card(up))

func _make_card(up: Dictionary) -> Control:
	var card := UITheme.make_button("", 600)
	card.custom_minimum_size = Vector2(600, 78)
	# Compose a rich label inside the button.
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_top = 8
	var name_l := UITheme.make_label(up["name"], 20, UITheme.GOLD)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var desc_l := UITheme.make_label(up["desc"], 15, UITheme.TEXT)
	desc_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_l.custom_minimum_size = Vector2(560, 0)
	v.add_child(name_l)
	v.add_child(desc_l)
	card.add_child(v)
	card.pressed.connect(func(): _choose(up))
	return card

func _choose(up: Dictionary) -> void:
	GameState.choose_upgrade(up["id"])
	_show_confirmation(up)

func _show_confirmation(up: Dictionary) -> void:
	_clear()
	add_child(UITheme.fullscreen_dim())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UITheme.make_panel()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	v.add_child(UITheme.make_title("Path Chosen", 32))
	var l := UITheme.make_label("You have become a seeker of \"%s\".\n%s" % [up["name"], up["desc"]],
		17, UITheme.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(470, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	v.add_child(_spacer(8))
	var cont := UITheme.make_button("Continue", 220)
	cont.pressed.connect(_close)
	var cc := CenterContainer.new()
	cc.add_child(cont)
	v.add_child(cc)

func _close() -> void:
	AudioManager.play("ui_click")
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false
	GameState.toast.emit("The first layer is revealed. Your journey begins.")
	_clear()

func _clear() -> void:
	for c in get_children():
		c.queue_free()

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
