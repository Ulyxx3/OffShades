#version 330 compatibility

// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_water.fsh
// Fragment shader for translucent geometry (water, stained glass, ice…).
//
// Step 1: Vanilla-accurate translucent rendering.
//         Reflections, waves and refraction come in a later step.
// ─────────────────────────────────────────────────────────────────────────────

in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;
in vec3 fragNormal;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    vec4 albedo = texture(gtexture, texCoord);

    // Water is translucent — don't fully discard, just keep alpha
    albedo *= glColor;

    vec3 lighting = texture(lightmap, lmCoord).rgb;
    albedo.rgb *= lighting;

    fragColor = albedo;
}
