#version 330 compatibility
/*
================================================================================
  OffShades — world0/deferred2.fsh
  Cloud temporal upscaling / reprojection.
  Takes half-res cloud buffer from colortex9 and blends with history (colortex10)
  to produce full-res cloud result written back to colortex9.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/depth.glsl"

varying vec2 v_uv;

/* DRAWBUFFERS:9 */
layout(location = 0) out vec4 cloud_upscale;

void main() {
    // Current frame cloud sample (may be at half-res UV offset)
    vec4 current    = texture(colortex9,  v_uv);
    // History (previous frame)
    vec2 prev_uv    = reproject_uv(screen_to_scene(v_uv, texture(depthtex0, v_uv).r));
    vec4 history    = texture(colortex10, prev_uv);

    // Checkerboard upsample: flip between frames for temporal accumulation
    float blend = (prev_uv.x >= 0.0 && prev_uv.x <= 1.0 &&
                   prev_uv.y >= 0.0 && prev_uv.y <= 1.0) ? 0.1 : 1.0;

    cloud_upscale = mix(history, current, blend);
}
