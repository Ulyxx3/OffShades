#version 330 compatibility
/*
================================================================================
  OffShades — world0/composite4.fsh
  Bloom downsample: extracts bright pixels and downsamples to colortex11.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/post/bloom.glsl"

varying vec2 v_uv;
/* DRAWBUFFERS:11 */
layout(location = 0) out vec4 bloom_out;

void main() {
    vec3 color = bloom_threshold(texture(colortex0, v_uv).rgb);
    bloom_out = vec4(kawase_downsample(colortex0, v_uv, view_pixel_size * 2.0)
                     * float(luminance(color) > 0.0), 1.0);
}


