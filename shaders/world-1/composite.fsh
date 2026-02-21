#version 330 compatibility
/*
================================================================================
  OffShades — world-1/composite.fsh
  Nether composite pass: applies Nether distance fog, lava glow effects,
  and the same composite chain as overworld (reusing helpers from fog.glsl).
================================================================================
*/
#define WORLD_NETHER
#include "/include/global.glsl"
#include "/include/utility/depth.glsl"
#include "/include/misc/nether.glsl"
#include "/include/post/tonemap.glsl"
#include "/include/post/bloom.glsl"

varying vec2 v_uv;
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 scene_out;

void main() {
    vec3 scene = texture(colortex0, v_uv).rgb;
    float depth = texture(depthtex0, v_uv).r;

    vec3 view_pos  = screen_to_view(v_uv, depth);
    float view_dist = length(view_pos);

    // Apply Nether fog
    scene = apply_nether_fog(scene, view_dist);

    // Bloom
#ifdef BLOOM
    vec3 bloom_color = texture(colortex11, v_uv).rgb;
    scene = apply_bloom(scene, bloom_color);
#endif

    // Exposure + tonemap
    scene *= EXPOSURE;
    scene = apply_tonemap(scene, 0.0);
    scene = linear_to_srgb(scene);

    scene_out = vec4(scene, 1.0);
}
