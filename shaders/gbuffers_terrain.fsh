#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.fsh  (Step 2 v8)
//
// Shadows: texelFetch (nearest-neighbor, no bilinear blur) = crisp block edges
// Night fix: lmCoord.y > 0.5 = outdoors check, works both day AND night
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;   // world-space
in vec4 shadowPos;    // distorted shadow clip coords

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;

// shadowLightPosition: sun by day, moon by night — always above horizon
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

const int SHADOW_MAP_RES = 4096;  // must match shadowMapResolution

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

    // Outdoor check: high lmCoord.y = has sky light access = outdoors.
    // Works both day AND night — shadow map uses moon at night automatically.
    bool isOutdoor = (lmCoord.y > 0.5);

    if (isOutdoor) {
        // Current light direction in world space (sun by day, moon by night)
        vec3 lightDirWorld = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
        float cosTheta     = dot(fragNormal, lightDirWorld);

        float geoFactor = smoothstep(-0.05, 0.1, cosTheta);

        if (geoFactor > 0.001) {
            vec3 ndc          = shadowPos.xyz / shadowPos.w;
            vec3 shadowCoords = ndc * 0.5 + 0.5;

            if (all(greaterThan(shadowCoords, vec3(0.0))) &&
                all(lessThan(shadowCoords, vec3(1.0)))) {

                // Single-sample hard shadow — no blurring
                float storedZ    = texture(shadowtex0, shadowCoords.xy).r;
                float hardShadow = (storedZ > shadowCoords.z - 0.0001) ? 1.0 : 0.0;

                // Edge fade at frustum boundary
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

    // ── 4. Combine ────────────────────────────────────────────────────────────
    float ambientMin = 0.40;   // slightly raised — avoids too-dark sides
    float shadow     = mix(ambientMin, 1.0, shadowFactor);

    albedo.rgb *= lightmapColor * shadow;

    fragColor = albedo;
}
