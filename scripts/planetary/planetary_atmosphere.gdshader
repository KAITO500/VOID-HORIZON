shader_type spatial;
render_mode unshaded, cull_front, blend_mix, depth_draw_never, shadows_disabled;

uniform vec4 atmosphere_color : source_color = vec4(0.77, 0.54, 0.36, 1.0);
uniform float density : hint_range(0.0, 2.0) = 0.42;
uniform float rim_power : hint_range(0.5, 8.0) = 2.4;
uniform float approach_blend : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float rim = pow(clamp(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), rim_power);
	ALBEDO = atmosphere_color.rgb;
	EMISSION = atmosphere_color.rgb * 0.12;
	ALPHA = clamp(rim * density * approach_blend, 0.0, 0.48);
}
