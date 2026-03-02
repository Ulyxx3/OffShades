

vec3 BlockLighting(float lightmap, vec3 ao, MaterialMask mask){
	ao = mix(ao, vec3(1.0), saturate(lightmap * 5.0 - 4.2));

	float lightSourceMask = saturate(mask.glowstone
								   + mask.torch
								   + mask.fire
								   + mask.lava
								   + mask.entitiesLitHigh
								   + mask.entitiesLitMedium
								   + mask.entitiesLitLow
								   + mask.particlelit
								   + mask.soulFire
								   + mask.amethyst);

	lightmap = min(lightmap, 1.0 - 0.13 * lightSourceMask);

	lightmap = CurveBlockLightTorch(lightmap);

	#ifdef DIMENSION_MAIN
		return colorTorchlight * ao * (lightmap * TORCHLIGHT_BRIGHTNESS * 0.015);
	#else
		return colorTorchlight * ao * (lightmap * TORCHLIGHT_BRIGHTNESS * 0.15);
	#endif
}

vec3 TextureLighting(vec3 albedo, float lightmap, float emissiveness, MaterialMask mask){
	emissiveness *= EMISSIVENESS_BRIGHTNESS;

	#if TEXTURE_EMISSIVENESS_MODE == 1
		#ifdef DIMENSION_MAIN
			return vec3(emissiveness * TORCHLIGHT_BRIGHTNESS * 0.01);
		#else
			return vec3(emissiveness * TORCHLIGHT_BRIGHTNESS * 0.1);
		#endif
	#else
		float blockLightingMask  = 	mask.glowstone 			* 0.016;
			  blockLightingMask += 	mask.torch 				* 0.03;
			  blockLightingMask += 	mask.fire 				* 0.004;
			  blockLightingMask += 	mask.lava 				* 0.012;
			  blockLightingMask += 	mask.redstoneTorch 		* 0.001;
			  blockLightingMask += 	mask.oxidizedBulb 		* 0.0002;

		vec3 blockLighting = vec3(1.0);
		if (blockLightingMask > 0.0) blockLighting = colorTorchlight;

			  blockLightingMask += 	mask.soulFire 			* 0.001;
			  blockLightingMask += 	mask.amethyst 			* 0.0003;
			  blockLightingMask += 	mask.endPortal 			* 4.0;
			  blockLightingMask += 	mask.entitiesLitHigh 	* 0.02;
			  blockLightingMask += 	mask.entitiesLitMedium 	* 0.005;
			  blockLightingMask += 	mask.entitiesLitLow 	* 0.002;
			  blockLightingMask += 	mask.particlelit 		* 0.01;
			//blockLightingMask += 	mask.eyes 				* 0.001;
			  blockLightingMask += 	mask.redstone 			* 0.2 * emissiveness;

		blockLightingMask *= length(albedo);

		#if TEXTURE_EMISSIVENESS_MODE == 2
			#ifdef DIMENSION_MAIN
				return blockLighting * (max(blockLightingMask * TEXTURE_BRIGHTNESS, emissiveness * 0.005) * TORCHLIGHT_BRIGHTNESS);
			#else
				return blockLighting * (max(blockLightingMask * TEXTURE_BRIGHTNESS, emissiveness * 0.005) * TORCHLIGHT_BRIGHTNESS * 10.0);
			#endif
		#else
			#ifdef DIMENSION_MAIN
				return blockLighting * (blockLightingMask * TEXTURE_BRIGHTNESS * TORCHLIGHT_BRIGHTNESS);
			#else
				return blockLighting * (blockLightingMask * TEXTURE_BRIGHTNESS * TORCHLIGHT_BRIGHTNESS * 10.0);
			#endif
		#endif
	#endif
}


float spotShape(float r){
	float shape = curve(saturate(r * 2.0 - (2.0 - FLASHLIGHT_FOV)));
	shape += curve(saturate(r * 1.25 - (1.0 - FLASHLIGHT_FOV))) * 0.01;

	const float ringSize = 8.0 / FLASHLIGHT_FOV;
	shape *= 1.0 - curve(saturate(1.0 - abs(r * ringSize - ringSize + 1.0))) * 0.25;

	return shape;
}


