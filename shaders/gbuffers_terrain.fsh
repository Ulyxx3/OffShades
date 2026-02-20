#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh  (Step 2 v4 — distorted shadow)
//
// PCF: fixed 12-sample Poisson disk, NO per-fragment random rotation.
// Random rotation caused temporal noise ("shimmering") as the sun moved.
// A fixed pattern gives stable, predictable soft edges.
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;
in vec4 shadowPos;  // already distorted in VSH

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;
uniform vec3 sunPosition;

// ── Fixed 12-sample Poisson disk ─────────────────────────────────────────────
const vec2 POISSON[12] = vec2[](
    vec2(-0.326212, -0.405805),
    vec2(-0.840144, -0.073580),
    vec2(-0.695914,  0.457137),
    vec2(-0.203345,  0.620716),
    vec2( 0.962340, -0.194983),
    vec2( 0.473434, -0.480026),
    vec2( 0.519456,  0.767022),
    vec2( 0.185461, -0.893124),
    vec2( 0.507431,  0.064425),
    vec2( 0.896420,  0.412458),
    vec2(-0.321940, -0.932615),
    vec2(-0.791559, -0.597710)
);

// ── PCF with fixed Poisson disk ───────────────────────────────────────────────
// spread is in shadow-map UV space (post-distortion, texel units vary)
float sampleShadowPCF(vec3 shadowCoords, float bias, float spread) {
    float lit   = 0.0;
    float texel = 1.0 / 4096.0;   // must match shadowMapResolution

    for (int i = 0; i < 12; i++) {
        vec2  offset  = POISSON[i] * texel * spread;
        float storedZ = texture(shadowtex0, shadowCoords.xy + offset).r;
        lit += (storedZ > shadowCoords.z - bias) ? 1.0 : 0.0;
    }
    return lit / 12.0;
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
        // shadowPos.xy already distorted, w=1 for ortho — remap to [0,1]
        vec3 shadowCoords = shadowPos.xyz * 0.5 + 0.5;

        if (all(greaterThan(shadowCoords, vec3(0.0))) &&
            all(lessThan(shadowCoords, vec3(1.0)))) {

            // Normal bias
            vec3  sunDir   = normalize(sunPosition);
            float cosTheta = clamp(dot(fragNormal, sunDir), 0.0, 1.0);
            float bias     = mix(0.0010, 0.0002, cosTheta);

            // Distance-adaptive spread:
            // Near = 1.5 texels → sharp block shadows
            // Far  = 5.0 texels → soft natural penumbra
            float dist   = length(shadowPos.xyz);
            float spread = mix(1.5, 5.0, clamp(dist / 64.0, 0.0, 1.0));

            shadowFactor = sampleShadowPCF(shadowCoords, bias, spread);

            // Frustum edge fade
            vec2  edgeDist = 1.0 - abs(shadowCoords.xy * 2.0 - 1.0);
            float edgeFade = smoothstep(0.0, 0.1, min(edgeDist.x, edgeDist.y));
            shadowFactor   = mix(1.0, shadowFactor, edgeFade);

            // Dusk/dawn fade
            float strength = smoothstep(0.8, 1.0, skyLight);
            shadowFactor   = mix(1.0, shadowFactor, strength);
        }
    }

    // ── 4. Combine ────────────────────────────────────────────────────────────
    float ambientMin = 0.35;
    float shadow     = mix(ambientMin, 1.0, shadowFactor);

    albedo.rgb *= lightmapColor * shadow;

    fragColor = albedo;
}
