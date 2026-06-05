shader_type canvas_item;

uniform float health_percent : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.2, 0.8, 0.3, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	float fill_line = 1.0 - health_percent;
	
	if (tex.a < 0.01 || UV.y < fill_line) {
		COLOR = tex;
	} else {
		COLOR = vec4(fill_color.rgb, tex.a);
	}
}