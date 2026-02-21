
// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_basic.fsh
// Fragment shader for basic geometry.
// ─────────────────────────────────────────────────────────────────────────────

in vec4 glColor;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    fragColor = glColor;
}
