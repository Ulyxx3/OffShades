#version 330 compatibility
/* OffShades — world1/gbuffers_basic.fsh — End proxy */
#define WORLD_END
#include "/include/global.glsl"
varying vec4 v_color;
/* DRAWBUFFERS:0 */ layout(location = 0) out vec4 color_out;
void main() { color_out = v_color; }
