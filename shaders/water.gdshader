shader_type spatial;
// Trunk Bay (St. John, USVI) tropical water: brilliant turquoise that is glass-
// clear over the pale sandy shallows and deepens to teal-blue in the basin.
// Depth is read from the opaque DEPTH_TEXTURE to drive both the colour ramp and
// the transparency (clear at the shoreline, richer turquoise where it's deep),
// with a bright foam line where water meets land, animated ripple normals for
// sun sparkle, and a fresnel sky reflection at grazing angles.
render_mode cull_back;

uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;
uniform vec3 shallow_color : source_color = vec3(0.22, 0.80, 0.80);
uniform vec3 deep_color : source_color = vec3(0.0, 0.45, 0.66);
uniform vec3 foam_color : source_color = vec3(0.92, 0.99, 0.99);
uniform vec3 sky_color : source_color = vec3(0.72, 0.90, 1.0);
uniform float depth_dist = 1.5;     // metres of water to reach full deep_color
uniform float clarity = 0.34;       // alpha in the shallows (lower = clearer)
uniform float glow = 0.16;          // self-lit turquoise so it pops in canopy shade
uniform float ripple_speed = 0.45;
uniform float ripple_strength = 0.07;
uniform float ripple_scale = 7.0;

void fragment() {
	// --- ripple normals (sun sparkle + reflection break-up) ---
	float t = TIME * ripple_speed;
	vec2 uv = UV * ripple_scale;
	float rx = sin(uv.x + t) + 0.5 * sin(uv.x * 2.3 - t * 1.4 + uv.y);
	float rz = cos(uv.y * 1.1 + t * 0.9) + 0.5 * sin(uv.y * 2.0 + t * 1.2 + uv.x);
	NORMAL_MAP = normalize(vec3(rx * ripple_strength, rz * ripple_strength, 1.0));
	NORMAL_MAP_DEPTH = 1.0;

	// --- water thickness from the opaque depth buffer (Godot 4 reconstruction) ---
	float raw = texture(depth_tex, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, raw) * 2.0 - 1.0;
	vec4 vp = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vp.xyz /= vp.w;
	float scene_depth = -vp.z;          // distance to the sandy bottom
	float frag_depth = -VERTEX.z;       // distance to the water surface
	float thickness = clamp(scene_depth - frag_depth, 0.0, 50.0);
	float fade = clamp(thickness / depth_dist, 0.0, 1.0);

	// --- colour ramp shallow -> deep, thin foam at the shoreline, sky at grazing ---
	vec3 col = mix(shallow_color, deep_color, fade);
	float foam = 1.0 - smoothstep(0.0, 0.07, thickness);
	col = mix(col, foam_color, foam * 0.5);
	float fres = pow(clamp(1.0 - dot(normalize(VIEW), NORMAL), 0.0, 1.0), 4.0);
	col = mix(col, sky_color, fres * 0.35);

	ALBEDO = col;
	// A faint turquoise self-glow keeps the water luminous even under the canopy,
	// the way Trunk Bay glows from light scattering off the white sand.
	EMISSION = mix(shallow_color, deep_color, fade) * glow;
	ROUGHNESS = 0.04;
	METALLIC = 0.0;
	SPECULAR = 0.85;
	// Clear over the sand in the shallows, turquoise-rich in the deep, and more
	// opaque at the foam line and at grazing reflections.
	float a = mix(clarity, 0.94, fade);
	a = max(a, foam * 0.85);
	a = max(a, fres * 0.6);
	ALPHA = a;
}
