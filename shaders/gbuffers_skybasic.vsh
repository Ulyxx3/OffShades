#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_skybasic.vsh  (Step 3)
// Passes world-space view direction used for sky gradient computation.
// ─────────────────────────────────────────────────────────────────────────────

uniform mat4 gbufferModelViewInverse;

out vec4 glColor;
out vec3 viewDirWorld;

void main() {
    gl_Position = ftransform();
    glColor     = gl_Color;

    // Eye-space position of this sky vertex → world-space direction
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    viewDirWorld = normalize(mat3(gbufferModelViewInverse) * normalize(viewPos.xyz));
}
