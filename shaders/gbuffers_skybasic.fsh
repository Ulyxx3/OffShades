#version 330 compatibility

// OffShades — gbuffers_skybasic.fsh
// Background sky color (gradient, void, fog color)

in vec4 glColor;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    fragColor = glColor;
}
