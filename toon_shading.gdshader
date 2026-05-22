shader_type spatial;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 light_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform vec4 albedo_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float cel = step(shadow_threshold, NdotL * ATTENUATION);
    DIFFUSE_LIGHT += mix(shadow_color.rgb, light_color.rgb, cel) * LIGHT_COLOR * ALBEDO;
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb * albedo_tint.rgb;
}