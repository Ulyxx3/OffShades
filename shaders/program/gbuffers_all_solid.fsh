/*
--------------------------------------------------------------------------------

  Photon Shader by SixthSurge

  program/gbuffers_all_solid:
  Handle terrain, entities, the hand, beacon beams and spider eyes

--------------------------------------------------------------------------------
*/

#include "/include/global.glsl"

layout(
    location = 0
) out vec4 gbuffer_data_0; // albedo, block ID, flat normal, light levels
layout(
    location = 1
) out vec4 gbuffer_data_1; // detailed normal, specular map (optional)

/* RENDERTARGETS: 1 */

#ifdef NORMAL_MAPPING
/* RENDERTARGETS: 1,2 */
#endif

#ifdef SPECULAR_MAPPING
/* RENDERTARGETS: 1,2 */
#endif

in vec2 uv;
in vec2 light_levels;
in vec3 scene_pos;
in vec4 tint;

flat in uint material_mask;
flat in mat3 tbn;

#if defined POM
in vec2 atlas_tile_coord;
in vec3 tangent_pos;
flat in vec2 atlas_tile_offset;
flat in vec2 atlas_tile_scale;
#endif

#if defined PROGRAM_GBUFFERS_TERRAIN
in float vanilla_ao;
#endif

#if defined PROGRAM_GBUFFERS_ENTITIES || defined PROGRAM_GBUFFERS_HAND
in vec2 uv_local;
#endif

// ------------
//   Uniforms
// ------------

uniform sampler2D noisetex;

uniform sampler2D gtexture;

#if defined NORMAL_MAPPING || defined POM
uniform sampler2D normals;
#endif

#if defined SPECULAR_MAPPING
uniform sampler2D specular;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec3 cameraPosition;

uniform float near;
uniform float far;

uniform int frameCounter;
uniform float frameTimeCounter;

uniform vec2 view_res;
uniform vec2 view_pixel_size;
uniform vec2 taa_offset;

uniform vec3 light_dir;

#if defined PROGRAM_GBUFFERS_ENTITIES
uniform int entityId;
uniform vec4 entityColor;
#endif

#if defined PROGRAM_GBUFFERS_PARTICLES
#define NO_NORMAL
#endif

#if defined PROGRAM_GBUFFERS_TERRAIN && defined POM
#include "/include/surface/parallax.glsl"
#endif

#ifdef DIRECTIONAL_LIGHTMAPS
#include "/include/lighting/directional_lightmaps.glsl"
#endif

#include "/include/misc/material_fix.glsl"
#include "/include/misc/material_masks.glsl"
#include "/include/utility/dithering.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/fast_math.glsl"
#include "/include/utility/random.glsl"
#include "/include/utility/space_conversion.glsl"

#if defined PROGRAM_GBUFFERS_TERRAIN && defined POM
#define read_tex(x) textureGrad(x, parallax_uv, uv_gradient[0], uv_gradient[1])
#else
#define read_tex(x) texture(x, uv, lod_bias)
#endif

#if TEXTURE_FORMAT == TEXTURE_FORMAT_LAB
void decode_normal_map(vec3 normal_map, out vec3 normal, out float ao) {
    normal.xy = normal_map.xy * 2.0 - 1.0;
    normal.z = sqrt(clamp01(1.0 - dot(normal.xy, normal.xy)));
    ao = normal_map.z;
}
#elif TEXTURE_FORMAT == TEXTURE_FORMAT_OLD
void decode_normal_map(vec3 normal_map, out vec3 normal, out float ao) {
    normal = normal_map * 2.0 - 1.0;
    ao = length(normal);
    normal *= rcp(ao);
}
#endif

