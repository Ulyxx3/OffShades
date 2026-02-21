/*
================================================================================
  OffShades — include/lighting/ao.glsl
  GTAO (Ground Truth Ambient Occlusion) + SSAO fallback.
  Adapted from Photon Shaders by Sixthsurge.
================================================================================
*/

#ifndef AO_INCLUDED
#define AO_INCLUDED

#include "/include/utility/math.glsl"
#include "/include/utility/depth.glsl"

// ─── SSAO (Screen-Space Ambient Occlusion) ───────────────────────────────────
// Simple hemisphere sampling SSAO
float compute_ssao(vec3 screen_pos, vec3 view_pos, vec3 view_normal, float dither) {
    const int  SSAO_SAMPLES = 8;
    const float ssao_radius = SHADER_AO_RADIUS;

    float ao        = 0.0;
    float total     = 0.0;

    // Build a TBN basis around the normal
    vec3 up    = abs(view_normal.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent   = normalize(cross(up, view_normal));
    vec3 bitangent = cross(view_normal, tangent);

    for (int i = 0; i < SSAO_SAMPLES; ++i) {
        // Generate sample direction in hemisphere
        float fi    = float(i) + dither;
        float theta = TAU * fi * 0.38196601125; // golden angle
        float phi   = acos(1.0 - 2.0 * (fi + 0.5) / float(SSAO_SAMPLES));

        vec3 sample_dir = vec3(sin(phi) * cos(theta),
                                sin(phi) * sin(theta),
                                cos(phi));
        // Rotate into tangent space
        vec3 sample_view = tangent * sample_dir.x + bitangent * sample_dir.y + view_normal * sample_dir.z;

        float scale = mix(0.1, 1.0, float(i + 1) / float(SSAO_SAMPLES));
        vec3  sample_pos = view_pos + sample_view * ssao_radius * scale;

        // Project to screen
        vec4 clip_pos     = gbufferProjection * vec4(sample_pos, 1.0);
        vec3 sample_screen = clip_pos.xyz / clip_pos.w * 0.5 + 0.5;

        if (sample_screen.x < 0.0 || sample_screen.x > 1.0 ||
            sample_screen.y < 0.0 || sample_screen.y > 1.0) continue;

        float depth       = texture(depthtex0, sample_screen.xy).r;
        vec3  real_pos    = screen_to_view(sample_screen.xy, depth);
        float range_check = smoothstep(0.0, 1.0, ssao_radius / abs(view_pos.z - real_pos.z));

        ao    += range_check * step(real_pos.z, sample_pos.z - 0.015);
        total += 1.0;
    }

    return (total > 0.0) ? 1.0 - (ao / total) : 1.0;
}

// ─── GTAO (Ground Truth Ambient Occlusion) ───────────────────────────────────
// Horizon-based AO with bent normals. Adapted from Photon.
float fast_acos(float x) {
    // Polynomial approximation of acos (Lagrange)
    float nabs = abs(x);
    float y    = (-0.0187293 * nabs + 0.0742610) * nabs;
    y = (y - 0.2121144) * nabs + 1.5707288;
    y = y * sqrt(1.0 - nabs);
    return (x < 0.0) ? PI - y : y;
}

float integrate_arc(vec2 h, float n, float cos_n) {
    vec2 tmp = cos_n + 2.0 * h * sin(n) - cos(2.0 * h - n);
    return 0.25 * (tmp.x + tmp.y);
}

float compute_horizon_angle(
    vec3 view_slice_dir, vec3 viewer_dir,
    vec3 screen_pos, vec3 view_pos,
    float radius, float dither
) {
    int steps = GTAO_HORIZON_STEPS;
    float step_size = (GTAO_RADIUS / float(steps)) * radius;

    // Compute screen-space step via small offset in view space
    vec4 clip_next = gbufferProjection * vec4(view_pos + view_slice_dir * step_size, 1.0);
    vec2 screen_next = clip_next.xy / clip_next.w * 0.5 + 0.5;
    vec2 ray_step = screen_next - screen_pos.xy;

    float max_cos_theta = -1.0;
    vec2  ray_pos = screen_pos.xy + ray_step * (dither + view_pixel_size.x / max(abs(ray_step.x), abs(ray_step.y)));

    for (int i = 0; i < steps; ++i, ray_pos += ray_step) {
        if (ray_pos.x < 0.0 || ray_pos.x > 1.0 || ray_pos.y < 0.0 || ray_pos.y > 1.0) break;

        float depth = textureLod(depthtex0, ray_pos, 0.0).x;
        if (depth >= 1.0) continue;

        vec3 offset = screen_to_view(ray_pos, depth) - view_pos;
        float len_sq = dot(offset, offset);
        float norm   = inversesqrt(len_sq);

        float falloff   = clamp((len_sq * norm / radius - GTAO_RADIUS * 0.75) / (GTAO_RADIUS * 0.25), 0.0, 1.0);
        float cos_theta = mix(dot(viewer_dir, offset) * norm, -1.0, falloff);

        max_cos_theta = max(cos_theta, max_cos_theta);
    }

    return fast_acos(clamp(max_cos_theta, -1.0, 1.0));
}

vec2 compute_gtao(
    vec3 screen_pos, vec3 view_pos, vec3 view_normal,
    vec2 dither, out vec3 bent_normal
) {
    float ao = 0.0;
    float ambient_sss = 0.0;
    bent_normal = vec3(0.0);

    vec3 viewer_dir   = normalize(-view_pos);
    vec3 viewer_right = normalize(cross(vec3(0.0, 1.0, 0.0), viewer_dir));
    vec3 viewer_up    = cross(viewer_dir, viewer_right);

    // Increase radius slightly at distance
    float ao_radius = max(0.25 + 0.75 * smoothstep(0.0, 81.0, dot(view_pos, view_pos)), 0.5);

    for (int i = 0; i < GTAO_SLICES; ++i) {
        float slice_angle = (float(i) + dither.x) * (PI / float(GTAO_SLICES));

        vec3 slice_dir      = vec3(cos(slice_angle), sin(slice_angle), 0.0);
        vec3 view_slice_dir = viewer_right * slice_dir.x + viewer_up * slice_dir.y;

        vec3 ortho_dir = slice_dir - dot(slice_dir, viewer_dir) * viewer_dir;
        vec3 axis      = cross(slice_dir, viewer_dir);
        vec3 proj_norm = view_normal - axis * dot(view_normal, axis);

        float len_sq   = dot(proj_norm, proj_norm);
        float norm     = inversesqrt(len_sq + 1e-6);

        float sgn_gamma = sign(dot(ortho_dir, proj_norm));
        float cos_gamma = clamp(dot(proj_norm, viewer_dir) * norm, -1.0, 1.0);
        float gamma     = sgn_gamma * fast_acos(cos_gamma);

        vec2 horizon;
        horizon.x = compute_horizon_angle(-view_slice_dir, viewer_dir, screen_pos, view_pos, ao_radius, dither.y);
        horizon.y = compute_horizon_angle( view_slice_dir, viewer_dir, screen_pos, view_pos, ao_radius, dither.y);

        ambient_sss += max(0.0, horizon.y - HALF_PI) * INV_PI;

        horizon = gamma + clamp(vec2(-1.0, 1.0) * horizon - gamma, -HALF_PI, HALF_PI);
        ao += integrate_arc(horizon, gamma, cos_gamma) * len_sq * norm;

        float bent_angle = dot(horizon, vec2(0.5));
        bent_normal += viewer_dir * cos(bent_angle) + ortho_dir * sin(bent_angle);
    }

    const float albedo = 0.2;
    ao          *= 1.0 / float(GTAO_SLICES);
    ambient_sss *= 1.0 / float(GTAO_SLICES);
    ao          /= albedo * ao + (1.0 - albedo);

    bent_normal = normalize(normalize(bent_normal) - 0.5 * viewer_dir);

    return clamp(vec2(ao, ambient_sss), 0.0, 1.0);
}

// ─── Dispatch ────────────────────────────────────────────────────────────────
// Returns final ambient occlusion factor [0,1] (0=fully occluded, 1=no AO)
float compute_ao(vec3 screen_pos, vec3 view_pos, vec3 view_normal, vec2 dither) {
#if SHADER_AO == AO_GTAO
    vec3 bent_normal;
    vec2 gtao = compute_gtao(screen_pos, view_pos, view_normal, dither, bent_normal);
    return 1.0 - gtao.x * SHADER_AO_STRENGTH;
#elif SHADER_AO == AO_SSAO
    float dither1d = dither.x + dither.y * 0.5;
    return compute_ssao(screen_pos, view_pos, view_normal, dither1d);
#else
    return 1.0;
#endif
}

#endif // AO_INCLUDED


