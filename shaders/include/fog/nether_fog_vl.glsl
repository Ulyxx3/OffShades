#if !defined INCLUDE_FOG_NETHER_FOG_VL
#define INCLUDE_FOG_NETHER_FOG_VL

/*
--------------------------------------------------------------------------------

  OffShades - Nether Volumetric Fog (Solas Shader V3.7b inspired)
  3D volumetric smoke plumes and biome-responsive atmospheric scattering

--------------------------------------------------------------------------------
*/

#include "/include/utility/color.glsl"
#include "/include/utility/fast_math.glsl"
#include "/include/utility/phase_functions.glsl"

float get_nether_smoke_sample(vec3 fog_pos) {
    float t = frameTimeCounter;

    fog_pos.y -= t * 2.0;
    fog_pos.x += cos(fog_pos.y * 0.09 + fog_pos.z * 0.007 + t * 0.13) * 6.0;
    fog_pos.z += sin(fog_pos.y * 0.11 + fog_pos.x * 0.007 + t * 0.09) * 6.0;

    float y_idx = fog_pos.y * 0.075;
    float n0 = texture(noisetex, fog_pos.xz * 0.0045 + floor(y_idx) * 0.137).r;
    float n1 = texture(noisetex, fog_pos.xz * 0.0045 + (floor(y_idx) + 1.0) * 0.137).r;
    float smoke = mix(n0, n1, smoothstep(0.0, 1.0, fract(y_idx)));
    smoke = max(smoke - 0.475, 0.0);
    return smoke * smoke * 10.0;
}

mat2x3 raymarch_nether_fog(
    vec3 world_start_pos,
    vec3 world_end_pos,
    bool sky,
    float dither
) {
    const uint min_step_count = 14;
    const uint max_step_count = 24;
    const float max_vl_distance = 160.0;

    vec3 world_dir = world_end_pos - world_start_pos;
    float ray_length;
    length_normalize(world_dir, world_dir, ray_length);

    ray_length = min(ray_length, min(far, max_vl_distance));
    if (ray_length <= 0.5) {
        return mat2x3(vec3(0.0), vec3(1.0));
    }

    uint step_count = uint(float(min_step_count) + 0.06 * ray_length);
    step_count = min(step_count, max_step_count);

    float step_length = ray_length * rcp(float(step_count));
    vec3 world_step = world_dir * step_length;

    // Jitter ray origin with dither
    vec3 world_pos = world_start_pos + world_step * dither;

    // Biome chromaticity extracted from fogColor (Solas style)
    vec3 n_fog = normalize(max(fogColor, vec3(0.001)));
    vec3 nether_chroma = pow(n_fog, vec3(0.125)) * rec709_to_working_color;
    nether_chroma /= max(dot(nether_chroma, luminance_weights_rec2020), eps);

    // Dynamic wind for smoke plume motion
    vec3 wind = vec3(
        -sin(frameTimeCounter * 0.3) * 0.2,
        -4.0 * frameTimeCounter,
        cos(frameTimeCounter * 0.5) * 0.4
    );

    const vec3 scattering_coeff = vec3(1.0);
    const vec3 extinction_coeff = vec3(1.2);

    vec3 scattering = vec3(0.0);
    vec3 transmittance = vec3(1.0);

    for (uint i = 0u; i < step_count; ++i, world_pos += world_step) {
        float alt = world_pos.y;
        float height_fade = clamp(alt / 35.0, 0.0, 1.0) * (1.0 - clamp(alt / 255.0, 0.0, 1.0));

        // Atmospheric base density + 3D animated smoke plumes
        float smoke = 0.0;
        if (alt > 30.0 && alt < 255.0) {
            smoke = get_nether_smoke_sample(world_pos * 1.5 + wind * 2.0) * height_fade;
        }

        // Base atmospheric haze
        float base_density = 0.006 * NETHER_FOG_INTENSITY;
        float density = (base_density + smoke * 0.028) * step_length;

        vec3 step_optical_depth = extinction_coeff * density;
        vec3 step_transmittance = exp(-step_optical_depth);
        vec3 step_transmitted_fraction =
            (1.0 - step_transmittance) / max(step_optical_depth, eps);

        vec3 visible_scattering = step_transmitted_fraction * transmittance;

        // Illumination: blend of ambient color and radiant biome chroma
        vec3 inscattering_color = ambient_color * 1.1 + nether_chroma * (0.04 + 0.12 * smoke);
        scattering += density * inscattering_color * visible_scattering;

        transmittance *= step_transmittance;
    }

    scattering *= scattering_coeff;
    transmittance = pow(transmittance, vec3(0.85));

    return mat2x3(scattering, transmittance);
}

#endif // INCLUDE_FOG_NETHER_FOG_VL
