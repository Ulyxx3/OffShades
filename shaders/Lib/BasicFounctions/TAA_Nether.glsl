

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

vec4 BicubicTextureVec4(sampler2D texSampler, vec2 coord, vec2 texSize){
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

	vec4 color = textureLod(texSampler, vec2(tc12.x, tc0.y ), 0.0) * (w12.x * w0.y ) +
				 textureLod(texSampler, vec2(tc0.x,  tc12.y), 0.0) * (w0.x  * w12.y) +
				 textureLod(texSampler, vec2(tc12.x, tc12.y), 0.0) * (w12.x * w12.y) +
				 textureLod(texSampler, vec2(tc3.x,  tc12.y), 0.0) * (w3.x  * w12.y) +
				 textureLod(texSampler, vec2(tc12.x, tc3.y ), 0.0) * (w12.x * w3.y );
	return color / (w12.x * w0.y + w0.x * w12.y + w12.x * w12.y + w3.x * w12.y + w12.x * w3.y);
}

vec4 SampleCurr(vec2 coord){
	vec4 curr = textureLod(colortex1, coord, 0.0);
	curr.rgb = RGB_To_YCoCg(curr.rgb);
	curr.a = LinearDepth_From_ScreenDepth(curr.a);
	return curr;
}

vec4 SampleCurrFetch(ivec2 coord){
	vec4 curr = texelFetch(colortex1, coord, 0);
	curr.rgb = RGB_To_YCoCg(curr.rgb);
	curr.a = LinearDepth_From_ScreenDepth(curr.a);
	return curr;
}

vec4 SampleCurrBicubic(vec2 coord){
	vec4 curr = BicubicTextureVec4(colortex1, coord, screenSize);
	curr.rgb = RGB_To_YCoCg(curr.rgb);
	curr.a = LinearDepth_From_ScreenDepth(curr.a);
	return curr;
}

vec2 SamplePreviousDepthBilinear(vec2 coord){
	coord = coord * screenSize - 0.5;

	vec2 f = fract(coord);
	ivec2 texel = ivec2(coord);

	vec2 s0 = Unpack2x16(texelFetch(colortex7, texel, 0).a);
	vec2 s1 = Unpack2x16(texelFetch(colortex7, texel + ivec2(1, 0), 0).a);
	vec2 s2 = Unpack2x16(texelFetch(colortex7, texel + ivec2(0, 1), 0).a);
	vec2 s3 = Unpack2x16(texelFetch(colortex7, texel + ivec2(1, 1), 0).a);

	return mix(mix(s0, s1, f.x), mix(s2, s3, f.x), f.y);
}

