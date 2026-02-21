/*
================================================================================

  OffShades — settings.glsl
  User-facing shader settings. Toggle features with // or adjust values.

================================================================================
*/

#ifndef SETTINGS_INCLUDED
#define SETTINGS_INCLUDED

// ============================================================
//   Core Shadow / Sun Path
// ============================================================

const bool shadowHardwareFiltering1 = true;
const int   shadowMapResolution       = 2048; // [1024 1536 2048 3072 4096 6144 8192]
const float shadowDistance            = 192.0; // [64.0 80.0 96.0 128.0 160.0 192.0 224.0 256.0 320.0 384.0 512.0]
const float shadowDistanceRenderMul   = 1.0;
const float shadowIntervalSize        = 2.0;
const float sunPathRotation           = -35.0; // [-40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0]
const float drynessHalflife           = 300.0;
const float wetnessHalflife           = 70.0;
const int   noiseTextureResolution    = 512;

// ============================================================
//   World
// ============================================================

  #define WAVING_PLANTS
  #define WAVING_LEAVES
  #define WAVING_PLANT_SPEED 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define SLANTED_RAIN
  #define RAIN_OPACITY 0.25 // [0.00 0.10 0.15 0.20 0.25 0.30 0.40 0.50 0.75 1.00]
  #define SNOW_OPACITY 0.75 // [0.00 0.25 0.50 0.75 1.00]
  #define MOON_PHASE_AFFECTS_BRIGHTNESS
  #define SEA_LEVEL 63.0 // [-60.0 4.0 63.0]
  #define LIGHTNING_FLASH

// Weather

  #define RANDOM_WEATHER_VARIATION
  #define BIOME_WEATHER_VARIATION
  #define WEATHER_TEMPERATURE_BIAS 0.00 // [-1.00 -0.75 -0.50 -0.25 0.00 0.25 0.50 0.75 1.00]
  #define WEATHER_HUMIDITY_BIAS    0.00 // [-1.00 -0.75 -0.50 -0.25 0.00 0.25 0.50 0.75 1.00]
  #define WEATHER_WIND_BIAS        0.00 // [-1.00 -0.75 -0.50 -0.25 0.00 0.25 0.50 0.75 1.00]
  #define WEATHER_TEMPERATURE_VARIATION_SPEED 1.0 // [0.5 1.0 1.5 2.0]
  #define WEATHER_HUMIDITY_VARIATION_SPEED    1.0 // [0.5 1.0 1.5 2.0]
  #define WEATHER_WIND_VARIATION_SPEED        1.0 // [0.5 1.0 1.5 2.0]

// ============================================================
//   Lighting
// ============================================================

//#define HANDHELD_LIGHTING
  #define HANDHELD_LIGHTING_INTENSITY 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUD_SHADOWS
  #define CLOUD_SHADOWS_INTENSITY 0.80 // [0.00 0.20 0.40 0.60 0.80 1.00]
  #define VANILLA_AO
  #define AO_IN_SUNLIGHT
  #define SSS_SHEEN
  #define SSS_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define SHADING_STRENGTH 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define SH_SKYLIGHT

// Light Sources — Sun

  #define SUN_NR 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_NG 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_NB 1.00 // [0.00 0.25 0.50 0.75 1.00]

  #define SUN_MR 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_MG 0.85 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_MB 0.60 // [0.00 0.25 0.50 0.75 1.00]

  #define SUN_ER 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_EG 0.65 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_EB 0.30 // [0.00 0.25 0.50 0.75 1.00]

  #define SUN_I 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]

// Light Sources — Moon

  #define MOON_R 0.75 // [0.00 0.25 0.50 0.75 1.00]
  #define MOON_G 0.83 // [0.00 0.25 0.50 0.75 1.00]
  #define MOON_B 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define MOON_I 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]

// Light Sources — Block, Sky, Cave, Bounced

  #define BLOCKLIGHT_R 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define BLOCKLIGHT_G 0.75 // [0.00 0.25 0.50 0.75 1.00]
  #define BLOCKLIGHT_B 0.63 // [0.00 0.25 0.50 0.75 1.00]
  #define BLOCKLIGHT_I 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define SKYLIGHT_I      1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define BOUNCED_LIGHT_I 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CAVE_LIGHTING_I 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]

