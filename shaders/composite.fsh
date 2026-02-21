#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — composite.fsh  (Step 3)
//
// Post-processing pass:
//   1. Reinhard tonemapping  — prevents oversaturation at noon
//   2. Gamma correction (sRGB) — correct perceptual brightness curve
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;

uniform sampler2D colortex0;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    // Pure passthrough — Iris/Minecraft output is already sRGB and correctly
    // tone-mapped by the lightmap system. Adding Reinhard or gamma on top
    // would double-process and wash out the image.
    // Bloom, color grading, etc. will be added here in a later step.
    fragColor = texture(colortex0, texCoord);
}
