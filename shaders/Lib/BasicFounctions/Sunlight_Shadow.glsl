

vec3 VariablePenumbraShadow(vec3 worldPos, vec3 worldNormal, float sunlight, vec3 albedo, float scatteringStrength, MaterialMask mask, out vec3 sss){
	worldPos += gbufferModelViewInverse[3].xyz;
	worldPos -= gbufferModelViewInverse[2].xyz * 0.5 * mask.hand;

	#ifdef DIMENSION_END
		vec3 shadowNormal = mat3(shadowModelViewEnd) * worldNormal;
		shadowNormal.z = -shadowNormal.z;

		vec3 shadowScreenPos = mat3(shadowModelViewEnd) * worldPos + shadowModelViewEnd[3].xyz;
	#else
		vec3 shadowNormal = mat3(shadowModelView) * worldNormal;
		shadowNormal.z = -shadowNormal.z;

		vec3 shadowScreenPos = mat3(shadowModelView) * worldPos + shadowModelView[3].xyz;
	#endif
	shadowScreenPos *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);

	float zScale = 1.0 / shadowProjection[0][0];
	float dist = length(shadowScreenPos.xy);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;


	#ifdef TAA
		vec2 noise = BlueNoiseTemproal();
		#if defined DISABLE_HAND_TAA && defined DISABLE_PLAYER_TAA_MOTION_BLUR
			if (mask.hand > 0.5 || mask.entityPlayer > 0.5) noise = BlueNoise();
		#else
			#ifdef DISABLE_HAND_TAA
				if (mask.hand > 0.5) noise = BlueNoise();
			#endif
			#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
				if (mask.entityPlayer > 0.5) noise = BlueNoise();
			#endif
		#endif
	#else
		vec2 noise = BlueNoise();
	#endif

	const mat2 rotMat = mat2(cos(goldenAngle), sin(goldenAngle), -sin(goldenAngle), cos(goldenAngle));

	vec3 result = vec3(1.0);

	sss = vec3(0.0);

	if (scatteringStrength > 0.0){
		vec3 shadowScreenPosRaw = shadowScreenPos;
		shadowScreenPosRaw.xy *= 0.95 / distortFactor;
		shadowScreenPosRaw = shadowScreenPosRaw * 0.5 + 0.5;

		float spread = (scatteringStrength * 0.12 + 0.05) / (distortFactor * shadowDistance) + SHADOW_BASIC_BLUR / shadowMapResolution;
		vec3 scatteringDensity = 15.0 / (scatteringStrength * albedo + 0.1);

		const float steps = SSS_QUALITY;
		const float rSteps = 1.0 / steps;

		float angle = noise.x * TAU;
		vec2 rot = vec2(cos(angle), sin(angle));

		float scatteringDepth = 0.0;

		for (float i = 0.0; i < steps; i++){
			rot *= rotMat;
			float radius = (i + noise.y) * rSteps;
			vec2 offset = rot * spread * radius;

			float sampleDepth = textureLod(shadowtex0, shadowScreenPosRaw.xy + offset, 0.0).x;

			scatteringDepth += max(shadowScreenPosRaw.z - sampleDepth, 1e-5);
		}
		scatteringDepth *= rSteps * zScale;

		vec3 scattering = exp2(-scatteringDepth * scatteringDensity);

		float distFalloff = saturate(((min(shadowDistance, far) - length(worldPos)) * 0.05 - 1.0));

		#ifdef SSS_NORMAL
			sss = scattering * (SSS_BRIGHTNESS * distFalloff * (MiePhaseFunction(0.5, dot(worldNormal, -worldShadowVector)) * 0.5 + 0.15));
		#else
			sss = scattering * (SSS_BRIGHTNESS * distFalloff * 0.2);
		#endif

		scatteringStrength *= distFalloff; 
	}

	if (sunlight > 0.0){
		shadowScreenPos += shadowNormal * (0.002 * (1.0 - mask.leaves) * distortFactor);
		shadowScreenPos.xy *= 0.95 / distortFactor;
		shadowScreenPos = shadowScreenPos * 0.5 + 0.5;

		if (saturate(shadowScreenPos.xy) == shadowScreenPos.xy){
			result = vec3(0.0);

			float spread = VPS_SPREAD * 200.0 / (distortFactor * shadowDistance);

			float avgDiff = 0.0;

			#ifdef VARIABLE_PENUMBRA_SHADOWS
				float spreadLod = log2(shadowMapResolution / 512.0);
				for (int i = -1; i <= 1; i++){
					for (int j = -1; j <= 1; j++){
						vec2 lookupCoord = shadowScreenPos.xy + vec2(i, j) * spread * 0.0039;
						float depthDiff = shadowScreenPos.z - textureLod(shadowtex0, lookupCoord, spreadLod).x;
						depthDiff = clamp(depthDiff * zScale * 0.0035, 0.0, 0.025);
						avgDiff += depthDiff * depthDiff;
					}
				}
				
				avgDiff /= 9.0;
				avgDiff = sqrt(avgDiff);
			#endif

			avgDiff = max(avgDiff, 0.015 * mask.leaves + 0.01 * mask.grass);


			float sampleSpread = avgDiff * 0.2 * spread + SHADOW_BASIC_BLUR / shadowMapResolution;

			shadowScreenPos.z -= (2e-6 + noise.y * 2e-6) * (dist + 0.03) * (1.0 - 0.9 * mask.leaves) * shadowDistance;


			const float steps = VPS_QUALITY;
			const float rSteps = 1.0 / steps;

			float angle = noise.y * TAU;
			vec2 rot = vec2(cos(angle), sin(angle));

			for (float i = 0.0; i < steps; i++){
				rot *= rotMat;
				float radius = sqrt((i + noise.x) * rSteps);
				vec2 offset = rot * radius * sampleSpread;

				vec3 sampleCoord = vec3(shadowScreenPos.xy + offset, shadowScreenPos.z);

				#ifdef COLORED_SHADOWS
					float translucentShadow = step(sampleCoord.z, textureLod(shadowtex0, sampleCoord.xy, 0.0).x);
					result += vec3(translucentShadow);

					float soildShadow = textureLod(shadowtex1, sampleCoord, 0.0);
					vec3 shadowColorSample = GammaToLinear(textureLod(shadowcolor0, sampleCoord.xy, 0.0).rgb);
					result += shadowColorSample * (soildShadow - translucentShadow);
				#else
					float soildShadow = textureLod(shadowtex1, sampleCoord, 0.0);
					result += vec3(soildShadow);
				#endif
			}
			result *= rSteps;
		}
	}

	#ifdef SSS_NORMAL
		return result * (saturate(0.4 - scatteringStrength * 0.4) + 0.6);
	#else
		return result * (saturate(0.5 - scatteringStrength * 0.5) + 0.5);
	#endif
}

