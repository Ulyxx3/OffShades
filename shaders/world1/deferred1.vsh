#version 330 compatibility


#define DIMENSION_MAIN


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


void main(){
    const float maxCausticsNormalHeight = CAUSTICS_TEX_RESOLUTION;

    vec2 texCoord = gl_Vertex.xy;
    texCoord *= screenSize * (1.0 / min(screenSize.y, maxCausticsNormalHeight));

	gl_Position = vec4(texCoord * 2.0 - 1.0, 0.0, 1.0);
}
