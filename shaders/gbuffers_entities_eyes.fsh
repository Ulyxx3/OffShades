#version 330 compatibility

// OffShades — gbuffers_entities_eyes.fsh
// Glowing eye texture layer on mobs (spiders, endermen, etc.)
// These are emissive — no lightmap modulation, always full brightness.

in vec2 texCoord;
in vec4 glColor;

uniform sampler2D gtexture;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    vec4 albedo = texture(gtexture, texCoord);
    if (albedo.a < 0.1) discard;

    // Eyes are emissive — ignore lightmap to keep them always glowing
    fragColor = albedo * glColor;
}
