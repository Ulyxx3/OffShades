

float CurveBlockLightSky(float blockLight){
	blockLight = 1.0 - pow(1.0 - blockLight * 0.9, 0.7);

	blockLight = saturate(blockLight * blockLight * blockLight * 1.95);

	return blockLight;
}

float CurveBlockLightTorch(float blockLight){
	float dist = (1.0 - blockLight) * 15.0 + 1.0;
	dist = dist * dist;

	float boost = saturate(blockLight * 2.0 - 1.0);
	blockLight = blockLight + boost * boost;
	blockLight /= dist;

	return blockLight;
}

struct Material{
	float roughness;
	float metalness;
	float f0;
	float emissiveness;
	float scattering;
	float reflectionStrength;
};

struct GbufferData{
	vec3 albedo;
	vec4 albedoW;
	vec3 normalL;
	vec3 normalW;
	float depthL;
	float depthW;
	vec2 lightmapL;
	vec2 lightmapW;
	float materialIDL;
	float materialIDW;
	float waterMask;
	float rainAlpha;
	float parallaxShadow;
	Material material;
};

struct Ray{
	vec3 dir;
	vec3 origin;
};

struct Plane{
	vec3 normal;
	vec3 origin;
};

struct Intersection{
	vec3 pos;
	float distance;
	float angle;
};


const Material airMaterial 		= Material(1.0, 0.0, 0.0,   0.0, 0.0, 0.0);
const Material material_water 	= Material(0.0, 0.0, 0.02,  0.0, 0.0, 1.0);
const Material material_glass 	= Material(0.0, 0.0, 0.042, 0.0, 0.0, 1.0);
const Material material_ice 	= Material(0.0, 0.0, 0.018, 0.0, 0.0, 1.0);

Material MaterialFromTex(inout vec3 baseTex, vec4 specTex, float wet){
	#ifdef TEXTURE_PBR_POROSITY
		#if TEXTURE_PBR_FORMAT < 2
			float porosity = saturate(specTex.b * (255.0 / 63.0) - step(64.0 / 255.0, specTex.b));
		#else
			float porosity = TEXTURE_DEFAULT_POROSITY;
		#endif
	#else
		float porosity = TEXTURE_DEFAULT_POROSITY;
	#endif

	baseTex *= 1.0 - wet * fsqrt(porosity) * POROSITY_ABSORPTION;


	Material material;


	float rawSmoothness = mix(specTex.r, 1.0, saturate(wet * (1.7 - porosity * 0.7)));
	material.roughness = 1.0 - rawSmoothness;
	material.roughness *= material.roughness;


	float rawMetalness = specTex.g;
	#if TEXTURE_PBR_FORMAT == 0
		rawMetalness = saturate(rawMetalness + step(0.9, rawMetalness));
	#endif
	#ifdef ROUGHNESS_CLAMP
		material.metalness = saturate(rawMetalness * 1.1 - 0.1);
	#else
		material.metalness = rawMetalness;
	#endif
	material.f0 = rawMetalness * 0.96 + 0.04;


	#ifdef ROUGHNESS_CLAMP
		material.reflectionStrength = saturate(2.0 - material.roughness * 5.0);
	#else
		material.reflectionStrength = saturate(2.0 - material.roughness * 2.0);
	#endif
	material.reflectionStrength = saturate(material.reflectionStrength + material.metalness * 1e10 + wet * 3.0);


	material.emissiveness = specTex.a;
	#if TEXTURE_PBR_FORMAT < 2
		material.emissiveness -= step(1.0, material.emissiveness);
	#endif
	material.emissiveness = pow(material.emissiveness, EMISSIVENESS_GAMMA);


	#if TEXTURE_PBR_FORMAT < 2
		material.scattering = saturate((specTex.b * 255.0 - 64.0) / 191.0) * SSS_STRENGTH + SSS_STRENGTH_OFFSET;
	#else
		material.scattering = 0.0;
	#endif


	return material;
}



GbufferData GetGbufferData(){
	GbufferData data;

	vec4 gbuffer0 = texelFetch(colortex0, texelCoord, 0);
	vec4 gbuffer3 = texelFetch(colortex3, texelCoord, 0);
	vec4 gbuffer5 = texelFetch(colortex5, texelCoord, 0);

#ifdef DIMENSION_END
	// In the End, bypass colortex4 and colortex6 (which are at reduced resolution in Photon).
	// We mimic what Iteration's deferred.fsh originally did, directly in the shader!
	vec4 gbuffer4 = gbuffer3;
	vec4 gbuffer6 = vec4(0.0, 0.0, gbuffer5.z, 0.0);
#else
	vec4 gbuffer4 = texelFetch(colortex4, texelCoord, 0);
	vec4 gbuffer6 = texelFetch(colortex6, texelCoord, 0);
#endif


	data.albedo 		= GammaToLinear(gbuffer0.rgb);
	data.albedoW 		= vec4(Unpack2x8(gbuffer6.r), Unpack2x8(gbuffer6.g));
	data.albedoW.rgb 	= GammaToLinear(data.albedoW.rgb);
	data.normalL 		= DecodeNormal(gbuffer3.rg);
	data.normalW 		= DecodeNormal(gbuffer4.rg);
	data.depthL 		= texelFetch(depthtex1, texelCoord, 0).x;
	data.depthW 		= texelFetch(depthtex0, texelCoord, 0).x;
	data.lightmapL 		= gbuffer3.ba;
	data.lightmapW 		= gbuffer4.ba;
	data.lightmapL 		= vec2(data.lightmapL.r, CurveBlockLightSky(data.lightmapL.g));
	data.lightmapW 		= vec2(data.lightmapW.r, CurveBlockLightSky(data.lightmapW.g));
	data.materialIDL 	= data.depthL >= 1.0 ? MATID_SKY / 255.0 : gbuffer5.b;
	data.materialIDW 	= data.depthW >= 1.0 ? MATID_SKY / 255.0 : gbuffer6.b;
	data.waterMask 		= gbuffer6.a;
	data.rainAlpha 		= 1.0 - gbuffer0.a;
	vec2 gbuffer5a 		= Unpack2x8(gbuffer5.a);
	data.parallaxShadow = gbuffer5a.y;

	#ifdef ENABLE_PBR
		vec4 specTex = vec4(Unpack2x8(gbuffer5.r), Unpack2x8(gbuffer5.g));
		data.material = MaterialFromTex(data.albedo, specTex, gbuffer5a.x);

		#if MC_VERSION < 11605
			data.material.reflectionStrength *= float(data.depthW >= 0.7);
		#endif
	#else
		data.material = airMaterial;
	#endif

	return data;
}


