

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
	vec3 lookupCenter = worldPos;
	lookupCenter.y += 1.0;

	vec3 wavesNormal = GetWavesNormalFromTex(lookupCenter).xzy;
	vec3 refractVector = refract(vec3(0.0, 1.0, 0.0), wavesNormal.xyz, 1.0);
	vec3 collisionPoint = lookupCenter - refractVector / refractVector.y;

	float dist = distance(collisionPoint, worldPos);

	return dist * 2.8 + 0.2;
}


vec3 UnderwaterVolumetricFog(vec3 startPos, vec3 endPos, vec3 worldDir, float globalCloudShadow){
	const float range = 40.0;

	float startDist = length(startPos);
	if(startDist > range) return vec3(0.0);

	endPos = mix(worldDir * range, endPos, step(length(endPos), range));

	float rayDist = distance(startPos, endPos);
	vec3 rayDir = (endPos - startPos) / rayDist;

	const float steps = VFOG_QUALITY;
	const float stepLength = range / steps;

	float noise = BlueNoiseTemproal().y;

	vec3 result = vec3(0.0);

	for (float i = 0.0; i < steps; i++){
		float rayLength = (i + noise) * stepLength;
		vec3 rayPos = startPos + rayDir * rayLength;

		if(startDist + rayLength > range || rayLength > rayDist) break;

		vec3 shadowProjPos = ShadowScreenPos_From_WorldPos_Distorted(rayPos + gbufferModelViewInverse[3].xyz);
		#ifdef MC_GL_VENDOR_NVIDIA
			vec3 shadow = vec3(step(shadowProjPos.z + 1e-06, textureLod(shadowtex1, shadowProjPos.xy, 0).x));
		#else
			vec3 shadow = vec3(step(shadowProjPos.z + 1e-06, textureLod(shadowtex0, shadowProjPos.xy, 0).x));
		#endif

		rayLength += startDist;

		float caustics = CalculateWaterCaustics(rayPos);
		shadow *= caustics * caustics * caustics;
		shadow /= max(3.0, rayLength * 0.1);
		#ifdef UNDERWATER_FOG
			shadow *= pow(vec3(0.1, 0.6, 1.0) * 0.99, vec3(rayLength * 0.04 * WATERFOG_DENSITY));
		#endif

		result += shadow;
	}
	result *= range / steps;

	vec3 lightVector = refract(worldShadowVector, vec3(0.0, -1.0, 0.0), 1.0 / 1.2);
	float LdotV = dot(lightVector,worldDir);
	float phace = MiePhaseFunction(0.7, LdotV);

	result *= colorShadowlight * (0.04 * phace * SUNLIGHT_INTENSITY * UNDERWATER_VFOG_DENSITY);

	#ifdef UNDERWATER_FOG
		result *= vec3(0.2, 0.65, 1.0);
	#endif

	result *= globalCloudShadow;

	return result;
}
