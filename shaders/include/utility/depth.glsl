/*
================================================================================
  OffShades — include/utility/depth.glsl
  Depth linearization, view-space position reconstruction, reprojection.
================================================================================
*/

#ifndef DEPTH_INCLUDED
#define DEPTH_INCLUDED

// Linearize a depth buffer value to a linear (0=near, far) value
float linearize_depth(float depth) {
    return (2.0 * near * far) / (far + near - depth * (far - near));
}

// Linearize depth in [0,1] normalized range
float linearize_depth_01(float depth) {
    return linearize_depth(depth * 2.0 - 1.0) / far;
}

// Reconstruct view-space position from screen UV + depth
vec3 screen_to_view(vec2 uv, float depth) {
    vec4 clip = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * clip;
    return view.xyz / view.w;
}

// Reconstruct world-space (scene) position from view-space position
vec3 view_to_scene(vec3 view_pos) {
    return (gbufferModelViewInverse * vec4(view_pos, 1.0)).xyz;
}

// Combined: screen → scene position
vec3 screen_to_scene(vec2 uv, float depth) {
    return view_to_scene(screen_to_view(uv, depth));
}

// Project a scene-space position to clip space (for reprojection)
vec4 scene_to_clip(vec3 scene_pos) {
    vec4 view = gbufferModelView * vec4(scene_pos, 1.0);
    return gbufferProjection * view;
}

// Compute previous-frame screen UV from current scene position (for TAA/reprojection)
vec2 reproject_uv(vec3 scene_pos) {
    vec4 prev_view = gbufferPreviousModelView * vec4(scene_pos + cameraPosition - previousCameraPosition, 1.0);
    vec4 prev_clip = gbufferPreviousProjection * prev_view;
    return prev_clip.xy / prev_clip.w * 0.5 + 0.5;
}

// Depth comparison helpers
bool is_hand(float depth) {
    return depth < 0.56; // hand depth threshold (matches Iris/OptiFine convention)
}

bool is_sky(float depth) {
    return depth >= 1.0 - 1e-5;
}

// Shadow projection helpers
vec3 project_ortho(mat4 p, vec3 v) {
    return vec3(p[0].x * v.x + p[3].x,
                p[1].y * v.y + p[3].y,
                p[2].z * v.z + p[3].z);
}

vec3 transform(mat4 m, vec3 v) {
    return (m * vec4(v, 1.0)).xyz;
}

#endif // DEPTH_INCLUDED
