

float GroundTruthBasedAmbientOcclusion(vec3 viewPos, vec3 viewDir, vec3 normal){
	#ifdef TAA
		vec2 noise = BlueNoiseTemproal();
	#else
		vec2 noise = BlueNoise();
	#endif

	const float steps = GTAO_QUALITY;
	const float rSteps = 1.0 / steps;

	const float sliceSteps = GTAO_SLICE_QUALITY;
	const float rSliceSteps = 1.0 / sliceSteps;



	const float falloffStart = GTAO_FALLOFF_START;
	const float maxSampleRadius = GTAO_MAX_RADIUS;
	#ifdef GTAO_FALLOFF_Z_OFFSET
		const float falloffZoffset = 1.7;
	#endif

	float projFactor = 0.125 * gbufferProjection[1][1];

	#if GTAO_RADIUS_MODE == 0
		#ifdef DISTANT_HORIZONS
			float radius = GTAO_WORLD_RADIUS - viewPos.z * 0.02;
		#else
			float radius = GTAO_WORLD_RADIUS - viewPos.z * 0.01;
		#endif

		float sampleRadiusRaw = radius * projFactor / -viewPos.z;
		float sampleRadius = min(sampleRadiusRaw, maxSampleRadius);
		float falloff = sampleRadius * radius / sampleRadiusRaw;
	#else
		const float sampleRadius = GTAO_SCREEN_RADIUS;
		float falloff = sampleRadius / projFactor * -viewPos.z;
	#endif

	float ao = 0.0;

	for (float i = 0.0; i < steps; i++){
		float sliceAngle = (i + noise.x) * rSteps * PI;

		vec3 sliceDir = vec3(cos(sliceAngle), sin(sliceAngle), 0.0);
		vec3 orthoSliceDir = sliceDir - dot(sliceDir, viewDir) * viewDir;
		vec3 axis = cross(sliceDir, viewDir);
		vec3 projNormal = normal - dot(normal, axis) * axis;
		
		float rProjNormalLength = inversesqrt(dot(projNormal, projNormal));

		float cosNormalAngle = saturate(dot(projNormal, viewDir) * rProjNormalLength);
		float normalAngle = sign(dot(orthoSliceDir, projNormal)) * facos(cosNormalAngle);

		vec2 minCosHorizonAngle = cos(vec2(normalAngle + hPI, normalAngle - hPI));

		vec2 maxCosHorizonAngle = minCosHorizonAngle;

		for (float j = 0.0; j < sliceSteps; j++){
			float stepNoise = (i + j * sliceSteps) * 0.61803399;
			stepNoise = fract(stepNoise + noise.y);

			float offset = (j + stepNoise) * rSliceSteps;
			offset *= offset;
			vec2 sampleOffset = offset * sliceDir.xy * sampleRadius;
			sampleOffset.y *= aspectRatio;

			{
				vec2 sampleCoord = texCoord + sampleOffset;
				float sampleDepth = textureLod(depthtex1, sampleCoord, 0.0).x;
				#ifdef DISTANT_HORIZONS
					vec3 sampleVector = vec3(0.0);
					if (sampleDepth == 1.0){
						sampleDepth = textureLod(dhDepthTex0, sampleCoord, 0.0).x;
						sampleVector = ViewPos_From_ScreenPos_DH(sampleCoord, sampleDepth);
					}else{
						sampleVector = ViewPos_From_ScreenPos(sampleCoord, sampleDepth);
					}
					sampleVector = sampleVector - viewPos;
				#else
					vec3 sampleVector = ViewPos_From_ScreenPos(sampleCoord, sampleDepth) - viewPos;
				#endif

				float rSampleDist = inversesqrt(dot(sampleVector, sampleVector));

				float cosHorizonAngle = dot(sampleVector, viewDir) * rSampleDist;

				#ifdef GTAO_FALLOFF_Z_OFFSET
					float offsetDist = length(vec3(sampleVector.xy, sampleVector.z * falloffZoffset));
					float falloffWeight = remapSaturate(offsetDist, falloff * falloffStart, falloff);
				#else
					float falloffWeight = remapSaturate(1.0 / rSampleDist, falloff * falloffStart, falloff);
				#endif
				cosHorizonAngle = mix(cosHorizonAngle, minCosHorizonAngle.x, falloffWeight);

				maxCosHorizonAngle.x = max(cosHorizonAngle, maxCosHorizonAngle.x);
			}{
				vec2 sampleCoord = texCoord - sampleOffset;
				float sampleDepth = textureLod(depthtex1, sampleCoord, 0.0).x;
				#ifdef DISTANT_HORIZONS
					vec3 sampleVector = vec3(0.0);
					if (sampleDepth == 1.0){
						sampleDepth = textureLod(dhDepthTex0, sampleCoord, 0.0).x;
						sampleVector = ViewPos_From_ScreenPos_DH(sampleCoord, sampleDepth);
					}else{
						sampleVector = ViewPos_From_ScreenPos(sampleCoord, sampleDepth);
					}
					sampleVector = sampleVector - viewPos;
				#else
					vec3 sampleVector = ViewPos_From_ScreenPos(sampleCoord, sampleDepth) - viewPos;
				#endif

				float rSampleDist = inversesqrt(dot(sampleVector, sampleVector));

				float cosHorizonAngle = dot(sampleVector, viewDir) * rSampleDist;
				
				#ifdef GTAO_FALLOFF_Z_OFFSET
					float offsetDist = length(vec3(sampleVector.xy, sampleVector.z * falloffZoffset));
					float falloffWeight = remapSaturate(offsetDist, falloff * falloffStart, falloff);
				#else
					float falloffWeight = remapSaturate(1.0 / rSampleDist, falloff * falloffStart, falloff);
				#endif				
				cosHorizonAngle = mix(cosHorizonAngle, minCosHorizonAngle.y, falloffWeight);

				maxCosHorizonAngle.y = max(cosHorizonAngle, maxCosHorizonAngle.y);
			}
		}
		maxCosHorizonAngle = vec2(-facos(maxCosHorizonAngle.y), facos(maxCosHorizonAngle.x)) * 2.0;

		float horizonAngleIntegra = 2.0 * cosNormalAngle + (maxCosHorizonAngle.x + maxCosHorizonAngle.y) * sin(normalAngle) - cos(maxCosHorizonAngle.x - normalAngle) - cos(maxCosHorizonAngle.y - normalAngle);

		ao += horizonAngleIntegra / rProjNormalLength;
	}
	ao *= 0.25 * rSteps;

	return saturate(mix(1.0, ao, GTAO_STRENGTH));
}

vec3 GTAOMultiBounce(float ao, vec3 albedo){
	vec3 a =  2.0404 * albedo - 0.3324;
	vec3 b = -4.7951 * albedo + 0.6417;
	vec3 c =  2.7552 * albedo + 0.6903;

	return max(vec3(ao), ((ao * a + b) * ao + c) * ao);
}