// Light Sources — Nether

  #define NETHER_USE_BIOME_COLOR
  #define NETHER_R 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define NETHER_G 0.25 // [0.00 0.25 0.50 0.75 1.00]
  #define NETHER_B 0.05 // [0.00 0.05 0.10 0.25 0.50 0.75 1.00]
  #define NETHER_I 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define NETHER_S 0.75 // [0.00 0.25 0.50 0.75 1.00]

// Light Sources — End

  #define END_LIGHT_R    1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define END_LIGHT_G    0.50 // [0.00 0.25 0.50 0.75 1.00]
  #define END_LIGHT_B    0.25 // [0.00 0.05 0.10 0.25 0.50 0.75 1.00]
  #define END_LIGHT_I    0.50 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define END_AMBIENT_R  0.75 // [0.00 0.25 0.50 0.75 1.00]
  #define END_AMBIENT_G  0.33 // [0.00 0.25 0.33 0.50 0.75 1.00]
  #define END_AMBIENT_B  1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define END_AMBIENT_I  0.75 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define END_GLOW

// ============================================================
//   Shadows
// ============================================================

  #define SHADOW
  #define SHADOW_PCF
  #define SHADOW_COLOR
  #define SHADOW_VPS
  #define SHADOW_PENUMBRA_SCALE 1.0 // [0.0 0.3 0.5 0.7 1.0 1.3 1.5 2.0]
  #define SHADOW_BLOCKER_SEARCH_RADIUS 1.0 // [0.5 0.7 1.0 1.5 2.0 3.0]
  #define ENTITY_SHADOWS
//#define BLOCK_ENTITY_SHADOWS
  #define SSS_STEPS 12 // [4 6 8 10 12 16 20 24]
  #define SHADOW_PCF_STEPS_MIN 4
  #define SHADOW_PCF_STEPS_MAX 16
  #define SHADOW_PCF_STEPS_SCALE 0.75
  #define SHADOW_DEPTH_SCALE 0.2
  #define SHADOW_DISTORTION   0.85

// ============================================================
//   Ambient Occlusion
// ============================================================

  #define SHADER_AO_NONE 0
  #define SHADER_AO_SSAO 1
  #define SHADER_AO_GTAO 2
  #define SHADER_AO SHADER_AO_GTAO // [SHADER_AO_NONE SHADER_AO_SSAO SHADER_AO_GTAO]

  #define SSAO_STEPS  12 // [4 6 8 10 12 16 20 24 32]
  #define SSAO_RADIUS 2.0 // [0.5 1.0 1.5 2.0 2.5 3.0 4.0 5.0]

  #define GTAO_SLICES       2 // [1 2 3 4 6 8]
  #define GTAO_HORIZON_STEPS 3 // [2 3 4 6 8]
  #define GTAO_RADIUS        2.0 // [0.5 1.0 1.5 2.0 2.5 3.0 4.0 5.0]

// ============================================================
//   Sky
// ============================================================

  #define ATMOSPHERE_SATURATION_BOOST
  #define ATMOSPHERE_SATURATION_BOOST_INTENSITY 1.00 // [0.00 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CREPUSCULAR_RAYS
  #define CREPUSCULAR_RAYS_INTENSITY       1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CREPUSCULAR_RAYS_STEPS_HORIZON   20   // [8 12 16 20 24 32]
  #define CREPUSCULAR_RAYS_STEPS_ZENITH     4   // [2 3 4 6 8]
  #define RAINBOWS
  #define END_SUN_EFFECT

// Aurora

  #define AURORA_NEVER  1
  #define AURORA_RARELY 2
  #define AURORA_ALWAYS 3
  #define AURORA_NORMAL AURORA_NEVER  // [AURORA_NEVER AURORA_RARELY AURORA_ALWAYS]
  #define AURORA_SNOW   AURORA_RARELY // [AURORA_NEVER AURORA_RARELY AURORA_ALWAYS]
  #define AURORA_BRIGHTNESS    1.00 // [0.25 0.50 0.75 1.00 1.50 2.00]
  #define AURORA_FREQUENCY     1.00 // [0.25 0.50 0.75 1.00 1.50 2.00]
  #define AURORA_CLOUD_LIGHTING 0.40 // [0.00 0.20 0.40 0.60 0.80 1.00]
  #define AURORA_GROUND_LIGHTING 0.10 // [0.00 0.05 0.10 0.20 0.40]

