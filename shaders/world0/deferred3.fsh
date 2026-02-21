#version 330 compatibility
/*
================================================================================
  OffShades — world0/deferred3.fsh
  AO computation pass (GTAO or SSAO). Writes AO result to colortex6.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/depth.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/lighting/ao.glsl"

varying vec2 v_uv;

/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 ao_out; // colortex6

void main() {
    float depth = texture(depthtex0, v_uv).r;

    // No AO for sky
    if (is_sky(depth)) {
        ao_out = vec4(1.0);
        return;
    }

    vec3 view_pos    = screen_to_view(v_uv, depth);
    vec3 screen_pos  = vec3(v_uv, depth);

    // Decode normal from gbuffer
    vec4 gbuf2_data  = texture(colortex2, v_uv);
    vec3 view_normal = decode_normal(gbuf2_data.rg);

    // Dither for GTAO sampling
    float dither_x = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453 + frameCounter * 0.618);
    float dither_y = fract(sin(dot(gl_FragCoord.xy, vec2(93.989, 67.345))) * 24674.5421 + frameCounter * 0.381);
    vec2 dither    = vec2(dither_x, dither_y);

    float ao = compute_ao(screen_pos, view_pos, view_normal, dither);

    ao_out = vec4(ao, 0.0, 0.0, 1.0);
}
