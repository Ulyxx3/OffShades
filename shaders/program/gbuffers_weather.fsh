
// OffShades — gbuffers_weather.fsh
// Rain & snow particles

in vec2 texCoord;
in vec4 glColor;

uniform sampler2D gtexture;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    vec4 albedo = texture(gtexture, texCoord);
    albedo *= glColor;
    fragColor = albedo;
}
