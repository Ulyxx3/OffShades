
// OffShades — gbuffers_entities_translucent.fsh
// Translucent entities: endermen, spiders, bats, some projectiles
// Identical to gbuffers_entities but keeps partial alpha transparency.

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
    // No discard — allow transparency for endermen shimmer, bat wings, etc.
    albedo *= glColor;

    vec3 lighting = texture(lightmap, lmCoord).rgb;
    albedo.rgb *= lighting;

    fragColor = albedo;
}
