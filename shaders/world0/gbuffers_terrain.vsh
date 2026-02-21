#version 330 compatibility
/*
================================================================================
  OffShades — world0/gbuffers_terrain.vsh
  Main terrain geometry vertex shader. Handles POM, waving, normal mapping.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/surface/waving.glsl"

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;
attribute vec4 at_tangent;

varying vec2  v_uv;
varying vec2  v_lm;
varying vec4  v_color;
varying vec3  v_normal;
varying vec3  v_tangent;
varying vec3  v_bitangent;
varying vec3  v_world_pos;
varying float v_entity_id;

void main() {
    v_uv        = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_lm        = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    v_color     = gl_Color;
    v_entity_id = mc_Entity.x;

    // Normal/tangent in view space
    v_normal    = normalize(gl_NormalMatrix * gl_Normal);
    v_tangent   = normalize(gl_NormalMatrix * at_tangent.xyz);
    v_bitangent = cross(v_normal, v_tangent) * sign(at_tangent.w);

    // World position
    vec4 model_pos   = gl_ModelViewMatrix * gl_Vertex;
    vec4 world_pos_h = gbufferModelViewInverse * model_pos;
    v_world_pos      = world_pos_h.xyz;

    // Waving animation
    float uv_y   = gl_MultiTexCoord0.y / mc_midTexCoord.y;
    v_world_pos += waving_offset(int(mc_Entity.x), v_world_pos, uv_y);

    vec4 view_pos   = gbufferModelView * vec4(v_world_pos, 1.0);
    gl_Position     = gbufferProjection * view_pos;

    // TAA jitter
    gl_Position.xy += taa_offset * gl_Position.w;
}


