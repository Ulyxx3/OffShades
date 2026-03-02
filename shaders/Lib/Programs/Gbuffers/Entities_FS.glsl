//Entities_FS Spidereyes_FS Block_FS Hand_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelViewInverse;

uniform vec3 cameraPosition;
uniform float wetness;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform int frameCounter;

#ifdef PROGRAM_ENTITIES
	uniform vec4 entityColor;
	uniform int entityId;
#endif

#ifdef PROGRAM_BLOCK
	uniform int blockEntityId;
#endif

uniform float eyeSnowySmooth;
uniform float eyeNoPrecipitationSmooth;

#ifdef DIMENSION_END
	#include "/Lib/Uniform/ShadowModelViewEnd.glsl"
#endif

uniform sampler2D tex;
uniform sampler2D specular;
uniform sampler2D normals;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;


/* DRAWBUFFERS:035 */
layout(location = 0) out vec4 gbufferOutput0;
layout(location = 1) out vec4 gbufferOutput3;
layout(location = 2) out vec4 gbufferOutput5;


in vec4 color;
in vec2 texCoord;
in vec3 viewPos;
in vec2 blockLight;

#ifdef ENTITIES_VS_TBN
#endif
#if (defined ENTITIES_VS_TBN && (defined PROGRAM_ENTITIES || defined PROGRAM_SPIDEREYES) && (MC_VERSION < 11500 || MC_VERSION > 11604)) || (defined PROGRAM_HAND && MC_VERSION < 11300)
	in mat3 tbn;
#endif

#ifdef PROGRAM_BLOCK
	in vec4 portalCoord;

	const vec3[] COLORS = vec3[](
	vec3(0.022087, 0.098399, 0.110818),
	vec3(0.011892, 0.095924, 0.089485),
	vec3(0.027636, 0.101689, 0.100326),
	vec3(0.046564, 0.109883, 0.114838),
	vec3(0.064901, 0.117696, 0.097189),
	vec3(0.063761, 0.086895, 0.123646),
	vec3(0.084817, 0.111994, 0.166380),
	vec3(0.097489, 0.154120, 0.091064),
	vec3(0.106152, 0.131144, 0.195191),
	vec3(0.097721, 0.110188, 0.187229),
	vec3(0.133516, 0.138278, 0.148582),
	vec3(0.070006, 0.243332, 0.235792),
	vec3(0.196766, 0.142899, 0.214696),
	vec3(0.047281, 0.315338, 0.321970),
	vec3(0.204675, 0.390010, 0.302066),
	vec3(0.080955, 0.314821, 0.661491));

	const mat4 SCALE_TRANSLATE = mat4(0.5, 0.0, 0.0, 0.25,
									  0.0, 0.5, 0.0, 0.25,
									  0.0, 0.0, 1.0, 0.0,
									  0.0, 0.0, 0.0, 1.0);

	mat2 mat2_rotate_z(float radian){
		return mat2(cos(radian), -sin(radian), sin(radian), cos(radian));
	}

	mat4 end_portal_layer(float layer){
		mat4 translate = mat4(1.0, 0.0, 0.0, 17.0 / layer,
							  0.0, 1.0, 0.0, (2.0 + layer / 1.5) * (frameTimeCounter * 0.0005),
							  0.0, 0.0, 1.0, 0.0,
							  0.0, 0.0, 0.0, 1.0);

		mat2 rotate = mat2_rotate_z(radians((layer * layer * 4321.0 + layer * 9.0) * 2.0));

		mat2 scale = mat2((4.5 - layer / 4.0) * 2.0);

		return mat4(scale * rotate) * translate * SCALE_TRANSLATE;
	}
#endif


#include "/Lib/IndividualFounctions/Parallax.glsl"
#include "/Lib/IndividualFounctions/Ripple.glsl"


