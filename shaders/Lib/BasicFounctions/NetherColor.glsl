

uniform float BiomeNetherWastesSmooth;
uniform float BiomeSoulSandValleySmooth;
uniform float BiomeCrimsonForestSmooth;
uniform float BiomeWarpedForestSmooth;
uniform float BiomeBasaltDeltasSmooth;


vec3 NetherLighting(){
	vec3 netherLighting =	 BiomeNetherWastesSmooth *   vec3(0.99, 0.34, 0.10) * 4.5e-4;
	netherLighting +=		 BiomeSoulSandValleySmooth * vec3(0.60, 0.77, 1.00) * 2e-4;
	netherLighting +=		 BiomeCrimsonForestSmooth *  vec3(1.00, 0.80, 0.57) * 4e-4;
	netherLighting +=		 BiomeWarpedForestSmooth *   vec3(0.79, 0.82, 1.00) * 2.5e-4;
	netherLighting +=		 BiomeBasaltDeltasSmooth *   vec3(1.00, 0.78, 0.62) * 1e-3;
	return netherLighting * NETHER_BRIGHTNESS;
}

vec4 NetherFogColor(){
	vec4 fog =	 vec4(0.990, 0.170, 0.005, 0.010) * BiomeNetherWastesSmooth;
	fog +=		 vec4(0.010, 0.035, 0.060, 0.007) * BiomeSoulSandValleySmooth;
	fog +=		 vec4(0.200, 0.020, 0.000, 0.010) * BiomeCrimsonForestSmooth;
	fog +=		 vec4(0.030, 0.100, 0.130, 0.007) * BiomeWarpedForestSmooth;
	fog +=		 vec4(0.400, 0.400, 0.400, 0.014) * BiomeBasaltDeltasSmooth;
	return fog * vec4(vec3(NETHER_BRIGHTNESS), NETHERFOG_DENSITY);
}
