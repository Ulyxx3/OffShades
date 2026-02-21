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
in vec4 currentPosition;
in vec4 previousPosition;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform int  frameCounter;

/* DRAWBUFFERS:03 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 velocityOut;

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

    // ── 4. Shadow — Soft noise for TAA accumulation ───────────────────────────
    // TAA smooths out noise over time. We introduce a tightly rotated 4-sample
    // PCF disk based on screen position and frame counter.
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

                // ── TAA Dithered PCF ────────────────────────────────────────────────
                // Hash function for random rotation per-pixel, shifting every frame
                vec2  fragCoord = gl_FragCoord.xy;
                float dither    = fract(sin(dot(fragCoord + float(frameCounter)*17.13, vec2(12.9898, 78.233))) * 43758.5453);
                float angle     = dither * 6.2831853;
                float s         = sin(angle);
                float c         = cos(angle);
                mat2  rot       = mat2(c, -s, s, c);

                const vec2 POISSON_4[4] = vec2[](
                    vec2(-0.942, -0.316),
                    vec2( 0.316, -0.942),
                    vec2( 0.942,  0.316),
                    vec2(-0.316,  0.942)
                );

                const float BIAS     = 0.0002;
                float shadowSpread   = 1.5 / 8192.0; // Very tight spread (1.5 texels)
                float accumulatedVis = 0.0;

                for (int i = 0; i < 4; i++) {
                    vec2 off = rot * POISSON_4[i] * shadowSpread;
                    float sz = texture(shadowtex0, shadowCoords.xy + off).r;
                    accumulatedVis += (sz > shadowCoords.z - BIAS) ? 0.25 : 0.0;
                }
                
                float inLight = accumulatedVis;

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

    // ── 6. Velocity Output ────────────────────────────────────────────────────
    // Perspective divide must happen per-pixel for correct interpolation
    vec2 currentNDC  = currentPosition.xy / currentPosition.w;
    vec2 previousNDC = previousPosition.xy / previousPosition.w;
    
    vec2 currentUV   = currentNDC * 0.5 + 0.5;
    vec2 previousUV  = previousNDC * 0.5 + 0.5;
    vec2 velocity    = currentUV - previousUV;
    
    // colortex3 stores: R=velX, G=velY, B=0, A=1
    velocityOut     = vec4(velocity, 0.0, 1.0);
}