struct MaterialMask{
	float sky;
	float land;
	float grass;
	float leaves;
	float hand;
	float entityPlayer;
	float water;
	float stainedGlass;
	float ice;

	float entitiesLitHigh;
	float entitiesLitMedium;
	float entitiesLitLow;
	float lightning;
	float entitiesSnow;

	float torch;
	float lava;
	float glowstone;
	float fire;
	float redstoneTorch;
	float redstone;
	float soulFire;
	float amethyst;
	float oxidizedBulb;

	float particle;
	float particlelit;

	float endPortal;

	float selection;
};

MaterialMask CalculateMasks(float materialIDs){
	MaterialMask mask;

	materialIDs = floor(materialIDs * 255.0);

	mask.sky				= float(materialIDs == MATID_SKY);
	mask.land				= float(materialIDs == MATID_LAND);
	mask.grass				= float(materialIDs == MATID_GRASS || materialIDs == MATID_BEACON_BEAM);
	mask.leaves				= float(materialIDs == MATID_LEAVES);
	mask.hand				= float(materialIDs == MATID_HAND);

	mask.water				= float(materialIDs == MATID_WATER);
	mask.stainedGlass		= float(materialIDs == MATID_STAINEDGLASS);
	mask.ice				= float(materialIDs == MATID_ICE);

	mask.entityPlayer		= float(materialIDs == MATID_ENTITIES_PLAYER);
	mask.entitiesLitHigh	= float(materialIDs == MATID_ENTITIES_LIT_HIGH || materialIDs == MATID_BEACON_BEAM);
	mask.entitiesLitMedium	= float(materialIDs == MATID_ENTITIES_LIT_MEDIUM);
	mask.entitiesLitLow		= float(materialIDs == MATID_ENTITIES_LIT_LOW);
	mask.entitiesSnow		= float(materialIDs == MATID_ENTITIES_SNOW || materialIDs == MATID_BEACON_BEAM);
	mask.lightning			= float(materialIDs == MATID_LIGHTNING);

	mask.torch				= float(materialIDs == MATID_TORCH);
	mask.lava				= float(materialIDs == MATID_LAVA);
	mask.glowstone			= float(materialIDs == MATID_GLOWSTONE);
	mask.fire				= float(materialIDs == MATID_FIRE);
	mask.redstoneTorch		= float(materialIDs == MATID_REDSTONE_TORCH);
	mask.redstone			= float(materialIDs == MATID_REDSTONE);
	mask.soulFire			= float(materialIDs == MATID_SOULFIRE);
	mask.amethyst			= float(materialIDs == MATID_AMETHYST);
	mask.oxidizedBulb		= float(materialIDs == MATID_OXIDIZED_BULB);

	mask.particle			= float(materialIDs == MATID_PARTICLE);
	mask.particlelit		= float(materialIDs == MATID_PARTICLE_LIT);

	mask.endPortal			= float(materialIDs == MATID_END_PORTAL);

	mask.selection			= float(materialIDs == MATID_SELECTION);

	return mask;
}

void FixParticleMask(inout MaterialMask materialMaskSoild, inout MaterialMask materialMask, inout float depthL, in float depthW){
	#if MC_VERSION >= 11500
	if(materialMaskSoild.particle > 0.5 || materialMaskSoild.particlelit > 0.5){
		materialMask.particle = 1.0;
		materialMask.water = 0.0;
		materialMask.stainedGlass = 0.0;
		materialMask.ice = 0.0;
		materialMask.sky = 0.0;
		depthL = depthW;
	}
	#endif
}

void FixParticleMask(inout MaterialMask materialMaskSoild, inout MaterialMask materialMask){
	#if MC_VERSION >= 11500
	if(materialMaskSoild.particle > 0.5 || materialMaskSoild.particlelit > 0.5){
		materialMask.particle = 1.0;
		materialMask.water = 0.0;
		materialMask.stainedGlass = 0.0;
		materialMask.ice = 0.0;
		materialMask.sky = 0.0;
	}
	#endif
}

void ApplyMaterial(inout Material material, in MaterialMask materialMask, inout bool isSmooth){
	if (materialMask.water > 0.5){
		material = material_water;
		isSmooth = true;
	}
	if (materialMask.stainedGlass > 0.5){
		material = material_glass;
		isSmooth = true;
	}
	if (materialMask.ice > 0.5){
		material = material_ice;
		isSmooth = true;
	}
}
