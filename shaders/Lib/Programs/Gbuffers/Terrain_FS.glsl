//Terrain_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelViewInverse;

uniform float frameTimeCounter;
uniform int frameCounter;
uniform ivec2 atlasSize;
uniform vec3 cameraPosition;
uniform float wetness;
uniform float rainStrength;
uniform int renderStage;

uniform float eyeSnowySmooth;
uniform float eyeNoPrecipitationSmooth;

#ifdef DIMENSION_END
	#include "/Lib/Uniform/ShadowModelViewEnd.glsl"
#endif

uniform sampler2D tex;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;


/* DRAWBUFFERS:035 */
layout(location = 0) out vec4 gbufferOutput0;
layout(location = 1) out vec4 gbufferOutput3;
layout(location = 2) out vec4 gbufferOutput5;


in vec3 color;
in vec2 texCoord;
in vec3 viewPos;
#ifdef TERRAIN_VS_TBN
	in mat3 tbn;
#endif
in vec2 blockLight;
flat in float materialIDs;
flat in float textureResolution;


#include "/Lib/IndividualFounctions/Parallax.glsl"
#include "/Lib/IndividualFounctions/Ripple.glsl"


vec4 SampleAnisotropic(vec2 coord, vec2 duv1, vec2 duv2, inout vec3 normalTex, inout vec4 specularTex){
	vec2 atlasTiles = vec2(atlasSize) / textureResolution;
	vec2 tilesCoord = coord * atlasTiles;

	//https://www.shadertoy.com/view/4lXfzn
	mat2 qd = inverse(mat2(dFdx(tilesCoord), dFdy(tilesCoord)));
	qd = transpose(qd) * qd;

	float d = determinant(qd);
	float t = (qd[0][0] + qd[1][1]) * 0.5;

	float D = sqrt(abs(t * t - d));
	float V = t - D;
	float v = t + D;
	vec2 A = vec2(-qd[0][1], qd[0][0] - V);
	A *= inversesqrt(V * dot(A, A) + 1e-20);

	float lod = log2(inversesqrt(v) * textureResolution);

	const float steps = ANISOTROPIC_FILTERING_QUALITY;
	const float rSteps = 1.0 / ANISOTROPIC_FILTERING_QUALITY;

	A *= rSteps;

	vec4 albedoSample = vec4(0.0);
	#ifdef ANISOTROPIC_FILTERING_NORMAL_SPECULAR
		vec3 normalSample = vec3(0.0);
		vec4 specularSample = vec4(0.0);
	#endif

	vec2 tilesBaseCoord = floor(tilesCoord);

	for (float i = 0.5 - steps * 0.5; i < steps * 0.5; i++){
		vec2 sampleCoord = i * A;
		sampleCoord = (tilesBaseCoord + fract(tilesCoord + sampleCoord)) / atlasTiles;

		vec4 sampleAlbedo = textureLod(tex, sampleCoord, lod);

		albedoSample += vec4(sampleAlbedo.rgb * sampleAlbedo.a, sampleAlbedo.a);

		#ifdef ANISOTROPIC_FILTERING_NORMAL_SPECULAR

			#ifdef MC_NORMAL_MAP
				normalSample += textureLod(normals, sampleCoord, lod).rgb * sampleAlbedo.a;
			#endif

			#ifdef MC_SPECULAR_MAP
				#if TEXTURE_EMISSIVENESS_MODE == 0
					specularSample += textureLod(specular, sampleCoord, lod) * sampleAlbedo.a;
				#endif
			#endif

		#endif
	}

	float weights = 1.0 / albedoSample.a;

	#ifdef ANISOTROPIC_FILTERING_NORMAL_SPECULAR

		#ifdef MC_NORMAL_MAP
			normalTex = DecodeNormalTex(normalSample * weights);
		#endif

		#ifdef MC_SPECULAR_MAP
			#if TEXTURE_EMISSIVENESS_MODE == 0
				specularTex = specularSample * weights;
			#else			
				specularTex = textureLod(specular, coord, 0.0);
			#endif
		#endif

	#else

		#ifdef MC_NORMAL_MAP
			normalTex = DecodeNormalTex(textureGrad(normals, coord, duv1, duv2).rgb);
		#endif

		#ifdef MC_SPECULAR_MAP
			#if TEXTURE_EMISSIVENESS_MODE == 0
				specularTex = textureGrad(specular, coord, duv1, duv2);
			#else			
				specularTex = textureLod(specular, coord, 0.0);
			#endif			
		#endif

	#endif
	
	return vec4(albedoSample.rgb * weights, textureLod(tex, coord, 0.0).a);
}



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

	#ifdef DIRECTIONAL_BLOCKLIGHT
		vec2 blockLightDir = vec2(dFdx(blockLight.x), dFdy(blockLight.x));
	#endif


