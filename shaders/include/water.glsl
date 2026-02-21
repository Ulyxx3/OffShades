// ── Water Physics & Optics ────────────────────────────────────────────────────

// Calculates a perturbed world-space normal for water surfaces
vec3 getWaterNormal(vec3 worldPos, float time) {
    vec2 pos = worldPos.xz;
    
    // Large ambient waves
    float wave1 = sin(pos.x * 1.5 + time * 2.0) * cos(pos.y * 1.5 + time * 1.5);
    
    // Small choppy waves
    float wave2 = sin(pos.x * 4.0 - time * 3.0) * cos(pos.y * 3.5 + time * 4.0);
    
    // Calculate analytical derivatives for the normal
    float dx = cos(pos.x * 1.5 + time * 2.0) * 1.5 * cos(pos.y * 1.5 + time * 1.5)
             + cos(pos.x * 4.0 - time * 3.0) * 4.0 * cos(pos.y * 3.5 + time * 4.0);
             
    float dz = -sin(pos.x * 1.5 + time * 2.0) * sin(pos.y * 1.5 + time * 1.5) * 1.5
             - sin(pos.x * 4.0 - time * 3.0) * sin(pos.y * 3.5 + time * 4.0) * 3.5;
             
    // Scale down the derivatives for a realistic slope
    float bumpiness = 0.05;
    
    return normalize(vec3(-dx * bumpiness, 1.0, -dz * bumpiness));
}
