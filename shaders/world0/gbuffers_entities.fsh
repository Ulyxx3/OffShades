/*
================================================================================
  OffShades — world0/gbuffers_entities.fsh
  Entity fragment shader: writes to gbuffer.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/encoding.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

varying vec2  v_uv;
varying vec2  v_lm;
varying vec4  v_color;
varying vec3  v_normal;
varying vec3  v_world_pos;

/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 gbuf0;
layout(location = 1) out vec4 gbuf1;
layout(location = 2) out vec4 gbuf2;
layout(location = 3) out vec4 gbuf3;

void main() {
    vec4 albedo = texture(gtexture, v_uv) * v_color;
    if (albedo.a < 0.1) discard;

    vec3  normal     = normalize(v_normal);
    float skylight   = v_lm.y;
    float blocklight = v_lm.x;

    vec4 spec_data  = vec4(0.0);
#ifdef SPECULAR_MAPS
    spec_data = texture(specular, v_uv);
#endif
    float roughness = max(spec_data.r, 0.7); // entities typically not very shiny
    float metalness = spec_data.g;
    float emissive  = spec_data.a;

    gbuf0 = albedo;
    gbuf1 = vec4(albedo.rgb, skylight);
    gbuf2 = vec4(encode_normal(normal), blocklight, 0.0);
    gbuf3 = vec4(roughness, metalness, 0.04, emissive);
}
