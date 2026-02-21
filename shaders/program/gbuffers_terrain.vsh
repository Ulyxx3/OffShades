
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// OffShades â€” gbuffers_terrain.vsh
//
// Normal offset bias: push receiver along world normal to prevent acne.
// Texel-snap: SAME snap as shadow.vsh applied to shadowPos so that the
// receiver lookup stays in sync with the stabilized shadow map.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform int  frameCounter;
uniform float viewWidth;
uniform float viewHeight;

#include "/include/taa.glsl"

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;
out vec4 shadowPos;
out vec4 currentPosition;
out vec4 previousPosition;
out vec3 worldPosition;

const float SHADOW_MAP_RES = 8192.0;
const float SHADOW_DISTORT = 0.08;

vec2 distortShadow(vec2 pos) {
    float factor = length(pos) * (1.0 - SHADOW_DISTORT) + SHADOW_DISTORT;
    return pos / factor;
}

void main() {
    gl_Position = ftransform();

    // â”€â”€ Velocity calculation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    vec4 viewPos  = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    worldPos.xyz += cameraPosition; // Absolute world coordinates
    worldPosition = worldPos.xyz;

    // Current screen position (un-jittered for velocity)
    vec4 currentProj = gl_ProjectionMatrix * viewPos;
    currentPosition  = currentProj;

    // Previous screen position
    vec4 prevWorldPos = worldPos;
    prevWorldPos.xyz -= previousCameraPosition; // Relative to previous camera
    vec4 prevViewPos  = gbufferPreviousModelView * prevWorldPos;
    vec4 prevProj     = gbufferPreviousProjection * prevViewPos;
    previousPosition  = prevProj;

    // â”€â”€ Apply Jitter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    vec2 jitter = getJitter(frameCounter);
    gl_Position.xy += jitter * vec2(2.0/viewWidth, 2.0/viewHeight) * gl_Position.w;

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor  = gl_Color;
    lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    // World-space normal
    vec3 viewNormal  = normalize(gl_NormalMatrix * gl_Normal);
    vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * viewNormal);
    fragNormal = worldNormal;

    // Relative world position for shadow offset
    vec4 relWorldPos = gbufferModelViewInverse * viewPos;

    vec3 lightDirWorld    = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float NdotL           = dot(worldNormal, lightDirWorld);
    float offsetScale     = clamp(1.0 - NdotL, 0.0, 1.0);
    float normalOffsetDist = 0.15 * offsetScale;
    vec4 biasedWorldPos   = relWorldPos + vec4(worldNormal * normalOffsetDist, 0.0);

    // Project into shadow clip space
    shadowPos = shadowProjection * (shadowModelView * biasedWorldPos);

    // â”€â”€ Texel-snap (must match shadow.vsh exactly) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    vec4 originClip  = shadowProjection * shadowModelView * vec4(0.0, 0.0, 0.0, 1.0);
    float texelNDC   = 2.0 / SHADOW_MAP_RES;
    vec2 snapOffset  = round(originClip.xy / texelNDC) * texelNDC - originClip.xy;
    shadowPos.xy    += snapOffset;

    // Radial distortion
    shadowPos.xy = distortShadow(shadowPos.xy);
}

