//Water_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float wetness;
uniform float rainStrength;
uniform int isEyeInWater;

uniform float eyeSnowySmooth;
uniform float eyeNoPrecipitationSmooth;

uniform sampler2D tex;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;


/* DRAWBUFFERS:460 */
layout(location = 0) out vec4 gbufferOutput4;
layout(location = 1) out vec4 gbufferOutput6;
#if MC_VERSION > 11605
	layout(location = 2) out vec4 gbufferOutput0;
#endif

in vec3 color;
in vec2 texCoord;
in vec3 viewPos;
#ifdef TERRAIN_VS_TBN
	in mat3 tbn;
#endif
in vec2 blockLight;
flat in float materialIDs;


#define PHYSICS_OCEAN_SUPPORT
#define PHYSICS_FS
#ifdef PHYSICS_OCEAN
	#include "/Lib/IndividualFounctions/PhysicsOceans.glsl"
#else
	#include "/Lib/IndividualFounctions/WaterWaves.glsl"
#endif

#include "/Lib/IndividualFounctions/Ripple.glsl"


void main(){
//TBN
	vec2 duv1 = dFdx(texCoord);
	vec2 duv2 = dFdy(texCoord);
	
	#ifndef TERRAIN_VS_TBN
		vec3 dp1 = dFdx(viewPos);
		vec3 dp2 = dFdy(viewPos);

		vec3 N = normalize(cross(dp1, dp2));
		vec3 dp2perp = cross(dp2, N);
		vec3 dp1perp = cross(N, dp1);
		vec3 T = normalize(dp2perp * duv1.x + dp1perp * duv2.x);
		vec3 B = normalize(dp2perp * duv1.y + dp1perp * duv2.y);
		float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
		mat3 tbn = mat3(T * invmax, B * invmax, N);
	#endif


//albedo
	vec4 tex = textureGrad(tex, texCoord, duv1, duv2);
	tex.rgb *= color;

	#ifdef WHITE_DEBUG_WORLD
		tex.rgb = vec3(1.0);
	#endif


//wet
	vec3 mcPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz + cameraPosition;
	float NdotU = dot(tbn[2], gbufferModelView[1].xyz);

	#ifdef ENABLE_PBR

		#ifdef DIMENSION_MAIN
			#ifndef DISABLE_LOCAL_PRECIPITATION
				float wet = wetness * (1.0 - eyeSnowySmooth) * (1.0 - eyeNoPrecipitationSmooth) + SURFACE_WETNESS;
			#else
				float wet = wetness + SURFACE_WETNESS;
			#endif

			wet *= step(0.9, blockLight.y);

			vec2 rainNormal = vec2(0.0);
			if (wet > 1e-7){
				wet *= GetModulatedRainSpecular(mcPos);
						
				float lightMask = saturate(blockLight.y * 10.0 - 9.0);
				if (isEyeInWater == 1) NdotU = -NdotU;

				#ifdef RAIN_SPLASH_EFFECT
					float splashStrength = saturate(NdotU * 2.0 - 1.0) * lightMask * 4.0;
					if (splashStrength > 0.0) rainNormal = GetRainNormal(mcPos, splashStrength, wet);
				#endif

				wet *= lightMask;
				wet *= saturate(NdotU * 0.5 + 0.5);
			}

		#else
			float wet = SURFACE_WETNESS;

			wet *= GetModulatedRainSpecular(mcPos);
			wet *= saturate(NdotU * 0.5 + 0.5);
		#endif

	#else
		float wet = 0.0;
	#endif


//normal
	vec3 waterNormal = vec3(0.0, 0.0, 1.0);

	bool iswater = materialIDs == MATID_WATER;

	#ifdef PHYSICS_OCEAN

		if (iswater){
				WavePixelData wave = physics_wavePixel(physics_localPosition.xz, physics_localWaviness, physics_iterationsNormal, physics_gameTime);
				waterNormal = mat3(gbufferModelView) * wave.normal;
		}else{
			#ifdef MC_NORMAL_MAP
				waterNormal = DecodeNormalTex(textureGrad(normals, texCoord, duv1, duv2).rgb);
			#endif

			waterNormal = tbn * waterNormal;

			#if defined ENABLE_PBR && defined DIMENSION_MAIN && defined RAIN_SPLASH_EFFECT 
				waterNormal = normalize(waterNormal + mat3(gbufferModelView) * vec3(rainNormal.x, 0.0, rainNormal.y));
			#endif
		}

	#else

		if (iswater){
			#ifdef WATER_PARALLAX
				mcPos = GetWaterParallaxCoord(mcPos, normalize(viewPos.xyz * tbn));
			#endif
			NdotU = saturate(NdotU + float(isEyeInWater == 1) * 2.0);
			waterNormal = GetWavesNormal(mcPos, max(NdotU * 15.0 + 3.0, 0.0));

		}else{
			#ifdef MC_NORMAL_MAP
				waterNormal = DecodeNormalTex(textureGrad(normals, texCoord, duv1, duv2).rgb);
				#ifdef ENABLE_PBR
					waterNormal = mix(waterNormal, vec3(0.0, 0.0, 1.0), saturate(wet * 1.5));
				#endif
			#endif
		}

		waterNormal = tbn * waterNormal;

		#if defined ENABLE_PBR && defined DIMENSION_MAIN && defined RAIN_SPLASH_EFFECT 
			waterNormal = normalize(waterNormal + mat3(gbufferModelView) * vec3(rainNormal.x, 0.0, rainNormal.y));
		#endif

		if (iswater){
			vec3 viewDir = normalize(-viewPos.xyz);
			#ifdef DISTANT_HORIZONS
				const float weight = 0.25;
			#else
				const float weight = 0.07;
			#endif
			waterNormal = normalize(waterNormal.xyz + (tbn[2] / (max(0.0, dot(tbn[2], viewDir)) + 0.001)) * weight);
		}

	#endif


	vec2 normalEnc = EncodeNormal(waterNormal);



	gbufferOutput4 = vec4(normalEnc, blockLight);
	gbufferOutput6 = vec4(Pack2x8(tex.rg), Pack2x8(tex.ba), (materialIDs + 0.1) / 255.0, float(iswater));

	#if MC_VERSION > 11605
		tex.a = materialIDs == MATID_LAND ? tex.a : 0.0;
		gbufferOutput0 = tex;
	#endif
}
