/* Nether proxy */ #define WORLD_NETHER
#include "/include/global.glsl"
varying vec4 v_color;
/* DRAWBUFFERS:0 */ layout(location = 0) out vec4 color_out;
void main() { color_out = v_color; }
