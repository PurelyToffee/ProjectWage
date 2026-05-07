shader_type spatial;
render_mode cull_front, unshaded;

uniform mat4 lag_transform;
uniform mat4 current_transform;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float grow_amount = 0.05;

void vertex() {
	// We don't smear the outline (t=0), but we use the same transforms 
	// to ensure it stays perfectly locked to the character's bone/mesh position.
	vec3 current_world = (current_transform * vec4(VERTEX, 1.0)).xyz;
	vec3 lag_world = (lag_transform * vec4(VERTEX, 1.0)).xyz;
	
	// Expand vertices along normals
	VERTEX += NORMAL * grow_amount;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}