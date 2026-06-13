shader_type spatial;
// Gentle wind sway for foliage (tree canopies, bushes, grass). Each instance
// sways on its own phase derived from its world position, with more movement
// toward the top of the mesh so trunks/bases stay planted. Lighting is left to
// Godot's default PBR. Cheap and macOS/Windows-portable.
render_mode cull_disabled;

uniform vec3 albedo : source_color = vec3(0.13, 0.27, 0.16);
uniform float roughness = 0.92;
uniform float sway_strength = 0.15;
uniform float sway_speed = 1.1;

void vertex() {
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	float phase = world_origin.x * 0.6 + world_origin.z * 0.45 + TIME * sway_speed;
	float h = clamp(VERTEX.y * 0.5 + 0.5, 0.0, 2.0);
	VERTEX.x += sin(phase) * sway_strength * h;
	VERTEX.z += cos(phase * 0.85) * sway_strength * h;
}

void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = roughness;
}
