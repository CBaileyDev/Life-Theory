class_name DamageNumber
extends Node3D
## DamageNumber
## A billboarded number that floats up and fades out, then frees itself.
## Spawned when a creature takes a hit, for readable combat feedback.

static func spawn(parent: Node, world_pos: Vector3, amount: float, color: Color) -> void:
	var d := DamageNumber.new()
	parent.add_child(d)
	d.global_position = world_pos
	d._setup(amount, color)

func _setup(amount: float, color: Color) -> void:
	var label := Label3D.new()
	label.text = str(int(round(amount)))
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.outline_size = 8
	label.font_size = 56
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	add_child(label)

	# Float up + slight drift, then fade and free.
	var drift := Vector3(randf_range(-0.4, 0.4), 1.6, randf_range(-0.4, 0.4))
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "global_position", global_position + drift, 0.9)
	t.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.25)
	t.chain().tween_callback(queue_free)
