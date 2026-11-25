shader_type spatial;
// Flat ring for the gas giant placeholder. Mesh is a PlaneMesh in the planet's equatorial plane.
// UV 0..1 across the plane; the ring is an annulus between `inner` and 1.0 (normalized).
render_mode blend_mix, cull_disabled, specular_disabled;

uniform vec4 ring_color : source_color = vec4(0.55, 0.65, 0.85, 1.0);
uniform float inner = 0.55;
uniform float opacity = 0.55;

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float edge = smoothstep(inner, inner + 0.03, r) * (1.0 - smoothstep(0.95, 1.0, r));
	float t = clamp((r - inner) / max(1.0 - inner, 0.001), 0.0, 1.0);
	float bands = clamp(0.55 + 0.25 * sin(t * 70.0) + 0.20 * sin(t * 23.0 + 1.3), 0.0, 1.0);
	ALBEDO = ring_color.rgb * (0.6 + 0.4 * bands);
	ROUGHNESS = 1.0;
	ALPHA = edge * opacity * bands;
}
