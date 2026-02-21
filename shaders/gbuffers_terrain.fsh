#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh  (Step 2 v5)
//
// Shadow fixes:
//  - Back-face geometric culling eliminates diagonal acne on N/S faces
//  - Tighter near spread for sharper block shadows
//  - shadowDistance halved to 64 → double effective resolution
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
float sampleShadowPCF(vec3 shadowCoords, float bias, float spread) {
    float lit   = 0.0;
    float texel = 1.0 / 4096.0;  // must match shadowMapResolution

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
    vec3  sunDir       = normalize(sunPosition);
    float cosTheta     = dot(fragNormal, sunDir);

    if (skyLight > 0.8) {

        // ── Geometric back-face check ─────────────────────────────────────────
        // If this fragment faces AWAY from the sun, it's in shadow by geometry.
        // Skip shadow map sampling entirely — avoids diagonal acne on N/S faces.
        if (cosTheta <= 0.0) {
            shadowFactor = 0.0;
        } else {
            // Perspective divide (safe even for ortho where w=1)
            vec3 ndc          = shadowPos.xyz / shadowPos.w;
            vec3 shadowCoords = ndc * 0.5 + 0.5;

            if (all(greaterThan(shadowCoords, vec3(0.0))) &&
                all(lessThan(shadowCoords, vec3(1.0)))) {

                // Normal bias — smaller is ok now that back-faces are culled
                float bias = mix(0.0006, 0.0001, clamp(cosTheta, 0.0, 1.0));

                // Distance-adaptive spread — tighter near for sharp block shadows
                // (distance now over 64 blocks instead of 128)
                float dist   = length(shadowPos.xyz);
                float spread = mix(1.0, 4.0, clamp(dist / 32.0, 0.0, 1.0));

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
    }

    // ── 4. Combine ────────────────────────────────────────────────────────────
    float ambientMin = 0.35;
    float shadow     = mix(ambientMin, 1.0, shadowFactor);

    albedo.rgb *= lightmapColor * shadow;

    fragColor = albedo;
}
