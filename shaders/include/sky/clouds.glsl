/*
================================================================================
  OffShades — include/sky/clouds.glsl
  Volumetric raymarched cloud layers: cumulus, altocumulus, cirrus.
  Adapted from Complementary Reimagined Shaders by EminGT.
================================================================================
*/

#ifndef CLOUDS_INCLUDED
#define CLOUDS_INCLUDED

#include "/include/utility/math.glsl"
#include "/include/utility/color.glsl"

// ─── Noise helpers ─────────────────────────────────────────────────────────
float cloud_noise_3d(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(mix(hash13(i), hash13(i + vec3(1,0,0)), f.x),
            mix(hash13(i + vec3(0,1,0)), hash13(i + vec3(1,1,0)), f.x), f.y),
        mix(mix(hash13(i + vec3(0,0,1)), hash13(i + vec3(1,0,1)), f.x),
            mix(hash13(i + vec3(0,1,1)), hash13(i + vec3(1,1,1)), f.x), f.y),
        f.z
    );
}

float cloud_fbm(vec3 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float freq = 1.0;
    for (int i = 0; i < octaves; ++i) {
        value += amplitude * cloud_noise_3d(p * freq);
        amplitude *= 0.5;
        freq      *= 2.0;
    }
    return value;
}

// ─── Cumulus cloud density ───────────────────────────────────────────────────
float cumulus_density(vec3 world_pos) {
    float altitude = world_pos.y - CLOUDS_CUMULUS_ALTITUDE;
    if (abs(altitude) > CLOUDS_CUMULUS_THICKNESS * 0.5) return 0.0;

    float height_grad = 1.0 - abs(altitude) / (CLOUDS_CUMULUS_THICKNESS * 0.5);
    height_grad = smoothstep(0.0, 1.0, height_grad);

    // Animate with wind
    vec2 wind   = vec2(frameTimeCounter * 0.005, 0.0);
    vec3 sample_pos = vec3((world_pos.xz + wind + cameraPosition.xz) * 0.003, altitude * 0.01);

    float shape = cloud_fbm(sample_pos, 4);
    float density = max(0.0, shape - (1.0 - CLOUDS_CUMULUS_COVERAGE)) * height_grad;
    return density * CLOUDS_CUMULUS_DENSITY;
}

// ─── Cirrus cloud density (2D) ───────────────────────────────────────────────
float cirrus_density(vec3 world_pos, vec3 rd) {
    if (world_pos.y + rd.y * 10000.0 < CLOUDS_CIRRUS_ALTITUDE && rd.y < 0.0) return 0.0;

    // Project to cirrus plane
    float t = (CLOUDS_CIRRUS_ALTITUDE - world_pos.y) / rd.y;
    if (t < 0.0) return 0.0;
    vec2  plane_pos = (world_pos.xz + rd.xz * t + cameraPosition.xz + vec2(frameTimeCounter * 0.002)) * 0.002;

    float c = cloud_fbm(vec3(plane_pos, 0.0), 3);
    return max(0.0, c - (1.0 - CLOUDS_CIRRUS_COVERAGE)) * CLOUDS_CIRRUS_DENSITY;
}

// ─── Cloud lighting ─────────────────────────────────────────────────────────
vec3 cloud_light(vec3 world_pos, vec3 sun_dir, vec3 sun_color) {
    // Simple single-scattering approximation
    float depth  = 0.0;
    float step_d = 30.0;
    vec3  p      = world_pos;
    for (int i = 0; i < 4; ++i) {
        p += sun_dir * step_d;
        depth += cumulus_density(p) * step_d;
    }
    float transmittance = exp(-depth * 0.06);
    return sun_color * mix(0.3, 1.0, transmittance);
}

// ─── Cumulus cloud raymarching ───────────────────────────────────────────────
// ro   : world-space camera position
// rd   : normalized world-space view direction
// sun_dir  : normalized sun direction
// sun_color : sun radiance
// Returns RGBA: .rgb = scattered light, .a = transmittance
vec4 raymarch_cumulus(vec3 ro, vec3 rd, vec3 sun_dir, vec3 sun_color) {
    // Find cloud layer intersection
    float t_enter = (CLOUDS_CUMULUS_ALTITUDE - CLOUDS_CUMULUS_THICKNESS * 0.5 - ro.y) / rd.y;
    float t_exit  = (CLOUDS_CUMULUS_ALTITUDE + CLOUDS_CUMULUS_THICKNESS * 0.5 - ro.y) / rd.y;

    if (rd.y == 0.0 || t_exit < 0.0 || t_enter > t_exit) return vec4(0.0, 0.0, 0.0, 1.0);

    t_enter = max(t_enter, 0.0);
    t_exit  = min(t_exit, 8000.0);

    const int   STEPS    = CLOUDS_CUMULUS_PRIMARY_STEPS_H;
    float step_size = (t_exit - t_enter) / float(STEPS);

    vec3  scatter      = vec3(0.0);
    float transmittance = 1.0;

    float dither = hash13(vec3(gl_FragCoord.xy, float(frameCounter)));

    vec3 p = ro + rd * (t_enter + step_size * dither);

    for (int i = 0; i < STEPS; ++i, p += rd * step_size) {
        float density = cumulus_density(p);
        if (density < 0.001) continue;

        float sigma_e = density * 0.1;
        float sigma_s = sigma_e * 0.9;

        vec3  light   = cloud_light(p, sun_dir, sun_color);
        vec3  in_scatter = light * sigma_s;

        float step_t = exp(-sigma_e * step_size);
        scatter += (in_scatter - in_scatter * step_t) / (sigma_e + EPS) * transmittance;
        transmittance *= step_t;

        if (transmittance < 0.01) break;
    }

    return vec4(scatter, transmittance);
}

// ─── Main cloud rendering ────────────────────────────────────────────────────
// Returns (scattered_light.rgb, cloud_shadow) — the caller composites it
struct CloudResult {
    vec4 cumulus;      // .rgb = scattered, .a = transmittance
    float cirrus;       // opacity [0,1]
    float cloud_shadow; // 0=in shadow, 1=no shadow
};

CloudResult render_clouds(vec3 ro, vec3 rd, vec3 sun_dir, vec3 sun_color) {
    CloudResult result;
    result.cloud_shadow = 1.0;

    // Cirrus (thin, 2D analytical)
    result.cirrus = 0.0;
#ifdef CLOUDS_CIRRUS
    result.cirrus = saturate(cirrus_density(ro, rd) * 5.0);
#endif

    // Cumulus (volumetric)
    result.cumulus = vec4(0.0, 0.0, 0.0, 1.0);
#ifdef CLOUDS_CUMULUS
    result.cumulus = raymarch_cumulus(ro, rd, sun_dir, sun_color);
    // Approximate cloud shadow below clouds
    float shadow_density = cumulus_density(vec3(ro.x, ro.y, ro.z));
    result.cloud_shadow  = exp(-shadow_density * 300.0);
#endif

    return result;
}

#endif // CLOUDS_INCLUDED


