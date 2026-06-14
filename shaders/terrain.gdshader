shader_type spatial;
// ---------------------------------------------------------------------------
// terrain.gdshader — the forest floor, rendered as a real splat-mapped terrain.
//
// Three CC0 PBR layers (grass / forest-floor-dirt / rock-cliff) are blended in
// the fragment shader by SLOPE (rock on steep ground), MACRO NOISE (organic
// dirt/grass patches so it never looks tiled), and a PATH MASK (a worn dirt
// trail from the spawn to the clearing — replaces the old flat grey plane).
//
// All sampling is world-space TRIPLANAR, so cliffs and overhangs never stretch,
// and two tiling scales are mixed to break up obvious texture repetition.
// Lighting is Godot's standard PBR. macOS (Metal) / Windows (Vulkan) portable.
// ---------------------------------------------------------------------------

// cull_disabled: the procedural ground mesh's triangle winding makes its top
// faces back-faces, so flat ground viewed from above was culled and showed the
// sky through it ("see-through ground"). Rendering both sides fixes it cheaply
// (the heightfield is a single thin surface; no z-fighting, lighting stays
// correct as Godot flips the normal for the visible side).
render_mode cull_disabled;

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_rough  : hint_roughness_gray, filter_linear_mipmap, repeat_enable;

uniform sampler2D floor_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D floor_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D floor_rough  : hint_roughness_gray, filter_linear_mipmap, repeat_enable;

uniform sampler2D cliff_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D cliff_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D cliff_rough  : hint_roughness_gray, filter_linear_mipmap, repeat_enable;

// Tiling: detail (close-up) and macro (far) scales blended to hide repetition.
uniform float grass_scale = 0.28;
uniform float floor_scale = 0.30;
uniform float cliff_scale = 0.16;
uniform float macro_scale = 0.045;   // big organic dirt/grass patches

// Per-biome colour grade applied to the whole floor (Quietwood warm green,
// Loomstrata cooler/violet). Set from WorldBuilder.
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float normal_strength = 1.0;

// Path corridor (world space), matched to WorldBuilder constants.
uniform float path_half_width = 2.6;
uniform float path_z_min = 0.0;
uniform float path_z_max = 18.5;
uniform float path_feather = 2.2;

varying vec3 v_wpos;
varying vec3 v_wnorm;
// Per-vertex cover field baked by WorldBuilder: r = grassiness (1 lush .. 0 bare
// dirt), g = trail wear (0 .. 1, damp trodden earth). The SAME field thins the
// grass MultiMesh, so exposed soil and worn trails in the texture line up with
// where the grass blades actually disappear (AAA splat/density-map workflow).
varying vec4 v_cover;

// --- cheap value noise (hash-based), for macro patch variation ----------------
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * vnoise(p); p *= 2.02; a *= 0.5; }
	return v;
}

// --- world-space triplanar colour sample, two scales mixed --------------------
vec3 tri_col(sampler2D tex, vec3 wp, vec3 bw, float s) {
	vec3 a = texture(tex, wp.zy * s).rgb;
	vec3 b = texture(tex, wp.xz * s).rgb;
	vec3 c = texture(tex, wp.xy * s).rgb;
	vec3 detail = a * bw.x + b * bw.y + c * bw.z;
	// Macro tile at 0.37x scale, slightly de-correlated, to break repetition.
	float ms = s * 0.37;
	vec3 a2 = texture(tex, wp.zy * ms + 3.1).rgb;
	vec3 b2 = texture(tex, wp.xz * ms + 5.7).rgb;
	vec3 c2 = texture(tex, wp.xy * ms + 1.3).rgb;
	vec3 macro = a2 * bw.x + b2 * bw.y + c2 * bw.z;
	return mix(detail, macro, 0.4);
}
float tri_r(sampler2D tex, vec3 wp, vec3 bw, float s) {
	return texture(tex, wp.zy * s).r * bw.x
		 + texture(tex, wp.xz * s).r * bw.y
		 + texture(tex, wp.xy * s).r * bw.z;
}
// Whiteout-blended triplanar normal -> world space.
vec3 tri_norm(sampler2D tex, vec3 wp, vec3 wn, vec3 bw, float s) {
	vec3 nx = texture(tex, wp.zy * s).xyz * 2.0 - 1.0;
	vec3 ny = texture(tex, wp.xz * s).xyz * 2.0 - 1.0;
	vec3 nz = texture(tex, wp.xy * s).xyz * 2.0 - 1.0;
	nx = vec3(nx.xy + wn.zy, abs(nx.z) * wn.x);
	ny = vec3(ny.xy + wn.xz, abs(ny.z) * wn.y);
	nz = vec3(nz.xy + wn.xy, abs(nz.z) * wn.z);
	return normalize(nx.zyx * bw.x + ny.xzy * bw.y + nz.xyz * bw.z);
}

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_cover = COLOR;
}

