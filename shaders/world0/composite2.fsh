/*
================================================================================
  OffShades — world0/composite2.fsh
  Depth of Field (DOF) pass. Applies hexagonal bokeh blur around focal plane.
================================================================================
*/
#include "/include/global.glsl"

varying vec2 v_uv;
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 scene_out;

#ifdef DOF
float circle_of_confusion(float depth, float focus_depth) {
    float linear_d     = linearize_depth(depth);
    float linear_focus = linearize_depth(focus_depth);
    float sensor_mm    = 35.0;
    float f_stop       = DOF_FSTOP;
    float focal_len    = DOF_FOCAL_LENGTH;
    float f            = focal_len * 0.001; // in meters

    float coc = abs((f * f) / (f_stop * linear_focus * (1.0 - f / linear_focus)) *
                    (linear_d - linear_focus) / linear_d);

    return min(coc * 1000.0, 16.0) / min(viewWidth, viewHeight);
}

vec3 dof_blur(vec2 uv, float coc) {
    if (coc < 0.0001) return texture(colortex0, uv).rgb;

    vec3 color_sum = vec3(0.0);
    float count    = 0.0;

    // Hexagonal sampling (3 axes)
    const int SAMPLES = 12;
    for (int i = 0; i < SAMPLES; ++i) {
        float angle  = float(i) * TAU / float(SAMPLES);
        vec2  offset = vec2(cos(angle), sin(angle)) * coc;
        color_sum += texture(colortex0, uv + offset).rgb;
        count += 1.0;
    }
    return color_sum / count;
}
#endif

void main() {
    float depth  = texture(depthtex0, v_uv).r;
    vec3  scene  = texture(colortex0, v_uv).rgb;

#ifdef DOF
    // Focus on center of screen (auto-focus approximation)
    float focus_depth = texture(depthtex0, vec2(0.5)).r;
    float coc         = circle_of_confusion(depth, focus_depth);
    scene = dof_blur(v_uv, coc);
#endif

    scene_out = vec4(scene, 1.0);
}
