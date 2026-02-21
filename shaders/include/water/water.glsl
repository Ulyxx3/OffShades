/*
================================================================================
  OffShades — include/water/water.glsl
  Water surface: animated wave normals, SSR, biome tint.
  Adapted from Complementary Reimagined Shaders by EminGT.
================================================================================
*/

#ifndef WATER_INCLUDED
#define WATER_INCLUDED

#include "/include/utility/math.glsl"
#include "/include/utility/depth.glsl"
#include "/include/lighting/pbr.glsl"

// ─── Wave normal animation ─────────────────────────────────────────────────
// Iterative sin/cos trochoidal wave model
// world_pos : xz position in world
// time      : frameTimeCounter
vec3 water_wave_normal(vec2 world_pos, float time) {
    vec3 normal = vec3(0.0, 1.0, 0.0);

    // Multiple wave directions and frequencies
    const int WAVES = WATER_WAVE_COUNT;
    const float[8] wave_amp =  float[](0.05, 0.04, 0.03, 0.025, 0.02, 0.015, 0.012, 0.01);
    const float[8] wave_frq =  float[](0.5,  0.8,  1.2,  1.7,   2.3,  3.0,   4.0,   5.5);
    const vec2[8]  wave_dir = vec2[](
        vec2( 1.0,  0.3), vec2(-0.6,  0.8), vec2( 0.2, -1.0), vec2( 0.9, -0.4),
        vec2(-0.7, -0.5), vec2( 0.4,  0.9), vec2(-0.3,  0.6), vec2( 0.8,  0.2)
    );

    for (int i = 0; i < min(WAVES, 8); ++i) {
        float amp = wave_amp[i] * WATER_WAVE_AMPLITUDE;
        float frq = wave_frq[i] * WATER_WAVE_FREQUENCY;
        vec2  dir = normalize(wave_dir[i]);
        float spd = WATER_WAVE_SPEED * sqrt(9.81 / frq);

        float phase = dot(dir, world_pos) * frq - time * spd;
        float c     = cos(phase);
        float s     = sin(phase);

        // Trochoidal wave gradient contributes to normal
        normal.xz += -dir * amp * frq * c;
        // small y contribution for roughness
    }

    return normalize(normal);
}

// ─── Screen-Space Reflections ────────────────────────────────────────────────
// Traces a ray in screen space from the water surface
// screen_pos : uv + depth (gl_FragCoord based)
// reflect_dir : view-space reflection direction
// Returns: reflected color (or fallback sky)
vec3 ssr(vec2 start_uv, vec3 view_pos, vec3 reflect_dir, float roughness) {
    const int SSR_STEPS       = WATER_SSR_STEPS;
    const float SSR_STEP_SIZE = 0.15;
    const float SSR_MAX_DIST  = 30.0;

    vec3 pos = view_pos;
    vec3 dir_v = reflect_dir * SSR_STEP_SIZE;

    for (int i = 0; i < SSR_STEPS; ++i) {
        pos += dir_v * pow(float(i) * 0.15 + 1.0, 1.5);

        vec4 clip = gbufferProjection * vec4(pos, 1.0);
        vec2 uv   = clip.xy / clip.w * 0.5 + 0.5;

        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) break;
        if (length(pos) > SSR_MAX_DIST) break;

        float depth = texture(depthtex0, uv).r;
        vec3  hit   = screen_to_view(uv, depth);

        if (hit.z < pos.z - 0.1 && hit.z > pos.z - 2.0) {
            // Hit! Sample scene color
            // Apply roughness blur (mip-based approximation)
            float mip = roughness * 4.0;
            return textureLod(colortex0, uv, mip).rgb;
        }
    }

    // Fallback: screen edge / no hit
    return vec3(0.0);
}

// ─── Water surface color ─────────────────────────────────────────────────────
// Computes the final shaded water surface color.
// albedo     : water base color (biome tint)
// world_pos  : surface world position
// view_pos   : view-space position
// view_normal: view-space normal (camera-space)
// sun_dir_v  : view-space sun direction
// sun_color  : sun radiance
// sky_irr    : sky irradiance
vec3 shade_water(
    vec3  albedo,
    vec3  world_pos,
    vec3  view_pos,
    vec3  view_normal,
    vec3  sun_dir_v,
    vec3  sun_color,
    vec3  sky_irr,
    vec2  screen_coord,
    float skylight
) {
    vec3 V       = normalize(-view_pos);
    vec3 N       = view_normal;
    float NoV    = max(dot(N, V), 0.0);

    // Fresnel
    vec3 f0      = vec3(0.02); // water IOR ~1.33
    vec3 fresnel = fresnel_schlick(f0, NoV);

    // SSR (reflection)
    vec3 reflect_dir = reflect(-V, N);
    vec3 ssr_color   = vec3(0.0);
#ifdef WATER_SSR
    ssr_color = ssr(screen_coord, view_pos, reflect_dir, WATER_ROUGHNESS);
#endif

    // Sky contribution as fallback when SSR misses
    vec3 sky_refl = sky_irr * 0.1;
    vec3 reflection = mix(sky_refl, ssr_color, float(length(ssr_color) > 0.0));

    // Sun specular
    vec3  H    = normalize(sun_dir_v + V);
    float NoH  = max(dot(N, H), 0.0);
    float spec = ggx_ndf(NoH, WATER_ROUGHNESS * WATER_ROUGHNESS) * 0.25;
    vec3  sun_spec = sun_color * spec * fresnel;

    // Refraction (simple parallax)
    vec3 refract_color = albedo * sky_irr * 0.3 * skylight;

    // Composite
    vec3 color = mix(refract_color, reflection, fresnel);
    color     += sun_spec;

    return color;
}

// ─── Biome water color ────────────────────────────────────────────────────────
vec3 water_biome_tint() {
    vec3 base    = srgb_to_linear(vec3(WATER_COLOR_R, WATER_COLOR_G, WATER_COLOR_B));
    vec3 swamp   = vec3(0.12, 0.18, 0.08);
    vec3 jungle  = vec3(0.05, 0.22, 0.24);
    vec3 ocean   = vec3(0.04, 0.10, 0.28);

    vec3 tint = base;
    tint      = mix(tint, swamp,  biome_swamp);
    tint      = mix(tint, jungle, biome_jungle);
    return tint;
}

#endif // WATER_INCLUDED


