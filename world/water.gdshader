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

// Value noise: a random level at each grid corner, blended smoothly between.
float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 f = fract(point);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float t = TIME * 0.35;
	vec2 at = world_position.xz;
	// Sine swells repeat, and across a wide pool the eye picks the repeat out
	// at once. Noise does not: one slow layer bends the position the finer
	// layers are read at, and the layers drift in different directions, so no
	// patch of water ever looks like the patch beside it.
	vec2 bend = vec2(noise(at * 0.23 + vec2(t, -t * 0.7)), noise(at * 0.23 + vec2(-t * 0.6, t) + 7.3));
	vec2 warped = at + (bend - 0.5) * 3.0;
	float swell = noise(warped * 0.55 + vec2(t * 0.9, t * 0.4)) * 0.6
		+ noise(warped * 1.3 - vec2(t * 0.7, -t * 1.1)) * 0.3
		+ noise(warped * 2.9 + vec2(-t * 1.6, t * 1.3)) * 0.1;
	float crest = smoothstep(0.62, 0.74, swell);
	ALBEDO = mix(deep, shallow, smoothstep(0.25, 0.75, swell)) + crest * 0.2;
	ALPHA = opacity;
	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
}
