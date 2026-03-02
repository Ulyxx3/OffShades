

float BicubicBlurNoise(vec2 coord){
	coord = coord * (1.2e-4 * 64.0) - 0.5;

	vec2 p = floor(coord);
	vec2 f = coord - p;

	vec2 ff = f * f;
	vec4 w0;
	vec4 w1;
	w0.xz = 1.0 - f; w0.xz *= w0.xz * w0.xz;
	w1.yw = ff * f;
	w1.xz = 3.0 * w1.yw + 4.0 - 6.0 * ff;
	w0.yw = 6.0 - w1.xz - w1.yw - w0.xz;

	vec4 s = w0 + w1;
	vec4 c = p.xxyy + vec2(-0.5, 1.5).xyxy + w1 / s;
	c *= 1.0 / 64.0;

	vec2 m = s.xz / (s.xz + s.yw);
	return mix(mix(textureLod(noisetex, c.yw, 0.0).w, textureLod(noisetex, c.xw, 0.0).w, m.x),
			   mix(textureLod(noisetex, c.yz, 0.0).w, textureLod(noisetex, c.xz, 0.0).w, m.x),
			   m.y);
}

float BilinearNoise(vec2 position) {
	return textureLod(noisetex, position * 1.2e-4, 0.0).w;
}


float GetPlanarCloudsDistortion(vec2 position, vec2 windDirection){
	float density = BilinearNoise(position - windDirection);
	float scale = 4.0;
	for (int i = 0; i < 3; i++, scale *= 3.0){
		density += BilinearNoise(scale * (position - windDirection * fsqrt(scale))) * pow(scale, -1.3);
	}
	return density;
}


float GetPlanarCloudsDensity(vec2 position, vec2 windDirection){
	position *= PC_NOISE_SCALE;

	float distortion = GetPlanarCloudsDistortion(position, windDirection);
	position += distortion * 50.0;

	const float octScale = 2.8;
	const mat2 rotateGoldenAngle = octScale * mat2(cos(goldenAngle), -sin(goldenAngle), sin(goldenAngle), cos(goldenAngle));

	float density = BicubicBlurNoise(position - windDirection);
	mat2 rot = rotateGoldenAngle;
	float weights = 1.0;

	for (float i = 1.0; i <= 6.0; i++, rot *= rotateGoldenAngle){
		float scale = fsqrt(i);
		
		vec2 noisePosition = rot * (position - windDirection * scale);
		noisePosition *= vec2(1.0 - 0.35 * scale, 1.0 + 0.05 * scale);

		float weight = pow(octScale, -0.85 * i);

		density += BicubicBlurNoise(noisePosition) * weight;
		weights += weight;
	}
	density /= weights;

	density = saturate(density + PC_COVERAGE - 1.0);
	density *= exp(-distortion);
	
	return density * density;
}

float GetPlanarCloudsLightingDensity(vec2 position, vec2 windDirection){
	position *= PC_NOISE_SCALE;

	float distortion = GetPlanarCloudsDistortion(position, windDirection);
	position += distortion * 50.0;

	const float octScale = 2.8;
	const mat2 rotateGoldenAngle = octScale * mat2(cos(goldenAngle), -sin(goldenAngle), sin(goldenAngle), cos(goldenAngle));

	float density = BicubicBlurNoise(position - windDirection);
	mat2 rot = rotateGoldenAngle;
	float weights = 1.0;

	for (float i = 1.0; i <= 3.0; i++, rot *= rotateGoldenAngle){
		float scale = fsqrt(i);
		
		vec2 noisePosition = rot * (position - windDirection * scale);
		noisePosition *= vec2(1.0 - 0.35 * scale, 1.0 + 0.05 * scale);

		float weight = pow(octScale, -0.85 * i);

		density += BilinearNoise(noisePosition) * weight;
		weights += weight;
	}
	density /= weights;

	density = saturate(density + PC_COVERAGE - 1.0);
	density *= exp(-distortion);
	
	return density * density;
}

void PlanarClouds(inout vec3 color, vec3 worldDir, vec3 camera, float dither, float cloudTransmittance){
	float planetRadius = atmosphereModel_bottom_radius * 1e3;

	vec3 rayStartPos = vec3(0.0, planetRadius + cameraPosition.y, 0.0);
	float intersection = RaySphereIntersection(rayStartPos, worldDir, planetRadius + PC_ALTITUDE).y;

	if (intersection > 0.0){
		float wind = 2.5 * (frameTimeCounter * CLOUD_SPEED + 10.0 * FTC_OFFSET);
		vec2 windDirection = vec2(-wind, wind * 0.2);

		float VdotL = dot(worldDir, worldShadowVector) * 0.5 + 0.5;

		vec3 centerPosition = worldDir * intersection;

		vec2 samplePosition = centerPosition.xz + cameraPosition.xz;

		cloudTransmittance = min(GetPlanarCloudsDensity(samplePosition, windDirection) * cloudTransmittance * 40.0, 0.9);
		#ifdef VOLUMETRIC_CLOUDS
			cloudTransmittance *= 1.0 - wetness;
		#endif

		if (cloudTransmittance > 1e-5){
			float stepLength = mix(150.0, 0.0, worldShadowVector.z);
			
			samplePosition += stepLength * dither * worldShadowVector.xy;

			float lightingDepth = 0.0;
			for (int i = 0; i < 4; i++, samplePosition += worldShadowVector.xy * stepLength, stepLength *= 1.5){
				lightingDepth += GetPlanarCloudsLightingDensity(samplePosition, windDirection) * stepLength;
			}

			float sunlightEnergy = 1.0 / (lightingDepth + 1.0);
			float powderFactor = exp2(-cloudTransmittance * (worldShadowVector.y * 5.0 + 0.5));
			sunlightEnergy *= MiePhaseFunction(powderFactor * 0.8, VdotL * 0.5 + 0.5);
			sunlightEnergy *= MiePhaseFunction(0.9, VdotL) * 0.4 + 1.0;
			vec3 cloudColor = colorShadowlight * (sunlightEnergy * 6.0);

			float skylightEnergy = exp2(-cloudTransmittance * 0.15);

			cloudColor += colorSkylight * (skylightEnergy * 0.2);

			cloudTransmittance *= exp2(-(length(centerPosition) + 2e3) * 4e-5);

			vec3 atmoPoint = camera + centerPosition * 0.001;
			vec3 transmittance;
			vec3 aerialPerspective = GetSkyRadianceToPoint(camera, atmoPoint, worldSunVector, -worldSunVector, transmittance);

			color *= (1.0 - cloudTransmittance);
			color += (cloudColor * transmittance + aerialPerspective) * cloudTransmittance;
		}
	}
}
