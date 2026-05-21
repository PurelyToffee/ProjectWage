shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform float alpha = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);

    // Premultiply properly
    c.rgb *= c.a;

    // Apply fade
    c.rgb *= alpha;
    c.a *= alpha;

    COLOR = c;
}