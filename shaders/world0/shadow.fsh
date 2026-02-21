#version 330 compatibility
/*
================================================================================
  OffShades — world0/shadow.fsh
  Shadow map generation fragment shader.
================================================================================
*/
#include "/include/global.glsl"

varying vec2  v_uv;
varying vec4  v_color;
varying float v_entity_id;

uniform sampler2D gtexture;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 shadow_out;

void main() {
    vec4 albedo = texture(gtexture, v_uv) * v_color;

    // Alpha-test for geometry
    if (albedo.a < 0.1) discard;

    // Colored translucent shadows (tint stored in shadowcolor0)
    shadow_out = albedo;
}


