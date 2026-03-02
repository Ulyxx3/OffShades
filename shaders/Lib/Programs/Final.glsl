

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


////////////////////PROGRAM_FINAL_0/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_FINAL_0/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_FINAL_0


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;


/* DRAWBUFFERS:1 */
layout(location = 0) out vec4 compositeOutput1;


#ifdef DIMENSION_NETHER
	uniform float BiomeNetherWastesSmooth;
	uniform float BiomeSoulSandValleySmooth;
	uniform float BiomeCrimsonForestSmooth;
	uniform float BiomeWarpedForestSmooth;
	uniform float BiomeBasaltDeltasSmooth;
#endif


#include "/Lib/Uniform/GbufferTransforms.glsl"


vec3 RRTAndODTFit(vec3 v){
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (v + 0.4329510) + 0.238081;
	return a / b;
}

vec3 ACES(vec3 color){
	color *= 1.4;

	#ifdef ABNEY_EFFECT_CORRECTION
		color *= mat3(0.99999976, -1.26657e-7, -1.29064e-9, 1.67316e-8, 0.99999976, -5.32026e-9, -0.00725587, 6.47740e-9, 1.00725580);
	#endif

	color *= mat3(0.59719, 0.35458, 0.04823, 0.07600, 0.90834, 0.01566, 0.02840, 0.13383, 0.83777);

	color = RRTAndODTFit(color);

	color *= mat3(1.60475, -0.53108, -0.07367, -0.10208, 1.10813, -0.00605, -0.00327, -0.07276, 1.07602);

	return LinearToGamma(color);
}


vec3 AgxDefaultContrastApprox(vec3 x){
	return (((((15.5 * x - 40.14) * x + 31.96) * x - 6.868) * x + 0.4298) * x + 0.1191) * x - 0.00232;			 
}

vec3 AgX(vec3 color) {
	color *= 2.3;

	#ifdef ABNEY_EFFECT_CORRECTION
		color *= mat3(0.99999976, -1.26657e-7, -1.29064e-9, 1.67316e-8, 0.99999976, -5.32026e-9, -0.00725587, 6.47740e-9, 1.00725580);
	#endif

	color *= mat3(0.842479062253094, 0.0784335999999992, 0.0792237451477643, 0.0423282422610123, 0.878468636469772, 0.0791661274605434, 0.0423756549057051, 0.0784336, 0.879142973793104);

	const float hev = AGX_EV * 0.5;
	const float middle_grey = 0.18;
	color = clamp(log2(color / middle_grey), -hev, hev);
	color = (color + hev) / AGX_EV;

	color = AgxDefaultContrastApprox(color);

	color *= mat3(1.19687900512017, -0.0980208811401368, -0.0990297440797205, -0.0528968517574562, 1.15190312990417, -0.0989611768448433, -0.0529716355144438, -0.0980434501171241, 1.15107367264116);

	return color;
}

vec3 None(vec3 color){
	return pow(color, vec3(1.0 / 2.2));
}

