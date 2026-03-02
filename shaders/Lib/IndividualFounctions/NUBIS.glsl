

float HenyeyGreenstein(float inCosAngle, float inG){
	float num = 1.0 - inG * inG;
	float denom = 1.0 + inG * inG - 2.0 * inG * inCosAngle;
	float rsqrt_denom = inversesqrt(denom);
	return num * rsqrt_denom * rsqrt_denom * rsqrt_denom * (0.25 / PI);
}

float curveTop(float x){
	x = x - 1.0;
	return 1.0 - x * x;
}

vec2 SampleDensity(vec4 cloudPos, vec3 windDirection, bool sampleDetail){
	//Base Noise
		vec4 baseNoise = textureLod(colortex4, cloudPos.xyz * CLOUD_BASE_NOISE_SCALE + windDirection * 10.0, 0.0);

		float baseDensity = baseNoise.y * 0.4 + baseNoise.z * 0.4 + baseNoise.w * 0.2;
		baseDensity = remapSaturate(baseNoise.x, baseDensity - 1.0, 1.0);

		float shapeCurve = curveTop(saturate(1.0 - cloudPos.w)) * 0.5;
		shapeCurve += curve(saturate(1.15 - cloudPos.w * 1.43)) * 0.5;
		baseDensity *= shapeCurve;
		baseDensity *= fsqrt(saturate(cloudPos.w * 2.5)) * 0.2 + 0.8;
		baseDensity *= mix(1.0, curveTop(saturate(cloudPos.w * 3.0)), wetness);

	//Coverage
		float coverageNoise = textureLod(colortex4, cloudPos.xyz * vec3(8.5e-5, -1e-5, 8.5e-5) + windDirection + CLOUD_COVERAGE_NOISE_OFFSET, 0.0).x;

		float coverage = mix(CLOUD_CLEAR_COVERY, CLOUD_RAIN_COVERY, wetness);
		coverage = remapSaturate(1.0 - coverageNoise, coverage * 0.2, coverage);

		baseDensity = remapSaturate(baseDensity, coverage, 1.0); 

	//Density Control
		baseDensity *= curve(saturate(cloudPos.w * 1.8 - 0.8)) * 2.0 + 1.0;
		baseDensity *= curveTop(saturate(cloudPos.w * 1.8));

		baseDensity = saturate(baseDensity);


	float detailedDensity = 0.0;

	if(baseDensity > 1e-6 && sampleDetail){
		//Curl Noise
			float curlNoise = textureLod(noisetex, cloudPos.xy * 0.0001, 0.0).w;
			cloudPos.xy += curlNoise * (100.0 - cloudPos.w * 100.0);

		//Detailed Noise
			vec3 detailedNoise = textureLod(colortex6, cloudPos.xyz * CLOUD_DETAILED_NOISE_SCALE + windDirection * 140.0, 0.0).xyz;
			detailedDensity = 1.0 - detailedNoise.x * 0.625 - detailedNoise.y * 0.25 - detailedNoise.z * 0.125;
			detailedDensity *= (0.21 - wetness * 0.11) * CLOUD_DETAILED_NOISE_STRENGTH;

			detailedDensity = remapSaturate(baseDensity, detailedDensity, 1.0);
	}else{
		detailedDensity = baseDensity;
	}

	return vec2(baseDensity, detailedDensity);
}


vec4 SetCloudPos(vec3 marchingPos, vec2 cloudAltitude, float planetRadius, float cloudScale, vec3 windDirection){
	vec4 cloudPos = vec4(marchingPos, 0.0);
	cloudPos.y = length(cloudPos.xyz + vec3(0.0, planetRadius, 0.0)) - planetRadius;
	cloudPos.w = remapSaturate(cloudPos.y, cloudAltitude.x, cloudAltitude.y);
	cloudPos.xyz = cloudPos.xyz * cloudScale + vec3(30.0 * cloudPos.w, 0.0, -12.0 * cloudPos.w);
	return cloudPos;
}


