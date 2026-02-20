#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh
// Step 2: + directional shadow with PCF softening
//
// Artistic goal:
//   - Sharp shadows for nearby blocks
//   - Progressively softer edges with distance (via larger PCF kernel)
// ─────────────────────────────────────────────────────────────────────────────

// ── Inputs from vertex shader ─────────────────────────────────────────────────
in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;
in vec4 shadowPos;   // clip-space position in shadow map

// ── Uniforms ──────────────────────────────────────────────────────────────────
uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2DShadow shadowtex1;  // shadow map with hardware PCF support

// Sun direction in view space (provided by Iris)
uniform vec3 sunPosition;

// ─────────────────────────────────────────────────────────────────────────────
// PCF (Percentage Closer Filtering)
// Samples the shadow map multiple times in a kernel around the projected
// position and averages the results for soft shadow edges.
//
// kernelSize: half-size of the sample grid (1 = 3x3, 2 = 5x5…)
//             We make it proportional to distance for near-sharp/far-soft.
// ─────────────────────────────────────────────────────────────────────────────
float sampleShadowPCF(vec3 projCoords, float kernelRadius) {
    float shadow  = 0.0;
    float texelSize = 1.0 / 2048.0;  // must match shadowMapResolution
    int   samples  = 0;

    // 5×5 kernel — quality / perf tradeoff; reduce to 3×3 if needed
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(x, y) * texelSize * kernelRadius;
            shadow += texture(shadowtex1, vec3(projCoords.xy + offset, projCoords.z));
            samples++;
        }
    }
    return shadow / float(samples);
}

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    // ── 1. Albedo ─────────────────────────────────────────────────────────────
    vec4 albedo = texture(gtexture, texCoord);
    if (albedo.a < 0.1) discard;
    albedo *= glColor;

    // ── 2. Lightmap (torch + sky ambient) ────────────────────────────────────
    vec3 lighting = texture(lightmap, lmCoord).rgb;

    // ── 3. Shadow factor ──────────────────────────────────────────────────────
    float shadowFactor = 1.0;  // 1.0 = fully lit, 0.0 = fully in shadow

    // Only compute shadows when the sun is above the horizon
    // sunPosition.y > 0 means daytime in view space
    if (sunPosition.y > 0.0) {

        // Project from clip space → NDC [−1,1]³ → texture space [0,1]³
        vec3 ndc       = shadowPos.xyz / shadowPos.w;
        vec3 projCoords = ndc * 0.5 + 0.5;

        // Check that position is inside the shadow map frustum
        if (projCoords.x >= 0.0 && projCoords.x <= 1.0 &&
            projCoords.y >= 0.0 && projCoords.y <= 1.0) {

            // ── Normal bias: push shadow receiver along the normal ────────────
            // Prevents "shadow acne" (self-shadowing) on flat surfaces.
            // Bias is larger for surfaces that are oblique to the sun.
            vec3  sunDir   = normalize(sunPosition);
            float cosTheta = max(dot(fragNormal, sunDir), 0.0);
            float bias     = mix(0.002, 0.0005, cosTheta);
            projCoords.z  -= bias;

            // ── Distance-based PCF kernel ─────────────────────────────────────
            // Near: kernel = 1.0 (tight = sharper), Far: kernel = 3.0 (softer)
            float dist        = length(shadowPos.xyz);  // approx distance
            float kernelRadius = clamp(dist * 0.03, 1.0, 3.0);

            shadowFactor = sampleShadowPCF(projCoords, kernelRadius);
        }
    }

    // ── 4. Combine: ambient + shadow-modulated direct light ───────────────────
    // We keep a minimum ambient floor so shadowed areas aren't pitch black.
    // This mimics the indirect/bounce light from the sky — vanilla-faithful feel.
    float ambientMin = 0.35;   // 0 = pitch black shadows, 1 = no shadows at all
    float shadow     = mix(ambientMin, 1.0, shadowFactor);

    albedo.rgb *= lighting * shadow;

    // ── 5. Output ─────────────────────────────────────────────────────────────
    fragColor = albedo;
}
