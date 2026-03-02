//Line_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


/* DRAWBUFFERS:035 */
layout(location = 0) out vec4 gbufferOutput0;
layout(location = 1) out vec4 gbufferOutput3;
layout(location = 2) out vec4 gbufferOutput5;


flat in vec4 color;


void main(){
	vec4 albedo = color;

	if (albedo.a < 0.1) discard;

	if (albedo.a == 0.4)
		albedo.rgb = vec3(SELECTION_BOX_COLOR_R, SELECTION_BOX_COLOR_G, SELECTION_BOX_COLOR_B);

	gbufferOutput0 = vec4(albedo.rgb, 1.0);
	gbufferOutput3 = vec4(EncodeNormal(vec3(0.0, 0.0, 1.0)), 0.0, 0.0);
	gbufferOutput5 = vec4(0.0, 0.0, (MATID_SELECTION + 0.1) / 255.0, Pack2x8(vec2(0.0, 1.0)));
}
