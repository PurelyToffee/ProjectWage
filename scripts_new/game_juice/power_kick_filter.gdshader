shader_type canvas_item;

uniform bool active = false;
uniform sampler2D gradient : hint_default_white, repeat_disable, filter_linear;
uniform float stp = .5;

void fragment() {
    vec4 original = texture(TEXTURE, UV);

    if (!active) {
        COLOR = original;
    }
    else
    {
        float val = (original.r + original.g + original.b)/3.0;
        COLOR = texture(gradient, vec2(val, 0.5));
    }
}