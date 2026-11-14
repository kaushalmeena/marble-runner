shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
// The surface of a pool.
//
// Water is drawn as this one sheet and nothing else. A see-through box would
// put faces exactly on the pool's walls and floor, and two surfaces in the
// same place flicker as the camera moves. Seen from above, a tinted sheet
// already colours everything under it.

uniform vec3 deep : source_color = vec3(0.06, 0.3, 0.72);
uniform vec3 shallow : source_color = vec3(0.3, 0.7, 0.98);
uniform float opacity : hint_range(0.0, 1.0) = 0.62;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME * 0.8;
	// Two crossing swells and a finer chop, from position so neighbouring
	// pools would line up.
	float swell = sin(world_position.x * 1.7 + t) * sin(world_position.z * 1.3 - t * 1.2)
		+ 0.5 * sin((world_position.x + world_position.z) * 2.9 + t * 1.7);
	float crest = smoothstep(0.8, 1.25, swell);
	ALBEDO = mix(deep, shallow, clamp(0.5 + 0.3 * swell, 0.0, 1.0)) + crest * 0.22;
	ALPHA = opacity;
	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
}