void main(){
//material ID

	#ifdef PROGRAM_ENTITIES
		float materialIDs = MATID_LAND;
		float noDiscard = 0.0;

		switch(entityId){
			case 7003:
				materialIDs = MATID_ENTITIES_PLAYER;
				break;

			case 14: case 15: case 22: case 26:
				materialIDs = MATID_ENTITIES_LIT_HIGH;
				break;

			case 200: case 7001:
				materialIDs = MATID_ENTITIES_LIT_MEDIUM;
				break;

			case 2: case 17: case 24: 
				materialIDs = MATID_ENTITIES_LIT_LOW;
				break;

			case 7000:
				materialIDs = MATID_LIGHTNING;
				noDiscard = 1.0;
				break;

			#ifdef IS_IRIS
				case 7002:
					materialIDs = 256.0;
					break;
			#endif

			case 829925:
				materialIDs = MATID_ENTITIES_SNOW;
				break;

			case 41:
				noDiscard = 1.0;
		}
	#endif

	#ifdef PROGRAM_SPIDEREYES
		float materialIDs = MATID_ENTITIES_LIT_LOW;
	#endif

	#ifdef PROGRAM_BLOCK
		float materialIDs = blockEntityId == 119 ? MATID_END_PORTAL : MATID_LAND;
	#endif

	#ifdef PROGRAM_HAND
		float materialIDs = MATID_HAND;
	#endif


//TBN
	vec2 duv1 = dFdx(texCoord);
	vec2 duv2 = dFdy(texCoord);

	#if (!defined ENTITIES_VS_TBN || (!defined PROGRAM_ENTITIES && !defined PROGRAM_SPIDEREYES) || (MC_VERSION >= 11500 && MC_VERSION <= 11604)) && (!defined PROGRAM_HAND || MC_VERSION >= 11300)
		vec3 dp1 = dFdx(viewPos);
		vec3 dp2 = dFdy(viewPos);

		vec3 N = normalize(cross(dp1, dp2));
		vec3 dp2perp = cross(dp2, N);
		vec3 dp1perp = cross(N, dp1);
		vec3 T = normalize(dp2perp * duv1.x + dp1perp * duv2.x);
		vec3 B = normalize(dp2perp * duv1.y + dp1perp * duv2.y);
		float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
		mat3 tbnMat = mat3(T * invmax, B * invmax, N);
	#else
		mat3 tbnMat = tbn;
		if(!gl_FrontFacing) tbnMat[2] = -tbnMat[2];
	#endif


//parallax
	#ifdef DIMENSION_END
		vec3 shadowVector = mat3(gbufferModelView) * shadowModelViewInverseEnd[2].xyz;
	#else
		vec3 shadowVector = mat3(gbufferModelView) * shadowModelViewInverse[2].xyz;
	#endif

	float parallaxShadow = saturate(dot(tbnMat[2], shadowVector) * 200.0);

	#ifdef ENTITIES_PARALLAX
	#endif

	#if defined ENTITIES_PARALLAX && PARALLAX_MODE > 0 && defined MC_NORMAL_MAP

		vec3 normalTex = vec3(0.0, 0.0, 1.0);
		ivec2 parallaxTexel = ParallaxOcclusionMapping(texCoord, tbnMat, shadowVector, duv1, duv2, normalTex, parallaxShadow);

		vec4 albedoTex = texelFetch(tex, parallaxTexel, 0);

		#if defined PROGRAM_ENTITIES
			#ifdef IS_IRIS
				if (albedoTex.a + noDiscard <= 0.004 || materialIDs > 255.0) discard;
			#else
				if (albedoTex.a + noDiscard <= 0.004) discard;
			#endif
		#elif defined PROGRAM_SPIDEREYES
			if (albedoTex.a < 0.1) discard; 
		#else
			if (albedoTex.a < 0.004) discard;
		#endif

		#ifdef MC_SPECULAR_MAP
			vec4 specularTex = texelFetch(specular, parallaxTexel, 0);
		#else
			vec4 specularTex = vec4(0.0);
		#endif

	#else

		vec4 albedoTex = textureGrad(tex, texCoord, duv1, duv2);

		#if defined PROGRAM_ENTITIES
			#ifdef IS_IRIS
				if (albedoTex.a + noDiscard <= 0.004 || materialIDs > 255.0) discard;
			#else
				if (albedoTex.a + noDiscard <= 0.004) discard;
			#endif
		#elif defined PROGRAM_SPIDEREYES
			if(albedoTex.a < 0.1) discard;
		#else
			if (albedoTex.a < 0.004) discard;
		#endif

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


//albedo
	vec4 albedo = vec4(albedoTex.rgb * color.rgb, albedoTex.a);
	#ifdef PROGRAM_ENTITIES
		#ifdef ENTITIES_STATUS_COLOR
			albedo.rgb = mix(albedo.rgb, entityColor.rgb, vec3(entityColor.a));
		#endif
	#endif

	#ifdef WHITE_DEBUG_WORLD
		albedo.rgb = vec3(1.0);
	#endif


//wet effect
	#ifdef ENABLE_PBR

		float NdotU = dot(tbnMat[2], gbufferModelView[1].xyz);

		#if defined TEXTURE_PBR_POROSITY && TEXTURE_PBR_FORMAT < 2
			float porosity = saturate(specularTex.b * (255.0 / 63.0) - step(64.0 / 255.0, specularTex.b));
		#else
			float porosity = TEXTURE_DEFAULT_POROSITY;
		#endif

		#ifdef PROGRAM_HAND

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

			vec3 mcPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz + cameraPosition;

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

					#if defined PROGRAM_ENTITIES || defined PROGRAM_SPIDEREYES
						if (materialIDs == MATID_ENTITIES_SNOW){
							#ifdef RAIN_SPLASH_EFFECT
								float splashStrength = saturate(NdotU * 2.0 - 1.0) * lightMask * (2.0 - porosity);
								if (splashStrength > 0.0) rainNormal = GetRainNormal(mcPos, splashStrength, wet);
							#endif
						}else{
							wet *= 0.5;
						}
					#else
						#ifdef RAIN_SPLASH_EFFECT
							float splashStrength = saturate(NdotU * 2.0 - 1.0) * lightMask * (2.0 - porosity);
							if (splashStrength > 0.0) rainNormal = GetRainNormal(mcPos, splashStrength, wet);
						#endif		
					#endif

					wet *= lightMask;
					wet *= saturate(NdotU * 0.5 + 0.5);
				}
			#else
				float wet = SURFACE_WETNESS;

				wet *= GetModulatedRainSpecular(mcPos);
				wet *= saturate(NdotU * 0.5 + 0.5);
			#endif
			
		#endif

	#else
		float wet = 0.0;	
	#endif



