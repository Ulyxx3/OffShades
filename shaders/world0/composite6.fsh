#version 330 compatibility
/*
================================================================================
  OffShades — world0/composite6.fsh
  Color grading + tonemapping pass. This is the final HDR → LDR conversion.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/post/tonemap.glsl"
#include "/include/post/bloom.glsl"

varying vec2 v_uv;
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 scene_out;

void main() {
    vec3 hdr = texture(colortex0, v_uv).rgb;

    // Apply bloom
#ifdef BLOOM
    vec3 bloom_color = texture(colortex11, v_uv).rgb;
    hdr = apply_bloom(hdr, bloom_color);
#endif

    // Exposure
    hdr *= EXPOSURE;

    // Night factor for Purkinje shift
    vec3 sun_dir_w = normalize((gbufferModelViewInverse * vec4(sun_dir, 0.0)).xyz);
    float night_f  = 1.0 - smoothstep(-0.1, 0.15, sun_dir_w.y);

    // Tonemap + grade
    vec3 ldr = apply_tonemap(hdr, night_f);

    // Gamma correction
    ldr = linear_to_srgb(ldr);

    scene_out = vec4(ldr, 1.0);
}