//anisotropic filtering & parallax
	#ifdef DIMENSION_END
		vec3 shadowVector = mat3(gbufferModelView) * shadowModelViewInverseEnd[2].xyz;
	#else
		vec3 shadowVector = mat3(gbufferModelView) * shadowModelViewInverse[2].xyz;
	#endif

	float parallaxShadow = saturate(dot(tbn[2], shadowVector) * 200.0);


	#if PARALLAX_MODE > 0 && defined MC_NORMAL_MAP

		vec3 normalTex = vec3(0.0, 0.0, 1.0);
		ivec2 parallaxTexel = ParallaxOcclusionMapping(texCoord, tbn, shadowVector, duv1, duv2, normalTex, parallaxShadow);

		vec4 albedoTex = texelFetch(tex, parallaxTexel, 0);

		#if MC_VERSION >= 11605 && !defined IS_IRIS
			float alphaRef = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ? 0.004 : 0.1;
		#else
			float alphaRef = 0.1;
		#endif
		if (albedoTex.a < alphaRef) discard;


		#ifdef MC_SPECULAR_MAP
			vec4 specularTex = texelFetch(specular, parallaxTexel, 0);
		#else
			vec4 specularTex = vec4(0.0);
		#endif

	#else

		#if ANISOTROPIC_FILTERING_QUALITY > 0

			vec3 normalTex = vec3(0.0, 0.0, 1.0);
			vec4 specularTex = vec4(0.0);

			vec4 albedoTex = SampleAnisotropic(texCoord, duv1, duv2, normalTex, specularTex);

			#if MC_VERSION >= 11605 && !defined IS_IRIS
				float alphaRef = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ? 0.004 : 0.1;
			#else
				float alphaRef = 0.1;
			#endif

			if (albedoTex.a < alphaRef) discard;


		#else

			vec4 albedoTex = textureGrad(tex, texCoord, duv1, duv2);

			#if MC_VERSION >= 11605 && !defined IS_IRIS
				float alphaRef = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ? 0.004 : 0.1;
			#else
				float alphaRef = 0.1;
			#endif
			if (albedoTex.a < alphaRef) discard;

			#ifdef MC_NORMAL_MAP
				vec3 normalTex = DecodeNormalTex(textureGrad(normals, texCoord, duv1, duv2).rgb);
			#else
				vec3 normalTex = vec3(0.0, 0.0, 1.0);
			#endif


			#ifdef MC_SPECULAR_MAP
				#if TEXTURE_EMISSIVENESS_MODE == 0
					vec4 specularTex = textureGrad(specular, texCoord, duv1, duv2);
				#else			
					vec4 specularTex = textureLod(specular, texCoord, 0.0);
				#endif		
			#else
				vec4 specularTex = vec4(0.0);
			#endif
			
		#endif

	#endif


//blockLight
	float blockLightDirectional = blockLight.x;

	#ifdef DIRECTIONAL_BLOCKLIGHT
		float blockLightFwidth = abs(blockLightDir.x) + abs(blockLightDir.y);
		blockLightDir = normalize(vec2(tbn * vec3(blockLightDir, 1e-10)));

		float lightNormalWeight = dot(blockLightDir, normalTex.xy) * (1.0 - blockLight.x * 0.95) * DIRECTIONAL_BLOCKLIGHT_STRENGTH + 1.0;
		
		if (blockLightFwidth > 1e-5 &&  blockLight.x < 1.0) blockLightDirectional = clamp(blockLightDirectional * lightNormalWeight, 0.0, 0.9999);
	#endif