vec3 MergeBloom(vec3 color, float bloomGuide){
	#ifdef DIMENSION_MAIN
		float rainAlpha = 1.0 - texelFetch(colortex0, texelCoord, 0).a;
		rainAlpha *= RAIN_VISIBILITY;
	#endif

	#ifdef DIMENSION_NETHER
		float linearDepth = LinearDepth_From_ScreenDepth(Unpack2x16(texelFetch(colortex7, texelCoord, 0).a).x);
		#ifndef DISTANT_HORIZONS
			linearDepth = min(linearDepth, far);
		#endif
	#else
		float depth = texelFetch(depthtex0, texelCoord, 0).x;
		float linearDepth = LinearDepth_From_ScreenDepth(depth);
		#ifdef DISTANT_HORIZONS
			if (depth == 1.0) linearDepth = LinearDepth_From_ScreenDepth_DH(texelFetch(dhDepthTex0, texelCoord, 0).x);
		#endif
	#endif


	//const float maxBloomHeight = 10000.0;
	//float scale = min(1.0, maxBloomHeight / screenSize.y) * 0.5;

	vec3 bloom = CurveToLinear(textureLod(colortex5, texCoord * 0.5, 0.0).rgb);


	float bloomAmount = BLOOM_AMOUNT;

	#ifdef DIMENSION_END
		bloomAmount *= 0.5 * NETHER_END_BLOOM_BOOST + 1.0;
	#endif

	#ifdef DIMENSION_NETHER
		float biomeOffset =	 BiomeNetherWastesSmooth * 1.0;
		biomeOffset +=		 BiomeCrimsonForestSmooth * 0.75;
		biomeOffset +=		 BiomeWarpedForestSmooth * 0.25;
		biomeOffset +=		 BiomeBasaltDeltasSmooth * 0.5;

		biomeOffset = biomeOffset * NETHER_END_BLOOM_BOOST + 1.0;

		float fogDensity = 0.008 * biomeOffset * NETHER_END_BLOOM_BOOST * NETHERFOG_DENSITY;

		if (isEyeInWater > 1) fogDensity = 0.7;

		float visibility = 1.0 / exp2(linearDepth * fogDensity);
		float fogFactor = 1.1 - visibility;
		fogFactor *= bloomGuide;

		bloomAmount = max(bloomAmount * biomeOffset, min(fogFactor, 0.92));
	#else
		float fogDensity = float(isEyeInWater > 1) * 0.7;

		#ifdef UNDERWATER_FOG
			fogDensity = float(isEyeInWater == 1) * 0.07 * WATERFOG_DENSITY;
		#endif

		float visibility = 1.0 / exp2(linearDepth * fogDensity);
		float fogFactor = 1.1 - visibility;
		fogFactor *= bloomGuide;

		bloomAmount = max(bloomAmount, fogFactor);
	#endif


	#ifdef DIMENSION_MAIN
		#ifndef INDOOR_FOG
			float rainBloomAmount = wetness * (0.2 * eyeBrightnessSmoothCurved + 0.15);
		#else
			float rainBloomAmount = wetness * 0.35;
		#endif
		rainBloomAmount = saturate(rainBloomAmount + rainAlpha * 0.2);

		bloomAmount = max(bloomAmount, rainBloomAmount);

		#if defined VFOG && !defined DOF
			#ifdef VFOG_BLOOM
				float fogTransmittance = textureLod(colortex3, texCoord + taaJitter * 0.5, 0.0).a * bloomGuide;

				float fogBloomAmount = fsqrt(fogTransmittance);

				bloomAmount = max(bloomAmount, fogTransmittance);
			#endif
		#endif
	#endif

	#ifndef DISABLE_BLINDNESS_DARKNESS
		bloomAmount *= 1.0 - blindness - darknessFactor;
	#endif

	return mix(color, bloom, saturate(bloomAmount));
}


float GetExposureValue(){
	#ifdef MANUAL_EXPOSURE
		return 1.5e5 * MAIN_OUTPUT_FACTOR * exp2(-EV_VALUE);
	#else
		float ae = CurveToLinear(texelFetch(colortex2, ivec2(0, screenSize.y - 1.0), 0).a) * (5120.0 / EXPOSURE_OUTPUT_FACTOR);
		float ep = ae;

		float aeCurve = AE_CURVE;
		#ifndef DISABLE_NIGHTVISION
			aeCurve = mix(aeCurve, 0.95, nightVision);
		#endif
		#ifdef AE_CLAMP
			aeCurve *= remapSaturate(ae, 2.0, 1.0) * 0.6 + 0.4;
		#endif
		#ifdef DIMENSION_NETHER
			aeCurve *= 0.83;
		#endif
		ae = pow(ae, -aeCurve);

		ae *= exp2(AE_OFFSET);

		#ifndef DISABLE_BLINDNESS_DARKNESS
			ae *= 1.0 - min(darknessLightFactor * 2.0, 0.9);
		#endif

		return 8.5 * MAIN_OUTPUT_FACTOR * ae;
	#endif
}

float Vignette(vec2 coord, const float falloff, const float roundness){
	vec2 aCoord = coord * 2.0 - 1.0;
	aCoord.x *= mix(1.0, aspectRatio, roundness);
	float rf = dot(aCoord, aCoord) * falloff * falloff + 1.0;
	return 1.0 / (rf * rf);
}


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	ivec2 texelCoord = ivec2(gl_FragCoord.xy);
	vec4 data1 = texelFetch(colortex1, texelCoord, 0);
	vec3 color = CurveToLinear(data1.rgb);

	#ifdef BLOOM
		color = MergeBloom(color, 1.0 - data1.a);
	#endif

	#ifdef VIGNETTE
		color *= Vignette(texCoord, VIGNETTE_FALLOFF, VIGNETTE_ROUNDNESS);
	#endif

	color *= GetExposureValue();

	color = TONEMAP_OPERATOR(color);

	#ifdef ADVANCED_COLOR
		color = GammaToLinear(color);
		color = pow(length(color), 1.0 / LUMA_GAMMA) * normalize(color + 1e-20);
		color = saturate(color * (1.0 + WHITE_CLIP));

		//color = WhiteBalance(color);
	
		color = mix(color, vec3(Luminance(color)), vec3(1.0 - SATURATION));
		color = saturate(pow(color, vec3(((1.0 / 2.2) / GAMMA))));
	#endif

	#ifdef SNEAKING_VIGNETTE
		color *= mix(1.0, Vignette(vec2(0.5, texCoord.y), 0.7, 0.0), isSneakingSmooth);
	#endif

	compositeOutput1 = vec4(color, 0.0);
}


