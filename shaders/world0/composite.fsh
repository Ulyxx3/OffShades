/*
================================================================================
  OffShades — world0/composite.fsh
  Translucent blending pass: blends water/glass layers in colortex13 over
  the opaque deferred-lit scene in colortex0. Applies water SSR + refraction.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/water/water.glsl"
#include "/include/water/underwater.glsl"

varying vec2 v_uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 scene_out;

void main() {
    vec4 scene = texture(colortex0, v_uv);
    float solid_depth  = texture(depthtex0, v_uv).r;
    float transp_depth = texture(depthtex1, v_uv).r;

    // No translucent geometry here
    if (transp_depth >= solid_depth - 1e-5) {
        scene_out = scene;
        return;
    }

    // Read translucent data from colortex13
    vec4 transp_data = texture(colortex13, v_uv);

    // Water normal (stored in colortex2 for water pixels, already used in gbuffers_water)
    vec4  gbuf2     = texture(colortex2, v_uv);
    vec3  surf_normal = decode_normal(gbuf2.rg);

    // Sun/sky colors
    vec3  sun_dir_w = normalize((gbufferModelViewInverse * vec4(sun_dir, 0.0)).xyz);
    vec3  sun_color = srgb_to_linear(vec3(SUN_COLOR_R, SUN_COLOR_G, SUN_COLOR_B)) * SUN_BRIGHTNESS;
    vec3  sky_irr   = texture(colortex4, v_uv * 0.1).rgb;

    vec3  view_pos  = screen_to_view(v_uv, transp_depth);
    vec3  world_pos = view_to_scene(view_pos);

    // Detect if surface is water
    float roughness  = gbuf2.a;
    float is_water   = float(roughness < 0.1);

    if (is_water > 0.5) {
        vec3 water_result = shade_water(
            water_biome_tint(),
            world_pos,
            view_pos,
            surf_normal,
            view_sun_dir,
            sun_color,
            sky_irr,
            v_uv,
            gbuf2.b
        );

        // Blend water over scene (Fresnel alpha)
        vec3  V       = normalize(-view_pos);
        float NoV     = max(dot(surf_normal, V), 0.0);
        float alpha   = 1.0 - (1.0 - WATER_ALPHA) * pow(1.0 - NoV, 4.0);
        scene.rgb     = mix(scene.rgb, water_result, alpha);
    } else {
        // Glass or other translucent
        scene.rgb = mix(scene.rgb, transp_data.rgb, transp_data.a);
    }

    // Underwater fog
    if (isEyeInWater == 1) {
        scene.rgb = apply_underwater(
            scene.rgb,
            view_pos,
            world_pos,
            sun_dir_w,
            sun_color,
            float(eyeBrightnessSmooth.y) / 240.0
        );
    }

    scene_out = scene;
}
