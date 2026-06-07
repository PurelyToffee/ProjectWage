/**
* Ported from the original unity shader by Erik Roystan Ross
* https://roystan.net/articles/toon-water.html
* https://github.com/IronWarrior/ToonWaterShader
* Camera3D Depth taken from Bastiaan Olij's video on: https://www.youtube.com/watch?v=Jq3he9Lbj7M
* PurelyToffee was here :3
* Ported it to Godot 4.6.1, all credits go to the guy above though.
* Noise waves + flowing foam added on top.
*/
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
const float SMOOTHSTEP_AA = 0.01;
uniform sampler2D surfaceNoise;
uniform sampler2D distortNoise;

// Beer / depth
uniform float beer_factor = 0.8;

// Foam
uniform float foam_distance = 0.1;
uniform float foam_max_distance = 0.4;
uniform float foam_min_distance = 0.04;
uniform vec4 foam_color: source_color = vec4(1.0);

// Noise / distortion
uniform vec2 surface_noise_tiling = vec2(1.0, 4.0);
uniform float surface_noise_cutoff: hint_range(0, 1) = 0.777;
uniform float surface_distortion_amount: hint_range(0, 1) = 0.27;

// Flow (moves foam + surface noise)
uniform vec2 flow_direction = vec2(0.0, 1.0);
uniform float flow_speed = 0.1;

// Depth gradient
uniform vec4 _DepthGradientShallow: source_color = vec4(0.325, 0.807, 0.971, 0.725);
uniform vec4 _DepthGradientDeep: source_color = vec4(0.086, 0.407, 1, 0.749);
uniform float _DepthMaxDistance: hint_range(0, 1) = 1.0;
uniform float _DepthFactor = 1.0;

// Waves
uniform float wave_height = 0.3;
uniform float wave_frequency = 6.0;
uniform float wave_speed = 2.0;
uniform vec2 wave_direction = vec2(0.0, 1.0);

varying vec2 noiseUV;
varying vec2 distortUV;
varying vec3 viewNormal;

vec4 alphaBlend(vec4 top, vec4 bottom)
{
	vec3 color = (top.rgb * top.a) + (bottom.rgb * (1.0 - top.a));
	float alpha = top.a + bottom.a * (1.0 - top.a);
	return vec4(color, alpha);
}

float calcWave(vec3 vertex, vec2 dir, float freq, float speed, float height) {
	return sin(dot(vertex.xz, normalize(dir)) * freq + TIME * speed) * height;
}

float calcCosWave(vec3 vertex, vec2 dir, float freq, float speed, float height) {
	return cos(dot(vertex.xz, normalize(dir)) * freq + TIME * speed) * height;
}

float calcTanWave(vec3 vertex, vec2 dir, float freq, float speed, float height) {
	return clamp(tan(dot(vertex.xz, normalize(dir)) * freq + TIME * speed), -1.0, 1.0) * height;
}

void vertex() {
	viewNormal = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	noiseUV = UV * surface_noise_tiling;
	distortUV = UV;

	float wave = 0.0;

	// Dominant wave
	wave += calcWave(VERTEX, wave_direction, wave_frequency, wave_speed, wave_height);

	// Supporting sin waves
	wave += calcWave(VERTEX, wave_direction + vec2(0.3, 0.7),  wave_frequency * 0.9, wave_speed * 1.1, wave_height * 0.4);
	wave += calcWave(VERTEX, wave_direction + vec2(-0.6, 0.4), wave_frequency * 1.3, wave_speed * 0.8, wave_height * 0.25);
	wave += calcWave(VERTEX, wave_direction + vec2(0.5, -0.8), wave_frequency * 0.6, wave_speed * 1.4, wave_height * 0.2);

	// Cos waves
	wave += calcCosWave(VERTEX, wave_direction + vec2(0.9, 0.2),   wave_frequency * 1.7, wave_speed * 0.6, wave_height * 0.8);
	wave += calcCosWave(VERTEX, wave_direction + vec2(-0.3, -0.9), wave_frequency * 2.2, wave_speed * 1.5, wave_height * 0.4);

	// Tan waves (small choppy detail)
	wave += calcTanWave(VERTEX, wave_direction + vec2(0.7, 0.5),  wave_frequency * 3.1, wave_speed * 0.9, wave_height * 0.05);
	wave += calcTanWave(VERTEX, wave_direction + vec2(-0.4, 0.6), wave_frequency * 2.7, wave_speed * 1.2, wave_height * 0.05);

	VERTEX.y += wave;
}

void fragment() {
	// Depth reconstruction (Godot 4)
	float raw_depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float depth = -view.z - (-VERTEX.z);
	depth = exp(-depth * beer_factor);
	depth = 1.0 - depth;

	// Foam normal
	vec3 existingNormal = vec3(dFdx(depth), dFdy(depth), 0.0);
	float normalDot = clamp(dot(existingNormal.xyz, viewNormal), 0.0, 1.0);
	float foamDistance = mix(foam_max_distance, foam_min_distance, normalDot);
	float foamDepth = clamp(depth / foamDistance, 0.0, 1.0);
	float surfaceNoiseCutoff = foamDepth * surface_noise_cutoff;

	// Distortion
	vec4 distortNoiseSample = texture(distortNoise, distortUV);
	vec2 distortAmount = (distortNoiseSample.xy * 2.0 - 1.0) * surface_distortion_amount;

	// Surface noise scrolls with flow
	vec2 flowOffset = normalize(flow_direction) * flow_speed * TIME;
	vec2 noise_uv = noiseUV + flowOffset + distortAmount;

	float surfaceNoiseSample = texture(surfaceNoise, noise_uv).r;
	float surfaceNoiseAmount = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);

	// Water color
	float waterDepth = clamp(depth / _DepthMaxDistance, 0.0, 1.0) * _DepthFactor;
	vec4 waterColor = mix(_DepthGradientShallow, _DepthGradientDeep, waterDepth);

	// Foam color
	vec4 surfaceNoiseColor = foam_color;
	surfaceNoiseColor.a *= surfaceNoiseAmount;

	vec4 color = alphaBlend(surfaceNoiseColor, waterColor);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}