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

	float center_mask = texture(mask_texture, uv).a;

	// DEBUG: paint mask alpha as grayscale so we can see what values we're getting
	imageStore(color_image, coord, vec4(center_mask, center_mask, center_mask, 1.0));
}
