

float PowderEffect(float absorption, float lightingAbsorption, float VdotL){
	return mix((1.0 - absorption) * (1.0 - lightingAbsorption), 1.0, VdotL * 0.5 + 0.5);
}


float FogPhase(float VdotL){
	return MiePhaseFunction(-0.4, VdotL) * 0.3 + MiePhaseFunction(0.5, VdotL) * 0.7;
}

void MultiScatteringPhases(float VdotL, inout float phases[4]){
	float cn = 1.0;

	for (int i = 0; i < 4; i++, cn *= 0.5){
		phases[i] = FogPhase(VdotL * cn);
	}
}

float Calculate3DNoise(vec3 position){
	vec3 p = floor(position);
	vec3 f = position - p;

	f = curve(f);

	vec2 uv = 17.0 * p.z + p.xy + f.xy;
	vec2 n = textureLod(noisetex, uv * 0.015625 + 0.0078125, 0.0).zw;

	return mix(n.x, n.y, f.z);
}

#if VFOG_NOISE_TYPE == 0

float FogDensity(vec3 fogPos, vec3 wind){
	float maxHeight = max(VFOG_HEIGHT, VFOG_HEIGHT_2);
	float minHeight = min(VFOG_HEIGHT, VFOG_HEIGHT_2);

	float dh = max(fogPos.y - maxHeight, 0.0) + max(minHeight - fogPos.y, 0.0);
	dh *= 2.0 / VFOG_FALLOFF;
	float density = exp2(-dh * (1.0 - timeMidnight * 0.5));

	return density * 0.1;
}

#else

float FogDensity(vec3 fogPos, vec3 wind){
	float dh = abs(fogPos.y - max(VFOG_HEIGHT, VFOG_HEIGHT_2));
	dh *= 1.0 / VFOG_FALLOFF;
	float falloff = exp2(-dh * (1.0 - timeMidnight * 0.5));
 
	float density = 0.0;
	fogPos = fogPos * 0.02 + wind;

	for (float stepAlpha = 0.5; stepAlpha >= 0.125; stepAlpha *= 0.5) {
		density += stepAlpha * Calculate3DNoise(fogPos);
		fogPos = (fogPos + wind) * 3.5;
	}

	density *= falloff;

	density = density * density;
	return density * density * 3.0;
}

#endif


