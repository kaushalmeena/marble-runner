shader_type spatial;
render_mode cull_back, diffuse_burley;

// Bends the track sideways as a function of depth, so the road appears to wind
// away into the distance.
//
// The bend is zero at the player's depth by construction (the sin(phase) term),
// which is the whole trick: every prop's X converges on its true lane centre
// exactly where the player is standing. The curve is drama, not difficulty -
// which lane you need to be in never changes.
//
// Lane stripes are drawn here from the pre-bend X rather than as separate
// meshes, so they follow the curve for free and the ground is one draw call.

uniform vec4 albedo : source_color = vec4(0.42, 0.62, 0.35, 1.0);
uniform vec4 stripe_color : source_color = vec4(0.12, 0.26, 0.13, 0.3);
uniform float roughness : hint_range(0.0, 1.0) = 0.95;

uniform float lane_spacing = 5.0;
uniform float stripe_width = 0.18;

uniform float curve_amplitude = 0.0;
uniform float curve_wavelength = 240.0;
uniform float curve_phase = 0.0;
uniform float curve_pivot_z = 10.0;

// Pre-bend X, needed in the fragment stage to place lane stripes.
varying float lane_x;

float track_bend(float world_z) {
	float k = TAU / max(1.0, curve_wavelength);
	return curve_amplitude * (sin(curve_phase + (world_z - curve_pivot_z) * k)
		- sin(curve_phase));
}

void vertex() {
	lane_x = VERTEX.x;
	float world_z = (MODEL_MATRIX * vec4(VERTEX, 1.0)).z;
	VERTEX.x += track_bend(world_z);
}

void fragment() {
	// Lane boundaries sit half a lane off the centres, so shifting by 0.5 puts
	// them on integers and the distance to one is the distance to a stripe.
	float t = lane_x / lane_spacing + 0.5;
	float edge_distance = abs(t - round(t)) * lane_spacing;
	float stripe = 1.0 - smoothstep(stripe_width * 0.5, stripe_width * 0.5 + 0.05,
		edge_distance);

	ALBEDO = mix(albedo.rgb, stripe_color.rgb, stripe * stripe_color.a);
	ROUGHNESS = roughness;
}