void fragment() {
	vec3 wp = v_wpos;
	vec3 wn = normalize(v_wnorm);
	vec3 bw = pow(abs(wn), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);

	// --- blend weights -------------------------------------------------------
	float slope = 1.0 - clamp(wn.y, 0.0, 1.0);                 // 0 flat .. 1 vertical
	float rockw = smoothstep(0.30, 0.62, slope);              // rock on steep faces

	// Grass <-> bare-dirt split comes from the baked cover field (the same field
	// that thins the grass MultiMesh), so soil shows through exactly where the
	// blades disappear. A whisper of macro noise only roughens the boundary so it
	// doesn't read as a hard painted edge.
	float grassiness = v_cover.r;
	float wear = v_cover.g;
	float macro = fbm(wp.xz * macro_scale);
	float floorw = clamp((1.0 - grassiness) + (macro - 0.5) * 0.18, 0.0, 1.0);
	// Trodden trails are bare earth regardless of the grass field.
	floorw = clamp(max(floorw, wear), 0.0, 1.0);

	// --- sample + composite --------------------------------------------------
	vec3 g_a = tri_col(grass_albedo, wp, bw, grass_scale);
	vec3 f_a = tri_col(floor_albedo, wp, bw, floor_scale);
	vec3 c_a = tri_col(cliff_albedo, wp, bw, cliff_scale);
	float g_r = tri_r(grass_rough, wp, bw, grass_scale);
	float f_r = tri_r(floor_rough, wp, bw, floor_scale);
	float c_r = tri_r(cliff_rough, wp, bw, cliff_scale);
	vec3 g_n = tri_norm(grass_normal, wp, wn, bw, grass_scale);
	vec3 f_n = tri_norm(floor_normal, wp, wn, bw, floor_scale);
	vec3 c_n = tri_norm(cliff_normal, wp, wn, bw, cliff_scale);

	float fw = floorw * (1.0 - rockw);
	vec3 alb = mix(g_a, f_a, fw);
	alb = mix(alb, c_a, rockw);
	float rgh = mix(mix(g_r, f_r, fw), c_r, rockw);
	vec3 nrm = normalize(mix(mix(g_n, f_n, fw), c_n, rockw));

	// Subtle large-scale ambient-occlusion-ish darkening in the dirt hollows.
	float ao = mix(1.0, 0.82, floorw * 0.6);
	// Trodden trails are damp, compacted, darker earth — sink them below the
	// loose dirt patches so the path network reads as walked-in, not just bare.
	float trail_dark = mix(1.0, 0.76, wear);

	ALBEDO = alb * tint * ao * trail_dark;
	// Forest floor is MATTE: keep roughness high and specular low, or the flat
	// ground mirror-reflects the sky/HDRI and reads as see-through water/glass.
	ROUGHNESS = clamp(rgh, 0.9, 1.0);
	SPECULAR = 0.0;   // no specular sky-mirror on the dirt — pure matte diffuse
	// World normal -> view space for Godot's lighting.
	vec3 vn = (VIEW_MATRIX * vec4(mix(wn, nrm, normal_strength), 0.0)).xyz;
	NORMAL = normalize(vn);
}