void VolumetricFog(inout vec3 color, vec3 startPos, vec3 endPos, vec3 worldDir, float globalCloudShadow, float fogTimeFactor, out float transmittance){
	#if VFOG_NOISE_TYPE == 0
		fogTimeFactor *= timeMidnight * 2.0 + 1.0;
	#endif

	#ifdef TAA
		float noise = BlueNoiseTemproal().y;
	#else
		float noise = bayer64(gl_FragCoord.xy);
	#endif

	float VdotL = dot(worldDir, worldShadowVector);

	#ifdef VFOG_LQ
		const float steps = 3.0;
	#else
		const float steps = VFOG_QUALITY;
	#endif
	const float rSteps = 1.0 / steps;

	vec3 start = startPos + gbufferModelViewInverse[3].xyz;
	vec3 end = endPos + gbufferModelViewInverse[3].xyz;

	vec3 rayVector = end - start;
	float rayLength = length(rayVector) * rSteps * 0.23979;

	vec3 shadowStart = ShadowScreenPos_From_WorldPos(start);
	vec3 shadowEnd = ShadowScreenPos_From_WorldPos(end);

	vec3 shadowRayVector = shadowEnd - shadowStart;

	start += cameraPosition;

	#ifdef DISTANT_HORIZONS
		float baseDensity = VFOG_DENSITY_BASE * (timeMidnight * 0.25 + 0.25) / clamp(float(dhRenderDistance), 512.0, 2048.0);
	#else
		float baseDensity = VFOG_DENSITY_BASE * (timeMidnight * 0.1 + 0.05) / max(far, 100.0);
	#endif
	#ifndef INDOOR_FOG
		baseDensity *= eyeBrightnessSmoothCurved;
	#endif

	#ifdef VFOG_VOLUMETRIC_LIGHTING
		float phases[4];
		MultiScatteringPhases(VdotL, phases);
	#else
		float phases = MiePhaseFunction(0.5, VdotL) * 0.7 + 0.05;
	#endif

	#if VFOG_NOISE_TYPE > 0
		float windTimer = (frameTimeCounter * CLOUD_SPEED + 10.0 * FTC_OFFSET) * 0.0025;
		vec3 wind = vec3(-1.0, -0.05, 0.6) * windTimer;
	#endif


	transmittance = 1.0;
	float fogDensity = 0.0;
	float rayDensity = 0.0;

	#ifdef MC_GL_VENDOR_NVIDIA
		#ifdef VFOG_STAINED
			vec3 translucentColor = vec3(0.0);
		#endif
	#endif

	for (float i = 0.0; i < steps; i++){
		float exponential = pow(11.0, (i + noise) * rSteps);
		float stepLength = exponential * 0.1 - 0.1;
		float stepDensity = exponential * rayLength * 1.442695;

		vec3 fogPos = start + stepLength * rayVector;
		vec3 shadowPos = shadowStart + stepLength * shadowRayVector;

		#if VFOG_NOISE_TYPE == 0
			float density = FogDensity(fogPos, vec3(0.0));
		#else
			float density = FogDensity(fogPos, wind);
		#endif
		density = (density * VFOG_DENSITY + baseDensity) * fogTimeFactor;
		float absorption = exp2(-density * stepDensity);

		#ifdef VFOG_VOLUMETRIC_LIGHTING
			float lightingDensity = 0.0;

			float lightingStepLength = VFOG_SUNLIGHT_STEPLENGTH;
			
			for (int i = 0; i < VFOG_SUNLIGHT_STEPS; i++, fogPos += worldShadowVector * lightingStepLength, lightingStepLength *= 1.5){
				#if VFOG_NOISE_TYPE == 0
					lightingDensity += FogDensity(fogPos, vec3(0.0)) * lightingStepLength;
				#else
					lightingDensity += FogDensity(fogPos, wind) * lightingStepLength;
				#endif
			}

			lightingDensity = (lightingDensity * VFOG_SUNLIGHT_ABSORPTION * VFOG_DENSITY + baseDensity) * fogTimeFactor;
			float lightingAbsorption = exp2(-lightingDensity * stepDensity);

			float stepRayDensity = 0.0;
			float order = 1.0;
			for (int j = 0; j < 4; j++, order *= 0.5){
				stepRayDensity += exp(-lightingDensity * order) * phases[j] * order;
			}
			stepRayDensity *= PowderEffect(absorption, lightingAbsorption, VdotL);
		#endif


		shadowPos.xy = DistortShadowScreenPos(shadowPos.xy);

		float shadow = 1.0;

		#ifdef VFOG_STAINED
			vec3 shadowColorSample = vec3(1.0);
		#endif

		if (saturate(shadowPos.xy) == shadowPos.xy && shadowPos.z < 1.0){
			#ifdef MC_GL_VENDOR_NVIDIA
				float solidDepth = textureLod(shadowtex1, shadowPos.xy, 0).x;
				shadow *= step(shadowPos.z, solidDepth);

				#ifdef VFOG_STAINED
					float transparentDepth = textureLod(shadowtex0, shadowPos.xy, 0).x;
					shadowColorSample = GammaToLinear(textureLod(shadowcolor0, shadowPos.xy, 0).rgb);
					float transparentShadow = step(transparentDepth, shadowPos.z) * shadow;

					shadowColorSample *= transparentShadow;
					shadow -= transparentShadow;
				#endif
			#else
				float solidDepth = textureLod(shadowtex0, shadowPos.xy, 0).x;
				shadow *= step(shadowPos.z, solidDepth);
			#endif
		}


		#ifdef VOLUMETRIC_CLOUDS
			#ifdef CLOUD_SHADOW
				#ifdef VFOG_CLOUD_SHADOW
					float cloudShadow = CloudShadowFromTex(fogPos - cameraPosition);
				#endif
			#endif
		#endif

		
		float integral = transmittance - absorption * transmittance;
		#ifdef VFOG_VOLUMETRIC_LIGHTING
			stepRayDensity *= integral;
		#else
			float stepRayDensity = integral * phases;
		#endif

		#if defined VOLUMETRIC_CLOUDS && defined CLOUD_SHADOW && defined VFOG_CLOUD_SHADOW
			stepRayDensity *= mix(cloudShadow, 1.0, wetness * 0.1 + 0.03);
			fogDensity += integral * mix(cloudShadow, 1.0, wetness * 0.3 + 0.7);
		#else
			fogDensity += integral;
		#endif

		rayDensity += stepRayDensity * shadow;

		#ifdef MC_GL_VENDOR_NVIDIA
			#ifdef VFOG_STAINED
				translucentColor += stepRayDensity * shadowColorSample;
			#endif
		#endif
		
		
		transmittance *= absorption;
	}


	vec3 skylight = colorSkylight;
	vec3 skySunLight = colorShadowlight * 0.03;
	skylight += skySunLight * (1.0 + (1.0 - globalCloudShadow) * (1.0 - wetness));

	skylight = mix(skylight, skySunLight, wetness * 0.7);

	vec3 fogColor = skylight         * fogDensity;
	vec3 rayColor = colorShadowlight * rayDensity;

	#ifdef MC_GL_VENDOR_NVIDIA
		#ifdef VFOG_STAINED
			rayColor += colorShadowlight * translucentColor;
		#endif
	#endif

	fogColor *= 0.32 * VFOG_FOG_DENSITY      * SKYLIGHT_INTENSITY;
	rayColor *= 0.7  * VFOG_SUNLIGHT_DENSITY * SUNLIGHT_INTENSITY;
	#if !defined VOLUMETRIC_CLOUDS || !defined CLOUD_SHADOW || !defined VFOG_CLOUD_SHADOW
		rayColor *= mix(globalCloudShadow, 1.0, wetness * 0.1);
	#endif

	#ifndef INDOOR_FOG
		fogColor *= eyeBrightnessSmoothCurved;
		#ifdef CAVE_MODE
			rayColor *= eyeBrightnessSmoothCurved;
		#endif
		transmittance = mix(1.0, transmittance, eyeBrightnessSmoothCurved);
	#endif

	color = transmittance * color;
	color += fogColor + rayColor;
}




