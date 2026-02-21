/*
================================================================================
  OffShades — include/surface/waving.glsl
  Vertex-shader waving animation for plants, leaves, and other geometry.
  Adapted from Photon Shaders by Sixthsurge.
================================================================================
*/

#ifndef WAVING_INCLUDED
#define WAVING_INCLUDED

#include "/include/utility/math.glsl"

// ─── Material IDs for waving blocks ────────────────────────────────────────
// These must match the IDs set in block.properties mc_Entity flags.
#define MATERIAL_TALL_PLANT   10001
#define MATERIAL_SHORT_PLANT  10002
#define MATERIAL_LEAVES       10003
#define MATERIAL_CROPS        10004
#define MATERIAL_HANGING_VINE 10005

// ─── Waving amplitude multipliers ──────────────────────────────────────────
#define WAVING_SPEED      1.0   // Global speed multiplier
#define PLANT_AMPLITUDE   0.06  // Side displacement amplitude for tall plants
#define LEAVES_AMPLITUDE  0.04  // Amplitude for leaves
#define CROP_AMPLITUDE    0.03  // Amplitude for crops

// ─── Wind direction (normalized) ────────────────────────────────────────────
// Use a slow rotating wind direction driven by world time
vec2 get_wind_dir(float time) {
    float angle = time * 0.0003;
    return normalize(vec2(cos(angle), sin(angle)));
}

// ─── Per-block random offset ─────────────────────────────────────────────────
// Avoids all plants moving in perfect sync.
float block_random(vec3 world_pos) {
    return hash13(floor(world_pos));
}

// ─── Main waving function ────────────────────────────────────────────────────
// Call from the vertex shader; returns a world-space position offset.
// entity_id    : mc_Entity.x from the vertex
// world_pos    : vertex world position (vaPosition + cameraPosition or similar)
// uv_y         : texture UV y (used to pin the bottom of tall grass in place)
vec3 waving_offset(int entity_id, vec3 world_pos, float uv_y) {
    vec3 offset = vec3(0.0);

#ifdef WAVING_PLANTS
    bool is_tall_plant  = (entity_id == MATERIAL_TALL_PLANT);
    bool is_short_plant = (entity_id == MATERIAL_SHORT_PLANT);
    bool is_crop        = (entity_id == MATERIAL_CROPS);
    bool is_vine        = (entity_id == MATERIAL_HANGING_VINE);

    if (is_tall_plant || is_short_plant || is_crop || is_vine) {
        float time  = frameTimeCounter * WAVING_SPEED;
        float rnd   = block_random(world_pos);
        vec2  wind  = get_wind_dir(frameTimeCounter) * (0.6 + 0.4 * rnd);

        // Amplitude: 0 at vertex bottom (uv_y ≈ 0.0 for the pinned bottom)
        // For standard foliage UVs, uv_y increases upward so bottom is pinned.
        float pin = is_tall_plant ? uv_y : 1.0;

        float amplitude = is_tall_plant  ? PLANT_AMPLITUDE :
                          is_crop        ? CROP_AMPLITUDE  :
                                           PLANT_AMPLITUDE * 0.7;

        float wave = sin(time * 2.3 + rnd * TAU + world_pos.x * 1.1 + world_pos.z * 1.3);
        wave += 0.4 * sin(time * 4.1 + rnd * TAU + world_pos.x + world_pos.z);

        offset.xz += wind * wave * amplitude * pin;

        // Small vertical bob
        offset.y += 0.01 * sin(time * 1.7 + rnd * TAU) * pin;
    }
#endif

#ifdef WAVING_LEAVES
    bool is_leaves = (entity_id == MATERIAL_LEAVES);

    if (is_leaves) {
        float time = frameTimeCounter * WAVING_SPEED;
        float rnd  = block_random(world_pos);
        vec2  wind = get_wind_dir(frameTimeCounter) * (0.5 + 0.5 * rnd);

        float wave  = sin(time * 1.8 + rnd * TAU + world_pos.x * 0.7 + world_pos.z * 0.7);
        wave += 0.3 * sin(time * 3.6 + rnd * TAU);

        offset.xz += wind * wave * LEAVES_AMPLITUDE;
        offset.y  += 0.005 * wave;
    }
#endif

    return offset;
}

#endif // WAVING_INCLUDED
