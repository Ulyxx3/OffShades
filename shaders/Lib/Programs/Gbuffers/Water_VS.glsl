//Water_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform vec2 taaJitter;


attribute vec4 mc_Entity;


out vec3 color;
out vec2 texCoord;
out vec3 viewPos;
#ifdef TERRAIN_VS_TBN
	attribute vec4 at_tangent;
	out mat3 tbn;
#endif
out vec2 blockLight;
flat out float materialIDs;


#define PHYSICS_OCEAN_SUPPORT
#define PHYSICS_VS
#ifdef PHYSICS_OCEAN
	#include "/Lib/IndividualFounctions/PhysicsOceans.glsl"
#endif


void main(){
	#ifdef PHYSICS_OCEAN
		physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;
		vec4 finalPosition = vec4(gl_Vertex.x, gl_Vertex.y + physics_waveHeight(gl_Vertex.xz, PHYSICS_ITERATIONS_OFFSET, physics_localWaviness, physics_gameTime), gl_Vertex.z, gl_Vertex.w);
		physics_localPosition = finalPosition.xyz;
		vec4 v_viewPos = gl_ModelViewMatrix * vec4(physics_localPosition, 1.0);
	#else
		vec4 v_viewPos = gl_ModelViewMatrix * gl_Vertex;
	#endif

	viewPos = v_viewPos.xyz;

	gl_Position = gl_ProjectionMatrix * v_viewPos;

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	color = gl_Color.rgb;
	texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);

	#ifdef TERRAIN_VS_TBN
		vec3 N = normalize(gl_NormalMatrix * gl_Normal);
		vec3 T = normalize(gl_NormalMatrix * at_tangent.xyz);
		vec3 B = cross(T, N) * sign(at_tangent.w);
		tbn = mat3(T, B, N);
	#endif

	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	blockLight = saturate(lmcoord * 1.103449 - 0.0689656);

	materialIDs = MATID_STAINEDGLASS;

	if(mc_Entity.x == 0.0){
		materialIDs = MATID_LAND;
		gl_Position.z -= 1e-4;
	}

	if(mc_Entity.x == 8.0){
		materialIDs = MATID_WATER;
	}

	if (mc_Entity.x == 79.0){
		materialIDs = MATID_ICE;
	}
}
