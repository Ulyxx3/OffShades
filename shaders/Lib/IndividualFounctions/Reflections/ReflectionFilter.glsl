

void AtrousWaveletFilter(inout vec4 reflectionData, vec3 viewPos, vec3 viewDir, vec3 normal, float roughness, float radius, vec2 noise){
	float linearDepth = -viewPos.z;
	float NdotV = saturate(dot(-viewDir, normal));

	roughness = max(roughness, 1e-4);

	radius *= min(roughness * 20.0, 1.0);
	radius *= reflectionData.a * 0.9 + 0.1;

	const mat2 rot90 = mat2(cos(1.5708), -sin(1.5708), sin(1.5708), cos(1.5708));

	vec2 T = normalize(cross(normal, viewDir).xy) * radius;
	vec2 B = T * rot90;
	T *= mix(0.1075, 0.5, NdotV) * pixelSize;
	B *= mix(0.7, 0.5, NdotV) * pixelSize;

	vec3 reflectedDir = reflect(-viewDir, normal);

	float normalThreshold = 75.0 / roughness;
	float luminanceThreshold = reflectionData.a * 0.95 + 0.05;
	
	vec4 accum = vec4(0.0);
	float weights = 0.0;

	const vec2 offset[9] = vec2[9](
		vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0), 
		vec2(-1.0,  0.0), vec2(0.0,  0.0), vec2(1.0,  0.0), 
		vec2(-1.0,  1.0), vec2(0.0,  1.0), vec2(1.0,  1.0));

	for (int i = 0; i < 9; i++){
		vec2 sampleCoord = texCoord + T * (offset[i] + noise.x) + B * (offset[i] + noise.y);

		vec4 sampleData = textureLod(colortex3, sampleCoord, 0.0);

		if (sampleData.a < 0.0001) continue;

		float sampleLinerDepth = LinearDepth_From_ScreenDepth(textureLod(depthtex0, sampleCoord, 0.0).x);
		vec3 sampleReflectedDir = reflect(-viewDir, DecodeNormal(textureLod(colortex4, sampleCoord, 0.0).xy));

		float normalWeight = pow(saturate(dot(sampleReflectedDir, reflectedDir)), normalThreshold);
		float depthWeight = exp2(-(abs(sampleLinerDepth - linearDepth) * 1.58));
		float sampleWeight = normalWeight * depthWeight;
		
		sampleData.rgb += 1e-13;
		float luminance = length(sampleData.rgb);
		sampleData.rgb *= pow(luminance, luminanceThreshold) / luminance;

		accum += sampleData * sampleWeight;
		weights += sampleWeight;
	
	}
	
	if (weights > 1e-13){
		accum /= weights;

		accum.rgb += 1e-13;
		float luminance = length(accum.rgb);
		accum.rgb *= pow(luminance, 1.0 / luminanceThreshold) / luminance;

		reflectionData = accum;
	}
}