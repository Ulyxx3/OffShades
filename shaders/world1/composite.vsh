#version 330 compatibility


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#include "/Lib/Uniform/ShadowModelViewEnd.glsl"


out vec3 worldShadowVector;
out vec3 shadowVector;
out vec3 worldSunVector;

out vec3 colorTorchlight;


void main(){
    gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0.0, 1.0);

    worldShadowVector = shadowModelViewInverseEnd[2].xyz;
	shadowVector = mat3(gbufferModelView) * worldShadowVector;
    worldSunVector = worldShadowVector;

    colorTorchlight = Blackbody(TORCHLIGHT_COLOR_TEMPERATURE);
}
