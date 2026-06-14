shader_type spatial;
// A calm forest pond: animated ripple normals, fresnel-driven transparency
// (clearer looking straight down, mirror-bright at grazing angles), low
// roughness so it reflects the HDRI sky, and a depth tint. No screen reads, so
// it's cheap and macOS/Windows portable.
render_mode cull_back;

uniform vec3 shallow_color : source_color = vec3(0.16, 0.40, 0.42);
uniform vec3 deep_color : source_color = vec3(0.03, 0.11, 0.16);
uniform float ripple_speed = 0.5;
uniform float ripple_strength = 0.12;
uniform float ripple_scale = 6.0;

void fragment() {
	float t = TIME * ripple_speed;
	vec2 uv = UV * ripple_scale;
	// Crossed travelling sine waves perturb the surface normal (tangent space).
	float rx = sin(uv.x * 1.0 + t) + 0.5 * sin(uv.x * 2.3 - t * 1.4 + uv.y);
	float rz = cos(uv.y * 1.1 + t * 0.9) + 0.5 * sin(uv.y * 2.0 + t * 1.2 + uv.x);
	NORMAL_MAP = normalize(vec3(rx * ripple_strength, rz * ripple_strength, 1.0));
	NORMAL_MAP_DEPTH = 1.0;

	float fres = pow(clamp(1.0 - dot(normalize(VIEW), NORMAL), 0.0, 1.0), 2.5);
	ALBEDO = mix(deep_color, shallow_color, 0.45);
	ROUGHNESS = 0.03;
	METALLIC = 0.0;
	SPECULAR = 0.7;
	ALPHA = mix(0.62, 0.96, fres);
}
