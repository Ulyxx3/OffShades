// ── Variable Penumbra Shadows (PCSS) ──────────────────────────────────────────

const vec2 POISSON_8[8] = vec2[](
    vec2( 0.490,  0.718), vec2( 0.444, -0.669),
    vec2(-0.767,  0.584), vec2(-0.468, -0.766),
    vec2(-0.887, -0.191), vec2( 0.812,  0.180),
    vec2(-0.110, -0.218), vec2(-0.021,  0.373)
);

float getShadow(sampler2D shadowMap, vec3 shadowCoords, float geoFactor, float dither) {
    if (geoFactor < 0.001) return 0.0;
    
    if (any(lessThan(shadowCoords, vec3(0.0))) || any(greaterThan(shadowCoords, vec3(1.0)))) {
        return geoFactor;
    }

    float angle     = dither * 6.2831853;
    float s         = sin(angle);
    float c         = cos(angle);
    mat2  rot       = mat2(c, -s, s, c);

    const float BIAS = 0.0002;
    float receiverDepth = shadowCoords.z - BIAS;
    
    // 1. Blocker Search
    float searchRadius = 2.0 / 8192.0;
    float blockerSum = 0.0;
    float blockers = 0.0;

    for (int i = 0; i < 8; i++) {
        vec2 off = rot * POISSON_8[i] * searchRadius;
        float z = texture(shadowMap, shadowCoords.xy + off).r;
        if (z < receiverDepth) {
            blockerSum += z;
            blockers += 1.0;
        }
    }

    // Totally unshadowed by geometry in frustum
    if (blockers < 0.5) {
        float inLight = 1.0;
        // Smooth fade at shadow frustum edge
        vec2  edgeDist = 1.0 - abs(shadowCoords.xy * 2.0 - 1.0);
        float edgeFade = smoothstep(0.0, 0.1, min(edgeDist.x, edgeDist.y));
        return mix(0.0, mix(1.0, inLight, edgeFade), geoFactor);
    }

    float avgBlockerDepth = blockerSum / blockers;

    // 2. Penumbra Estimation
    // Penumbra width is proportional to (receiverDepth - blockerDepth) / blockerDepth
    // Optifine shadow map depth is non-linear so this is a rough aesthetic approximation
    float penumbra = max(receiverDepth - avgBlockerDepth, 0.0) * 1500.0; 
    float filterRadius = clamp(penumbra, 1.5, 12.0) / 8192.0; // Between 1.5 texels and 12 texels wide blur

    // 3. PCF Filtering
    float accumulatedVis = 0.0;
    for (int i = 0; i < 8; i++) {
        vec2 off = rot * POISSON_8[i] * filterRadius;
        float sz = texture(shadowMap, shadowCoords.xy + off).r;
        accumulatedVis += (sz > receiverDepth) ? 0.125 : 0.0;
    }

    float inLight = accumulatedVis;

    // Smooth fade at shadow frustum edge
    vec2  edgeDist = 1.0 - abs(shadowCoords.xy * 2.0 - 1.0);
    float edgeFade = smoothstep(0.0, 0.1, min(edgeDist.x, edgeDist.y));
    inLight = mix(1.0, inLight, edgeFade);

    return mix(0.0, inLight, geoFactor);
}
