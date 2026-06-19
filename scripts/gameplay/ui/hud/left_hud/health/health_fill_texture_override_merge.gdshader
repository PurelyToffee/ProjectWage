shader_type canvas_item;
uniform float health_percent : hint_range(0.0, 1.0) = 1.0;
uniform sampler2DArray replace_texture : repeat_enable, filter_nearest;
uniform sampler2DArray surface_texture : repeat_enable, filter_nearest;
uniform float tile_size = 64.0;
uniform float surface_height = 16.0; // height in pixels of the surface strip
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

	// Surface strip: pixel distance from the fill line
	// Surface sits centered ON the fill line, half above half below
	float fill_line_px = fill_line / TEXTURE_PIXEL_SIZE.y;
	float frag_y_px = UV.y / TEXTURE_PIXEL_SIZE.y;
	float dist_from_surface = frag_y_px - fill_line_px + (surface_height * 0.5);
	bool on_surface = dist_from_surface >= 0.0 && dist_from_surface < surface_height;

	float surface_frame = floor(mod(TIME * fps, float(textureSize(surface_texture, 0).z)));
	vec2 surface_uv = vec2(tiled_uv.x, dist_from_surface / surface_height);
	vec4 surface = texture(surface_texture, vec3(surface_uv, surface_frame));

	if (tex.a < 0.01) {
		COLOR = tex;
	} else if ((on_surface && surface.a > 0.01) || UV.y >= fill_line) {
		COLOR = vec4(replacement.rgb, tex.a); // surface draws over everything, empty area included
	} else if (UV.y < fill_line) {
		COLOR = tex;
	}
}