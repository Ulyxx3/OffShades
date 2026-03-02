

float CalculateCoCRadius(float f, float d, float a){
	return abs(a * (d - f) / (d * f));
}

float GetLinearDepth(vec2 coord){
	float depth = textureLod(depthtex0, coord, 0.0).x;
	#ifdef DISTANT_HORIZONS
		if (depth == 1.0){
			depth = textureLod(dhDepthTex0, coord, 0.0).x;
			depth = saturate(ScreenDepth_From_DHScreenDepth(depth));
		}
	#endif
	depth = max(depth, 0.875);
	return LinearDepth_From_ScreenDepth(depth);
}

float GetFocus(){
	#if CAMERA_FOCUS_MODE == 0
		float focus = LinearDepth_From_ScreenDepth(texelFetch(colortex2, ivec2(60, screenSize.y - 1.0), 0).a * 0.125 + 0.875);
	#else
		float focus = CAMERA_FOCAL_POINT;
	#endif
	return focus;
}


float CoCSpread(){
	float cocRadiusfactor = DOF_BLUR * gbufferProjection[1][1];
	const float maxCoc = DOF_MAX_COC;
	const float rMaxCoc = 1.0 / maxCoc;
	float rAspectRatio = 1.0 / aspectRatio;
	#ifdef TAA
		vec2 noise = BlueNoiseTemproal();
	#else
		vec2 noise = BlueNoise();
	#endif

	float currDepth = GetLinearDepth(texCoord);
	float focus = GetFocus();
	float currCoc = CalculateCoCRadius(focus, currDepth, cocRadiusfactor);

	float startRadius = currCoc * rMaxCoc;
	startRadius *= startRadius;


	float spreadCoc = currCoc;


	const float steps = DOF_COCSPREAD_QUALITY;
	const float rSteps = 1.0 / steps;
	const mat2 rotMat = mat2(cos(goldenAngle), sin(goldenAngle), -sin(goldenAngle), cos(goldenAngle));
	float angle = noise.x * TAU;
	vec2 rot = vec2(cos(angle), sin(angle));

	for (float i = 0.0; i < steps; i++){
		rot *= rotMat;
		float sampleRadius = sqrt(startRadius + (i + noise.y) * (1.0 - startRadius) * rSteps) * maxCoc;
		vec2 sampleCoordOffset = rot * sampleRadius;
		sampleCoordOffset.x *= rAspectRatio;
		vec2 sampleCoord = texCoord + sampleCoordOffset;

		float sampleDepth = GetLinearDepth(sampleCoord);
		float sampleCoC = CalculateCoCRadius(focus, sampleDepth, cocRadiusfactor);

		if (sampleCoC >= sampleRadius && sampleDepth <= currDepth){
			spreadCoc = max(spreadCoc, sampleCoC);
		}
	}

	spreadCoc = min(spreadCoc, maxCoc) * rMaxCoc;
	return spreadCoc;
}

