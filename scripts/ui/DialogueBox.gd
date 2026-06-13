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
var _type_tween: Tween

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
	_panel.visible = true
	_show_line(str(_lines[0]))
	AudioManager.play("magic_hum", -10.0)

func _show_line(text: String) -> void:
	# Typewriter reveal via Label.visible_ratio.
	_text_label.text = text
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_text_label.visible_ratio = 0.0
	var dur := clampf(text.length() * 0.022, 0.2, 2.0)
	_type_tween = create_tween()
	_type_tween.tween_property(_text_label, "visible_ratio", 1.0, dur)

func _typing() -> bool:
	return _type_tween != null and _type_tween.is_valid() and _text_label.visible_ratio < 1.0

func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		AudioManager.play("ui_click", -8.0)
		_show_line(str(_lines[_index]))

func _close() -> void:
	_open = false
	_panel.visible = false

func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("attack"):
		# First press finishes the typewriter; next press advances.
		if _typing():
			_type_tween.kill()
			_text_label.visible_ratio = 1.0
		else:
			_advance()
		get_viewport().set_input_as_handled()