// ============================================================
//   Water
// ============================================================

  #define WATER_WAVE_COUNT 8 // [4 6 8 10 12 16]
  #define WATER_WAVE_AMPLITUDE 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
  #define WATER_WAVE_FREQUENCY 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]
  #define WATER_WAVE_SPEED 1.0     // [0.25 0.5 0.75 1.0 1.5 2.0]
  
  #define WATER_SSR
  #define WATER_SSR_STEPS 16 // [8 12 16 20 24 32 48 64]
  #define WATER_ROUGHNESS 0.02 // [0.0 0.01 0.02 0.03 0.05 0.1 0.2]
  
  #define WATER_COLOR_R 0.12 // [0.0 0.05 0.12 0.2 0.3 0.5]
  #define WATER_COLOR_G 0.40 // [0.0 0.15 0.3 0.4 0.5 0.6 0.8]
  #define WATER_COLOR_B 0.55 // [0.0 0.2 0.4 0.55 0.7 0.8 1.0]

// ============================================================
//   Stars
// ============================================================

  #define STARS
  #define STARS_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
  #define STARS_COVERAGE  0.50 // [0.10 0.25 0.40 0.50 0.65 0.80 1.00]

// Sun / Moon

  #define SUN_ANGULAR_RADIUS  2.0  // [0.5 1.0 1.5 2.0 2.5 3.0 4.0 5.0]
  #define MOON_ANGULAR_RADIUS 0.7  // [0.3 0.5 0.7 1.0 1.5 2.0]
//#define VANILLA_SUN
//#define VANILLA_MOON

// ============================================================
//   Clouds (Complementary-style volumetric)
// ============================================================

  #define CLOUDS_TEMPORAL_UPSCALING   4 // [1 2 3 4]
  #define CLOUDS_AERIAL_PERSPECTIVE_BOOST 1 // [0 1 2 3]
  #define CLOUDS_SCALE               10.0 // [5.0 8.0 10.0 12.0 15.0]

// Cumulus (main)

  #define CLOUDS_CUMULUS
  #define CLOUDS_CUMULUS_PRIMARY_STEPS_H    40  // [16 24 32 40 56 80]
  #define CLOUDS_CUMULUS_PRIMARY_STEPS_Z    20  // [8 12 16 20 28 40]
  #define CLOUDS_CUMULUS_LIGHTING_STEPS      6  // [3 4 6 8 12]
  #define CLOUDS_CUMULUS_AMBIENT_STEPS       2  // [1 2 3 4]
  #define CLOUDS_CUMULUS_ALTITUDE         1200.0 // [400.0 600.0 800.0 1000.0 1200.0 1500.0 2000.0 2500.0]
  #define CLOUDS_CUMULUS_THICKNESS          1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_CUMULUS_DENSITY            1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_CUMULUS_COVERAGE           1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_CUMULUS_SIZE               1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_CUMULUS_DETAIL_STRENGTH    1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_CUMULUS_WIND_SPEED        25.0  // [0.0 5.0 10.0 15.0 20.0 25.0 35.0 50.0]
  #define CLOUDS_CUMULUS_WIND_ANGLE        30.0  // [0.0 30.0 60.0 90.0 120.0 150.0 180.0 210.0 240.0 270.0 300.0 330.0]

// Altocumulus (mid-level)

  #define CLOUDS_ALTOCUMULUS
  #define CLOUDS_ALTOCUMULUS_PRIMARY_STEPS_H 12 // [6 8 10 12 16 20]
  #define CLOUDS_ALTOCUMULUS_PRIMARY_STEPS_Z  6 // [3 4 6 8 12]
  #define CLOUDS_ALTOCUMULUS_LIGHTING_STEPS   4 // [2 3 4 6 8]
  #define CLOUDS_ALTOCUMULUS_AMBIENT_STEPS    2 // [1 2 3 4]
  #define CLOUDS_ALTOCUMULUS_ALTITUDE      3200.0 // [1500.0 2000.0 2500.0 3000.0 3200.0 4000.0 5000.0]
  #define CLOUDS_ALTOCUMULUS_THICKNESS     0.15 // [0.05 0.10 0.15 0.20 0.30]
  #define CLOUDS_ALTOCUMULUS_DENSITY       0.10 // [0.05 0.10 0.15 0.20 0.30 0.50]
  #define CLOUDS_ALTOCUMULUS_COVERAGE      1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_ALTOCUMULUS_SIZE          1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_ALTOCUMULUS_DETAIL_STRENGTH 1.50 // [0.50 1.00 1.50 2.00]
  #define CLOUDS_ALTOCUMULUS_WIND_SPEED    25.0 // [0.0 10.0 20.0 25.0 35.0 50.0]
  #define CLOUDS_ALTOCUMULUS_WIND_ANGLE    60.0 // [0.0 30.0 60.0 90.0 120.0 150.0 180.0 210.0 240.0 270.0 300.0 330.0]