vec3 CloudLighting(vec3 marchingPos, vec2 cloudAltitude, float planetRadius, float cloudScale, vec2 lightingStrength, vec2 cloudDensity, vec4 cloudPos, vec3 windDirection, float noise, float VdotL){
	float stepLength = 28.0;
	float lightingDensity = 0.0;

	for (int i = 0; i < 5; i++, stepLength *= 1.5){
		vec4 checkPos = SetCloudPos(marchingPos + worldShadowVector * stepLength * noise, cloudAltitude, planetRadius, cloudScale, windDirection);

		lightingDensity += SampleDensity(checkPos, windDirection, i < 3).y * stepLength;

		marchingPos += worldShadowVector * stepLength;
	}

	//Direct Scattering
		float hg = HenyeyGreenstein(VdotL, 0.7);

		float directScattering = exp2(-lightingDensity * (cloudPos.w * 0.15 + 0.05)) * (hg + 0.02) * (1.0 - wetness * 0.8);
		directScattering += (1.0 / (lightingDensity * 0.2 + 1.0)) * (HenyeyGreenstein(VdotL, 0.2) + 0.1);

		directScattering *= hg * 2.0 + 1.0;
		directScattering *= mix(CLOUD_BOTTOM_BRIGHTNESS, 0.005 + pow(cloudDensity.y, CLOUD_OUTSCATTER_FACTOR), curve(saturate(cloudPos.w * 3.333 - 0.333)));
		directScattering *= pow(max(cloudPos.w, 0.05), 0.75);

		vec3 cloudColor = colorShadowlight * (directScattering * lightingStrength.x * 36.0);

	//Ambient Scattering
		float ambientScattering = 1.0 - cloudDensity.x;
		ambientScattering *= fsqrt(cloudPos.w);

		cloudColor += colorSkylight * (ambientScattering * lightingStrength.y * 0.35);

	return cloudColor;
}



