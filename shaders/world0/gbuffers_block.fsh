/*
================================================================================
  OffShades — world0/gbuffers_block.fsh
  Block entities fragment shader.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/utility/encoding.glsl"
uniform sampler2D gtexture;
uniform sampler2D specular;
varying vec2 v_uv;
varying vec2 v_lm;
varying vec4 v_color;
varying vec3 v_normal;
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
    vec4 spec = vec4(0.0);
#ifdef SPECULAR_MAPS
    spec = texture(specular, v_uv);
#endif
    gbuf0 = albedo;
    gbuf1 = vec4(albedo.rgb, skylight);
    gbuf2 = vec4(encode_normal(normal), blocklight, 0.0);
    gbuf3 = vec4(max(spec.r, 0.6), spec.g, 0.04, spec.a);
}
