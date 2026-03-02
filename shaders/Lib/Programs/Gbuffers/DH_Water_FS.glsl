//DH_Water_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform float frameTimeCounter;
uniform float wetness;
uniform int isEyeInWater;

uniform float eyeSnowySmooth;
uniform float eyeNoPrecipitationSmooth;

uniform sampler2D depthtex0;
uniform sampler2D noisetex;


/* DRAWBUFFERS:46 */
layout(location = 0) out vec4 gbufferOutput4;
layout(location = 1) out vec4 gbufferOutput6;


in vec4 color;
in vec3 viewPos;
in mat3 tbn;
in vec2 blockLight;
flat in float materialIDs;


#include "/Lib/IndividualFounctions/WaterWaves.glsl"


float LinearDepth_From_ScreenDepth(float depth){
	depth = depth * 2.0 - 1.0;
	return 1.0 / (depth * gbufferProjectionInverse[2][3] + gbufferProjectionInverse[3][3]);
}

vec4 DH_noise(vec4 color, vec3 pos){
	const float steps = DH_TEXTURE_NOISE_STEPS;
	pos = floor(pos * steps) / steps;
	
	float weight = Luminance(color.rgb) * 2.0 - 1.0;
	weight = 1.0 - weight * weight;
	//weight *= float(materialIDs == MATID_LEAVES) + 1.0;
	weight *= DH_TEXTURE_NOISE_STRENGTH * color.a;

	float noise = fract(sin(dot(pos.xy + fract(sin(pos.z * (91.3458)) * 47453.5453), vec2(12.9898, 78.233))) * 43758.5453);
	noise = (noise * 2.0 - 1.0) * weight;

	color.rgb = saturate(color.rgb - color.rgb * noise);
	return color;
}


void main(){
	if (texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x < 1.0) discard;

	vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;

	
//albedo
	#ifdef DH_TEXTURE_NOISE
		vec4 tex = DH_noise(color, worldPos + cameraPosition + mat3(gbufferModelView) * tbn[2] * 0.001);
	#else
		vec4 tex = color;
	#endif


	#ifdef WHITE_DEBUG_WORLD
		tex.rgb = vec3(1.0);
	#endif

//normal
	vec3 waterNormal = vec3(0.0, 0.0, 1.0);

	vec3 mcPos = worldPos + cameraPosition;

	bool iswater = materialIDs == MATID_WATER;
	
	if (iswater){
		waterNormal = GetWavesNormal(mcPos, 18.0);
	}

	waterNormal = tbn * waterNormal;

	if (iswater){
		vec3 viewDir = normalize(-viewPos);
		#ifdef DISTANT_HORIZONS
			const float weight = 0.3;
		#else
			const float weight = 0.07;
		#endif
		waterNormal = normalize(waterNormal + (tbn[2] / (max(0.0, dot(tbn[2], viewDir)) + 0.001)) * weight);
	}

	vec2 normalEnc = EncodeNormal(waterNormal);


	gbufferOutput4 = vec4(normalEnc, blockLight);
	gbufferOutput6 = vec4(Pack2x8(tex.rg), Pack2x8(tex.ba), (materialIDs + 0.1) / 255.0, float(iswater));
}
