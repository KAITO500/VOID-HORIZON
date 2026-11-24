shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
// Camera-relative "space dust": instances are random points in a cube; the vertex stage wraps them
// around `anchor` so a fixed pool always surrounds the ship. Gives parallax and a sense of speed.
// Each point is a camera-facing quad stretched along the screen-space velocity direction.

uniform vec3 anchor = vec3(0.0);
uniform vec3 velocity = vec3(0.0);
uniform float box_size = 500.0;
uniform float point_size = 0.35;
uniform float streak_per_speed = 0.012;
uniform float max_streak = 14.0;
uniform vec3 dust_color : source_color = vec3(0.6, 0.85, 0.85);
uniform float brightness = 0.8;

varying float v_fade;

void vertex() {
	vec3 base = MODEL_MATRIX[3].xyz;
	vec3 rel = mod(base - anchor + vec3(0.5 * box_size), vec3(box_size)) - vec3(0.5 * box_size);
	vec3 center_world = anchor + rel;
	vec4 center_view = VIEW_MATRIX * vec4(center_world, 1.0);

	vec3 vel_view = (VIEW_MATRIX * vec4(velocity, 0.0)).xyz;
	vec2 dir = vel_view.xy;
	float dir_len = length(dir);
	dir = dir_len > 0.0001 ? dir / dir_len : vec2(0.0, 1.0);
	vec2 side = vec2(-dir.y, dir.x);
	float streak = clamp(length(velocity) * streak_per_speed, 0.0, max_streak);

	vec2 offset = side * VERTEX.x * point_size + dir * VERTEX.y * (point_size + streak);
	center_view.xy += offset;
	POSITION = PROJECTION_MATRIX * center_view;

	float d = length(rel) / (0.5 * box_size);
	v_fade = (1.0 - smoothstep(0.55, 1.0, d)) * smoothstep(0.0, 0.08, d);
}

void fragment() {
	ALBEDO = dust_color * brightness * v_fade;
}