#if defined PROGRAM_GBUFFERS_BLOCK
vec3 draw_end_portal() {
    const int layer_count = 8; // Number of layers
    const float depth_scale = 0.33; // Apparent distance between layers
    const float depth_fade = 0.5; // How quickly the layers fade to black
    const float threshold =
        0.99; // Threshold for the "stars". Lower values mean more stars appear
    const float twinkle_speed = 0.4; // How fast the stars appear to twinkle
    const float twinkle_amount = 0.04; // How many twinkling stars appear
    const vec3 color0 = pow(vec3(0.80, 0.90, 0.99), vec3(2.2));
    const vec3 color1 = pow(vec3(0.75, 0.40, 0.93), vec3(2.2));
    const vec3 color2 = pow(vec3(0.20, 0.70, 0.90), vec3(2.2));

    vec3 screen_pos = vec3(
        gl_FragCoord.xy * view_pixel_size * rcp(taau_render_scale),
        gl_FragCoord.z
    );
    vec3 view_pos = screen_to_view_space(screen_pos, true);
    vec3 scene_pos = view_to_scene_space(view_pos);

    vec3 world_pos = scene_pos + cameraPosition;
    vec3 world_dir = normalize(scene_pos - gbufferModelViewInverse[3].xyz);

    // Get tangent-space position/direction without tangent/bitangent

    vec2 tangent_pos, tangent_dir;
    if (abs(tbn[2].x) > 0.5) {
        tangent_pos = world_pos.yz;
        tangent_dir = world_dir.yz / abs(world_dir.x + eps);
    } else if (abs(tbn[2].y) > 0.5) {
        tangent_pos = world_pos.xz;
        tangent_dir = world_dir.xz / abs(world_dir.y + eps);
    } else {
        tangent_pos = world_pos.xy;
        tangent_dir = world_dir.xy / abs(world_dir.z + eps);
    }

    vec3 result = vec3(0.0);

    for (int i = 0; i < layer_count; ++i) {
        // Random layer offset
        vec2 layer_offset = r2(i) * 512.0;

        // Make layers drift over time
        float angle = i * golden_angle;
        vec2 drift =
            0.033 * vec2(cos(angle), sin(angle)) * frameTimeCounter * r1(i);

        // Snap tangent_pos to a grid and calculate a seed for the RNG
        ivec2 grid_pos = ivec2((tangent_pos + drift) * 32.0 + layer_offset);
        uint seed = uint(80000 * grid_pos.y + grid_pos.x);

        // 4 random numbers for this grid cell
        vec4 random = rand_next_vec4(seed);

        // Twinkling animation
        float twinkle_offset = tau * random.w;
        random.x *= 1.0 -
            twinkle_amount *
                cos(frameTimeCounter * twinkle_speed + twinkle_offset);

        // Stomp all values below threshold to zero
        float intensity = pow8(linear_step(threshold, 1.0, random.x));

        // Blend between the 3 colors
        vec3 color = mix(color0, color1, random.y);
        color = mix(color, color2, random.z);

        // Fade away with depth
        float fade = exp2(-depth_fade * float(i));

        result += color * intensity *
            exp2(-3.0 * (1.0 - fade) * (1.0 - color)) * fade;

        // Step along the view ray
        tangent_pos +=
            tangent_dir * depth_scale * gbufferProjection[1][1] * rcp(1.37);

        if (random.x > threshold) {
            break;
        }
    }

    result *= 0.8;
    result = sqrt(result);
    result *= sqrt(result);

    return result;
}
#endif

const float lod_bias = log2(taau_render_scale);

