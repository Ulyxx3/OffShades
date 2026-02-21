#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.vsh  (Step 3 — clean shadow rewrite)
//
// Normal offset bias: push shadow receiver along world normal BEFORE
// projecting into shadow space. Physically correct, works for all angles.
// With 8192px shadow map resolution, offset of 0.12 is sufficient.
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

// ── Radial distortion (same formula as shadow.vsh) ────────────────────────────
// Concentrates shadow map texels near the player for higher effective resolution.
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

    // Light direction in world space
    vec3 lightDirWorld = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float NdotL        = dot(worldNormal, lightDirWorld);

    // Normal offset: front-facing faces get 0, oblique/back faces get up to 0.15
    float offsetScale     = clamp(1.0 - NdotL, 0.0, 1.0);
    float normalOffsetDist = 0.15 * offsetScale;
    vec4 biasedWorldPos   = worldPos + vec4(worldNormal * normalOffsetDist, 0.0);

    shadowPos    = shadowProjection * (shadowModelView * biasedWorldPos);
    shadowPos.xy = distortShadow(shadowPos.xy);
}
