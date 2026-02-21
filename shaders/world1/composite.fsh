/*
================================================================================
  OffShades — world1/composite.fsh
  End composite pass: applies End distance fog (void fade), bloom, and tonemap.
================================================================================
*/
#define WORLD_END
#include "/include/global.glsl"
#include "/include/misc/end.glsl"
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
    vec3 world_dir  = normalize((gbufferModelViewInverse * vec4(view_pos, 0.0)).xyz);

    // Apply End fog (void fade, purple distance fog)
    scene = apply_end_fog(scene, world_dir, view_dist);

    // Bloom
#ifdef BLOOM
    vec3 bloom_color = texture(colortex11, v_uv).rgb;
    scene = apply_bloom(scene, bloom_color);
#endif

    // Exposure + tonemap
    scene *= EXPOSURE;
    scene  = apply_tonemap(scene, 0.0);
    scene  = linear_to_srgb(scene);

    scene_out = vec4(scene, 1.0);
}
