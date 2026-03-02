#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"

#include "/Lib/BasicFounctions/PrecomputedAtmosphere.glsl"


out vec3 worldShadowVector;
out vec3 shadowVector;
out vec3 worldSunVector;
out vec3 worldMoonVector;

out vec3 colorShadowlight;
out vec3 colorSunlight;
out vec3 colorMoonlight;

out vec3 colorSkylight;
out vec3 colorSunSkylight;
out vec3 colorMoonSkylight;

out vec3 colorTorchlight;

out float timeNoon;
out float timeMidnight;

#ifdef VS_SHADOW_HIGHLIGHT
	out float shadowHighlightStrength;
#endif

#ifdef VS_SUN_VISIBILITY
	#if defined LENS_GLARE || defined LENS_FLARE
		#include "/Lib/Uniform/GbufferTransforms.glsl"

		#ifdef GLARE_FLARE_SHADOWBASED
			const float shadowDistance = 192.0; // [64.0 96.0 128.0 192.0 256.0 384.0 512.0 768.0 1024.0 1536.0 2048.0]

			#include "/Lib/Uniform/ShadowTransforms.glsl"
			uniform sampler2D shadowtex0;
		#endif

		out vec2 sunCoord;
		out float sunVisibility;
	#endif
#endif


#if (defined VS_SUN_VISIBILITY && !defined CAVE_MODE && (defined LENS_GLARE || defined LENS_FLARE)) || defined VS_SHADOW_HIGHLIGHT
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
#endif

void main(){
	gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0.0, 1.0);

	worldShadowVector = shadowModelViewInverse[2].xyz;
	shadowVector = mat3(gbufferModelView) * worldShadowVector;
	//worldSunVector = worldTime > 12785 && worldTime < 23215 ? -worldShadowVector : worldShadowVector;
	worldSunVector = worldShadowVector * (step(sunAngle, 0.5) * 2.0 - 1.0);
	worldMoonVector = -worldSunVector;

	float SdotU = dot(vec3(0.0, 1.0, 0.0), worldSunVector);
	float MdotU = dot(vec3(0.0, 1.0, 0.0), worldMoonVector);

	timeNoon = 1.0 - pow(1.0 - (clamp(SdotU, 0.2, 0.99) - 0.2) / 0.8, 6.0);
	timeMidnight = 1.0 - curve(saturate((1.0 - saturate(MdotU)) * 5.0 - 4.0));

	#if (defined VS_SUN_VISIBILITY && !defined CAVE_MODE && (defined LENS_GLARE || defined LENS_FLARE)) || defined VS_SHADOW_HIGHLIGHT
		float tileSize = min(SKY_IMAGE_RESOLUTION, floor(min(screenSize.x / 3.3, screenSize.y * 0.45)));
		vec2 skyImageCoord = ProjectSky(worldShadowVector, tileSize);

		float cloudVisibility = saturate(textureLod(colortex2, skyImageCoord, 0.0).a * 1.5 - 0.5);
		cloudVisibility = mix(cloudVisibility, 1.0, curve(saturate((1.0 - saturate(SdotU)) * 12.0 - 11.0)) * saturate(1.0 - wetness * 1.5));
		cloudVisibility = mix(1.0, cloudVisibility, RAIN_SHADOW);
	#endif

	#ifdef VS_SHADOW_HIGHLIGHT
		shadowHighlightStrength = cloudVisibility / MAIN_OUTPUT_FACTOR;
		shadowHighlightStrength *= timeNoon * 3.0 + 0.2;
	#endif

	#ifdef VS_SUN_VISIBILITY
		#if defined LENS_GLARE || defined LENS_FLARE
			#ifdef CAVE_MODE
				sunVisibility = 0.0;
			#else
				vec3 sunViewPos = shadowVector * 1e5;
				sunCoord = ScreenPos_From_ViewPos_Raw(sunViewPos).xy;

				float dirVisibility = remapSaturate(shadowVector.z, -0.2, -0.6);

				float effectVisibility = saturate(1.0 - blindness - darknessFactor);

				#ifdef GLARE_FLARE_SHADOWBASED
					vec3 cameraShadowPos = ShadowScreenPos_From_WorldPos_Distorted(worldShadowVector * 0.5 + gbufferModelViewInverse[3].xyz);
					float shadowVisibility = step(cameraShadowPos.z, textureLod(shadowtex0, cameraShadowPos.xy, 0.0).x);

					sunVisibility =	dirVisibility * shadowVisibility * cloudVisibility * effectVisibility;
				#else
					float screenVisibility = smoothstep(0.5, 0.45, abs(sunCoord.x - 0.5)) *
											 smoothstep(0.5, 0.45, abs(sunCoord.y - 0.5));
					float depthVisibility = step(1.0, textureLod(depthtex0, sunCoord, 0.0).x);

					#ifdef DISTANT_HORIZONS
						depthVisibility *= step(1.0, textureLod(dhDepthTex0, sunCoord, 0.0).x);
					#endif

					sunVisibility =	dirVisibility * screenVisibility * depthVisibility * cloudVisibility * effectVisibility;
				#endif

				sunVisibility *= timeNoon * 2.0 + 0.2;
			#endif
		#endif
	#endif

	#ifdef VS_CLOUD_LIGHTING
		vec3 camera = vec3(0.0, 500.0 * 0.001 + atmosphereModel_bottom_radius, 0.0);
	#else
		#ifdef ATMO_HORIZON
			vec3 camera = vec3(0.0, max(cameraPosition.y, ATMO_MIN_ALTITUDE) * 0.001 + atmosphereModel_bottom_radius, 0.0);
		#else
			vec3 camera = vec3(0.0, max(cameraPosition.y, 63.0) * 0.001 + atmosphereModel_bottom_radius, 0.0);
		#endif
	#endif

	colorSunlight = GetSunAndSkyIrradiance(camera, worldSunVector, -worldSunVector, colorMoonlight, colorSunSkylight, colorMoonSkylight);

	colorSunlight *= 1.0 - curve(saturate((1.0 - saturate(SdotU)) * 30.0 - 29.0));
	colorMoonlight *= 1.0 - curve(saturate((1.0 - saturate(MdotU)) * 5.0 - 4.0));
	#ifdef COLD_MOONLIGHT
		DoNightEye(colorMoonlight);
	#endif

	colorShadowlight = colorSunlight + colorMoonlight;
	colorSkylight = colorSunSkylight + colorMoonSkylight;

	colorTorchlight = Blackbody(TORCHLIGHT_COLOR_TEMPERATURE);
}
