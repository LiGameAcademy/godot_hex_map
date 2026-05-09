float get_waves(vec2 world_xz, sampler2D noise_tex, float time) {
	vec2 uv1 = world_xz;
	uv1.y -= TIME * 2.0;
	vec4 noise1 = texture(noise_tex, uv1 * 0.025);

	vec2 uv2 = world_xz;
	uv2.x -= TIME * 2.0;
	vec4 noise2 = texture(noise_tex, uv2 * 0.025);

	float blend_wave = sin((world_xz.x + world_xz.y) * 0.1 + (noise1.y + noise2.z) + time);
	blend_wave *= blend_wave;

	float waves = mix(noise1.z, noise1.w, blend_wave) + mix(noise2.x, noise2.y, blend_wave);
	waves = smoothstep(0.75, 2, waves);

	return waves;
}

float get_foam(float shore_value, vec2 world_xz, sampler2D noise_tex, float time) {
	float shore = sqrt(shore_value) * 0.9;

	vec2 noise_uv = world_xz + TIME * 0.25;
	vec4 noise = texture(noise_tex, noise_uv * 0.015);
	float distortion1 = noise.x * (1.0 - shore);
	float foam1 = sin((shore + distortion1) * 10.0 - TIME);
	foam1 *= foam1;
	
	float distortion2 = noise.y * (1.0 - shore);
	float foam2 = sin((shore + distortion2) * 10.0 + TIME + 2.0);
	foam2 *= foam2 * 0.7;

	float foam = max(foam1, foam2) * shore;
	return foam;
}