vec3 simpleScattering(vec3 camera, vec3 worldDir, float dist, float shadowDist, vec3 lightVector){
	float ds = RaySphereIntersection(camera, lightVector, atmosphereModel_top_radius).y * 0.25;
	vec3 opticalLength = ds * lightVector;
	camera += 0.5 * opticalLength;

	vec3 opticalDepth = vec3(0.0);
	for (int i = 0; i < 4; i++, camera += opticalLength){
		float altitude = length(camera) - atmosphereModel_bottom_radius;
		opticalDepth += vec3(GetProfileDensityRayleighMie(atmosphereModel_densityProfile_rayleigh, altitude),
							 GetProfileDensityRayleighMie(atmosphereModel_densityProfile_mie, altitude),
							 GetProfileDensityAbsorption (atmosphereModel_densityProfile_absorption_width, atmosphereModel_densityProfile_absorption, altitude));
	}
	opticalDepth = opticalDepth * ds + dist;

	vec3 attenuation = exp2(-opticalDepth.x * atmosphereModel_rayleigh_scattering
		 				    -opticalDepth.y * atmosphereModel_mie_scattering
		 			   	    -opticalDepth.z * atmosphereModel_absorption_extinction);

	float nu = dot(worldDir, lightVector);
	vec3 scattering = RayleighPhaseFunction(nu) * atmosphereModel_rayleigh_scattering * (dist * 0.25 + shadowDist * 0.75)
					+ MiePhaseFunction(0.6, nu) * atmosphereModel_mie_scattering * shadowDist;

	return scattering * atmosphereModel_solar_irradiance * attenuation * LMS;
}

void LandAtmosphericScattering(inout vec3 color, in float dist, vec3 startPos, vec3 endPos, vec3 worldDir, bool isSky){
	float strength = max(LANDSCATTERING_STRENGTH - float(isSky), 0.0);
	#ifdef VFOG
		strength *= timeNoon;
	#endif
	#ifndef INDOOR_FOG
		strength *= eyeBrightnessSmoothCurved;
	#endif

	if(strength > 0.001 && isEyeInWater == 0){

		#ifdef ATMO_HORIZON
			vec3 camera = vec3(0.0, max(cameraPosition.y, ATMO_MIN_ALTITUDE) * 0.001 + atmosphereModel_bottom_radius, 0.0);
		#else
			vec3 camera = vec3(0.0, max(cameraPosition.y, 63.0) * 0.001 + atmosphereModel_bottom_radius, 0.0);
		#endif

		float shadowDist = dist;

		#ifdef LANDSCATTERING_SHADOW
			float rSteps = 1.0 / LANDSCATTERING_SHADOW_QUALITY;

			vec3 shadowStart = ShadowScreenPos_From_WorldPos(startPos + gbufferModelViewInverse[3].xyz);
			vec3 shadowEnd = ShadowScreenPos_From_WorldPos(endPos + gbufferModelViewInverse[3].xyz);

			#ifdef TAA
				float noise = BayerTemproal();
			#else
				float noise = bayer64(gl_FragCoord.xy);
			#endif

			vec3 shadowIncrement = (shadowEnd - shadowStart) * rSteps;
			vec3 shadowRayPosition = shadowIncrement * noise + shadowStart;

			float shadowLength = 0.0;

			for (int i = 0; i < LANDSCATTERING_SHADOW_QUALITY; i++, shadowRayPosition += shadowIncrement){
				vec3 shadowPos = shadowRayPosition;
				shadowPos.xy = DistortShadowScreenPos(shadowPos.xy);

				if (saturate(shadowPos.xy) == shadowPos.xy && shadowPos.z < 1.0){
					float solidDepth = textureLod(shadowtex0, shadowPos.xy, 0).x;
					shadowLength += step(solidDepth, shadowPos.z);
				}
			}

			shadowDist = max(shadowDist - shadowLength * length((endPos - startPos) * rSteps), 0.0);
		#endif

		dist *= LANDSCATTERING_DISTANCE;
		shadowDist *= LANDSCATTERING_DISTANCE;

		color += simpleScattering(camera, worldDir, dist, shadowDist, worldSunVector)
			   * (1.0 - wetness)
			   * strength;
	}
}
