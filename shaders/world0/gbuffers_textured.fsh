#version 330 compatibility
/*
================================================================================
  OffShades — world0/gbuffers_textured.fsh
  Particles, 2D quads fragment shader.
================================================================================
*/
#include "/include/global.glsl"
uniform sampler2D gtexture;
varying vec2 v_uv;
varying vec4 v_color;
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 color_out;
void main() {
    vec4 col = texture(gtexture, v_uv) * v_color;
    if (col.a < 0.05) discard;
    color_out = col;
}
