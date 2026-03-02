

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* DRAWBUFFERS:7 */
layout(location = 0) out vec4 compositeOutput7;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;


#include "/Lib/Uniform/GbufferTransforms.glsl"



vec3 RGB_To_YCoCg(vec3 color) {
	return vec3(color.r * 0.25 + color.g * 0.5 + color.b * 0.25, color.r * 0.5 - color.b * 0.5, color.r * -0.25 + color.g * 0.5 + color.b * -0.25);
}

vec3 YCoCg_To_RGB(vec3 color) {
	float temp = color.r - color.b;
	return vec3(temp + color.g, color.r + color.b, temp - color.g);
}

vec3 BicubicTexture(sampler2D texSampler, vec2 coord, vec2 texSize){
	vec2 texPixelSize = 1.0 / texSize;
	coord = coord * texSize;

	vec2 p = floor(coord - 0.5) + 0.5;
	vec2 f = coord - p;
	vec2 f2 = f * f;
	vec2 f3 = f * f2;

	const float c = 0.5;
	vec2 w0 =        -c  * f3 +  2.0 * c         * f2 - c * f;
	vec2 w1 =  (2.0 - c) * f3 - (3.0 - c)        * f2         + 1.0;
	vec2 w2 = -(2.0 - c) * f3 + (3.0 -  2.0 * c) * f2 + c * f;
	vec2 w3 =         c  * f3 -                c * f2;

	vec2 w12 = w1 + w2;
	vec2 tc12 = texPixelSize * (p + w2 / w12);
	vec2 tc0 = texPixelSize * (p - 1.0);
	vec2 tc3 = texPixelSize * (p + 2.0);

	vec4 color = vec4(textureLod(texSampler, vec2(tc12.x, tc0.y ), 0.0).rgb, 1.0) * (w12.x * w0.y ) +
				 vec4(textureLod(texSampler, vec2(tc0.x,  tc12.y), 0.0).rgb, 1.0) * (w0.x  * w12.y) +
				 vec4(textureLod(texSampler, vec2(tc12.x, tc12.y), 0.0).rgb, 1.0) * (w12.x * w12.y) +
				 vec4(textureLod(texSampler, vec2(tc3.x,  tc12.y), 0.0).rgb, 1.0) * (w3.x  * w12.y) +
				 vec4(textureLod(texSampler, vec2(tc12.x, tc3.y ), 0.0).rgb, 1.0) * (w12.x * w3.y );
	return color.rgb / color.a;
}


vec3 SampleCurrColor(vec2 coord){
	return RGB_To_YCoCg(textureLod(colortex1, coord, 0.0).rgb);
}

vec3 SampleCurrColorFetch(ivec2 coord){
	return RGB_To_YCoCg(texelFetch(colortex1, coord, 0).rgb);
}

vec3 SampleCurrColorBicubic(vec2 coord){
	return RGB_To_YCoCg(BicubicTexture(colortex1, coord, screenSize));
}

vec3 SamplePrevColor(vec2 coord){
	#ifdef TAA_BICUBIC_PREVIOUS
		return RGB_To_YCoCg(BicubicTexture(colortex7, coord, screenSize));
	#else
		return RGB_To_YCoCg(textureLod(colortex7, coord, 0.0).rgb);
	#endif
}

float SampleDepthFetch(ivec2 coord){
	return texelFetch(depthtex0, coord, 0).x;
}

float SampleCurrDepthFetchClosest3x3(ivec2 coord){
	float depth0 = SampleDepthFetch(coord + ivec2(-1, -1));
	float depth1 = SampleDepthFetch(coord + ivec2( 0, -1));
	float depth2 = SampleDepthFetch(coord + ivec2( 1, -1));
	float depth3 = SampleDepthFetch(coord + ivec2(-1,  0));
	float depth4 = SampleDepthFetch(coord + ivec2( 0,  0));
	float depth5 = SampleDepthFetch(coord + ivec2( 1,  0));
	float depth6 = SampleDepthFetch(coord + ivec2(-1,  1));
	float depth7 = SampleDepthFetch(coord + ivec2( 0,  1));
	float depth8 = SampleDepthFetch(coord + ivec2( 1,  1));

	return min9(depth0, depth1, depth2, depth3, depth4, depth5, depth6, depth7, depth8);
}

