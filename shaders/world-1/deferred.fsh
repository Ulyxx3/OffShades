#version 330 compatibility
/*
================================================================================
  OffShades — world-1/deferred.fsh
  Nether main deferred pass. No sky, no shadow map sun. Uses Nether fog and
  Nether ambient light instead. Applies blocklight + emissive shading.
================================================================================
*/
#define WORLD_NETHER
#include "/include/global.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/depth.glsl"
#include "/include/misc/nether.glsl"

varying vec2 v_uv;
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 scene_out;

void main() {
    float depth = texture(depthtex0, v_uv).r;

    // Sky/ceiling in Nether
    if (is_sky(depth)) {
        vec3 view_pos   = screen_to_view(v_uv, 0.9999);
        vec3 world_dir  = normalize((gbufferModelViewInverse * vec4(view_pos, 0.0)).xyz);
        scene_out = vec4(nether_sky(world_dir), 1.0);
        return;
    }

    // Read gbuffer
    vec4 gbuf1 = texture(colortex1, v_uv);
    vec4 gbuf2 = texture(colortex2, v_uv);
    vec4 gbuf3 = texture(colortex3, v_uv);

    vec3  albedo     = gbuf1.rgb;
    float blocklight = gbuf2.b;
    float emissive   = gbuf3.a;

    vec3 color = nether_shade(albedo, emissive, blocklight);

    scene_out = vec4(color, 1.0);
}