float TorchScreenSpaceShadow(vec3 viewPos, vec3 viewDir, vec3 normal, vec3 shadowDir){
	shadowDir.z = max(shadowDir.z, 1e-5);

	float rayLength = -0.04 * viewPos.z / shadowDir.z;
	vec3 viewRayDir = shadowDir * rayLength;

	vec3 start = viewPos;

	float pixelScale = max(pixelSize.x, pixelSize.y);
	float NdotL = saturate(dot(shadowDir, normal));

	float fov = atan(1.0 / gbufferProjection[1][1]) * 360.0 * rPI;
	start += viewRayDir * (pixelScale * max(0.04 / max(dot(normal, -viewDir), 0.1), 1e3));
	start += normal * (8e-3 * fov * -viewPos.z * pixelScale / max(NdotL, 0.01));

	vec3 end = start + viewRayDir;

	start = vec3(vec2(gbufferProjection[0][0], gbufferProjection[1][1]) * start.xy, -start.z);
	end   = vec3(vec2(gbufferProjection[0][0], gbufferProjection[1][1]) * end.xy,   -end.z);

	vec3 screenRayDir = (end - start);
	screenRayDir.xy *= 0.5;

	start.xy += gbufferProjection[3].xy;
	start.xy *= 0.5;

	#ifdef TAA
		float noise = BlueNoiseTemproal().x;
		vec2 offsetCoord = 0.5 + taaJitter * 0.5;
	#else
		float noise = BlueNoise().x;
		vec2 offsetCoord = vec2(0.5);
	#endif

	float minDist = LinearDepth_From_ScreenDepth(0.7);

	float shadow = 1.0;
	float stepLength = 1.0;

	for (int i = 0; i < 8; i++, start += screenRayDir * stepLength, stepLength += 0.3){
		vec3 samplePos = start + screenRayDir * noise * stepLength;

		if (samplePos.z < minDist) break;

		samplePos.xy = samplePos.xy / samplePos.z + offsetCoord;
		
		if (saturate(samplePos.xy) != samplePos.xy) break;

		float sampleDepth = textureLod(depthtex1, samplePos.xy, 0.0).x;

		if (sampleDepth < 0.7) break;

		#ifdef DISTANT_HORIZONS
				float sampleDist = 0.0;

			if (sampleDepth == 1.0){
				sampleDepth = textureLod(dhDepthTex1, samplePos.xy, 0.0).x;
				sampleDist = LinearDepth_From_ScreenDepth_DH(sampleDepth);
			}else{
				sampleDist = LinearDepth_From_ScreenDepth(sampleDepth);
			}
		#else
			float sampleDist = LinearDepth_From_ScreenDepth(textureLod(depthtex1, samplePos.xy, 0.0).x);
		#endif

		if (samplePos.z - sampleDist > 0.0){
			shadow = 0.0;
			break;
		}
	}

	return shadow * 0.85 + 0.15;
}

