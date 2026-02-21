/*
================================================================================
  OffShades — world0/composite5.fsh
  Bloom upsample: upsamples colortex11 back to full-res bloom result.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/post/bloom.glsl"

varying vec2 v_uv;
/* DRAWBUFFERS:11 */
layout(location = 0) out vec4 bloom_out;

void main() {
    vec3 upsampled = kawase_upsample(colortex11, v_uv, view_pixel_size * 2.0);
    bloom_out = vec4(upsampled, 1.0);
}