float ScreenSpaceShadow(vec3 viewPos, vec3 viewDir, vec3 normal, MaterialMask mask){
	mask.leaves = saturate(mask.leaves * 1e10);

	float fov = mask.grass + mask.leaves > 0.5 ? 95.0 : atan(1.0 / gbufferProjection[1][1]) * 360.0 * rPI;

	vec3 viewRayDir = shadowVector * max(-viewPos.z * 3e-5 * fov, 0.06 * shadowDistance / shadowMapResolution);

	vec3 start = viewPos;

	if (mask.grass + mask.leaves < 0.1){
		float pixelScale = max(pixelSize.x, pixelSize.y);
		float NdotL = saturate(dot(shadowVector, normal));

		start += viewRayDir * (pixelScale * max(0.04 / max(dot(normal, -viewDir), 0.1), 1e3));
		start += normal * (8e-3 * fov * -viewPos.z * pixelScale / max(NdotL, 0.01));
	}

	vec3 end = start + viewRayDir;

	start = vec3(vec2(gbufferProjection[0][0], gbufferProjection[1][1]) * start.xy, -start.z);
    end   = vec3(vec2(gbufferProjection[0][0], gbufferProjection[1][1]) * end.xy,   -end.z);

	vec3 screenRayDir = (end - start);
	screenRayDir.xy *= 0.5;

	start.xy += gbufferProjection[3].xy;
	start.xy *= 0.5;

	start += screenRayDir * mask.grass;

	float absorption = 0.0;
	absorption += 0.7 * mask.grass;
	absorption += 0.85 * mask.leaves;
	absorption = pow(absorption, sqrt(-viewPos.z) * 0.5);

	#ifdef TAA
		float noise = BlueNoiseTemproal().x;
		#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
			if (mask.entityPlayer > 0.5) noise = BlueNoise().x;
		#endif
		vec2 offsetCoord = 0.5 + taaJitter * 0.5;
	#else
		float noise = BlueNoise().x;
		vec2 offsetCoord = vec2(0.5);
	#endif

	float shadow = 1.0;
	float stepLength = 1.0;
	float zThickness = 0.025 + 0.0125 * -viewPos.z;

	for (int i = 0; i < 12; i++, start += screenRayDir * stepLength, stepLength += 0.3){
		vec3 samplePos = start + screenRayDir * noise * stepLength;
		samplePos.xy = samplePos.xy / samplePos.z + offsetCoord;
		
		if (saturate(samplePos.xy) != samplePos.xy) break;

		#ifdef DISTANT_HORIZONS
			float sampleDepth = textureLod(depthtex1, samplePos.xy, 0.0).x;
			float sampleDist = 0.0;

			if (sampleDepth == 1.0){
				sampleDepth = textureLod(dhDepthTex1, samplePos.xy, 0.0).x;
				sampleDist = LinearDepth_From_ScreenDepth_DH(sampleDepth);
			}else{
				sampleDist = LinearDepth_From_ScreenDepth(sampleDepth);
			}
		#else
			float sampleDist = LinearDepth_From_ScreenDepth(textureLod(depthtex1, samplePos.xy, 0.0).x);
		#endif

		float depthDiff = samplePos.z - sampleDist;

		if (depthDiff > 0.0 && depthDiff < zThickness) shadow *= absorption;

		if (shadow < 0.01) break;
	}

	return shadow;
}

