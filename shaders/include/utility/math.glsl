/*
================================================================================
  OffShades — include/utility/math.glsl
  Math helpers: hash, noise, easing, geometry utilities.
================================================================================
*/

#ifndef UTILITY_MATH_INCLUDED
#define UTILITY_MATH_INCLUDED

// ============================================================
//   Hash Functions
// ============================================================

float hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash1(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float hash1(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453123);
}

vec3 hash3(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return fract(sin(p) * 43758.5453123);
}

// IGN (Interleaved Gradient Noise) — good for temporal sampling
float ign(vec2 coord) {
    return fract(52.9829189 * fract(0.06711056 * coord.x + 0.00583715 * coord.y));
}

// Blue noise sample from noise texture
float blue_noise(vec2 coord, sampler2D noise_tex) {
    return texelFetch(noise_tex, ivec2(coord) & 511, 0).r;
}

// ============================================================
//   Value Noise
// ============================================================

float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f); // smooth

    float a = hash1(i);
    float b = hash1(i + vec2(1.0, 0.0));
    float c = hash1(i + vec2(0.0, 1.0));
    float d = hash1(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float value_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);

    float a000 = hash1(i);
    float a100 = hash1(i + vec3(1, 0, 0));
    float a010 = hash1(i + vec3(0, 1, 0));
    float a110 = hash1(i + vec3(1, 1, 0));
    float a001 = hash1(i + vec3(0, 0, 1));
    float a101 = hash1(i + vec3(1, 0, 1));
    float a011 = hash1(i + vec3(0, 1, 1));
    float a111 = hash1(i + vec3(1, 1, 1));

    return mix(
        mix(mix(a000, a100, u.x), mix(a010, a110, u.x), u.y),
        mix(mix(a001, a101, u.x), mix(a011, a111, u.x), u.y),
        u.z
    );
}

// Fractional Brownian Motion (fBm) 
float fbm(vec2 p, int octaves) {
    float val = 0.0, amp = 0.5, freq = 1.0;
    for (int i = 0; i < octaves; ++i) {
        val  += amp * value_noise(p * freq);
        freq *= 2.0;
        amp  *= 0.5;
    }
    return val;
}

// Curl noise (from gradient of value noise, useful for clouds)
vec2 curl_noise(vec2 p) {
    const float eps = 0.001;
    float nx = value_noise(p + vec2(eps, 0.0)) - value_noise(p - vec2(eps, 0.0));
    float ny = value_noise(p + vec2(0.0, eps)) - value_noise(p - vec2(0.0, eps));
    return vec2(ny, -nx) * (1.0 / (2.0 * eps));
}

// ============================================================
//   Easing / Smoothing
// ============================================================

float smoothstep3(float t) { return t * t * (3.0 - 2.0 * t); }
float smoothstep5(float t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }

// Smooth maximum/minimum (softmax)
float smax(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return max(a, b) + h * h * k * 0.25;
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// ============================================================
//   Geometry Helpers
// ============================================================

// Reconstruct view-space position from depth
vec3 view_pos_from_depth(vec2 uv, float depth, mat4 proj_inv) {
    vec4 ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view = proj_inv * ndc;
    return view.xyz / view.w;
}

// Reconstruct world-space position from view-space
vec3 world_pos_from_view(vec3 view_pos, mat4 mv_inv) {
    return (mv_inv * vec4(view_pos, 1.0)).xyz;
}

// Ray-sphere intersection (returns tNear, tFar; negative = no hit)
vec2 ray_sphere(vec3 ro, vec3 rd, float r) {
    float b = dot(ro, rd);
    float d = b * b - dot(ro, ro) + r * r;
    if (d < 0.0) return vec2(-1.0);
    float sq = sqrt(d);
    return vec2(-b - sq, -b + sq);
}

// Ray-box intersection (AABB)
vec2 ray_box(vec3 ro, vec3 inv_rd, vec3 bmin, vec3 bmax) {
    vec3 t0 = (bmin - ro) * inv_rd;
    vec3 t1 = (bmax - ro) * inv_rd;
    vec3 tmin = min(t0, t1);
    vec3 tmax = max(t0, t1);
    float tn = max(max(tmin.x, tmin.y), tmin.z);
    float tf = min(min(tmax.x, tmax.y), tmax.z);
    return vec2(tn, tf);
}

// Rotation matrix around Y axis
mat2 rotate2d(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

// ============================================================
//   Phase Functions
// ============================================================

// Henyey-Greenstein phase function (g = anisotropy, -1..1)
float hg_phase(float cos_theta, float g) {
    float g2 = g * g;
    return (1.0 - g2) / (4.0 * PI * pow(1.0 + g2 - 2.0 * g * cos_theta, 1.5));
}

// Cornette-Shanks improved phase (more accurate for forward scattering)
float cs_phase(float cos_theta, float g) {
    float g2 = g * g;
    float denom = 1.0 + g2 - 2.0 * g * cos_theta;
    return (3.0 / 2.0) * ((1.0 - g2) / (2.0 + g2)) * (1.0 + cos_theta * cos_theta) / pow(denom, 1.5);
}

// Draine (dual; sun forward + back)
float draine_phase(float cos_theta, float g, float d) {
    return mix(hg_phase(cos_theta, g), hg_phase(cos_theta, -g * d), 0.5);
}

#endif // UTILITY_MATH_INCLUDED
