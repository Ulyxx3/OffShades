
// OffShades — gbuffers_skytextured.fsh
// Textured sky objects: sun disc, moon disc, stars billboard

in vec2 texCoord;
in vec4 glColor;

uniform sampler2D gtexture;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    vec4 albedo = texture(gtexture, texCoord);
    // Keep semi-transparent alpha for sun halo, moon, stars
    albedo *= glColor;
    fragColor = albedo;
}
