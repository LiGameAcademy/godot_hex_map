shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

uniform sampler2D _main_tex : source_color;
uniform vec4 _color : source_color = vec4(0.2, 0.4, 0.9, 0.6);
uniform float _metallic : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float _glossiness : hint_range(0.0, 1.0, 0.1) = 0.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv1 = world_position.xz;
	uv1.y -= TIME * 2.0;
	vec4 noise1 = texture(_main_tex, uv1 * 0.025);

	vec2 uv2 = world_position.xz;
	uv2.x -= TIME * 2.0;
	vec4 noise2 = texture(_main_tex, uv2 * 0.025);

	float blend_wave = sin((world_position.x + world_position.z) * 0.1 + (noise1.y + noise2.z) + TIME);
	blend_wave *= blend_wave;

	float waves = mix(noise1.z, noise1.w, blend_wave) + mix(noise2.x, noise2.y, blend_wave);
	waves = smoothstep(0.75, 2, waves);

	//vec3 c = clamp(_color.rgb + vec3(waves), 0.0, 1.0);
	float alpha = clamp(_color.a, 0.0, 1.0);

	float shore = UV.y;
	shore = sqrt(shore);

	vec2 noise_uv = world_position.xz + TIME * 0.25;
	vec4 noise = texture(_main_tex, noise_uv * 0.015);
	float distortion1 = noise.x * (1.0 - shore);
	float foam1 = sin((shore + distortion1) * 10.0 - TIME);
	foam1 *= foam1;
	
	float distortion2 = noise.y * (1.0 - shore);
	float foam2 = sin((shore + distortion2) * 10.0 + TIME + 2.0);
	foam2 *= foam2 * 0.7;

	float foam = max(foam1, foam2) * shore;
	vec3 c = clamp(_color.rgb + vec3(foam), 0.0, 1.0);
	
	METALLIC = _metallic;
	ROUGHNESS = clamp(1.0 - _glossiness, 0.0, 1.0);
	ALBEDO = c.rgb;
	//ALBEDO = vec3(UV.x, UV.y, 1.0);
	ALPHA = alpha;
}