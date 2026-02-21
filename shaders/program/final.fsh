
// ─────────────────────────────────────────────────────────────────────────────
// OffShades — final.fsh
// Reads the final TAA output buffer and applies tonemapping before screen.
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;

uniform sampler2D colortex1; // TAA Ping
uniform sampler2D colortex2; // TAA Pong
uniform int frameCounter;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    // Read from the buffer that was WRITTEN TO in the composite pass.
    // In composite.fsh: writeToPing (colortex1) is true when frameCounter % 2 == 0
    vec3 color;
    if (frameCounter % 2 == 0) {
        color = texture(colortex1, texCoord).rgb;
    } else {
        color = texture(colortex2, texCoord).rgb;
    }

    // Passthrough (Minecraft already expects sRGB and does its own minor grading)
    fragColor = vec4(color, 1.0);
}
