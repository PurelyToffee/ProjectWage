shader_type spatial;
// cull_front is vital: it hides the "front" of the outline so you see the "back" shell
render_mode cull_front, unshaded, depth_test_disabled;

uniform sampler2D noise;
uniform mat4 lag_transform;
uniform mat4 current_transform;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float grow_amount = 0.05;

void vertex() {
    // 1. Smear Displacement
	float t = pow(texture(noise, UV * 40.0).r, 4.0);
	vec3 current_world = (current_transform * vec4(VERTEX, 1.0)).xyz;
	vec3 lag_world = (lag_transform * vec4(VERTEX, 1.0)).xyz;
	vec3 offset = (lag_world - current_world) * t;
	
	vec3 displaced_vertex = VERTEX + mat3(inverse(current_transform)) * offset;
	
    // 2. Grow logic (The Outline thickness)
	VERTEX = displaced_vertex + (NORMAL * grow_amount);
}

void fragment() {
    // 1. Fresnel/Normal check: 
    // Is this part of the 'shell' pointing roughly toward the camera?
    // If dot product is positive, it's facing away; if negative, it's facing toward.
    // Since we use cull_front, we check if the backface is pointing at us.
    float facing = dot(NORMAL, VIEW);
    
    // Discard the 'center' of the outline shell so it doesn't cover the face
    if (facing > -0.1) { 
        discard; 
    }

    ALBEDO = outline_color.rgb;
    // Keep the depth nudge as a safety measure
    DEPTH = FRAGCOORD.z + 0.0001;
}