//Shadow_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


const float shadowDistance = 192.0; // [64.0 96.0 128.0 192.0 256.0 384.0 512.0 768.0 1024.0 1536.0 2048.0]


out vec2 texCoord;
out vec3 color;
out vec3 normal;
out vec2 blockLight;
out float tilted;
#ifdef PROGRAM_DH_SHADOW
	out vec3 viewPos;
#endif

#ifndef PROGRAM_DH_SHADOW
	attribute vec4 mc_Entity;
	#ifdef SHADOW_WAVING_PLANTS
		attribute vec4 mc_midTexCoord;
	#endif
#endif

uniform sampler2D noisetex;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float wetness;
uniform float far;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;

uniform int entityId;

#ifdef DH_SHADOW
#ifdef DISTANT_HORIZONS 
	uniform int dhRenderDistance;
#endif
#endif


#ifdef DIMENSION_END
	#include "/Lib/Uniform/ShadowModelViewEnd.glsl"
#endif


vec4 BicubicBlurTexture(sampler2D texSampler, vec2 coord){
	const float texPixelSize = 1.0 / 64.0;
	coord = coord * 64.0 - 0.5;

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
	c *= texPixelSize;

	vec2 m = s.xz / (s.xz + s.yw);
	return mix(mix(textureLod(noisetex, c.yw, 0.0), textureLod(noisetex, c.xw, 0.0), m.x),
			   mix(textureLod(noisetex, c.yz, 0.0), textureLod(noisetex, c.xz, 0.0), m.x),
			   m.y);
}



