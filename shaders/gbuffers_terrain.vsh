#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.vsh
//
// Normal offset bias: push receiver along world normal to prevent acne.
// Texel-snap: SAME snap as shadow.vsh applied to shadowPos so that the
// receiver lookup stays in sync with the stabilized shadow map.
// ─────────────────────────────────────────────────────────────────────────────

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

// ── TAA Halton Jitter ────────────────────────────────────────────────────────
// Generates sub-pixel offsets to accumulate detail over time
vec2 getJitter(int frame) {
    vec2 halton[8] = vec2[](
        vec2( 0.125, -0.375), vec2(-0.375,  0.125),
        vec2( 0.375,  0.375), vec2(-0.125, -0.125),
        vec2( 0.250, -0.125), vec2(-0.250,  0.375),
        vec2( 0.000, -0.500), vec2(-0.500,  0.000)
    );
    int idx = frame % 8;
    return halton[idx];
}

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;
out vec4 shadowPos;
out vec4 currentPosition;
out vec4 previousPosition;

const float SHADOW_MAP_RES = 8192.0;
const float SHADOW_DISTORT = 0.08;

vec2 distortShadow(vec2 pos) {
    float factor = length(pos) * (1.0 - SHADOW_DISTORT) + SHADOW_DISTORT;
    return pos / factor;
}

void main() {
    gl_Position = ftransform();

    // ── Velocity calculation ──────────────────────────────────────────────────
    vec4 viewPos  = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    worldPos.xyz += cameraPosition; // Absolute world coordinates

    // Current screen position (un-jittered for velocity)
    vec4 currentProj = gl_ProjectionMatrix * viewPos;
    currentPosition  = currentProj;

    // Previous screen position
    vec4 prevWorldPos = worldPos;
    prevWorldPos.xyz -= previousCameraPosition; // Relative to previous camera
    vec4 prevViewPos  = gbufferPreviousModelView * prevWorldPos;
    vec4 prevProj     = gbufferPreviousProjection * prevViewPos;
    previousPosition  = prevProj;

    // ── Apply Jitter ──────────────────────────────────────────────────────────
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

    // ── Texel-snap (must match shadow.vsh exactly) ────────────────────────────
    vec4 originClip  = shadowProjection * shadowModelView * vec4(0.0, 0.0, 0.0, 1.0);
    float texelNDC   = 2.0 / SHADOW_MAP_RES;
    vec2 snapOffset  = round(originClip.xy / texelNDC) * texelNDC - originClip.xy;
    shadowPos.xy    += snapOffset;

    // Radial distortion
    shadowPos.xy = distortShadow(shadowPos.xy);
}
