#version 330 compatibility

// OffShades — gbuffers_entities_glowing.fsh
// Glowing/emissive texture overlays: spider eyes, enderman eyes, etc.
// Emissive — no lightmap, always max brightness.

in vec2 texCoord;
in vec4 glColor;

uniform sampler2D gtexture;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    vec4 albedo = texture(gtexture, texCoord);
    if (albedo.a < 0.1) discard;
    fragColor = albedo * glColor;
}
