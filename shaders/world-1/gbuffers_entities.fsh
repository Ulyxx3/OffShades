#version 330 compatibility
/* OffShades — world-1/gbuffers_entities.fsh — Nether proxy */
#define WORLD_NETHER
#include "/include/global.glsl"
#include "/include/utility/encoding.glsl"
uniform sampler2D gtexture; uniform sampler2D specular;
varying vec2 v_uv; varying vec2 v_lm; varying vec4 v_color; varying vec3 v_normal; varying vec3 v_world_pos;
/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 gbuf0; layout(location = 1) out vec4 gbuf1;
layout(location = 2) out vec4 gbuf2; layout(location = 3) out vec4 gbuf3;
void main() {
    vec4 albedo = texture(gtexture, v_uv) * v_color; if (albedo.a < 0.1) discard;
    vec3 normal = normalize(v_normal);
    float blocklight = v_lm.x;
    vec4 spec = vec4(0.0); 
#ifdef SPECULAR_MAPS
    spec = texture(specular, v_uv);
#endif
    gbuf0 = albedo; gbuf1 = vec4(albedo.rgb, 0.0); // no sky in Nether
    gbuf2 = vec4(encode_normal(normal), blocklight, 0.0);
    gbuf3 = vec4(max(spec.r, 0.7), spec.g, 0.04, spec.a);
}