void NubisCumulus(inout vec3 color, vec3 worldDir, vec2 cloudAltitude, vec3 windDirection, vec3 camera, vec2 noise, out float cloudTransmittance){
	const float planetRadius = atmosphereModel_bottom_radius * 1e3;

	//Marching Setup
		vec3 rayStartPos = vec3(0.0, planetRadius + cameraPosition.y, 0.0);
		vec2 iBottom = RaySphereIntersection(rayStartPos, worldDir, planetRadius + cloudAltitude.x);
		vec2 iTop = RaySphereIntersection(rayStartPos, worldDir, planetRadius + cloudAltitude.y);

		vec2 iMarching = cameraPosition.y > cloudAltitude.y ? vec2(iTop.x, iBottom.x) : vec2(iBottom.y, iTop.y);
		vec3 marchingStart = iMarching.x * worldDir;
		vec3 marchingEnd = iMarching.y * worldDir;

		float inCloud = (1.0 - saturate((cameraPosition.y - cloudAltitude.y) * 0.005)) *
						(1.0 - saturate((cloudAltitude.x - cameraPosition.y) * 0.005));

		float iInner = iBottom.y >= 0.0 && cameraPosition.y > cloudAltitude.x ? iBottom.x : iTop.y;
		iInner = min(iInner, 5000.0);

		marchingStart = marchingStart * (1.0 - inCloud) + cameraPosition;
		marchingEnd = mix(marchingEnd, iInner * worldDir, inCloud) + cameraPosition;

		float marchingSteps = 20.0 - saturate(fsqrt(abs(worldDir.y)) * 1.4 - 0.4) * 8.0;
		marchingSteps = floor(marchingSteps * CLOUD_QUALITY);

		float marchingStepSize = 1.0 / marchingSteps;

		vec3 marchingIncrement = (marchingEnd - marchingStart) * marchingStepSize;
		vec3 marchingPos = marchingStart + marchingIncrement * noise.x;
		float marchingLength = length(marchingIncrement);


	//Cloud Properties
		vec2 lightingStrength = vec2(mix(CLOUD_CLEAR_SUNLIGHTING, CLOUD_RAIN_SUNLIGHTING, wetness),
									 mix(CLOUD_CLEAR_SKYLIGHTING, CLOUD_RAIN_SKYLIGHTING, wetness));
		float cloudScale = 			 mix(CLOUD_CLEAR_SCALE,       CLOUD_RAIN_SCALE,       wetness);
		float cloudDensityMul = 	 mix(CLOUD_CLEAR_DENSITY,     CLOUD_RAIN_DENSITY,     wetness);
		cloudDensityMul *= (cloudAltitude.y - cloudAltitude.x) * marchingStepSize;

		float VdotL = dot(worldDir, worldShadowVector);


	//Marching
		vec3 cloudAccum = vec3(0.0, 0.0, 0.0);
		cloudTransmittance = 1.0;
		vec3 rayHitPos = vec3(0.0);
		float sumTransmit = 0.0;

		for (int i = 0; i < int(marchingSteps); i++, marchingPos += marchingIncrement){	
			vec4 cloudPos = SetCloudPos(marchingPos, cloudAltitude, planetRadius, cloudScale, windDirection);

			vec2 cloudDensity = SampleDensity(cloudPos, windDirection, true);

			if (cloudDensity.y < 1e-6) continue;

			vec3 cloudColor = CloudLighting(marchingPos, cloudAltitude, planetRadius, cloudScale, lightingStrength, cloudDensity, cloudPos, windDirection, noise.y, VdotL);
			float absorption = exp2(-cloudDensity.y * cloudDensityMul);

			cloudAccum += cloudColor * (cloudTransmittance - absorption * cloudTransmittance);

			rayHitPos += marchingPos * cloudTransmittance;
			sumTransmit += cloudTransmittance;

			cloudTransmittance *= absorption;
			if (cloudTransmittance < 0.0001) break;
		}


	//Aerial Perspective
		#ifdef CLOUD_FADE
			rayHitPos /= sumTransmit;
			rayHitPos -= cameraPosition;

			float fade = saturate(exp2(-length(rayHitPos) * 8e-5));
			float cloudTransmittanceFaded = mix(1.0, cloudTransmittance, fade);
			cloudAccum *= fade;

			if(cloudTransmittance < 0.9999){
				vec3 atmoPoint = camera + rayHitPos * 0.001;
				vec3 transmittance;
				vec3 aerialPerspective = GetSkyRadianceToPoint(camera, atmoPoint, worldSunVector, worldMoonVector, transmittance);

				color *= cloudTransmittanceFaded;

				color += aerialPerspective * (1.0 - cloudTransmittanceFaded);
				color += cloudAccum * transmittance;
			}
		#else
			if(cloudTransmittance < 0.9999){
				rayHitPos /= sumTransmit;
				rayHitPos -= cameraPosition;

				vec3 atmoPoint = camera + rayHitPos * 0.001;
				vec3 transmittance;
				vec3 aerialPerspective = GetSkyRadianceToPoint(camera, atmoPoint, worldSunVector, worldMoonVector, transmittance);

				color *= cloudTransmittance;

				color += aerialPerspective * (1.0 - cloudTransmittance);
				color += cloudAccum * transmittance;
			}
		#endif
}


float CloudShadowTex(vec2 coord, vec2 cloudAltitude, vec3 windDirection){
	coord = coord * CLOUD_SHADOW_RANGE - (CLOUD_SHADOW_RANGE * 0.5);
	vec4 checkPos = vec4(coord.x + cameraPosition.x, 0.0, coord.y + cameraPosition.z, 0.0);
	float thickness = cloudAltitude.y - cloudAltitude.x;

	checkPos += vec4(worldShadowVector * ((cloudAltitude.x + thickness * 0.25) / worldShadowVector.y) , 0.25);
	float cloudDensity = SampleDensity(checkPos, windDirection, false).y;
	
	checkPos += vec4(worldShadowVector * ((thickness * 0.25) / worldShadowVector.y) , 0.25);
	cloudDensity = max(cloudDensity, SampleDensity(checkPos, windDirection, false).y);

	return exp2(-cloudDensity * 20.0);
}