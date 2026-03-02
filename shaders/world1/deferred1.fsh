#version 330


#define DIMENSION_MAIN


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* DRAWBUFFERS:7 */
layout(location = 0) out vec4 compositeOutput7;


#include "/Lib/IndividualFounctions/WaterWaves.glsl"


void main(){
    const float maxCausticsNormalHeight = CAUSTICS_TEX_RESOLUTION;

    vec3 screenCaustics = vec3(0.0, 0.0, 1.0);
    vec2 causticsCoord = gl_FragCoord.xy * (50.0 / min(screenSize.y, maxCausticsNormalHeight));

    //if (causticsCoord.x <= 50.0 && causticsCoord.y <= 50.0)
    screenCaustics = GetWavesNormal(vec3(causticsCoord.x, 1.0, causticsCoord.y), 25.0).xyz;


    compositeOutput7 = vec4(EncodeNormal(screenCaustics), 0.0, 0.0);
}
