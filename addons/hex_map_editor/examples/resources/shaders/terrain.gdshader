shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2DArray terrain_textures : source_color, repeat_enable;
uniform float texture_scale: hint_range(0.01, 1.0) = 0.02;

varying vec3 terrain_layers;
varying vec3 world_pos;

void vertex() {
	terrain_layers = CUSTOM0.rgb;
	world_pos = VERTEX;
}

void fragment() {
	vec2 uv = world_pos.xz * max(texture_scale, 1e-4);
	vec3 w = COLOR.rgb;
	vec3 idx = terrain_layers;

	vec3 c0 = texture(terrain_textures, vec3(uv, idx.x)).rgb;
	vec3 c1 = texture(terrain_textures, vec3(uv, idx.y)).rgb;
	vec3 c2 = texture(terrain_textures, vec3(uv, idx.z)).rgb;

	ALBEDO = (c0 * w.x + c1 * w.y + c2 * w.z);
}