void main() {
#if defined TAA && defined TAAU
    vec2 coord = gl_FragCoord.xy * view_pixel_size * rcp(taau_render_scale);
    if (clamp01(coord) != coord) {
        discard;
        return;
    }
#endif

    bool parallax_shadow = false;
    float dither = interleaved_gradient_noise(gl_FragCoord.xy, frameCounter);

#if defined PROGRAM_GBUFFERS_TERRAIN && defined POM
    float view_distance = length(tangent_pos);

    bool has_pom =
        view_distance < POM_DISTANCE; // Only calculate POM for close terrain
    has_pom = has_pom &&
        material_mask !=
            MATERIAL_LAVA; // Do not calculate POM for water or lava

    vec3 tangent_dir = -normalize(tangent_pos);
    mat2 uv_gradient = mat2(dFdx(uv), dFdy(uv));

    vec2 parallax_uv;

    if (has_pom) {
        float pom_depth;
        vec3 shadow_trace_pos;

        parallax_uv = get_parallax_uv(
            tangent_dir,
            uv_gradient,
            view_distance,
            dither,
            shadow_trace_pos,
            pom_depth
        );
#ifdef POM_SHADOW
        if (dot(tbn[2], light_dir) >= eps) {
            parallax_shadow = get_parallax_shadow(
                shadow_trace_pos,
                uv_gradient,
                view_distance,
                dither
            );
        } else {
            parallax_shadow = false;
        }
#endif
    } else {
        parallax_uv = uv;
        parallax_shadow = false;
    }
#endif

    //--//

    vec4 base_color = read_tex(gtexture) * tint;

    if (material_mask == MATERIAL_LAVA) {
        vec3 world_pos = scene_pos + cameraPosition;
        vec3 world_normal = tbn[2];
        float is_vertical_flow = clamp01(1.0 - abs(world_normal.y) * 1.25);

        // 1. Onde macroscopique à très basse fréquence (brise la monotonie des grands lacs)
        // Crée de vastes fleuves thermiques et des méandres doux sans couture
        vec2 macro_flow = vec2(-frameTimeCounter * 0.025, frameTimeCounter * 0.018);
        float macro_n1 = texture(noisetex, (world_pos.xz + macro_flow) * 0.006).r;
        float macro_n2 = texture(noisetex, (world_pos.zx * 1.4 - macro_flow * 0.8) * 0.008).r;
        float macro_heat = smoothstep(0.28, 0.72, macro_n1 * 0.6 + macro_n2 * 0.4);

        // 2. Courants méso croisés continus dans le monde (aucun découpage par bloc)
        vec2 lava_pos = (world_pos.xz + world_pos.xy + world_pos.zy) * 0.5;
        lava_pos.x *= 0.5;

        vec2 flow1 = vec2(-frameTimeCounter * 0.09, frameTimeCounter * 0.04);
        vec2 flow2 = vec2(frameTimeCounter * 0.05, frameTimeCounter * 0.10);

        if (is_vertical_flow > 0.2) {
            flow1.y -= frameTimeCounter * 0.16;
            flow2.y -= frameTimeCounter * 0.18;
        }

        float freq_mult = mix(1.0, 1.8, is_vertical_flow);
        vec2 uv1 = (lava_pos + flow1) * (0.028 * freq_mult);
        vec2 uv2 = (lava_pos.yx * 1.4 + flow2) * (0.025 * freq_mult);

        float n1 = texture(noisetex, uv1).r;
        float n2 = texture(noisetex, uv2).r;

        float wave1 = texture(noisetex, uv1 + vec2(n2 * 0.28, -n2 * 0.22)).r;
        float wave2 = texture(noisetex, uv2 + vec2(-n1 * 0.22, n1 * 0.28)).r;

        float meso_flow = mix(wave1, wave2, 0.50 + 0.30 * sin(frameTimeCounter * 0.12 + lava_pos.x * 0.04));

        // 3. Texture animée vanilla de Minecraft (détails par pixel)
        float vanilla_luma = clamp01(dot(base_color.rgb, vec3(0.299, 0.587, 0.114)));

        // 4. Combinaison fluide et continue
        float wave_t = smoothstep(0.22, 0.72, meso_flow);
        float pixel_t = smoothstep(0.18, 0.80, vanilla_luma);

        // Dynamique globale modulée par l'onde macroscopique
        float raw_t = clamp01(0.42 * wave_t + 0.38 * pixel_t + 0.20 * macro_heat);
        float t = mix(mix(0.20, 0.85, raw_t), raw_t, mix(0.40, 1.0, is_vertical_flow));

        // Palette de lave incandescente
        vec3 dark_lava   = vec3(0.64, 0.11, 0.005); // Sombre fluide
        vec3 mid_lava    = vec3(0.98, 0.36, 0.015); // Orange vif
        vec3 bright_lava = vec3(1.00, 0.60, 0.040); // Crête dorée

        vec3 magma_color = mix(dark_lava, mid_lava, smoothstep(0.12, 0.52, t));
        magma_color = mix(magma_color, bright_lava, smoothstep(0.48, 0.88, t));

        // Articulation finale des pixels animés
        base_color.rgb = clamp01(magma_color * (0.68 + 0.48 * vanilla_luma));
    }
#ifdef NORMAL_MAPPING
    vec3 normal_map = read_tex(normals).xyz;
#endif
#ifdef SPECULAR_MAPPING
    vec4 specular_map = read_tex(specular);
#endif

#if defined PROGRAM_GBUFFERS_ENTITIES
    if (material_mask == MATERIAL_LIGHTNING_BOLT) {
        base_color = vec4(1.0);
    }
    if (base_color.a < 0.1 && material_mask != MATERIAL_BOAT) {
        discard;
        return;
    } // Save transparent quad in boats, which masks out water
#elif !defined PROGRAM_GBUFFERS_TERRAIN_SOLID
    if (base_color.a < 0.1) {
        discard;
        return;
    }
#endif

#if (defined PROGRAM_GBUFFERS_BLOCK || defined PROGRAM_GBUFFERS_ENTITIES || \
     defined PROGRAM_GBUFFERS_HAND) && \
    !(defined USE_SEPARATE_ENTITY_DRAWS && defined IS_IRIS)