vec4 SamplePrevious(vec2 coord){
	#ifdef TAA_BICUBIC_PREVIOUS
		vec3 prevColor = RGB_To_YCoCg(BicubicTexture(colortex7, coord, screenSize));
	#else
		vec3 prevColor = RGB_To_YCoCg(textureLod(colortex7, coord, 0.0).rgb);
	#endif
	float prevReferenceDepth = LinearDepth_From_ScreenDepth(SamplePreviousDepthBilinear(coord).x);
	return vec4(prevColor, prevReferenceDepth);
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
    return Unpack2x16(texelFetch(colortex7, coord, 0).a).y;
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

vec3 GetVariance3x3(ivec2 coord, vec3 currColor, out vec3 avgColor, out vec3 crossAvgColor, out vec2 referenceDepthMinMax){
	vec4 data0 = SampleCurrFetch(coord + ivec2(-1, -1));
	vec4 data1 = SampleCurrFetch(coord + ivec2( 0, -1));
	vec4 data2 = SampleCurrFetch(coord + ivec2( 1, -1));
	vec4 data3 = SampleCurrFetch(coord + ivec2(-1,  0));
	vec4 data4 = SampleCurrFetch(coord + ivec2( 0,  0));
	vec4 data5 = SampleCurrFetch(coord + ivec2( 1,  0));
	vec4 data6 = SampleCurrFetch(coord + ivec2(-1,  1));
	vec4 data7 = SampleCurrFetch(coord + ivec2( 0,  1));
	vec4 data8 = SampleCurrFetch(coord + ivec2( 1,  1));

	crossAvgColor = data1.rgb + data3.rgb + data4.rgb + data5.rgb + data7.rgb;
	avgColor = (crossAvgColor + data0.rgb + data2.rgb + data6.rgb + data8.rgb) / 9.0;
	crossAvgColor *= 0.2;
	vec3 m2 = (data0.rgb * data0.rgb + data1.rgb * data1.rgb + data2.rgb * data2.rgb + data3.rgb * data3.rgb + data4.rgb * data4.rgb + data5.rgb * data5.rgb + data6.rgb * data6.rgb + data7.rgb * data7.rgb + data8.rgb * data8.rgb) / 9.0;

	vec3 variance = sqrt(m2 - avgColor * avgColor) * TAA_AGGRESSION;

	vec3 minColor = min(avgColor - variance, currColor) * 0.5;
	vec3 maxColor = max(avgColor + variance, currColor) * 0.5;

	referenceDepthMinMax = vec2(min9(data0.a, data1.a, data2.a, data3.a, data4.a, data5.a, data6.a, data7.a, data8.a),
								max9(data0.a, data1.a, data2.a, data3.a, data4.a, data5.a, data6.a, data7.a, data8.a));

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

vec4 TemporalReprojection(vec2 coord, vec3 velocity, float currDepthMin, out float referenceDepth){
	vec2 unjitterCoord = coord + taaJitter * 0.5;

	#ifdef TAA_BICUBIC_CURRENT
		vec4 currData = SampleCurrBicubic(unjitterCoord);
	#else
		vec4 currData = SampleCurr(unjitterCoord);
	#endif

	vec3 currColor = currData.rgb;
	vec3 avgColor = currColor;
	vec3 crossAvgColor = currColor;
	vec2 referenceDepthMinMax = vec2(0.0);
	vec3 variance = GetVariance3x3(texelCoord, currData.rgb, avgColor, crossAvgColor, referenceDepthMinMax);

	coord -= velocity.xy;
	vec4 prevData = SamplePrevious(coord);
	vec3 prevColor = prevData.rgb;

	prevColor = clipAABB(avgColor, variance, prevColor);

	const float depthThreshold = 2e-5;
	prevData.a = clamp(prevData.a + velocity.z, referenceDepthMinMax.x - depthThreshold, referenceDepthMinMax.y + depthThreshold);

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
	referenceDepth = mix(currData.a, prevData.a, blendWeight);

	currColor = YCoCg_To_RGB(currColor);
	referenceDepth = ScreenDepth_From_LinearDepth(referenceDepth);
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
		vec4 projection = vec4(0.0);

		if (screenPos.z == 1.0){
			#ifdef TAA_CLOSEST_DEPTH
				screenPos.z = SampleCurrDepthDHFetchClosest3x3(texelCoord);
			#else
				screenPos.z = SampleDepthDHFetch(texelCoord);
			#endif

			projection = vec4(screenPos * 2.0 - 1.0, 1.0);

			projection = dhProjectionInverse * projection;
			projection.xyz /= projection.w;
			projection.xyz = mat3(gbufferModelViewInverse) * projection.xyz + gbufferModelViewInverse[3].xyz;

			if (screenPos.z < 1.0) projection.xyz += cameraPosition - previousCameraPosition;

			projection.xyz = mat3(gbufferPreviousModelView) * projection.xyz + gbufferPreviousModelView[3].xyz;
			projection.xyz = (vec3(dhPreviousProjection[0].x, dhPreviousProjection[1].y, dhPreviousProjection[2].z) * projection.xyz + dhPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;

			screenPos.z = ScreenDepth_From_DHScreenDepth(screenPos.z);
			projection.z = ScreenDepth_From_DHScreenDepth(projection.z);
			depth = saturate(screenPos.z);
		}else{
			projection = vec4(screenPos * 2.0 - 1.0, 1.0);

			projection.xyz = (vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * projection.xy, 0.0) + gbufferProjectionInverse[3].xyz) / (gbufferProjectionInverse[2].w * projection.z + gbufferProjectionInverse[3].w);

			if (depth < 0.7){
				projection.xyz += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
			}else{
				projection.xyz = mat3(gbufferModelViewInverse) * projection.xyz + gbufferModelViewInverse[3].xyz;
				projection.xyz += cameraPosition - previousCameraPosition;
				projection.xyz = mat3(gbufferPreviousModelView) * projection.xyz + gbufferPreviousModelView[3].xyz;
			}
			
			projection.xyz = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection.xyz + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;
		}
		
		velocity = screenPos - projection.xyz;
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

		float referenceDepth = 0.0;

		vec4 taa = vec4(0.0); 

		#ifdef DISABLE_HAND_TAA
		#endif
		#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
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
				taa = TemporalReprojection(texCoord, velocity, depth, referenceDepth);
			}

	#else

		vec4 taa = texelFetch(colortex1, texelCoord, 0);

		float referenceDepth = taa.a;

	#endif

	compositeOutput7 = vec4(saturate(taa.rgb), Pack2x16(saturate(vec2(referenceDepth, taa.a))));
}
