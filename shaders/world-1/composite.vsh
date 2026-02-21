#version 330 compatibility
/* OffShades — world-1/composite.vsh */
#define WORLD_NETHER
#include "/include/global.glsl"
varying vec2 v_uv;
void main() { gl_Position = vec4(gl_Vertex.xy*2.0-1.0,0.0,1.0); v_uv=gl_Vertex.xy; }
