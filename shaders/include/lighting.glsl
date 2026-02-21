// ── Shared Lighting Functions ─────────────────────────────────────────────────

// ── Sky-color ambient (matches gbuffers_skybasic palette) ─────────────────────
vec3 skyAmbientColor(float sunHeight) {
    float dayFactor     = smoothstep(-0.10, 0.25, sunHeight);
    float sunriseFactor = pow(max(1.0 - abs(sunHeight) * 3.0, 0.0), 2.0);

    vec3 nightAmb  = vec3(0.04, 0.05, 0.10);
    vec3 dayAmb    = vec3(0.45, 0.58, 0.85);
    vec3 sunsetAmb = vec3(0.80, 0.42, 0.18);

    vec3 base = mix(nightAmb, dayAmb, dayFactor);
    return mix(base, sunsetAmb, sunriseFactor * dayFactor);
}

vec3 sunColor(float sunHeight) {
    float dayFactor     = smoothstep(-0.05, 0.25, sunHeight);
    float sunriseFactor = pow(max(1.0 - abs(sunHeight) * 4.0, 0.0), 2.0);

    vec3 nightCol   = vec3(0.50, 0.55, 0.75);
    vec3 dayCol     = vec3(1.00, 0.97, 0.90);
    vec3 sunsetCol  = vec3(1.00, 0.60, 0.20);

    vec3 base = mix(nightCol, dayCol, dayFactor);
    return mix(base, sunsetCol, sunriseFactor * dayFactor);
}

// ── Schlick's approximation for Fresnel ───────────────────────────────────────
float calculateFresnel(vec3 viewDir, vec3 normal, float f0) {
    float cosTheta = clamp(dot(viewDir, normal), 0.0, 1.0);
    return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
}
