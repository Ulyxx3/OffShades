#if !defined INCLUDE_END_ENDSKY
#define INCLUDE_END_ENDSKY

// ==========================================
// ITERATION END SKY PORTED TO PHOTON
// ==========================================

#define TAU 6.28318530718
#define saturate(x) clamp(x, 0.0, 1.0)
#define curve(x) (x * x * (3.0 - 2.0 * x))
#define remapSaturate(x, e0, e1) saturate((x - e0) / (e1 - e0))

vec3 Blackbody_Iter(float temperature){
	const mat2x4 splineX = mat2x4(-0.2661293e9, -0.2343589e6, 0.8776956e3, 0.179910,
								  -3.0258469e9,  2.1070479e6, 0.2226347e3, 0.240390);

	const mat3x4 splineY = mat3x4(-1.1063814, -1.34811020, 2.18555832, -0.20219683,
								  -0.9549476, -1.37418593, 2.09137015, -0.16748867,
								   3.0817580, -5.87338670, 3.75112997, -0.37001483);

	float rt = 1.0 / temperature;
	float rt2 = rt * rt;
	vec4 coeffX = vec4(rt2 * rt, rt2, rt, 1.0);

	float x = dot(coeffX, temperature < 4000.0 ? splineX[0] : splineX[1]);
	float x2 = x * x;
	vec4 coeffY = vec4(x2 * x, x2, x, 1.0);

	float z = 1.0 / dot(coeffY, temperature < 2222.0 ? splineY[0] : temperature < 4000.0 ? splineY[1] : splineY[2]);

	vec3 xyz = vec3(x * z, 1.0, z);
	xyz.z -= xyz.x + 1.0;

	const mat3 xyzToSrgb = mat3( 3.24097, -0.96924,  0.05563,
								-1.53738,  1.87597, -0.20398,
								-0.49861,  0.04156,  1.05697);

	return max(xyzToSrgb * xyz, vec3(0.0));
}

vec3 RayPlaneIntersection(vec3 ori, vec3 dir, vec3 normal){
	float rayPlaneAngle = dot(dir, normal);
	float planeRayDist = 1e8;
	vec3 intersectionPos = dir * planeRayDist;
	if (rayPlaneAngle > 0.0001 || rayPlaneAngle < -0.0001){
		planeRayDist = dot(-ori, normal) / rayPlaneAngle;
		intersectionPos = ori + dir * planeRayDist;
	}
	return intersectionPos;
}

vec2 RaySphereIntersection(vec3 ori, vec3 dir, float radius){
	float b = dot(ori, dir);
	float c = -radius * radius + dot(ori, ori);
	float d = b * b - c;
	vec2 intersection = vec2(1e10, -1e10);
	if (d >= 0.0){
		d = sqrt(d);
		intersection = vec2(-b - d, -b + d);
	}
	return intersection;
}

float MiePhaseFunction_Iter(float g, float nu) {
	float gg = g * g;
	float k = 0.1193662 * (1.0 - gg) / (2.0 + gg);
	return k * (1.0 + nu * nu) * pow(1.0 + gg - 2.0 * g * nu, -1.5);
}

mat3 RotateMatrix(float x, float y, float z){
	mat3 matx = mat3(1.0, 0.0, 0.0, 0.0, cos(x), sin(x), 0.0, -sin(x), cos(x));
	mat3 maty = mat3(cos(y), 0.0, -sin(y), 0.0, 1.0, 0.0, sin(y), 0.0, cos(y));
	mat3 matz = mat3(cos(z), sin(z), 0.0, -sin(z), cos(z), 0.0, 0.0, 0.0, 1.0);
	return maty * matx * matz;
}

// Global time factor mimicking Iteration
float get_end_time_factor(float frameTimeCounter) {
	return fract(frameTimeCounter * ((1.0 / 60.0) / 10.0) + 0.282) * TAU; // Hardcoded default speed
}

float get_planet_shadow(float timeFactor) {
	return smoothstep(0.62, 0.35, timeFactor) + smoothstep(1.6, 1.87, timeFactor);
}