vec4 DepthOfField(){
	float cocRadiusfactor = DOF_BLUR * gbufferProjection[1][1];
	float minCoc = 0.5641895835 * pixelSize.y;
	const float maxCoc = DOF_MAX_COC;
	float rAspectRatio = 1.0 / aspectRatio;
	#ifdef TAA
		vec2 noise = BlueNoiseTemproal();
	#else
		vec2 noise = BlueNoise();
	#endif


	float currDepth = GetLinearDepth(texCoord);
	float focus = GetFocus();
	float currCoc = CalculateCoCRadius(focus, currDepth, cocRadiusfactor);
	currCoc = clamp(currCoc, minCoc, maxCoc);

	vec4 currData = textureLod(colortex1, texCoord, 0.0);

	float spreadCoc = currData.a * maxCoc;

	float centerWeight = spreadCoc * spreadCoc - spreadCoc + 1.0;
    centerWeight = mix(centerWeight, 1e-20, pow(currCoc / spreadCoc, 4.0));

	#ifdef DOF_CATSEYE
		vec2 catsEyeOffset = (texCoord) * 2.0 - 1.0;
		catsEyeOffset.x *= aspectRatio;
		float catsEyeDist = length(catsEyeOffset);
		catsEyeDist = max(catsEyeDist - DOF_CATSEYE_MIDPOINT, 0.0);
		catsEyeDist *= spreadCoc * DOF_CATSEYE_STRENGTH;
		catsEyeOffset = normalize(catsEyeOffset) * catsEyeDist;
	#endif


	vec3 dof = vec3(0.0);
	float weights = 0.0;
	vec3 selfColor = CurveToLinear(currData.rgb) * 1e-20;
	float selfSamples = 1e-20;
	float selfWeights = 0.0;
#ifdef DIMENSION_NETHER
	float blendedDepth = 0.0;
	float selfDepth = currDepth * 1e-20;
#endif


	const float steps = DOF_QUALITY;
	const float rSteps = 1.0 / steps;
	const float firstStepRadius = sqrt(rSteps);
	const mat2 rotMat = mat2(cos(goldenAngle), sin(goldenAngle), -sin(goldenAngle), cos(goldenAngle));
	float angle = noise.x * TAU;
	vec2 rot = vec2(cos(angle), sin(angle));

	for (float i = 0.0; i < steps; i++){
		rot *= rotMat;
		float sampleRadius = sqrt((i + noise.y) * rSteps) * spreadCoc;
		vec2 sampleCoordOffset = rot * sampleRadius;
		
		#ifdef DOF_CATSEYE
			if (distance(catsEyeOffset, sampleCoordOffset) > spreadCoc) continue;
		#endif

		sampleCoordOffset.x *= rAspectRatio;
		
		vec2 sampleCoord = texCoord + sampleCoordOffset;

		float sampleDepth =  GetLinearDepth(sampleCoord);
		float sampleCoC = CalculateCoCRadius(focus, sampleDepth, cocRadiusfactor);
		sampleCoC = clamp(sampleCoC, minCoc, maxCoc);
		vec3 sampleColor = CurveToLinear(textureLod(colortex1, sampleCoord, 0.0).rgb);

#ifdef DIMENSION_NETHER

		if (currCoc >= sampleRadius && sampleDepth >= currDepth){
			selfColor += sampleColor;
			selfDepth += sampleDepth;
			selfSamples += 1.0;
		}else if (sampleCoC >= sampleRadius && sampleDepth < currDepth){
			float sampleWeight = max(1.0, currCoc / sampleCoC);
			sampleWeight *= sampleWeight;
			dof += sampleColor * sampleWeight;
			blendedDepth += sampleDepth * sampleWeight;
			weights += sampleWeight;
		}else{
			selfWeights += centerWeight;
		}
	}

	dof += selfColor * (1.0 + selfWeights / selfSamples);
    dof /= weights + selfSamples + selfWeights;

	blendedDepth += selfDepth * (1.0 + selfWeights / selfSamples);
	blendedDepth /= weights + selfSamples + selfWeights;

    return vec4(LinearToCurve(dof), ScreenDepth_From_LinearDepth(blendedDepth));

#else

		if (currCoc >= sampleRadius && sampleDepth >= currDepth){
			selfColor += sampleColor;
			selfSamples += 1.0;
		}else if (sampleCoC >= sampleRadius && sampleDepth < currDepth){
			float sampleWeight = max(1.0, currCoc / sampleCoC);
			sampleWeight *= sampleWeight;
			dof += sampleColor * sampleWeight;
			weights += sampleWeight;
		}else{
			selfWeights += centerWeight;
		}
	}

	dof += selfColor * (1.0 + selfWeights / selfSamples);
    dof /= weights + selfSamples + selfWeights;

    return vec4(LinearToCurve(dof), 0.0);

#endif
}
