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

	// Already part of the enemy silhouette — skip
	if (center_mask > 0.5)
		return;

	// Depth of whatever is at THIS pixel in the main scene
	float scene_depth = texture(depth_texture, uv).r;

	int thickness = int(params.thickness);
	bool is_outline = false;
	bool occluded = true;

	for (int x = -thickness; x <= thickness; x++) {
		for (int y = -thickness; y <= thickness; y++) {
			if (length(vec2(x, y)) > float(thickness) + 0.5)
				continue;

			vec2 offset_uv = uv + vec2(x, y) / size;
			float neighbor_mask = texture(mask_texture, offset_uv).a;

			if (neighbor_mask > 0.5) {
				is_outline = true;

				// Sample the main scene depth AT the neighbor (enemy) pixel
				// If the enemy pixel's scene depth equals its own depth, it's visible
				// We check: is the enemy neighbor visible in the main scene?
				// In the main scene, the enemy IS rendered on layer 1 too,
				// so its depth is written. If scene_depth at that neighbor
				// pixel is roughly the same as the enemy, it's not behind a wall.
				//
				// For the OUTLINE pixel itself: if this pixel has something
				// closer than the neighbor enemy pixel, it's occluded.
				float neighbor_scene_depth = texture(depth_texture, offset_uv).r;

				// neighbor_scene_depth is the depth of the enemy at that pixel
				// scene_depth is what's at our outline pixel
				// If our outline pixel has geometry closer (higher reversed-Z)
				// than the enemy neighbor, we are occluded
				if (scene_depth <= neighbor_scene_depth + 0.0001) {
					// At least one neighbor is not occluded here
					occluded = false;
					break;
				}
			}
		}
		if (!occluded) break;
	}

	if (is_outline && !occluded) {
		vec4 current = imageLoad(color_image, coord);
		float alpha = params.outline_color.a;
		vec4 result = vec4(mix(current.rgb, params.outline_color.rgb, alpha), current.a);
		imageStore(color_image, coord, result);
	}
}
