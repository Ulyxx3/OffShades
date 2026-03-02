#version 330


#define DIMENSION_END


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/*
const int 	colortex0Format         = RGBA8;
const vec4 	colortex0ClearColor 	= vec4(0.0, 0.0, 0.0, 1.0);
const int 	colortex1Format         = RGBA16;
const int 	colortex2Format         = RGBA16;
const int 	colortex3Format 		= RGBA16;
const int 	colortex4Format 		= RGBA16;
const int 	colortex5Format 		= RGBA16;
const int 	colortex6Format 		= RGBA16;
const int 	colortex7Format 		= RGBA16;
const int 	colortex8Format 		= RGB16;

const bool	colortex2Clear          = false;
const bool	colortex7Clear          = false;

const float shadowIntervalSize 			= 4.0;
const float shadowDistanceRenderMul 	= 1.0;

const bool 	shadowHardwareFiltering1 	= true;
const bool 	shadowtex0Mipmap 			= true;
const bool 	shadowtex0Nearest 			= false;
const bool 	shadowtex1Mipmap 			= false;
const bool 	shadowtex1Nearest 			= false;
const bool 	shadowcolor0Mipmap 			= false;
const bool 	shadowcolor0Nearest 		= false;
const bool 	shadowcolor1Mipmap 			= false;
const bool 	shadowcolor1Nearest 		= false;


const int 	noiseTextureResolution 	= 64;

const float wetnessHalflife 		= 200.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float drynessHalflife 		= 50.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float eyeBrightnessHalflife 	= 10.0;

const float sunPathRotation 		= -30.0; 	// [-90.0 -89.0 -88.0 -87.0 -86.0 -85.0 -84.0 -83.0 -82.0 -81.0 -80.0 -79.0 -78.0 -77.0 -76.0 -75.0 -74.0 -73.0 -72.0 -71.0 -70.0 -69.0 -68.0 -67.0 -66.0 -65.0 -64.0 -63.0 -62.0 -61.0 -60.0 -59.0 -58.0 -57.0 -56.0 -55.0 -54.0 -53.0 -52.0 -51.0 -50.0 -49.0 -48.0 -47.0 -46.0 -45.0 -44.0 -43.0 -42.0 -41.0 -40.0 -39.0 -38.0 -37.0 -36.0 -35.0 -34.0 -33.0 -32.0 -31.0 -30.0 -29.0 -28.0 -27.0 -26.0 -25.0 -24.0 -23.0 -22.0 -21.0 -20.0 -19.0 -18.0 -17.0 -16.0 -15.0 -14.0 -13.0 -12.0 -11.0 -10.0 -9.0 -8.0 -7.0 -6.0 -5.0 -4.0 -3.0 -2.0 -1.0 0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0 31.0 32.0 33.0 34.0 35.0 36.0 37.0 38.0 39.0 40.0 41.0 42.0 43.0 44.0 45.0 46.0 47.0 48.0 49.0 50.0 51.0 52.0 53.0 54.0 55.0 56.0 57.0 58.0 59.0 60.0 61.0 62.0 63.0 64.0 65.0 66.0 67.0 68.0 69.0 70.0 71.0 72.0 73.0 74.0 75.0 76.0 77.0 78.0 79.0 80.0 81.0 82.0 83.0 84.0 85.0 86.0 87.0 88.0 89.0 90.0]

const float ambientOcclusionLevel 	= 0.0;
const int 	superSamplingLevel 		= 0;
*/


const int 	shadowMapResolution 		= 2048; 	// [1024 2048 4096 8192 16384 32768]
const float shadowDistance 				= 192.0; 	// [64.0 96.0 128.0 192.0 256.0 384.0 512.0 768.0 1024.0 1536.0 2048.0]


uniform sampler2D shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 compositeOutput0;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;

in vec3 worldShadowVector;
in vec3 shadowVector;
in vec3 worldSunVector;

in vec3 colorTorchlight;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/Uniform/ShadowTransformsEnd.glsl"

#include "/Lib/BasicFounctions/TemporalNoise.glsl"
#include "/Lib/BasicFounctions/Blocklight.glsl"
#include "/Lib/BasicFounctions/Sunlight_Shadow.glsl"

