shader_type spatial;
//render_mode unshaded, cull_disabled, depth_test_disabled;
render_mode unshaded;

uniform float normal_offset = 0.02;

void vertex() {
	VERTEX += NORMAL * normal_offset;
}

void fragment() {
	ALBEDO = vec3(UV.rg, 1.0);
}