// CalculateStars from Iteration
vec3 CalculateIterStars(vec3 worldDir, vec3 sun_dir, float frameTimeCounter){
	float angleY = frameTimeCounter * 0.001;
	mat3 eyeRoataionMatrixY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));
	worldDir = eyeRoataionMatrixY * worldDir;

	const float scale = 384.0;
	const float coverage = 0.007;
	const float maxLuminance = 0.04;
	const float minTemperature = 4000.0;
	const float maxTemperature = 8000.0;

	float cosine = dot(sun_dir, vec3(0, 0, 1));
	vec3 axis = cross(sun_dir, vec3(0, 0, 1));
	float cosecantSquared = 1.0 / (dot(axis, axis) + 1e-5);
	worldDir = cosine * worldDir + cross(axis, worldDir) + (cosecantSquared - cosecantSquared * cosine) * dot(axis, worldDir) * axis;

	vec3  p = worldDir * scale;
	ivec3 i = ivec3(floor(p));
	vec3  f = p - i;
	float r = dot(f - 0.5, f - 0.5);

	vec3 i3 = fract(i * vec3(443.897, 441.423, 437.195));
	i3 += dot(i3, i3.yzx + 19.19);
	vec2 hash = fract((i3.xx + i3.yz) * i3.zy);
	hash.y = 2.0 * hash.y - 4.0 * hash.y * hash.y + 3.0 * hash.y * hash.y * hash.y;

	float c = remapSaturate(hash.x, 1.0 - coverage, 1.0);
	return (maxLuminance * remapSaturate(r, 0.25, 0.0) * c * c) * Blackbody_Iter(mix(minTemperature, maxTemperature, hash.y));
}

vec3 H_Iter(vec3 albedo, float a){
	vec3 R = sqrt(vec3(1.0) - albedo);
	vec3 r = (1.0 - R) / (1.0 + R);
	vec3 H = r + (0.5 - r * a) * log((1.0 + a) / a);
	H *= albedo * a;
	return 1.0 / (1.0 - H);
}

vec3 ppss(vec3 albedo, vec3 normal, vec3 eyeDir, vec3 lightDir, float s){
	float NdotL = dot(normal, lightDir);
	float NdotV = dot(normal, eyeDir);
	albedo *= curve(saturate(NdotL));
	vec3 color = albedo * H_Iter(albedo, NdotL) * H_Iter(albedo, NdotV) / (4.0 * pi * (NdotL + NdotV));
	return saturate(color);
}

float Disc(float a, float s, float h){
	float disc = curve(saturate((a - (1.0 - s)) * h));
	return disc * disc;
}

