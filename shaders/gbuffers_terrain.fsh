#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh
// Fragment shader for solid terrain blocks.
//
// Goal (Step 1): Vanilla-accurate output — sample the block texture atlas,
// multiply by vertex color (biome tint), apply lightmap.
// No custom effects yet; this is the compile-check baseline.
// ─────────────────────────────────────────────────────────────────────────────

// ── Inputs from vertex shader ─────────────────────────────────────────────────
in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;

// ── Uniforms provided by Iris/OptiFine ───────────────────────────────────────
uniform sampler2D gtexture;       // Block texture atlas (albedo)
uniform sampler2D lightmap;       // Lightmap texture (sky + block light)

// ── Render target output ──────────────────────────────────────────────────────
/* DRAWBUFFERS:0 */               // Write to colortex0 only
out vec4 fragColor;

void main() {
    // 1. Sample block texture from the atlas
    vec4 albedo = texture(gtexture, texCoord);

    // 2. Discard fully transparent pixels (e.g. leaves cutout)
    if (albedo.a < 0.1) discard;

    // 3. Multiply by vertex color (biome tint, AO baked in vertex data)
    albedo *= glColor;

    // 4. Sample lightmap and apply it
    //    lmCoord.x = block light (0=dark, 1=full torch)
    //    lmCoord.y = sky light   (0=cave, 1=full sun)
    vec3 lighting = texture(lightmap, lmCoord).rgb;
    albedo.rgb *= lighting;

    // 5. Output — vanilla-accurate color, ready for composite passes
    fragColor = albedo;
}
