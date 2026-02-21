/*
================================================================================
  OffShades — include/post/tonemap.glsl
  Multiple tonemapping operators + color grading.
================================================================================
*/

#ifndef TONEMAP_INCLUDED
#define TONEMAP_INCLUDED

#include "/include/utility/color.glsl"

// ─── Lottes ──────────────────────────────────────────────────────────────────
vec3 tonemap_lottes(vec3 x) {
    const float a  = 1.6;
    const float d  = 0.977;
    const float hdr_max = 8.0;
    const float mid_in  = 0.18;
    const float mid_out = 0.267;

    float b = (-pow(mid_in, a) + pow(hdr_max, a) * mid_out) /
              ((pow(hdr_max, a * d) - pow(mid_in, a * d)) * mid_out);
    float c = (pow(hdr_max, a * d) * pow(mid_in, a) - pow(hdr_max, a) * pow(mid_in, a * d) * mid_out) /
              ((pow(hdr_max, a * d) - pow(mid_in, a * d)) * mid_out);

    return pow(x, vec3(a)) / (pow(x, vec3(a * d)) * b + c);
}

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

// ─── Reinhard ────────────────────────────────────────────────────────────────
vec3 tonemap_reinhard(vec3 x) {
    return x / (x + 1.0);
}

// ─── Reinhard-Jodie (luminance-based) ────────────────────────────────────────
vec3 tonemap_reinhard_jodie(vec3 x) {
    float L  = luminance(x);
    vec3  tc = x / (x + 1.0);
    return mix(x / (L + 1.0), tc, tc);
}

// ─── Purkinje shift (night = blue shift) ──────────────────────────────────────
vec3 purkinje_shift(vec3 color, float night_factor) {
#ifndef PURKINJE_SHIFT
    return color;
#endif
    // Scotopic (rod) luminance peaks at ~507 nm (blue-green)
    float L_scotopic = dot(color, vec3(0.2126, 0.7152, 0.0722));
    vec3  scotopic   = L_scotopic * vec3(0.55, 0.70, 1.0);
    return mix(color, scotopic, night_factor * PURKINJE_STRENGTH);
}

// ─── Color grading ────────────────────────────────────────────────────────────
vec3 color_grade(vec3 color) {
    // Brightness / Contrast
    color = (color - 0.5) * (CONTRAST + 1.0) + 0.5;
    color *= BRIGHTNESS;

    // Saturation
    float lum  = luminance(color);
    color      = mix(vec3(lum), color, SATURATION);

    // White balance (simple RGB offset)
    color *= srgb_to_linear(vec3(WHITE_BALANCE_R, WHITE_BALANCE_G, WHITE_BALANCE_B));

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
