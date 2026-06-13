extends Control
## Loading
## Masks the menu -> forest transition (the Forest builds its world in _ready,
## which can hitch). Shows an in-world lore tip + an animated "Pulse" line, then
## changes to the gameplay scene. GameState.pending_load already carries
## new-game vs continue.

const TARGET := "res://scenes/Forest.tscn"

var _dots := 0
var _label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)

	v.add_child(UITheme.make_title("Entering the First Layer", 30))
	var tip: String = Content.LORE_TIPS[randi() % Content.LORE_TIPS.size()]
	var tip_l := UITheme.make_label("“%s”" % tip, 17, UITheme.TEXT_DIM)
	tip_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_l.custom_minimum_size = Vector2(620, 0)
	tip_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tip_l)

	_label = UITheme.make_label("◈", 22, UITheme.ACCENT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_label)

	# Animate the pulse line, then load.
	var t := create_tween()
	t.set_loops(6)
	t.tween_callback(_pulse).set_delay(0.18)
	get_tree().create_timer(1.9).timeout.connect(_go)

func _pulse() -> void:
	_dots = (_dots + 1) % 6
	_label.text = "◈ ".repeat(_dots + 1).strip_edges()

func _go() -> void:
	get_tree().change_scene_to_file(TARGET)
