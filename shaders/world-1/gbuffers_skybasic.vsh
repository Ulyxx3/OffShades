/* Nether proxy */ #define WORLD_NETHER
#include "/include/global.glsl"
varying vec4 v_color;
void main() { v_color = gl_Color; gl_Position = ftransform(); }
