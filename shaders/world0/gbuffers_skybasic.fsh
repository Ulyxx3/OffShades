#version 330 compatibility
/*
================================================================================
  OffShades — world0/gbuffers_skybasic.fsh
  The deferred pass draws the real sky. This just clears the sky buffer
  to a neutral color so the depth is set correctly.
================================================================================
*/
#include "/include/global.glsl"
varying vec4 v_color;
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 color_out;
void main() {
    // Output sky blue as a placeholder; deferred.fsh overwrites this.
    color_out = vec4(0.0, 0.0, 0.0, 1.0);
}


