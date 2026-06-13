shader_type spatial;
// Procedural forest floor: blends moss and dirt with value-noise fBm so the
// large ground plane reads as varied terrain rather than a flat colour. Pure
// procedural (no textures), portable across macOS/Windows.

uniform vec3 moss : source_color = vec3(0.13, 0.20, 0.11);
uniform vec3 dirt : source_color = vec3(0.22, 0.17, 0.11);
uniform float detail_scale = 0.15;
uniform float patch_scale = 0.04;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = fbm(world_pos.xz * detail_scale);
	float patch = fbm(world_pos.xz * patch_scale + vec2(10.0));
	vec3 col = mix(moss, dirt, smoothstep(0.40, 0.65, patch));
	col *= 0.72 + 0.55 * n;
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
