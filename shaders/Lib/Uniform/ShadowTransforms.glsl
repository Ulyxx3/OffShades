

vec3 ShadowScreenPos_From_WorldPos_Distorted(vec3 worldPos){
	vec3 shadowPos = mat3(shadowModelView) * worldPos + shadowModelView[3].xyz;
	shadowPos *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);

	float dist = length(shadowPos.xy);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	shadowPos.xy *= 0.95 / distortFactor;

	return shadowPos * 0.5 + 0.5;
}

vec3 ShadowScreenPos_From_WorldPos(vec3 worldPos){
	vec3 shadowPos = mat3(shadowModelView) * worldPos + shadowModelView[3].xyz;
	shadowPos *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);

	return shadowPos * 0.5 + 0.5;
}

vec3 ShadowScreenPos_From_WorldPos_WithoutZScaling(vec3 worldPos){
	vec3 shadowPos = mat3(shadowModelView) * worldPos + shadowModelView[3].xyz;
	shadowPos *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);
	
	return shadowPos * 0.5 + 0.5;
}

vec2 DistortShadowScreenPos(vec2 shadowPos){
	shadowPos = shadowPos * 2.0 - 1.0;

	float dist = length(shadowPos.xy);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	shadowPos *= 0.95 / distortFactor;

	return shadowPos * 0.5 + 0.5;
}
