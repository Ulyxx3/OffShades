
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// OffShades â€” gbuffers_water.vsh
// Vertex shader for translucent geometry (water, stained glass, iceâ€¦).

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
// Step 1: Pass-through identical to terrain.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

out vec2 texCoord;
out vec4 glColor;
out vec2 lmCoord;
out vec3 fragNormal;
out vec4 currentPosition;
out vec4 previousPosition;

out vec3 worldPosition;
flat out int blockId;

attribute vec4 mc_Entity;

uniform int   frameCounter;
uniform float viewWidth;
uniform float viewHeight;

#include "/include/taa.glsl"

void main() {
    gl_Position = ftransform();

    // â”€â”€ Velocity calculation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    vec4 viewPos  = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    worldPos.xyz += cameraPosition; // Absolute world coordinates
    
    worldPosition = worldPos.xyz;
    blockId = int(mc_Entity.x);

    // Current screen position (un-jittered for velocity)
    vec4 currentProj = gl_ProjectionMatrix * viewPos;
    currentPosition  = currentProj;

    // Previous screen position
    vec4 prevWorldPos = worldPos;
    prevWorldPos.xyz -= previousCameraPosition; // Relative to previous camera
    vec4 prevViewPos  = gbufferPreviousModelView * prevWorldPos;
    vec4 prevProj     = gbufferPreviousProjection * prevViewPos;
    previousPosition  = prevProj;

    // â”€â”€ Apply Jitter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    vec2 jitter = getJitter(frameCounter);
    gl_Position.xy += jitter * vec2(2.0/viewWidth, 2.0/viewHeight) * gl_Position.w;
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor     = gl_Color;
    lmCoord     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    fragNormal  = normalize(gl_NormalMatrix * gl_Normal);
}

