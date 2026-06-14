shader_type spatial;
// Soft additive "god-ray" light shafts — faint warm beams angled like the sun
// breaking through the canopy. Volumetric fog is off (it murked the scene), so
// these cheap additive cards give the shaft feel. Occluded by geometry in front
// (normal depth test) but write no depth. Subtle by design.
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec3 shaft_color : source_color = vec3(1.0, 0.93, 0.72);
uniform float intensity = 0.45;

void fragment() {
	float hx = 1.0 - abs(UV.x - 0.5) * 2.0;   // bright center column, soft edges
	hx = pow(clamp(hx, 0.0, 1.0), 2.2);
	float vy = pow(1.0 - UV.y, 1.3);          // brightest near the canopy, fading down
	float flick = 0.85 + 0.15 * sin(TIME * 0.7 + UV.y * 2.5);
	ALBEDO = shaft_color * (hx * vy * intensity * flick);
}
