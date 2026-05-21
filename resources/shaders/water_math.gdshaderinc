float get_waves(vec2 world_xz, sampler2D noise_tex, float time) {
    // 1. 第一层波纹：沿 Z 轴缓慢滚动
	vec2 uv1 = world_xz;
	uv1.y -= time;
    float n1_z = texture(noise_tex, uv1 * 0.025).r;
    float n1_w = texture(noise_tex, uv1 * 0.025).g;

	vec2 uv2 = world_xz;
	uv2.x -= time;
	float n2_x = texture(noise_tex, uv2 * 0.025).b;
	float n2_y = texture(noise_tex, uv2 * 0.025).a;

	float blend_wave = sin((world_xz.x + world_xz.y) * 0.1 + (n1_z + n2_x) + time);
	blend_wave *= blend_wave;
	
	float waves = (mix(n1_z, n1_w, blend_wave) + mix(n2_x, n2_y, blend_wave)) * 0.5;
	return smoothstep(0.25, 0.75, waves);
}

float get_foam(float shore_value, vec2 world_xz, sampler2D noise_tex, float time) {
	float shore = sqrt(shore_value) * 0.9;

	vec2 noise_uv = world_xz + time * 0.25;
	vec4 noise = texture(noise_tex, noise_uv * 0.015);
	float distortion1 = noise.x * (1.0 - shore);
	float foam1 = sin((shore + distortion1) * 10.0 - time);
	foam1 *= foam1;

	float distortion2 = noise.y * (1.0 - shore);
	float foam2 = sin((shore + distortion2) * 10.0 + time + 2.0);
	foam2 *= foam2 * 0.7;
	
	float foam = max(foam1, foam2) * shore;
	return foam;
}