vec3 HeldLighting(vec3 viewPos, vec3 viewDir, vec3 normal, float roughness, vec3 ao, bool isHand){
	float heldLightFalloff = 0.0;

	#if HELDLIGHT_MODE > 0
		
		if (isHand){
			heldLightFalloff = 0.01 * max(heldBlockLightValue, heldBlockLightValue2);
		}else{
			#ifdef FLASHLIGHT_CAMERA_SMOOTH
				float angleRx = eyeRxSmooth * -FLASHLIGHT_CAMERA_SMOOTH_TIME;
				mat3 Rx = mat3(1.0,  0.0,          0.0,
							   0.0,  cos(angleRx), sin(angleRx),
							   0.0, -sin(angleRx), cos(angleRx));

				float angleRy = eyeRySmooth * -FLASHLIGHT_CAMERA_SMOOTH_TIME;
				mat3 Ry = mat3(cos(angleRy), 0.0, -sin(angleRy),
							   0.0,          1.0,  0.0,
							   sin(angleRy), 0.0,  cos(angleRy));

				vec3 aimDir = Ry * Rx * vec3(0.0, 0.0, -1.0);
			#else
				vec3 aimDir = vec3(0.0, 0.0, -1.0);
			#endif

			if (heldBlockLightValue > 0.0){
				vec3 spotPosR = viewPos - vec3(FLASHLIGHT_POS_R_X, FLASHLIGHT_POS_R_Y, 0.0);
				float spotDistR = length(spotPosR);
				vec3 shadowDirR = spotPosR / spotDistR;

				float spotR = pow(max(spotDistR, 0.6), -FLASHLIGHT_HELDLIGHT_FALLOFF);
				spotR *= spotShape(dot(shadowDirR, aimDir));

				#ifdef HELDLIGHT_SHADOW
					spotR *= TorchScreenSpaceShadow(viewPos, viewDir, normal, -shadowDirR);
				#endif
				spotR *= Fd_Burley(normal, -viewDir, -shadowDirR, roughness) * 1.7 + 0.05;
				
				heldLightFalloff += heldBlockLightValue * spotR;
			}

			if (heldBlockLightValue2 > 0.0){
				vec3 spotPosL = viewPos - vec3(FLASHLIGHT_POS_L_X, FLASHLIGHT_POS_L_Y, 0.0);
				float spotDistL = length(spotPosL);
				vec3 shadowDirL = spotPosL / spotDistL;

				float spotL = pow(max(spotDistL, 0.6), -FLASHLIGHT_HELDLIGHT_FALLOFF);
				spotL *= spotShape(dot(shadowDirL, aimDir));

				#ifdef HELDLIGHT_SHADOW
					spotL *= TorchScreenSpaceShadow(viewPos, viewDir, normal, -shadowDirL);
				#endif
				spotL *= Fd_Burley(normal, -viewDir, -shadowDirL, roughness) * 1.7 + 0.05;

				heldLightFalloff += heldBlockLightValue2 * spotL;
			}
		}
		
		#ifdef DIMENSION_MAIN
			return vec3(FLASHLIGHT_COLOR_R, FLASHLIGHT_COLOR_G, FLASHLIGHT_COLOR_B) * (ao * 0.5 + 0.5) * (heldLightFalloff * (HELDLIGHT_BRIGHTNESS * 0.02));
		#else
			return vec3(FLASHLIGHT_COLOR_R, FLASHLIGHT_COLOR_G, FLASHLIGHT_COLOR_B) * (ao * 0.5 + 0.5) * (heldLightFalloff * (HELDLIGHT_BRIGHTNESS * 0.2));
		#endif

	#else

		if (isHand){
			heldLightFalloff = 0.2 * max(heldBlockLightValue, heldBlockLightValue2);
		}else{
			#ifdef HELDLIGHT_SHADOW

				if (heldBlockLightValue > 0.0){
					vec3 torchPosR = viewPos - vec3(FLASHLIGHT_POS_R_X, FLASHLIGHT_POS_R_Y, 0.0);
					float torchDistR = length(torchPosR);
					torchDistR += 4.0 / (torchDistR + 2.0);

					float torchR = pow(torchDistR, -HELDLIGHT_FALLOFF);

					vec3 shadowDirR = -normalize(viewPos - vec3(FLASHLIGHT_POS_R_X, FLASHLIGHT_POS_R_Y, 0.0));
					torchR *= TorchScreenSpaceShadow(viewPos, viewDir, normal, shadowDirR);
					torchR *= Fd_Burley(normal, -viewDir, shadowDirR, roughness) * 1.7 + 0.05;

					heldLightFalloff += heldBlockLightValue * torchR;
				}

				if (heldBlockLightValue2 > 0.0){
					vec3 torchPosL = viewPos - vec3(FLASHLIGHT_POS_L_X, FLASHLIGHT_POS_L_Y, 0.0);
					float torchDistL = length(torchPosL);
					torchDistL += 4.0 / (torchDistL + 2.0);

					float torchL = pow(torchDistL, -HELDLIGHT_FALLOFF);

					vec3 shadowDirL = -normalize(viewPos - vec3(FLASHLIGHT_POS_L_X, FLASHLIGHT_POS_L_Y, 0.0));
					torchL *= TorchScreenSpaceShadow(viewPos, viewDir, normal, shadowDirL);
					torchL *= Fd_Burley(normal, -viewDir, shadowDirL, roughness) * 1.7 + 0.05;

					heldLightFalloff += heldBlockLightValue2 * torchL;
				}

			#else

				float torchDist = length(viewPos);
				torchDist += 4.0 / (torchDist + 2.0);
				heldLightFalloff = pow(torchDist, -HELDLIGHT_FALLOFF);
				heldLightFalloff *= Fd_Burley(normal, -viewDir, -viewDir, roughness) + 0.3;

				heldLightFalloff *= heldBlockLightValue + heldBlockLightValue2;

			#endif
		}

		#ifdef DIMENSION_MAIN
			return colorTorchlight * (ao * 0.5 + 0.5) * (heldLightFalloff * (TORCHLIGHT_BRIGHTNESS * HELDLIGHT_BRIGHTNESS * 0.0015));
		#else
			return colorTorchlight * (ao * 0.5 + 0.5) * (heldLightFalloff * (TORCHLIGHT_BRIGHTNESS * HELDLIGHT_BRIGHTNESS * 0.015));
		#endif

	#endif

}


