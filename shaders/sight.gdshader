shader_type canvas_item;
// The Sight: a sustained "perceive the simulation" overlay. While active it
// desaturates and cool-tints the world, adds drifting scanlines, a subtle
// chromatic split, and a breathing vignette — the look of seeing the layer's
// underlying structure. Driven by `amount` (0..1). Portable (macOS/Windows).

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float desync : hint_range(0.0, 1.0) = 0.0;   // adds instability as it rises
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	float a = amount;
	// Chromatic aberration grows with desync.
	float ca = (0.0015 + 0.004 * desync) * a;
	vec3 col;
	col.r = texture(screen_tex, uv + vec2(ca, 0.0)).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - vec2(ca, 0.0)).b;

	// Cool, slightly desaturated "code" tint.
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 tinted = mix(col, vec3(luma) * vec3(0.55, 0.85, 1.05), 0.55 * a);

	// Drifting scanlines + faint horizontal data-jitter.
	float scan = 0.92 + 0.08 * sin((uv.y + TIME * 0.05) * 900.0);
	tinted *= mix(1.0, scan, a);

	// Breathing vignette.
	float d = distance(uv, vec2(0.5));
	float vig = smoothstep(0.85, 0.35, d);
	tinted *= mix(1.0, vig * (0.9 + 0.1 * sin(TIME * 2.0)), a);

	COLOR = vec4(mix(col, tinted, a), 1.0);
}