#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////





////////////////////PROGRAM_FINAL_1/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_FINAL_1/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_FINAL_1


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;


/* DRAWBUFFERS:1 */
layout(location = 0) out vec4 compositeOutput1;


vec3 FidelityFX_CAS(vec3 sampleE, ivec2 texelCoord){
	//      +---+
	//    g | h | i
	//  +---+---+---+
	//  | d | e | f |
	//  +---+---+---+
	//    a | b | c
	//      +---+

	vec3 sampleB = texelFetch(colortex1, texelCoord + ivec2( 0, -1), 0).rgb;
	vec3 sampleD = texelFetch(colortex1, texelCoord + ivec2(-1,  0), 0).rgb;
	vec3 sampleF = texelFetch(colortex1, texelCoord + ivec2( 1,  0), 0).rgb;
	vec3 sampleH = texelFetch(colortex1, texelCoord + ivec2( 0,  1), 0).rgb;
	float luminanceB = Luminance(sampleB);
	float luminanceD = Luminance(sampleD);
	float luminanceE = Luminance(sampleE);
	float luminanceF = Luminance(sampleF);
	float luminanceH = Luminance(sampleH);

	float minCross = min5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);
	float maxCross = max5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);

	float weight = sqrt(saturate(min(minCross, 2.0 - maxCross) / maxCross)) * (-0.1 - CAS_SHARPNESS * 0.01);

	#ifdef CAS_DENOISE
		float noise = luminanceB * 0.25 + luminanceD * 0.25 + luminanceF * 0.25 + luminanceH * 0.25 - luminanceE;
		noise = saturate(abs(noise) / (maxCross - minCross));
		weight *= 1.0 - 0.5 * noise;
	#endif

	vec3 sharpen = (sampleB * weight + sampleD * weight + sampleF * weight + sampleH * weight + sampleE) / (1.0 + 4.0 * weight);

	return max(sharpen, vec3(0.0));
}


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	vec3 color = texelFetch(colortex1, texelCoord, 0).rgb;
	
	#if CAS_SHARPNESS > 0 && defined TAA
		color = FidelityFX_CAS(color, texelCoord);
	#endif

	compositeOutput1 = vec4(color, 0.0);
}


#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////





////////////////////PROGRAM_FINAL_2/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_FINAL_2/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_FINAL_2


vec2 finalScreenSize = ceil(screenSize / MC_RENDER_QUALITY);
vec2 finalPixelSize = 1.0 / finalScreenSize;
ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * finalPixelSize;


#include "/Lib/IndividualFounctions/PrintFloat.glsl"


vec3 FidelityFX_CAS(vec3 sampleE, ivec2 texelCoord){
	//      +---+
	//    g | h | i
	//  +---+---+---+
	//  | d | e | f |
	//  +---+---+---+
	//    a | b | c
	//      +---+

	vec3 sampleB = texelFetch(colortex1, texelCoord + ivec2( 0, -1), 0).rgb;
	vec3 sampleD = texelFetch(colortex1, texelCoord + ivec2(-1,  0), 0).rgb;
	vec3 sampleF = texelFetch(colortex1, texelCoord + ivec2( 1,  0), 0).rgb;
	vec3 sampleH = texelFetch(colortex1, texelCoord + ivec2( 0,  1), 0).rgb;
	float luminanceB = Luminance(sampleB);
	float luminanceD = Luminance(sampleD);
	float luminanceE = Luminance(sampleE);
	float luminanceF = Luminance(sampleF);
	float luminanceH = Luminance(sampleH);

	float minCross = min5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);
	float maxCross = max5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);

	float weight = sqrt(saturate(min(minCross, 2.0 - maxCross) / maxCross)) * (-0.1 - CAS_SHARPNESS * 0.01);

	#ifdef CAS_DENOISE
		float noise = luminanceB * 0.25 + luminanceD * 0.25 + luminanceF * 0.25 + luminanceH * 0.25 - luminanceE;
		noise = saturate(abs(noise) / (maxCross - minCross));
		weight *= 1.0 - 0.5 * noise;
	#endif

	vec3 sharpen = (sampleB * weight + sampleD * weight + sampleF * weight + sampleH * weight + sampleE) / (1.0 + 4.0 * weight);

	return max(sharpen, vec3(0.0));
}

