
// ─────────────────────────────────────────────────────────────────────────────
// OffShades — shadow.fsh
// Fragment shader for the shadow pass.
//
// We only need to write depth (handled automatically by OpenGL).
// But we still need to handle alpha cutout (leaves, flowers…)
// so their holes don't cast solid shadows.
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;

uniform sampler2D gtexture;

// No color output needed — depth buffer is written automatically.
out vec4 shadowColor;

void main() {
    vec4 albedo = texture(gtexture, texCoord);

    // Discard transparent cutout pixels so they don't occlude light
    if (albedo.a < 0.5) discard;

    // shadowColor is not actually used for depth — still needed for
    // colored transparent shadow support (future: stained glass tinting)
    shadowColor = vec4(albedo.rgb, 1.0);
}
