#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_terrain.vsh
// Step 2: + shadow map projection
// ─────────────────────────────────────────────────────────────────────────────

// ── Uniforms ──────────────────────────────────────────────────────────────────
// Shadow MVP matrix provided by Iris (sun-space transform)
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

// ── Outputs to fragment shader ────────────────────────────────────────────────
out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;
out vec4 shadowPos;        // Position in shadow map space (clip coords)

void main() {
    gl_Position = ftransform();

    texCoord   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor    = gl_Color;
    lmCoord    = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    fragNormal = normalize(gl_NormalMatrix * gl_Normal);

    // ── Shadow map projection ─────────────────────────────────────────────────
    // Transform vertex from view space → world space → shadow clip space
    vec4 viewPos  = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    vec4 shadowView = shadowModelView * worldPos;
    shadowPos = shadowProjection * shadowView;
}
