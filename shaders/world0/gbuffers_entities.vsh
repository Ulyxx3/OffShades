#version 330 compatibility
/*
================================================================================
  OffShades — world0/gbuffers_entities.vsh
  Entity geometry (mobs, items, armor stands) vertex shader.
================================================================================
*/
#include "/include/global.glsl"

attribute vec4 mc_Entity;
attribute vec4 at_tangent;

varying vec2  v_uv;
varying vec2  v_lm;
varying vec4  v_color;
varying vec3  v_normal;
varying vec3  v_world_pos;

uniform vec4 entityColor; // damage flash tint

void main() {
    v_uv      = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_lm      = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    // Damage flash: blend with red
    v_color   = mix(gl_Color, vec4(entityColor.rgb, gl_Color.a), entityColor.a);

    vec4 world_pos_h = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
    v_world_pos      = world_pos_h.xyz;
    v_normal         = normalize(gl_NormalMatrix * gl_Normal);

    gl_Position = ftransform();
    gl_Position.xy += taa_offset * gl_Position.w;
}
