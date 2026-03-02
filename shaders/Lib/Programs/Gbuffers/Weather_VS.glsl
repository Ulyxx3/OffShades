//Weather_VS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;

uniform float eyeBrightnessOneSmooth;
uniform vec2 taaJitter;


out vec2 texCoord;


void main(){
	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	vec4 worldPos = gbufferModelViewInverse * viewPos;

	float angle = dot(worldPos.xyz + cameraPosition.xyz, vec3(3.0, 0.5, 3.0)) + frameTimeCounter * 0.2;
	vec2 rot = vec2(sin(angle), cos(angle));
	vec2 offset = (vec2(RAIN_WIND_X, RAIN_WIND_Z) + rot * RAIN_DISTURBANCE) * worldPos.y;

	worldPos.xz += eyeBrightnessOneSmooth * offset;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * worldPos;

	//#ifdef TAA
	//    gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	//#endif

	texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
}