// Cirrus (high-level wispy)

  #define CLOUDS_CIRRUS
  #define CLOUDS_CIRRUS_LIGHTING_STEPS     6    // [3 4 6 8 12]
  #define CLOUDS_CIRRUS_ALTITUDE        6000.0  // [4000.0 5000.0 6000.0 7000.0 8000.0]
  #define CLOUDS_CIRRUS_DENSITY            0.50 // [0.10 0.25 0.50 0.75 1.00]
  #define CLOUDS_CIRRUS_COVERAGE           1.00 // [0.25 0.50 0.75 1.00 1.50 2.00]
  #define CLOUDS_CIRRUS_SIZE               1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_CIRRUS_WIND_SPEED        40.0  // [10.0 20.0 30.0 40.0 60.0 80.0]
  #define CLOUDS_CIRRUS_WIND_ANGLE        90.0  // [0.0 30.0 60.0 90.0 120.0 150.0 180.0 210.0 240.0 270.0 300.0 330.0]
  #define CLOUDS_CIRRUS_DETAIL_STRENGTH    1.00 // [0.25 0.50 0.75 1.00 1.50 2.00]
  #define CLOUDS_CIRRUS_CURL_STRENGTH      0.80 // [0.10 0.30 0.50 0.80 1.00 1.50 2.00]
  #define CLOUDS_CIRRUS_THICKNESS       1500.0
  #define CLOUDS_CIRROCUMULUS_DENSITY      1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_CIRROCUMULUS_COVERAGE     1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_CIRROCUMULUS_SIZE         1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]
  #define CLOUDS_CIRROCUMULUS_DETAIL_STRENGTH 1.00 // [0.25 0.50 0.75 1.00 1.50 2.00]
  #define CLOUDS_CIRROCUMULUS_CURL_STRENGTH   1.00 // [0.25 0.50 0.75 1.00 1.50 2.00]

// Noctilucent (polar night clouds)

  #define CLOUDS_NOCTILUCENT
  #define CLOUDS_NOCTILUCENT_INTENSITY 1.00 // [0.25 0.50 0.75 1.00 1.50 2.00]
  #define CLOUDS_NOCTILUCENT_RARITY    0.70 // [0.30 0.50 0.70 0.90 1.00]

// ============================================================
//   Fog
// ============================================================

  #define VL
  #define OVERWORLD_FOG_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define NETHER_FOG_INTENSITY    1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define VL_RENDER_SCALE         0.50 // [0.50 0.60 0.75 1.00]
  #define BORDER_FOG
  #define CAVE_FOG
//#define BLOOMY_FOG
  #define BLOOMY_FOG_INTENSITY    1.0  // [0.0 0.5 1.0 1.5 2.0]
  #define BLOOMY_RAIN
  #define AIR_FOG_CLOUDY_NOISE

