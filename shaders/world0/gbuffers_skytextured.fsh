#version 330 compatibility
/*
================================================================================
  OffShades — world0/gbuffers_skytextured.fsh
  Vanilla sky textured (sun/moon quads) fragment shader.
  Since the deferred pass draws the real procedural sky, we discard these
  vanilla quads and let the deferred atmosphere handle sun/moon rendering.
================================================================================
*/
#include "/include/global.glsl"
uniform sampler2D gtexture;
varying vec2 v_uv;
varying vec4 v_color;
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 color_out;
void main() {
    // Discard vanilla sun/moon quads — atmosphere.glsl renders them procedurally
    discard;
}


