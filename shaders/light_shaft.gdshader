shader_type spatial;
// Soft volumetric "god-ray" beams. Each shaft is a quad, but it (a) cylindrically
// Y-billboards so it always faces the camera — you never catch the flat edge and
// see a rectangle — and (b) feathers ALL edges to zero, so it reads as a soft
// column of light, not a card. Additive, writes no depth, occluded by geometry
// in front. Subtle by design; the volumetric haze + fog sun-scatter do the rest.
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec3 shaft_color : source_color = vec3(1.0, 0.95, 0.80);
uniform float intensity = 0.22;

void vertex() {
	// Cylindrical billboard: keep the beam vertical (world up, scaled by height),
	// rotate around Y to face the camera. Hides the quad's flat profile entirely.
	float w = length(MODEL_MATRIX[0].xyz);
	float h = length(MODEL_MATRIX[1].xyz);
	vec3 sx = normalize(INV_VIEW_MATRIX[0].xyz) * w;   // camera-right * width
	vec3 sy = vec3(0.0, 1.0, 0.0) * h;                 // world up * height
	vec3 sz = normalize(INV_VIEW_MATRIX[2].xyz) * w;   // camera-forward
	mat4 mw = mat4(vec4(sx, 0.0), vec4(sy, 0.0), vec4(sz, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * mw;
}

void fragment() {
	// Soft horizontal falloff (bright core column, edges -> 0).
	float dx = abs(UV.x - 0.5) * 2.0;
	float fx = pow(clamp(1.0 - dx, 0.0, 1.0), 1.9);
	// Vertical: ease in softly at the top (light entering the canopy), fade out
	// toward the ground — no hard top/bottom edge.
	float fy = smoothstep(0.0, 0.22, UV.y) * pow(clamp(1.0 - UV.y, 0.0, 1.0), 0.9);
	float flick = 0.9 + 0.1 * sin(TIME * 0.55 + UV.y * 3.0);
	ALBEDO = shaft_color * (fx * fy * intensity * flick);
}
