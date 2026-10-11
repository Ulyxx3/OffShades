#if !defined INCLUDE_LIGHTING_CLOUD_SHADOWS
#define INCLUDE_LIGHTING_CLOUD_SHADOWS

#include "/include/sky/clouds/constants.glsl"
#include "/include/utility/bicubic.glsl"

#ifndef SAMPLER_GAUX4_DECLARED
#define SAMPLER_GAUX4_DECLARED
uniform sampler2D gaux4; // Complementary cloud-water atlas
#endif

const ivec2 cloud_shadow_res = ivec2(512);
const float cloud_shadow_extent = 256.0;
#if !defined INCLUDE_SKY_CLOUDS_REIMAGINED_FUNCS
#define INCLUDE_SKY_CLOUDS_REIMAGINED_FUNCS

const float cloudNarrowness = 0.07;
const float defaultCloudAltitude = 160.0;

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

float sample_reimagined_cloud(vec3 pos, float wind, float roundness) {
    vec3 pos_m = modify_cloud_trace_pos(pos, defaultCloudAltitude, wind);
    vec2 coord = get_rounded_cloud_coord(pos_m.xz, roundness);
    float noise = texture(gaux4, coord).b;
    float rain_boost = rainStrength * 0.12;
    return smoothstep(0.20 - rain_boost, 0.40, noise);
}

vec2 shadow_view_to_cloud_shadow_space(vec3 shadow_view_pos) {
    vec2 cloud_shadow_pos = shadow_view_pos.xy / cloud_shadow_extent;
    cloud_shadow_pos /= 1.0 + length(cloud_shadow_pos);
    cloud_shadow_pos = cloud_shadow_pos * 0.5 + 0.5;

    return cloud_shadow_pos;
}

vec2 project_cloud_shadow_map(vec3 scene_pos) {
    return shadow_view_to_cloud_shadow_space(
        transform(shadowModelView, scene_pos)
    );
}

vec3 unproject_cloud_shadow_map(vec2 cloud_shadow_pos) {
    cloud_shadow_pos = cloud_shadow_pos * 2.0 - 1.0;
    float len = length(cloud_shadow_pos);
    if (len >= 0.99) return vec3(0.0);
    cloud_shadow_pos /= 1.0 - len;

    vec3 shadow_view_pos = vec3(cloud_shadow_pos * cloud_shadow_extent, 1.0);

    return transform(shadowModelViewInverse, shadow_view_pos);
}

float get_cloud_shadows(sampler2D cloud_shadow_map, vec3 scene_pos) {
#ifndef CLOUD_SHADOWS
    return 1.0;
#else
    // If the light source is too low or below horizon, no cloud shadows
    if (light_dir.y < 0.05) {
        return 1.0;
    }

    vec3 world_pos = scene_pos + cameraPosition;

    // Fade out cloud shadows when fragment is at or above cloud layer (160m)
    float dist_to_cloud = defaultCloudAltitude - world_pos.y;
    if (dist_to_cloud <= 0.0) {
        return 1.0;
    }

    float light_y = max(light_dir.y, 0.08);
    vec3 cloud_pos = world_pos + light_dir * (dist_to_cloud / light_y);

    float wind = frameTimeCounter * 0.015 * 1.2;
    const float roundness = 0.30;

    float cloud_density = sample_reimagined_cloud(cloud_pos, wind, roundness);

    // Altitude fade near cloud altitude (150m to 160m)
    float altitude_fraction = smoothstep(150.0, 160.0, world_pos.y);
    // Sun elevation fade near horizon (0.05 to 0.15)
    float sun_fade = smoothstep(0.05, 0.15, light_dir.y);
    float cloud_shadow_fade = sun_fade * (1.0 - altitude_fraction);

    float shadow = 1.0 - cloud_density * cloud_shadow_fade * CLOUD_SHADOWS_INTENSITY;
    return shadow;
#endif
}

#if defined PROGRAM_PREPARE && defined CLOUD_SHADOWS

vec2 render_cloud_shadow_map(vec2 uv) {
    if (light_dir.y < 0.04) {
        return vec2(1.0, 1.0);
    }

    vec2 p = uv * 2.0 - 1.0;
    if (length(p) >= 0.98) {
        return vec2(1.0, 1.0);
    }

    vec3 scene_pos = unproject_cloud_shadow_map(uv);
    vec3 world_pos = scene_pos + cameraPosition;

    float light_y = max(light_dir.y, 0.08);
    float dist_to_cloud = defaultCloudAltitude - world_pos.y;
    vec3 cloud_pos = world_pos + light_dir * (dist_to_cloud / light_y);

    float wind = frameTimeCounter * 0.015 * 1.2;
    const float roundness = 0.30;

    float cloud_density = sample_reimagined_cloud(cloud_pos, wind, roundness);
    float shadow = 1.0 - cloud_density;

    return vec2(shadow, shadow);
}
#endif
#endif // INCLUDE_LIGHTING_CLOUD_SHADOWS
