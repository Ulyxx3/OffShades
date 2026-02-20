#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh  (Step 2 fix)
//
// Fix: replaced sampler2DShadow (hardware comparison, unreliable in compat.
//      mode) with a manual depth comparison against shadowtex0 raw depth.
//
// Fix: replaced sunPosition.y check (view-space, changes with camera)
//      with lmCoord.y (sky light) — naturally handles day/night/underground.
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;
in vec4 shadowPos;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;   // raw depth shadow map (solid geometry)

// Sun direction in view space — used only for normal bias direction
uniform vec3 sunPosition;

// ─────────────────────────────────────────────────────────────────────────────
// Manual PCF shadow sampling
//
// shadowCoords : UV + reference depth, all in [0,1]
// bias         : depth offset to prevent self-shadowing
// radius       : kernel spread in texels (1.0 = tight, 3.0 = wide)
//
// Returns 1.0 = fully lit, 0.0 = fully in shadow
// ─────────────────────────────────────────────────────────────────────────────
float sampleShadowPCF(vec3 shadowCoords, float bias, float radius) {
    float lit     = 0.0;
    float texel   = 1.0 / 2048.0;   // must match shadowMapResolution
    int   samples = 0;

    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2  offset    = vec2(float(x), float(y)) * texel * radius;
            float storedZ   = texture(shadowtex0, shadowCoords.xy + offset).r;
            // Lit if the stored depth (closest occluder) is further than us
            lit += (storedZ > shadowCoords.z - bias) ? 1.0 : 0.0;
            samples++;
        }
    }
    return lit / float(samples);
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
    float shadowFactor = 1.0;  // default: fully lit

    // skyLight: 1.0 = full outdoor daylight, 0.0 = cave/night
    // We only apply directional shadows outdoors in daylight.
    float skyLight = lmCoord.y;

    // Shadow is only meaningful when sky light is significant (outdoors, day)
    // Threshold 0.8 avoids shadow artifacts in dim/night conditions
    if (skyLight > 0.8) {

        // shadowPos is in clip space — perspective divide to NDC [-1, 1]
        vec3 ndc        = shadowPos.xyz / shadowPos.w;
        vec3 shadowCoords = ndc * 0.5 + 0.5;  // remap to [0, 1]

        // Only sample if inside the shadow frustum
        if (all(greaterThan(shadowCoords, vec3(0.0))) &&
            all(lessThan(shadowCoords, vec3(1.0)))) {

            // Normal bias — larger bias for surfaces oblique to the sun
            vec3  sunDir   = normalize(sunPosition);
            float cosTheta = clamp(dot(fragNormal, sunDir), 0.0, 1.0);
            float bias     = mix(0.0015, 0.0003, cosTheta);

            // Distance-adaptive PCF: tight near player, wider further away
            float dist   = length(shadowPos.xyz);
            float radius = clamp(dist * 0.025, 1.0, 3.5);

            shadowFactor = sampleShadowPCF(shadowCoords, bias, radius);

            // Fade shadow out at the edge of the shadow frustum
            // to avoid a hard cutoff ring at 128 blocks
            vec2  edgeDist  = 1.0 - abs(shadowCoords.xy * 2.0 - 1.0);
            float edgeFade  = smoothstep(0.0, 0.1, min(edgeDist.x, edgeDist.y));
            shadowFactor    = mix(1.0, shadowFactor, edgeFade);

            // Modulate shadow strength by sky light
            // (weaker at dusk/dawn when skyLight is not full 1.0)
            float shadowStrength = smoothstep(0.8, 1.0, skyLight);
            shadowFactor = mix(1.0, shadowFactor, shadowStrength);
        }
    }

    // ── 4. Combine ────────────────────────────────────────────────────────────
    // Ambient floor prevents pitch-black shadows
    float ambientMin = 0.35;
    float shadow     = mix(ambientMin, 1.0, shadowFactor);

    albedo.rgb *= lightmapColor * shadow;

    fragColor = albedo;
}
