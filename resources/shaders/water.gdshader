shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

#include "res://resources/shaders/water_math.gdshaderinc"

uniform sampler2D _main_tex : source_color;
uniform vec4 _color : source_color = vec4(0.2, 0.4, 0.9, 0.6);
uniform float _metallic : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float _glossiness : hint_range(0.0, 1.0, 0.1) = 0.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float waves = get_waves(world_position.xz, _main_tex, TIME);

	vec3 c = clamp(_color.rgb + vec3(waves), 0.0, 1.0);
	float alpha = clamp(_color.a, 0.0, 1.0);
	
	METALLIC = _metallic;
	ROUGHNESS = clamp(1.0 - _glossiness, 0.0, 1.0);
	ALBEDO = c.rgb;
	//ALBEDO = vec3(blend_wave);
	ALPHA = alpha;
}