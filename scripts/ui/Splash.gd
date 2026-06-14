extends Control
## Splash
## Boot screen: a brief studio/title beat with a "Sight-flicker" reveal of the
## title, then advances to the main menu. Skippable with any key/click.
## Visuals are intentionally simple placeholders — final art is the art team's.

var _done := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	center.add_child(v)

	var title := UITheme.make_title("THE FIRST LAYER", 64)
	title.modulate.a = 0.0
	v.add_child(title)
	var sub := UITheme.make_title("A Magical Forest Simulation Mystery", 20)
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	sub.modulate.a = 0.0
	v.add_child(sub)

	var hint := UITheme.make_label("press any key", 13, UITheme.TEXT_DIM)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(0, -60)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	# "Sight-flicker" reveal: the title stutters into being. Honour reduce-motion
	# by fading in smoothly instead of strobing.
	var t := create_tween()
	if SettingsManager.reduce_motion:
		t.tween_property(title, "modulate:a", 1.0, 0.8)
	else:
		for a in [0.0, 0.9, 0.1, 1.0, 0.3, 1.0]:
			t.tween_property(title, "modulate:a", a, 0.09)
	t.tween_property(sub, "modulate:a", 1.0, 0.6)
	t.tween_interval(1.6)
	t.tween_callback(_advance)
	AudioManager.play("mushroom_transform", -8.0)

func _input(event: InputEvent) -> void:
	if event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton):
		_advance()

func _advance() -> void:
	if _done:
		return
	_done = true
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
