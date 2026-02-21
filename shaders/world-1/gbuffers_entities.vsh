#version 330 compatibility
/* OffShades — world-1/gbuffers_entities.vsh — Nether proxy */
#define WORLD_NETHER
#include "/include/global.glsl"

attribute vec4 mc_Entity;

varying vec2 v_uv;
varying vec2 v_lm;
varying vec4 v_color;
varying vec3 v_normal;
varying vec3 v_world_pos;

uniform vec4 entityColor;

void main() {
    v_uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_lm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    v_color = mix(gl_Color, vec4(entityColor.rgb, gl_Color.a), entityColor.a);
    vec4 wph = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
    v_world_pos = wph.xyz;
    v_normal = normalize(gl_NormalMatrix * gl_Normal);
    // No TAA jitter in Nether (skylight = 0 anyway)
    gl_Position = ftransform();
}
