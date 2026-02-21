/*
================================================================================
  OffShades — include/utility/color.glsl
  Color space conversions, tonemapping operators, white balance.
================================================================================
*/

#ifndef UTILITY_COLOR_INCLUDED
#define UTILITY_COLOR_INCLUDED

// ============================================================
//   Color Space Conversions
// ============================================================

// sRGB → Linear (accurate gamma)
vec3 srgb_to_linear_accurate(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

// Linear → sRGB (accurate gamma)
vec3 linear_to_srgb_accurate(vec3 c) {
    c = max(c, 0.0);
    return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
}

// BT.709 luminance
float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// BT.601 luminance (legacy, slightly faster)
float luma601(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

// RGB → HSV
vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV → RGB
vec3 hsv_to_rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// ============================================================
//   White Balance (D65 Chromatic Adaptation)
// ============================================================

// Kelvin temperature to approximate RGB tint (blackbody approximation)
vec3 kelvin_to_rgb(float kelvin) {
    float t = kelvin / 100.0;
    float r, g, b;

    if (t <= 66.0) {
        r = 1.0;
        g = clamp((99.4708025861 * log(t) - 161.1195681661) / 255.0, 0.0, 1.0);
        b = (t <= 19.0) ? 0.0 : clamp((138.5177312231 * log(t - 10.0) - 305.0447927307) / 255.0, 0.0, 1.0);
    } else {
        r = clamp((329.698727446 * pow(t - 60.0, -0.1332047592)) / 255.0, 0.0, 1.0);
        g = clamp((288.1221695283 * pow(t - 60.0, -0.0755148492)) / 255.0, 0.0, 1.0);
        b = 1.0;
    }
    return vec3(r, g, b);
}

// Apply white balance correction based on GRADE_WHITE_BALANCE (default 6500K → D65)
vec3 apply_white_balance(vec3 color, float kelvin) {
    vec3 target = kelvin_to_rgb(kelvin);
    vec3 ref    = kelvin_to_rgb(6500.0);
    return color * (ref / max(target, 1e-6));
}

// ============================================================
//   Tonemapping Operators
// ============================================================

// Reinhard
vec3 tonemap_reinhard(vec3 x) {
    return x / (1.0 + x);
}

// Reinhard-Jodie (luminance-based)
vec3 tonemap_reinhard_jodie(vec3 x) {
    float l = luma(x);
    vec3 tv = x / (1.0 + x);
    return mix(x / (1.0 + l), tv, tv);
}

// Lottes (smooth film-like, default)
vec3 tonemap_lottes(vec3 x) {
    const vec3 a = vec3(1.6);
    const vec3 d = vec3(0.977);
    const vec3 hdrMax = vec3(8.0);
    const vec3 midIn  = vec3(0.18);
    const vec3 midOut = vec3(0.267);

    vec3 b = (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
             ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
    vec3 c = (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
             ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);

    return pow(x, a) / (pow(x, a * d) * b + c);
}

// ACES (fit by Stephen Hill)
vec3 tonemap_aces_fit(vec3 x) {
    x *= 0.6;
    x = max(vec3(0.0), x - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

// Hejl 2015 (film-like, preserves saturation)
vec3 tonemap_hejl_2015(vec3 x) {
    vec4 vh = vec4(x, 1.0);
    vec4 va = 1.425 * vh + 0.05;
    vec4 vf = (vh * va + 0.004) / (vh * (va + 0.55) + 0.0491) - 0.0821;
    return vf.xyz / vf.www;
}

// Burgess (filmic)
vec3 tonemap_hejl_burgess(vec3 x) {
    x = max(vec3(0.0), x - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

// Uncharted 2
vec3 tonemap_uncharted_2_partial(vec3 x) {
    const float A=0.15, B=0.50, C=0.10, D=0.20, E=0.02, F=0.30;
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}
vec3 tonemap_uncharted_2(vec3 x) {
    x *= 2.0;
    vec3 curr = tonemap_uncharted_2_partial(x);
    vec3 w    = tonemap_uncharted_2_partial(vec3(11.2));
    return curr / w;
}

// Uchimura / Gran Turismo
vec3 tonemap_tech(vec3 x) {
    const float a = 1.0, b = 0.55, c = 0.5, d = 0.35;
    return clamp(a * pow(abs(x), vec3(a)) / (pow(abs(x), vec3(a * b)) * pow(b, a * d) + pow(b, a * c) * c), 0.0, 1.0);
}

// Ozius (simple, punchy contrast)
vec3 tonemap_ozius(vec3 x) {
    x = pow(x, vec3(1.0/2.2));
    return x / (1.0 + x) * 1.5;
}

// ============================================================
//   Saturation / Hue Operations
// ============================================================

// Adjust saturation
vec3 adjust_saturation(vec3 color, float saturation) {
    float l = luma(color);
    return mix(vec3(l), color, saturation);
}

// Hue rotation (fast approximate)
vec3 rotate_hue(vec3 color, float radians) {
    float cos_a = cos(radians), sin_a = sin(radians);
    const vec3 k = vec3(0.57735);
    return color * cos_a + cross(k, color) * sin_a + k * dot(k, color) * (1.0 - cos_a);
}

// Selective color boost (hue-range saturation)
float hue_in_range(vec3 rgb, float center_hue, float range) {
    vec3 hsv = rgb_to_hsv(rgb);
    float d = abs(hsv.x - center_hue);
    d = min(d, 1.0 - d); // wrap
    return clamp(1.0 - d / range, 0.0, 1.0);
}

// ============================================================
//   Purkinje Shift (scotopic vision blue shift at night)
// ============================================================

vec3 apply_purkinje(vec3 color, float night_factor, float intensity) {
    float lum = luma(color);
    vec3 purkinje = vec3(0.5, 0.7, 1.0) * lum;
    return mix(color, purkinje, saturate(night_factor * intensity * 0.3));
}

#endif // UTILITY_COLOR_INCLUDED


