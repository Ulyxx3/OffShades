#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — final.vsh
// Vertex shader for the final output pass (writes to the actual framebuffer).
// ─────────────────────────────────────────────────────────────────────────────

out vec2 texCoord;

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
