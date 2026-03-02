//Armor_Glint_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D tex;


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 gbufferOutput0;


in vec4 color;
in vec2 texCoord;


void main(){
	vec4 albedo = texture(tex, texCoord);
	albedo *= color;

	#ifdef WHITE_DEBUG_WORLD
		albedo.rgb = vec3(1.0);
	#endif

	gbufferOutput0 = albedo;
}
