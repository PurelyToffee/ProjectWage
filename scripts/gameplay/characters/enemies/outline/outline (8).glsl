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
layout(set = 0, binding = 2) uniform sampler2D depth_texture;
layout(set = 0, binding = 3) uniform sampler2D mask_texture;
layout(set = 0, binding = 4) uniform sampler2D enemy_depth_texture;

void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	vec2 size = params.raster_size;

	if (float(coord.x) >= size.x || float(coord.y) >= size.y)
		return;

	vec2 uv = (vec2(coord) + 0.5) / size;

	// Skip enemy pixels
	if (texture(mask_texture, uv).a > 0.5)
		return;

	int thickness = int(params.thickness);

	for (int x = -thickness; x <= thickness; x++) {
		for (int y = -thickness; y <= thickness; y++) {
			if (length(vec2(x, y)) > float(thickness) + 0.5)
				continue;
			vec2 offset_uv = uv + vec2(x, y) / size;
			if (texture(mask_texture, offset_uv).a > 0.5) {
				imageStore(color_image, coord, vec4(1.0, 0.0, 0.0, 1.0));
				return;
			}
		}
	}
}
