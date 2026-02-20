#version 330 compatibility

// OffShades — gbuffers_entities.fsh
// Entities (mobs, players, item frames, etc.)
// Note: Iris injects a hurt-flash tint via gl_Color alpha — we preserve it.

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
    if (albedo.a < 0.1) discard;

    albedo *= glColor;

    vec3 lighting = texture(lightmap, lmCoord).rgb;
    albedo.rgb *= lighting;

    fragColor = albedo;
}
