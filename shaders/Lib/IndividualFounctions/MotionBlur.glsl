

#define TITLE_SAMPLER
#define COLORTEX8_2D


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const bool colortex1MipmapEnabled  = true;


/* DRAWBUFFERS:12 */
layout(location = 0) out vec4 compositeOutput1;
layout(location = 1) out vec4 compositeOutput2;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;


#ifdef DIMENSION_NETHER
	#include "/Lib/BasicFounctions/NetherColor.glsl"
#endif

#include "/Lib/Uniform/GbufferTransforms.glsl"

#define NO_COMPOSITE_VS
#include "/Lib/IndividualFounctions/CloudShadow.glsl"


vec2 CalculateCameraVelocity(vec2 coord, float depth){
	vec3 projection = vec3(coord, depth) * 2.0 - 1.0;
	projection = (vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * projection.xy, 0.0) + gbufferProjectionInverse[3].xyz) / (gbufferProjectionInverse[2].w * projection.z + gbufferProjectionInverse[3].w);

	if (depth < 0.7){
		projection += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
	}else{
		projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
		if (depth < 1.0) projection += cameraPosition - previousCameraPosition;
		projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
	}
	
	projection = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;
	return coord - projection.xy;
}

vec3 MotionBlur(){
	float materialIDs = floor(texelFetch(colortex6, texelCoord, 0).b * 255.0);
	float depth = 0.0;
	if (materialIDs == MATID_WATER || materialIDs == MATID_ICE){
		depth = texelFetch(depthtex0, texelCoord, 0).x;
	}else{
		depth = texelFetch(depthtex1, texelCoord, 0).x;
	}
	vec2 velocity = vec2(0.0);
	
	#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
		if (depth > 0.7 && materialIDs != MATID_END_PORTAL && materialIDs != MATID_ENTITIES_PLAYER) 
	#else
		if (depth > 0.7 && materialIDs != MATID_END_PORTAL)
	#endif
		velocity = CalculateCameraVelocity(texCoord, depth);

	vec3 color = vec3(0.0);

	if (length(velocity) < 5e-7){

		color = CurveToLinear(texelFetch(colortex7, texelCoord, 0).rgb);

	}else{

		velocity *= MOTION_BLUR_SUTTER_ANGLE / 720.0;
		velocity = clamp(velocity, -0.1, 0.1);

		float steps = MOTION_BLUR_QUALITY;
		float samples = 0.0;

		float dither = 0.0;
		#ifdef MOTION_BLUR_DITHER
			dither = InterleavedGradientNoise(gl_FragCoord.xy);
		#endif

		for (float i = -steps; i <= steps; i++){
			vec2 coord = texCoord.st + velocity / (steps + 1.0) * (i + dither);

			if (saturate(coord) == coord){
				color += CurveToLinear(textureLod(colortex7, coord, 0.0).rgb);
				samples++;
			}
		}

		color.rgb /= samples;
	}

	return color;
}

