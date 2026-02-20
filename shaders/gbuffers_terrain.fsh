#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh  (Step 2 v3 — soft shadows)
//
// Shadow quality: Poisson Disk PCF with per-fragment disk rotation.
// This produces smooth, organic shadow edges instead of the grid-banding
// artifact from a regular NxN kernel.
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;
in vec4 shadowPos;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;

uniform vec3 sunPosition;
uniform vec2 viewSize;   // screen resolution — used for dither rotation

// ─────────────────────────────────────────────────────────────────────────────
// Poisson Disk — 16 sample points in a unit disk, well-distributed.
// Using a fixed set avoids gl_FragCoord dependency for the disk itself;
// we only rotate the disk per-fragment using a cheap hash.
// ─────────────────────────────────────────────────────────────────────────────
const vec2 POISSON[16] = vec2[](
    vec2(-0.94201624, -0.39906216),
    vec2( 0.94558609, -0.76890725),
    vec2(-0.09418410, -0.92938870),
    vec2( 0.34495938,  0.29387760),
    vec2(-0.91588581,  0.45771432),
    vec2(-0.81544232, -0.87912464),
    vec2(-0.38277543,  0.27676845),
    vec2( 0.97484398,  0.75648379),
    vec2( 0.44323325, -0.97511554),
    vec2( 0.53742981, -0.47373420),
    vec2(-0.26496911, -0.41893023),
    vec2( 0.79197514,  0.19090188),
    vec2(-0.24188840,  0.99706507),
    vec2(-0.81409955,  0.91437590),
    vec2( 0.19984126,  0.78641367),
    vec2( 0.14383161, -0.14100790)
);

// ── Cheap 2D rotation matrix from angle θ ────────────────────────────────────
mat2 rotate2D(float theta) {
    float s = sin(theta), c = cos(theta);
    return mat2(c, -s, s, c);
}

// ── Per-fragment angle hash — avoids uniform banding ─────────────────────────
// Maps screen pixel position to a pseudo-random angle in [0, 2π]
float ditherAngle(vec2 screenPos) {
    return fract(sin(dot(screenPos, vec2(12.9898, 78.233))) * 43758.5453) * 6.2832;
}

// ─────────────────────────────────────────────────────────────────────────────
// Poisson PCF shadow sampling
//
// shadowCoords : UV.xy + reference depth Z, all in [0,1]
// bias         : depth offset to prevent self-shadowing (shadow acne)
// spread       : radius of the Poisson disk in texture space
//                  e.g. 0.0005 = tight/sharp, 0.003 = wide/soft
// Returns 1.0 = fully lit, 0.0 = fully in shadow
// ─────────────────────────────────────────────────────────────────────────────
float sampleShadowPoisson(vec3 shadowCoords, float bias, float spread) {
    float lit    = 0.0;
    float angle  = ditherAngle(gl_FragCoord.xy);
    mat2  rot    = rotate2D(angle);

    for (int i = 0; i < 16; i++) {
        vec2 offset  = rot * POISSON[i] * spread;
        float storedZ = texture(shadowtex0, shadowCoords.xy + offset).r;
        lit += (storedZ > shadowCoords.z - bias) ? 1.0 : 0.0;
    }
    return lit / 16.0;
}

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    // ── 1. Albedo ─────────────────────────────────────────────────────────────
    vec4 albedo = texture(gtexture, texCoord);
    if (albedo.a < 0.1) discard;
    albedo *= glColor;

    // ── 2. Lightmap ───────────────────────────────────────────────────────────
    vec3 lightmapColor = texture(lightmap, lmCoord).rgb;

    // ── 3. Shadow ─────────────────────────────────────────────────────────────
    float shadowFactor = 1.0;
    float skyLight     = lmCoord.y;

    if (skyLight > 0.8) {
        vec3 ndc          = shadowPos.xyz / shadowPos.w;
        vec3 shadowCoords = ndc * 0.5 + 0.5;

        if (all(greaterThan(shadowCoords, vec3(0.0))) &&
            all(lessThan(shadowCoords, vec3(1.0)))) {

            // Normal bias
            vec3  sunDir   = normalize(sunPosition);
            float cosTheta = clamp(dot(fragNormal, sunDir), 0.0, 1.0);
            float bias     = mix(0.0018, 0.0004, cosTheta);

            // ── Distance-adaptive Poisson spread ─────────────────────────────
            // Near: spread 0.0004 → very tight = sharp block shadows
            // Far:  spread 0.0025 → wider = soft natural edges
            float dist   = length(shadowPos.xyz);
            float spread = mix(0.0004, 0.0025, clamp(dist / 64.0, 0.0, 1.0));

            shadowFactor = sampleShadowPoisson(shadowCoords, bias, spread);

            // Edge fade — smooth disappearance at frustum bounds
            vec2  edgeDist = 1.0 - abs(shadowCoords.xy * 2.0 - 1.0);
            float edgeFade = smoothstep(0.0, 0.1, min(edgeDist.x, edgeDist.y));
            shadowFactor   = mix(1.0, shadowFactor, edgeFade);

            // Dusk/dawn fade
            float shadowStrength = smoothstep(0.8, 1.0, skyLight);
            shadowFactor = mix(1.0, shadowFactor, shadowStrength);
        }
    }

    // ── 4. Combine ────────────────────────────────────────────────────────────
    float ambientMin = 0.35;
    float shadow     = mix(ambientMin, 1.0, shadowFactor);

    albedo.rgb *= lightmapColor * shadow;

    fragColor = albedo;
}
