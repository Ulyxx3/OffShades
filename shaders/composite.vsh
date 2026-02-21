#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — composite.vsh
// Standard fullscreen quad vertex shader for post-processing passes.
// ─────────────────────────────────────────────────────────────────────────────

out vec2 texCoord;

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
