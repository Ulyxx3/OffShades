

#ifdef GI_RSM

////////////////////PROGRAM_GI_0////////////////////////////////////////////////////////////////////
////////////////////PROGRAM_GI_0////////////////////////////////////////////////////////////////////
#ifdef PROGRAM_GI_0

vec3 RSM(vec3 viewPos, vec3 normal){
	vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;

	vec3 shadowPosition = ShadowScreenPos_From_WorldPos_WithoutZScaling(worldPos);

	#ifdef DIMENSION_END
		vec3 shadowNormal = mat3(shadowModelViewEnd) * mat3(gbufferModelViewInverse) * normal;
	#else
		vec3 shadowNormal = mat3(shadowModelView) * mat3(gbufferModelViewInverse) * normal;
	#endif

	float pixelOffset = GI_RADIUS * shadowProjection[0][0];

	float zScale = 1.0 / shadowProjection[0][0];

	vec2 noise = BlueNoiseTemproal();

	const mat2 rotMat = mat2(cos(goldenAngle), sin(goldenAngle), -sin(goldenAngle), cos(goldenAngle));
	float angle = noise.x * TAU;
	vec2 rot = vec2(cos(angle), sin(angle));


	const float steps = GI_QUALITY;
	const float rSteps = 1.0 / steps;

	vec3 rsm = vec3(0.0);

	for (float i = 0.0; i < steps; i++){
		rot *= rotMat;
		float r = (i + noise.y) * rSteps;
		vec2 offset = rot * r * pixelOffset;

		vec2 offsetPosition = shadowPosition.xy + offset;
		vec2 sampleCoord = DistortShadowScreenPos(offsetPosition);
		ivec2 sampleTexelcoord = ivec2(shadowMapResolution * sampleCoord);

		#ifdef MC_GL_VENDOR_NVIDIA
			float sampleDepth = texelFetch(shadowtex1, sampleTexelcoord, 0).x;
		#else
			float sampleDepth = texelFetch(shadowtex0, sampleTexelcoord, 0).x;
		#endif
		if (sampleDepth == 0.0 || sampleDepth >= 1.0) continue;


		vec3 sampleVector = vec3(offsetPosition, sampleDepth) - shadowPosition;
		sampleVector *= vec3(zScale, zScale, -zScale * 2.0);

		vec3 sampleDir = normalize(sampleVector);

		float NdotV = dot(sampleDir, shadowNormal);
		if (NdotV <= 0.0) continue;

		vec4 sampleData = texelFetch(shadowcolor1, sampleTexelcoord, 0);
		vec3 sampleNormal = sampleData.rgb * 2.0 - 1.0;

		float SNdotV = dot(-sampleDir, sampleNormal) * 1.004 - 0.004;
		if (SNdotV < 0.0) continue;

		vec3 sampleAlbedo = GammaToLinear(texelFetch(shadowcolor0, sampleTexelcoord, 0).rgb);

		sampleVector.z *= 1.5;
		float sampleDist = length(sampleVector);
		float distFalloff = pow(sampleDist + 0.035, -GI_FALLOFF) * fsqrt(1.0 - r);

		#if defined SUNLIGHT_LEAK_FIX && !defined DIMENSION_END 
			float mcLightingMask = saturate(sampleData.a * 15.0 + float(isEyeInWater == 1));

			rsm += sampleAlbedo * (NdotV * SNdotV * distFalloff * mcLightingMask);
		#else
			rsm += sampleAlbedo * (NdotV * SNdotV * distFalloff);
		#endif
	}

	rsm *= rSteps * GI_RADIUS * 0.1;

	return rsm;
}


#ifdef DISTANT_HORIZONS

