#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh  (Step 2 v7)
//
// Bias is now handled by normal offset in the vertex shader.
// The depth comparison here uses only a tiny epsilon for float precision.
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;   // world-space
in vec4 shadowPos;    // distorted shadow clip coords

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;

// sunPosition is in eye-space — we rotate it to world-space
uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;

// worldTime: 0–12000 = day, 12000–24000 = night
uniform int worldTime;

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

float sampleShadowPCF(vec3 shadowCoords, float spread) {
    float lit   = 0.0;
    float texel = 1.0 / 4096.0;
    // Tiny epsilon to handle floating point self-comparison
    float eps   = 0.0001;
    for (int i = 0; i < 12; i++) {
        vec2  offset  = POISSON[i] * texel * spread;
        float storedZ = texture(shadowtex0, shadowCoords.xy + offset).r;
        lit += (storedZ > shadowCoords.z - eps) ? 1.0 : 0.0;
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

    // Day check via worldTime — 23500–24000 and 0–12500 is day/dusk/dawn
    // This is more reliable than lmCoord.y which doesn't encode time of day
    bool isDay = (worldTime < 13000 || worldTime > 22500);

    if (isDay) {
        // Sun direction in world space — stable across camera rotations
        vec3 sunDirWorld = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        float cosTheta   = dot(fragNormal, sunDirWorld);

        // ── Smooth geometric attenuation ──────────────────────────────────────
        // smoothstep creates a soft transition for sides oblique to the sun.
        // No hard cutoff → no flickering at the perpendicular boundary.
        // cosTheta < -0.05 → fully in shadow (genuine back face)
        // cosTheta >  0.1  → full shadow map lighting
        float geoFactor = smoothstep(-0.05, 0.1, cosTheta);

        if (geoFactor > 0.001) {
            // Only sample shadow map if the face is at least partially lit
            vec3 ndc          = shadowPos.xyz / shadowPos.w;
            vec3 shadowCoords = ndc * 0.5 + 0.5;

            if (all(greaterThan(shadowCoords, vec3(0.0))) &&
                all(lessThan(shadowCoords, vec3(1.0)))) {

                float dist   = length(shadowPos.xyz);
                float spread = mix(1.0, 4.0, clamp(dist / 32.0, 0.0, 1.0));

                float pcf = sampleShadowPCF(shadowCoords, spread);

                // Edge fade at frustum bounds
                vec2  edgeDist = 1.0 - abs(shadowCoords.xy * 2.0 - 1.0);
                float edgeFade = smoothstep(0.0, 0.1, min(edgeDist.x, edgeDist.y));
                pcf = mix(1.0, pcf, edgeFade);

                // Blend shadow map result with geometric attenuation
                shadowFactor = mix(0.0, pcf, geoFactor);
            } else {
                // Outside frustum — pass through geometric attenuation only
                shadowFactor = geoFactor;
            }
        } else {
            // Definitely a back face — full shadow, no sampling
            shadowFactor = 0.0;
        }
    }

    // ── 4. Combine ────────────────────────────────────────────────────────────
    float ambientMin = 0.40;   // slightly raised — avoids too-dark sides
    float shadow     = mix(ambientMin, 1.0, shadowFactor);

    albedo.rgb *= lightmapColor * shadow;

    fragColor = albedo;
}
