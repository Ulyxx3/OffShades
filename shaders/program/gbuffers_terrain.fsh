
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
in vec3 worldPosition;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform int  frameCounter;
uniform float frameTimeCounter;

#include "/include/lighting.glsl"
#include "/include/shadows.glsl"
#include "/include/caustics.glsl"

/* DRAWBUFFERS:03 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 velocityOut;

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

                vec2  fragCoord = gl_FragCoord.xy;
                float dither    = fract(sin(dot(fragCoord + float(frameCounter)*17.13, vec2(12.9898, 78.233))) * 43758.5453);

                shadowFactor = getShadow(shadowtex0, shadowCoords, geoFactor, dither);
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
    
    if (isOutdoor && shadowFactor > 0.05) {
        float caustic = getCaustics(worldPosition, frameTimeCounter);
        vec3 causticColor = vec3(0.8, 0.95, 1.0) * caustic * 1.5; // Bright cyan-blue bands
        albedo.rgb += causticColor * albedo.rgb;
    }

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
