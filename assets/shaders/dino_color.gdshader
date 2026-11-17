shader_type canvas_item;

// How far to turn the colors around the color wheel.
// 0.0 = the original colors, 0.33 = red becomes green, 0.67 = red becomes blue.
uniform float hue_shift : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Rotate the color around the grey axis. Black, white and greys sit on
	// that axis, so they stay the same and only the hue of the rest changes.
	vec3 grey_axis = vec3(0.57735);
	float angle = hue_shift * TAU;
	COLOR.rgb = COLOR.rgb * cos(angle)
		+ cross(grey_axis, COLOR.rgb) * sin(angle)
		+ grey_axis * dot(grey_axis, COLOR.rgb) * (1.0 - cos(angle));
}
