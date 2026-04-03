shader_type canvas_item;

uniform float panini_strength : hint_range(0.0, 1.0) = 0.0;
uniform float panini_d = 1.0; // controls curvature

void fragment() {
    vec2 uv = UV * 2.0 - 1.0; // center at (0,0)

    // Panini projection approximation
    float d = panini_d;
    float r = length(uv);
    
    vec2 panini_uv = uv;
    if (r > 0.0) {
        float scale = (d + 1.0) / (d + sqrt(1.0 + r * r));
        panini_uv = uv * scale;
    }

    // Blend between normal and panini
    vec2 final_uv = mix(uv, panini_uv, panini_strength);

    final_uv = final_uv * 0.5 + 0.5;

    COLOR = texture(TEXTURE, final_uv);
}