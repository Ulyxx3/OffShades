#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — composite.vsh
// Vertex shader for full-screen post-processing quad.
//
// This is a standard screen-space quad pass.
// Step 1: Just forward UV. Future passes: bloom, atmospheric scattering…
// ─────────────────────────────────────────────────────────────────────────────

out vec2 texCoord;

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
