shader_type spatial;

uniform sampler2D _main_tex : source_color;
uniform vec4 _color : source_color = vec4(0.2, 0.4, 0.9, 0.6);
uniform float _metallic : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float _glossiness : hint_range(0.0, 1.0, 0.1) = 0.5;

void fragment() {
	vec4 c = texture(_main_tex, UV) * _color;
	vec3 albedo = c.rgb;
	
	METALLIC = _metallic;
	ROUGHNESS = clamp(1.0 - _glossiness, 0.0, 1.0);
	//ALPHA = c.a;
	albedo.r = UV.x;
	albedo.g = UV.y;
	ALBEDO = albedo;
}