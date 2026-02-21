#version 330 compatibility
/*
================================================================================
  OffShades — world1/deferred.fsh
  The End main deferred pass.
  - Draws the End sky (void gradient + purple + End stars + End sun)
  - Shades solid geometry using End ambient (no directional sun, no shadow map)
  - Uses include/misc/end.glsl for all End-specific visuals
================================================================================
*/
#define WORLD_END
#include "/include/global.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/depth.glsl"
#include "/include/misc/end.glsl"

varying vec2 v_uv;
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 scene_out;

void main() {
    float depth = texture(depthtex0, v_uv).r;

    // End sky: void gradient + procedural star field + End sun patch
    if (is_sky(depth)) {
        vec3 view_pos  = screen_to_view(v_uv, 0.9999);
        vec3 world_dir = normalize((gbufferModelViewInverse * vec4(view_pos, 0.0)).xyz);
        scene_out = vec4(end_sky(world_dir), 1.0);
        return;
    }

    // Read gbuffer data
    vec4  gbuf1 = texture(colortex1, v_uv); // albedo + skylight(unused in End)
    vec4  gbuf2 = texture(colortex2, v_uv); // normal + blocklight
    vec4  gbuf3 = texture(colortex3, v_uv); // roughness, metalness, f0, emissive

    vec3  albedo     = gbuf1.rgb;
    float blocklight = gbuf2.b;
    vec3  view_normal = decode_normal(gbuf2.rg);
    float emissive   = gbuf3.a;

    scene_out = vec4(end_shade(albedo, view_normal, emissive, blocklight), 1.0);
}


