#version 330 compatibility
/*
================================================================================
  OffShades — world0/deferred4.fsh
  MAIN DEFERRED SHADING PASS.
  Reads all gbuffer data (albedo, normals, specular, lightmap) and applies:
    - PCSS shadows from Photon
    - ambient occlusion (from colortex6)
    - PBR lighting (from include/lighting/lighting.glsl)
    - sky/indirect irradiance (from colortex4)
  Writes final HDR scene color to colortex0.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/depth.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/color.glsl"
#include "/include/lighting/lighting.glsl"

varying vec2 v_uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 scene_color;

void main() {
    float depth = texture(depthtex0, v_uv).r;

    // Sky pixels already have correct color from deferred.fsh
    if (is_sky(depth)) {
        scene_color = texture(colortex0, v_uv);
        return;
    }

    // Read gbuffer data
    vec4  gbuf0_data  = texture(colortex0, v_uv); // scene color slot (pre-lit albedo)
    vec4  gbuf1_data  = texture(colortex1, v_uv); // albedo + skylight
    vec4  gbuf2_data  = texture(colortex2, v_uv); // normal xy + blocklight + material id
    vec4  gbuf3_data  = texture(colortex3, v_uv); // roughness, metalness, f0, emissive

    vec3  albedo      = gbuf1_data.rgb;
    float skylight    = gbuf1_data.a;
    vec3  view_normal = decode_normal(gbuf2_data.rg);
    float blocklight  = gbuf2_data.b;
    float roughness   = gbuf3_data.r;
    float metalness   = gbuf3_data.g;
    float f0_val      = gbuf3_data.b;
    float emissive    = gbuf3_data.a;

    vec3  view_pos    = screen_to_view(v_uv, depth);
    vec3  scene_pos   = view_to_scene(view_pos);
    vec3  screen_pos  = vec3(v_uv, depth);

    // Flat normal from geometry — decoded separately (stored in same slot via blend)
    // For simplicity, use view_normal as flat normal too (minor approximation)
    vec3  flat_normal = view_normal;

    // F0 from metalness/specular
    vec3  f0          = mix(vec3(f0_val > 0.0 ? f0_val : 0.04), albedo, metalness);

    // SSS
    float sss_amount  = 0.0; // TODO: read from material ID
    vec3  sss_color   = albedo;

    // Cloud shadow (from cloud transmittance stored in colortex9)
    float cloud_shadow = 1.0;
#ifdef CLOUDS_CUMULUS
    cloud_shadow = texture(colortex9, v_uv).a;
#endif

    // AO
    float ao_val = texture(colortex6, v_uv).r;

    // AO dither for GTAO (dummy here — AO is already computed)
    vec2 ao_dither = vec2(0.5);

    LightingResult lit = compute_lighting(
        scene_pos,
        view_normal,
        flat_normal,
        albedo,
        f0,
        roughness,
        metalness,
        emissive,
        skylight,
        blocklight,
        sss_amount,
        sss_color,
        cloud_shadow,
        ao_dither,
        screen_pos,
        view_pos,
        colortex4  // sky irradiance map
    );

    // Override AO from precomputed AO pass
    // (lighting.glsl computes its own AO but we prefer the deferred3 GTAO result)
    lit.color *= ao_val;
    lit.color /= max(compute_ao(screen_pos, view_pos, view_normal, ao_dither), 0.01); // undo internal AO
    lit.color *= ao_val; // apply GTAO result

    scene_color = vec4(lit.color, 1.0);
}
