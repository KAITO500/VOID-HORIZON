shader_type canvas_item;
render_mode blend_add;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float aspect_ratio = 1.7778;
uniform vec4 streak_color : source_color = vec4(0.82, 0.88, 0.84, 1.0);

float ray_hash(float value) {
	return fract(sin(value * 127.1 + 311.7) * 43758.5453);
}

void fragment() {
	vec2 position = UV * 2.0 - 1.0;
	position.x *= aspect_ratio;
	float radius = length(position);
	float angle = atan(position.y, position.x);
	const float ray_count = 92.0;
	float ray_coordinate = (angle / 6.28318530718 + 0.5) * ray_count;
	float ray_id = floor(ray_coordinate);
	float seed = ray_hash(ray_id);
	float angular_offset = abs(fract(ray_coordinate + seed) - 0.5);
	float ray = 1.0 - smoothstep(0.018, 0.042, angular_offset);
	float chosen_ray = smoothstep(0.28, 0.42, seed);

	// Segments slide outward along each ray. The center remains clear for piloting and HUD legibility.
	float radial_flow = fract(radius * 2.8 - TIME * (0.35 + intensity * 3.8) + seed);
	float segment = smoothstep(0.55, 0.63, radial_flow) * (1.0 - smoothstep(0.91, 0.98, radial_flow));
	float center_fade = smoothstep(0.16, 0.34, radius);
	float edge_fade = 1.0 - smoothstep(0.94, 1.42, radius);
	float alpha = ray * chosen_ray * segment * center_fade * edge_fade * intensity * 0.32;
	COLOR = vec4(streak_color.rgb, alpha);
}
