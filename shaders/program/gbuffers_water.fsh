
// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_water.fsh
// Fragment shader for translucent geometry (water, stained glass, ice…).
//
// Step 1: Vanilla-accurate translucent rendering.
//         Reflections, waves and refraction come in a later step.
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;
in vec4 currentPosition;
in vec4 previousPosition;

in vec3 worldPosition;
flat in int blockId;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;

#include "/include/lighting.glsl"
#include "/include/water.glsl"
#include "/include/caustics.glsl"

/* DRAWBUFFERS:03 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 velocityOut;

void main() {
    vec4 albedo = texture(gtexture, texCoord);

    // Water is translucent — don't fully discard, just keep alpha
    albedo *= glColor;
    
    vec3 normal = fragNormal;
    bool isWater = (blockId == 8 || blockId == 9);
    
    vec3 lightDirWorld = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float sunHeight    = lightDirWorld.y;
    
    if (isWater) {
        if (fragNormal.y > 0.5) {
            normal = getWaterNormal(worldPosition, frameTimeCounter);
        }
        
        // Water Reflections
        vec3 viewDir = normalize(worldPosition - cameraPosition);
        float f = calculateFresnel(-viewDir, normal, 0.02);
        
        vec3 skyColor = skyAmbientColor(sunHeight);
        albedo.rgb = mix(albedo.rgb, skyColor, f);
        albedo.a = mix(albedo.a, 1.0, f); // Fresnel makes water more opaque at grazing angles
    }

    vec3 lighting = texture(lightmap, lmCoord).rgb;
    albedo.rgb *= lighting;

    bool isOutdoor = (lmCoord.y > 0.5);
    if (isOutdoor) {
        float caustic = getCaustics(worldPosition, frameTimeCounter);
        vec3 causticColor = vec3(0.8, 0.95, 1.0) * caustic * 1.5;
        albedo.rgb += causticColor * albedo.rgb;
    }

    fragColor = albedo;

    // ── Velocity Output ───────────────────────────────────────────────────────
    vec2 currentNDC  = currentPosition.xy / currentPosition.w;
    vec2 previousNDC = previousPosition.xy / previousPosition.w;
    
    vec2 currentUV   = currentNDC * 0.5 + 0.5;
    vec2 previousUV  = previousNDC * 0.5 + 0.5;
    vec2 velocity    = currentUV - previousUV;
    
    velocityOut     = vec4(velocity, 0.0, 1.0);
}
