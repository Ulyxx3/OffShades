#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — composite.fsh
// First post-processing pass (runs after all gbuffers).
//
// Step 1: Pure pass-through — output colortex0 unchanged.
//         Future: bloom, fog, atmospheric scattering, color grading…
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;

// colortex0 = the scene as rendered by gbuffers passes
uniform sampler2D colortex0;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    // Step 1: No effects — just read and re-emit
    vec4 color = texture(colortex0, texCoord);
    fragColor  = color;

    // ── Future effect stubs (commented out) ─────────────────────────────────
    // Step 4 — Bloom:
    //   vec3 bloom = computeBloom(colortex0, texCoord);
    //   color.rgb += bloom;
    //
    // Step 3 — Atmospheric fog / sky scattering:
    //   color.rgb = applyAtmosphere(color.rgb, viewDir);
}
