#if !defined INCLUDE_SURFACE_WATER_COMPLEMENTARY
#define INCLUDE_SURFACE_WATER_COMPLEMENTARY

/*
--------------------------------------------------------------------------------
  OffShades - Complementary Reimagined Water System
  Faithful water ripples, vanilla texture detail extraction, depth absorption & foam
--------------------------------------------------------------------------------
*/

#ifndef SAMPLER_GAUX4_DECLARED
#define SAMPLER_GAUX4_DECLARED
uniform sampler2D gaux4; // Complementary cloud-water atlas
#endif

#ifndef WATER_SPEED_MULT
#define WATER_SPEED_MULT 1.00
#endif
#ifndef WATER_BUMPINESS
#define WATER_BUMPINESS 0.75
#endif
#ifndef WATER_BUMP_MED
#define WATER_BUMP_MED 1.00
#endif
#ifndef WATER_BUMP_SMALL
#define WATER_BUMP_SMALL 0.35
#endif
#ifndef WATER_BUMP_BIG
#define WATER_BUMP_BIG 0.25
#endif

// Computes Complementary Reimagined water surface normal & ripples
vec3 get_complementary_water_normal(
    vec3 world_pos,
    vec3 flat_normal,
    mat3 tbn_matrix,
    vec3 view_dir_world,
    float skylight,
    bool flowing_water,
    out vec2 out_normal_tangent_xy
) {
    float raw_wind = frameTimeCounter * 0.018 * WATER_SPEED_MULT;
    vec2 wind = vec2(0.0, -raw_wind);
    
    vec2 water_pos = 0.032 * (world_pos.xz + world_pos.y * 2.0);
    vec2 water_pos_m = water_pos * 2.5;
    vec2 wind_m = wind * 2.5;

    // View direction in tangent space for parallax
    vec3 view_dir_tangent = view_dir_world * tbn_matrix;
    vec2 parallax_mult = -0.008 * view_dir_tangent.xy / max(abs(view_dir_tangent.z), 0.001);

#ifdef WATER_PARALLAX
    // Parallax mapping (4 steps, as in Complementary Reimagined)
    for (int i = 0; i < 4; i++) {
        water_pos_m += parallax_mult * texture(gaux4, water_pos_m - wind_m).a;
        water_pos_m += parallax_mult * texture(gaux4, water_pos_m * 0.25 - 0.5 * wind_m).a;
    }
#endif

    // Multi-octave normals from Complementary Reimagined
    vec2 normal_med   = texture(gaux4, water_pos_m + wind_m).rg - 0.5;
    vec2 normal_small = texture(gaux4, water_pos_m * 4.0 - 2.0 * wind_m).rg - 0.5;
    vec2 normal_big   = texture(gaux4, water_pos_m * 0.25 - 0.5 * wind_m).rg - 0.5;
         normal_big  += texture(gaux4, water_pos_m * 0.05 - 0.05 * wind_m).rg - 0.5;

    vec2 normal_xy = normal_med * WATER_BUMP_MED + normal_small * WATER_BUMP_SMALL + normal_big * WATER_BUMP_BIG;
    
    float fresnel_approx = clamp(1.0 + dot(flat_normal, view_dir_world), 0.0, 1.0);
    normal_xy *= 4.5 * (1.0 - 0.6 * fresnel_approx) * WATER_BUMPINESS;
    normal_xy *= 0.025 * skylight + 0.01;

    if (flowing_water) {
        normal_xy *= 1.35;
    }

    out_normal_tangent_xy = normal_xy;

    vec3 normal_tangent;
    normal_tangent.xy = normal_xy;
    normal_tangent.z = sqrt(max(0.0, 1.0 - dot(normal_xy, normal_xy)));

    vec3 world_normal = normalize(tbn_matrix * normal_tangent);

    // Complementary anti-artifact fix for normals pointing inside water surface
    vec3 reflected_vec = reflect(view_dir_world, world_normal);
    float nor_mix = pow(clamp(1.0 - max(0.0, dot(flat_normal, reflected_vec)), 0.0, 1.0), 8.0) * 0.5;
    world_normal = normalize(mix(world_normal, flat_normal, nor_mix));

    return world_normal;
}

// Extracts only fine wave details from Minecraft vanilla animated water texture
float get_vanilla_water_detail(vec4 vanilla_tex) {
    float peak = max(vanilla_tex.r, vanilla_tex.g);
    float detail = clamp((peak - 0.62) / 0.38, 0.0, 1.0);
    return detail * detail;
}

// Complementary Reimagined water color with isolated vanilla texture details
vec4 get_complementary_water_color(
    vec4 vanilla_tex,
    vec3 tint_rgb,
    float water_depth_dist,
    float skylight,
    float fresnel,
    bool is_eye_in_water,
    out float out_water_fog,
    out vec3 out_vanilla_highlight
) {
    vec3 comp_color_m = sqrt(max(tint_rgb, vec3(0.01))) * vec3(0.85, 0.92, 1.0);
    vec3 shallow_color = vec3(0.06, 0.16, 0.24) * comp_color_m;
    vec3 deep_color    = vec3(0.02, 0.07, 0.14) * comp_color_m;

    // Depth fog factor: clear near surface, darker in deep water
    float water_fog = clamp(1.0 - exp(-water_depth_dist * 0.045), 0.0, 1.0);
    out_water_fog = water_fog;

    vec3 absorbed_col = mix(shallow_color, deep_color, water_fog);

    // Extract only fine details (crests) from vanilla animated texture
    float detail = get_vanilla_water_detail(vanilla_tex);
    vec3 detail_color = vec3(0.14, 0.22, 0.30) * comp_color_m * (0.4 + 0.6 * skylight);
    absorbed_col += detail_color * detail * 0.50;

    // Reimagined crystal-clear transparency
    float base_alpha = clamp(0.10 + 0.55 * water_fog, 0.0, 0.75);
    base_alpha += detail * 0.12; // Wave crests are slightly more visible
    float fresnel4 = fresnel * fresnel * fresnel * fresnel;
    float alpha = mix(base_alpha, 0.95, fresnel4 * 0.85);

    if (is_eye_in_water) {
        alpha = 0.40;
    }

    // Soft, controlled vanilla highlight (no blinding overexposure)
    out_vanilla_highlight = vec3(0.12, 0.18, 0.25) * detail * (0.2 + 0.8 * skylight);

    return vec4(absorbed_col, alpha);
}

// Complementary Reimagined edge foam
vec4 apply_complementary_water_foam(
    vec4 current_color,
    float water_depth_dist,
    float skylight,
    vec3 world_pos
) {
#ifdef WATER_FOAM
    if (water_depth_dist < 0.35) {
        float foam_threshold = 0.28;
        float foam = pow(clamp((foam_threshold - water_depth_dist) / foam_threshold, 0.0, 1.0), 2.0);
        foam *= (0.35 + 0.35 * skylight);
        
        // World noise pattern to break up uniform foam lines
        float noise_val = texture(gaux4, world_pos.xz * 0.15).b;
        foam *= smoothstep(0.2, 0.6, noise_val);

        vec4 foam_color = vec4(0.90, 0.94, 0.98, 0.90);
        current_color = mix(current_color, foam_color, foam * 0.8);
    }
#endif
    return current_color;
}

#endif // INCLUDE_SURFACE_WATER_COMPLEMENTARY