// Rayleigh (scattering color by biome)

  #define AIR_FOG_RAYLEIGH_DENSITY        0.0005 // [0.0001 0.0003 0.0005 0.0007 0.0010]
  #define AIR_FOG_RAYLEIGH_R              0.31
  #define AIR_FOG_RAYLEIGH_G              0.67
  #define AIR_FOG_RAYLEIGH_B              1.00
  #define AIR_FOG_RAYLEIGH_FALLOFF_START  30.0 // [10.0 20.0 30.0 50.0 80.0 128.0]
  #define AIR_FOG_RAYLEIGH_FALLOFF_HALF_LIFE 30.0 // [10.0 20.0 30.0 50.0 80.0 128.0]

  #define AIR_FOG_RAYLEIGH_DENSITY_RAIN   0.0005
  #define AIR_FOG_RAYLEIGH_R_RAIN         0.31
  #define AIR_FOG_RAYLEIGH_G_RAIN         0.67
  #define AIR_FOG_RAYLEIGH_B_RAIN         1.00

  #define AIR_FOG_RAYLEIGH_DENSITY_ARID   0.0003
  #define AIR_FOG_RAYLEIGH_R_ARID         0.65
  #define AIR_FOG_RAYLEIGH_G_ARID         0.80
  #define AIR_FOG_RAYLEIGH_B_ARID         1.00

  #define AIR_FOG_RAYLEIGH_DENSITY_SNOWY  0.0010
  #define AIR_FOG_RAYLEIGH_R_SNOWY        0.50
  #define AIR_FOG_RAYLEIGH_G_SNOWY        0.81
  #define AIR_FOG_RAYLEIGH_B_SNOWY        1.00

  #define AIR_FOG_RAYLEIGH_DENSITY_TAIGA  0.0006
  #define AIR_FOG_RAYLEIGH_R_TAIGA        0.31
  #define AIR_FOG_RAYLEIGH_G_TAIGA        0.85
  #define AIR_FOG_RAYLEIGH_B_TAIGA        1.00

  #define AIR_FOG_RAYLEIGH_DENSITY_JUNGLE 0.0013
  #define AIR_FOG_RAYLEIGH_R_JUNGLE       0.40
  #define AIR_FOG_RAYLEIGH_G_JUNGLE       0.95
  #define AIR_FOG_RAYLEIGH_B_JUNGLE       1.00

  #define AIR_FOG_RAYLEIGH_DENSITY_SWAMP  0.0014
  #define AIR_FOG_RAYLEIGH_R_SWAMP        0.67
  #define AIR_FOG_RAYLEIGH_G_SWAMP        1.00
  #define AIR_FOG_RAYLEIGH_B_SWAMP        0.94

// Mie (particles / haze by time of day)

  #define AIR_FOG_MIE_DENSITY_MORNING   0.0070
  #define AIR_FOG_MIE_DENSITY_NOON      0.0001
  #define AIR_FOG_MIE_DENSITY_EVENING   0.0050
  #define AIR_FOG_MIE_DENSITY_MIDNIGHT  0.0050
  #define AIR_FOG_MIE_DENSITY_RAIN      0.030
  #define AIR_FOG_MIE_DENSITY_SNOW      0.015
  #define AIR_FOG_MIE_DENSITY_BLUE_HOUR 0.0020
  #define AIR_FOG_MIE_FALLOFF_START     7.0  // [1.0 3.0 5.0 7.0 10.0 15.0 20.0]
  #define AIR_FOG_MIE_FALLOFF_HALF_LIFE 7.0  // [1.0 3.0 5.0 7.0 10.0 15.0 20.0]

// ============================================================
//   Materials
// ============================================================

  #define TEXTURE_FORMAT_LAB 0
  #define TEXTURE_FORMAT_OLD 1
  #define TEXTURE_FORMAT TEXTURE_FORMAT_LAB // [TEXTURE_FORMAT_LAB TEXTURE_FORMAT_OLD]

//#define NORMAL_MAPPING
//#define SPECULAR_MAPPING
//#define POM
  #define HARDCODED_SPECULAR
  #define HARDCODED_EMISSION
  #define HARDCODED_SSS
  #define RAIN_PUDDLES
  #define EMISSION_STRENGTH 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]

  #define POM_SAMPLES     40 // [10 20 30 40 60 80]
  #define POM_DEPTH       0.25 // [0.05 0.10 0.15 0.20 0.25 0.30 0.40]
  #define POM_DISTANCE    32   // [8 16 24 32]
//#define POM_SHADOW
  #define POM_SHADOW_SAMPLES 40 // [10 20 30 40 60 80]
//#define POM_SLOPE_NORMALS

  #define REFRACTION_OFF        0
  #define REFRACTION_ALL        1
  #define REFRACTION_WATER_ONLY 2
  #define REFRACTION REFRACTION_ALL // [REFRACTION_OFF REFRACTION_ALL REFRACTION_WATER_ONLY]
  #define REFRACTION_INTENSITY 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]

