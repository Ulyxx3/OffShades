#version 330 compatibility
/*
================================================================================
  OffShades — world1/final.fsh
  End final output: vignette and film grain (tonemap done in composite.fsh).
================================================================================
*/
#define WORLD_END
#include "/include/global.glsl"

varying vec2 v_uv;

void main() {
    vec3 color = texture(colortex0, v_uv).rgb;

#ifdef VIGNETTE
    vec2  vc = v_uv * 2.0 - 1.0;
    float vg = 1.0 - VIGNETTE_INTENSITY * length(vc) * 0.5;
    color   *= max(vg, 0.0);
#endif

#ifdef FILM_GRAIN
    #ifndef FILM_GRAIN_STRENGTH
    #define FILM_GRAIN_STRENGTH 0.05
    #endif
    float grain = fract(sin(dot(gl_FragCoord.xy + float(frameCounter) * 17.4, vec2(12.9898, 78.233))) * 43758.5453);
    color      += (grain - 0.5) * FILM_GRAIN_STRENGTH;
#endif

    gl_FragColor = vec4(max(color, vec3(0.0)), 1.0);
}


