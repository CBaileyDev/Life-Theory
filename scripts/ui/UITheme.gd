class_name UITheme
extends RefCounted
## UITheme
## Dark-fantasy UI styling built entirely in code so menus stay consistent and
## need no .theme asset. Soft glow, translucent panels, readable type.

const BG := Color(0.04, 0.06, 0.07, 0.92)
const PANEL := Color(0.06, 0.09, 0.11, 0.88)
const ACCENT := Color(0.55, 0.85, 0.78)        # mossy-gold-teal glow
const ACCENT_DIM := Color(0.30, 0.48, 0.46)
const TEXT := Color(0.86, 0.92, 0.90)
const TEXT_DIM := Color(0.62, 0.70, 0.70)
const GOLD := Color(1.0, 0.82, 0.45)

static func panel_style(border := true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	if border:
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = ACCENT_DIM
	return sb

static func make_panel(border := true) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(border))
	return p

static func make_label(text: String, size := 18, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l

static func make_title(text: String, size := 56) -> Label:
	var l := make_label(text, size, ACCENT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# A dark outline keeps the title legible over a bright, busy 3D backdrop.
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("outline_size", maxi(3, size / 10))
	return l

static func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = border
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

static func make_button(text: String, min_width := 260.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 0)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", ACCENT)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_focus_color", ACCENT)
	b.add_theme_stylebox_override("normal", _btn_style(Color(0.08, 0.12, 0.13, 0.9), ACCENT_DIM))
	b.add_theme_stylebox_override("hover", _btn_style(Color(0.12, 0.20, 0.20, 0.95), ACCENT))
	b.add_theme_stylebox_override("pressed", _btn_style(Color(0.06, 0.10, 0.10, 0.95), GOLD))
	b.add_theme_stylebox_override("focus", _btn_style(Color(0.10, 0.16, 0.16, 0.95), ACCENT))
	return b

## A clean rounded stat bar (track + fill). Returns the fill Panel; animate its
## size.x in [0, width]. Small uppercase caption sits above it.
static func make_stat_bar(parent: Node, caption: String, width := 224.0, height := 12.0, fill_color := ACCENT) -> Panel:
	if caption != "":
		var lbl := make_label(caption.to_upper(), 11, TEXT_DIM)
		lbl.add_theme_constant_override("line_spacing", 2)
		parent.add_child(lbl)
	var track := Panel.new()
	track.custom_minimum_size = Vector2(width, height)
	var tb := StyleBoxFlat.new()
	tb.bg_color = Color(0.02, 0.03, 0.04, 0.80)
	tb.set_corner_radius_all(int(height * 0.5))
	tb.set_border_width_all(1)
	tb.border_color = Color(ACCENT_DIM.r, ACCENT_DIM.g, ACCENT_DIM.b, 0.45)
	track.add_theme_stylebox_override("panel", tb)
	parent.add_child(track)
	var fill := Panel.new()
	fill.position = Vector2.ZERO
	fill.size = Vector2(width, height)
	var fb := StyleBoxFlat.new()
	fb.bg_color = fill_color
	fb.set_corner_radius_all(int(height * 0.5))
	# A subtle lighter top edge gives the fill a soft sheen.
	fb.border_width_top = 1
	fb.border_color = Color(minf(fill_color.r + 0.25, 1.0), minf(fill_color.g + 0.25, 1.0), minf(fill_color.b + 0.25, 1.0), 0.6)
	fill.add_theme_stylebox_override("panel", fb)
	track.add_child(fill)
	return fill

## A clean crosshair: a tiny dot with a faint dark outline for legibility on any
## backdrop. Returns the dot Panel (recolour/resize for the interact state).
static func make_crosshair() -> Panel:
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(5, 5)
	dot.size = Vector2(5, 5)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.92, 0.96, 0.96, 0.7)
	sb.set_corner_radius_all(3)
	sb.set_border_width_all(1)
	sb.border_color = Color(0, 0, 0, 0.55)
	dot.add_theme_stylebox_override("panel", sb)
	return dot

static func fullscreen_dim(color := BG) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r
