/*
================================================================================
  OffShades — include/sky/stars.glsl
  Procedural star field, shooting stars, Milky Way approximation.
================================================================================
*/

#ifndef STARS_INCLUDED
#define STARS_INCLUDED

#include "/include/utility/math.glsl"
#include "/include/utility/color.glsl"

// ─── Star field ──────────────────────────────────────────────────────────────
// Uses a hash-based point process.
// dir     : normalized view direction in world space
// Returns : star brightness (HDR)
float star_field(vec3 dir) {
    // Spherical coordinates
    vec2 uv;
    uv.x = atan(dir.x, dir.z) * (INV_PI * 0.5) + 0.5;
    uv.y = dir.y * 0.5 + 0.5;

    // Tile the sphere into cells
    vec2 cell    = floor(uv * STARS_DENSITY);
    vec2 frac_uv = fract(uv * STARS_DENSITY);

    float brightness = 0.0;

    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 neighbor = cell + vec2(x, y);
            // Random star position within cell
            vec2 star_pos = hash22(neighbor);
            vec2 diff     = frac_uv - (vec2(x, y) + star_pos);
            float dist_sq = dot(diff, diff);

            // Only render bright stars
            float threshold = hash12(neighbor + 523.7);
            if (threshold > STARS_COVERAGE) continue;

            // Star twinkle
            float twinkle = 1.0 + STARS_TWINKLE * sin(frameTimeCounter * (5.0 + 3.0 * hash12(neighbor)));

            float size = STARS_SIZE * (0.5 + 0.5 * threshold);
            brightness += max(0.0, 1.0 - sqrt(dist_sq) / size) * twinkle;
        }
    }

    return saturate(brightness) * STARS_BRIGHTNESS;
}

// ─── Star color from temperature ─────────────────────────────────────────────
// Very simple approximation: hotter = bluer
vec3 star_color(vec3 dir) {
    vec2 uv   = vec2(atan(dir.x, dir.z) * INV_PI * 0.5 + 0.5, dir.y * 0.5 + 0.5);
    float temp = hash12(floor(uv * STARS_DENSITY));
    // Map [0,1] temp to color: cool red → white blue
    return mix(vec3(1.0, 0.6, 0.4), vec3(0.7, 0.85, 1.0), temp);
}

// ─── Main star rendering ──────────────────────────────────────────────────────
// dir       : normalized world view direction
// night_factor : [0=day, 1=night] (suppress stars during day)
vec3 render_stars(vec3 dir, float night_factor) {
    if (night_factor < 0.001) return vec3(0.0);

    float brightness = star_field(dir);
    vec3  color      = mix(vec3(1.0), star_color(dir), 0.4);

    // Stars only visible above horizon
    float horizon = smoothstep(-0.02, 0.06, dir.y);

    return brightness * color * night_factor * horizon;
}

#endif // STARS_INCLUDED
