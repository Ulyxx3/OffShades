#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — final.fsh
// Last shader pass — outputs the final pixel color to screen.
//
// Step 1: Pass-through.
//         Future: tonemapping (ACES/Reinhard), gamma correction, vignette…
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;

uniform sampler2D colortex0;

// Note: 'final' pass writes directly to the screen — no DRAWBUFFERS needed.
out vec4 fragColor;

void main() {
    vec4 color = texture(colortex0, texCoord);

    // ── Tonemapping stub (disabled in Step 1) ────────────────────────────────
    // ACES filmic tonemapping will go here:
    //   color.rgb = aces(color.rgb);
    //
    // Gamma correction (sRGB output):
    //   color.rgb = pow(color.rgb, vec3(1.0 / 2.2));

    fragColor = color;
}
