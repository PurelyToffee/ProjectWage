shader_type spatial;
render_mode depth_draw_opaque, ambient_light_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest_mipmap_anisotropic;
uniform vec4      albedo_color   : source_color = vec4(1.0);
uniform sampler2D gradient       : source_color, filter_nearest;

void vertex() {
    // Intentionally empty — presence alone enables shadow casting
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb * albedo_color.rgb;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
    ALPHA = tex.a * albedo_color.a;
}

void light() {
    float n_dot_l  = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);

    // Fold shadow map occlusion into the ramp lookup
    float ramp_uv  = n_dot_l * ATTENUATION;
    vec3  shaded   = texture(gradient, vec2(ramp_uv, 0.0)).rgb;

    DIFFUSE_LIGHT += shaded * LIGHT_COLOR;
}