#include "/Lib/IndividualFounctions/EndSky.glsl"
#include "/Lib/IndividualFounctions/GTAO.glsl"


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);

	FixParticleMask(materialMaskSoild, materialMask, gbuffer.depthL, gbuffer.depthW);

	if (materialMask.water > 0.5)
	{
		gbuffer.material.roughness = 1.0;
		gbuffer.material.metalness = 0.0;
	}

	vec3 viewPos 					= ViewPos_From_ScreenPos(texCoord, gbuffer.depthL);

	#ifdef DISTANT_HORIZONS
		bool isDH = gbuffer.depthL == 1.0;
		if (isDH){
			gbuffer.depthL 			= texelFetch(dhDepthTex1, texelCoord, 0).x;
			viewPos 				= ViewPos_From_ScreenPos_DH(texCoord, gbuffer.depthL);
		}
	#endif

	vec3 worldPos					= mat3(gbufferModelViewInverse) * viewPos;
	vec3 viewDir 					= normalize(viewPos);
	vec3 worldDir 					= normalize(worldPos);

	#ifdef DISTANT_HORIZONS
		float farDist 				= max(dhFarPlane, 1024.0);
	#else
		float farDist 				= max(far * 1.2, 1024.0);
	#endif
	float opaqueDist 				= gbuffer.depthL < 1.0 ? length(viewPos) : farDist;


	vec3 colorSunLight = Blackbody(6000.0);
	vec3 finalComposite = vec3(0.0);


	if (materialMaskSoild.sky < 0.5){
		vec3 worldNormal = mat3(gbufferModelViewInverse) * gbuffer.normalL;

		#ifdef DISTANT_HORIZONS
			#ifdef DH_SHADOW
				materialMaskSoild.leaves *= saturate(3.2 - opaqueDist / min(shadowDistance, far) * 4.0) * 0.65 + 0.35;
			#else
				materialMaskSoild.leaves *= saturate(3.2 - opaqueDist / min(shadowDistance, far) * 4.0 - float(isDH) * 1e10) * 0.65 + 0.35;
			#endif
		#else
			materialMaskSoild.leaves *= saturate(3.2 - opaqueDist / min(shadowDistance, far) * 4.0) * 0.6 + 0.4;
		#endif

		worldNormal = normalize(mix(worldNormal, vec3(0.0, 1.0, 0.0), materialMaskSoild.grass * 0.49));
		gbuffer.material.scattering *= saturate(1.0 - materialMaskSoild.leaves - materialMaskSoild.grass);


		finalComposite += vec3(colorSunLight * 0.005) * ((worldNormal.y * 0.35 + 0.75) * (dot(worldSunVector, worldNormal) * 0.3 + 0.7) * (planetShadow * planetShadow * 0.93 + 0.07));


	   vec3 sunlightMult = colorSunLight * (0.3 * SUNLIGHT_INTENSITY * planetShadow * planetShadow);


		// Since we disabled the deferred passes, colortex1 (GI) is empty.
		// We provide a basic ambient global illumination instead.
		vec4 gi = vec4(0.01, 0.01, 0.015, 1.0);
		gi = mix(gi, vec4(0.0, 0.0, 0.0, 1.0), materialMask.particle);

		vec3 rsm = CurveToLinear(gi.rgb);
		rsm *= sunlightMult * (7.0 * GI_BRIGHTNESS);

		// Add a base ambient so it's not totally pitch black
		finalComposite += rsm + vec3(0.02, 0.015, 0.03);

		#ifdef GTAO
			#ifdef GTAO_MULTIBOUNCE
				vec3 ao = GTAOMultiBounce(gi.a, gbuffer.albedo);
			#else
				vec3 ao = vec3(gi.a);
			#endif
		#else
			vec3 ao = vec3(1.0);
		#endif
		finalComposite *= ao;

		if(heldBlockLightValue + heldBlockLightValue2 > 0.0)
			finalComposite += HeldLighting(viewPos, viewDir, gbuffer.normalL, gbuffer.material.roughness, ao, materialMask.hand > 0.5);

		finalComposite += BlockLighting(gbuffer.lightmapL.r, ao, materialMaskSoild);
		finalComposite += TextureLighting(gbuffer.albedo, gbuffer.lightmapL.r, gbuffer.material.emissiveness, materialMaskSoild);


		float sunlight = Fd_Burley(worldNormal, -worldDir, worldShadowVector, gbuffer.material.roughness);

		float sunlightTrans = saturate(materialMaskSoild.leaves * 3.0) * 0.25 + materialMask.particle * 0.4 + materialMaskSoild.grass * 0.15;
		sunlight = mix(sunlight, 0.6, sunlightTrans);
		gbuffer.parallaxShadow = saturate(gbuffer.parallaxShadow + sunlightTrans * 1e10);


		vec3 shadow = vec3(1.0);
		vec3 specularHighlight = vec3(0.0);
		vec3 sss = vec3(0.0);

		if (sunlight + gbuffer.material.scattering > 0.0)
			shadow *= VariablePenumbraShadow(worldPos, worldNormal, sunlight, gbuffer.albedo, gbuffer.material.scattering, materialMaskSoild, sss);

		#if PARALLAX_MODE > 0
			shadow *= gbuffer.parallaxShadow;
		#endif

		if (any(greaterThan(sunlight * shadow, vec3(0.0)))){
			#ifdef SCREEN_SPACE_SHADOWS
				#ifdef DISABLE_PLAYER_SCREEN_SPACE_SHADOWS
					#if PARALLAX_MODE > 0
						if (materialMaskSoild.leaves + materialMaskSoild.hand + materialMaskSoild.entitiesSnow + materialMaskSoild.entityPlayer < 1.0)
					#else
						if (materialMaskSoild.leaves + materialMaskSoild.hand + materialMaskSoild.entitiesSnow + materialMaskSoild.entityPlayer < 1.0 && gbuffer.parallaxShadow > 0.0)
					#endif
				#else
					#if PARALLAX_MODE > 0
						if (materialMaskSoild.leaves + materialMaskSoild.hand + materialMaskSoild.entitiesSnow < 1.0)
					#else
						if (materialMaskSoild.leaves + materialMaskSoild.hand + materialMaskSoild.entitiesSnow < 1.0 && gbuffer.parallaxShadow > 0.0)
					#endif
				#endif
					shadow *= mix(ScreenSpaceShadow(viewPos, viewDir, gbuffer.normalL, materialMaskSoild), 1.0, saturate(materialMaskSoild.leaves * 1.67 - 0.67));
			#endif

			#ifdef CAUSTICS
				if (materialMask.water > 0.5 || isEyeInWater == 1)
					shadow *= CalculateWaterCaustics(worldPos);
			#endif

			shadow *= sunlightMult;

			finalComposite += sunlight * shadow;

			if (materialMask.water + materialMask.ice < 0.5){
				float highlightGGX = SpecularGGX(gbuffer.normalL, -viewDir, shadowVector, clamp(gbuffer.material.roughness, 0.0015, 0.9), gbuffer.material.f0);
				highlightGGX *= saturate(4.0 - gbuffer.material.roughness * 3.5);
				highlightGGX *= 0.07 - materialMaskSoild.grass * 0.035;
				specularHighlight = mix(vec3(1.0), gbuffer.albedo, vec3(gbuffer.material.metalness)) * shadow * highlightGGX;
			}
		}
		finalComposite += sss * sunlightMult;

		finalComposite *= gbuffer.albedo;

		finalComposite *= 1.0 - gbuffer.material.metalness * 0.75;

		finalComposite += specularHighlight;
	}

	worldDir = (isEyeInWater == 1 && materialMask.water > 0.5) ? refract(worldDir, normalize((gbufferModelViewInverse * vec4(gbuffer.normalW, 0.0)).xyz), WATER_REFRACT_IOR) : worldDir;


	if (materialMaskSoild.sky > 0.5){
		finalComposite = vec3(0.0);

		BlackHole_AccretionDisc_Stars(finalComposite, worldDir, worldShadowVector);

		PlanetEnd2(finalComposite, vec3(0.0), worldDir, worldSunVector);
	}


	float totalInternalReflection = 0.0;
	if (length(worldDir) < 0.5){
		finalComposite = vec3(0.0);
		totalInternalReflection = 1.0;
	}


	finalComposite /= MAIN_OUTPUT_FACTOR;
	finalComposite = LinearToCurve(finalComposite);

	compositeOutput0 = vec4(finalComposite, totalInternalReflection);
}