//normal
	#if defined MC_NORMAL_MAP && defined ENABLE_PBR
		normalTex = mix(normalize(normalTex), vec3(0.0, 0.0, 1.0), saturate(wet * (1.6 - porosity * 0.6)));
	#endif

	vec3 viewNormal = tbnMat * normalize(normalTex);

	#if !defined PROGRAM_HAND && defined ENABLE_PBR && defined DIMENSION_MAIN && defined RAIN_SPLASH_EFFECT
		viewNormal = normalize(viewNormal + mat3(gbufferModelView) * vec3(rainNormal.x, 0.0, rainNormal.y));
	#endif

	#if defined PROGRAM_ENTITIES || defined PROGRAM_SPIDEREYES
		#ifdef ENTITIES_NORMAL_CLAMP
			vec3 viewDir = -normalize(viewPos.xyz);
			viewNormal = normalize(viewNormal + tbnMat[2] * inversesqrt(saturate(dot(viewNormal, viewDir)) + 0.001));
		#endif
	#elif defined PROGRAM_BLOCK
		#ifdef TERRAIN_NORMAL_CLAMP
			vec3 viewDir = -normalize(viewPos);
			viewNormal = normalize(viewNormal + tbnMat[2] * inversesqrt(saturate(dot(viewNormal, viewDir)) + 0.001));
		#endif
	#elif defined PROGRAM_HAND
		#ifdef HAND_NORMAL_CLAMP
			vec3 viewDir = -normalize(viewPos);
			viewNormal = normalize(viewNormal + tbnMat[2] * inversesqrt(saturate(dot(viewNormal, viewDir)) + 0.001));
		#endif
	#endif


//specular
	#if defined MC_SPECULAR_MAP && TEXTURE_PBR_FORMAT == 2
		specularTex.a = specularTex.b;
	#endif

	#ifdef PROGRAM_HAND
		#ifdef DISABLE_HAND_SPECULAR
			specularTex = vec4(0.0);
		#endif
	#endif

	#ifdef PROGRAM_ENTITIES
		#ifdef DISABLE_PLAYER_SPECULAR
			if(materialIDs == MATID_ENTITIES_PLAYER) specularTex = vec4(0.0);
		#endif
	#endif	


//hardcoded texture
	#ifdef PROGRAM_ENTITIES
		if (materialIDs == MATID_ENTITIES_SNOW){
			albedo.rgb = vec3(0.9690, 0.9965, 0.9965);
			viewNormal = tbnMat[2];
			specularTex = vec4(0.0, 0.0, 0.7, 0.0);
		}
	#endif

	#ifdef PROGRAM_BLOCK
		if (materialIDs == MATID_END_PORTAL){
			vec3 portalColor = textureProj(tex, portalCoord).rgb * COLORS[0];
			for (int i = 0; i < 16; i++){
				portalColor += textureProj(tex, portalCoord * end_portal_layer(float(i + 1))).rgb * COLORS[i];
			}
			albedo.rgb = portalColor;
			specularTex.rgb = vec3(1.0, 0.0, 254.0 / 255.0);
		}
	#endif

	#if defined PROGRAM_ENTITIES || defined PROGRAM_SPIDEREYES
		gbufferOutput0 = albedo;
	#else
		gbufferOutput0 = vec4(albedo.rgb, 1.0);
	#endif
	gbufferOutput3 = vec4(EncodeNormal(viewNormal), blockLight);
	gbufferOutput5 = vec4(Pack2x8(specularTex.rg), Pack2x8(specularTex.ba), (materialIDs + 0.1) / 255.0, Pack2x8(vec2(wet, parallaxShadow)));
}
