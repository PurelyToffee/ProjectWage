shader_type canvas_item;

uniform float panini_strength : hint_range(0.0, 1.0) = 0.0;
uniform float panini_d : hint_range(0.0, 1.0) = 0.5;
uniform float panini_s : hint_range(-1.0, 1.0) = 0.0; // vertical compression

const float EPS = 1e-6;

// --- Panini inverse (adapted from your big shader) ---
vec3 panini_inverse(vec2 p, float d, float s) {
    float dp1 = d + 1.0;
    float k = (p.x * p.x) / (dp1 * dp1);

    float disc = k * k * d * d - (k + 1.0) * (k * d * d - 1.0);
    if (disc <= 0.0) return normalize(vec3(p, 1.0));

    float c_lon = (-k * d + sqrt(disc)) / (k + 1.0);
    float S = dp1 / (d + c_lon);

    vec2 ang = vec2(
        atan(p.y, S),
        atan(p.x, S * c_lon)
    );

    float cos_lat = cos(ang.x);
    vec3 ray = vec3(
        cos_lat * sin(ang.y),
        sin(ang.x),
        cos_lat * cos(ang.y)
    );

    // vertical compression tweak
    if (ray.z > 0.0) {
        float q = ray.x / ray.z;
        q = (q * q) / ((d + 1.0) * (d + 1.0));
        ray.y *= mix(1.0, 1.0 / sqrt(1.0 + q), s);
    }

    return ray;
}

void fragment() {
    // screen space → centered
    vec2 screen_xy = UV * 2.0 - 1.0;

    // remap d so it's usable
    float d = mix(0.0, 1.5, panini_d);

    // get ray directions
    vec3 rect_ray = normalize(vec3(screen_xy, 1.0));
    vec3 panini_ray = panini_inverse(screen_xy, d, panini_s);

    // blend between projections
    vec3 ray = mix(rect_ray, panini_ray, panini_strength);

    // project back to UV
    vec2 final_uv = ray.xy / max(ray.z, EPS);
    final_uv = final_uv * 0.5 + 0.5;

    COLOR = texture(TEXTURE, final_uv);
}