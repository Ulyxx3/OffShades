#version 330 compatibility
/* OffShades — world0/gbuffers_beaconbeam.vsh — beacon beam */
#include "/include/global.glsl"
varying vec4 v_color;
void main() { v_color = gl_Color; gl_Position = ftransform(); }
