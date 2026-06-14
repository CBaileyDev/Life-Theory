shader_type spatial;
// Glowing wireframe-grid seam for the Loomstrata — the simulation's structure
// showing through where nature used to be. Additive emissive grid lines on a
// quad, transparent between, double-sided, no depth occlusion. Cheap.
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec3 grid_color : source_color = vec3(0.35, 0.75, 1.0);
uniform float cells = 5.0;
uniform float line_w = 0.06;
uniform float intensity = 1.6;

void fragment() {
	vec2 f = fract(UV * cells);
	vec2 e = min(f, 1.0 - f);                 // distance to nearest cell edge
	float line = 1.0 - smoothstep(0.0, line_w, min(e.x, e.y));
	// A slow flicker sells the unstable render.
	float flick = 0.75 + 0.25 * sin(TIME * 3.0 + UV.x * 8.0);
	ALBEDO = grid_color * line * intensity * flick;
}
