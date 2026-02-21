/*
================================================================================
  OffShades — include/post/bloom.glsl
  Dual-Kawase blur bloom: downsample + upsample chain.
================================================================================
*/

#ifndef BLOOM_INCLUDED
#define BLOOM_INCLUDED

#include "/include/utility/math.glsl"

// ─── Luminance threshold (extract bright pixels) ─────────────────────────────
vec3 bloom_threshold(vec3 color) {
    float brightness = luminance(color);
    float weight     = max(brightness - BLOOM_THRESHOLD, 0.0) / max(brightness, 0.001);
    return color * weight;
}

// ─── Dual Kawase downsample ───────────────────────────────────────────────────
// Sample 4+1 neighbours rotated 45° (Kawase, SIGGRAPH 2003).
// Pass this to a series of half-res buffers.
vec3 kawase_downsample(sampler2D src, vec2 uv, vec2 texel_size) {
    vec3 color = vec3(0.0);
    color += texture(src, uv + vec2( 0.5,  0.5) * texel_size).rgb;
    color += texture(src, uv + vec2(-0.5,  0.5) * texel_size).rgb;
    color += texture(src, uv + vec2(-0.5, -0.5) * texel_size).rgb;
    color += texture(src, uv + vec2( 0.5, -0.5) * texel_size).rgb;
    return color * 0.25;
}

// ─── Dual Kawase upsample ─────────────────────────────────────────────────────
// Upsamples from half-res with bilinear blending.
vec3 kawase_upsample(sampler2D src, vec2 uv, vec2 texel_size) {
    vec3 color = vec3(0.0);
    // 8-tap bilinear
    color += texture(src, uv + vec2(-1.0,  0.0) * texel_size).rgb * 2.0;
    color += texture(src, uv + vec2( 1.0,  0.0) * texel_size).rgb * 2.0;
    color += texture(src, uv + vec2( 0.0, -1.0) * texel_size).rgb * 2.0;
    color += texture(src, uv + vec2( 0.0,  1.0) * texel_size).rgb * 2.0;
    color += texture(src, uv + vec2(-1.0, -1.0) * texel_size).rgb;
    color += texture(src, uv + vec2( 1.0, -1.0) * texel_size).rgb;
    color += texture(src, uv + vec2(-1.0,  1.0) * texel_size).rgb;
    color += texture(src, uv + vec2( 1.0,  1.0) * texel_size).rgb;
    return color / 12.0;
}

// ─── Apply bloom to scene color ───────────────────────────────────────────────
// bloom_color : the result of the upsample chain (sampled from colortex11)
// scene_color : the scene HDR color before tonemap
vec3 apply_bloom(vec3 scene_color, vec3 bloom_color) {
    return scene_color + bloom_color * BLOOM_STRENGTH;
}

#endif // BLOOM_INCLUDED
