#version 330 compatibility
/*
================================================================================
  OffShades — world0/deferred.fsh
  Sky rendering pass: writes procedural sky + stars to colortex0 where sky
  depth is 1.0 (no geometry). Also computes sky irradiance map into colortex4.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/depth.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/sky/stars.glsl"
#include "/include/sky/clouds.glsl"

varying vec2 v_uv;

/* DRAWBUFFERS:04 */
layout(location = 0) out vec4 scene_color;
layout(location = 1) out vec4 sky_map_out;

void main() {
    float depth = texture(depthtex0, v_uv).r;

    // View direction in world space
    vec3 view_pos = screen_to_view(v_uv, depth < 1.0 ? 0.9999 : depth);
    vec3 world_dir = normalize((gbufferModelViewInverse * vec4(view_pos, 0.0)).xyz);

    vec3 sun_dir_w  = normalize((gbufferModelViewInverse * vec4(sun_dir, 0.0)).xyz);
    vec3 moon_dir_w = normalize((gbufferModelViewInverse * vec4(moon_dir, 0.0)).xyz);

    // Night factor
    float night_factor = 1.0 - smoothstep(-0.1, 0.15, sun_dir_w.y);

    if (depth < 1.0 - 1e-5) {
        // Geometry pixel — don't overwrite
        scene_color = texture(colortex0, v_uv);
    } else {
        // Sky pixel — compute atmosphere
        vec3 sky = sky_color(world_dir, sun_dir_w, moon_dir_w);
        sky += render_stars(world_dir, night_factor);

        // Clouds
        CloudResult clouds = render_clouds(
            cameraPosition,
            world_dir,
            sun_dir_w,
            sun_color(sun_dir_w)
        );
#ifdef CLOUDS_CUMULUS
        sky = sky * clouds.cumulus.a + clouds.cumulus.rgb;
#endif
#ifdef CLOUDS_CIRRUS
        vec3 cirrus_color = vec3(0.9, 0.95, 1.0) * mix(1.0, 0.6, night_factor);
        sky = mix(sky, cirrus_color, clouds.cirrus * 0.8);
#endif

        scene_color = vec4(sky, 1.0);
    }

    // Sky irradiance map (equirectangular, low-res colortex4)
    // Write the sky hemisphere color for ambient lighting lookups
    {
        vec3 n;
        n.x = sin(v_uv.y * PI) * cos(v_uv.x * TAU);
        n.z = sin(v_uv.y * PI) * sin(v_uv.x * TAU);
        n.y = cos(v_uv.y * PI);
        vec3 irr = sky_color(n, sun_dir_w, moon_dir_w) * 0.1;
        sky_map_out = vec4(irr, 1.0);
    }
}
