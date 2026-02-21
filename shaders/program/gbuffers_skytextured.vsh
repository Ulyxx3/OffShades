
// OffShades â€” gbuffers_skytextured.vsh
// Textured sky objects: sun disc, moon disc, stars billboard

out vec2 texCoord;
out vec4 glColor;

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor     = gl_Color;
}