// PlanetEnd2 from Iteration
void PlanetEnd2(inout vec3 color, in vec3 eye, in vec3 rayDir, in vec3 lightDir, in vec3 shadowVector, float timeFactor, float planetShadow, sampler2D noiseTex){
	const float Rground = 20e6;
	const float Ratmo = 20.1e6;
	eye.y += Rground;
	eye.y += 15e6;

	float VdotL = dot(shadowVector, rayDir);
	float mie = MiePhaseFunction_Iter(0.8, VdotL);

	float angleX = -1.57079633 + (0.2 * sin(timeFactor + 3.0) - 0.1);
	float angleY = timeFactor;
	mat3 eyeRoataionMatrixX = mat3(1, 0, 0, 0, cos(angleX), -sin(angleX), 0, sin(angleX), cos(angleX));
	mat3 eyeRoataionMatrixY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));
	mat3 eyeRoataionMatrix = eyeRoataionMatrixX * eyeRoataionMatrixY;

	float ringAngle = 0.008 * sin(timeFactor + 4.6);
	mat3 ringRoataionMatrix = mat3(1.0, 0.0, 0.0, 0.0, cos(ringAngle), sin(ringAngle), 0.0, -sin(ringAngle), cos(ringAngle));
	mat3 ringRoataionMatrixInverse = transpose(ringRoataionMatrix);

	rayDir = eyeRoataionMatrix * rayDir;
	lightDir = eyeRoataionMatrix * lightDir;
	vec3 rayDirRing = ringRoataionMatrix * rayDir;
	vec3 lightDirRing = ringRoataionMatrix * lightDir;

	vec3 ringOrigin = vec3(0.0, cos(ringAngle), sin(ringAngle)) * (eye.y / Rground);
	vec2 ringRadius = vec2(1.6, 2.6);

	vec3 surface = vec3(0.0);
	vec2 groundIntersection = RaySphereIntersection(eye, rayDir, Rground);
	vec2 topAtmoIntersection = RaySphereIntersection(eye, rayDir, Ratmo);
	vec3 surfacePos = rayDir * groundIntersection.x;
	vec3 surfaceNormal = normalize(surfacePos + vec3(0.0, eye.y, 0.0));

	if (groundIntersection.y > 0.0){
		color *= 0.0;
		vec3 surfaceAlbedo = vec3(0.98, 0.87, 0.55);
		surface = ppss(surfaceAlbedo, surfaceNormal, -rayDir, lightDir, 1.0);

		vec3 origin = ringOrigin + surfacePos / Rground;
		vec3 rayPos = RayPlaneIntersection(origin, lightDirRing, vec3(0.0, 0.0, 1.0));
		float rayRadius = length(rayPos);

		if (rayRadius > ringRadius.x && rayRadius < ringRadius.y && dot(rayPos - origin, lightDirRing) > 0.0){
			const float octAlpha = 0.5;
			float octScale = 4.0;
			float octShift = (octAlpha / octScale) / 5.0;
			float accum = 0.0;
			float alpha = 0.5;
			float shift = 0.0;
			float position = rayRadius * 0.5 + 0.69;

			for (int i = 0; i < 5; i++){
				accum += alpha * textureLod(noiseTex, vec2(position, 0.0), 0.0).z;
				position = (position + shift) * octScale;
				alpha *= octAlpha;
			}
			surface *= exp(-pow(saturate(accum + octShift - 0.1) * 1.5, 3.0) * smoothstep(ringRadius.x, ringRadius.x * 1.1, rayRadius));
		}

		float UdotN = saturate(dot(ringRoataionMatrixInverse[2], surfaceNormal));
		float DdotN = saturate(dot(-ringRoataionMatrixInverse[2], surfaceNormal));
		float OLdotN = saturate(dot(ringRoataionMatrixInverse * normalize(vec3(-lightDir.xy, 0.0)), surfaceNormal));

		float ringLighting = Disc(UdotN, 1.2, 1.5) * (1.0 - Disc(UdotN, 3.4, 0.3));
		ringLighting += Disc(DdotN, 1.2, 1.5) * (1.0 - Disc(DdotN, 3.4, 0.3));
		ringLighting *= 1.0 - Disc(OLdotN, 0.7, 1.3);

		surface += surfaceAlbedo * (1.5e-4 + ringLighting * 0.01);
	}

	if (topAtmoIntersection.y > 0.0){
		float isGround = step(0.0, groundIntersection.y);
		float thickness = (topAtmoIntersection.y - topAtmoIntersection.x - (groundIntersection.y - groundIntersection.x) * isGround) * 1e-7;
		float topAtmoMie = mie * thickness * thickness;
		topAtmoMie *= mix(1.0, smoothstep(0.9, 0.4, dot(surfaceNormal, normalize(eye))), isGround);
		surface += topAtmoMie * vec3(0.65, 0.7, 1.0);
	}

	color += surface * 0.6;

	float inRing = saturate(abs(ringAngle) * 3000.0 - 0.8);
	float ring = 0.0;
	float transmittance = 1.0;

	if (rayDirRing.z * ringAngle < 0.0){
		vec3 origin = vec3(0.0, cos(ringAngle), sin(ringAngle)) * (eye.y / Rground);
		vec3 ringPos = RayPlaneIntersection(origin, rayDirRing, vec3(0.0, 0.0, 1.0));
		float rayRadius = length(ringPos);

		if(rayRadius > ringRadius.x && rayRadius < ringRadius.y) {
			const float octAlpha = 0.5;
			float octScale = 4.0;
			float octShift = (octAlpha / octScale) / 5.0;
			float accum = 0.0;
			float alpha = 0.5;
			float shift = 0.0;
			float position = rayRadius * 0.5 + 0.69;

			for (int i = 0; i < 5; i++) {
				accum += alpha * textureLod(noiseTex, vec2(position, 0.0), 0.0).z;
				position = (position + shift) * octScale;
				alpha *= octAlpha;
			}
			ring += pow(saturate(accum + octShift - 0.1) * 1.5, 3.0);
			ring *= smoothstep(ringRadius.x, ringRadius.x * 1.1, rayRadius);

			if(ringPos.y < 0.0 && groundIntersection.y > 0.0){
				ring *= 0.0;
			}else{
				transmittance *= exp2(-ring * 3.0);
			}
			float d = length(cross(lightDirRing, ringPos));
			ring *= 0.98 * max(smoothstep(0.8, 1.2, d), step(0.0, dot(lightDirRing, ringPos))) + 0.02;
		}
	}

	ring = mix(planetShadow * 0.49 + 0.01, ring, inRing);
	transmittance = mix(0.7, transmittance, inRing);

	color *= transmittance;
	ring *= 1.0 + mie * 10.0 * planetShadow;
	color += ring * 0.012 * vec3(1.0, 0.85, 0.60);
}

void WarpSpace(inout vec3 eyevec, inout vec3 raypos){
	vec3 origin = vec3(0.0, 0.0, 0.0);
	float singularityDist = distance(raypos, origin);
	float warpFactor = 1.0 / (singularityDist * singularityDist + 0.000001);
	vec3 singularityVector = normalize(origin - raypos);
	float warpAmount = 0.06;
	eyevec = normalize(eyevec + singularityVector * warpFactor * warpAmount);
}