float title(inout vec3 color){
	float exposure = CurveToLinear(texelFetch(colortex2, ivec2(0, screenSize.y - 1.0), 0).a) * (1500.0 / EXPOSURE_OUTPUT_FACTOR / MAIN_OUTPUT_FACTOR);
	float titleCounter = texelFetch(colortex2, ivec2(20, screenSize.y - 1.0), 0).a * 20.0;
	titleCounter = smoothstep(7.0, 4.0, titleCounter);
 
	vec4 title = vec4(0.0);

	if (titleCounter > 0.0){

		vec3 viewDir = normalize(ViewPos_From_ScreenPos_Raw(texCoord, 1.0));
		vec3 camera = vec3(0.0, 0.0, 4.0);

		float angleRx = acos(dot(gbufferModelView[1].xyz, vec3(0.0, 0.0, -1.0))) - hPI;

		angleRx = -0.5 * angleRx + 0.1;
		mat3 Rx = mat3(1.0,  0.0,          0.0,
					   0.0,  cos(angleRx), sin(angleRx),
					   0.0, -sin(angleRx), cos(angleRx));

		float angleRy = eyeRySmooth * 7.0;
		mat3 Ry = mat3(cos(angleRy), 0.0, -sin(angleRy),
					   0.0,          1.0,  0.0,
					   sin(angleRy), 0.0,  cos(angleRy));
		Rx = Ry * Rx;

		vec3 op = camera;
		op = Rx * op;
		vec3 pp = Rx * viewDir;

		#if MC_VERSION >= 11400
			op = mat3(gbufferModelViewInverse) * op + gbufferModelViewInverse[3].xyz * 0.1;
			pp = mat3(gbufferModelViewInverse) * pp + gbufferModelViewInverse[3].xyz * 0.1;
		#else
			op = mat3(gbufferModelViewInverse) * op;
			pp = mat3(gbufferModelViewInverse) * pp;
		#endif

		op = op * Ry;

		vec3 intersectionPlane = mat3(gbufferModelView) * RayPlaneIntersection(op, pp, -gbufferModelViewInverse[2].xyz);


		if(clamp(intersectionPlane.xy, vec2(-1.9, -1.0), vec2(2.1, 1.0)) == intersectionPlane.xy){
			vec2 titleCoord = intersectionPlane.xy * vec2(0.25, -0.25) + vec2(0.48, 0.28);
			ivec2 tcoord = ivec2(titleCoord * 50.0) + ivec2(0, -4);
			#if MC_VERSION >= 11605
				title = texelFetch(colortex8, tcoord, 0);
			#else
				title = texelFetch(depthtex2, tcoord, 0);
			#endif

			#ifdef DIMENSION_NETHER
				title.rgb *= NetherLighting() * (10.0 / MAIN_OUTPUT_FACTOR);
				title.a = 1.0 - saturate(1e10 - title.a * 1e10);
			#else
				title.rgb *= exposure;
			#endif
		}

		title.a *= titleCounter;

		color = mix(color, title.rgb, title.a);
	}

	return title.a;
}

