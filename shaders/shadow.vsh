#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — shadow.vsh  (with radial distortion)
//
// DISTORTION: concentrates shadow map texels near the player (center of the
// shadow frustum) and uses fewer for the far edges.
// This is the standard technique used by BSL, Complementary, Photon, etc.
//
// The same distortShadow() function MUST be applied in gbuffers_terrain.vsh
// when projecting vertices into shadow space.
// ─────────────────────────────────────────────────────────────────────────────

// ── Distortion strength ───────────────────────────────────────────────────────
// Range [0, 1].  Lower = more aggressive distortion (more near-player res).
// 0.10 = very strong (BSL style),  0.20 = moderate,  0.85+ = nearly none
const float SHADOW_DISTORT = 0.15;

// Radial warp: compresses far positions, expands near positions
vec2 distortShadow(vec2 pos) {
    float factor = length(pos) * (1.0 - SHADOW_DISTORT) + SHADOW_DISTORT;
    return pos / factor;
}

out vec2 texCoord;

void main() {
    gl_Position = ftransform();

    // Apply warp in clip-space XY (shadow proj is orthographic → w = 1)
    gl_Position.xy = distortShadow(gl_Position.xy);

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
