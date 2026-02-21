/*
================================================================================
  OffShades — include/water/underwater.glsl
  Underwater rendering: volumetric fog, caustics, Snell's window.
  Adapted from Complementary Reimagined Shaders by EminGT.
================================================================================
*/

#ifndef UNDERWATER_INCLUDED
#define UNDERWATER_INCLUDED

#include "/include/utility/math.glsl"
#include "/include/utility/color.glsl"

// ─── Underwater absorption ────────────────────────────────────────────────────
// Water absorbs red most, then green, blue passes farthest
const vec3 water_absorption = vec3(
    WATER_ABSORPTION_R,
    WATER_ABSORPTION_G,
    WATER_ABSORPTION_B
);

vec3 underwater_transmittance(float depth) {
    return exp(-water_absorption * depth);
}

// ─── Caustics projection ──────────────────────────────────────────────────────
// Animates a caustics pattern projected from above onto underwater surfaces
float caustics(vec3 world_pos, float time) {
    // Multiple FBM layers in different directions
    vec3 p = world_pos * WATER_CAUSTICS_SCALE + vec3(time * 0.3, 0.0, time * 0.2);

    float c = 0.0;
    c += abs(sin(p.x * 2.1 + sin(p.z * 1.7))) * 0.5;
    c += abs(sin(p.x * 3.7 + sin(p.z * 2.9))) * 0.25;
    c += abs(sin(p.x * 5.3 + sin(p.z * 4.1))) * 0.125;
    c *= abs(sin(p.z * 1.3 + sin(p.x * 0.9)));

    return saturate(c * 1.5) * WATER_CAUSTICS_STRENGTH;
}

// ─── Snell's window ───────────────────────────────────────────────────────────
// The bright cone of light visible looking up through the water surface
// view_dir     : normalized view direction (camera-relative, world space)
// Returns      : window factor [0,1]
float snell_window(vec3 view_dir) {
#ifndef WATER_SNELL_WINDOW
    return 0.0;
#endif
    // Critical angle for water (n=1.33): ~48.75°
    const float critical_cos = 0.6569; // cos(48.75°)
    float cos_up = max(0.0, view_dir.y);
    float window = smoothstep(critical_cos + 0.01, critical_cos + 0.08, cos_up);
    return window;
}

// ─── Underwater volumetric fog ────────────────────────────────────────────────
// scene_color  : pre-lit scene color
// view_pos     : view-space surface position
// world_pos    : world position
// sun_dir      : world sun direction
// sun_color    : sun radiance
// skylight     : sky lightmap
vec3 apply_underwater(
    vec3  scene_color,
    vec3  view_pos,
    vec3  world_pos,
    vec3  sun_dir,
    vec3  sun_color,
    float skylight
) {
    float view_dist = length(view_pos);

    // Distance-based absorption
    vec3  transmit = underwater_transmittance(view_dist * WATER_DENSITY);

    // Water scatter color: blue-green ambient (approximated based on scattering coefficient)
    vec3  scatter_color = vec3(0.1, 0.4, 0.5) * WATER_SCATTERING_UNDERWATER;
    vec3  scatter       = scatter_color * (1.0 - vec3(transmit)) * skylight;

    // Caustics
    float caus = 0.0;
#ifdef WATER_CAUSTICS
    caus = caustics(world_pos, frameTimeCounter);
    scene_color *= 1.0 + caus * sun_color.r * skylight;
#endif

    // Apply absorption and scatter
    vec3 color = scene_color * transmit + scatter;

    // Snell's window (bright upward glow)
    vec3 view_dir = normalize(-(gbufferModelViewInverse * vec4(view_pos, 1.0)).xyz);
    float window  = snell_window(view_dir);
    color += sun_color * window * 0.5;

    return color;
}

#endif // UNDERWATER_INCLUDED
