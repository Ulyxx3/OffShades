//Basic_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


/* DRAWBUFFERS:035 */
layout(location = 0) out vec4 gbufferOutput0;
layout(location = 1) out vec4 gbufferOutput3;
layout(location = 2) out vec4 gbufferOutput5;


flat in vec4 color;
in vec2 texCoord;
in vec3 normal;
in vec2 blockLight;
flat in float isLine;


void main(){
	vec4 albedo = color;

	vec2 mcLightmap = blockLight;

	float materialIDs = MATID_LAND;

	#if MC_VERSION >= 11605
		if (albedo.a < 0.1) discard;
	#else
		if (albedo.a <= 0.004) discard;
	#endif

	if (albedo.a == 0.4){
		albedo.rgb = vec3(SELECTION_BOX_COLOR_R, SELECTION_BOX_COLOR_G, SELECTION_BOX_COLOR_B);
		materialIDs = MATID_SELECTION;
		mcLightmap = vec2(0.0);
	}

	if (isLine > 0.5){
		materialIDs = MATID_SELECTION;
		mcLightmap = vec2(0.0);
	}

	gbufferOutput0 = vec4(albedo.rgb, 1.0);
	gbufferOutput3 = vec4(EncodeNormal(normal), mcLightmap);
	gbufferOutput5 = vec4(0.0, 0.0, (materialIDs + 0.1) / 255.0, Pack2x8(vec2(0.0, 1.0)));
}
