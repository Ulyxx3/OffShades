//Hand_Water_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform vec2 taaJitter;


out vec3 color;
out vec2 texCoord;
out vec3 viewPos;
out vec2 blockLight;


void main(){
	vec4 v_viewPos = gl_ModelViewMatrix * gl_Vertex;
	viewPos = v_viewPos.xyz;
	gl_Position = gl_ProjectionMatrix * v_viewPos;

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	color = gl_Color.rgb;
	texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	blockLight = saturate(lmcoord * 1.103449 - 0.0689656);
}
