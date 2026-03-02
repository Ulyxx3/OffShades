//Line_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform vec2 screenSize;
uniform vec2 taaJitter;


flat out vec4 color;


const float LineWidth = 2.5;

const float VIEW_SHRINK = 1.0 - (1.0 / 256.0);
const mat4 VIEW_SCALE = mat4(
	VIEW_SHRINK, 0.0, 0.0, 0.0,
	0.0, VIEW_SHRINK, 0.0, 0.0,
	0.0, 0.0, VIEW_SHRINK, 0.0,
	0.0, 0.0, 0.0, 1.0
);


void main(){
	color = gl_Color;

	vec4 linePosStart = gl_ProjectionMatrix * VIEW_SCALE * gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);
	vec4 linePosEnd = gl_ProjectionMatrix * VIEW_SCALE * gl_ModelViewMatrix * vec4(gl_Vertex.xyz + gl_Normal, 1.0);

	vec3 ndc1 = linePosStart.xyz / linePosStart.w;
	vec3 ndc2 = linePosEnd.xyz / linePosEnd.w;

	vec2 lineScreenDirection = normalize((ndc2.xy - ndc1.xy) * screenSize);
	vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) * LineWidth / screenSize;

	lineOffset *= sign(lineOffset.x);

	if (gl_VertexID % 2 == 0){
		ndc1.xy += lineOffset;
	}else{
		ndc1.xy -= lineOffset;
	}

	gl_Position = vec4(ndc1 * linePosStart.w, linePosStart.w);

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif
}
