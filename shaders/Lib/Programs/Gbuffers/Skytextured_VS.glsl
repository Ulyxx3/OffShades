//Skytextured_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform vec2 taaJitter;


out vec3 v_color;
out vec2 v_texCoord;


void main(){
	gl_Position = ftransform();

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	v_color = gl_Color.rgb;
	v_texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
}
