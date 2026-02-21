#version 330 compatibility
/*
================================================================================
  OffShades — world0/shadow.vsh
  Shadow map generation vertex shader.
================================================================================
*/
#include "/include/global.glsl"
#include "/include/surface/waving.glsl"

float get_distortion_factor(vec2 shadow_clip_pos) {
    float q = sqrt(sqrt(pow(shadow_clip_pos.x, 4.0) + pow(shadow_clip_pos.y, 4.0)));
    return q * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
}

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

varying vec2 v_uv;
varying vec4 v_color;
varying float v_entity_id;

void main() {
    v_uv       = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_color    = gl_Color;
    v_entity_id = mc_Entity.x;

    vec4 world_pos_h = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
    vec3 world_pos   = world_pos_h.xyz;

    // Waving vertex animation
    float uv_y = gl_MultiTexCoord0.y / mc_midTexCoord.y;
    world_pos += waving_offset(int(mc_Entity.x), world_pos, uv_y);

    vec4 shadow_view = shadowModelView * vec4(world_pos, 1.0);
    vec4 shadow_clip = shadowProjection * shadow_view;

    // Shadow space distortion
    float dist_f = get_distortion_factor(shadow_clip.xy);
    shadow_clip.xy /= dist_f;
    shadow_clip.z  *= SHADOW_DEPTH_SCALE;

    gl_Position = shadow_clip;
}
