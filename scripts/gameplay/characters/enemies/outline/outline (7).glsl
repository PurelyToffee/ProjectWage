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

// Main scene color (read/write)
layout(rgba16f, set = 0, binding = 1) uniform image2D color_image;

// Main scene depth — layer 1 only, NO enemies (enemies are layer 7 only now)
layout(set = 0, binding = 2) uniform sampler2D depth_texture;

// EnemyCamera color — alpha = 1 where enemy is
layout(set = 0, binding = 3) uniform sampler2D mask_texture;

// EnemyCamera depth — depth of enemies only
layout(set = 0, binding = 4) uniform sampler2D enemy_depth_texture;

void main() {
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	vec2 size = params.raster_size;

	if (float(coord.x) >= size.x || float(coord.y) >= size.y)
		return;

	vec2 uv = (vec2(coord) + 0.5) / size;

	// Skip pixels that are part of the enemy silhouette
	if (texture(mask_texture, uv).a > 0.5)
		return;

	// Find if any neighbor pixel is an enemy (outline detection)
	int thickness = int(params.thickness);
	bool is_outline = false;
	float nearest_enemy_depth = 0.0;
	float nearest_dist = 999.0;

	for (int x = -thickness; x <= thickness; x++) {
		for (int y = -thickness; y <= thickness; y++) {
			float d = length(vec2(x, y));
			if (d > float(thickness) + 0.5)
				continue;

			vec2 offset_uv = uv + vec2(x, y) / size;
			if (texture(mask_texture, offset_uv).a > 0.5) {
				is_outline = true;
				// Track the nearest enemy neighbor's depth from EnemyCamera
				if (d < nearest_dist) {
					nearest_dist = d;
					nearest_enemy_depth = texture(enemy_depth_texture, offset_uv).r;
				}
			}
		}
	}

	if (!is_outline)
		return;

	// Main scene depth at this outline pixel (walls, floor — no enemies)
	float scene_depth = texture(depth_texture, uv).r;

	// Reversed-Z: higher = closer to camera
	// If the main scene has something closer than the enemy here, occlude the outline
	if (scene_depth > nearest_enemy_depth) {
		return;
	}

	vec4 current = imageLoad(color_image, coord);
	float alpha = params.outline_color.a;
	imageStore(color_image, coord, vec4(mix(current.rgb, params.outline_color.rgb, alpha), current.a));
}
