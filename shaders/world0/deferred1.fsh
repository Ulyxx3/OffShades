#version 330 compatibility
/*
================================================================================
  OffShades — world0/deferred1.fsh
  Volumetric cloud raymarching pass (writes cloud color to colortex9).
  For performance, clouds are rendered at half resolution and upscaled.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/depth.glsl"
#include "/include/sky/clouds.glsl"

varying vec2 v_uv;

/* DRAWBUFFERS:9 */
layout(location = 0) out vec4 cloud_out; // colortex9

void main() {
    vec3 sun_dir_w  = normalize((gbufferModelViewInverse * vec4(sun_dir, 0.0)).xyz);
    vec3 sun_color  = sun_color(sun_dir_w);

    // Reconstruct view direction
    vec3 view_pos   = screen_to_view(v_uv, 0.9999);
    vec3 world_dir  = normalize((gbufferModelViewInverse * vec4(view_pos, 0.0)).xyz);

    // Skip cloud computation if looking down
    if (world_dir.y < -0.05) {
        cloud_out = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    CloudResult clouds = render_clouds(
        cameraPosition,
        world_dir,
        sun_dir_w,
        sun_color
    );

    // Store cumulus scatter + transmittance (cirrus handled in composite)
    cloud_out = clouds.cumulus;
}


