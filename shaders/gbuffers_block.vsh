#version 330 compatibility

// OffShades — gbuffers_block.vsh
// Block entities: chests, signs, banners, shulker boxes, etc.

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor     = gl_Color;
    lmCoord     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    fragNormal  = normalize(gl_NormalMatrix * gl_Normal);
}
