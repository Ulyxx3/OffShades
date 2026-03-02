//DH_Water_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelViewInverse;
uniform mat4 dhProjection;
uniform vec2 taaJitter;


out vec4 color;
out vec3 viewPos;
out mat3 tbn;
out vec2 blockLight;
flat out float materialIDs;


void main(){
	vec4 v_viewPos = gl_ModelViewMatrix * gl_Vertex;
	viewPos = v_viewPos.xyz;
	gl_Position = dhProjection * v_viewPos;

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	color = gl_Color;

	vec3 T = vec3(0.0);
	vec3 B = vec3(0.0);
	vec3 N = normalize(gl_NormalMatrix * gl_Normal);

	if (gl_Normal.x > 0.5) {
		//  1.0,  0.0,  0.0
		T = normalize(gl_NormalMatrix * vec3( 0.0,  0.0, -1.0));
		B = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.x < -0.5){
		// -1.0,  0.0,  0.0
		T = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
		B = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.y > 0.5){
		//  0.0,  1.0,  0.0
		T = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		B = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	} else if (gl_Normal.y < -0.5){
		//  0.0, -1.0,  0.0
		T = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		B = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	} else if (gl_Normal.z > 0.5){
		//  0.0,  0.0,  1.0
		T = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		B = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.z < -0.5){
		//  0.0,  0.0, -1.0
		T = normalize(gl_NormalMatrix * vec3(-1.0,  0.0,  0.0));
		B = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	tbn = mat3(T, B, N);

	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	blockLight = saturate(lmcoord * 1.103449 - 0.0689656);
	
	materialIDs = MATID_STAINEDGLASS;

	if (dhMaterialId == DH_BLOCK_WATER){
		materialIDs = MATID_WATER;
	}
}
