#version 330 compatibility

#define DIMENSION_END

uniform sampler2D colortex0;
uniform vec2 screenSize;
uniform vec2 pixelSize;

#include "/Lib/Settings.glsl"
#include "/Lib/IndividualFounctions/PrintFloat.glsl"

vec3 RRTAndODTFit(vec3 v){
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (v + 0.4329510) + 0.238081;
	return a / b;
}

vec3 LinearToGamma(vec3 color){
	return pow(color, vec3(1.0 / 2.2));
}

vec3 ACES(vec3 color){
	color *= 1.4;
	color *= mat3(0.59719, 0.35458, 0.04823, 0.07600, 0.90834, 0.01566, 0.02840, 0.13383, 0.83777);
	color = RRTAndODTFit(color);
	color *= mat3(1.60475, -0.53108, -0.07367, -0.10208, 1.10813, -0.00605, -0.00327, -0.07276, 1.07602);
	return LinearToGamma(color);
}

void main(){
	ivec2 texelCoord = ivec2(gl_FragCoord.xy);
	vec2 texCoord = gl_FragCoord.xy * pixelSize;

	// In the End, composite.fsh writes directly to colortex0.
	// We read it here and output it to the screen with a basic tonemap.
	vec3 color = texelFetch(colortex0, texelCoord, 0).rgb;

	// Basic ACES tonemapping to avoid washed-out sky (Iteration's default)
	color = ACES(color);

	gl_FragData[0] = vec4(color, 0.0);
}