float GetExposureTiles(){
	float avg = Luminance(CurveToLinear(textureLod(colortex1, vec2(0.65, 0.65), floor(log2(min(viewWidth, viewHeight)))).rgb)) * (MAIN_OUTPUT_FACTOR / 128.0);

	int lod = 6;

	float tileScale = exp2(float(lod));
	vec2 tileCount = floor(screenSize / tileScale);
	vec2 tileCenter = tileCount * 0.5;

	float exposure = 0.0;
	float weights = 0.0;

	for (int x = 0; x < tileCount.x; x++){
	for (int y = 0; y < tileCount.y; y++){
		float tileExposure = Luminance(CurveToLinear(texelFetch(colortex1, ivec2(x, y), lod).rgb)) * (MAIN_OUTPUT_FACTOR / 128.0);

		vec2 tileDistance = (tileCenter - vec2(x, y) + 0.5) * pixelSize * tileScale * 2.0;
		float centerDistance = length(tileDistance);

		#if AE_MODE == 0
			#ifdef DIMENSION_END
				float tileWeight = 1.0;
			#else
				float tileWeight = remapSaturate(centerDistance, 0.6, 0.4);
			#endif
		#elif AE_MODE == 1
			float tileWeight = remapSaturate(centerDistance, 0.7, 0.0);
			tileWeight *= tileWeight;
		#elif AE_MODE == 2
			float tileWeight = remapSaturate(centerDistance, 0.6, 0.4);
		#elif AE_MODE == 3
			float tileWeight = 1.0;
		#endif

		#ifdef AE_CLAMP
			tileExposure = max(6.4e-9, tileExposure);
		#endif

		#if defined CAVE_MODE && defined DIMENSION_MAIN
			float lumaWeight = avg / tileExposure;
			tileWeight *= pow(lumaWeight, 0.7);
		#else
			#if LUMINANCE_WEIGHT_MODE > 0 
				#if LUMINANCE_WEIGHT_MODE == 1
					#ifdef DIMENSION_NETHER
						float lumaWeight = avg / tileExposure;
						lumaWeight = pow(lumaWeight, 0.7);
					#else
						float lumaWeight = avg / tileExposure;
						#ifdef DIMENSION_MAIN
							lumaWeight = pow(lumaWeight, remapSaturate(avg, 1.55e-6, 6.25e-8) * 0.7);
						#else
							lumaWeight = pow(lumaWeight, remapSaturate(avg, 1.55e-6, 6.25e-8) * 0.5 + 0.2);
						#endif
					#endif
				#elif LUMINANCE_WEIGHT_MODE == 2
					#ifdef DIMENSION_NETHER
						float lumaWeight = avg / tileExposure;
						lumaWeight = pow(lumaWeight, 0.7);
					#else
						float lumaWeight = avg / tileExposure;
						lumaWeight = pow(lumaWeight, remapSaturate(avg, 1.55e-6, 6.25e-8) * 0.5 + 0.2);
					#endif				
				#elif LUMINANCE_WEIGHT_MODE == 3
					float lumaWeight = avg / tileExposure;
					lumaWeight = pow(lumaWeight, LUMINANCE_WEIGHT_STRENGTH);
				#elif LUMINANCE_WEIGHT_MODE == 4
					float lumaWeight = tileExposure / avg;
					lumaWeight = pow(lumaWeight, LUMINANCE_WEIGHT_STRENGTH);
				#endif
				tileWeight *= lumaWeight;
			#endif
		#endif

		exposure += tileExposure * tileWeight;
		weights += tileWeight;
	}
	}
	exposure /= weights;
	exposure *= EXPOSURE_OUTPUT_FACTOR;

	return  LinearToCurve(exposure);
}


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	#ifdef MOTION_BLUR
		vec3 color = MotionBlur();
	#else
		vec3 color = CurveToLinear(texelFetch(colortex7, texelCoord, 0).rgb);
	#endif

	#ifdef DIMENSION_MAIN
		#if defined LENS_GLARE || defined LENS_FLARE
			color += CurveToLinear(texelFetch(colortex3, texelCoord, 0).rgb) * eyeBrightnessSmoothCurved;
		#endif
	#endif

	float bloomGuide = 0.0;
	#ifdef TITLE
		bloomGuide = title(color);
	#endif

	color = LinearToCurve(color);

	compositeOutput1 = vec4(color, bloomGuide);


	vec4 data2 = texelFetch(colortex2, texelCoord, 0);

	vec2 texel = floor(gl_FragCoord.xy);

	if (texel == vec2(0.0, screenSize.y - 1.0)){
		float avgExposure = GetExposureTiles();
		#ifdef SMOOTH_EXPOSURE
			float prevAvgExposure = data2.a;
			#ifdef IS_IRIS
				float frameTimeFixed = frameTime + step(frameTime, 0.0) * 5.0;
				float exposureTime = saturate((step(avgExposure, prevAvgExposure) * 2.0 + 1.0) * frameTimeFixed / EXPOSURE_TIME);
			#else
				float exposureTime = saturate((step(avgExposure, prevAvgExposure) * 2.0 + 1.0) * frameTime / EXPOSURE_TIME);
			#endif
			avgExposure = mix(prevAvgExposure, avgExposure, exposureTime);
		#endif
		data2.a = avgExposure;
	}

	#ifdef TITLE
		if (texel == vec2(20.0, screenSize.y - 1.0)){
			float preAlpha = data2.a;
			float newAlpha = preAlpha + min(frameTime, 0.5) * 0.05;
			data2.a = saturate(newAlpha);
		}
	#endif

	#if defined VOLUMETRIC_CLOUDS && defined CLOUD_SHADOW
		if (texel == vec2(40.0, screenSize.y - 1.0)){
			data2.a = mix(data2.a, CloudShadowFromTex(vec3(0.0)), 2.0 * frameTime);
		}
	#endif

	#if defined DOF && CAMERA_FOCUS_MODE == 0
		if (texel == vec2(60.0, screenSize.y - 1.0)){
			ivec2 centerTexelCoord = ivec2(screenSize * 0.5);
			float prevCenterDepth = data2.a * 0.125 + 0.875;

			float centerDepth = texelFetch(depthtex0, centerTexelCoord, 0).x;
			#ifdef DISTANT_HORIZONS
				if (centerDepth == 1.0){
					centerDepth = texelFetch(dhDepthTex0, centerTexelCoord, 0).x;
					centerDepth = ScreenDepth_From_DHScreenDepth(centerDepth);
				}
			#endif
			centerDepth = max(centerDepth, 0.875);

			float f = exp2(-frameTime * 10.0 / DOF_DEPTH_SMMOOTH_HALFLIFE);
			float centerMaterialID = floor(texelFetch(colortex5, centerTexelCoord, 0).b * 255.0);
			#ifdef DOF_FOCUS_IGNORE_HAND_PARTICLE
				if (heldItemId != 358.0 && centerMaterialID == MATID_HAND || centerMaterialID == MATID_PARTICLE) f = 1.0;
			#endif

			data2.a = saturate(mix(centerDepth, prevCenterDepth, f) * 8.0 - 7.0);
		}
	#endif

	compositeOutput2 = data2;
}
