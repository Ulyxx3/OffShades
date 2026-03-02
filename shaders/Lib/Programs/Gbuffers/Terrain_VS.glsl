//Terrain_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D noisetex;


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float wetness;
uniform int renderStage;

uniform vec2 taaJitter;


attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;


out vec3 v_color;
out vec2 v_texCoord;
out vec3 v_viewPos;
#ifdef TERRAIN_VS_TBN
	attribute vec4 at_tangent;
	out mat3 v_tbn;
#endif
out vec2 v_blockLight;
flat out float v_materialIDs;


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
	#ifdef WHITE_DEBUG_WORLD
		#ifdef GTAO
			v_color = vec3(1.0);
		#else
			v_color = vec3(gl_Color.r, 0.0, gl_Color.a);
		#endif
	#else
		#ifdef GTAO
			v_color = gl_Color.rgb;
		#else
			v_color = gl_Color.rgb * gl_Color.a;
		#endif
	#endif
	v_texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	v_blockLight = saturate(lmcoord * 1.103449 - 0.0689656);

	if(mc_Entity.x == 213.0) v_blockLight.x = min(v_blockLight.x, 0.85);

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	v_viewPos = viewPos.xyz;
	vec4 worldPos = gbufferModelViewInverse * viewPos;
	worldPos.xyz += cameraPosition.xyz;

	#if !defined DIMENSION_END
	#ifdef WAVING_PLANTS
		float tick = frameTimeCounter * ANIMATION_SPEED;

		float lightWeight = saturate(v_blockLight.y * 1.5 - 0.5);
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
	#endif
	#endif

	worldPos.xyz -= cameraPosition.xyz;
	gl_Position = gl_ProjectionMatrix * gbufferModelView * worldPos;

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	#ifdef TERRAIN_VS_TBN
		vec3 N = normalize(gl_NormalMatrix * gl_Normal);
		vec3 T = normalize(gl_NormalMatrix * at_tangent.xyz);
		vec3 B = cross(T, N) * sign(at_tangent.w);
		v_tbn = mat3(T, B, N);
	#endif

	v_materialIDs = MATID_LAND;

	#ifdef MOD_BLOCK_SUPPORT
	#endif

	#ifdef GENERAL_GRASS_FIX
		vec3 an = abs(gl_Normal);
		if (all(lessThan(an, vec3(0.99)))){
			v_materialIDs = MATID_GRASS;
		}
	#endif

	switch(int(mc_Entity.x)){
	//2 grass
		case 7000: case 7010: case 7011: case 7020: case 7021: case 7040:
			v_materialIDs = MATID_GRASS;
			break;

		case 7030:
			v_materialIDs = MATID_LEAVES;
			break;

		case 89:
			v_materialIDs = MATID_GLOWSTONE;
			break;

		case 50:
			v_materialIDs = MATID_TORCH;
			break;

		case 10:
			v_materialIDs = MATID_LAVA;
			break;

		case 51:
			v_materialIDs = MATID_FIRE;
			break;

		case 76:
			v_materialIDs = MATID_REDSTONE_TORCH;
			break;

		case 55:
			v_materialIDs = MATID_REDSTONE;
			break;

		case 7100:
			v_materialIDs = MATID_SOULFIRE;
			break;

		case 7101:
			v_materialIDs = MATID_AMETHYST;

		case 7102:
			v_materialIDs = MATID_OXIDIZED_BULB;
	}
}