vec2 CalculateCameraVelocity(vec2 coord, float depth, bool isDH){
	vec3 screenPos = vec3(coord, depth);
	vec3 projection = vec3(screenPos * 2.0 - 1.0);

	if (isDH){
		projection = (vec3(vec2(dhProjectionInverse[0].x, dhProjectionInverse[1].y) * projection.xy, 0.0) + dhProjectionInverse[3].xyz) / (dhProjectionInverse[2].w * projection.z + dhProjectionInverse[3].w);
		projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
		projection += cameraPosition - previousCameraPosition;
		projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
	}else{
		projection = (vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * projection.xy, 0.0) + gbufferProjectionInverse[3].xyz) / (gbufferProjectionInverse[2].w * projection.z + gbufferProjectionInverse[3].w);

		#if defined DISABLE_HAND_GI_VELOCITY && defined DISABLE_PLAYER_GI_VELOCITY
			float materialIDs = floor(texelFetch(colortex5, ivec2(floor(coord * screenSize)), 0).b * 255.0);
			if (depth >= 0.7 && materialIDs != MATID_ENTITIES_PLAYER){
				projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
				projection += cameraPosition - previousCameraPosition;
				projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
			}
		#elif defined DISABLE_HAND_GI_VELOCITY
			if (depth >= 0.7){
				projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
				projection += cameraPosition - previousCameraPosition;
				projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
			}
		#elif defined DISABLE_PLAYER_GI_VELOCITY
			float materialIDs = floor(texelFetch(colortex5, ivec2(floor(coord * screenSize)), 0).b * 255.0);
			if (materialIDs != MATID_ENTITIES_PLAYER){
				if (depth < 0.7){
					projection += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
				}else{
					projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
					projection += cameraPosition - previousCameraPosition;
					projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
				}
			}
		#else
			if (depth < 0.7){
				projection += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
			}else{
				projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
				projection += cameraPosition - previousCameraPosition;
				projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
			}
		#endif
	}

	projection = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;

	return coord - projection.xy;
}
	
#else

vec2 CalculateCameraVelocity(vec2 coord, float depth){
	vec3 projection = vec3(coord, depth) * 2.0 - 1.0;
	projection = (vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * projection.xy, 0.0) + gbufferProjectionInverse[3].xyz) / (gbufferProjectionInverse[2].w * projection.z + gbufferProjectionInverse[3].w);

	#if defined DISABLE_HAND_GI_VELOCITY && defined DISABLE_PLAYER_GI_VELOCITY
		float materialIDs = floor(texelFetch(colortex5, ivec2(floor(coord * screenSize)), 0).b * 255.0);
		if (depth >= 0.7 && materialIDs != MATID_ENTITIES_PLAYER){
			projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
			projection += cameraPosition - previousCameraPosition;
			projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
		}
	#elif defined DISABLE_HAND_GI_VELOCITY
		if (depth >= 0.7){
			projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
			projection += cameraPosition - previousCameraPosition;
			projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
		}
	#elif defined DISABLE_PLAYER_GI_VELOCITY
		float materialIDs = floor(texelFetch(colortex5, ivec2(floor(coord * screenSize)), 0).b * 255.0);
		if (materialIDs != MATID_ENTITIES_PLAYER){
			if (depth < 0.7){
				projection += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
			}else{
				projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
				projection += cameraPosition - previousCameraPosition;
				projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
			}
		}
	#else
		if (depth < 0.7){
			projection += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
		}else{
			projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
			projection += cameraPosition - previousCameraPosition;
			projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
		}
	#endif
	
	projection = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;
	return coord - projection.xy;
}

#endif

