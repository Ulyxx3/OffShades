/*
================================================================================
  OffShades — world0/composite3.fsh
  Temporal Anti-Aliasing (TAA) pass. Blends current frame with history.
================================================================================
*/
#include "/include/global.glsl"

varying vec2 v_uv;
/* DRAWBUFFERS:05 */
layout(location = 0) out vec4 scene_out;
layout(location = 1) out vec4 taa_history; // colortex5

#ifdef TAA
// Clamp box: constrain history to neighbourhood of current sample
vec3 neighbourhood_clamp(vec3 history, vec2 uv) {
    vec3 c_min = vec3(1e10);
    vec3 c_max = vec3(-1e10);
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec3 n = texture(colortex0, uv + vec2(x, y) * view_pixel_size).rgb;
            c_min = min(c_min, n);
            c_max = max(c_max, n);
        }
    }
    return clamp(history, c_min, c_max);
}
#endif

void main() {
    vec3 current = texture(colortex0, v_uv).rgb;

#ifdef TAA
    float depth   = texture(depthtex0, v_uv).r;
    vec3  scene_p = screen_to_scene(v_uv, depth);
    vec2  prev_uv = reproject_uv(scene_p);

    bool valid = prev_uv.x >= 0.0 && prev_uv.x <= 1.0 &&
                 prev_uv.y >= 0.0 && prev_uv.y <= 1.0;

    if (valid) {
        vec3 history = texture(colortex5, prev_uv).rgb;
        history      = neighbourhood_clamp(history, v_uv);
        current      = mix(current, history, 0.9);
    }
#endif

    scene_out   = vec4(current, 1.0);
    taa_history = vec4(current, 1.0);
}
