

void VanillaFog(inout vec3 color, float dist){
	#ifndef DISABLE_BLINDNESS_DARKNESS
		if (darknessFactor > 0.0) color = mix(color, vec3(0.0), smoothstep(5.0, mix(far, 15.0, darknessFactor), dist) * darknessFactor);
		if (blindness > 0.0) color = mix(color, vec3(0.0), smoothstep(1.5, mix(far, 4.5, blindness), dist) * blindness);
	#endif

	if (isEyeInWater == 3) color = mix(color, vec3(0.03), smoothstep(0.0, 2.0, dist));

	if (isEyeInWater == 2) color = mix(color, vec3(0.3721, 0.0775, 0.0024) * TORCHLIGHT_BRIGHTNESS, smoothstep(0.0, 1.0, dist));
}

void SelectionBox(inout vec3 color, vec3 albedo, bool isSelection){
	if (isSelection){
		float exposure = CurveToLinear(texelFetch(colortex2, ivec2(0, screenSize.y - 1.0), 0).a) * (1500.0 / EXPOSURE_OUTPUT_FACTOR);
		color = albedo * exposure;;
	}
}