float SamplePrevDepthFetch(ivec2 coord){
	return texelFetch(colortex7, coord, 0).w;
}

vec2 SamplePrevDepthMinMax3x3(vec2 prevCoord){
	ivec2 nearestTexel = ivec2(prevCoord * screenSize);
	float depth0 = SamplePrevDepthFetch(nearestTexel + ivec2(-1, -1));
	float depth1 = SamplePrevDepthFetch(nearestTexel + ivec2( 0, -1));
	float depth2 = SamplePrevDepthFetch(nearestTexel + ivec2( 1, -1));
	float depth3 = SamplePrevDepthFetch(nearestTexel + ivec2(-1,  0));
	float depth4 = SamplePrevDepthFetch(nearestTexel + ivec2( 0,  0));
	float depth5 = SamplePrevDepthFetch(nearestTexel + ivec2( 1,  0));
	float depth6 = SamplePrevDepthFetch(nearestTexel + ivec2(-1,  1));
	float depth7 = SamplePrevDepthFetch(nearestTexel + ivec2( 0,  1));
	float depth8 = SamplePrevDepthFetch(nearestTexel + ivec2( 1,  1));

	float depthMin = min9(depth0, depth1, depth2, depth3, depth4, depth5, depth6, depth7, depth8);
	float depthMax = max9(depth0, depth1, depth2, depth3, depth4, depth5, depth6, depth7, depth8);

	return vec2(depthMin, depthMax);
}

vec3 GetVariance3x3(ivec2 coord, vec3 currColor, out vec3 avgColor, out vec3 crossAvgColor){
	vec3 color0 = SampleCurrColorFetch(coord + ivec2(-1, -1));
	vec3 color1 = SampleCurrColorFetch(coord + ivec2( 0, -1));
	vec3 color2 = SampleCurrColorFetch(coord + ivec2( 1, -1));
	vec3 color3 = SampleCurrColorFetch(coord + ivec2(-1,  0));
	vec3 color4 = SampleCurrColorFetch(coord + ivec2( 0,  0));
	vec3 color5 = SampleCurrColorFetch(coord + ivec2( 1,  0));
	vec3 color6 = SampleCurrColorFetch(coord + ivec2(-1,  1));
	vec3 color7 = SampleCurrColorFetch(coord + ivec2( 0,  1));
	vec3 color8 = SampleCurrColorFetch(coord + ivec2( 1,  1));

	crossAvgColor = color1 + color3 + color4 + color5 + color7;
	avgColor = (crossAvgColor + color0 + color2 + color6 + color8) / 9.0;
	crossAvgColor *= 0.2;
	vec3 m2 = (color0 * color0 + color1 * color1 + color2 * color2 + color3 * color3 + color4 * color4 + color5 * color5 + color6 * color6 + color7 * color7 + color8 * color8) / 9.0;

	vec3 variance = sqrt(m2 - avgColor * avgColor) * TAA_AGGRESSION;

	vec3 minColor = min(avgColor - variance, currColor) * 0.5;
	vec3 maxColor = max(avgColor + variance, currColor) * 0.5;

	avgColor = minColor + maxColor;
	return maxColor - minColor;
}


vec3 clipAABB(vec3 avgColor, vec3 variance, vec3 prevColor){	
	#ifdef TAA_CLIP_TO_CENTER
		const float eps = 1e-20;
		vec3 p_clip = avgColor;
		vec3 e_clip = variance - eps;

		vec3 v_clip = prevColor - p_clip;
		vec3 v_unit = v_clip.xyz / e_clip;
		vec3 a_unit = abs(v_unit);
		float ma_unit = max3(a_unit.x, a_unit.y, a_unit.z);

		if (ma_unit > 1.0)
			return p_clip + v_clip / ma_unit;
		else
			return prevColor;
	#else
		vec3 diff = prevColor - avgColor;

		vec3 clipMax = mix(vec3(1.0), variance / diff, greaterThan(diff, variance));
		vec3 clipMin = mix(vec3(1.0), -variance / diff, lessThan(diff, -variance));
		diff *= clipMax.x * clipMax.y * clipMax.z * clipMin.x * clipMin.y * clipMin.z;

		return avgColor + diff;
	#endif
}

