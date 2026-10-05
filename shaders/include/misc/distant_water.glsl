#if !defined INCLUDE_MISC_DISTANT_WATER
#define INCLUDE_MISC_DISTANT_WATER

#include "/include/lighting/specular_lighting.glsl"
#include "/include/misc/purkinje_shift.glsl"
#include "/include/surface/water_normal.glsl"
#include "/include/surface/water_complementary.glsl"

vec4 draw_distant_water(
    vec3 position_screen,
    vec3 position_view,
    vec3 position_world,
    vec3 direction_world,
    vec3 flat_normal,
    vec3 tint,
    vec2 light_levels,
    float view_distance,
    float layer_distance
) {
    vec4 water_color = vec4(0.0);

    // Use hardcoded TBN matrix pointing upwards that is the same for LoD water
    // and regular water
    const mat3 tbn =
        mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0));

    // Common fog

    float fog_visibility = common_fog(view_distance, false).a;

    // Cloud shadows

#if defined WORLD_OVERWORLD && defined CLOUD_SHADOWS
    float cloud_shadows =
        get_cloud_shadows(colortex8, position_world - cameraPosition);
#else
    const float cloud_shadows = 1.0;
#endif

    // Account for 1/8 height difference between water and terrain
    vec3 water_surface_pos = position_world - vec3(0.0, rcp(8.0), 0.0);

    vec3 normal = flat_normal;

#ifdef WATER_WAVES
    if (flat_normal.y > eps) {
        vec2 dummy_tangent;
        normal = get_complementary_water_normal(
            water_surface_pos,
            flat_normal,
            tbn,
            direction_world,
            light_levels.y,
            false,
            dummy_tangent
        );
    }
#endif

    // Complementary Reimagined water color & absorption
    float comp_fresnel = clamp(1.0 + dot(normal, direction_world), 0.0, 1.0);
    float comp_fog_val = 0.0;
    vec3 dummy_hl = vec3(0.0);
    vec4 comp_water = get_complementary_water_color(
        vec4(0.35, 0.45, 0.60, 1.0),
        tint.rgb,
        layer_distance,
        light_levels.y,
        comp_fresnel,
        false,
        comp_fog_val,
        dummy_hl
    );
    water_color.rgb = comp_water.rgb * (comp_fog_val * 0.35) * fog_visibility;
    water_color.a = comp_water.a;

    // Specular highlight

#if (defined WORLD_OVERWORLD || defined WORLD_END)
    float NoL = dot(normal, light_dir);
    float NoV = clamp01(dot(normal, -direction_world));
    float LoV = dot(light_dir, -direction_world);
    float halfway_norm = inversesqrt(2.0 * LoV + 2.0);
    float NoH = (NoL + NoV) * halfway_norm;
    float LoH = LoV * halfway_norm + halfway_norm;

    water_color.rgb +=
        get_specular_highlight(water_material, NoL, NoV, NoH, LoV, LoH) *
        light_color * cloud_shadows * fog_visibility;
#endif

    // Specular reflections

#if defined ENVIRONMENT_REFLECTIONS || defined SKY_REFLECTIONS
    mat3 new_tbn = get_tbn_matrix(normal);
    water_color.rgb +=
        get_specular_reflections(
            water_material,
            new_tbn,
            position_screen,
            position_view,
            position_world,
            normal,
            flat_normal,
            direction_world,
            direction_world * new_tbn,
            light_levels.y,
            true
        ) *
        fog_visibility;
#endif

    // Purkinje shift

    water_color.rgb = purkinje_shift(water_color.rgb, light_levels);

    return water_color;
}

#endif // INCLUDE_MISC_DISTANT_WATER