float Calculate3DNoise(vec3 position, sampler2D noiseTex){
	vec3 p = floor(position);
	vec3 b = curve(fract(position));
	vec2 uv = 17.0 * p.z + p.xy + b.xy;
	vec2 rg = textureLod(noiseTex, (uv + 0.5) / 64.0, 0.0).zx;
	return mix(rg.x, rg.y, b.z);
}

float CalculateCloudFBM(vec3 position, vec3 shift, sampler2D noiseTex){
	const int octaves = 4;
	const float octAlpha = 0.87;
	const float octScale = 2.5;
	const float octShift = (octAlpha / octScale) / octaves;
	float accum = 0.0;
	float alpha = 0.5;

	for (int i = 0; i < octaves; i++) {
		accum += alpha * Calculate3DNoise(position, noiseTex);
		position = (position + shift) * octScale;
		alpha *= octAlpha;
	}
	return accum + octShift;
}

float pcurve(float x){
	float x2 = x * x;
	return 12.207 * x2 * x2 * (1.0 - x);
}

void BlackHole_AccretionDisc_Stars(inout vec3 color, in vec3 rayDir, in vec3 lightDir, vec2 gl_FragCoord, float frameTimeCounter, sampler2D noiseTex, vec3 sunDir){
	const float steps = 50.0;
	const float rSteps = 1.0 / steps;
	const float stepLength = 0.2;

	const float discRadius = 2.25;
	const float discWidth = 3.5;
	const float discInner = discRadius - discWidth * 0.5;
	const float discOuter = discRadius + discWidth * 0.5;

	float noise = fract(52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y));

	vec3 eye = -lightDir * 8.0;
	vec3 rayPos = eye + rayDir * 3.0;

	mat3 rotation = RotateMatrix(0.1, 0.0, -0.35);

	vec3 result = vec3(0.0);
	float transmittance = 1.0;

	rayPos += rayDir * stepLength * noise;

	for(int i = 0; i < steps; i++){
		if(transmittance < 0.0001) break;

		WarpSpace(rayDir, rayPos);
		rayPos += rayDir * stepLength;

		{
			vec3 discPos = rotation * rayPos;
			float r = length(discPos);
			float p = atan(discPos.x, -discPos.z);
			float h = discPos.y;

			float radialGradient = 1.0 - saturate((r - discInner) / discWidth * 0.5);
			float dist = abs(h);

			float discThickness = 0.1 * radialGradient;
			float fr = abs(r - discInner) + 0.4;
			fr = fr * fr;
			float fade = fr * fr * 0.04;
			float bloomFactor = 1.0 / (h * h * 40.0 + fade + 0.00002);
			bloomFactor *= saturate(2.0 - abs(dist) / discThickness);
			bloomFactor = bloomFactor * bloomFactor;

			float dr = pcurve(radialGradient);
			float density = dr;

			density *= saturate(1.0 - abs(dist) / discThickness);
			density = saturate(density * 0.7);
			density = saturate(density + bloomFactor * 0.1);

			if (density > 0.0001){
				vec3 discCoord = vec3(r, 0.0, h * 0.1) * 3.5;
				float fbm = CalculateCloudFBM(discCoord, frameTimeCounter * vec3(0.03, 0.05, 0.0), noiseTex);
				fbm = fbm * fbm;
				fbm = fbm * fbm;

				density *= fbm * dr;

				float gr = 1.0 - radialGradient;
				gr = gr * gr;
				float glowStrength = 1.0 / (gr * gr * 400.0 + 0.002);
				vec3 glow = Blackbody_Iter(2700.0 + glowStrength * 50.0) * glowStrength;

				float stepTransmittance = exp2(-density * 7.0);
				float integral = 1.0 - stepTransmittance;
				transmittance *= stepTransmittance;

				result += integral * transmittance * glow;
			}

			vec2 t = vec2(1.0, 0.01);
			float torusDist = length(vec2(length(discPos.xz) - t.x, discPos.y)); // fix torus calc
			float bloomDisc = 1.0 / (pow(torusDist, 3.5) + 0.001);
			vec3 col = Blackbody_Iter(12000.0);
			bloomDisc *= step(0.5, r);

			result += col * bloomDisc * 0.1 * transmittance;
		}
	}
	result *= rSteps;

	color += CalculateIterStars(rayDir, sunDir, frameTimeCounter);

	color *= transmittance;
	color += result;
}

#endif