vec4 TemporalReprojection(vec2 coord, vec3 velocity, float currDepthMin){
	vec2 unjitterCoord = coord + taaJitter * 0.5;

	#ifdef TAA_BICUBIC_CURRENT
		vec3 currColor = SampleCurrColorBicubic(unjitterCoord);
	#else
		vec3 currColor = SampleCurrColor(unjitterCoord);
	#endif

	vec3 avgColor = currColor;
	vec3 crossAvgColor = currColor;
	vec3 variance = GetVariance3x3(texelCoord, currColor, avgColor, crossAvgColor);

	coord -= velocity.xy;
	vec3 prevColor = SamplePrevColor(coord);

	prevColor = clipAABB(avgColor, variance, prevColor);

	float blendWeight = TAA_BLENDWEIGHT;

	vec2 pixelVelocity = abs(fract(velocity.xy * screenSize) - 0.5) * 2.0;
	blendWeight *= sqrt(pixelVelocity.x * pixelVelocity.y) * 0.25 + 0.75;
	blendWeight *= float(saturate(coord) == coord);

	#ifdef TAA_DEPTH_COMPARE
		vec2 prevDepth = SamplePrevDepthMinMax3x3(coord);
		float currDist = LinearDepth_From_ScreenDepth(currDepthMin);
		float threshold = max(TAA_DEPTH_COMPARE_THRESHOLD - currDist / far * 0.2 * TAA_DEPTH_COMPARE_THRESHOLD, 1e-5);
		blendWeight *= step(prevDepth.x - currDepthMin + velocity.z, threshold);
		blendWeight *= step(currDepthMin - velocity.z - prevDepth.y, threshold);
	#endif

	#ifdef TAA_MICRO_BLUR
		currColor = mix(crossAvgColor, currColor, saturate(blendWeight * 5.0 - 0.5));
	#endif

	currColor = mix(currColor, prevColor, blendWeight);

	currColor = YCoCg_To_RGB(currColor);
	return vec4(currColor, currDepthMin);
}

#ifdef DISTANT_HORIZONS

float SampleDepthDHFetch(ivec2 coord){
	return texelFetch(dhDepthTex0, coord, 0).x;
}

float SampleCurrDepthDHFetchClosest3x3(ivec2 coord){
	float depth0 = SampleDepthDHFetch(coord + ivec2(-1, -1));
	float depth1 = SampleDepthDHFetch(coord + ivec2( 0, -1));
	float depth2 = SampleDepthDHFetch(coord + ivec2( 1, -1));
	float depth3 = SampleDepthDHFetch(coord + ivec2(-1,  0));
	float depth4 = SampleDepthDHFetch(coord + ivec2( 0,  0));
	float depth5 = SampleDepthDHFetch(coord + ivec2( 1,  0));
	float depth6 = SampleDepthDHFetch(coord + ivec2(-1,  1));
	float depth7 = SampleDepthDHFetch(coord + ivec2( 0,  1));
	float depth8 = SampleDepthDHFetch(coord + ivec2( 1,  1));

	return min9(depth0, depth1, depth2, depth3, depth4, depth5, depth6, depth7, depth8);
}