#if MC_VERSION >= 11801
#if 1

	vec3 FidelityFX_FSR1(ivec2 texelCoord){
		//      +---+
		//    g | h | i
		//  +---+---+---+
		//  | d | e | f |
		//  +---+---+---+
		//    a | b | c
		//      +---+
		
		vec3 sampleB = texelFetch(colortex8, texelCoord + ivec2( 0, -1), 0).rgb;
		vec3 sampleD = texelFetch(colortex8, texelCoord + ivec2(-1,  0), 0).rgb;
		vec3 sampleE = texelFetch(colortex8, texelCoord + ivec2( 0,  0), 0).rgb;
		vec3 sampleF = texelFetch(colortex8, texelCoord + ivec2( 1,  0), 0).rgb;
		vec3 sampleH = texelFetch(colortex8, texelCoord + ivec2( 0,  1), 0).rgb;
		float luminanceB = Luminance(sampleB);
		float luminanceD = Luminance(sampleD);
		float luminanceE = Luminance(sampleE);
		float luminanceF = Luminance(sampleF);
		float luminanceH = Luminance(sampleH);

		float minCross = min5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);
		float maxCross = max5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);

		float weight = sqrt(saturate(min(minCross, 2.0 - maxCross) / maxCross)) * (-0.1 - FSR_SHARPNESS * 0.01);

		#ifdef FSR_DENOISE
			float noise = luminanceB * 0.25 + luminanceD * 0.25 + luminanceF * 0.25 + luminanceH * 0.25 - luminanceE;
			noise = saturate(abs(noise) / (maxCross - minCross));
			weight *= 1.0 - 0.5 * noise;
		#endif

		vec3 sharpen = (sampleB * weight + sampleD * weight + sampleF * weight + sampleH * weight + sampleE) / (1.0 + 4.0 * weight);

		return max(sharpen, vec3(0.0));
	}

#else

	vec3 FidelityFX_FSR1(ivec2 texelCoord){
		//      +---+
		//    g | h | i
		//  +---+---+---+
		//  | d | e | f |
		//  +---+---+---+
		//    a | b | c
		//      +---+
		
		vec3 sampleB = texelFetch(colortex8, texelCoord + ivec2( 0, -1), 0).rgb;
		vec3 sampleD = texelFetch(colortex8, texelCoord + ivec2(-1,  0), 0).rgb;
		vec3 sampleE = texelFetch(colortex8, texelCoord + ivec2( 0,  0), 0).rgb;
		vec3 sampleF = texelFetch(colortex8, texelCoord + ivec2( 1,  0), 0).rgb;
		vec3 sampleH = texelFetch(colortex8, texelCoord + ivec2( 0,  1), 0).rgb;

		vec3 minRing = vec3(min4(sampleB.r, sampleD.r, sampleF.r, sampleH.r),
							min4(sampleB.g, sampleD.g, sampleF.g, sampleH.g),
							min4(sampleB.b, sampleD.b, sampleF.b, sampleH.b));

		vec3 maxRing = vec3(max4(sampleB.r, sampleD.r, sampleF.r, sampleH.r),
							max4(sampleB.g, sampleD.g, sampleF.g, sampleH.g),
							max4(sampleB.b, sampleD.b, sampleF.b, sampleH.b));

		#ifdef FSR_DENOISE
			float luminanceB = Luminance(sampleB);
			float luminanceD = Luminance(sampleD);
			float luminanceE = Luminance(sampleE);
			float luminanceF = Luminance(sampleF);
			float luminanceH = Luminance(sampleH);

			float minCross = min5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);
			float maxCross = max5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);

			float noise = luminanceB * 0.25 + luminanceD * 0.25 + luminanceF * 0.25 + luminanceH * 0.25 - luminanceE;
			noise = saturate(abs(noise) / (maxCross - minCross));
		#endif

		minRing = -0.25 * minRing / maxRing;
		maxRing = (1.0 - maxRing) / (4.0 * minRing - 4.0);

		float weight = max(-0.1875, min(maxVec3(max(minRing, maxRing)), 0.0));

		#ifdef FSR_DENOISE
			weight *= 1.0 - 0.5 * noise;
		#endif

		vec3 sharpen = (sampleB * weight + sampleD * weight + sampleF * weight + sampleH * weight + sampleE) / (1.0 + 4.0 * weight);

		return max(sharpen, vec3(0.0));
	}

