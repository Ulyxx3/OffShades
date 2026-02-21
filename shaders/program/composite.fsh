
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// OffShades â€” composite.fsh (TAA Pass)
//
// Core Temporal Anti-Aliasing algorithm:
// 1. Fetch current frame color and velocity.
// 2. Reproject current pixel to previous frame coordinates using velocity.
// 3. Fetch history color from ping-pong buffer.
// 4. Neighborhood clipping (Catmull-Rom or YCoCg bbox) to prevent ghosting.
// 5. Blend current and history (e.g. 10% current, 90% history).
// 6. Output to next ping-pong buffer.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

in vec2 texCoord;

// G-buffers
uniform sampler2D colortex0; // Current Color
uniform sampler2D colortex3; // Velocity (xy)

// Ping-pong history buffers
uniform sampler2D colortex1; // History Ping
uniform sampler2D colortex2; // History Pong

uniform int  frameCounter;
uniform float frameTimeCounter;
uniform vec2 texelSize; // 1.0 / vec2(viewWidth, viewHeight)
uniform int isEyeInWater;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;

#include "/include/taa.glsl"

/* DRAWBUFFERS:12 */
// We write to colortex1 OR colortex2 depending on the frame parity.
// Iris automatically handles reading the *other* one in the next pass if requested.
// But to do ping-pong safely in a single pass, we just output to both and read the correct one.
// Wait, correct ping-pong in Optifine/Iris:
// We read from the "previous" buffer and write to the "current" buffer.
layout(location = 0) out vec4 historyPingOut; // Write to colortex1
layout(location = 1) out vec4 historyPongOut; // Write to colortex2

// RGB <-> YCoCg conversions for neighborhood clipping
vec3 rgbToYcocg(vec3 k) {
    return vec3(
         k.r/4.0 + k.g/2.0 + k.b/4.0,
         k.r/2.0           - k.b/2.0,
        -k.r/4.0 + k.g/2.0 - k.b/4.0
    );
}

vec3 ycocgToRgb(vec3 k) {
    return vec3(
        k.x + k.y - k.z,
        k.x       + k.z,
        k.x - k.y - k.z
    );
}

void main() {
    // 0. Un-jitter current coordinates
    vec2 jitter     = getJitter(frameCounter) * texelSize * 2.0;
    vec2 unjittered = texCoord - jitter * 0.5; // NDC to UV scale

    // 1. Current frame color
    vec2 sampleCoords = unjittered;
    
    if (isEyeInWater == 1) {
        // Screen-space refraction (distortion)
        vec2 distortion = vec2(
            sin(unjittered.y * 50.0 + frameTimeCounter * 3.0),
            cos(unjittered.x * 50.0 + frameTimeCounter * 2.5)
        ) * 0.003;
        sampleCoords = clamp(unjittered + distortion, 0.001, 0.999);
    }

    vec3 currentColor = texture(colortex0, sampleCoords).rgb;
    
    // 1.5 Underwater Fog / Absorption
    if (isEyeInWater == 1) {
        float rawDepth = texture(depthtex0, sampleCoords).r;
        vec4 ndc = vec4(0.0, 0.0, 2.0 * rawDepth - 1.0, 1.0);
        vec4 view = gbufferProjectionInverse * ndc;
        float viewDist = -view.z / view.w;
        
        vec3 waterAmbient = vec3(0.02, 0.25, 0.45);
        float fogDensity = 0.05;
        float fogFactor = exp(-viewDist * fogDensity);
        
        // At max depth, it fades entirely to the deep water color
        currentColor = mix(waterAmbient, currentColor, clamp(fogFactor, 0.0, 1.0));
    }
    
    // 2. Velocity
    vec2 velocity = texture(colortex3, unjittered).xy;
    
    // If velocity is exactly (0,0), it might be sky or unwritten background.
    // For now, we assume velocity is computed everywhere geometry exists.
    
    // 3. Reprojection coordinates (back to previous unjittered frame)
    vec2 prevCoord = unjittered - velocity;
    
    // 4. Read History
    // frameCounter % 2 == 0: Read from Pong (2), Write to Ping (1)
    // frameCounter % 2 == 1: Read from Ping (1), Write to Pong (2)
    vec3 historyColor;
    bool writeToPing = (frameCounter % 2 == 0);
    
    if (writeToPing) {
        historyColor = texture(colortex2, prevCoord).rgb;
    } else {
        historyColor = texture(colortex1, prevCoord).rgb;
    }

    // Out-of-bounds check
    if (prevCoord.x < 0.0 || prevCoord.x > 1.0 || prevCoord.y < 0.0 || prevCoord.y > 1.0) {
        historyColor = currentColor;
    }

    // 5. Neighborhood Clipping (prevent ghosting)
    // Sample a 3x3 neighborhood of the current frame
    vec3 minColor = vec3(9999.0);
    vec3 maxColor = vec3(-9999.0);
    
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec3 neighbor = texture(colortex0, unjittered + vec2(x, y) * texelSize).rgb;
            vec3 ycocg    = rgbToYcocg(neighbor);
            minColor      = min(minColor, ycocg);
            maxColor      = max(maxColor, ycocg);
        }
    }

    // Clip history to the current 3x3 bounding box
    vec3 historyYcocg = rgbToYcocg(historyColor);
    historyYcocg      = clamp(historyYcocg, minColor, maxColor);
    historyColor      = ycocgToRgb(historyYcocg);

    // 6. Temporal Blend
    // Mix factor: higher = more ghosting but smoother. Lower = more aliased but responsive.
    // Usually 0.05 to 0.1 for the current frame.
    float blendFactor = 0.10; 
    
    // If velocity is very high, trust current frame more (reduce ghosting on fast moving objects)
    float motionDist = length(velocity / texelSize);
    if (motionDist > 5.0) {
        blendFactor = mix(0.10, 0.40, clamp((motionDist - 5.0) / 10.0, 0.0, 1.0));
    }

    vec3 finalColor = mix(historyColor, currentColor, blendFactor);

    // 7. Output Ping-Pong
    historyPingOut = vec4(0.0);
    historyPongOut = vec4(0.0);
    
    if (writeToPing) {
        historyPingOut = vec4(finalColor, 1.0); // Output to colortex1
        // colortex2 is essentially unmodified this frame (read-only)
    } else {
        historyPongOut = vec4(finalColor, 1.0); // Output to colortex2
        // colortex1 is unmodified
    }
}

