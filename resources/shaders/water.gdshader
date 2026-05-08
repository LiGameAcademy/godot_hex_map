shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

uniform sampler2D _main_tex : source_color;
uniform vec4 _color : source_color = vec4(0.2, 0.4, 0.9, 0.6);
uniform float _metallic : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float _glossiness : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform bool use_main_tex = false;

void fragment() {
	vec3 albedo = clamp(_color.rgb, 0.0, 1.0);
	if (use_main_tex){
		albedo *= texture(_main_tex, UV).rgb;
	}

	float alpha = clamp(_color.a, 0.0, 1.0);
	
	METALLIC = _metallic;
	ROUGHNESS = clamp(1.0 - _glossiness, 0.0, 1.0);
	ALBEDO = albedo;
	ALPHA = alpha;
}