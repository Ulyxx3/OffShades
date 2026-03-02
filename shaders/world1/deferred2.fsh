#version 330


#define DIMENSION_END


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const int shadowMapResolution = 2048; // [1024 2048 4096 8192 16384 32768]
const float shadowDistance = 192.0; // [64.0 96.0 128.0 192.0 256.0 384.0 512.0 768.0 1024.0 1536.0 2048.0]

#ifdef MC_GL_VENDOR_NVIDIA
	uniform sampler2D shadowtex1;
#else
	uniform sampler2D shadowtex0;
#endif
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;


/* DRAWBUFFERS:2 */
layout(location = 0) out vec4 deferredOutput2;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;


#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/Uniform/ShadowTransformsEnd.glsl"
#include "/Lib/BasicFounctions/TemporalNoise.glsl"


#define PROGRAM_GI_0
#include "/Lib/IndividualFounctions/GlobalIllumination.glsl"


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	deferredOutput2 = GI_TemporalFilter();
}
