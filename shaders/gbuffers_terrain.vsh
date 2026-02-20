#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.vsh
// Vertex shader for solid terrain blocks.
//
// Goal (Step 1): Pass-through — transform geometry, forward UV + color to FSH.
// No effects yet, just enough to make the world appear correctly.
// ─────────────────────────────────────────────────────────────────────────────

// ── Outputs to fragment shader ────────────────────────────────────────────────
out vec2 texCoord;       // Texture UV from the atlas
out vec4 glColor;        // Tint color (biome color, shading, etc.)
out vec2 lmCoord;        // Lightmap coordinates (sky light + block light)
out vec3 fragNormal;     // World-space normal (for future lighting)

void main() {
    // Standard MVP transform — identical to vanilla rendering
    gl_Position = ftransform();

    // Forward texture coordinates
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    // Forward vertex color (biome tinting, brightness vertex data)
    glColor = gl_Color;

    // Lightmap UVs — normalize to [0,1] range for sampler2D lookup
    lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    // Forward normals in view space (will be used in Step 2 for shadow bias)
    fragNormal = normalize(gl_NormalMatrix * gl_Normal);
}
