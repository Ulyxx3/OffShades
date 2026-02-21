#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.vsh  (Step 2 v7 — normal offset bias)
//
// KEY CHANGE: Normal offset bias applied HERE in vertex shader.
// Instead of shifting the depth value in the FSH (unstable at grazing angles),
// we push the shadow receiver position outward along the world normal BEFORE
// projecting into shadow space. This naturally handles all face orientations.
// ─────────────────────────────────────────────────────────────────────────────

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;

// shadowLightPosition: the current shadow-casting light (sun by day, moon by night)
// Always above the horizon — correct regardless of time of day.
uniform vec3 shadowLightPosition;

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;   // world-space, for smooth geometric attenuation in FSH
out vec4 shadowPos;

// Same distortion as shadow.vsh
const float SHADOW_DISTORT = 0.08;
vec2 distortShadow(vec2 pos) {
    float factor = length(pos) * (1.0 - SHADOW_DISTORT) + SHADOW_DISTORT;
    return pos / factor;
}

void main() {
    gl_Position = ftransform();

    texCoord  = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor   = gl_Color;
    lmCoord   = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    // World-space normal (stable across camera rotations)
    vec3 viewNormal  = normalize(gl_NormalMatrix * gl_Normal);
    vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * viewNormal);
    fragNormal       = worldNormal;

    // ── Normal offset bias ────────────────────────────────────────────────────
    // Push the vertex along the surface normal before shadow projection.
    // This moves the shadow receiver slightly "away" from the surface in
    // the direction where it's most needed — physically correct and works
    // for ALL face orientations including grazing angles.
    //
    // Offset is scaled by (1 - NdotL) so faces perpendicular to sun get
    // more offset (they need it most), faces directly lit get minimal offset.
    vec4 viewPos     = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos    = gbufferModelViewInverse * viewPos;

    // Shadow-casting light direction in world space (sun or moon)
    vec3 lightDirWorld = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float NdotL        = dot(worldNormal, lightDirWorld);

    // Adaptive offset: 0.0 for front faces, 0.20 for perpendicular faces
    // 0.20 instead of 0.12 to better handle steep/oblique faces
    float offsetScale     = clamp(1.0 - NdotL, 0.0, 1.0);
    float normalOffsetDist = 0.20 * offsetScale;
    vec4 biasedWorldPos   = worldPos + vec4(worldNormal * normalOffsetDist, 0.0);

    // Project into shadow space using the offset world position
    shadowPos    = shadowProjection * (shadowModelView * biasedWorldPos);
    shadowPos.xy = distortShadow(shadowPos.xy);
}
