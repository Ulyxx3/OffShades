#version 330 compatibility
/*
================================================================================
  OffShades — world0/final.fsh
  Final output pass: FXAA anti-aliasing, contrast-adaptive sharpening,
  vignette, film grain, and final display output.
================================================================================
*/
#include "/include/global.glsl"

varying vec2 v_uv;

// ─── FXAA (Nvidia FXAA 3.11 simplified) ──────────────────────────────────────
#ifdef FXAA
vec3 fxaa(sampler2D src, vec2 uv, vec2 pixel_size) {
    vec3 c[] = vec3[](
        texture(src, uv + vec2(-1,-1) * pixel_size).rgb,
        texture(src, uv + vec2( 1,-1) * pixel_size).rgb,
        texture(src, uv + vec2(-1, 1) * pixel_size).rgb,
        texture(src, uv + vec2( 1, 1) * pixel_size).rgb,
        texture(src, uv).rgb
    );
    float luma[] = float[](luminance(c[0]), luminance(c[1]), luminance(c[2]), luminance(c[3]), luminance(c[4]));
    float l_min  = min(min(luma[0], luma[1]), min(luma[2], luma[3]));
    float l_max  = max(max(luma[0], luma[1]), max(luma[2], luma[3]));
    float contrast = l_max - l_min;

    if (contrast < max(FXAA_EDGE_THRESHOLD_MIN, l_max * FXAA_EDGE_THRESHOLD)) return c[4];

    // Blend fomula
    float blend = 0.0;
    blend += luma[0] + luma[1] + luma[2] + luma[3];
    blend  = blend * 0.25;
    blend  = abs(blend - luma[4]) / contrast;
    blend  = smoothstep(0.0, 1.0, blend);
    blend  = blend * blend * FXAA_SUBPIXEL_QUALITY;

    // Edge direction
    float h = abs((luma[0] + luma[2]) - (luma[1] + luma[3]));
    float v = abs((luma[0] + luma[1]) - (luma[2] + luma[3]));
    vec2 edge_dir = (h > v) ? vec2(0, pixel_size.y) : vec2(pixel_size.x, 0);

    vec3 result = mix(c[4], (texture(src, uv + edge_dir).rgb + texture(src, uv - edge_dir).rgb) * 0.5, blend);
    return result;
}
#endif

// ─── CAS (Contrast-Adaptive Sharpening — simplified) ─────────────────────────
#ifdef CAS
vec3 cas_sharpen(sampler2D src, vec2 uv, vec2 ps) {
    vec3 a   = texture(src, uv + vec2(-ps.x,  0)).rgb;
    vec3 b   = texture(src, uv + vec2( ps.x,  0)).rgb;
    vec3 c   = texture(src, uv + vec2( 0, -ps.y)).rgb;
    vec3 d   = texture(src, uv + vec2( 0,  ps.y)).rgb;
    vec3 e   = texture(src, uv).rgb;

    vec3 mn  = min(min(a, b), min(c, d));
    vec3 mx  = max(max(a, b), max(c, d));
    vec3 w   = clamp(-1.0 / sqrt(max(vec3(0.0125), max(mn / mx, (1.0 - mx) / (1.0 - mn)))), -0.125, 0.0);
    vec3 sharpen = (e + (e - (a + b + c + d) * w) * CAS_SHARPNESS * rcp(1.0 + 4.0 * abs(w)));
    return max(vec3(0.0), sharpen);
}
#endif

void main() {
    vec3 color = texture(colortex0, v_uv).rgb;

#ifdef FXAA
    color = fxaa(colortex0, v_uv, view_pixel_size);
#endif

#ifdef CAS
    color = cas_sharpen(colortex0, v_uv, view_pixel_size);
#endif

    // Vignette
#ifdef VIGNETTE
    vec2  vc = v_uv * 2.0 - 1.0;
    float vg = 1.0 - VIGNETTE_STRENGTH * pow(dot(vc * VIGNETTE_FALLOFF, vc), 1.5);
    color   *= vg;
#endif

    // Film grain
#ifdef FILM_GRAIN
    float grain = fract(sin(dot(gl_FragCoord.xy + float(frameCounter) * 17.4, vec2(12.9898, 78.233))) * 43758.5453);
    color      += (grain - 0.5) * FILM_GRAIN_STRENGTH;
#endif

    gl_FragColor = vec4(max(color, vec3(0.0)), 1.0);
}
