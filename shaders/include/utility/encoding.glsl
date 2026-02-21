/*
================================================================================
  OffShades — include/utility/encoding.glsl
  Gbuffer data packing: normals, material IDs, roughness, metalness, emission.
================================================================================
*/

#ifndef UTILITY_ENCODING_INCLUDED
#define UTILITY_ENCODING_INCLUDED

// ============================================================
//   Normal Encoding (Octahedral)
// ============================================================

// Encodes a unit normal into a vec2 in [-1, 1] (octahedral projection)
vec2 encode_normal(vec3 n) {
    float l1 = abs(n.x) + abs(n.y) + abs(n.z);
    n /= l1;
    if (n.z < 0.0) {
        vec2 s = sign(n.xy) * max(abs(n.xy), 1e-8);
        n.xy = (1.0 - abs(n.yx)) * s;
    }
    return n.xy;
}

// Decodes octahedral normal back to unit vec3
vec3 decode_normal(vec2 e) {
    vec3 n = vec3(e.xy, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) {
        n.xy = (1.0 - abs(n.yx)) * sign(n.xy);
    }
    return normalize(n);
}

// ============================================================
//   Material Data Packing
// ============================================================

// colortex2 layout (rgba):
//   r: encoded normal x (0..1, remapped from -1..1)
//   g: encoded normal y
//   b: material ID (packed 8-bit integer)
//   a: ao (from vertex / vanilla AO)

vec4 pack_gbuffer2(vec3 normal, float mat_id, float ao) {
    vec2 enc = encode_normal(normal) * 0.5 + 0.5;
    return vec4(enc, mat_id / 255.0, ao);
}

void unpack_gbuffer2(vec4 data, out vec3 normal, out float mat_id, out float ao) {
    normal = decode_normal(data.xy * 2.0 - 1.0);
    mat_id = data.z * 255.0;
    ao     = data.w;
}

// colortex3 layout (rgba):
//   r: roughness
//   g: metalness
//   b: F0 (specular intensity, 0 = non-metal default, >0.5 = conductor)
//   a: emission (normalized, 0 = none)

vec4 pack_gbuffer3(float roughness, float metalness, float f0, float emission) {
    return vec4(roughness, metalness, f0, emission);
}

void unpack_gbuffer3(vec4 data, out float roughness, out float metalness, out float f0, out float emission) {
    roughness = data.r;
    metalness = data.g;
    f0        = data.b;
    emission  = data.a;
}

// ============================================================
//   Material IDs
// ============================================================

#define MAT_DEFAULT      0.0
#define MAT_WATER        1.0
#define MAT_LEAVES       2.0
#define MAT_PLANTS       3.0
#define MAT_GLASS        4.0
#define MAT_ICE          5.0
#define MAT_SNOW         6.0
#define MAT_EMISSIVE     7.0
#define MAT_ENTITY       8.0
#define MAT_HAND         9.0
#define MAT_NETHER_LAVA  10.0
#define MAT_END_STONE    11.0
#define MAT_METAL        12.0
#define MAT_STONE        13.0
#define MAT_SAND         14.0

bool is_water(float mat_id)   { return abs(mat_id - MAT_WATER) < 0.5; }
bool is_leaves(float mat_id)  { return abs(mat_id - MAT_LEAVES) < 0.5; }
bool is_plants(float mat_id)  { return abs(mat_id - MAT_PLANTS) < 0.5; }
bool is_glass(float mat_id)   { return abs(mat_id - MAT_GLASS) < 0.5; }
bool is_emissive(float mat_id){ return abs(mat_id - MAT_EMISSIVE) < 0.5; }

// ============================================================
//   Depth Encoding
// ============================================================

// Linear depth from NDC depth
float linearize_depth(float depth, float z_near, float z_far) {
    return 2.0 * z_near * z_far / (z_far + z_near - (depth * 2.0 - 1.0) * (z_far - z_near));
}

// Linear depth from projection matrix (faster)
float linearize_depth_fast(float depth, float proj22, float proj32) {
    return -proj32 / (depth * 2.0 - 1.0 + proj22);
}

// View-space Z from non-linear depth
float view_z_from_depth(float depth, mat4 proj_inv) {
    float ndc_z = depth * 2.0 - 1.0;
    return -proj_inv[3][2] / (ndc_z + proj_inv[2][2]);
}

// ============================================================
//   Dithering
// ============================================================

// 4x4 Bayer matrix dithering
float bayer4x4(ivec2 coord) {
    const int bayer[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
    return float(bayer[(coord.x & 3) + (coord.y & 3) * 4]) / 16.0;
}

float bayer8x8(ivec2 coord) {
    float b = bayer4x4(coord >> 1);
    float s = bayer4x4(coord & 3);
    return (b + s * 0.25) * (16.0 / 64.0);
}

#endif // UTILITY_ENCODING_INCLUDED


