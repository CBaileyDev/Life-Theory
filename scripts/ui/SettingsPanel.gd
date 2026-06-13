class_name SettingsPanel
extends Control
## SettingsPanel
## Reusable settings UI (main menu + pause menu). Reads/writes SettingsManager,
## which persists to user:// and applies changes live. Emits `closed` when the
## player backs out.

signal closed

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()

func _build() -> void:
	var dim := UITheme.fullscreen_dim()
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UITheme.make_panel()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := UITheme.make_title("Settings", 34)
	v.add_child(title)
	v.add_child(_spacer(6))

	# Graphics quality
	var quality := OptionButton.new()
	quality.add_item("Low")
	quality.add_item("Medium")
	quality.add_item("High")
	quality.selected = SettingsManager.graphics_quality
	quality.item_selected.connect(func(i): SettingsManager.set_quality(i))
	v.add_child(_row("Graphics Quality", quality))

	# Resolution
	var resopt := OptionButton.new()
	for r in SettingsManager.RESOLUTIONS:
		resopt.add_item("%d x %d" % [r.x, r.y])
	resopt.selected = SettingsManager.resolution_index
	resopt.item_selected.connect(func(i): SettingsManager.set_resolution_index(i))
	v.add_child(_row("Resolution", resopt))

	# Render scale (3D resolution)
	var rs := HSlider.new()
	rs.min_value = 0.5
	rs.max_value = 1.0
	rs.step = 0.05
	rs.value = SettingsManager.render_scale
	rs.custom_minimum_size = Vector2(220, 0)
	var rs_val := UITheme.make_label("%d%%" % int(SettingsManager.render_scale * 100), 16, UITheme.TEXT_DIM)
	var rs_cb := func(v2: float):
		SettingsManager.set_render_scale(v2)
		rs_val.text = "%d%%" % int(v2 * 100)
	rs.value_changed.connect(rs_cb)
	v.add_child(_row("Render Scale", rs, rs_val))

	# Fullscreen
	var fs := CheckBox.new()
	fs.button_pressed = SettingsManager.fullscreen
	fs.toggled.connect(func(on): SettingsManager.set_fullscreen(on))
	v.add_child(_row("Fullscreen", fs))

	# Mouse sensitivity
	var sens := HSlider.new()
	sens.min_value = 0.05
	sens.max_value = 1.0
	sens.step = 0.01
	sens.value = SettingsManager.mouse_sensitivity
	sens.custom_minimum_size = Vector2(220, 0)
	var sens_val := UITheme.make_label("%.2f" % SettingsManager.mouse_sensitivity, 16, UITheme.TEXT_DIM)
	var sens_cb := func(v2: float):
		SettingsManager.set_mouse_sensitivity(v2)
		sens_val.text = "%.2f" % v2
	sens.value_changed.connect(sens_cb)
	v.add_child(_row("Mouse Sensitivity", sens, sens_val))

	# Master volume
	var vol := HSlider.new()
	vol.min_value = 0.0
	vol.max_value = 1.0
	vol.step = 0.01
	vol.value = SettingsManager.master_volume
	vol.custom_minimum_size = Vector2(220, 0)
	vol.value_changed.connect(func(v2): SettingsManager.set_master_volume(v2))
	v.add_child(_row("Master Volume", vol))

	# Field of view
	var fov := HSlider.new()
	fov.min_value = 60.0
	fov.max_value = 110.0
	fov.step = 1.0
	fov.value = SettingsManager.fov
	fov.custom_minimum_size = Vector2(220, 0)
	var fov_val := UITheme.make_label("%d°" % int(SettingsManager.fov), 16, UITheme.TEXT_DIM)
	var fov_cb := func(v2: float):
		SettingsManager.set_fov(v2)
		fov_val.text = "%d°" % int(v2)
	fov.value_changed.connect(fov_cb)
	v.add_child(_row("Field of View", fov, fov_val))

	# Camera mode (third-person toggle)
	var cam := CheckBox.new()
	cam.button_pressed = SettingsManager.third_person
	cam.toggled.connect(func(on): SettingsManager.set_third_person(on))
	v.add_child(_row("Third-Person Camera", cam))

	# Invert vertical look
	var inv := CheckBox.new()
	inv.button_pressed = SettingsManager.invert_y
	inv.toggled.connect(func(on): SettingsManager.set_invert_y(on))
	v.add_child(_row("Invert Look (Y)", inv))

	# ---- Accessibility & gameplay ----
	v.add_child(_spacer(6))
	v.add_child(UITheme.make_label("Accessibility & Gameplay", 16, UITheme.ACCENT))

	var diff := OptionButton.new()
	diff.add_item("Story")
	diff.add_item("Seeker")
	diff.add_item("Trial")
	diff.selected = SettingsManager.difficulty
	diff.item_selected.connect(func(i): SettingsManager.set_difficulty(i))
	v.add_child(_row("Difficulty", diff))

	var shake := HSlider.new()
	shake.min_value = 0.0
	shake.max_value = 1.0
	shake.step = 0.1
	shake.value = SettingsManager.screen_shake
	shake.custom_minimum_size = Vector2(220, 0)
	shake.value_changed.connect(func(v2): SettingsManager.set_screen_shake(v2))
	v.add_child(_row("Screen Shake", shake))

	var motion := CheckBox.new()
	motion.button_pressed = SettingsManager.reduce_motion
	motion.toggled.connect(func(on): SettingsManager.set_reduce_motion(on))
	v.add_child(_row("Reduce Motion", motion))

	var sprintc := CheckBox.new()
	sprintc.button_pressed = SettingsManager.sprint_toggle
	sprintc.toggled.connect(func(on): SettingsManager.set_sprint_toggle(on))
	v.add_child(_row("Sprint: Toggle (off = Hold)", sprintc))

	var subs := CheckBox.new()
	subs.button_pressed = SettingsManager.subtitles
	subs.toggled.connect(func(on): SettingsManager.set_subtitles(on))
	v.add_child(_row("Subtitles", subs))

	v.add_child(_spacer(8))
	var back := UITheme.make_button("Back", 180)
	var back_cb := func():
		AudioManager.play("ui_click")
		closed.emit()
	back.pressed.connect(back_cb)
	var back_center := CenterContainer.new()
	back_center.add_child(back)
	v.add_child(back_center)

func _row(label_text: String, control: Control, suffix: Control = null) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := UITheme.make_label(label_text, 18)
	l.custom_minimum_size = Vector2(240, 0)
	h.add_child(l)
	h.add_child(control)
	if suffix:
		h.add_child(suffix)
	return h

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
