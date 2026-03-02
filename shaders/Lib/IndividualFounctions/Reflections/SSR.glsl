


bool ScreenSpaceTracer(vec3 viewRayOri, vec3 viewRayDir, float NdotV, float noise, float minLength, bool isHand, inout vec3 screenPos){
	const float rSteps = 1.0 / RAYTRACE_QUALITY;

	float viewRayLength = (-near - viewRayOri.z) / viewRayDir.z + step(viewRayDir.z, 0.0) * 1e20;
	vec3 rayDir = normalize(ScreenPos_From_ViewPos_Raw(viewRayOri + viewRayDir * viewRayLength) - screenPos);
	
	float minStepLength = minLength * rSteps;

	float stepLength = mix(minStepLength, rSteps, NdotV);
	float zScaling = abs(1.0 / rayDir.z);


	bool hit = false;

	screenPos += rayDir * stepLength * noise;
	float depth = textureLod(depthtex1, screenPos.xy, 0.0).x;
	#ifdef DISTANT_HORIZONS
		if (depth == 1.0){
			depth = textureLod(dhDepthTex1, screenPos.xy, 0.0).x;
			depth = ScreenDepth_From_DHScreenDepth(depth);
		}

		float maxDepth = ScreenDepth_From_LinearDepth(LinearDepth_From_ScreenDepth_DH(1.0));
	#endif

	for(int i = 0; i < RAYTRACE_QUALITY + 3; i++){

		if (saturate(screenPos.xy) != screenPos.xy) break;

		#ifdef DISTANT_HORIZONS
			if (screenPos.z >= maxDepth){
				hit = depth >= maxDepth;
		#else
			if (screenPos.z >= 1.0){
				hit = depth >= 1.0;
		#endif
				break;
			}else if (screenPos.z < 0.7 && !isHand){	
				break;
			}


		if (depth < screenPos.z){

			vec3 refineDir = rayDir * stepLength * 0.5;

			for (int j = 0; j < RAYTRACE_REFINEMENT_STEPS; j++, refineDir *= 0.5) {
				
				screenPos += refineDir * (step(screenPos.z, depth) * 2.0 - 1.0);

				#if MC_VERSION >= 11605
					if (isHand){
						depth = textureLod(depthtex2, screenPos.xy, 0.0).x;
					}else{
						depth = textureLod(depthtex1, screenPos.xy, 0.0).x;
						#ifdef DISTANT_HORIZONS
							if (depth == 1.0){
								depth = textureLod(dhDepthTex1, screenPos.xy, 0.0).x;
								depth = ScreenDepth_From_DHScreenDepth(depth);
							}
						#endif
					}
				#else
					depth = textureLod(depthtex1, screenPos.xy, 0.0).x;
					#ifdef DISTANT_HORIZONS
						if (depth == 1.0){
							depth = textureLod(dhDepthTex1, screenPos.xy, 0.0).x;
							depth = ScreenDepth_From_DHScreenDepth(depth);
						}
					#endif
				#endif
			}

			if (depth > screenPos.z) continue;

			float stepDist = LinearDepth_From_ScreenDepth(screenPos.z);
			float sampleDist = LinearDepth_From_ScreenDepth(depth);

			float distDiff = abs(sampleDist - stepDist) / stepDist;

			#ifdef DISTANT_HORIZONS
				if (distDiff < RAYTRACE_ZDIFF_THRESHOLD && screenPos.z > 0.0 && screenPos.z < maxDepth){
					hit = true;
					break;
				}
			#else
				if (distDiff < RAYTRACE_ZDIFF_THRESHOLD && screenPos.z > 0.0 && screenPos.z < 1.0){
					hit = true;
					break;
				}
			#endif
		}
		
		stepLength = clamp(abs(depth - screenPos.z) * zScaling, minStepLength, rSteps);
		screenPos += rayDir * stepLength;	
		depth = textureLod(depthtex1, screenPos.xy, 0.0).x;
		#ifdef DISTANT_HORIZONS
			if (depth == 1.0){
				depth = textureLod(dhDepthTex1, screenPos.xy, 0.0).x;
				depth = ScreenDepth_From_DHScreenDepth(depth);
			}
		#endif
	}

	return hit;
}



vec2 ProjectSky(vec3 dir, float tileSize){
	float tileSizeDivide = 0.5 * tileSize - 1.5;
	vec3 adir = abs(dir);

	vec2 texel;
	if (adir.x > adir.y && adir.x > adir.z){
		dir /= adir.x;
		texel.x = dir.y * tileSizeDivide + tileSize * 0.5;
		texel.y = dir.z * tileSizeDivide + tileSize * (step(0.0, dir.x) + 0.5);
	}else if (adir.y > adir.x && adir.y > adir.z){
		dir /= adir.y;
		texel.x = dir.x * tileSizeDivide + tileSize * 1.5;
		texel.y = dir.z * tileSizeDivide + tileSize * (step(0.0, dir.y) + 0.5);
	}else{
		dir /= adir.z;
		texel.x = dir.x * tileSizeDivide + tileSize * 2.5;
		texel.y = dir.y * tileSizeDivide + tileSize * (step(0.0, dir.z) + 0.5);
	}

	texel.y += ceil(screenSize.y * 0.5 + 1.0);

	return texel * pixelSize;
}


//Modified from http://jcgt.org/published/0007/04/01/paper.pdf by Eric Heitz
vec3 sampleGGXVNDF(vec3 viewVector, float roughness, vec2 noise) {
	vec3 orthoNormal = normalize(vec3(roughness * viewVector.xy, viewVector.z));

	float length2 = dot(orthoNormal.xy, orthoNormal.xy);
	vec3 orthoTangent = length2 > 0.0 ? vec3(-orthoNormal.y, orthoNormal.x, 0.0) * inversesqrt(length2) : vec3(1.0, 0.0, 0.0);
	vec3 orthoBitangent = cross(orthoNormal, orthoTangent);

	float radius = sqrt(noise.y * 0.7);
	float angle = TAU * noise.x;
	vec2 samplePos = vec2(cos(angle), sin(angle)) * radius;

	float scaling = orthoNormal.z * 0.5 + 0.5;
	samplePos.y = (1.0 - scaling) * sqrt(1.0 - samplePos.x * samplePos.x) + scaling * samplePos.y;

	vec3 sampleVector = samplePos.x * orthoTangent + samplePos.y * orthoBitangent + sqrt(max(0.0, 1.0 - dot(samplePos, samplePos))) * orthoNormal;
	return normalize(vec3(roughness * sampleVector.xy, max(sampleVector.z, 0.0)));
}

#ifdef DIMENSION_MAIN
	void CalculateSpecularReflections(inout vec3 color, vec3 viewDir, vec3 normal, vec3 albedo, float waterAbsorption, Material material){
#else
	void CalculateSpecularReflections(inout vec3 color, vec3 viewDir, vec3 normal, vec3 albedo, Material material){
#endif

	vec3 reflection = CurveToLinear(texelFetch(colortex3, texelCoord, 0).rgb);

	#ifndef DIMENSION_NETHER
		if (texelFetch(colortex1, texelCoord, 0).a < 0.5){
	#endif

		reflection *= mix(vec3(1.0), albedo, vec3(material.metalness));

		vec3 l = normalize(reflect(viewDir, normal) + normal * material.roughness);

		vec3 h = normalize(l - viewDir);
		float LdotH = saturate(dot(l, h));
		float NdotL = saturate(dot(normal, l));
		float NdotV = saturate(dot(normal, -viewDir));

		float specular = F_Schlick(LdotH, material.f0, 1.0);
		specular *= V_Schlick(NdotL, NdotV + 0.8, material.roughness);
		specular *= material.reflectionStrength;

		specular = mix(specular, 1.0, material.metalness);

		vec3 temp = color;

		float diff = (length(color) - length(reflection)) / (length(color) + length(reflection));
		diff = sign(diff) * sqrt(abs(diff));
		specular += 0.75 * diff * (1.0 - specular) * specular;

	#ifdef DIMENSION_MAIN
		color = mix(color, reflection, saturate(specular * waterAbsorption));
		color += temp * (material.metalness * waterAbsorption);
	#else
		color = mix(color, reflection, saturate(specular));
		color += temp * material.metalness;
	#endif

	#ifndef DIMENSION_NETHER
		}else{
			color = reflection;
		}
	#endif
}