shader_type canvas_item;

uniform float panini_strength : hint_range(0.0, 1.0) = 0.0;
uniform float panini_d : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;

    float d = mix(0.2, 2.0, panini_d); // 👈 key fix
    float r = length(uv);
    
    vec2 panini_uv = uv;
    if (r > 0.0) {
        float scale = (d + 1.0) / (d + sqrt(1.0 + r * r));
        panini_uv = uv * scale;
    }

    vec2 final_uv = mix(uv, panini_uv, panini_strength);
    final_uv = final_uv * 0.5 + 0.5;

    COLOR = texture(TEXTURE, final_uv);
}