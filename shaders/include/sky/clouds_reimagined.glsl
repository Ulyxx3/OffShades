#if !defined INCLUDE_SKY_CLOUDS_REIMAGINED
#define INCLUDE_SKY_CLOUDS_REIMAGINED

/*
--------------------------------------------------------------------------------
  OffShades - Complementary Reimagined Volumetric Box Clouds
  Adapted for Photon shader pipeline with balanced HDR lighting & horizon fade
--------------------------------------------------------------------------------
*/

#include "/include/sky/clouds/common.glsl"

#ifndef SAMPLER_GAUX4_DECLARED
#define SAMPLER_GAUX4_DECLARED
uniform sampler2D gaux4; // Complementary cloud-water atlas
#endif

#if !defined INCLUDE_SKY_CLOUDS_REIMAGINED_FUNCS
#define INCLUDE_SKY_CLOUDS_REIMAGINED_FUNCS

const float cloudNarrowness = 0.07;
const float defaultCloudAltitude = 160.0;

// Rounded coordinates for geometric cubic clouds (SixthSurge / EminGT)
vec2 get_rounded_cloud_coord(vec2 pos, float roundness) {
    vec2 coord = pos.yx + 0.5;
    vec2 sign_coord = sign(coord);
    coord = abs(coord) + 1.0;
    vec2 i, f = modf(coord, i);
    f = smoothstep(0.5 - roundness, 0.5 + roundness, f);
    coord = i + f;
    return (coord - 0.5) * sign_coord / 256.0;
}

vec3 modify_cloud_trace_pos(vec3 trace_pos, float altitude, float wind) {
    trace_pos.z -= wind;
    trace_pos.x += altitude * 64.0;
    trace_pos.xz *= cloudNarrowness;
    return trace_pos;
}

#endif

const float cloudStretch = 4.2;
const float cloudTallness = cloudStretch * 2.0;
const float cloudRoundness = 0.125;

bool get_reimagined_cloud_noise(vec3 trace_pos, float altitude, float wind) {
    vec3 trace_pos_m = modify_cloud_trace_pos(trace_pos, altitude, wind);
    vec2 coord = get_rounded_cloud_coord(trace_pos_m.xz, cloudRoundness);
    
    // Complementary Reimagined cloud noise is in the blue channel of cloud-water.png
    float noise = texture(gaux4, coord).b;

    float height_fraction = clamp(abs(altitude - trace_pos.y) / cloudStretch, 0.001, 0.999);
    float threshold = height_fraction * height_fraction;
    threshold = threshold * threshold;
    
    return noise > (threshold * 0.5 + 0.25);
}

// Raymarches the Reimagined volumetric box cloud layer
CloudsResult draw_reimagined_box_clouds(
    vec3 camera_pos_world,
    vec3 ray_dir,
    vec3 clear_sky,
    vec3 sun_col,
    vec3 moon_col,
    vec3 sky_col,
    float distance_to_terrain,
    float dither
) {
    CloudsResult result = clouds_not_hit;

    float cloud_altitude = defaultCloudAltitude;
    float lower_plane_alt  = cloud_altitude - cloudStretch;
    float higher_plane_alt = cloud_altitude + cloudStretch;

    if (abs(ray_dir.y) < 1e-4) {
        return clouds_not_hit;
    }

    float dist_lower  = (lower_plane_alt - camera_pos_world.y) / ray_dir.y;
    float dist_higher = (higher_plane_alt - camera_pos_world.y) / ray_dir.y;

    float min_dist = max(0.0, min(dist_lower, dist_higher));
    float max_dist = max(dist_lower, dist_higher);

    if (max_dist <= 0.0) {
        return clouds_not_hit;
    }

    if (distance_to_terrain > 0.0) {
        max_dist = min(max_dist, distance_to_terrain);
    }

    if (min_dist >= max_dist) {
        return clouds_not_hit;
    }

    // Maximum distance for clouds: smooth fade towards horizon (prevents endless glowing grid)
    float distance_threshold = clamp(far * 0.9, 280.0, 480.0);
    if (min_dist > distance_threshold) {
        return clouds_not_hit;
    }

    float plane_diff = min(max_dist, distance_threshold) - min_dist;
    if (plane_diff <= 0.0) {
        return clouds_not_hit;
    }

    const int sample_count = 18;
    float step_length = plane_diff / float(sample_count);
    vec3 ray_step = ray_dir * step_length;

    vec3 current_pos = camera_pos_world + ray_dir * min_dist + ray_step * dither;

    float wind = frameTimeCounter * 0.015 * 1.2;

    // Balanced lighting intensities matching Photon's HDR pipeline
    // Prevents extreme blow-out and blinding white clouds
    float sun_vis = clamp(sun_dir.y * 5.0, 0.0, 1.0);
    vec3 direct_light = mix(moon_col * 0.08, sun_col * 0.09, sun_vis);
    vec3 ambient_light = mix(sky_col * 0.25, clear_sky * 0.35, 0.5) + vec3(0.04, 0.06, 0.09);

    float VdotL = dot(ray_dir, light_dir);
    float forward_scatter = pow(max(0.0, VdotL), 4.0) * 0.15;

    vec3 accumulated_scattering = vec3(0.0);
    float accumulated_transmittance = 1.0;
    float first_hit_distance = 1e5;

    for (int i = 0; i < sample_count; ++i) {
        if (accumulated_transmittance < 0.03) break;

        float dist_xz = length(current_pos.xz - camera_pos_world.xz);
        if (dist_xz > distance_threshold) break;

        if (get_reimagined_cloud_noise(current_pos, cloud_altitude, wind)) {
            float dist_from_cam = length(current_pos - camera_pos_world);
            if (first_hit_distance > 1e4) {
                first_hit_distance = dist_from_cam;
            }

            // Height-based vertical shading: soft bright top, subtle blue-tinted underside
            float vertical_shading = clamp((current_pos.y - lower_plane_alt) / cloudTallness, 0.0, 1.0);
            vertical_shading = pow(vertical_shading, 0.8);

            vec3 step_color = mix(ambient_light, direct_light, vertical_shading * 0.75 + 0.25 + forward_scatter);

            // Horizon distance fade factor (as in Complementary Reimagined)
            float dist_ratio = clamp((distance_threshold - dist_xz) / (distance_threshold * 0.4), 0.0, 1.0);
            float horizon_fade = dist_ratio * dist_ratio;
            step_color = mix(clear_sky * 0.7, step_color, horizon_fade);

            float sample_density = 0.55 * (step_length / cloudStretch);
            float sample_alpha = (1.0 - exp(-sample_density)) * horizon_fade;

            accumulated_scattering += step_color * (accumulated_transmittance * sample_alpha);
            accumulated_transmittance *= (1.0 - sample_alpha);
        }

        current_pos += ray_step;
    }

    if (first_hit_distance < 1e4) {
        result.scattering = vec4(accumulated_scattering, 1.0);
        result.transmittance = accumulated_transmittance;
        result.apparent_distance = first_hit_distance;
    }

    return result;
}

#endif // INCLUDE_SKY_CLOUDS_REIMAGINED
