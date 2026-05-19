shader_type spatial;
render_mode unshaded;

uniform sampler2D main_texture : source_color, hint_default_transparent, filter_nearest;
uniform vec4 target_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float color_threshold : hint_range(0.0, 1.0) = 0.1;

uniform sampler2DArray replace_texture : repeat_enable, filter_nearest;
uniform vec2 tile_scale = vec2(4.0, 4.0);
uniform vec2 scroll_speed = vec2(0.05, 0.03);
uniform vec2 sprite_aspect = vec2(1.7778, 1.0);
uniform float texture_pixel_size = 0.00195313; // 1.0 / 512.0
uniform float fps = 5.0;

void fragment() {
	vec4 col = texture(main_texture, UV);

	vec2 scroll = TIME * scroll_speed;
	scroll = floor(scroll / texture_pixel_size) * texture_pixel_size;

	float frame = floor(mod(TIME * fps, float(textureSize(replace_texture, 0).z)));
	vec2 tiled_uv = UV * sprite_aspect * tile_scale + scroll;
	vec4 replacement = texture(replace_texture, vec3(tiled_uv, frame));

	float dist = distance(col.rgb, target_color.rgb);

	if (dist < color_threshold) {
		ALBEDO = replacement.rgb;
		ALPHA = col.a;
	} else {
		ALBEDO = col.rgb;
		ALPHA = col.a;
	}
}