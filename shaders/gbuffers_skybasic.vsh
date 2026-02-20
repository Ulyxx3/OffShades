#version 330 compatibility

// OffShades — gbuffers_skybasic.vsh
// Background sky color (gradient, void, fog color)
// Note: sky geometry has no texture UVs — only vertex color matters.

out vec4 glColor;

void main() {
    gl_Position = ftransform();
    glColor     = gl_Color;
}
