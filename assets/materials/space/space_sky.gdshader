shader_type sky;
// Deep-space base sky: very dark navy gradient plus a warm distant star (disc + halo).
// Cheap by design: no noise, no TIME. Stars and nebulae are separate layers.
// The full sun is only drawn for the visible background, not the radiance cubemap,
// so ambient light stays a calm, dark blue.

uniform vec4 zenith_color : source_color = vec4(0.012, 0.028, 0.075, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.004, 0.009, 0.028, 1.0);

uniform vec3 sun_direction = vec3(0.0, 0.0, -1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.86, 0.68, 1.0);
uniform float sun_radius = 0.010;       // angular radius of the disc, radians
uniform float sun_disc_energy = 8.0;    // >1 so glow/bloom picks it up
uniform float sun_halo_size = 0.12;     // halo falloff, radians
uniform float sun_halo_energy = 0.55;

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y * 0.5 + 0.5;
	vec3 col = mix(horizon_color.rgb, zenith_color.rgb, smoothstep(0.15, 1.0, h));

	if (!AT_CUBEMAP_PASS) {
		vec3 sd = normalize(sun_direction);
		float ang = acos(clamp(dot(d, sd), -1.0, 1.0));
		float disc = 1.0 - smoothstep(sun_radius * 0.75, sun_radius, ang);
		float halo = exp(-ang / sun_halo_size);
		col += sun_color.rgb * (disc * sun_disc_energy + halo * sun_halo_energy);
	}
	COLOR = col;
}
