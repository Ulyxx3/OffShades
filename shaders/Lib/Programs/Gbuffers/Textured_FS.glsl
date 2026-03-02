//Textured_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D tex;


/* DRAWBUFFERS:035 */
layout(location = 0) out vec4 gbufferOutput0;
layout(location = 1) out vec4 gbufferOutput3;
layout(location = 2) out vec4 gbufferOutput5;


in vec4 color;
in vec2 texCoord;
in vec2 blockLight;


void main(){
//albedo
    vec4 albedo = texture(tex, texCoord);
    albedo *= color;

	if(albedo.a < 0.1) discard;

	#ifdef WHITE_DEBUG_WORLD
        albedo.rgb = vec3(1.0);
    #endif


//normal
	vec2 normalEnc = EncodeNormal(vec3(0.0, 0.0, 1.0));


//material ID
	float materialIDs = MATID_PARTICLE + float(blockLight.x > 0.9999);


	gbufferOutput0 = vec4(albedo.rgb, 1.0);
    gbufferOutput3 = vec4(normalEnc, blockLight);
    gbufferOutput5 = vec4(0.0, 0.0, (materialIDs + 0.1) / 255.0, Pack2x8(vec2(0.0, 1.0)));
}
