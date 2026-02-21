out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmCoord     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glColor     = gl_Color;
}