vec3 CalculateCameraVelocity(out float depth, float materialIDs){
	if (materialIDs == MATID_STAINEDGLASS || materialIDs == MATID_ICE){
		depth = texelFetch(depthtex1, texelCoord, 0).x;
	}else{
		#ifdef TAA_CLOSEST_DEPTH
			depth = SampleCurrDepthFetchClosest3x3(texelCoord);
		#else
			depth = SampleDepthFetch(texelCoord);
		#endif
	}

	vec3 velocity = vec3(0.0);

	if (materialIDs != MATID_END_PORTAL){
		vec3 screenPos = vec3(texCoord, depth);
		vec3 projection = vec3(0.0);

		if (screenPos.z == 1.0){
			#ifdef TAA_CLOSEST_DEPTH
				screenPos.z = SampleCurrDepthDHFetchClosest3x3(texelCoord);
			#else
				screenPos.z = SampleDepthDHFetch(texelCoord);
			#endif

			projection = vec3(screenPos * 2.0 - 1.0);

			projection = (vec3(vec2(dhProjectionInverse[0].x, dhProjectionInverse[1].y) * projection.xy, 0.0) + dhProjectionInverse[3].xyz) / (dhProjectionInverse[2].w * projection.z + dhProjectionInverse[3].w);

			projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;

			if (screenPos.z < 1.0) projection += cameraPosition - previousCameraPosition;

			projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
			projection = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;

			screenPos.z = ScreenDepth_From_DHScreenDepth(screenPos.z);
			projection.z = ScreenDepth_From_DHScreenDepth(projection.z);
			depth = saturate(screenPos.z);
		}else{
			projection = vec3(screenPos * 2.0 - 1.0);

			projection = (vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * projection.xy, 0.0) + gbufferProjectionInverse[3].xyz) / (gbufferProjectionInverse[2].w * projection.z + gbufferProjectionInverse[3].w);

			if (depth < 0.7){
				projection += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
			}else{
				projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
				projection += cameraPosition - previousCameraPosition;
				projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
			}
			
			projection = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;
		}
		
		velocity = screenPos - projection;
	}

	return velocity;
}
	
#else

vec3 CalculateCameraVelocity(out float depth, float materialIDs){
	if (materialIDs == MATID_STAINEDGLASS || materialIDs == MATID_ICE){
		depth = texelFetch(depthtex1, texelCoord, 0).x;
	}else{
		#ifdef TAA_CLOSEST_DEPTH
			depth = SampleCurrDepthFetchClosest3x3(texelCoord);
		#else
			depth = SampleDepthFetch(texelCoord);
		#endif
	}
	
	vec3 velocity = vec3(0.0);

	if (materialIDs != MATID_END_PORTAL){
		vec3 screenPos = vec3(texCoord, depth);
		vec3 projection = screenPos * 2.0 - 1.0;

		projection = (vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * projection.xy, 0.0) + gbufferProjectionInverse[3].xyz) / (gbufferProjectionInverse[2].w * projection.z + gbufferProjectionInverse[3].w);

		if (depth < 0.7){
			projection += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
		}else{
			projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
			if (depth < 1.0) projection += cameraPosition - previousCameraPosition;
			projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
		}
		
		projection = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;

		velocity = screenPos - projection;
	}
 
	return velocity;
}

#endif


void main(){
	#ifdef TAA
		float materialIDs = floor(texelFetch(colortex6, texelCoord, 0).b * 255.0);

		float depth = 1.0;
		vec3 velocity = CalculateCameraVelocity(depth, materialIDs);

		vec4 taa = vec4(0.0);

		#ifdef DISABLE_HAND_TAA
		#endif
		#ifdef DISABLE_HAND_GI
		#endif
		#ifdef DISABLE_HAND_GI_VELOCITY
		#endif
		#ifdef DISABLE_HAND_SPECULAR
		#endif
		#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
		#endif
		#ifdef DISABLE_PLAYER_GI
		#endif
		#ifdef DISABLE_PLAYER_GI_VELOCITY
		#endif
		#ifdef DISABLE_PLAYER_SCREEN_SPACE_SHADOWS
		#endif

		#if defined DISABLE_HAND_TAA && defined DISABLE_PLAYER_TAA_MOTION_BLUR
			if (materialIDs == MATID_HAND || materialIDs == MATID_ENTITIES_PLAYER){
				taa = texelFetch(colortex1, texelCoord, 0);
			}else
		#elif defined DISABLE_HAND_TAA
			if (materialIDs == MATID_HAND){
				taa = texelFetch(colortex1, texelCoord, 0);
			}else
		#elif defined DISABLE_PLAYER_TAA_MOTION_BLUR
			if (materialIDs == MATID_ENTITIES_PLAYER){
				taa = texelFetch(colortex1, texelCoord, 0);
			}else
		#endif
			{
				taa = TemporalReprojection(texCoord, velocity, depth);
			}

	#else

		vec4 taa = texelFetch(colortex1, texelCoord, 0);

	#endif

	compositeOutput7 = taa;
}
