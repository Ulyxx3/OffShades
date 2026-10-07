#if !defined INCLUDE_FOG_END_FOG_VL
#define INCLUDE_FOG_END_FOG_VL

#include "/include/lighting/shadows/distortion.glsl"
#include "/include/utility/color.glsl"
#include "/include/utility/fast_math.glsl"
#include "/include/utility/phase_functions.glsl"

float end_fog_density(vec3 world_pos) {
    const float falloff_start = 64.0;
    const float falloff_half_life = 7.0;

    const float mul = -rcp(falloff_half_life);
    const float add = -mul * falloff_start;

    float density = exp2(min(world_pos.y * mul + add, 0.0));

    // fade away below the island
    density *= linear_step(0.0, 64.0, world_pos.y);

    return density;
}

vec3 end_fog_emission(vec3 world_pos) {
    const vec3 main_col =
        from_srgb(vec3(END_AMBIENT_R, END_AMBIENT_G, END_AMBIENT_B)) *
        END_AMBIENT_I;
    const vec3 alt_col = 0.5 * vec3(0.25, 1.0, 0.5);
    const vec3 wind0 = vec3(1.0, 0.1, 0.5) * 0.01;
    const vec3 wind1 = vec3(-0.7, -0.1, -0.1) * 0.05;

    float base_noise =
        texture(colortex0, 0.02 * world_pos + wind0 * frameTimeCounter).x;
    float detail_nose =
        texture(colortex0, 0.04 * world_pos + wind1 * frameTimeCounter).x *
            0.8 -
        0.4;
    float color_noise = texture(colortex0, 0.02 * world_pos + 0.2).x;

    float density = max0(linear_step(0.6, 0.9, base_noise) + detail_nose);
    float color_mix = linear_step(0.5, 0.7, color_noise);

    float view_dist = distance(world_pos, cameraPosition);
    float fade_near = 1.0 - exp2(-0.1 * view_dist);
    float fade_far = exp2(-0.05 * view_dist);
    float fade_height = exp2(-0.05 * (max0(cameraPosition.y - 120.0))) *
        linear_step(0.0, 64.0, world_pos.y);

    return mix(main_col, alt_col, color_mix) *
        (density * fade_near * fade_far * fade_height);
}

mat2x3 raymarch_end_fog(
    vec3 world_start_pos,
    vec3 world_end_pos,
    bool sky,
    float dither
) {
    // In deep space, there is no atmospheric fog below the islands.
    // The cosmic void and Saturn's rings stretch cleanly below and around the player.
    return mat2x3(vec3(0.0), vec3(1.0));
}

#endif // INCLUDE_FOG_END_FOG_VL
