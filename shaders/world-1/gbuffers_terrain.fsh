#version 330 compatibility
/*
================================================================================
  OffShades — world-1/gbuffers_terrain.fsh
  Nether terrain fragment shader — writes gbuffer data.
================================================================================
*/
#define WORLD_NETHER
#include "/include/global.glsl"
#include "/include/utility/encoding.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

varying vec2  v_uv;
varying vec2  v_lm;
varying vec4  v_color;
varying vec3  v_normal;
varying vec3  v_tangent;
varying vec3  v_bitangent;
varying vec3  v_world_pos;

/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 gbuf0;
layout(location = 1) out vec4 gbuf1;
layout(location = 2) out vec4 gbuf2;
layout(location = 3) out vec4 gbuf3;

void main() {
    vec4 albedo = texture(gtexture, v_uv) * v_color;
    if (albedo.a < 0.1) discard;

    vec3 normal = normalize(v_normal);
#ifdef NORMAL_MAPS
    vec3 nm  = texture(normals, v_uv).xyz * 2.0 - 1.0;
    nm.z     = sqrt(max(1.0 - dot(nm.xy, nm.xy), 0.0));
    mat3 tbn = mat3(normalize(v_tangent), normalize(v_bitangent), normal);
    normal   = normalize(tbn * nm);
#endif

    vec4 spec     = vec4(0.0);
#ifdef SPECULAR_MAPS
    spec = texture(specular, v_uv);
#endif

    float skylight   = 0.0; // No sky in Nether
    float blocklight = v_lm.x;

    gbuf0 = albedo;
    gbuf1 = vec4(albedo.rgb, skylight);
    gbuf2 = vec4(encode_normal(normal), blocklight, 0.0);
    gbuf3 = vec4(max(spec.r, 0.8), spec.g, 0.04, spec.a);
}