#endif
#endif

float BlackBar(float newRatio){
	if (newRatio == 0.0) return 1.0;
	vec2 aCoord = abs(texCoord - 0.5) * 2.0;
	float width = min(newRatio / aspectRatio, 1.0);
	float height = min(aspectRatio / newRatio, 1.0);

	return step(aCoord.x, width) * step(aCoord.y, height);
}

vec3 Fxaa(vec3 rgbM, vec2 coord){

	#define FXAA_REDUCE_MIN   (1.0/64.0)
	#define FXAA_REDUCE_MUL   (1.0/8.0)
	#define FXAA_SPAN_MAX     16.0
	
	vec3 rgbNW = textureLod(colortex1, coord + pixelSize * vec2(-0.5, -0.5), 0.0).xyz;
	vec3 rgbNE = textureLod(colortex1, coord + pixelSize * vec2( 0.5, -0.5), 0.0).xyz;
	vec3 rgbSW = textureLod(colortex1, coord + pixelSize * vec2(-0.5,  0.5), 0.0).xyz;
	vec3 rgbSE = textureLod(colortex1, coord + pixelSize * vec2( 0.5,  0.5), 0.0).xyz;

	vec3 luma = vec3(0.299, 0.587, 0.114);
	float lumaNW = dot(rgbNW, luma);
	float lumaNE = dot(rgbNE, luma);
	float lumaSW = dot(rgbSW, luma);
	float lumaSE = dot(rgbSE, luma);
	float lumaM  = dot(rgbM,  luma);

	float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
	float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

	vec2 dir;
	dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

	float dirReduce = max(
		(lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
		FXAA_REDUCE_MIN);
	float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);
	dir = min(vec2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
		  max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
		  dir * rcpDirMin)) * pixelSize;

	vec3 rgbA = (1.0/2.0) * (
	textureLod(colortex1, coord + dir * vec2(1.0/3.0 - 0.5), 0.0).xyz +
	textureLod(colortex1, coord + dir * vec2(2.0/3.0 - 0.5), 0.0).xyz);
	vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
	textureLod(colortex1, coord + dir * vec2(0.0/3.0 - 0.5), 0.0).xyz +
	textureLod(colortex1, coord + dir * vec2(3.0/3.0 - 0.5), 0.0).xyz);

	float lumaB = dot(rgbB, luma);

	if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
		return rgbA;
	} else {
		return rgbB;
	}
}


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	vec3 color = vec3(0.0);
	
	if (MC_RENDER_QUALITY == 1.0){
		color = texelFetch(colortex1, texelCoord, 0).rgb;

		#if defined DISABLE_HAND_TAA && defined DISABLE_PLAYER_TAA_MOTION_BLUR
			float materialIDs = floor(texelFetch(colortex6, texelCoord, 0).b * 255.0);
			if (materialIDs == MATID_HAND || materialIDs == MATID_ENTITIES_PLAYER){
				color = Fxaa(color, texCoord);
			}else
		#elif defined DISABLE_HAND_TAA
			float materialIDs = floor(texelFetch(colortex6, texelCoord, 0).b * 255.0);
			if (materialIDs == MATID_HAND){
				color = Fxaa(color, texCoord);
			}else
		#elif defined DISABLE_PLAYER_TAA_MOTION_BLUR
			float materialIDs = floor(texelFetch(colortex6, texelCoord, 0).b * 255.0);
			if (materialIDs == MATID_ENTITIES_PLAYER){
				color = Fxaa(color, texCoord);
			}else
		#endif
			{
				#if CAS_SHARPNESS > 0 && defined TAA && (!defined FSR || MC_VERSION < 11801)
					color = FidelityFX_CAS(color, texelCoord);
				#endif
			}

	#if MC_VERSION >= 11801
	#ifdef FSR
		}else if(MC_RENDER_QUALITY < 1.0){
			color = FidelityFX_FSR1(texelCoord);
	#endif
	#endif
	
	}else{
		color = textureLod(colortex1, texCoord, 0.0).rgb;
	}

	color += InterleavedGradientNoise(gl_FragCoord.xy) * (1.0 / 255.0);

	color *= BlackBar(SEREEN_RATIO);

	//color = texelFetch(colortex2, texelCoord, 0).rgb;

	gl_FragData[0] = vec4(color, 0.0);
}


#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////
