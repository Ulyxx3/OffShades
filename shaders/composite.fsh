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
    vec4 color = texture(colortex0, texCoord);

    // ── Reinhard tonemapping ──────────────────────────────────────────────────
    // Compress bright areas, keep shadows perceptually correct.
    // Exposure slightly above 1 to brighten the overall scene.
    const float EXPOSURE = 1.2;
    color.rgb *= EXPOSURE;
    color.rgb  = color.rgb / (color.rgb + vec3(1.0));  // Reinhard

    // ── Gamma correction (linear → sRGB) ──────────────────────────────────────
    color.rgb  = pow(max(color.rgb, vec3(0.0)), vec3(1.0 / 2.2));

    fragColor = color;
}
