#version 330 compatibility
/*
================================================================================
  OffShades — world0/gbuffers_water.fsh
  Water surface fragment shader: outputs gbuffer data + wave normal.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/water/water.glsl"

uniform sampler2D gtexture;

varying vec2  v_uv;
varying vec2  v_lm;
varying vec4  v_color;
varying vec3  v_normal;
varying vec3  v_tangent;
varying vec3  v_bitangent;
varying vec3  v_world_pos;
varying float v_is_water;

/* DRAWBUFFERS:712 */
layout(location = 0) out vec4 gbuf0; // scene color -> colortex7 (translucent map)
layout(location = 1) out vec4 gbuf1; // albedo + skylight -> colortex1
layout(location = 2) out vec4 gbuf2; // normal + lightmap -> colortex2

void main() {
    vec4 base = texture(gtexture, v_uv) * v_color;

    vec3 normal;
    float roughness;

    if (v_is_water > 0.5) {
        // Animated water normals
        vec3 wave_n = water_wave_normal(v_world_pos.xz + cameraPosition.xz, frameTimeCounter);
        // Transform to view space
        mat3 tbn    = mat3(normalize(v_tangent), normalize(v_bitangent), normalize(v_normal));
        normal      = normalize(tbn * wave_n);
        roughness   = WATER_ROUGHNESS;

        // Water color = biome tint
        base.rgb = water_biome_tint();
        base.a   = WATER_ALPHA;
    } else {
        // Glass or other translucent
        normal    = normalize(v_normal);
        roughness = 0.5;
    }

    float skylight   = v_lm.y;
    float blocklight = v_lm.x;

    gbuf0 = vec4(base.rgb, base.a);
    gbuf1 = vec4(base.rgb, skylight);
    gbuf2 = vec4(encode_normal(normal), blocklight, roughness);
}



