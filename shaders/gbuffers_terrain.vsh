#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.vsh  (Step 2 v6 — world-space normals)
// ─────────────────────────────────────────────────────────────────────────────

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;   // world-space normal (stable across camera rotations)
out vec4 shadowPos;

// Same distortion as shadow.vsh
const float SHADOW_DISTORT = 0.15;
vec2 distortShadow(vec2 pos) {
    float factor = length(pos) * (1.0 - SHADOW_DISTORT) + SHADOW_DISTORT;
    return pos / factor;
}

void main() {
    gl_Position = ftransform();

    texCoord  = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor   = gl_Color;
    lmCoord   = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    // World-space normal — not affected by camera rotation
    // mat3(gbufferModelViewInverse) rotates from view space → world space
    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    fragNormal      = normalize(mat3(gbufferModelViewInverse) * viewNormal);

    // Shadow space transform
    vec4 viewPos  = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    shadowPos     = shadowProjection * (shadowModelView * worldPos);
    shadowPos.xy  = distortShadow(shadowPos.xy);
}
