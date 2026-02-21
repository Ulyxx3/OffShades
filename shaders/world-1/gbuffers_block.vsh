#version 330 compatibility
/* Nether proxy */ #define WORLD_NETHER
#include "/include/global.glsl"
attribute vec4 at_tangent;
varying vec2 v_uv; varying vec2 v_lm; varying vec4 v_color; varying vec3 v_normal;
void main() {
    v_uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_lm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    v_color = gl_Color; v_normal = normalize(gl_NormalMatrix * gl_Normal);
    gl_Position = ftransform(); gl_Position.xy += taa_offset * gl_Position.w;
}


