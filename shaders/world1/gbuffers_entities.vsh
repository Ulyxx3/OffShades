#version 330 compatibility
/* OffShades — world1/gbuffers_entities.vsh — End proxy */
#define WORLD_END
#include "/include/global.glsl"
attribute vec4 mc_Entity;
varying vec2 v_uv; varying vec2 v_lm; varying vec4 v_color; varying vec3 v_normal; varying vec3 v_world_pos;
uniform float entityColor;
void main() {
    v_uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_lm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    v_color = mix(gl_Color, vec4(1.0, 0.0, 0.0, 1.0), entityColor);
    vec4 wph = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
    v_world_pos = wph.xyz;
    v_normal = normalize(gl_NormalMatrix * gl_Normal);
    gl_Position = ftransform(); gl_Position.xy += taa_offset * gl_Position.w;
}
