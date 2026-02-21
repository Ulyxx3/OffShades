#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — shadow.vsh
//
// STABILIZATION: snaps the shadow frustum to texel-grid boundaries.
// Without this, sub-texel movement of the camera causes the shadow map
// to shift every frame → shadow edges flicker when the player moves.
// Technique used by BSL, Complementary, Photon shaders.
//
// DISTORTION: concentrates texels near the player for higher effective resolution.
// ─────────────────────────────────────────────────────────────────────────────

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

const float SHADOW_MAP_RES  = 8192.0;
const float SHADOW_DISTORT  = 0.08;

vec2 distortShadow(vec2 pos) {
    float factor = length(pos) * (1.0 - SHADOW_DISTORT) + SHADOW_DISTORT;
    return pos / factor;
}

out vec2 texCoord;

void main() {
    gl_Position = ftransform();

    // ── Texel-snap: eliminate camera-movement-induced flickering ──────────────
    // Find where world-origin maps to in shadow NDC space.
    // All vertices of the frustum share the same translation → snap uniformly.
    vec4 originClip   = shadowProjection * shadowModelView * vec4(0.0, 0.0, 0.0, 1.0);
    float texelNDC    = 2.0 / SHADOW_MAP_RES;
    vec2  snapOffset  = round(originClip.xy / texelNDC) * texelNDC - originClip.xy;
    gl_Position.xy   += snapOffset;

    // ── Radial distortion ─────────────────────────────────────────────────────
    gl_Position.xy = distortShadow(gl_Position.xy);

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
