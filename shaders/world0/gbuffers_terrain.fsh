#version 330 compatibility
/*
================================================================================
  OffShades — world0/gbuffers_terrain.fsh
  Main terrain fragment shader: writes to gbuffer (albedo, normal, specular).
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/encoding.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;       // normal map (if NORMAL_MAPS enabled)
uniform sampler2D specular;      // specular map

varying vec2  v_uv;
varying vec2  v_lm;
varying vec4  v_color;
varying vec3  v_normal;
varying vec3  v_tangent;
varying vec3  v_bitangent;
varying vec3  v_world_pos;
varying float v_entity_id;

/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 gbuf0; // albedo + alpha
layout(location = 1) out vec4 gbuf1; // albedo (for lightmap), AO
layout(location = 2) out vec4 gbuf2; // normal + material ID
layout(location = 3) out vec4 gbuf3; // roughness, metalness, f0, emissive

void main() {
    vec4 albedo = texture(gtexture, v_uv) * v_color;
    if (albedo.a < 0.1) discard;

    // Normal mapping
    vec3 geo_normal = normalize(v_normal);
#ifdef NORMAL_MAPS
    vec3 normal_map = texture(normals, v_uv).xyz * 2.0 - 1.0;
    normal_map.z    = sqrt(max(1.0 - dot(normal_map.xy, normal_map.xy), 0.0));
    mat3 tbn        = mat3(normalize(v_tangent), normalize(v_bitangent), geo_normal);
    vec3 normal     = normalize(tbn * normal_map);
#else
    vec3 normal = geo_normal;
#endif

    // Specular map (PBR spec/gloss pipeline)
    vec4 spec_data = vec4(0.0);
#ifdef SPECULAR_MAPS
    spec_data = texture(specular, v_uv);
#endif
    // Standard LabPBR: R=roughness, G=metalness, B=f0, A=emissive
    float roughness = spec_data.r > 0.0 ? spec_data.r : 1.0;
    float metalness = spec_data.g;
    float f0        = spec_data.b;
    float emissive  = spec_data.a;

    // Lightmap
    float skylight   = v_lm.y;
    float blocklight = v_lm.x;

    // Encode and write gbuffers
    gbuf0 = albedo;
    gbuf1 = vec4(albedo.rgb, skylight);          // albedo for ambient + skylight
    gbuf2 = vec4(encode_normal(normal), blocklight, float(v_entity_id) / 65536.0);
    gbuf3 = vec4(roughness, metalness, f0, emissive);
}


