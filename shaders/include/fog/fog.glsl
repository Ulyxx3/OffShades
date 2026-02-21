/*
================================================================================
  OffShades — include/fog/fog.glsl
  Volumetric aerial-perspective fog, biome-aware fog tints.
  Adapted from Photon Shaders by Sixthsurge.
================================================================================
*/

#ifndef FOG_INCLUDED
#define FOG_INCLUDED

#include "/include/utility/math.glsl"
#include "/include/utility/color.glsl"
#include "/include/sky/atmosphere.glsl"

// ─── Fog parameters per biome ────────────────────────────────────────────────
// Blended in main programs using biome_* uniforms from shaders.properties

vec3 overworld_fog_color(vec3 sun_dir, vec3 sky_color_horizon) {
    // Horizon glow from sun
    vec3 base  = sky_color_horizon;
    float glow = pow(max(0.0, sun_dir.y), 2.0);
    return mix(base, vec3(1.0, 0.55, 0.2) * 2.0, glow * 0.3);
}

// ─── Mie phase (forward-scattering fog glow) ─────────────────────────────────
float mie_phase_approx(float cos_theta) {
    // Cornette-Shanks approximation
    const float g = FOG_MIE_G;
    float g2 = g * g;
    return (1.5 * (1.0 - g2) / (2.0 + g2))
         * (1.0 + cos_theta * cos_theta)
         / pow(1.0 + g2 - 2.0 * g * cos_theta, 1.5);
}

// ─── Overworld fog density ────────────────────────────────────────────────────
float fog_density(float height, float sea_level) {
    float h  = max(height - sea_level, 0.0);
    float hf = h / FOG_HEIGHT;
    return exp(-hf * FOG_FALLOFF);
}

// ─── Volumetric light shaft (simple) ─────────────────────────────────────────
// Integrates inscattered light along a ray segment
// ro      : ray origin (view position in world space)
// rd      : normalized ray direction
// dist    : max march distance
// sun_dir : normalized sun direction  
// shadow  : 0=in shadow, 1=lit (cloud shadow)
vec3 volumetric_fog(vec3 ro, vec3 rd, float dist, vec3 sun_dir,
                    vec3 sky_irr, vec3 sun_color, float shadow) {
    const int STEPS = VL_STEPS;

    float step_size = min(dist, VL_MAX_DIST) / float(STEPS);
    vec3  scatter   = vec3(0.0);
    float transmit  = 1.0;

    float cos_theta    = dot(rd, sun_dir);
    float mie_phase    = mie_phase_approx(cos_theta);
    float ray_phase    = (3.0 / (16.0 * PI)) * (1.0 + cos_theta * cos_theta);

    float dither = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);

    vec3 p = ro + rd * (step_size * dither);

    for (int i = 0; i < STEPS; ++i, p += rd * step_size) {
        float density = fog_density(p.y + cameraPosition.y, SEA_LEVEL) * FOG_DENSITY;
        if (density < 1e-6) continue;

        float sigma_e = density * (FOG_RAYLEIGH + FOG_MIE);
        float sigma_s = density * (FOG_RAYLEIGH * 0.9 + FOG_MIE);

        // In-scatter: sun + sky
        vec3 sun_in = sun_color * mie_phase * shadow;
        vec3 sky_in = sky_irr  * ray_phase;
        vec3 in_scatter = sigma_s * (sun_in + sky_in);

        float step_t = exp(-sigma_e * step_size);
        scatter  += (in_scatter - in_scatter * step_t) / (sigma_e + EPS) * transmit;
        transmit *= step_t;

        if (transmit < 0.01) break;
    }

    return scatter;
}

// ─── Border fog (distance-based fade) ────────────────────────────────────────
float border_fog(float view_dist) {
    return 1.0 - exp(-view_dist * view_dist / (BORDER_FOG_DISTANCE * BORDER_FOG_DISTANCE));
}

// ─── Apply fog to a scene color ──────────────────────────────────────────────
vec3 apply_overworld_fog(
    vec3 scene_color,
    vec3 ro, vec3 rd, float dist,
    vec3 sun_dir, vec3 sky_irr, vec3 sun_color,
    float shadow, float skylight
) {
    vec3  vl_scatter = vec3(0.0);

#ifdef VOLUMETRIC_FOG
    vl_scatter = volumetric_fog(ro, rd, dist, sun_dir, sky_irr, sun_color, shadow);
    vl_scatter *= skylight; // suppress in caves
#endif

    // Exponential distance fog
    vec3  fog_color    = overworld_fog_color(sun_dir, sky_irr * 0.2);
    float fog_amount   = 1.0 - exp(-dist * FOG_DENSITY * 0.0005);

    vec3 result = mix(scene_color, fog_color, fog_amount * OVERWORLD_FOG_INTENSITY * skylight);
    result     += vl_scatter;

#ifdef BORDER_FOG
    float bf = border_fog(dist);
    result = mix(result, fog_color, bf * BORDER_FOG_INTENSITY);
#endif

    return result;
}

#endif // FOG_INCLUDED
