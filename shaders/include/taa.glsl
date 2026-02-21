// ── TAA Halton Jitter ────────────────────────────────────────────────────────
// Generates sub-pixel offsets to accumulate detail over time
vec2 getJitter(int frame) {
    vec2 halton[8] = vec2[](
        vec2( 0.125, -0.375), vec2(-0.375,  0.125),
        vec2( 0.375,  0.375), vec2(-0.125, -0.125),
        vec2( 0.250, -0.125), vec2(-0.250,  0.375),
        vec2( 0.000, -0.500), vec2(-0.500,  0.000)
    );
    int idx = frame % 8;
    return halton[idx];
}