//albedo
	vec3 albedo = albedoTex.rgb * color;

	#ifdef WHITE_DEBUG_WORLD
		albedo = color.bbb;
	#endif


//wet effect
	#ifdef ENABLE_PBR

		vec3 mcPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz + cameraPosition;
		float NdotU = dot(tbn[2], gbufferModelView[1].xyz);

		#if defined TEXTURE_PBR_POROSITY && TEXTURE_PBR_FORMAT < 2
			float porosity = saturate(specularTex.b * (255.0 / 63.0) - step(64.0 / 255.0, specularTex.b));
		#else
			float porosity = TEXTURE_DEFAULT_POROSITY;
		#endif

		#ifdef DIMENSION_MAIN
			#ifndef DISABLE_LOCAL_PRECIPITATION
				float wet = wetness * (1.0 - eyeSnowySmooth) * (1.0 - eyeNoPrecipitationSmooth) + SURFACE_WETNESS;
			#else
				float wet = wetness + SURFACE_WETNESS;
			#endif

			wet *= saturate(abs(materialIDs - MATID_LAVA - 0.5) - 0.5); // lava & fire
			wet *= step(0.9, blockLight.y);

			vec2 rainNormal = vec2(0.0);
			if (wet > 1e-7){
				wet *= GetModulatedRainSpecular(mcPos);
				
				float lightMask = saturate(blockLight.y * 10.0 - 9.0);

				#ifdef RAIN_SPLASH_EFFECT
					float splashStrength = saturate(NdotU * 2.0 - 1.0) * lightMask * (2.0 - porosity);
					if (splashStrength > 0.0) rainNormal = GetRainNormal(mcPos, splashStrength, wet);
				#endif

				wet *= lightMask;
				wet *= saturate(NdotU * 0.5 + 0.5);
			}
		#else
			float wet = SURFACE_WETNESS;

			wet *= saturate(abs(materialIDs - MATID_LAVA - 0.5) - 0.5); // lava & fire
			wet *= GetModulatedRainSpecular(mcPos);
			wet *= saturate(NdotU * 0.5 + 0.5);
		#endif

	#else
		float wet = 0.0;
	#endif


//normal
	#if defined MC_NORMAL_MAP && defined ENABLE_PBR
		normalTex = mix(normalize(normalTex), vec3(0.0, 0.0, 1.0), saturate(wet * (1.6 - porosity * 0.6)));
	#endif


	vec3 viewNormal = tbn * normalize(normalTex);

	#if defined ENABLE_PBR && defined DIMENSION_MAIN && defined RAIN_SPLASH_EFFECT 
		viewNormal = normalize(viewNormal + mat3(gbufferModelView) * vec3(rainNormal.x, 0.0, rainNormal.y));
	#endif

	#ifdef TERRAIN_NORMAL_CLAMP
		vec3 viewDir = -normalize(viewPos);
		viewNormal = normalize(viewNormal + tbn[2] * inversesqrt(saturate(dot(viewNormal, viewDir)) + 0.001));
	#endif

	vec2 normalEnc = EncodeNormal(viewNormal);


//specular
	#if defined MC_SPECULAR_MAP && TEXTURE_PBR_FORMAT == 2
		specularTex.a = specularTex.b;
	#endif

	#if defined ENABLE_PBR && TEXTURE_PBR_FORMAT != 1
		if (materialIDs == MATID_REDSTONE && color.b == 0.0){
			float power = color.r;
			power = saturate(power * 1.1 - 0.1) * step(0.3, power);
			specularTex.a = max(specularTex.a, power * power * 0.3);
		}
	#endif


	gbufferOutput0 = vec4(albedo, 1.0);
	gbufferOutput3 = vec4(normalEnc, blockLightDirectional, blockLight.y);
	gbufferOutput5 = vec4(Pack2x8(specularTex.rg), Pack2x8(specularTex.ba), (materialIDs + 0.1) / 255.0, Pack2x8(vec2(wet, parallaxShadow)));
}
