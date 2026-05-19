shader_type canvas_item;

uniform float health_percent : hint_range(0.0, 1.0) = 1.0;
uniform sampler2DArray replace_texture : repeat_enable, filter_nearest;
uniform float tile_size = 64.0;
uniform vec2 scroll_speed = vec2(0.05, 0.03);
uniform vec2 offset = vec2(0.0, 0.0);
uniform float texture_pixel_size = 0.00195313;
uniform float fps = 5.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float fill_line = 1.0 - health_percent;

	vec2 scroll = TIME * scroll_speed;
	scroll = floor(scroll / texture_pixel_size) * texture_pixel_size;
	float frame = floor(mod(TIME * fps, float(textureSize(replace_texture, 0).z)));

	float health_offset_y = (1.0 - health_percent) * (1.0 / TEXTURE_PIXEL_SIZE.y);
	vec2 tiled_uv = (FRAGCOORD.xy + offset + vec2(0.0, -health_offset_y)) / tile_size + scroll;
	vec4 replacement = texture(replace_texture, vec3(tiled_uv, frame));

	if (tex.a < 0.01 || UV.y < fill_line) {
		COLOR = tex;
	} else {
		COLOR = vec4(replacement.rgb, tex.a);
	}
}