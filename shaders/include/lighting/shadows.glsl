/*
================================================================================
  OffShades — include/lighting/shadows.glsl
  PCSS (Percentage-Closer Soft Shadows) with Variable Penumbra.
  Adapted from Photon Shaders by Sixthsurge (MIT).
================================================================================
*/

#ifndef SHADOWS_INCLUDED
#define SHADOWS_INCLUDED

#include "/include/utility/depth.glsl"
#include "/include/utility/math.glsl"

// Shadow distortion — concentrates more shadow map resolution near the player
float get_distortion_factor(vec2 shadow_clip_pos) {
    // Quartic-norm based (Photon style)
    float q = sqrt(sqrt(pow4(shadow_clip_pos.x) + pow4(shadow_clip_pos.y)));
    return q * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
}

vec3 distort_shadow_space(vec3 shadow_clip_pos) {
    float f = get_distortion_factor(shadow_clip_pos.xy);
    return shadow_clip_pos * vec3(1.0 / f, 1.0 / f, SHADOW_DEPTH_SCALE);
}

// Shadow normal bias (Complementary method, used with permission)
vec3 get_shadow_bias(vec3 scene_pos, vec3 normal, float NoL, float skylight) {
    return 0.25 * normal * clamp(0.12 + 0.01 * length(scene_pos), 0.0, 1.0)
                         * (2.0 - clamp(NoL, 0.0, 1.0));
}

// ─── Blue-noise progressive disk kernel (32 samples) ────────────────────────
const vec2[32] blue_noise_disk = vec2[](
    vec2( 0.478712,  0.875764), vec2(-0.337956, -0.793959),
    vec2(-0.955259, -0.028164), vec2( 0.864527,  0.325689),
    vec2( 0.209342, -0.395657), vec2(-0.106779,  0.672585),
    vec2( 0.156213,  0.235113), vec2(-0.413644, -0.082856),
    vec2(-0.415667,  0.323909), vec2( 0.141896, -0.939980),
    vec2( 0.954932, -0.182516), vec2(-0.766184,  0.410799),
    vec2(-0.434912, -0.458845), vec2( 0.415242, -0.078724),
    vec2( 0.728335, -0.491777), vec2(-0.058086, -0.066401),
    vec2( 0.202990,  0.686837), vec2(-0.808362, -0.556402),
    vec2( 0.507386, -0.640839), vec2(-0.723494, -0.229240),
    vec2( 0.489740,  0.317826), vec2(-0.622663,  0.765301),
    vec2(-0.010640,  0.929347), vec2( 0.663146,  0.647618),
    vec2(-0.096674, -0.413835), vec2( 0.525945, -0.321063),
    vec2(-0.122533,  0.366019), vec2( 0.195235, -0.687983),
    vec2(-0.563203,  0.098748), vec2( 0.418563,  0.561335),
    vec2(-0.378595,  0.800367), vec2( 0.826922,  0.001024)
);

