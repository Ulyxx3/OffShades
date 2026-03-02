//Hand_Water_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelView;
uniform float wetness;

uniform float eyeSnowySmooth;
uniform float eyeNoPrecipitationSmooth;

uniform sampler2D tex;
uniform sampler2D normals;


/* DRAWBUFFERS:46 */
layout(location = 0) out vec4 gbufferOutput4;
layout(location = 1) out vec4 gbufferOutput6;


in vec3 color;
in vec2 texCoord;
in vec3 viewPos;
in vec2 blockLight;


void main(){
//TBN
	vec3 dp1 = dFdx(viewPos);
	vec3 dp2 = dFdy(viewPos);
	vec3 N = normalize(cross(dp1, dp2));
	vec2 duv1 = dFdx(texCoord);
	vec2 duv2 = dFdy(texCoord);
	vec3 dp2perp = cross(dp2, N);
	vec3 dp1perp = cross(N, dp1);
	vec3 T = normalize(dp2perp * duv1.x + dp1perp * duv2.x);
	vec3 B = normalize(dp2perp * duv1.y + dp1perp * duv2.y);
	float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
	mat3 tbn = mat3(T * invmax, B * invmax, N);


//albedo
	vec4 albedo = textureGrad(tex, texCoord, duv1, duv2);
	albedo.rgb *= color;

	#ifdef WHITE_DEBUG_WORLD
		albedo.rgb = vec3(1.0);
	#endif


//wet effect
	#ifdef ENABLE_PBR

		float NdotU = dot(tbn[2], gbufferModelView[1].xyz);

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
	#ifdef MC_NORMAL_MAP
		vec3 normalTex = DecodeNormalTex(textureGrad(normals, texCoord, duv1, duv2).rgb);
		#ifdef ENABLE_PBR 
			normalTex = mix(normalTex, vec3(0.0, 0.0, 1.0), saturate(wet * 1.5));
		#endif
	#else
		vec3 normalTex = vec3(0.0, 0.0, 1.0);
	#endif

	vec3 viewNormal = tbn * normalize(normalTex);

	#ifdef HAND_NORMAL_CLAMP
		vec3 viewDir = -normalize(viewPos);
		viewNormal = normalize(viewNormal + tbn[2] * inversesqrt(saturate(dot(viewNormal, viewDir)) + 0.001));
	#endif

	vec2 normalEnc = EncodeNormal(viewNormal);


	gbufferOutput4 = vec4(normalEnc, blockLight);
	gbufferOutput6 = vec4(Pack2x8(albedo.rg), Pack2x8(albedo.ba), (MATID_STAINEDGLASS + 0.1) / 255.0, 1.0);
}
