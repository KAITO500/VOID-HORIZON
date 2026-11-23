shader_type spatial;
// Procedural nebula painted on the inside of a large sphere (NebulaLayer).
// Direction-based 3D fbm: no textures, no seams, one full-screen additive pass per layer.
render_mode unshaded, blend_add, depth_draw_never, cull_front, fog_disabled;

#include "res://assets/materials/space/space_noise.gdshaderinc"

uniform vec3 seed_offset = vec3(12.3, 4.5, 7.8);
uniform float noise_scale = 2.2;
uniform int octaves = 4;
uniform float threshold = 0.52;
uniform float softness = 0.35;
uniform float intensity = 0.35;
uniform vec4 color_a : source_color = vec4(0.28, 0.10, 0.55, 1.0);  // violet
uniform vec4 color_b : source_color = vec4(0.05, 0.25, 0.70, 1.0);  // electric blue
uniform vec4 color_c : source_color = vec4(0.00, 0.70, 0.90, 1.0);  // cyan accent
uniform vec3 band_normal = vec3(0.0, 1.0, 0.0);
uniform float band_strength = 0.6;  // 0 = uniform, 1 = only along the band
uniform float band_width = 0.5;

varying vec3 v_dir;

void vertex() {
	v_dir = normalize(VERTEX);
}

void fragment() {
	vec3 d = normalize(v_dir);
	vec3 p = d * noise_scale + seed_offset;

	float n = fbm3(p, octaves);
	float off_plane = smoothstep(0.0, band_width, abs(dot(d, normalize(band_normal))));
	float band = 1.0 - band_strength * off_plane;
	float density = smoothstep(threshold, threshold + softness, n) * band;

	float v = value_noise3(p * 0.6 + vec3(17.0));
	vec3 col = mix(color_a.rgb, color_b.rgb, smoothstep(0.25, 0.75, v));
	col = mix(col, color_c.rgb, pow(density, 3.0) * 0.6);

	ALBEDO = col * density * intensity;
	ALPHA = 1.0;
}
