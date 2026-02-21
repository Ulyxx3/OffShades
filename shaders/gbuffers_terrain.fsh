#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh  (Step 3)
//
// Adds sky-colored ambient lighting:
//  - Lit areas: warm sun color (bright white at noon, orange at sunset)
//  - Shadow areas: sky blue tint (pale blue ambient, not flat grey)
//  - Night: cool dark-blue moon ambient
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

// ── Sky palette (matches gbuffers_skybasic) ───────────────────────────────────
// Sun height in world space drives time-of-day blending.
vec3 skyAmbientColor(float sunHeight) {
    float dayFactor    = smoothstep(-0.10, 0.25, sunHeight);
    float sunriseFactor = pow(max(1.0 - abs(sunHeight) * 3.0, 0.0), 2.0);

    vec3 nightAmb  = vec3(0.04, 0.05, 0.10);   // dark cool blue (moonlit)
    vec3 dayAmb    = vec3(0.45, 0.58, 0.85);   // sky blue
    vec3 sunsetAmb = vec3(0.80, 0.42, 0.18);   // warm orange

    vec3 base = mix(nightAmb, dayAmb, dayFactor);
    return mix(base, sunsetAmb, sunriseFactor * dayFactor);
}

vec3 sunColor(float sunHeight) {
    float dayFactor     = smoothstep(-0.05, 0.25, sunHeight);
    float sunriseFactor = pow(max(1.0 - abs(sunHeight) * 4.0, 0.0), 2.0);

    vec3 nightCol   = vec3(0.50, 0.55, 0.75);   // cool moon white
    vec3 dayCol     = vec3(1.00, 0.97, 0.90);   // neutral white-warm
    vec3 sunsetCol  = vec3(1.00, 0.60, 0.20);   // deep orange

    vec3 base = mix(nightCol, dayCol, dayFactor);
    return mix(base, sunsetCol, sunriseFactor * dayFactor);
}

void main() {
    // ── 1. Albedo ─────────────────────────────────────────────────────────────
    vec4 albedo = texture(gtexture, texCoord);
    if (albedo.a < 0.1) discard;
    albedo *= glColor;

    // ── 2. Lightmap (block + sky brightness) ─────────────────────────────────
    vec3 lightmapColor = texture(lightmap, lmCoord).rgb;

    // ── 3. Time-of-day colors ─────────────────────────────────────────────────
    vec3 lightDirWorld = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float sunHeight    = lightDirWorld.y;  // -1=below horizon, +1=zenith

    vec3 ambientColor = skyAmbientColor(sunHeight);   // for shadow areas
    vec3 directColor  = sunColor(sunHeight);          // for lit areas

    // ── 4. Shadow ─────────────────────────────────────────────────────────────
    float shadowFactor = 1.0;
    bool isOutdoor = (lmCoord.y > 0.5);

    if (isOutdoor) {
        float cosTheta  = dot(fragNormal, lightDirWorld);
        float geoFactor = smoothstep(-0.05, 0.1, cosTheta);

        if (geoFactor > 0.001) {
            vec3 ndc          = shadowPos.xyz / shadowPos.w;
            vec3 shadowCoords = ndc * 0.5 + 0.5;

            if (all(greaterThan(shadowCoords, vec3(0.0))) &&
                all(lessThan(shadowCoords, vec3(1.0)))) {

                // Adaptive bias: near = tiny (normal offset suffices),
                // far = larger (texels grow with distance due to distortion).
                float dist         = length(shadowPos.xyz);
                float adaptiveBias = mix(0.0001, 0.0008, clamp(dist / 48.0, 0.0, 1.0));

                // ── Angle-adaptive Poisson PCF (8 samples) ──────────────────
                // Direct (cosTheta~1): spread=0 → hard, crisp block shadows
                // Oblique (cosTheta~0): spread=6 → blurs aliasing stripes
                float texel   = 1.0 / 4096.0;
                float oblique = 1.0 - clamp(cosTheta * 5.0, 0.0, 1.0);
                float spread  = mix(0.0, 6.0, oblique);

                // 8-point Poisson disk for better coverage than quad
                const vec2 POISSON8[8] = vec2[](
                    vec2(-0.7071,  0.0000),
                    vec2( 0.7071,  0.0000),
                    vec2( 0.0000, -0.7071),
                    vec2( 0.0000,  0.7071),
                    vec2(-0.5000, -0.5000),
                    vec2( 0.5000, -0.5000),
                    vec2(-0.5000,  0.5000),
                    vec2( 0.5000,  0.5000)
                );

                float hardShadow = 0.0;
                for (int i = 0; i < 8; i++) {
                    vec2  off = POISSON8[i] * texel * spread;
                    float sz  = texture(shadowtex0, shadowCoords.xy + off).r;
                    hardShadow += (sz > shadowCoords.z - adaptiveBias) ? 0.125 : 0.0;
                }

                vec2  edgeDist = 1.0 - abs(shadowCoords.xy * 2.0 - 1.0);
                float edgeFade = smoothstep(0.0, 0.15, min(edgeDist.x, edgeDist.y));
                hardShadow = mix(1.0, hardShadow, edgeFade);

                shadowFactor = mix(0.0, hardShadow, geoFactor);
            } else {
                shadowFactor = geoFactor;
            }
        } else {
            shadowFactor = 0.0;
        }
    }

    // ── 5. Compose lighting ───────────────────────────────────────────────────
    // Shadow areas get sky-blue ambient tint (30% tint strength, subtle)
    // Lit areas get sun-warm direct light tint
    const float TINT_STRENGTH = 0.30;
    vec3 ambientTint = mix(vec3(1.0), ambientColor, TINT_STRENGTH);
    vec3 directTint  = mix(vec3(1.0), directColor,  TINT_STRENGTH);
    vec3 lightTint   = mix(ambientTint, directTint, shadowFactor);

    // Shadow brightness (same range as before: 0.40 ambient, 1.0 lit)
    float lightLevel = mix(0.40, 1.0, shadowFactor);

    albedo.rgb *= lightmapColor * lightLevel * lightTint;

    fragColor = albedo;
}
