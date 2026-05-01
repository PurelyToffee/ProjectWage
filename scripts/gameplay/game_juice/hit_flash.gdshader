shader_type spatial;

uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec3 base = ALBEDO;
    
    // Blend original color with flash color
    ALBEDO = mix(base, flash_color.rgb, flash_strength);
    
    // Optional: make it glow
    EMISSION = flash_color.rgb * flash_strength * 2.0;
}