/*
================================================================================
  OffShades — include/global.glsl
  Global uniforms, constants, and dimension macros shared by all programs.
================================================================================
*/

#ifndef GLOBAL_INCLUDED
#define GLOBAL_INCLUDED

#include "/settings.glsl"

// ============================================================
//   Mathematical Constants
// ============================================================

#define PI      3.14159265358979
#define TAU     6.28318530717959
#define HALF_PI 1.57079632679490
#define INV_PI  0.31830988618379
#define SQRT2   1.41421356237310
#define SQRT3   1.73205080756888
#define PHI     1.61803398874989

#define EPS 1e-5
#define INF 1e10

// ============================================================
//   Dimension Detection
// ============================================================

#if defined(WORLD_NETHER)
  #define DIM_NETHER
#elif defined(WORLD_END)
  #define DIM_END
#else
  #define DIM_OVERWORLD
#endif

// ============================================================
//   Gbuffer Render Targets
// ============================================================

// colortex0  : Scene color (HDR), reused across passes
// colortex1  : Albedo + AO (gbuffer)
// colortex2  : Normal (encoded) + Material ID
// colortex3  : Specular data (roughness, metalness, F0, emissive)
// colortex4  : Sky irradiance map (small buffer)
// colortex5  : TAA history
// colortex6  : AO result (half-res)
// colortex7  : Volumetric fog (half-res)
// colortex8  : Cloud shadow map (512x512)
// colortex9  : Cloud render (temporal upscaling buffer A)
// colortex10 : Cloud render (temporal upscaling buffer B)
// colortex11 : Bloom chain
// colortex12 : Misc scratch
// colortex13 : Translucent data (water, glass, particles)
// depthtex0  : Solid depth
// depthtex1  : Translucent depth (water, glass)
// shadowtex0 : Shadow map (hard)
// shadowtex1 : Shadow map (for colored translucent)
// shadowcolor0 : Colored shadow tint

// ============================================================
//   Uniforms
// ============================================================

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D       shadowcolor0;
uniform sampler2D       shadowcolor1;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform vec3  cameraPosition;
uniform vec3  previousCameraPosition;

uniform vec3  sunPosition;
uniform vec3  moonPosition;
uniform vec3  upPosition;
uniform vec3  shadowLightPosition;
uniform vec3  skyColor;
uniform vec3  fogColor;

uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float near;
uniform float far;

uniform float frameTimeCounter;
uniform int   frameCounter;
uniform int   worldTime;
uniform int   worldDay;
uniform int   moonPhase;

uniform float rainStrength;
uniform float wetness;
uniform float thunderStrength;

uniform float sunAngle;
uniform float shadowDistance;

uniform ivec2  eyeBrightness;
uniform ivec2  eyeBrightnessSmooth;
uniform float  eyeAltitude;
uniform bool   isEyeInWater;

// Injected by shaders.properties custom uniforms:
uniform vec2  view_res;
uniform vec2  view_pixel_size;
uniform vec2  taa_offset;
uniform vec3  sun_dir;
uniform vec3  moon_dir;
uniform vec3  light_dir;
uniform vec3  view_sun_dir;
uniform vec3  view_moon_dir;
uniform vec3  view_light_dir;

uniform float time_sunrise;
uniform float time_noon;
uniform float time_sunset;
uniform float time_midnight;
uniform float world_age;
uniform bool  daylight_cycle_enabled;

uniform float eye_blocklight;
uniform float eye_skylight;

uniform float moon_phase_brightness;
uniform float atmosphere_saturation_boost_amount;
uniform float lightning_flash_of;
uniform float lightning_flash_base;

uniform float biome_cave;
uniform float biome_arid;
uniform float biome_snowy;
uniform float biome_taiga;
uniform float biome_jungle;
uniform float biome_swamp;
uniform float biome_temperate;
uniform float biome_may_rain;
uniform float biome_may_snow;

// ============================================================
//   Helper Macros
// ============================================================

#define rcp(x) (1.0 / (x))
#define saturate(x) clamp(x, 0.0, 1.0)
#define linearstep(a, b, t) saturate(((t) - (a)) / ((b) - (a)))

// Screen-space UV from gl_FragCoord
#define screen_uv (gl_FragCoord.xy * view_pixel_size)

// Fast sRGB encode/decode
#define srgb_to_linear(c) pow(max(c, 0.0), vec3(2.2))
#define linear_to_srgb(c) pow(max(c, 0.0), vec3(1.0 / 2.2))

// Luminance (BT.709)
#define luminance(c) dot(c, vec3(0.2126, 0.7152, 0.0722))

#endif // GLOBAL_INCLUDED
