

#if PARALLAX_MODE > 1

#include "/Lib/BasicFounctions/TemporalNoise.glsl"

float BilinearHeightSample(vec2 coord, ivec2 tilesBaseTexel, float textureResolution, int iTextureResolution
#ifndef PROGRAM_TERRAIN
, bool isBlock
#endif
){
	ivec2 texelX = ivec2(floor(coord));
	ivec2 texelW = texelX + 1;

	vec2 f = coord - vec2(texelX);

	#ifndef PROGRAM_TERRAIN
		if (isBlock){
			texelX = tilesBaseTexel + (texelX & iTextureResolution);
			texelW = tilesBaseTexel + (texelW & iTextureResolution);
		}
	#else
		texelX = tilesBaseTexel + (texelX & iTextureResolution);
		texelW = tilesBaseTexel + (texelW & iTextureResolution);
	#endif

	vec4 sh = vec4(texelFetch(normals, texelX, 0).a,
				   texelFetch(normals, ivec2(texelW.x, texelX.y), 0).a,
				   texelFetch(normals, ivec2(texelX.x, texelW.y), 0).a,
				   texelFetch(normals, texelW, 0).a);

	sh += saturate(1.0 - sh * 1e20);

	return mix(mix(sh.x, sh.y, f.x),
			   mix(sh.z, sh.w, f.x),
			   f.y);
}

vec3 HeightBasedNormal(vec2 coord, ivec2 tilesBaseTexel, float textureResolution, int iTextureResolution
#ifndef PROGRAM_TERRAIN
, bool isBlock
#endif
){
	coord -= 0.5;

	ivec2 texelX = ivec2(floor(coord));
	ivec2 texelW = texelX + 1;

	vec2 f = coord - vec2(texelX);

	#ifndef PROGRAM_TERRAIN
		if (isBlock){
			texelX = tilesBaseTexel + (texelX & iTextureResolution);
			texelW = tilesBaseTexel + (texelW & iTextureResolution);
		}
	#else
		texelX = tilesBaseTexel + (texelX & iTextureResolution);
		texelW = tilesBaseTexel + (texelW & iTextureResolution);
	#endif

	vec4 sh = vec4(texelFetch(normals, texelX, 0).a,
				   texelFetch(normals, ivec2(texelW.x, texelX.y), 0).a,
				   texelFetch(normals, ivec2(texelX.x, texelW.y), 0).a,
				   texelFetch(normals, texelW, 0).a);

	#if PARALLAX_MODE == 2
		sh.w = sh.y + sh.z -sh.x - sh.w;
		return vec3(sh.w * f.yx + (sh.x - sh.yz), (8.0 / PARALLAX_DEPTH) / textureResolution);
	#else
		const float eps = 0.01;
		f -= 0.5;

		float dX = mix(sh.x - sh.y, sh.z - sh.w, saturate(f.y * 1e20)) * saturate((eps - abs(f.x)) * 1e20);
		float dY = mix(sh.x - sh.z, sh.y - sh.w, saturate(f.x * 1e20)) * saturate((eps - abs(f.y)) * 1e20);
		
		return vec3(dX, dY, step(abs(dX) + abs(dY), 0.0));
	#endif
}

