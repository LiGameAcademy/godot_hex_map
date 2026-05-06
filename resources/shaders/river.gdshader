shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

uniform sampler2D _main_tex : source_color;
uniform vec4 _color : source_color = vec4(0.2, 0.4, 0.9, 0.6);
uniform float _metallic : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float _glossiness : hint_range(0.0, 1.0, 0.1) = 0.5;

uniform float flow_speed : hint_range(0.0, 5.0) = 1.0;
uniform float u_scale : hint_range(0.0, 1.0) = 0.0625;
uniform float highlight_strength : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec2 uv = UV;
	uv.x = fract(uv.x * u_scale + TIME * 0.005);
	uv.y -= fract(TIME * flow_speed);
	
	vec2 uv2 = UV;
	uv2.x = fract(uv2.x * u_scale + TIME * 0.0052);
	uv2.y -= fract(TIME * (flow_speed - 0.02));

	vec4 noise_sample = texture(_main_tex, uv);
	vec4 noise_sample2 = texture(_main_tex, uv2);
	float blend_noise = noise_sample.r * noise_sample2.r;
	
	vec3 albedo = clamp(_color.rgb + vec3(blend_noise * highlight_strength), 0.0, 1.0);
	float alpha = clamp(_color.a + blend_noise * highlight_strength, 0.0, 1.0);
	
	METALLIC = _metallic;
	ROUGHNESS = clamp(1.0 - _glossiness, 0.0, 1.0);
	ALBEDO = albedo;
	ALPHA = alpha;
}