#ifdef DITHERED_TRANSLUCENCY_FALLBACK
    // Dithered transparency for translucent objects rendered as solid
    float dither_pattern =
        r1(frameCounter,
           texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 511, 0).z);
    if (base_color.a < dither_pattern) {
        discard;
        return;
    }
#endif
#endif

#ifdef WHITE_WORLD
    base_color.rgb = vec3(1.0);
#endif

#if defined PROGRAM_GBUFFERS_TERRAIN && defined VANILLA_AO
#if SHADER_AO != SHADER_AO_NONE
    const float vanilla_ao_strength = 0.9;
    const float vanilla_ao_lift = 0.5;
#else
    const float vanilla_ao_strength = 1.0;
    const float vanilla_ao_lift = 0.0;
#endif

    base_color.rgb *= lift(vanilla_ao, vanilla_ao_lift) * vanilla_ao_strength +
        (1.0 - vanilla_ao_strength);
#endif

#if defined PROGRAM_GBUFFERS_ENTITIES
    base_color.rgb = mix(base_color.rgb, entityColor.rgb, entityColor.a);
#endif

#if defined PROGRAM_GBUFFERS_BLOCK
    // parallax end portal
    if (material_mask == MATERIAL_END_PORTAL) {
        base_color.rgb = draw_end_portal();
    }
#endif

#if defined PROGRAM_GBUFFERS_BEACONBEAM
    // Discard the translucent edge part of the beam
    if (base_color.a < 0.5) {
        discard;
    }
#endif

    vec2 adjusted_light_levels = light_levels;

#ifdef NORMAL_MAPPING
    vec3 normal;
    float material_ao;
    decode_normal_map(normal_map, normal, material_ao);

    normal = tbn * normal;

    adjusted_light_levels *= mix(0.7, 1.0, material_ao);

#ifdef DIRECTIONAL_LIGHTMAPS
    adjusted_light_levels *= get_directional_lightmaps(scene_pos, normal);
#endif
#endif

#if defined NO_NORMAL
    // No normal vector => make one from screen-space partial derivatives
    vec3 particle_normal = normalize(cross(dFdx(scene_pos), dFdy(scene_pos)));
#define flat_normal particle_normal
#define detailed_normal particle_normal
#else
#define flat_normal tbn[2]
#define detailed_normal normal
#endif

#if defined PROGRAM_GBUFFERS_ENTITIES || defined PROGRAM_GBUFFERS_HAND
    uint new_material_mask = fix_material_mask();
#define material_mask new_material_mask
#endif

    gbuffer_data_0.x = pack_unorm_2x8(base_color.rg);
    gbuffer_data_0.y = pack_unorm_2x8(
        base_color.b,
        clamp01(float(material_mask) * rcp(255.0))
    );
    gbuffer_data_0.z = pack_unorm_2x8(encode_unit_vector(flat_normal));
    gbuffer_data_0.w =
        pack_unorm_2x8(dither_8bit(adjusted_light_levels, dither));

#ifdef NORMAL_MAPPING
    gbuffer_data_1.xy = encode_unit_vector(detailed_normal);
#endif

#ifdef SPECULAR_MAPPING
#if defined POM && defined POM_SHADOW
    // Pack parallax shadow in alpha component of specular map
    // Specular map alpha >= 0.5 => parallax shadow
    specular_map.a *= step(specular_map.a, 0.999);
    specular_map.a =
        clamp01(specular_map.a * 0.5 + 0.5 * float(parallax_shadow));
#endif

    gbuffer_data_1.z = pack_unorm_2x8(specular_map.xy);
    gbuffer_data_1.w = pack_unorm_2x8(specular_map.zw);
#else
#if defined POM && defined POM_SHADOW
    gbuffer_data_1.z = float(parallax_shadow);
#endif
#endif

#if defined PROGRAM_GBUFFERS_PARTICLES
    // Kill the little rain splash particles
    if (base_color.r < 0.29 && base_color.g < 0.45 && base_color.b > 0.75) {
        discard;
    }
#endif
}
