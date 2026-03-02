//Shadow_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


const int shadowMapResolution = 2048; // [1024 2048 4096 8192 16384 32768]
const float shadowDistance = 192.0; // [64.0 96.0 128.0 192.0 256.0 384.0 512.0 768.0 1024.0 1536.0 2048.0]


uniform float far;

uniform sampler2D tex;


in vec2 texCoord;
in vec3 color;
in vec3 normal;
in vec2 blockLight;
in float tilted;

#ifdef PROGRAM_DH_SHADOW
	uniform vec3 cameraPosition;
	uniform mat4 shadowProjectionInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowModelViewInverse;
	uniform float pixelSize;

	#ifdef DIMENSION_END
		#include "/Lib/Uniform/ShadowModelViewEnd.glsl"
	#endif

	uniform int dhRenderDistance;

	in vec3 viewPos;
#endif


void main(){
	#ifdef PROGRAM_DH_SHADOW
		#ifdef DH_SHADOW_CULLING
			vec3 viewPosOrigin = viewPos;
			viewPosOrigin.z += 100.0;
			#ifdef DIMENSION_END		
				vec3 worldPosInterval = mat3(shadowModelViewInverseEnd) * viewPosOrigin;
			#else
				vec3 worldPosInterval = mat3(shadowModelViewInverse) * viewPosOrigin;
			#endif

			vec2 worldDist = vec2(length(worldPosInterval.xz), worldPosInterval.y);

			float clipDist = min(shadowDistance, far) * 0.7;
			#ifdef DH_SHADOW_FIX
				if (worldDist.x < clipDist && worldDist.y > -clipDist || normal.z <= 0.0) discard;
			#else
				if (worldDist.x < clipDist && worldDist.y > -clipDist) discard;
			#endif
		#else
			#ifdef DH_SHADOW_FIX
				if (normal.z <= 0.0) discard;
			#endif
		#endif

		#ifdef DH_SHADOW_FIX
			vec2 currNdcPos = gl_FragCoord.xy / float(shadowMapResolution) * 2.0 - 1.0;
			currNdcPos *= (1.0 - SHADOW_MAP_BIAS) / (0.95 - length(currNdcPos) * SHADOW_MAP_BIAS);
			vec2 currViewPos = currNdcPos * vec2(shadowProjectionInverse[0][0], shadowProjectionInverse[0][0]);

			float z = viewPos.z;

			z += dot(viewPos.xy - currViewPos, normal.xy) / normal.z; 
				
			gl_FragDepth = 0.5 - z * shadowProjection[0][0] * 0.25;
		#endif
	#elif 0
	#endif

	vec4 tex = textureLod(tex, texCoord, 0.0);
	tex.rgb *= color;

	#ifdef WHITE_DEBUG_WORLD
		tex.rgb = vec3(1.0);
	#endif

	if (!gl_FrontFacing && tilted == 0.0) tex.rgb = vec3(0.0);

	vec3 shadowNormal = normal.xyz;

	gl_FragData[0] = tex;
	gl_FragData[1] = vec4(shadowNormal.xyz * 0.5 + 0.5, blockLight.y);
}
