//Damagedblock_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform vec2 taaJitter;


out vec4 color;
out vec2 texCoord;


void main(){
	gl_Position = ftransform();

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	color = gl_Color;
	texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
}
