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

void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	vec2 size = params.raster_size;

	if (float(coord.x) >= size.x || float(coord.y) >= size.y)
		return;

	vec2 uv = (vec2(coord) + 0.5) / size;

	float center_mask = texture(mask_texture, uv).a;

	// Already part of the enemy — skip
	if (center_mask > 0.5)
		return;

	float scene_depth = texture(depth_texture, uv).r;

	int thickness = int(params.thickness);
	float max_neighbor_mask = 0.0;
	float min_neighbor_depth = 1.0;

	for (int x = -thickness; x <= thickness; x++) {
		for (int y = -thickness; y <= thickness; y++) {
			if (length(vec2(x, y)) > float(thickness) + 0.5)
				continue;

			vec2 offset_uv = uv + vec2(x, y) / size;
			float neighbor_mask = texture(mask_texture, offset_uv).a;
			float neighbor_depth = texture(depth_texture, offset_uv).r;

			if (neighbor_mask > 0.5) {
				max_neighbor_mask = max(max_neighbor_mask, neighbor_mask);
				min_neighbor_depth = min(min_neighbor_depth, neighbor_depth);
			}
		}
	}

	bool is_outline = max_neighbor_mask > 0.5;

	// DEBUG: skip occlusion check entirely for now
	// bool occluded = scene_depth < min_neighbor_depth - 0.0001;

	if (is_outline) {
		vec4 current = imageLoad(color_image, coord);
		float alpha = params.outline_color.a;
		vec4 result = vec4(mix(current.rgb, params.outline_color.rgb, alpha), current.a);
		imageStore(color_image, coord, result);
	}
}
