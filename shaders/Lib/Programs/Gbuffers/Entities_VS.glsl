//Block_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferProjection;
uniform float aspectRatio;

#if defined PROGRAM_ENTITIES && defined DISABLE_PLAYER_TAA_MOTION_BLUR
	uniform int entityId;
#endif

uniform vec2 taaJitter;


out vec4 color;
out vec2 texCoord;
out vec3 viewPos;
out vec2 blockLight;

#if (defined ENTITIES_VS_TBN && (defined PROGRAM_ENTITIES || defined PROGRAM_SPIDEREYES) && (MC_VERSION < 11500 || MC_VERSION > 11604)) || (defined PROGRAM_HAND && MC_VERSION < 11300)
	attribute vec4 at_tangent;
	out mat3 tbn;
#endif

#ifdef PROGRAM_BLOCK
	out vec4 portalCoord;
#endif


void main(){
	vec4 v_viewPos = gl_ModelViewMatrix * gl_Vertex;
	viewPos = v_viewPos.xyz;
	#ifdef PROGRAM_HAND
		#if HAND_FOV_MODE == 1
			mat4 handProjection = gbufferProjection;
			handProjection[2][2] *= MC_HAND_DEPTH;
			
			gl_Position = handProjection * v_viewPos;
		#elif HAND_FOV_MODE == 2
			mat4 handProjection = gbufferProjection;
			handProjection[1][1] = 1.0 / tan(HAND_FOV * (PI / 360.0));
			handProjection[0][0] = handProjection[1][1] / aspectRatio;
			handProjection[2][2] *= MC_HAND_DEPTH;
			
			gl_Position = handProjection * v_viewPos;
		#else
			gl_Position = gl_ProjectionMatrix * v_viewPos;
		#endif
	#else
		gl_Position = gl_ProjectionMatrix * v_viewPos;
	#endif

	#ifdef TAA
		#if defined PROGRAM_HAND
			#ifndef DISABLE_HAND_TAA
				gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
			#endif
		#elif defined PROGRAM_ENTITIES
			#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
				if(entityId != 7003)
			#endif
				gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
		#else
			gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
		#endif
	#endif

	color = gl_Color;
	texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	blockLight = saturate(lmcoord * 1.103449 - 0.0689656);

	#if !defined PROGRAM_BLOCK
		blockLight.x = min(blockLight.x, 0.85);
	#endif

	#if (defined ENTITIES_VS_TBN && (defined PROGRAM_ENTITIES || defined PROGRAM_SPIDEREYES) && (MC_VERSION < 11500 || MC_VERSION > 11604)) || (defined PROGRAM_HAND && MC_VERSION < 11300)
		vec3 N = normalize(gl_NormalMatrix * gl_Normal);
		vec3 T = normalize(gl_NormalMatrix * at_tangent.xyz);
		vec3 B = cross(T, N) * sign(at_tangent.w);
		tbn = mat3(T, B, N);
	#endif
	

	#ifdef PROGRAM_BLOCK
		portalCoord = gl_Position * 0.5;
		portalCoord.xy = vec2(portalCoord.x + portalCoord.w, portalCoord.y + portalCoord.w);
		portalCoord.zw = gl_Position.zw;
	#endif
}