vec3 GetWavesNormalFromTex(vec3 position){
	const float maxCausticsNormalHeight = CAUSTICS_TEX_RESOLUTION;

	vec2 coord = position.xz;
	vec3 lightVector = refract(worldShadowVector, vec3(0.0, 1.0, 0.0), 1.0 / WATER_REFRACT_IOR);
	coord.x += position.y * lightVector.x / lightVector.y;
	coord.y += position.y * lightVector.z / lightVector.y;

	coord *= 0.02;
	coord = fract(coord);

	coord *= pixelSize * min(screenSize.y, maxCausticsNormalHeight);

	vec3 normal;
	normal.xyz = DecodeNormal(textureLod(colortex7, coord, 0.0).xy);

	return normal;
}

float CalculateWaterCaustics(vec3 worldPos){
	worldPos.xyz += cameraPosition;

	vec2 dither = BlueNoiseTemproal();

	vec3 lookupCenter = worldPos + vec3(0.0, 1.0, 0.0);

	vec3 lightVector = refract(worldShadowVector, vec3(0.0, -1.0, 0.0), 1.0 / 1.2);
	vec3 depthBias = vec3(worldPos.y * lightVector.x, 0.0, worldPos.y * lightVector.z) / lightVector.y;


	float caustics = 0.0;

	for (float i = -1.0; i <= 1.0; i++){
		for (float j = -1.0; j <= 1.0; j++){
			vec2 offset = dither + vec2(i, j);

			vec3 lookupPoint = lookupCenter;
			lookupPoint.xz += offset * 0.1;

			vec3 wavesNormal = GetWavesNormalFromTex(lookupPoint).xzy;

			vec3 refractVector = refract(vec3(0.0, 1.0, 0.0), wavesNormal.xyz, 1.0);
			vec3 collisionPoint = lookupPoint - refractVector / refractVector.y;
			collisionPoint -= worldPos;

			float dist = dot(collisionPoint, collisionPoint) * 7.1;

			caustics += 1.0 - saturate(dist * 7.0);
		}
	}

	return mix(caustics * 0.16 + 0.2, 1.0, 0.3 - 0.3 * float(isEyeInWater));
}
