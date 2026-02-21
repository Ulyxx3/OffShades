/*
================================================================================
  OffShades — world-1/final.fsh — Nether final output pass.
  Applies FXAA and vignette; tonemapping was done in composite.fsh.
================================================================================
*/
#define WORLD_NETHER
#include "/include/global.glsl"

varying vec2 v_uv;

void main() {
    vec3 color = texture(colortex0, v_uv).rgb;

    // Vignette
#ifdef VIGNETTE
    vec2 vc  = v_uv * 2.0 - 1.0;
    float vg = 1.0 - VIGNETTE_STRENGTH * pow(dot(vc * VIGNETTE_FALLOFF, vc), 1.5);
    color   *= vg;
#endif

    // Film grain
#ifdef FILM_GRAIN
    float grain = fract(sin(dot(gl_FragCoord.xy + float(frameCounter) * 17.4, vec2(12.9898, 78.233))) * 43758.5453);
    color      += (grain - 0.5) * FILM_GRAIN_STRENGTH;
#endif

    gl_FragColor = vec4(max(color, vec3(0.0)), 1.0);
}