ivec2 ParallaxOcclusionMapping(vec2 coord, mat3 tbnMat, vec3 shadowVector, vec2 duv1, vec2 duv2, inout vec3 normalTex, inout float parallaxShadow){
	#ifndef PROGRAM_TERRAIN
		const float textureResolution = ENTITIES_TEXTURE_RESOLUTION;
		ivec2 atlasSize = textureSize(tex, 0);

		bool isBlock = textureSize(gaux4, 0) == atlasSize;
	#endif

	vec2 atlasTiles = vec2(atlasSize) / textureResolution;

	#ifdef PARALLAX_FADE
		vec2 duvMax = max(abs(duv1), abs(duv2)) * atlasTiles;
		float fade = saturate(pow(max(duvMax.x, duvMax.y), -0.1) * (1.0 / 1.4));
	#endif

	vec2 tilesBaseCoord = floor(coord * atlasTiles);
	ivec2 tilesBaseTexel = ivec2(tilesBaseCoord * textureResolution);
	int iTextureResolution = int(textureResolution) - 1;

	vec3 parallaxTexelCoord = vec3(coord * atlasSize, 1.0);

	float sampleHeight = BilinearHeightSample(parallaxTexelCoord.xy - 0.5, tilesBaseTexel, textureResolution, iTextureResolution
	#ifndef PROGRAM_TERRAIN
	, isBlock
	#endif
	);

	if (sampleHeight > 0.0 && sampleHeight < 1.0){
		parallaxTexelCoord.xy -= 0.5;

		vec3 viewVector = normalize(viewPos) * tbnMat;
		viewVector /= -viewVector.z;

		vec3 stepDir = viewVector / PARALLAX_QUALITY;
		stepDir.xy *= textureResolution * PARALLAX_DEPTH * 0.25;

		float stepLength = 2.0 / PARALLAX_QUALITY;

		for (int i = 0; i < PARALLAX_QUALITY; i++, stepLength += 2.0 / PARALLAX_QUALITY){
			parallaxTexelCoord += stepDir * stepLength;

			sampleHeight = BilinearHeightSample(parallaxTexelCoord.xy, tilesBaseTexel, textureResolution, iTextureResolution
			#ifndef PROGRAM_TERRAIN
			, isBlock
			#endif
			);

			if (sampleHeight > parallaxTexelCoord.z) break;
		}

		for (int i = 0; i < PARALLAX_MAX_REFINEMENTS; i++){
			if (sampleHeight > parallaxTexelCoord.z){
				parallaxTexelCoord -= stepDir * stepLength;
				stepLength *= 0.5;
			}

			parallaxTexelCoord += stepDir * stepLength;

			sampleHeight = BilinearHeightSample(parallaxTexelCoord.xy, tilesBaseTexel, textureResolution, iTextureResolution
			#ifndef PROGRAM_TERRAIN
			, isBlock
			#endif
			);
		}

		if (sampleHeight <= parallaxTexelCoord.z) parallaxTexelCoord += stepDir * stepLength * 2.0;


		#ifdef PARALLAX_SHADOW

			if(parallaxShadow > 0.0){
				shadowVector = shadowVector * tbnMat;
				shadowVector /= shadowVector.z * 0.9 + 0.1;

				vec3 shadowTexelCoord = parallaxTexelCoord;

				vec3 stepSize = shadowVector / (PARALLAX_SHADOW_QUALITY);
				stepSize.xy *= textureResolution * PARALLAX_DEPTH * 0.25;

				#ifdef TAA
					shadowTexelCoord += stepSize * BlueNoiseTemproal().x;
				#else
					shadowTexelCoord += stepSize;
				#endif

				for (int i = 0; i < PARALLAX_SHADOW_QUALITY; i++, shadowTexelCoord += stepSize){	
					if (shadowTexelCoord.z > 1.0) break;

					sampleHeight = BilinearHeightSample(shadowTexelCoord.xy, tilesBaseTexel, textureResolution, iTextureResolution
					#ifndef PROGRAM_TERRAIN
					, isBlock
					#endif
					);

					float diff = shadowTexelCoord.z - sampleHeight;
					parallaxShadow *= saturate(diff * 40.0 + 1.0);

					if(parallaxShadow < 0.003) break;
				}
			}
			#ifdef PARALLAX_FADE
				parallaxShadow = mix(1.0, parallaxShadow, fade);
			#endif
		#endif
		
		parallaxTexelCoord.xy += 0.5;

		#if PARALLAX_BASED_NORMAL == 2
			normalTex = HeightBasedNormal(parallaxTexelCoord.xy, tilesBaseTexel, textureResolution, iTextureResolution
			#ifndef PROGRAM_TERRAIN
			, isBlock
			#endif
			);
		#endif

		parallaxTexelCoord.xy = (fract(parallaxTexelCoord.xy / textureResolution) + tilesBaseCoord) * textureResolution;
	}

	ivec2 parallaxTexel = ivec2(parallaxTexelCoord.xy);

	#if PARALLAX_BASED_NORMAL < 2
		normalTex = DecodeNormalTex(texelFetch(normals, parallaxTexel, 0).rgb);
	#else
		#ifdef PARALLAX_FADE
			normalTex = mix(vec3(0.0, 0.0, 1.0), normalTex, fade);
		#endif
	#endif

	return parallaxTexel;
}

#elif PARALLAX_MODE == 1

