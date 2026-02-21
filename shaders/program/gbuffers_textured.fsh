in vec2 texCoord;
in vec4 glColor;
in vec2 lmCoord;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    vec4 albedo = texture(gtexture, texCoord) * glColor;
    if (albedo.a < 0.1) discard;

    vec3 lighting = texture(lightmap, lmCoord).rgb;
    albedo.rgb *= lighting;

    fragColor = albedo;
}
