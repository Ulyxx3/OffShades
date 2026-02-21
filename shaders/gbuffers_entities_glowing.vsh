#version 330 compatibility

// OffShades — gbuffers_entities_glowing.vsh
// Glowing/emissive texture overlays: spider eyes, enderman eyes, etc.

out vec2 texCoord;
out vec4 glColor;

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor     = gl_Color;
}
