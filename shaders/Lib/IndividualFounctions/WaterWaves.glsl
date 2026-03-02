vec4 textureSmooth(sampler2D texSampler, vec2 coord){
	coord *= 64.0;
	coord += 0.5;

	vec2 whole = floor(coord);
	vec2 part  = coord - whole;

	coord = whole + curve(part);

	coord -= 0.5;
	coord *= 0.015625;

	return textureLod(texSampler, coord, 0.0);
}

float AlmostIdentity(float x, float m, float n){
	x = abs(x * 2.0 - 1.0);

	if (x <= m){
		float a = 2.0 * n - m;
		float b = 2.0 * m - 3.0 * n;
		float t = x / m;

		x = (a * t + b) * t * t + n;
	}

	return 1.0 - x;
}


float GetWaves(vec3 position) {
	float wavesTime = frameTimeCounter * 0.0035;

	position *= WAVE_SCALE;
	vec2 p = position.xz - position.y;
	p += -3.875 * wavesTime;
	p.x = -p.x;

	vec2 waves = vec2(0.0);

	waves += vec2(textureSmooth(noisetex, p * vec2(2.0, 1.2) + vec2(0.0, p.x * 2.1)).w,
				  1.0);

		p = p * 0.475;
		p += vec2(-5.16, -7.75) * wavesTime;

	waves += vec2(textureSmooth(noisetex, p * vec2(2.0, 1.4) + vec2(0.0, -p.x * 2.1)).w
				  * 4.0, 4.0);

		p *= 0.67;
		p.x += 7.75 * wavesTime;

	waves += vec2(textureSmooth(noisetex, p + vec2(0.0, p.x * 1.1)).z
				  * 8.0, 8.0);

		p *= 0.7;
		p.x += -2.82 * wavesTime;

	waves += vec2(textureSmooth(noisetex, p * vec2(1.0, 0.75) + vec2(0.0, -p.x * 1.7)).w
				  * 16.0, 16.0);

		p *= 0.45;
		p.x += wavesTime;

	waves += vec2(AlmostIdentity(textureSmooth(noisetex, p * vec2(1.0, 0.8) + vec2(0.0, -p.x * 1.7)).z, 0.2, 0.1)
				  * 30.0, 30.0);

		p *= 0.5;
		p.x += wavesTime;

	waves += vec2(AlmostIdentity(textureSmooth(noisetex, p * vec2(1.0, 0.8) + vec2(0.0,  p.x * 1.7)).w, 0.2, 0.1)
				  * 20.0, 20.0);

	return waves.x / waves.y;
}

#define sampleDistance 12.0

vec3 GetWavesNormal(vec3 position, const float waveHeight){
	position.xz -= 0.005 * sampleDistance;

	float wavesCenter = GetWaves(position);
	float wavesLeft = GetWaves(position + vec3(0.01 * sampleDistance, 0.0, 0.0));
	float wavesUp   = GetWaves(position + vec3(0.0, 0.0, 0.01 * sampleDistance));

	vec3 wavesNormal = vec3(wavesCenter - wavesLeft, wavesCenter - wavesUp, 1.0);

	wavesNormal.xy *= waveHeight * (WAVE_HEIGHT / sampleDistance);

	return normalize(wavesNormal);
}


vec3 GetWaterParallaxCoord(vec3 position, vec3 viewVector){
	const vec3 stepSize = vec3(vec2(WAVE_HEIGHT * 0.8), 0.6);
	float waveHeight = GetWaves(position);
	vec3 pCoord = vec3(0.0, 0.0, 1.0);
	vec3 steps = viewVector * stepSize;

	float sampleHeight = waveHeight;

	for (int i = 0; sampleHeight < pCoord.z && i < 12; ++i)
	{
		pCoord.xy += steps.xy * saturate((pCoord.z - sampleHeight) * (-viewVector.z + 0.05) / (stepSize.z * 0.2));
		pCoord.z += steps.z;
		sampleHeight = GetWaves(position + vec3(pCoord.x, 0.0, pCoord.y));
	}

	return position.xyz + vec3(pCoord.x, 0.0, pCoord.y);
}
