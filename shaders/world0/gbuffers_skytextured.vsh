#version 330 compatibility
/*
================================================================================
  OffShades — world0/gbuffers_skytextured.vsh
  Textured vanilla sky elements (sun/moon texture quad) vertex shader.
================================================================================
*/
#include "/include/global.glsl"
varying vec2 v_uv;
varying vec4 v_color;
void main() {
    v_uv    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_color = gl_Color;
    gl_Position = ftransform();
}