vec4 GI_TemporalFilter(){
	vec4 prev = texelFetch(colortex2, texelCoord, 0);
	vec2 coord = texCoord / GI_RENDER_RESOLUTION;


	if (saturate(coord) == coord){
		ivec2 texel = ivec2(coord * screenSize);

		float currDepth = texelFetch(depthtex1, texel, 0).x;

		#ifdef DISTANT_HORIZONS
			bool isDH = false;
			if (currDepth == 1.0){
				currDepth = texelFetch(dhDepthTex0, texel, 0).x;
				isDH = true;
			}
		#endif

		if (currDepth < 1.0){
			vec4 data3 = texelFetch(colortex3, texel, 0);
			vec3 currNormal = DecodeNormal(data3.xy);
			vec3 currViewPos = ViewPos_From_ScreenPos_Raw(coord, currDepth);

			#ifdef DISTANT_HORIZONS
				if (isDH) currViewPos = ViewPos_From_ScreenPos_Raw_DH(coord, currDepth);
			#endif

			vec3 gi = vec3(0.0);
			#if MC_VERSION >= 11605
				#if defined SUNLIGHT_LEAK_FIX && !defined DIMENSION_END 
					if (data3.w > 0.0 || isEyeInWater == 1)
				#endif
					gi = RSM(currViewPos, currNormal);
			#else
				#if defined SUNLIGHT_LEAK_FIX && !defined DIMENSION_END 
					if (currDepth > 0.7 && (data3.w > 0.0 || isEyeInWater == 1))
				#else
					if (currDepth > 0.7)
				#endif
					gi = RSM(currViewPos, currNormal);
			#endif


			#ifdef DISTANT_HORIZONS
				vec2 velocity = CalculateCameraVelocity(coord, currDepth, isDH);
			#else
				vec2 velocity = CalculateCameraVelocity(coord, currDepth);
			#endif

			vec2 pcoord = coord - velocity;
			vec2 prevCoord = clamp(pcoord, vec2(0.0), vec2(1.0) - pixelSize * 2.0);

			if (prevCoord == pcoord){
				prevCoord = prevCoord * GI_RENDER_RESOLUTION * screenSize - 0.5;

				vec2 prevTexel = floor(prevCoord);

				vec3 prevGi = vec3(0.0);
				float weights = 0.0;

				for(float i = 0.0; i <= 1.0; i++){
				for(float j = 0.0; j <= 1.0; j++){
					vec2 sampleTexelcoord = prevTexel + vec2(i, j);

					vec4 prevData = texelFetch(colortex2, ivec2(sampleTexelcoord.x + GI_RENDER_RESOLUTION * screenSize.x, sampleTexelcoord.y), 0);

					vec3 prevNormal = prevData.xyz * 2.0 - 1.0;
					float normalWeight = float(dot(currNormal, prevNormal) > 0.5);

					float currDist = -currViewPos.z;
					currDist = min(currDist, 1000.0);
					float prevDist = prevData.a * 1000.0;

					vec3 cameraVelocity = mat3(gbufferModelView) * (cameraPosition - previousCameraPosition);
					float depthWeight = max(abs(currDist - prevDist - cameraVelocity.z), 0.0);
					depthWeight = exp(-depthWeight / (currDist * 0.1 + 0.1));
					depthWeight = saturate(depthWeight * 2.0);

					float bilinearWeight = (1.0 - abs(prevCoord.x - sampleTexelcoord.x)) * (1.0 - abs(prevCoord.y - sampleTexelcoord.y));

					bilinearWeight *= normalWeight * depthWeight;
					
					prevGi += CurveToLinear(texelFetch(colortex2, ivec2(sampleTexelcoord), 0).rgb) * bilinearWeight;
					weights += bilinearWeight;
				}}

				gi = mix(gi, prevGi, 0.95 * weights);
			}

			prev = vec4(LinearToCurve(gi), 0.0);
		}
	}


	coord.x -= 1.0;

	if (saturate(coord) == coord){
		ivec2 texel = ivec2(floor(coord * screenSize));

		float depth = texelFetch(depthtex1, texel, 0).x;

		#ifdef DISTANT_HORIZONS
			bool isDH = false;
			if (depth == 1.0){
				depth = texelFetch(dhDepthTex0, texel, 0).x;
				isDH = true;
			}
		#endif

		if (depth < 1.0){

			vec3 normal = DecodeNormal(texelFetch(colortex3, texel, 0).xy);

			float dist = LinearDepth_From_ScreenDepth(depth);
			#ifdef DISTANT_HORIZONS
				if(isDH) dist = LinearDepth_From_ScreenDepth_DH(depth);
			#endif
			
			prev = vec4(normal * 0.5 + 0.5, dist * 0.001);
		}else{
			prev = vec4(vec3(0.5), 0.0);
		}
	}
	return prev;
}

