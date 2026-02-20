#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.vsh  (Step 2 fix)
// ─────────────────────────────────────────────────────────────────────────────

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;
out vec4 shadowPos;     // shadow clip-space position

void main() {
    gl_Position = ftransform();

    texCoord   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor    = gl_Color;
    lmCoord    = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    fragNormal = normalize(gl_NormalMatrix * gl_Normal);

    // ── Shadow space transform ────────────────────────────────────────────────
    // view space → world/player space → shadow view → shadow clip
    vec4 viewPos  = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    shadowPos     = shadowProjection * (shadowModelView * worldPos);
}
