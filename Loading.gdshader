shader_type canvas_item;

group_uniforms arrows;
/** Arrow amount in the circle */
uniform float arrows_amount: hint_range(1.0, 16.0, 1.0) = 1.0;
/** Screw of the arrow */
uniform float screw_facor: hint_range(-8.0, 8.0, 1e-3) = 0.0;
/** Revolutions per second */
uniform float rotation_frequency: hint_range(-32.0, 32.0, 1e-3) = 1.0;
/** Half angular width of the arrow, in radians */
uniform float angle_half_width: hint_range(0.0, 3.142, 1e-3) = 0.24;
/** Angular edge smoothing, in radians */
uniform float angle_softness: hint_range(0.0, 6.284, 1e-3) = 0.02;

group_uniforms borders;
/** Inner radius of the visible ring, normalized [0–1] */
uniform float inner_radius: hint_range(0.0, 1.0, 1e-3) = 0.2;
/** Outer radius of the visible ring, normalized [0–1] */
uniform float outer_radius: hint_range(0.0, 1.0, 1e-3) = 0.9;
/** Radial edge smoothing amount */
uniform float radius_softness: hint_range(0.0, 1.0, 1e-3) = 0.02;

/** Background color of the ring */
uniform vec4 base_color : source_color = vec4(0.2, 0.6, 0.7, 1.0);
/** Color of the rotating arrow */
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r2 = dot(uv, uv);
	
	if (r2 > 1.0) {
		discard;
	}
	
	float r = sqrt(r2);
	float angle = atan(uv.y, uv.x) * arrows_amount;
	float target = PI - mod(TIME * TAU * rotation_frequency * arrows_amount, TAU);
	
	float screw = r * screw_facor;
	float d = abs(mod(angle - target + screw * PI, TAU) - PI);
	
	float angular =
		1.0 - smoothstep(
			arrows_amount * angle_half_width,
			arrows_amount * angle_half_width + angle_softness * arrows_amount,
			d
		);

	float radial =
		smoothstep(inner_radius, inner_radius + radius_softness, r) *
		(1.0 - smoothstep(outer_radius, outer_radius + radius_softness, r));
	
	float mask = angular * radial;
	
	COLOR = mix(base_color, line_color, mask);
}
