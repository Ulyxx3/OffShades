#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.vsh  (Step 2 v4)
// IMPORTANT: distortShadow() here MUST match the one in shadow.vsh exactly.
// ─────────────────────────────────────────────────────────────────────────────

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;
out vec4 shadowPos;

// ── Same distortion as shadow.vsh ─────────────────────────────────────────────
const float SHADOW_DISTORT = 0.15;
vec2 distortShadow(vec2 pos) {
    float factor = length(pos) * (1.0 - SHADOW_DISTORT) + SHADOW_DISTORT;
    return pos / factor;
}

void main() {
    gl_Position = ftransform();

    texCoord   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor    = gl_Color;
    lmCoord    = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    fragNormal = normalize(gl_NormalMatrix * gl_Normal);

    // view → world → shadow clip
    vec4 viewPos  = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    shadowPos     = shadowProjection * (shadowModelView * worldPos);

    // Apply same radial distortion as in shadow.vsh
    // (orthographic proj → w = 1, so XY is already in NDC)
    shadowPos.xy = distortShadow(shadowPos.xy);
}
