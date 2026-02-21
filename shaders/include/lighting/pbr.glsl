/*
================================================================================
  OffShades — include/lighting/pbr.glsl
  GGX PBR BRDF: diffuse (Burley), specular (GGX), Fresnel (Schlick).
================================================================================
*/

#ifndef PBR_INCLUDED
#define PBR_INCLUDED

#include "/include/utility/math.glsl"

// ─── GGX Normal Distribution Function ───────────────────────────────────────
float ggx_ndf(float NoH, float roughness) {
    float a  = roughness * roughness;
    float a2 = a * a;
    float d  = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (PI * d * d + 1e-6);
}

// ─── Smith GGX Geometry Term (Height-Correlated, Lagarde 2014) ──────────────
float ggx_smith(float NoL, float NoV, float roughness) {
    float a2  = roughness * roughness * roughness * roughness;
    float gv  = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float gl  = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / (gv + gl + 1e-6);
}

// ─── Fresnel (Schlick) ───────────────────────────────────────────────────────
vec3 fresnel_schlick(vec3 f0, float cosTheta) {
    float fc = pow5(1.0 - cosTheta);
    return f0 + (1.0 - f0) * fc;
}

// Fresnel with roughness attenuation (for ambient/indirect Fresnel)
vec3 fresnel_schlick_roughness(vec3 f0, float cosTheta, float roughness) {
    vec3 r   = vec3(1.0 - roughness);
    float fc = pow5(1.0 - cosTheta);
    return f0 + (max(r, f0) - f0) * fc;
}

// ─── Burley Diffuse BRDF ─────────────────────────────────────────────────────
float burley_diffuse(float NoL, float NoV, float LoH, float roughness) {
    float fd90 = 0.5 + 2.0 * LoH * LoH * roughness;
    float fl   = 1.0 + (fd90 - 1.0) * pow5(1.0 - NoL);
    float fv   = 1.0 + (fd90 - 1.0) * pow5(1.0 - NoV);
    return fl * fv * INV_PI;
}

// ─── Specular BRDF (GGX Cook-Torrance) ──────────────────────────────────────
// Returns the specular contribution ONLY (without Fresnel applied outside)
vec3 specular_brdf(float NoL, float NoV, float NoH, float LoH, float roughness, vec3 f0) {
    float D   = ggx_ndf(NoH, max(roughness, 0.002));
    float G   = ggx_smith(NoL, NoV, max(roughness, 0.002));
    vec3  F   = fresnel_schlick(f0, LoH);
    return D * G * F;
}

// ─── Full direct lighting BRDF ───────────────────────────────────────────────
// Returns (diffuse, specular) contributions for a single direct light.
// albedo    : linear albedo
// f0        : specular base reflectance (from metalness/F0 map)
// roughness : perceptual roughness
// metalness : 0=dielectric, 1=metal
// L, V, N   : light direction, view direction, normal (all in same space)
struct BRDFResult {
    vec3 diffuse;
    vec3 specular;
};

BRDFResult evaluate_brdf(
    vec3  albedo,
    vec3  f0,
    float roughness,
    float metalness,
    vec3  L,
    vec3  V,
    vec3  N
) {
    vec3  H   = normalize(L + V);
    float NoL = max(dot(N, L), 0.0);
    float NoV = max(dot(N, V), 1e-4);
    float NoH = max(dot(N, H), 0.0);
    float LoH = max(dot(L, H), 0.0);

    vec3 F     = fresnel_schlick(f0, LoH);
    float D    = ggx_ndf(NoH, max(roughness * roughness, 0.002));
    float G    = ggx_smith(NoL, NoV, max(roughness * roughness, 0.002));

    vec3 spec  = D * G * F;
    vec3 diff  = (1.0 - F) * (1.0 - metalness) * albedo * burley_diffuse(NoL, NoV, LoH, roughness * roughness) * PI;

    BRDFResult result;
    result.diffuse  = diff;
    result.specular = spec;
    return result;
}

// ─── Dielectric F0 from IOR ───────────────────────────────────────────────────
vec3 ior_to_f0(float ior) {
    float r = (ior - 1.0) / (ior + 1.0);
    return vec3(r * r);
}

#endif // PBR_INCLUDED