void TorchSpecularHighlight(inout vec3 color, vec3 viewPos, vec3 viewDir, float dist, vec3 albedo, vec3 normal, Material material){
	material.roughness = max(material.roughness, 0.002);
	#if HELDLIGHT_MODE > 0
		#ifdef FLASHLIGHT_CAMERA_SMOOTH
			float angleRx = eyeRxSmooth * -FLASHLIGHT_CAMERA_SMOOTH_TIME;
			mat3 Rx = mat3(1.0,  0.0,          0.0,
							0.0,  cos(angleRx), sin(angleRx),
							0.0, -sin(angleRx), cos(angleRx));

			float angleRy = eyeRySmooth * -FLASHLIGHT_CAMERA_SMOOTH_TIME;
			mat3 Ry = mat3(cos(angleRy), 0.0, -sin(angleRy),
							0.0,          1.0,  0.0,
							sin(angleRy), 0.0,  cos(angleRy));

			vec3 aimDir = Ry * Rx * vec3(0.0, 0.0, -1.0);
		#else
			vec3 aimDir = vec3(0.0, 0.0, -1.0);
		#endif

		float heldHighlight = 0.0;
		
		if (heldBlockLightValue > 0.0){
			vec3 spotPosR = viewPos - vec3(FLASHLIGHT_POS_R_X, FLASHLIGHT_POS_R_Y, 0.0);
			float spotDistR = length(spotPosR);
			vec3 shadowDirR = spotPosR / spotDistR;

			float spotR = pow(max(spotDistR, 0.6), -FLASHLIGHT_HELDLIGHT_FALLOFF);
			spotR *= spotShape(dot(shadowDirR, aimDir));

			spotR *= SpecularGGX(normal, -viewDir, -shadowDirR, material.roughness, material.f0);
			
			heldHighlight += heldBlockLightValue * spotR;
		}

		if (heldBlockLightValue2 > 0.0){
			vec3 spotPosL = viewPos - vec3(FLASHLIGHT_POS_L_X, FLASHLIGHT_POS_L_Y, 0.0);
			float spotDistL = length(spotPosL);
			vec3 shadowDirL = spotPosL / spotDistL;

			float spotL = pow(max(spotDistL, 0.6), -FLASHLIGHT_HELDLIGHT_FALLOFF);
			spotL *= spotShape(dot(shadowDirL, aimDir));

			spotL *= SpecularGGX(normal, -viewDir, -shadowDirL, material.roughness, material.f0);

			heldHighlight += heldBlockLightValue2 * spotL;
		}

		if (heldHighlight > 0.001){
			#ifdef DIMENSION_MAIN
				color += vec3(FLASHLIGHT_COLOR_R, FLASHLIGHT_COLOR_G, FLASHLIGHT_COLOR_B) * albedo * (heldHighlight * (HELDLIGHT_BRIGHTNESS * 0.0025));
			#else
				color += vec3(FLASHLIGHT_COLOR_R, FLASHLIGHT_COLOR_G, FLASHLIGHT_COLOR_B) * albedo * (heldHighlight * (HELDLIGHT_BRIGHTNESS * 0.025));
			#endif
		}
	#else
		float heldHighlight = SpecularGGX(normal, -viewDir, -viewDir, material.roughness, material.f0);

		if (heldHighlight > 0.001){
			dist += 4.0 / (dist + 2.0);
			heldHighlight *= pow(dist, -HELDLIGHT_FALLOFF);

			heldHighlight *= (heldBlockLightValue + heldBlockLightValue2);

			#ifdef DIMENSION_MAIN
				color += colorTorchlight * albedo * (heldHighlight * (TORCHLIGHT_BRIGHTNESS * HELDLIGHT_BRIGHTNESS * 0.0002));
			#else
				color += colorTorchlight * albedo * (heldHighlight * (TORCHLIGHT_BRIGHTNESS * HELDLIGHT_BRIGHTNESS * 0.002));
			#endif
		}
	#endif
}