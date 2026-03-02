

float BicubicBlurTexture(sampler2D texSampler, vec2 coord, vec2 texSize){
	vec2 texPixelSize = 1.0 / texSize;
	coord = coord * texSize - 0.5;

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
	c *= texPixelSize.xxyy;

	vec2 m = s.xz / (s.xz + s.yw);
	return mix(mix(textureLod(texSampler, c.yw, 0.0).x, textureLod(texSampler, c.xw, 0.0).x, m.x),
			   mix(textureLod(texSampler, c.yz, 0.0).x, textureLod(texSampler, c.xz, 0.0).x, m.x),
			   m.y);
}

float CloudShadowFromTex(vec3 worldPos){
	#ifdef NO_COMPOSITE_VS
		vec3 worldShadowVector = shadowModelViewInverse[2].xyz;
	#endif

	vec2 coord = worldPos.xz - worldShadowVector.xz * ((worldPos.y + cameraPosition.y) / worldShadowVector.y);
	coord = coord * (1.0 / CLOUD_SHADOW_RANGE) + 0.5;

	float cloudShadow = 1.0 - wetness;

	if (saturate(coord) == coord){
		float shadowTexSize = floor(min(screenSize.y * 0.45, CLOUD_SHADOWTEX_SIZE));
		vec2 shadowTexel = screenSize - coord * shadowTexSize;

		vec2 fade = saturate(5.9 - abs(coord - 0.5) * 12.0);
		
		cloudShadow = mix(cloudShadow, BicubicBlurTexture(colortex2, shadowTexel * pixelSize, screenSize), fade.x * fade.y);
	}

	#ifdef CLOUD_SHADOW_FADE
		float fadeAngle = smoothstep(0.06, 0.18, abs(worldShadowVector.y));
		cloudShadow = mix(1.0 - wetness, cloudShadow, fadeAngle * fadeAngle);
	#endif

	return ((RAIN_SHADOW - 1.0) * wetness + 1.0) * cloudShadow + (wetness - RAIN_SHADOW * wetness); // mix(cloudShadow, mix(1.0, cloudShadow, RAIN_SHADOW), wetness)
}

float GetSmoothCloudShadow(){
	#if defined VOLUMETRIC_CLOUDS && defined CLOUD_SHADOW
		float globalCloudShadow = mix(texelFetch(colortex2, ivec2(40, screenSize.y - 1.0), 0).a, 1.0, 0.03 - wetness * 0.015);
	#else
		float globalCloudShadow = 1.0 - wetness * (RAIN_SHADOW * 0.985);
	#endif

	return globalCloudShadow;
}