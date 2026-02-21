/*
================================================================================
  OffShades — include/lighting/lighting.glsl
  Main deferred shading: combines direct light, shadow, AO, sky.
================================================================================
*/

#ifndef LIGHTING_INCLUDED
#define LIGHTING_INCLUDED

#include "/include/utility/color.glsl"
#include "/include/lighting/pbr.glsl"
#include "/include/lighting/shadows.glsl"
#include "/include/lighting/ao.glsl"

// ─── Block-light color ───────────────────────────────────────────────────────
vec3 blocklight_color() {
    return srgb_to_linear(vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B));
}

// ─── Sky / indirect diffuse contribution ────────────────────────────────────
// Reads from the sky irradiance stored in colortex4 (computed in deferred.fsh)
vec3 sky_irradiance(vec3 normal, sampler2D sky_map) {
    // Equirectangular sky map lookup from normal direction
    vec3  n   = normalize(normal);
    float u   = atan(n.x, n.z) * INV_PI * 0.5 + 0.5;
    float v   = acos(clamp(n.y, -1.0, 1.0)) * INV_PI;
    return texture(sky_map, vec2(u, v)).rgb;
}

// ─── SSS transmittance (simple)  ────────────────────────────────────────────
// sss_amount : material SSS factor [0,1]
// sss_depth  : estimated shadow-space absorb distance (from blocker search)
vec3 sss_transmittance(float sss_amount, float sss_depth, vec3 subsurface_color) {
    if (sss_amount < EPS) return vec3(0.0);
    // Beer-Lambert: transmittance = exp(-density * depth)
    float density   = 6.0 * (1.0 - sss_amount);
    vec3  absorb    = 1.0 - subsurface_color;
    return exp(-absorb * density * sss_depth) * sss_amount;
}

// ─── Main lighting computation ───────────────────────────────────────────────
// scene_pos   : world-space (camera-relative) position
// normal      : smooth shading normal (view or world, must match V,L)
// flat_normal : geometry (face) normal for shadow bias
// albedo      : linear albedo
// f0          : specular F0
// roughness   : perceptual roughness
// metalness   : [0,1]
// emission    : emissive value [0,1]
// skylight    : sky lightmap value
// blocklight  : block lightmap value
// sss_amount  : SSS intensity
// subsurface_color : SSS tint
struct LightingResult {
    vec3 color;
    vec3 ao_debug;
};

LightingResult compute_lighting(
    vec3  scene_pos,
    vec3  normal,
    vec3  flat_normal,
    vec3  albedo,
    vec3  f0,
    float roughness,
    float metalness,
    float emission,
    float skylight,
    float blocklight,
    float sss_amount,
    vec3  subsurface_color,
    float cloud_shadows,
    vec2  ao_dither,
    vec3  screen_pos,
    vec3  view_pos,
    sampler2D sky_map
) {
    vec3 color = vec3(0.0);
    vec3 V     = normalize(-view_pos);
    vec3 L     = light_dir; // from global.glsl custom uniform

    // ── Sun / moon direct lighting ──
    // Sun/moon irradiance scale
    bool isDay = sunAngle < 0.5;
    // Use noon constants for base sunlight/moonlight in block shading
    vec3 direct_light_color = isDay ?
        srgb_to_linear(vec3(SUN_NR,  SUN_NG,  SUN_NB )) * SUN_I :
        srgb_to_linear(vec3(MOON_R, MOON_G, MOON_B)) * MOON_I;

    // Shadow
    float sss_depth    = 0.0;
    float distance_fade = 0.0;
    float sss_inout    = sss_amount;

    vec3 shadows = calculate_shadows(
        scene_pos, flat_normal, skylight, cloud_shadows,
        sss_inout, distance_fade, sss_depth
    );

    float NoL = max(dot(normal, L), 0.0);

    // BRDF
    BRDFResult brdf = evaluate_brdf(albedo, f0, roughness, metalness, L, V, normal);

    vec3 direct = (brdf.diffuse * NoL + brdf.specular * NoL) * direct_light_color * shadows * PI;

    // ── SSS backlight ──
    vec3 sss = sss_transmittance(sss_amount, sss_depth, subsurface_color)
              * direct_light_color * shadows;
    color += sss;

    // ── AO ──
    float ao = compute_ao(screen_pos, view_pos, normal, ao_dither);

    // ── Sky ambient ──
    vec3 sky   = sky_irradiance(normal, sky_map) * SKYLIGHT_I;
    sky       *= skylight * skylight; // lightmap-based sky falloff

    // Ambient diffuse
    vec3 ambient_diff = albedo * (1.0 - metalness) * sky * ao;

    // Approximate ambient specular
    vec3 R    = reflect(-V, normal);
    float NdotV = max(dot(normal, V), EPS);
    vec3  fenv = fresnel_schlick_roughness(f0, NdotV, roughness);
    vec3  ambient_spec = sky_irradiance(R, sky_map) * fenv * SKYLIGHT_I * ao;

    color += direct;
    color += ambient_diff;
    color += ambient_spec;

    // ── Block light ──
    float bl_strength = blocklight * blocklight;
    color += albedo * blocklight_color() * bl_strength * BLOCKLIGHT_I;

    // ── Emissive ──
    color += albedo * emission * EMISSION_STRENGTH;

    // ── Darkening from AO debug view ──
    LightingResult result;
    result.color    = color;
    result.ao_debug = vec3(ao);
    return result;
}

#endif // LIGHTING_INCLUDED
