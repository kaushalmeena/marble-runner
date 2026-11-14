shader_type spatial;
// Checkerboard tiles for every platform in the game.
//
// The pattern is projected from position rather than from UVs, so a platform of
// any size gets square tiles with no texture and no unwrapping, and two
// platforms that touch line up. Moving platforms use their own space instead,
// or the tiles would slide across them as they travel.

uniform vec3 color_a : source_color = vec3(0.42, 0.62, 0.35);
uniform vec3 color_b : source_color = vec3(0.5, 0.7, 0.42);
uniform vec3 side_color : source_color = vec3(0.2, 0.3, 0.18);
uniform float cell = 2.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.75;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.0;
uniform bool local_space = false;

varying vec3 tile_position;
varying vec3 tile_normal;

void vertex() {
	if (local_space) {
		tile_position = VERTEX;
		tile_normal = NORMAL;
	} else {
		tile_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		tile_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	}
}

void fragment() {
	vec3 facing = abs(tile_normal);
	bool is_top = tile_normal.y > 0.6;
	vec2 uv = tile_position.xz;
	if (!is_top) {
		uv = facing.x > facing.z ? tile_position.zy : tile_position.xy;
	}
	vec2 scaled = uv / cell + 0.0005;
	vec2 tile = floor(scaled);
	vec2 inside = fract(scaled);
	float checker = mod(tile.x + tile.y, 2.0);
	// A thin dark seam between tiles gives the floor some grain at speed.
	float seam = 1.0 - step(0.03, min(min(inside.x, inside.y), min(1.0 - inside.x, 1.0 - inside.y)));

	vec3 top = mix(color_a, color_b, checker) * mix(1.0, 0.8, seam);
	vec3 side = side_color * mix(0.85, 1.0, checker);
	ALBEDO = is_top ? top : side;
	ROUGHNESS = roughness_value;
	METALLIC = metallic_value;
}
