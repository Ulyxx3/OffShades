#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_basic.vsh
// Vertex shader for basic geometry: lines, hit box outlines, particles…
// ─────────────────────────────────────────────────────────────────────────────

out vec4 glColor;

void main() {
    gl_Position = ftransform();
    glColor     = gl_Color;
}
