shader_type spatial;
// Stylized gas giant placeholder: latitude bands warped by noise, plus a soft atmosphere rim.
// Lit by the scene's DirectionalLight3D (StarLightingController). No textures.
render_mode specular_disabled;

#include "res://assets/materials/space/space_noise.gdshaderinc"

uniform vec4 color_a : source_color = vec4(0.06, 0.12, 0.34, 1.0);  // deep blue
uniform vec4 color_b : source_color = vec4(0.30, 0.16, 0.52, 1.0);  // violet
uniform vec4 color_c : source_color = vec4(0.30, 0.65, 0.85, 1.0);  // pale cyan
uniform float band_frequency = 9.0;
uniform float turbulence = 0.35;
uniform vec3 seed_offset = vec3(3.1, 7.7, 1.9);
uniform vec4 atmosphere_color : source_color = vec4(0.25, 0.60, 1.0, 1.0);
uniform float atmosphere_strength = 0.55;
uniform float atmosphere_power = 3.0;

varying vec3 v_dir;

void vertex() {
	v_dir = normalize(VERTEX);
}

void fragment() {
	vec3 d = normalize(v_dir);
	float warp = fbm3(d * vec3(2.0, 10.0, 2.0) + seed_offset, 3);
	float phase = d.y * band_frequency * PI + (warp - 0.5) * turbulence * 12.0;
	float band = 0.5 + 0.5 * sin(phase);
	float band2 = 0.5 + 0.5 * sin(d.y * band_frequency * 0.37 * PI + 1.7 + (warp - 0.5) * 4.0);

	vec3 col = mix(color_a.rgb, color_b.rgb, band);
	col = mix(col, color_c.rgb, smoothstep(0.55, 1.0, band2) * 0.7);

	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), atmosphere_power);

	ALBEDO = col;
	ROUGHNESS = 0.95;
	EMISSION = atmosphere_color.rgb * fres * atmosphere_strength;
}
