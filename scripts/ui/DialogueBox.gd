extends CanvasLayer
## DialogueBox
## Bottom panel that shows short, line-by-line dialogue (e.g. from Auralis).
## Advance with E / Space / click. Consumes the interact input while open so it
## doesn't bleed through to the player.

var _panel: PanelContainer
var _speaker_label: Label
var _text_label: Label
var _hint_label: Label
var _lines: Array = []
var _index := 0
var _open := false

func _ready() -> void:
	add_to_group("dialogue")
	layer = 5
	_build()
	GameState.dialogue_requested.connect(open)

func _build() -> void:
	_panel = UITheme.make_panel()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.position = Vector2(0, -200)
	_panel.offset_left = 120
	_panel.offset_right = -120
	_panel.offset_top = -200
	_panel.offset_bottom = -40
	_panel.visible = false
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)
	_speaker_label = UITheme.make_label("", 20, UITheme.ACCENT)
	vbox.add_child(_speaker_label)
	_text_label = UITheme.make_label("", 19)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(_text_label)
	_hint_label = UITheme.make_label("[E] continue", 14, UITheme.TEXT_DIM)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_hint_label)

func open(speaker: String, lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	_open = true
	_speaker_label.text = speaker
	_speaker_label.visible = speaker != ""
	_text_label.text = str(_lines[0])
	_panel.visible = true
	AudioManager.play("magic_hum", -10.0)

func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_text_label.text = str(_lines[_index])
		AudioManager.play("ui_click", -8.0)

func _close() -> void:
	_open = false
	_panel.visible = false

func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("attack"):
		_advance()
		get_viewport().set_input_as_handled()
