#version 330


#define DIMENSION_END


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* DRAWBUFFERS:1 */
layout(location = 0) out vec4 deferredOutput1;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;


#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFounctions/TemporalNoise.glsl"

#define PROGRAM_GI_1
#include "/Lib/IndividualFounctions/GlobalIllumination.glsl"
#include "/Lib/IndividualFounctions/GTAO.glsl"





////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main(){
	float depth = texelFetch(depthtex0, texelCoord, 0).x;
	vec3 viewPos = ViewPos_From_ScreenPos(texCoord, depth);

	#ifdef DISTANT_HORIZONS
		if (depth == 1.0){
			depth = texelFetch(dhDepthTex0, texelCoord, 0).x;
			viewPos = ViewPos_From_ScreenPos_DH(texCoord, depth);
		}
	#endif

	vec4 gi = vec4(0.0, 0.0, 0.0, 1.0);

	if (depth < 1.0){
		vec3 viewDir = normalize(viewPos);
		vec3 normal = DecodeNormal(texelFetch(colortex3, texelCoord, 0).xy);

		#ifdef GTAO
			if (-viewPos.z > 0.15) gi.a = GroundTruthBasedAmbientOcclusion(viewPos, -viewDir, normal);
		#endif

		#ifdef GI_RSM
			gi.rgb = GI_SpatialFilter(-viewPos.z, normal, viewDir);
		#endif
	}

	deferredOutput1 = gi;
}
