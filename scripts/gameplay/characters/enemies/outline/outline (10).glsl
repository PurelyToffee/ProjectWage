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

	// Skip enemy silhouette pixels — enemy renders normally via layer 1
	if (texture(mask_texture, uv).a > 0.5)
		return;

	// Main scene depth at this pixel (has enemies on layer 1 + world geometry)
	float scene_depth = texture(depth_texture, uv).r;

	// Find nearest enemy neighbor for outline detection
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
				if (d < nearest_dist) {
					nearest_dist = d;
					nearest_enemy_depth = texture(enemy_depth_texture, offset_uv).r;
				}
			}
		}
	}

	if (!is_outline)
		return;

	// Reversed-Z: higher = closer. If scene pixel is closer than enemy, occlude outline.
	if (scene_depth > nearest_enemy_depth + 0.0001)
		return;

	vec4 current = imageLoad(color_image, coord);
	float alpha = params.outline_color.a;
	imageStore(color_image, coord, vec4(mix(current.rgb, params.outline_color.rgb, alpha), current.a));
}
