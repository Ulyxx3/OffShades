#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh  (Step 3 — clean shadow rewrite)
//
// Shadow: single texture() sample, no PCF, no blur.
// Resolution is 8192px → sub-pixel accuracy → no visible pixelation.
// Acne: handled by normal offset bias (VSH) + tiny fixed depth bias.
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;   // world-space
in vec4 shadowPos;    // distorted shadow clip coords

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

// ── Sky-color ambient (matches gbuffers_skybasic palette) ─────────────────────
vec3 skyAmbientColor(float sunHeight) {
    float dayFactor     = smoothstep(-0.10, 0.25, sunHeight);
    float sunriseFactor = pow(max(1.0 - abs(sunHeight) * 3.0, 0.0), 2.0);

    vec3 nightAmb  = vec3(0.04, 0.05, 0.10);
    vec3 dayAmb    = vec3(0.45, 0.58, 0.85);
    vec3 sunsetAmb = vec3(0.80, 0.42, 0.18);

    vec3 base = mix(nightAmb, dayAmb, dayFactor);
    return mix(base, sunsetAmb, sunriseFactor * dayFactor);
}

vec3 sunColor(float sunHeight) {
    float dayFactor     = smoothstep(-0.05, 0.25, sunHeight);
    float sunriseFactor = pow(max(1.0 - abs(sunHeight) * 4.0, 0.0), 2.0);

    vec3 nightCol   = vec3(0.50, 0.55, 0.75);
    vec3 dayCol     = vec3(1.00, 0.97, 0.90);
    vec3 sunsetCol  = vec3(1.00, 0.60, 0.20);

    vec3 base = mix(nightCol, dayCol, dayFactor);
    return mix(base, sunsetCol, sunriseFactor * dayFactor);
}

void main() {
    // ── 1. Albedo ─────────────────────────────────────────────────────────────
    vec4 albedo = texture(gtexture, texCoord);
    if (albedo.a < 0.1) discard;
    albedo *= glColor;

    // ── 2. Lightmap ───────────────────────────────────────────────────────────
    vec3 lightmapColor = texture(lightmap, lmCoord).rgb;

    // ── 3. Time-of-day colors ─────────────────────────────────────────────────
    vec3 lightDirWorld = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float sunHeight    = lightDirWorld.y;

    vec3 ambientColor = skyAmbientColor(sunHeight);
    vec3 directColor  = sunColor(sunHeight);

    // ── 4. Shadow — exact single sample ───────────────────────────────────────
    // 8192px shadow map → 1 texel = 0.0078 blocks even at 64 block distance.
    // Sub-pixel precision: no PCF or blurring required.
    float shadowFactor = 1.0;
    bool  isOutdoor    = (lmCoord.y > 0.5);

    if (isOutdoor) {
        float cosTheta  = dot(fragNormal, lightDirWorld);
        float geoFactor = smoothstep(-0.05, 0.1, cosTheta);

        if (geoFactor > 0.001) {
            vec3 ndc          = shadowPos.xyz / shadowPos.w;
            vec3 shadowCoords = ndc * 0.5 + 0.5;

            if (all(greaterThan(shadowCoords, vec3(0.0))) &&
                all(lessThan(shadowCoords, vec3(1.0)))) {

                // Single exact lookup — normal offset in VSH prevents acne
                const float BIAS  = 0.0002;
                float storedZ     = texture(shadowtex0, shadowCoords.xy).r;
                float inLight     = (storedZ > shadowCoords.z - BIAS) ? 1.0 : 0.0;

                // Smooth fade at shadow frustum edge
                vec2  edgeDist = 1.0 - abs(shadowCoords.xy * 2.0 - 1.0);
                float edgeFade = smoothstep(0.0, 0.1, min(edgeDist.x, edgeDist.y));
                inLight = mix(1.0, inLight, edgeFade);

                shadowFactor = mix(0.0, inLight, geoFactor);
            } else {
                shadowFactor = geoFactor;
            }
        } else {
            shadowFactor = 0.0;
        }
    }

    // ── 5. Compose lighting ───────────────────────────────────────────────────
    const float TINT_STRENGTH = 0.30;
    vec3 ambientTint = mix(vec3(1.0), ambientColor, TINT_STRENGTH);
    vec3 directTint  = mix(vec3(1.0), directColor,  TINT_STRENGTH);
    vec3 lightTint   = mix(ambientTint, directTint, shadowFactor);

    float lightLevel = mix(0.40, 1.0, shadowFactor);

    albedo.rgb *= lightmapColor * lightLevel * lightTint;
    fragColor = albedo;
}
