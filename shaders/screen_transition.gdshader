shader_type canvas_item;
// Fullscreen transformation effect for the mushroom event: a brief wavy
// distortion plus a colour-tinted flash. Driven by `progress` (0..1) from the
// Forest controller. Reads the screen via a back-buffer copy, so it is safe to
// draw over the scene. Compatible with macOS and Windows renderers.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint : source_color = vec3(0.75, 1.0, 0.9);
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	// Vertical wave that grows with progress.
	float wave = sin(uv.y * 28.0 + TIME * 9.0) * 0.012 * progress;
	float wave2 = cos(uv.x * 22.0 - TIME * 7.0) * 0.010 * progress;
	uv.x += wave;
	uv.y += wave2;
	vec3 col = texture(screen_tex, uv).rgb;
	// Mild chromatic split for the magical shimmer.
	col.r = texture(screen_tex, uv + vec2(0.004 * progress, 0.0)).r;
	col.b = texture(screen_tex, uv - vec2(0.004 * progress, 0.0)).b;
	col = mix(col, tint, progress * 0.55);
	COLOR = vec4(col, 1.0);
}