void main(){
	color = gl_Color.rgb;
	if (entityId == 7003) color.rgb = vec3(0.0);
	texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	blockLight = saturate(lmcoord * 1.103449 - 0.0689656);

	vec4 v_viewPos = gl_ModelViewMatrix * gl_Vertex;

	#ifdef PROGRAM_DH_SHADOW
		viewPos = v_viewPos.xyz;
	#endif

	#ifdef SHADOW_WAVING_PLANTS
	#if !defined PROGRAM_DH_SHADOW && !defined DIMENSION_END
	#ifdef WAVING_PLANTS
		vec4 worldPos = shadowModelViewInverse * v_viewPos;
		worldPos.xyz += cameraPosition;

		float tick = frameTimeCounter * ANIMATION_SPEED;

		float lightWeight = saturate(blockLight.y * 1.5 - 0.5);
			  lightWeight = lightWeight * lightWeight;
			  lightWeight = lightWeight * lightWeight;

		float grassWeight = step(gl_MultiTexCoord0.y, mc_midTexCoord.y);

		if (mc_Entity.x == 7020.0){
			grassWeight = grassWeight * 0.7;
		}else
		if (mc_Entity.x == 7021.0){
			grassWeight = grassWeight * 0.7 + 0.7;
		}


	//grass//
		if (mc_Entity.x == 7010.0 || mc_Entity.x == 7020.0 || mc_Entity.x == 7021.0){
			//heavy wind
			#define heavyAxialFrequency             8.0
			#define heavyAxialWaveLocalization      0.9
			#define heavyAxialRandomization         13.0
			#define heavyAxialAmplitude             15.0
			#define heavyAxialOffset                15.0

			#define heavyLateralFrequency           6.732
			#define heavyLateralWaveLocalization    1.274
			#define heavyLateralRandomization       1.0
			#define heavyLateralAmplitude           6.0
			#define heavyLateralOffset              0.0

			//light wind
			#define lightAxialFrequency             5.5
			#define lightAxialWaveLocalization      1.1
			#define lightAxialRandomization         21.0
			#define lightAxialAmplitude             5.0
			#define lightAxialOffset                5.0

			#define lightLateralFrequency           5.9732
			#define lightLateralWaveLocalization    1.174
			#define lightLateralRandomization       0.0
			#define lightLateralAmplitude           1.0
			#define lightLateralOffset              0.0

			float windStrength = mix(0.85, 1.0, wetness);

			vec2 pn = worldPos.xz;
				 pn.x *= 2.0;
				 pn.x -= tick * 15.0;
				 pn.y *= 8.0;

			float windStrengthRandom = BicubicBlurTexture(noisetex, pn / 640.0).x;
				  windStrengthRandom = mix(windStrengthRandom * windStrengthRandom, windStrengthRandom, wetness);
				  windStrength *= mix(windStrengthRandom, 0.5, wetness * 0.25);

			vec2 pn0 = worldPos.xz;
				 pn0.x -= tick / 3.0;

			float stoch = BicubicBlurTexture(noisetex, pn0 / 64.0).x;
			vec2 stochLarge = BicubicBlurTexture(noisetex, worldPos.xz / 384.0).xz;

			vec3 p = worldPos.xyz;
				 p.x += sin(p.z / 2.0) * 1.0;
				 p.xz += stochLarge.rg * 5.0;

			vec2 angleLight = vec2(sin(tick * lightAxialFrequency   - p.x * lightAxialWaveLocalization   + stoch * lightAxialRandomization)   * lightAxialAmplitude   + lightAxialOffset,
								   sin(tick * lightLateralFrequency - p.x * lightLateralWaveLocalization + stoch * lightLateralRandomization) * lightLateralAmplitude + lightLateralOffset);
			vec2 angleHeavy = vec2(sin(tick * heavyAxialFrequency   - p.x * heavyAxialWaveLocalization   + stoch * heavyAxialRandomization)   * heavyAxialAmplitude   + heavyAxialOffset,
								   sin(tick * heavyLateralFrequency - p.x * heavyLateralWaveLocalization + stoch * heavyLateralRandomization) * heavyLateralAmplitude + heavyLateralOffset);

			float windStrengthCrossfade = saturate(windStrength * 2.0 - 1.0);
			float lightWindFade = clamp(windStrength * 2.0, 0.2, 1.0);

			vec2 angle = mix(angleLight * lightWindFade, angleHeavy, vec2(windStrengthCrossfade)) * 2.0;

			worldPos.x +=  sin( angle.x            * (PI / 180.0))        * grassWeight * lightWeight * 0.5;
			worldPos.z +=  sin( angle.y            * (PI / 180.0))        * grassWeight * lightWeight * 0.5;
			worldPos.y += (cos((angle.x + angle.y) * (PI / 180.0)) - 1.0) * grassWeight * lightWeight * 0.5;
		}



	//Wheat//
		if (mc_Entity.x == 7011.0){
			#define speedWheat     0.1
			#define speedWheatLeaf 0.04
			{
				float magnitude = sin(tick * (PI / 28.0) + (worldPos.x + worldPos.z)) * 0.024 + 0.004;
					  magnitude *= grassWeight;
					  magnitude *= lightWeight;
				float d0 = sin(tick * (PI / speedWheat / 122.0)) * 3.0 - 1.5 + worldPos.z;
				float d1 = sin(tick * (PI / speedWheat / 152.0)) * 3.0 - 1.5 + worldPos.x;
				float d2 = sin(tick * (PI / speedWheat / 122.0)) * 3.0 - 1.5 + worldPos.x;
				float d3 = sin(tick * (PI / speedWheat / 152.0)) * 3.0 - 1.5 + worldPos.z;
				worldPos.x += sin((tick * PI / (28.0 * speedWheat)) + (worldPos.x + d0) * 0.1 + (worldPos.z + d1) * 0.1) * magnitude;
				worldPos.z += sin((tick * PI / (28.0 * speedWheat)) + (worldPos.z + d2) * 0.1 + (worldPos.x + d3) * 0.1) * magnitude;
			}

		//small leaf movement
			{
				float magnitude = sin(tick * (PI / 28.0) + (worldPos.x + worldPos.y) * 0.5) * 0.005 + 0.015;
					  magnitude *= grassWeight;
					  magnitude *= lightWeight;
				float d0 =    sin(tick * (PI / speedWheatLeaf / 112.0)) * 3.0 - 1.5;
				float d1 =    sin(tick * (PI / speedWheatLeaf / 142.0)) * 3.0 - 1.5;
				float d2 =    sin(tick * (PI / speedWheatLeaf / 112.0)) * 3.0 - 1.5;
				float d3 =    sin(tick * (PI / speedWheatLeaf / 142.0)) * 3.0 - 1.5;
				worldPos.x += sin(tick * (PI / speedWheatLeaf / 18.0) + (-worldPos.x + d0) * 1.6 + ( worldPos.z + d1) * 1.6) *  magnitude        * (1.0 + wetness * 2.0);
				worldPos.z += sin(tick * (PI / speedWheatLeaf / 18.0) + ( worldPos.z + d2) * 1.6 + (-worldPos.x + d3) * 1.6) *  magnitude        * (1.0 + wetness * 2.0);
				worldPos.y += sin(tick * (PI / speedWheatLeaf / 11.0) + ( worldPos.z + d2)       + ( worldPos.x + d3)      ) * (magnitude / 3.0) * (1.0 + wetness * 2.0);
			}
		}


	//Leaves//
		if (mc_Entity.x == 7030.0){
			#define speedLeaves 0.05

			float magnitude = sin(tick * (PI / speedLeaves / 28.0) + (worldPos.x + worldPos.z)) * 0.009 + 0.009;
				  magnitude *= lightWeight;
			float d0 =    sin(tick * (PI / speedLeaves / 112.0)) * 3.0 - 1.5;
			float d1 =    sin(tick * (PI / speedLeaves / 142.0)) * 3.0 - 1.5;
			float d2 =    sin(tick * (PI / speedLeaves / 132.0)) * 3.0 - 1.5;
			float d3 =    sin(tick * (PI / speedLeaves / 122.0)) * 3.0 - 1.5;
			worldPos.x += sin(tick * (PI / speedLeaves / 18.0) + (-worldPos.x + d0) * 1.6 + ( worldPos.z + d1) * 1.6) *  magnitude        * (1.0 + wetness * 1.0);
			worldPos.z += sin(tick * (PI / speedLeaves / 17.0) + ( worldPos.z + d2) * 1.6 + (-worldPos.x + d3) * 1.6) *  magnitude        * (1.0 + wetness * 1.0);
			worldPos.y += sin(tick * (PI / speedLeaves / 11.0) + ( worldPos.z + d2)       + ( worldPos.x + d3)      ) * (magnitude / 2.0) * (1.0 + wetness * 1.0);

		}

		worldPos.xyz -= cameraPosition;
		v_viewPos = shadowModelView * worldPos;
	#endif
	#endif
	#endif

	#ifdef DIMENSION_END
		v_viewPos = shadowModelViewEnd * shadowModelViewInverse * v_viewPos;
	#endif	

	gl_Position = v_viewPos;

	gl_Position.xyz *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);


	vec3 an = abs(gl_Normal);
	tilted = float(max(max(an.x, an.y), an.z) < 0.99);

	#ifdef PROGRAM_DH_SHADOW
		normal = gl_Normal;
	#else
		if (mc_Entity.x == 7000.0 || 
			mc_Entity.x == 7010.0 || 
			mc_Entity.x == 7011.0 || 
			mc_Entity.x == 7020.0 || 
			mc_Entity.x == 7021.0 || 
			mc_Entity.x == 7040.0){
			
			normal = vec3(0.0, 1.0, 0.0);
			tilted = 1.0;
		}else{
			normal = gl_Normal;
		}
	#endif


	#ifdef DIMENSION_END
		normal = normalize(mat3(shadowModelViewEnd) * normal);
	#else
		normal = normalize(gl_NormalMatrix * normal);
	#endif

	float dist = length(gl_Position.xy);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	gl_Position.xy *= 0.95 / distortFactor;
	

	#ifdef PROGRAM_DH_SHADOW
		if (dhMaterialId == DH_BLOCK_WATER) gl_Position.z = 2.0;
	#else
		if (mc_Entity.x == 8.0 || mc_Entity.x == 79.0) gl_Position.z = 2.0;
	#endif
}
