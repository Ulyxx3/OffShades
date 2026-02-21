/*
================================================================================
  OffShades — include/misc/nether.glsl
  Nether dimension atmosphere: biome-colored ambient, lava glow, Nether fog.
  Adapted from Photon Shaders by Sixthsurge.
================================================================================
*/

#ifndef NETHER_INCLUDED
#define NETHER_INCLUDED

#include "/include/utility/math.glsl"
#include "/include/utility/color.glsl"

// ─── Nether ambient light ─────────────────────────────────────────────────────
// Nether has no sky light; ambient comes from the lava sea and biome color.
vec3 nether_ambient(float blocklight) {
    // Lava glow adds warm red-orange tint
    vec3 lava_glow  = srgb_to_linear(vec3(1.0, 0.35, 0.05)) * 0.5;
    // Use the NETHER_R/G/B ambient color from settings
    vec3 biome_light = srgb_to_linear(vec3(NETHER_R, NETHER_G, NETHER_B)) * NETHER_I;

    return biome_light + lava_glow * (0.5 + 0.5 * blocklight);
}

// ─── Nether fog ───────────────────────────────────────────────────────────────
// Distance-based exponential fog, tinted by the Nether ambient color.
// NETHER_FOG_DENSITY default: derived from render distance (~0.02)
#ifndef NETHER_FOG_DENSITY
  #define NETHER_FOG_DENSITY 0.020 // [0.005 0.010 0.015 0.020 0.030 0.050]
#endif

vec3 nether_fog_color() {
    // Fog color = ambient color, slightly desaturated
    return srgb_to_linear(vec3(NETHER_R * 0.6, NETHER_G * 0.4, NETHER_B * 0.3));
}

// Apply fog to a Nether scene color
vec3 apply_nether_fog(vec3 scene_color, float view_dist) {
    float fog   = 1.0 - exp(-view_dist * NETHER_FOG_DENSITY);
    vec3  color = nether_fog_color();

    // Add lava-glow tint at close range
    float lava_near = exp(-view_dist * 0.05);
    color = mix(color, srgb_to_linear(vec3(1.0, 0.4, 0.1)) * 2.0, lava_near * 0.15);

    return mix(scene_color, color, fog * NETHER_FOG_INTENSITY);
}

// ─── Nether sky (no actual sky, but a ceiling glow) ──────────────────────────
// Returns a "sky" color for directions pointing up (ceiling)
vec3 nether_sky(vec3 rd) {
    // Simple gradient: dark red ceiling fading to fog color
    float up = rd.y * 0.5 + 0.5;
    return mix(nether_fog_color(), srgb_to_linear(vec3(0.5, 0.05, 0.02)) * 0.2, up);
}

// ─── Nether deferred shading (no sun/shadow) ─────────────────────────────────
vec3 nether_shade(vec3 albedo, float emission, float blocklight) {
    vec3 ambient = nether_ambient(blocklight);
    vec3 emissive = albedo * emission * EMISSION_STRENGTH;

    float bl = blocklight * blocklight;
    vec3 block_contrib = albedo * blocklight_color() * bl * BLOCKLIGHT_I;

    return albedo * ambient + emissive + block_contrib;
}

#endif // NETHER_INCLUDED
