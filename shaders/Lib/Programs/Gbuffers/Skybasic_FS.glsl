//Skybasic_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 gbufferOutput0;


in vec4 color;


void main(){
	#if STAR_TYPE < 2
		discard;
	#endif
	gbufferOutput0 = color;
}

