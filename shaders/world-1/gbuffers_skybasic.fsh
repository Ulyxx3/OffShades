#version 330 compatibility
/* Nether proxy */ #define WORLD_NETHER
#include "/include/global.glsl"
varying vec4 v_color;
/* DRAWBUFFERS:0 */ layout(location = 0) out vec4 color_out;
void main() { 
    // Nether has no sky — output the nether sky color from the deferred pass
    color_out = vec4(0.0, 0.0, 0.0, 1.0);
}
