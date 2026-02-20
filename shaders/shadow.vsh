#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — shadow.vsh
// Renders the scene from the sun's point of view into the shadow map.
// Iris calls this pass automatically when shadow.enabled is true.
// ─────────────────────────────────────────────────────────────────────────────

out vec2 texCoord;

void main() {
    // ftransform() here uses the shadow MVP matrix (sun perspective)
    // provided automatically by Iris — no manual matrix needed.
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
