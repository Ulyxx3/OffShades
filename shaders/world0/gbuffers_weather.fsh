#version 330 compatibility
/*
================================================================================
  OffShades — world0/gbuffers_weather.fsh
  Rain/snow particle fragment shader.
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
    // Weather uses compositing pass — just output to colortex0
    col.rgb *= 0.9;
    color_out = col;
}