ivec2 ParallaxOcclusionMapping(vec2 coord, mat3 tbnMat, vec3 shadowVector, vec2 duv1, vec2 duv2, inout vec3 hitNormal, inout float parallaxShadow){
	#ifndef PROGRAM_TERRAIN
		const float textureResolution = ENTITIES_TEXTURE_RESOLUTION;
		ivec2 atlasSize = textureSize(tex, 0);

		bool isBlock = textureSize(gaux4, 0) == atlasSize;
	#endif

	vec2 atlasTiles = vec2(atlasSize) / textureResolution;

	vec2 pixelCoord = coord * vec2(atlasSize);
	ivec2 parallaxTexel = ivec2(floor(pixelCoord));
	int iTextureResolution = int(textureResolution) - 1;

	float sampleHeight = texelFetch(normals, parallaxTexel, 0).a;
	sampleHeight += saturate(1.0 - sampleHeight * 1e20);

	bool exit = false;

	if (sampleHeight > 0.0 && sampleHeight < 1.0){
		#ifdef PARALLAX_FADE
			vec2 duvMax = max(abs(duv1), abs(duv2)) * atlasTiles;
			float fade = saturate(pow(max(duvMax.x, duvMax.y), -0.4) * 0.2);
		#endif

		ivec2 tilesPixelBase = ivec2(floor(coord * atlasTiles) * textureResolution);

		vec3 viewVector = normalize(viewPos) * tbnMat;
		vec3 stepDir = normalize(vec3(viewVector.xy * PARALLAX_DEPTH * textureResolution * 0.25, -viewVector.z));

		vec2 ardir = abs(1.0 / stepDir.xy);
		ivec2 sdir = (floatBitsToInt(stepDir.xy) >> 31) * 2 + 1;

		vec2 totalStep = (vec2(sdir) * (0.5 - (pixelCoord - vec2(parallaxTexel))) + 0.5) * ardir;

		float stepLength = 0.0;
		float stepHeight = 1.0;
		float prevStepHeight = 1.0;
		ivec2 stepNext = ivec2(0);

		for (int i = 0; i < PARALLAX_QUALITY; i++){
			stepLength = min(totalStep.x, totalStep.y);
			stepHeight = 1.0 - stepLength * stepDir.z;
			if (sampleHeight > stepHeight){
				if (sampleHeight > prevStepHeight){
					hitNormal = vec3(-stepNext * sdir, 0.0);
					sampleHeight = prevStepHeight;
				}
				exit = true;
				break;
			}

			stepNext = (floatBitsToInt(vec2(stepLength) - totalStep) >> 31) + 1;
			parallaxTexel += stepNext * sdir;
			totalStep += vec2(stepNext) * ardir;
			prevStepHeight = stepHeight;

			#ifndef PROGRAM_TERRAIN
				if (isBlock)
			#endif
			parallaxTexel = tilesPixelBase + (parallaxTexel & iTextureResolution);
			sampleHeight = texelFetch(normals, parallaxTexel, 0).a;
			sampleHeight += saturate(1.0 - sampleHeight * 1e20);
		}


		#ifdef PARALLAX_SHADOW
			shadowVector = shadowVector * tbnMat;

			float shadow = 1.0;

			if(dot(shadowVector, hitNormal) * parallaxShadow > 0.0 && exit){
				float currHeight = sampleHeight;
				stepLength = (1.0 - currHeight) / stepDir.z;

				vec2 shadowTexelCoord = pixelCoord + stepLength * stepDir.xy;
				ivec2 shadowTexel = ivec2(floor(shadowTexelCoord));

				stepDir = normalize(vec3(shadowVector.xy * PARALLAX_DEPTH * textureResolution * 0.25, shadowVector.z));

				vec2 ardir = abs(1.0 / stepDir.xy);
				ivec2 sdir = (floatBitsToInt(stepDir.xy) >> 31) * 2 + 1;

				totalStep = (vec2(sdir) * (0.5 - (shadowTexelCoord - shadowTexel)) + 0.5) * ardir;
				stepNext = ivec2(0);

				for (int i = 0; i < PARALLAX_SHADOW_QUALITY; i++){
					stepLength = min(totalStep.x, totalStep.y);
					stepHeight = currHeight + stepLength * stepDir.z;

					stepNext = (floatBitsToInt(vec2(stepLength) - totalStep) >> 31) + 1;
					shadowTexel += stepNext * sdir;
					totalStep += vec2(stepNext) * ardir;

					#ifndef PROGRAM_TERRAIN
						if (isBlock)
					#endif
					shadowTexel = tilesPixelBase + (shadowTexel & iTextureResolution);
					sampleHeight = texelFetch(normals, shadowTexel, 0).a;
					sampleHeight += saturate(1.0 - sampleHeight * 1e20);

					if (sampleHeight > stepHeight){
						parallaxShadow = 0.0;
						break;
					}
				}

				#ifdef PARALLAX_FADE
					parallaxShadow *= mix(1.0, shadow, fade);
				#else
					parallaxShadow *= shadow;
				#endif
			}
		#endif

	#if PARALLAX_BASED_NORMAL == 1
		#ifdef PARALLAX_FADE
			hitNormal = mix(DecodeNormalTex(texelFetch(normals, parallaxTexel, 0).rgb), hitNormal, fade * (1.0 - hitNormal.z));
		#else
			if(hitNormal.z == 1.0) hitNormal = DecodeNormalTex(texelFetch(normals, parallaxTexel, 0).rgb);
		#endif
		}else{
			hitNormal = DecodeNormalTex(texelFetch(normals, parallaxTexel, 0).rgb);
	#elif PARALLAX_BASED_NORMAL == 2 && defined PARALLAX_FADE
		hitNormal = mix(vec3(0.0, 0.0, 1.0), hitNormal, fade);
	#endif
	}

	#if PARALLAX_BASED_NORMAL == 0
		hitNormal = DecodeNormalTex(texelFetch(normals, parallaxTexel, 0).rgb);
	#endif

	return parallaxTexel;
}

#endif