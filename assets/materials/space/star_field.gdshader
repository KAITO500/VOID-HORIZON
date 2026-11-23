shader_type spatial;
// Billboarded additive star sprite for the StarField MultiMesh (one draw call).
// Per-instance COLOR: rgb = tint, a = brightness (0..1).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform float intensity = 1.0;
uniform float peak = 1.4;       // brightest stars slightly exceed 1.0 so they bloom
uniform float falloff = 2.5;    // higher = tighter, sharper star

varying vec4 v_color;

void vertex() {
	v_color = COLOR;
	// Face the camera but keep the instance scale (see spatial shader billboard docs).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	float shape = pow(max(1.0 - d, 0.0), falloff);
	ALBEDO = v_color.rgb * v_color.a * shape * intensity * peak;
	ALPHA = 1.0;
}