// Simple 2D rotation matrix
mat2 rotation_matrix(float angle) {
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

// Interleaved gradient noise (Jimenez 2014) for shadow dithering
float interleaved_gradient_noise(vec2 coord) {
    return fract(52.9829189 * fract(0.06711056 * coord.x + 0.00583715 * coord.y));
}

// Constants
const int   shadow_map_res        = int(float(shadowMapResolution) * MC_SHADOW_QUALITY);
const float shadow_map_pixel_size = 1.0 / float(shadow_map_res);

// Lightmap-based fallback shadow when outside shadow range
float lightmap_shadow(float skylight, float NoL) {
    return smoothstep(13.5 / 15.0, 14.5 / 15.0, skylight);
}

// ─── PCSS Blocker Search ─────────────────────────────────────────────────────
// Returns (average_blocker_depth, sss_depth_accumulation)
vec2 blocker_search(vec3 scene_pos, vec3 shadow_clip_pos, float ref_z, float dither, int steps) {
    float radius = SHADOW_BLOCKER_SEARCH_RADIUS * shadowProjection[0].x;
    mat2  rot    = rotation_matrix(TAU * dither) * radius;

    float depth_sum    = 0.0;
    float weight_sum   = 0.0;
    float depth_sss_sum = 0.0;

    for (int i = 0; i < steps; ++i) {
        vec2 uv = shadow_clip_pos.xy + rot * blue_noise_disk[i];
        uv /= get_distortion_factor(uv);
        uv  = uv * 0.5 + 0.5;

        float depth  = texelFetch(shadowtex0, ivec2(uv * float(shadow_map_res)), 0).x;
        float weight = step(depth, ref_z);

        depth_sum    += weight * depth;
        weight_sum   += weight;
        depth_sss_sum += max(ref_z - depth, 0.0);
    }

    float avg_blocker = (weight_sum == 0.0) ? 0.0 : depth_sum / weight_sum;
    float sss_depth   = -shadowProjectionInverse[2].z * depth_sss_sum
                         / (SHADOW_DEPTH_SCALE * float(steps));

    return vec2(avg_blocker, sss_depth);
}

// ─── PCF Shadow Sampling ─────────────────────────────────────────────────────
vec3 shadow_pcf(vec3 shadow_screen_pos, vec3 shadow_clip_pos,
#ifdef SHADOW_COLOR
                vec3 shadow_screen_pos_translucent, vec3 shadow_clip_pos_translucent,
#endif
                float penumbra_size, float dither) {

    float dist_factor     = get_distortion_factor(shadow_clip_pos.xy);
    float min_filter_rad  = 2.0 * shadow_map_pixel_size * dist_factor;
    float filter_radius   = max(penumbra_size, min_filter_rad);
    float filter_scale    = (filter_radius / min_filter_rad) * (filter_radius / min_filter_rad);

    int step_count = int(clamp(float(SHADOW_PCF_STEPS_MIN) + SHADOW_PCF_STEPS_SCALE * filter_scale,
                                 float(SHADOW_PCF_STEPS_MIN), float(SHADOW_PCF_STEPS_MAX)));

    mat2 rot = rotation_matrix(TAU * dither) * filter_radius;

    float shadow     = 0.0;
    vec3  color_sum  = vec3(0.0);
    float weight_sum = 0.0;

    // First 4 samples + optional color
    for (int i = 0; i < 4; ++i) {
        vec2 offset = rot * blue_noise_disk[i];
        vec2 uv     = shadow_clip_pos.xy + offset;
        uv /= get_distortion_factor(uv);
        uv  = uv * 0.5 + 0.5;

        shadow += texture(shadowtex1, vec3(uv, shadow_screen_pos.z));

#ifdef SHADOW_COLOR
        vec2 uv_t = shadow_clip_pos_translucent.xy + offset;
        uv_t /= get_distortion_factor(uv_t);
        uv_t = uv_t * 0.5 + 0.5;

        ivec2 texel     = ivec2(uv_t * float(shadow_map_res));
        float depth     = texelFetch(shadowtex0, texel, 0).x;
        vec3  color     = texelFetch(shadowcolor0, texel, 0).rgb;
        color = mix(vec3(1.0), 4.0 * color, step(depth, shadow_screen_pos_translucent.z));

        float w = step(EPS, max(max(color.r, color.g), color.b));
        color_sum  += color * w;
        weight_sum += w;
#endif
    }

    vec3 color = (weight_sum > 0.0) ? color_sum / weight_sum : vec3(1.0);

    if (shadow > 4.0 - EPS) return color;
    if (shadow < EPS)        return vec3(0.0);

    for (int i = 4; i < step_count; ++i) {
        vec2 uv = shadow_clip_pos.xy + rot * blue_noise_disk[i];
        uv /= get_distortion_factor(uv);
        uv  = uv * 0.5 + 0.5;
        shadow += texture(shadowtex1, vec3(uv, shadow_screen_pos.z));
    }

    float rcp_steps = 1.0 / float(step_count);
    float sharp     = 0.4 * max(0.0, (min_filter_rad - penumbra_size) / min_filter_rad);
    shadow = clamp((shadow * rcp_steps - sharp) / (1.0 - 2.0 * sharp), 0.0, 1.0);

    return shadow * color;
}

// ─── Main Shadow Entry Point ─────────────────────────────────────────────────
vec3 calculate_shadows(
    vec3  scene_pos,
    vec3  flat_normal,
    float skylight,
    float cloud_shadows,
    inout float sss_amount,
    out   float distance_fade,
    out   float sss_depth
) {
    sss_depth     = 0.0;
    distance_fade = 0.0;

    float NoL = dot(flat_normal, light_dir);
    if (NoL < 1e-3 && sss_amount < 1e-3) return vec3(0.0);

    vec3 bias = get_shadow_bias(scene_pos, flat_normal, NoL, skylight);

    // Light-leak prevention (Complementary Reimagined technique)
    vec3 edge_factor = 0.1 - 0.2 * fract(scene_pos + cameraPosition + flat_normal * 0.01);
    edge_factor -= edge_factor * skylight;

    vec3 shadow_view_pos   = transform(shadowModelView, scene_pos + bias + edge_factor);
    vec3 shadow_clip_pos   = project_ortho(shadowProjection, shadow_view_pos);
    vec3 shadow_screen_pos = distort_shadow_space(shadow_clip_pos) * 0.5 + 0.5;

    // Distance fade
    float dist_sq      = dot(scene_pos.xz, scene_pos.xz) / (shadowDistance * shadowDistance);
    float screen_fade  = max(max(abs(shadow_screen_pos.x * 2.0 - 1.0),
                                 abs(shadow_screen_pos.y * 2.0 - 1.0)), 0.0);
    screen_fade = screen_fade * screen_fade * screen_fade * screen_fade *
                  screen_fade * screen_fade * screen_fade * screen_fade *
                  screen_fade * screen_fade * screen_fade * screen_fade *
                  screen_fade * screen_fade * screen_fade * screen_fade *
                  screen_fade * screen_fade * screen_fade * screen_fade *
                  screen_fade * screen_fade * screen_fade * screen_fade *
                  screen_fade * screen_fade * screen_fade * screen_fade *
                  screen_fade * screen_fade * screen_fade * screen_fade;
    distance_fade = pow(max(screen_fade,
                            mix(1.0, 0.55, clamp((light_dir.y - 0.33) / 0.47, 0.0, 1.0)) * dist_sq),
                        1.0 / 32.0);

    float distant_shadow = lightmap_shadow(skylight, NoL);
    if (distance_fade >= 1.0) return vec3(distant_shadow);

    float dither = interleaved_gradient_noise(gl_FragCoord.xy + float(frameCounter) * 17.0);

#ifdef SHADOW_VPS
    float ref_z = shadow_screen_pos.z;
    vec2  blocker = blocker_search(scene_pos, shadow_clip_pos, ref_z, dither, SSS_STEPS);
    sss_depth = mix(blocker.y, sss_depth, distance_fade);

    if (NoL < 1e-3)          return vec3(0.0);
    if (blocker.x < EPS)     return vec3(mix(1.0, distant_shadow, distance_fade));

    float penumbra_size = 16.0 * SHADOW_PENUMBRA_SCALE * (ref_z - blocker.x) / blocker.x;
          penumbra_size *= 5.0 - 4.0 * cloud_shadows;
          penumbra_size  = min(penumbra_size, SHADOW_BLOCKER_SEARCH_RADIUS);
          penumbra_size *= shadowProjection[0].x;
#else
    float penumbra_size = sqrt(0.5) * shadow_map_pixel_size * SHADOW_PENUMBRA_SCALE;
    penumbra_size *= 1.0 + 7.0 * sss_amount;
#endif

#ifdef SHADOW_COLOR
    vec3 shadow_view_pos_t = transform(shadowModelView, scene_pos + bias);
    vec3 shadow_clip_pos_t = project_ortho(shadowProjection, shadow_view_pos_t);
    vec3 shadow_screen_pos_t = distort_shadow_space(shadow_clip_pos_t) * 0.5 + 0.5;
#endif

#ifdef SHADOW_PCF
    vec3 shadow = shadow_pcf(
        shadow_screen_pos, shadow_clip_pos,
#ifdef SHADOW_COLOR
        shadow_screen_pos_t, shadow_clip_pos_t,
#endif
        penumbra_size, dither
    );
#else
    float sh = texture(shadowtex1, shadow_screen_pos);
    vec3 shadow = vec3(sh);
#ifdef SHADOW_COLOR
    {
        ivec2 texel = ivec2(shadow_screen_pos.xy * float(shadow_map_res));
        float d  = texelFetch(shadowtex0, texel, 0).x;
        vec3  c  = texelFetch(shadowcolor0, texel, 0).rgb * 4.0;
        float w  = step(d, shadow_screen_pos.z) * step(EPS, max(max(c.r,c.g),c.b));
        shadow  *= c * w + (1.0 - w);
    }
#endif
#endif

    return mix(shadow, vec3(distant_shadow), clamp(distance_fade, 0.0, 1.0));
}

#endif // SHADOWS_INCLUDED


