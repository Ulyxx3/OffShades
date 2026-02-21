#version 330 compatibility

// OffShades — gbuffers_entities_eyes.vsh
// Glowing eye texture layer on mobs (spiders, endermen, etc.)

out vec2 texCoord;
out vec4 glColor;

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor     = gl_Color;
}
