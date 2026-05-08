shader_type spatial;
render_mode blend_mix, cull_front, unshaded, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_width = 0.02;

void vertex() {
    vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    vec3 clip_normal = normalize((PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    clip_pos.xy += clip_normal.xy * outline_width * clip_pos.w;
    POSITION = clip_pos;
}

void fragment() {
    ALBEDO = outline_color.rgb;
    ALPHA = 1.0;
}