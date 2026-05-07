shader_type spatial;
//render_mode unshaded, cull_disabled, depth_test_disabled;
render_mode unshaded;

uniform vec4 road_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
uniform sampler2D noise_tex : repeat_enable;
uniform vec2 alpha_smoothstep = vec2(0.4, 0.7);
uniform float noise_scale = 0.025;
uniform float color_noise_strength = 0.75;
uniform float color_noise_bias = 0.25;

uniform float normal_offset = 0.02;

varying vec3 world_pos;

void vertex() {
	VERTEX += NORMAL * normal_offset;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 noise = texture(noise_tex, world_pos.xz * noise_scale);
	float blend = UV.x;
	blend *= noise.x + 0.5;
	blend = smoothstep(alpha_smoothstep.x, alpha_smoothstep.y, blend);
	
	ALBEDO = road_color.rgb * (noise.y * color_noise_strength + color_noise_bias);
	ALPHA = road_color.a * blend;
}
