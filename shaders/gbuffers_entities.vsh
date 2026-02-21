#version 330 compatibility

// OffShades — gbuffers_entities.vsh
// Entities (mobs, players, item frames, etc.)

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;
out vec4 currentPosition;
out vec4 previousPosition;

uniform int   frameCounter;
uniform float viewWidth;
uniform float viewHeight;

vec2 getJitter(int frame) {
    vec2 halton[8] = vec2[](
        vec2( 0.125, -0.375), vec2(-0.375,  0.125),
        vec2( 0.375,  0.375), vec2(-0.125, -0.125),
        vec2( 0.250, -0.125), vec2(-0.250,  0.375),
        vec2( 0.000, -0.500), vec2(-0.500,  0.000)
    );
    return halton[frame % 8];
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
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor     = gl_Color;
    lmCoord     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    fragNormal  = normalize(gl_NormalMatrix * gl_Normal);
}
