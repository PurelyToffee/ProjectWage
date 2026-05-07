shader_type spatial;
render_mode blend_mix,
	cull_back,
	depth_draw_never;

uniform sampler2D noise;
uniform mat4 lag_transform;
uniform mat4 current_transform;
uniform vec4 albedo_color : source_color = vec4(1.0);

void vertex() {
	float t = pow(texture(noise, UV * 5.0).r, 4.0);

	vec3 current_world = (current_transform * vec4(VERTEX, 1.0)).xyz;
	vec3 lag_world     = (lag_transform * vec4(VERTEX, 1.0)).xyz;

	vec3 offset = (lag_world - current_world) * t;

	VERTEX += mat3(inverse(current_transform)) * offset;
}

void fragment() {
	ALBEDO = albedo_color.rgb;
	ALPHA  = 1.0;
}