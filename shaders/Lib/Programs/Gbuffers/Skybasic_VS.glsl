//Skytextured_VS


out vec4 color;


void main(){
	gl_Position = ftransform();

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	color = gl_Color;
}