//DH_Terrain_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;
uniform float far;
uniform float wetness;

uniform float eyeSnowySmooth;
uniform float eyeNoPrecipitationSmooth;


/* DRAWBUFFERS:035 */
layout(location = 0) out vec4 gbufferOutput0;
layout(location = 1) out vec4 gbufferOutput3;
layout(location = 2) out vec4 gbufferOutput5;


in vec3 color;
in vec3 viewPos;
in vec3 viewNormal;
in vec2 blockLight;
flat in float materialIDs;


void DH_noise(inout vec3 color, vec3 pos){
	const float steps = DH_TEXTURE_NOISE_STEPS;
	pos = floor(pos * steps) / steps;
	
	float weight = Luminance(color) * 2.0 - 1.0;
	weight = 1.0 - weight * weight;
	weight *= float(materialIDs == MATID_LEAVES) + 1.0;
	weight *= DH_TEXTURE_NOISE_STRENGTH;

	float noise = fract(sin(dot(pos.xy + fract(sin(pos.z * (91.3458)) * 47453.5453), vec2(12.9898, 78.233))) * 43758.5453);
	noise = (noise * 2.0 - 1.0) * weight;

	color = saturate(color - color * noise);
}


void main(){
	#ifdef DH_TERRAIN_CULLING
		if (length(viewPos) < far * 0.7) discard;
	#endif

	vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;

//albedo
	vec3 albedo = color;
	#ifdef DH_TEXTURE_NOISE
		if (fract(materialIDs) != 0.1) DH_noise(albedo, worldPos + cameraPosition + mat3(gbufferModelView) * viewNormal * 0.001);
	#endif

	#ifdef WHITE_DEBUG_WORLD
		albedo = vec3(1.0);
	#endif

//wet effect
	#ifdef ENABLE_PBR

		float NdotU = dot(viewNormal, gbufferModelView[1].xyz);

		#ifdef DIMENSION_MAIN
			#ifndef DISABLE_LOCAL_PRECIPITATION
				float wet = wetness * (1.0 - eyeSnowySmooth) * (1.0 - eyeNoPrecipitationSmooth) + SURFACE_WETNESS;
			#else
				float wet = wetness + SURFACE_WETNESS;
			#endif
			wet *= 0.5;
			wet *= saturate(blockLight.y * 10.0 - 9.0);
			wet *= saturate(NdotU * 0.5 + 0.5);
		#else
			float wet = SURFACE_WETNESS;
			wet *= 0.5;
			wet *= saturate(NdotU * 0.5 + 0.5);
		#endif

	#else
		float wet = 0.0;
	#endif

//normal
	vec2 normalEnc = EncodeNormal(viewNormal);


	gbufferOutput0 = vec4(albedo, 1.0);
	gbufferOutput3 = vec4(normalEnc, blockLight);
	gbufferOutput5 = vec4(0.0, 0.0, (materialIDs + 0.1) / 255.0, Pack2x8(vec2(wet, 1.0)));
}