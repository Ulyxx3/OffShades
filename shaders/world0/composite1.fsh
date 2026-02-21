#version 330 compatibility
/*
================================================================================
  OffShades — world0/composite1.fsh
  Volumetric fog / light shaft pass. Reads fog result from include/fog/fog.glsl.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/depth.glsl"
#include "/include/fog/fog.glsl"

varying vec2 v_uv;
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 scene_out;

void main() {
    vec3 scene = texture(colortex0, v_uv).rgb;
    float depth = texture(depthtex0, v_uv).r;

    vec3 view_pos   = screen_to_view(v_uv, depth);
    vec3 scene_pos  = view_to_scene(view_pos);
    float view_dist = length(view_pos);

    vec3 world_dir  = normalize(scene_pos - vec3(0.0)); // camera-relative

    vec3 sun_dir_w  = normalize((gbufferModelViewInverse * vec4(sun_dir, 0.0)).xyz);
    vec3 sun_color  = sun_color(sun_dir_w);
    vec3 sky_irr    = texture(colortex4, v_uv).rgb;

    float skylight  = float(eyeBrightnessSmooth.y) / 240.0;
    float cloud_shadow = texture(colortex9, v_uv).a;

    scene = apply_overworld_fog(
        scene,
        cameraPosition,
        normalize(view_pos),
        view_dist,
        sun_dir_w,
        sky_irr,
        sun_color,
        cloud_shadow,
        skylight
    );

    scene_out = vec4(scene, 1.0);
}