// Reflections (SSR)

  #define ENVIRONMENT_REFLECTIONS
  #define SKY_REFLECTIONS
  #define SSR_ROUGHNESS_SUPPORT
  #define SSR_RAY_COUNT              4  // [1 2 3 4 6 8]
  #define SSR_INTERSECTION_STEPS_SMOOTH 16 // [4 8 12 16 20 24 32]
  #define SSR_INTERSECTION_STEPS_ROUGH   8 // [4 6 8 12 16]
  #define SSR_REFINEMENT_STEPS           4 // [0 1 2 3 4 6 8]
  #define SSR_ROUGHNESS_THRESHOLD      2.0 // [0.5 1.0 1.5 2.0 3.0 4.0]

// ============================================================
//   Water
// ============================================================

  #define WATER_TEXTURE_OFF                  0
  #define WATER_TEXTURE_HIGHLIGHT            1
  #define WATER_TEXTURE_VANILLA              2
  #define WATER_TEXTURE_HIGHLIGHT_UNDERGROUND 3
  #define WATER_TEXTURE WATER_TEXTURE_HIGHLIGHT_UNDERGROUND // [WATER_TEXTURE_OFF WATER_TEXTURE_HIGHLIGHT WATER_TEXTURE_VANILLA WATER_TEXTURE_HIGHLIGHT_UNDERGROUND]

  #define WATER_PARALLAX
  #define WATER_DISPLACEMENT
  #define WATER_EDGE_HIGHLIGHT
  #define WATER_EDGE_HIGHLIGHT_INTENSITY 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
//#define WATER_CAUSTICS
  #define WATER_CAUSTICS_INTENSITY 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
//#define SNELLS_WINDOW
  #define BIOME_WATER_COLOR

  #define WATER_WAVES
  #define WATER_ALPHA             0.65 // [0.25 0.50 0.65 0.75 0.85 1.00]
  #define WATER_WAVE_ITERATIONS   3    // [1 2 3 4 5 6 7 8]
  #define WATER_WAVE_STRENGTH     1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define WATER_WAVE_FREQUENCY    1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define WATER_WAVE_SPEED_STILL  1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define WATER_WAVE_SPEED_FLOWING 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define WATER_WAVE_PERSISTENCE  1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define WATER_WAVE_LACUNARITY   1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define WATER_WAVES_HEIGHT_VARIATION

// Water absorption / scattering coefficients

  #define WATER_ABSORPTION_R 0.39 // [0.00 0.10 0.20 0.30 0.39 0.50 0.65 0.80 1.00]
  #define WATER_ABSORPTION_G 0.14 // [0.00 0.05 0.10 0.14 0.20 0.30]
  #define WATER_ABSORPTION_B 0.07 // [0.00 0.03 0.05 0.07 0.10 0.15 0.20]
  #define WATER_SCATTERING   0.01 // [0.00 0.01 0.02 0.03 0.05 0.10]

  #define WATER_ABSORPTION_R_UNDERWATER 0.20 // [0.00 0.05 0.10 0.15 0.20 0.30 0.40]
  #define WATER_ABSORPTION_G_UNDERWATER 0.08 // [0.00 0.03 0.05 0.08 0.12 0.20]
  #define WATER_ABSORPTION_B_UNDERWATER 0.04 // [0.00 0.02 0.04 0.06 0.10]
  #define WATER_SCATTERING_UNDERWATER   0.03 // [0.00 0.01 0.02 0.03 0.05 0.10]
  #define WATER_DENSITY                 0.02 // [0.00 0.01 0.02 0.03 0.05 0.10 0.20]

// ============================================================
//   Post-Processing
// ============================================================

  #define BLOOM
  #define BLOOM_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define BLOOM_THRESHOLD 1.00 // [0.50 0.75 1.00 1.25 1.50 2.00 3.00 5.00]
  #define EXPOSURE 1.0 // [0.5 0.7 0.8 0.9 1.0 1.1 1.2 1.5 2.0]
  #define TONEMAP_MODE TONEMAP_ACES // [TONEMAP_ACES TONEMAP_REINHARD TONEMAP_UNCHARTED]

//#define DOF
  #define DOF_INTENSITY 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define DOF_SAMPLES   40   // [10 20 30 40 60 80]
  #define DOF_FOCUS     -1.0 // [-1.0 0.0 2.0 5.0 10.0 15.0 20.0 30.0 50.0]

