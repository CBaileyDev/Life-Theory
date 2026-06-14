shader_type spatial;
// Alpha-tested, wind-swayed grass for the MultiMesh carpet. Each instance's
// sway phase derives from its world origin (MODEL_MATRIX[3] is the per-instance
// transform under a MultiMesh), so the whole field ripples as one coherent wave.
// Double-sided so grass cards read from both faces. macOS/Windows portable.
render_mode cull_disabled, world_vertex_coords;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float alpha_cut = 0.5;
uniform vec3 tint : source_color = vec3(1.0, 1.0, 0.92);
uniform float sway_strength = 0.10;
uniform float sway_speed = 1.4;
uniform float roughness_val = 0.92;

void vertex() {
	// VERTEX is in world space (world_vertex_coords). Recover the instance
	// origin from the model matrix for a per-clump phase.
	vec3 wo = MODEL_MATRIX[3].xyz;
	float phase = wo.x * 0.5 + wo.z * 0.4 + TIME * sway_speed;
	// Height above the clump base drives sway (tips move, roots stay planted).
	float h = clamp((VERTEX.y - wo.y) * 6.0, 0.0, 1.0);
	float gust = 0.6 + 0.4 * sin(TIME * 0.7 + wo.x * 0.1);
	VERTEX.x += sin(phase) * sway_strength * h * gust;
	VERTEX.z += cos(phase * 0.8) * sway_strength * h * gust;
}

void fragment() {
	vec4 c = texture(albedo_tex, UV);
	// The grass atlas is blades on pure black. Use proper ALPHA_SCISSOR (not a
	// raw discard) so Godot's DEPTH PREPASS respects the cutout — a raw discard
	// let the full quad write depth in the prepass, occluding the terrain behind
	// and showing the sky background through the gaps ("see-through ground").
	float lum = max(c.r, max(c.g, c.b));
	// COLOR carries the MultiMesh per-instance tint for natural clump variation.
	ALBEDO = c.rgb * tint * 1.25 * COLOR.rgb;
	ALPHA = min(c.a < 1.0 ? c.a : 1.0, step(0.05, lum));
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.1;
}
