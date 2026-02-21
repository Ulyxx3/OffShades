/*
================================================================================
  OffShades — include/post/tonemap.glsl
  Multiple tonemapping operators + color grading.
================================================================================
*/

#ifndef TONEMAP_INCLUDED
#define TONEMAP_INCLUDED

#include "/include/utility/color.glsl"


// ─── ACES (Krzysztof Narkowicz approximation) ────────────────────────────────
vec3 tonemap_aces(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

// ─── Hejl/Burgess-Dawson filmic ──────────────────────────────────────────────
vec3 tonemap_hejl(vec3 x) {
    vec3 t0 = max(vec3(0.0), x - 0.004);
    return (t0 * (6.2 * t0 + 0.5)) / (t0 * (6.2 * t0 + 1.7) + 0.06);
}


// ─── Purkinje shift (night = blue shift) ──────────────────────────────────────
vec3 purkinje_shift(vec3 color, float night_factor) {
#ifndef PURKINJE_SHIFT
    return color;
#endif
    // Scotopic (rod) luminance peaks at ~507 nm (blue-green)
    float L_scotopic = dot(color, vec3(0.2126, 0.7152, 0.0722));
    vec3  scotopic   = L_scotopic * vec3(0.55, 0.70, 1.0);
    return mix(color, scotopic, night_factor * PURKINJE_SHIFT_INTENSITY);
}

// ─── Color grading ────────────────────────────────────────────────────────────
vec3 color_grade(vec3 color) {
    // Brightness / Contrast (HDR safe pivoting around 0.18 linear)
    color = max(vec3(0.0), color); // Prevent NaNs
    color = pow(color / 0.18, vec3(GRADE_CONTRAST)) * 0.18;
    color *= GRADE_BRIGHTNESS;

    // Saturation
    float lum  = luminance(color);
    color      = mix(vec3(lum), color, GRADE_SATURATION);

    // White balance (simple RGB offset)
    color *= srgb_to_linear(vec3(1.0)); // simple placeholder for WHITE_BALANCE_R/G/B since they don't exist

    // Hue shifts (crude: shift channels)
    // Skipped for simplicity — can be added later via LUT

    return max(color, vec3(0.0));
}

// ─── Dispatch ────────────────────────────────────────────────────────────────
vec3 apply_tonemap(vec3 color, float night_factor) {
    color  = color_grade(color);
    color  = purkinje_shift(color, night_factor);

#if TONEMAPPING == TONEMAP_LOTTES
    color = tonemap_lottes(color);
#elif TONEMAPPING == TONEMAP_ACES
    color = tonemap_aces(color);
#elif TONEMAPPING == TONEMAP_HEJL
    color = tonemap_hejl(color);
#elif TONEMAPPING == TONEMAP_REINHARD
    color = tonemap_reinhard(color);
#elif TONEMAPPING == TONEMAP_REINHARD_JODIE
    color = tonemap_reinhard_jodie(color);
#else
    // None / Linear
#endif

    return color;
}

#endif // TONEMAP_INCLUDED