#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////





////////////////////PROGRAM_GI_1////////////////////////////////////////////////////////////////////
////////////////////PROGRAM_GI_1////////////////////////////////////////////////////////////////////
#ifdef PROGRAM_GI_1

vec3 GI_SpatialFilter(float dist, vec3 normal, vec3 viewDir){
	const vec2 offset[49] = vec2[49](
	vec2(-3.0, -3.0), vec2(-2.0, -3.0), vec2(-1.0, -3.0), vec2(0.0, -3.0), vec2(1.0, -3.0), vec2(2.0, -3.0), vec2(3.0, -3.0),
	vec2(-3.0, -2.0), vec2(-2.0, -2.0), vec2(-1.0, -2.0), vec2(0.0, -2.0), vec2(1.0, -2.0), vec2(2.0, -2.0), vec2(3.0, -2.0),
	vec2(-3.0, -1.0), vec2(-2.0, -1.0), vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0), vec2(2.0, -1.0), vec2(3.0, -1.0),
	vec2(-3.0,  0.0), vec2(-2.0,  0.0), vec2(-1.0,  0.0), vec2(0.0,  0.0), vec2(1.0,  0.0), vec2(2.0,  0.0), vec2(3.0,  0.0),
	vec2(-3.0,  1.0), vec2(-2.0,  1.0), vec2(-1.0,  1.0), vec2(0.0,  1.0), vec2(1.0,  1.0), vec2(2.0,  1.0), vec2(3.0,  1.0),
	vec2(-3.0,  2.0), vec2(-2.0,  2.0), vec2(-1.0,  2.0), vec2(0.0,  2.0), vec2(1.0,  2.0), vec2(2.0,  2.0), vec2(3.0,  2.0),
	vec2(-3.0,  3.0), vec2(-2.0,  3.0), vec2(-1.0,  3.0), vec2(0.0,  3.0), vec2(1.0,  3.0), vec2(2.0,  3.0), vec2(3.0,  3.0));

	vec2 coord = texCoord * GI_RENDER_RESOLUTION;

	float weights = 0.0;
	vec3 gi = vec3(0.0);

	float clampedDist = min(dist, 1000.0);

	float b = clampedDist * 0.001 + 0.025;
	float depthThreshold = min(0.1 + clampedDist * 0.05, 1.1) + saturate(1.0 - abs(dot(normal, viewDir)) / b) * 10.0;

	vec2 border = vec2(GI_RENDER_RESOLUTION) - pixelSize * 2.0;
	vec2 offsetScale = pixelSize * 4.0 * GI_RENDER_RESOLUTION;

	for (int i = 0; i < 49; i++){
		vec2 sampleCoord = coord + offset[i] * offsetScale;
		sampleCoord = clamp(sampleCoord, vec2(0.0), border);

		float weight = length(offset[i]);
	  	weight = exp2(-weight * weight * 0.1);

		vec4 sampleData = textureLod(colortex2, sampleCoord + vec2(GI_RENDER_RESOLUTION, 0.0), 0.0);

		vec3 sampleNormal = sampleData.xyz * 2.0 - 1.0;
		float normalWeight = abs(dot(normal, sampleNormal));
		normalWeight = pow(normalWeight, 64.0);

		float depthWeight = saturate(-abs(sampleData.w * 1000.0 - clampedDist) + depthThreshold);

		weight = weight * normalWeight * depthWeight + 1e-20;
		gi += CurveToLinear(textureLod(colortex2, sampleCoord, 0.0).rgb) * weight;
		weights += weight;
	}
	gi /= weights;

	return LinearToCurve(gi);
}

#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////

#endif
