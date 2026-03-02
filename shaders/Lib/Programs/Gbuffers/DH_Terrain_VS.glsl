//DH_Terrain_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 dhProjection;
uniform vec2 taaJitter;


out vec3 color;
out vec3 viewPos;
out vec3 viewNormal;
out vec2 blockLight;
flat out float materialIDs;



void main(){
	vec4 v_viewPos = gl_ModelViewMatrix * gl_Vertex;
	viewPos = v_viewPos.xyz;
	gl_Position = dhProjection * v_viewPos;

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	color = gl_Color.rgb;
	viewNormal = normalize(gl_NormalMatrix * gl_Normal);
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	blockLight = saturate(lmcoord * 1.103449 - 0.0689656);

	materialIDs = 1.0;

	switch(dhMaterialId){
	//3 leaves
		case DH_BLOCK_LEAVES:
			materialIDs = MATID_LEAVES;
			break;
		case DH_BLOCK_SNOW:
			materialIDs = MATID_LEAVES + 0.1;
			break;
	//26 lava
		case DH_BLOCK_LAVA:
			materialIDs = MATID_LAVA;
			break;
	//27 glowstone and lamp
		case DH_BLOCK_ILLUMINATED:
			materialIDs = MATID_GLOWSTONE;
			break;
	}

	if (materialIDs == 1.0 && blockLight.x > 0.93) materialIDs = MATID_GLOWSTONE;
}
