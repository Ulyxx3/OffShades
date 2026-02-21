#version 330 compatibility

// OffShades — gbuffers_entities.fsh
// Entities (mobs, players, item frames, etc.)
// Note: Iris injects a hurt-flash tint via gl_Color alpha — we preserve it.

in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;
in vec4 currentPosition;
in vec4 previousPosition;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

/* DRAWBUFFERS:03 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 velocityOut;

void main() {
    vec4 albedo = texture(gtexture, texCoord);
    if (albedo.a < 0.1) discard;

    albedo *= glColor;

    vec3 lighting = texture(lightmap, lmCoord).rgb;
    albedo.rgb *= lighting;

    fragColor = albedo;

    // ── Velocity Output ───────────────────────────────────────────────────────
    vec2 currentNDC  = currentPosition.xy / currentPosition.w;
    vec2 previousNDC = previousPosition.xy / previousPosition.w;
    
    vec2 currentUV   = currentNDC * 0.5 + 0.5;
    vec2 previousUV  = previousNDC * 0.5 + 0.5;
    vec2 velocity    = currentUV - previousUV;
    
    velocityOut     = vec4(velocity, 0.0, 1.0);
}
