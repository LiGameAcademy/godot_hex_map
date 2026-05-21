shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

uniform sampler2D _main_tex : source_color;
uniform vec4 _color : source_color = vec4(0.2, 0.4, 0.9, 0.6);
uniform float _metallic : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float _glossiness : hint_range(0.0, 1.0, 0.1) = 0.5;

varying vec3 world_position;

void vertex() {
	// 模型空间 VERTEX → 世界坐标；fragment 里用 .xz 当作平面 UV
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv1 = world_position.xz;
	uv1.y -= TIME;
	vec4 noise1 = texture(_main_tex, uv1 * 0.025);

	vec2 uv2 = world_position.xz;
	uv2.x -= TIME;
	vec4 noise2 = texture(_main_tex, uv2 * 0.025);

	float blend_wave = sin((world_position.x + world_position.z) * 0.1 + (noise1.y + noise2.z) + TIME);
	blend_wave *= blend_wave;
	
	float waves = (mix(noise1.z, noise2.w, blend_wave) + mix(noise1.x, noise2.y, blend_wave)) * 0.5;
	waves = smoothstep(0.25, 0.75, waves);

	vec3 c = clamp(_color.rgb + vec3(waves), 0.0, 1.0);
	float alpha = clamp(_color.a, 0.0, 1.0);
	
	METALLIC = _metallic;
	ROUGHNESS = clamp(1.0 - _glossiness, 0.0, 1.0);
	ALBEDO = c;
	ALPHA = alpha;
}