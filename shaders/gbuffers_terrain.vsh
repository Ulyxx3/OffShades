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

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;
out vec4 shadowPos;

const float SHADOW_MAP_RES = 8192.0;
const float SHADOW_DISTORT = 0.08;

vec2 distortShadow(vec2 pos) {
    float factor = length(pos) * (1.0 - SHADOW_DISTORT) + SHADOW_DISTORT;
    return pos / factor;
}

void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor  = gl_Color;
    lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    // World-space normal
    vec3 viewNormal  = normalize(gl_NormalMatrix * gl_Normal);
    vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * viewNormal);
    fragNormal = worldNormal;

    vec4 viewPos  = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos = gbufferModelViewInverse * viewPos;

    // Normal offset: oblique faces get up to 0.15 blocks of push
    vec3 lightDirWorld    = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float NdotL           = dot(worldNormal, lightDirWorld);
    float offsetScale     = clamp(1.0 - NdotL, 0.0, 1.0);
    float normalOffsetDist = 0.15 * offsetScale;
    vec4 biasedWorldPos   = worldPos + vec4(worldNormal * normalOffsetDist, 0.0);

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
