vec3 ViewPos_From_ScreenPos(vec2 coord, float depth){
	#ifdef TAA
		coord -= taaJitter * 0.5;
	#endif
	vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
	vec3 viewPos = vec3(vec2(gbufferProjectionInverse[0][0], gbufferProjectionInverse[1][1]) * ndcPos.xy, 0.0) + gbufferProjectionInverse[3].xyz;
	return viewPos / (gbufferProjectionInverse[2][3] * ndcPos.z + gbufferProjectionInverse[3][3]);
}

vec3 ViewPos_From_ScreenPos_Raw(vec2 coord, float depth){
	vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
	vec3 viewPos = vec3(vec2(gbufferProjectionInverse[0][0], gbufferProjectionInverse[1][1]) * ndcPos.xy, 0.0) + gbufferProjectionInverse[3].xyz;
	return viewPos / (gbufferProjectionInverse[2][3] * ndcPos.z + gbufferProjectionInverse[3][3]);
}

vec3 ScreenPos_From_ViewPos(vec3 viewPos){
	vec3 screenPos = vec3(gbufferProjection[0][0], gbufferProjection[1][1], gbufferProjection[2][2]) * viewPos + gbufferProjection[3].xyz;
	screenPos = screenPos * (0.5 / -viewPos.z) + 0.5;
	#ifdef TAA
		screenPos.xy += taaJitter * 0.5;
	#endif
	return screenPos;
}

vec3 ScreenPos_From_ViewPos_Raw(vec3 viewPos){
	vec3 screenPos = vec3(gbufferProjection[0][0], gbufferProjection[1][1], gbufferProjection[2][2]) * viewPos + gbufferProjection[3].xyz;
	return screenPos * (0.5 / -viewPos.z) + 0.5;
}

float LinearDepth_From_ScreenDepth(float depth){
	depth = depth * 2.0 - 1.0;
	return 1.0 / (depth * gbufferProjectionInverse[2][3] + gbufferProjectionInverse[3][3]);
}

float ScreenDepth_From_LinearDepth(float depth){
	depth = (1.0 / depth - gbufferProjectionInverse[3][3]) / gbufferProjectionInverse[2][3];
	return depth * 0.5 + 0.5;
}

#ifdef DISTANT_HORIZONS

	vec3 ViewPos_From_ScreenPos_DH(vec2 coord, float depth){
		#ifdef TAA
			coord -= taaJitter * 0.5;
		#endif
		vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
		vec4 viewPos = dhProjectionInverse * vec4(ndcPos, 1.0);
		return viewPos.xyz / viewPos.w;
	}

	vec3 ViewPos_From_ScreenPos_Raw_DH(vec2 coord, float depth){
		vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
		vec4 viewPos = dhProjectionInverse * vec4(ndcPos, 1.0);
		return viewPos.xyz / viewPos.w;
	}

	vec3 ScreenPos_From_ViewPos_DH(vec3 viewPos){
		vec3 screenPos = vec3(dhProjection[0][0], dhProjection[1][1], dhProjection[2][2]) * viewPos + dhProjection[3].xyz;
		screenPos = screenPos * (0.5 / -viewPos.z) + 0.5;
		#ifdef TAA
			screenPos.xy += taaJitter * 0.5;
		#endif
		return screenPos;
	}

	vec3 ScreenPos_From_ViewPos_Raw_DH(vec3 viewPos){
		vec3 screenPos = vec3(dhProjection[0][0], dhProjection[1][1], dhProjection[2][2]) * viewPos + dhProjection[3].xyz;
		return screenPos * (0.5 / -viewPos.z) + 0.5;
	}

	float LinearDepth_From_ScreenDepth_DH(float depth){
		depth = depth * 2.0 - 1.0;
		return 1.0 / (depth * dhProjectionInverse[2][3] + dhProjectionInverse[3][3]);
	}

	float ScreenDepth_From_LinearDepth_DH(float depth){
		depth = (1.0 / depth - dhProjectionInverse[3][3]) / dhProjectionInverse[2][3];
		return depth * 0.5 + 0.5;
	}

	float ScreenDepth_From_DHScreenDepth(float depth){
		depth = depth * 2.0 - 1.0;
		depth = 1.0 / (depth * dhProjectionInverse[2][3] + dhProjectionInverse[3][3]);
		depth = (1.0 / depth - gbufferProjectionInverse[3][3]) / gbufferProjectionInverse[2][3];
    	return depth * 0.5 + 0.5;
	}

#endif