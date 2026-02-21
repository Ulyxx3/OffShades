#version 330 compatibility
/* OffShades — world1/gbuffers_skybasic.fsh — End proxy */
/* Outputs black; End sky is drawn in deferred.fsh */
#define WORLD_END
#include "/include/global.glsl"
varying vec4 v_color;
/* DRAWBUFFERS:0 */ layout(location = 0) out vec4 color_out;
void main() { color_out = vec4(0.0, 0.0, 0.0, 1.0); }
