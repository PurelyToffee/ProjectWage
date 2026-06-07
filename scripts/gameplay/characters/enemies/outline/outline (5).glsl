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

// Convert raw reversed-Z depth to linear view-space depth
// We just need relative comparison so we work in raw depth space,
// but we average neighbor enemy depths to estimate enemy depth at outline pixel
void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	vec2 size = params.raster_size;

	if (float(coord.x) >= size.x || float(coord.y) >= size.y)
		return;

	vec2 uv = (vec2(coord) + 0.5) / size;

	float center_mask = texture(mask_texture, uv).a;
	if (center_mask > 0.5)
		return;

	// Depth of whatever is rendered at this outline pixel in the main scene
	float scene_depth = texture(depth_texture, uv).r;

	int thickness = int(params.thickness);
	bool is_outline = false;

	// Collect the average depth of nearby enemy pixels in the main scene
	// This estimates what depth the enemy "would be" at this outline pixel
	float enemy_depth_sum = 0.0;
	float enemy_depth_count = 0.0;

	for (int x = -thickness; x <= thickness; x++) {
		for (int y = -thickness; y <= thickness; y++) {
			if (length(vec2(x, y)) > float(thickness) + 0.5)
				continue;

			vec2 offset_uv = uv + vec2(x, y) / size;
			float neighbor_mask = texture(mask_texture, offset_uv).a;

			if (neighbor_mask > 0.5) {
				is_outline = true;
				// Sample the main scene depth at the enemy pixel
				// (enemy is on layer 1 so its depth is in the main buffer)
				float neighbor_depth = texture(depth_texture, offset_uv).r;
				enemy_depth_sum += neighbor_depth;
				enemy_depth_count += 1.0;
			}
		}
	}

	if (!is_outline)
		return;

	// Average enemy depth near this outline pixel
	float avg_enemy_depth = enemy_depth_sum / enemy_depth_count;

	// In reversed-Z: higher value = closer to camera
	// If the scene at our outline pixel is closer than the enemy, occlude the outline
	// Add a small bias to avoid z-fighting at enemy edges
	bool occluded = scene_depth > avg_enemy_depth + 0.0005;

	if (!occluded) {
		vec4 current = imageLoad(color_image, coord);
		float alpha = params.outline_color.a;
		vec4 result = vec4(mix(current.rgb, params.outline_color.rgb, alpha), current.a);
		imageStore(color_image, coord, result);
	}
}
