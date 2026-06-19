#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer Params {
    vec2 raster_size;
    vec2 reserved;
    vec4 outline_color;
    float thickness;
    float reserved2;
    float reserved3;
    float reserved4;
} params;

layout(rgba16f, set = 0, binding = 1) uniform image2D color_image;
layout(set = 0, binding = 2) uniform sampler2D depth_texture;       // Main camera raw depth
layout(set = 0, binding = 3) uniform sampler2D enemy_depth_texture; // Enemy SubViewport raw depth

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = params.raster_size;

    if (float(coord.x) >= size.x || float(coord.y) >= size.y)
        return;

    vec2 uv = (vec2(coord) + 0.5) / size;


    if (texture(enemy_depth_texture, uv).r > 0.0)
        return;


    float main_depth = texture(depth_texture, uv).r;
    int thickness = int(params.thickness);

    // Pass 1: find max_enemy_depth within full thickness
    float max_enemy_depth = 0.0;
    for (int x = -thickness; x <= thickness; x++) {
        for (int y = -thickness; y <= thickness; y++) {
            vec2 offset_uv = uv + vec2(x, y) / size;
            float ed = texture(enemy_depth_texture, offset_uv).r;
            if (ed > max_enemy_depth)
                max_enemy_depth = ed;
        }
    }

    // No enemy nearby at all
    if (max_enemy_depth <= 0.0)
        return;

    if (main_depth > max_enemy_depth)
        return;

    float reference_depth = 0.001;
	float depth_scale = max_enemy_depth / reference_depth;
	int scaled_thickness = clamp(int(float(thickness) * depth_scale), 1, 8);

    // Pass 2: is this pixel within scaled_thickness of enemy geometry?
    bool in_range = false;
    for (int x = -scaled_thickness; x <= scaled_thickness; x++) {
        for (int y = -scaled_thickness; y <= scaled_thickness; y++) {
            if (length(vec2(x, y)) > float(scaled_thickness) + 0.5)
                continue;
            vec2 offset_uv = uv + vec2(x, y) / size;
            if (texture(enemy_depth_texture, offset_uv).r > 0.0) {
                in_range = true;
                break;
            }
        }
        if (in_range) break;
    }

	

    if (!in_range)
        return;

    vec4 current = imageLoad(color_image, coord);
    float alpha = params.outline_color.a;
    imageStore(color_image, coord, vec4(mix(current.rgb, params.outline_color.rgb, alpha), current.a));
}