//#define MOTION_BLUR
  #define MOTION_BLUR_INTENSITY 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]

  #define TAA
  #define FXAA
//#define TAAU
  #define TAAU_RENDER_SCALE 0.75 // [0.50 0.60 0.70 0.75 0.80 0.90 1.00]

  #define CAS
  #define CAS_INTENSITY 0.50 // [0.00 0.25 0.50 0.75 1.00]

  #define VIGNETTE
  #define VIGNETTE_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]

// Color Grading

  #define tonemap tonemap_lottes // [tonemap_aces_fit tonemap_aces_full tonemap_lottes tonemap_hejl_2015 tonemap_hejl_burgess tonemap_tech tonemap_uncharted_2 tonemap_ozius tonemap_reinhard tonemap_reinhard_jodie]
  #define GRADE_BRIGHTNESS     1.00 // [0.50 0.75 1.00 1.25 1.50]
  #define GRADE_CONTRAST       1.00 // [0.50 0.75 1.00 1.25 1.50]
  #define GRADE_SATURATION     1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define GRADE_WHITE_BALANCE  6500 // [4000 4500 5000 5500 6000 6500 7000 7500 8000]
  #define GRADE_ORANGE_SAT_BOOST 0.00 // [-0.50 -0.25 0.00 0.25 0.50]
  #define GRADE_TEAL_SAT_BOOST   0.10 // [-0.50 -0.25 0.00 0.10 0.25 0.50]
  #define GRADE_GREEN_SAT_BOOST  0.00 // [-0.50 -0.25 0.00 0.25 0.50]
  #define GRADE_GREEN_HUE_SHIFT  0.0  // [-8.0 -4.0 -2.0 0.0 2.0 4.0 8.0]
  #define PURKINJE_SHIFT
  #define PURKINJE_SHIFT_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]

// Exposure

  #define AUTO_EXPOSURE_OFF       0
  #define AUTO_EXPOSURE_SIMPLE    1
  #define AUTO_EXPOSURE_HISTOGRAM 2
  #define AUTO_EXPOSURE AUTO_EXPOSURE_OFF // [AUTO_EXPOSURE_OFF AUTO_EXPOSURE_SIMPLE AUTO_EXPOSURE_HISTOGRAM]
  #define AUTO_EXPOSURE_BIAS   0.0 // [-2.0 -1.5 -1.0 -0.5 0.0 0.5 1.0 1.5 2.0]
  #define AUTO_EXPOSURE_MIN   -1.0 // [-3.0 -2.0 -1.0 0.0]
  #define AUTO_EXPOSURE_MAX    0.0 // [-1.0 0.0 1.0 2.0 3.0]
  #define AUTO_EXPOSURE_RATE_DIM_TO_BRIGHT 2.0 // [0.5 1.0 2.0 3.0 5.0]
  #define AUTO_EXPOSURE_RATE_BRIGHT_TO_DIM 1.0 // [0.5 1.0 2.0 3.0 5.0]
  #define MANUAL_EXPOSURE_VALUE 0.0 // [-6.0 -4.0 -2.0 0.0 2.0 4.0 6.0 8.0]

// ============================================================
//   Miscellaneous
// ============================================================

  #define FANCY_NETHER_PORTAL
//#define CUSTOM_SKY
  #define CUSTOM_SKY_BRIGHTNESS      1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define ENCHANTMENT_GLINT_BRIGHTNESS 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]

  #define DEBUG_VIEW_NONE      0
  #define DEBUG_VIEW_SAMPLER   1
  #define DEBUG_VIEW_HISTOGRAM 2
  #define DEBUG_VIEW_WEATHER   3
  #define DEBUG_VIEW DEBUG_VIEW_NONE // [DEBUG_VIEW_NONE DEBUG_VIEW_SAMPLER DEBUG_VIEW_HISTOGRAM DEBUG_VIEW_WEATHER]
  #define DEBUG_SAMPLER colortex1 // [colortex1 colortex2 colortex3 colortex4 colortex5 colortex6 colortex7 colortex8 colortex9 colortex10 depthtex0 depthtex1 shadowtex0 shadowtex1 shadowcolor0 shadowcolor1]

//#define WHITE_WORLD
  #define USE_HALF_PRECISION_FP
  #define DITHERED_TRANSLUCENCY_FALLBACK

#endif // SETTINGS_INCLUDED
