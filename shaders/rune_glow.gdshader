shader_type spatial;
// Pulsing glowing rune used on trees/stones around the clearing in the
// First Layer. Unshaded + additive so it reads as light, not a surface.
// Deliberately simple to stay compatible with macOS (Metal) and Windows.
render_mode unshaded, cull_disabled, blend_add, shadows_disabled;

uniform vec3 glow_color : source_color = vec3(0.7, 0.55, 1.0);
uniform float speed = 1.4;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Soft circular falloff so the square quad reads as a glyph, not a box.
	vec2 c = UV - vec2(0.5);
	float d = length(c);
	float mask = smoothstep(0.5, 0.15, d);
	// A couple of bands to suggest an inscribed symbol.
	float bands = 0.5 + 0.5 * sin(UV.y * 24.0 + TIME * speed);
	float pulse = 0.5 + 0.5 * sin(TIME * speed);
	float intensity = mask * (0.6 + 0.4 * bands) * (0.6 + 0.6 * pulse) * reveal;
	ALBEDO = glow_color;
	EMISSION = glow_color * intensity * 3.0;
	ALPHA = intensity;
}
