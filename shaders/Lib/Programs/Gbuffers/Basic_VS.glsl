//Basic_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform vec2 taaJitter;


flat out vec4 color;
out vec2 texCoord;
out vec3 normal;
out vec2 blockLight;
flat out float isLine;


void main(){
	gl_Position = ftransform();

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	color = gl_Color;
	texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
	normal = gl_NormalMatrix * gl_Normal;
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	blockLight = saturate(lmcoord * 1.103449 - 0.0689656);

	isLine = float(clamp(gl_MultiTexCoord1.xy, 0.0, 240.0) != gl_MultiTexCoord1.xy);
}
