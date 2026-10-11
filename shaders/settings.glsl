/*
--------------------------------------------------------------------------------

  OffShades - Settings
  
  Boolean options (on/off) can be disabled by inserting // before the #define
  and re-enabled by removing it.

  Value options can be adjusted by changing the value after the macro name.

--------------------------------------------------------------------------------
*/

#if !defined SETTINGS_INCLUDED
#define SETTINGS_INCLUDED

const int noiseTextureResolution = 512;

const bool shadowHardwareFiltering1 = true;
const int shadowMapResolution       = 2048; // [512 1024 1536 2048 3072 4096 8192]
const float shadowDistance          = 128.0; // [48.0 64.0 80.0 96.0 112.0 128.0 144.0 160.0 176.0 192.0 208.0 224.0 240.0 256.0 320.0 384.0 512.0]
const float shadowDistanceRenderMul = 1.0;
const float shadowIntervalSize      = 2.0;
const float sunPathRotation         = -35.0; // [-40.0 -39.0 -38.0 -37.0 -36.0 -35.0 -34.0 -33.0 -32.0 -31.0 -30.0 -29.0 -28.0 -27.0 -26.0 -25.0 -24.0 -23.0 -22.0 -21.0 -20.0 -19.0 -18.0 -17.0 -16.0 -15.0 -14.0 -13.0 -12.0 -11.0 -10.0 -9.0 -8.0 -7.0 -6.0 -5.0 -4.0 -3.0 -2.0 -1.0 0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0 31.0 32.0 33.0 34.0 35.0 36.0 37.0 38.0 39.0 40.0]
const float drynessHalflife         = 300.0;
const float wetnessHalflife         = 70.0;

// ---------
//   World
// ---------

  #define WAVING_PLANTS
  #define WAVING_LEAVES
//#define EDGE_HIGHLIGHT
  #define EDGE_HIGHLIGHT_SCALE 16.0 // [4.0 8.0 16.0 32.0 64.0 128.0 256.0]
  #define SLANTED_RAIN
  #define RAIN_OPACITY 0.25 // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.60 0.70 0.80 0.90 1.00]
  #define SNOW_OPACITY 0.75 // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.60 0.70 0.75 0.80 0.90 1.00]
  #define MOON_PHASE_AFFECTS_BRIGHTNESS
  #define DESERT_SANDSTORM
  #define SEA_LEVEL 63.0 // [-60.0 4.0 63.0]
  #define END_GLOW

// Weather

  #define RANDOM_WEATHER_VARIATION
  #define BIOME_WEATHER_VARIATION
  #define WEATHER_TEMPERATURE_BIAS 0.00 // [-1.00 -0.80 -0.60 -0.40 -0.20 0.00 0.20 0.40 0.60 0.80 1.00]
  #define WEATHER_HUMIDITY_BIAS 0.00 // [-1.00 -0.80 -0.60 -0.40 -0.20 0.00 0.20 0.40 0.60 0.80 1.00]
  #define WEATHER_WIND_BIAS 0.00 // [-1.00 -0.80 -0.60 -0.40 -0.20 0.00 0.20 0.40 0.60 0.80 1.00]
  #define WEATHER_TEMPERATURE_VARIATION_SPEED 1.0 // [0.1 0.2 0.5 1.0 1.5 2.0 3.0 4.0 5.0]
  #define WEATHER_HUMIDITY_VARIATION_SPEED 1.0 // [0.1 0.2 0.5 1.0 1.5 2.0 3.0 4.0 5.0]
  #define WEATHER_WIND_VARIATION_SPEED 1.0 // [0.1 0.2 0.5 1.0 1.5 2.0 3.0 4.0 5.0]

// ------------
//   Lighting
// ------------

//#define COLORED_LIGHTS
  #define COLORED_LIGHTS_VANILLA_LIGHTMAP_CONTRIBUTION
//#define HANDHELD_LIGHTING
  #define HANDHELD_LIGHTING_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
  #define CLOUD_SHADOWS
  #define CLOUD_SHADOWS_INTENSITY 0.80 // [0.00 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.00]
  #define VANILLA_AO
  #define AO_IN_SUNLIGHT
  #define SH_SKYLIGHT
  #define SSS_SHEEN
  #define SSS_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
  #define SHADING_STRENGTH 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
  #define LIGHTNING_FLASH

// Light Sources

  #define SUN_NR 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_NG 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_NB 1.00 // [0.00 0.25 0.50 0.75 1.00]

  #define SUN_MR 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_MG 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_MB 1.00 // [0.00 0.25 0.50 0.75 1.00]

  #define SUN_ER 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_EG 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define SUN_EB 1.00 // [0.00 0.25 0.50 0.75 1.00]

  #define SUN_I 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]

  #define MOON_R 0.75 // [0.00 0.25 0.50 0.75 1.00]
  #define MOON_G 0.83 // [0.00 0.25 0.50 0.75 1.00]
  #define MOON_B 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define MOON_I 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]

  #define BLOCKLIGHT_R 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define BLOCKLIGHT_G 0.75 // [0.00 0.25 0.50 0.75 1.00]
  #define BLOCKLIGHT_B 0.63 // [0.00 0.25 0.50 0.75 1.00]
  #define BLOCKLIGHT_I 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]

  #define SKYLIGHT_I 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
  #define BOUNCED_LIGHT_I 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
  #define CAVE_LIGHTING_I 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]

// Shadows

  #define SHADOW
//#define SHADOW_SSRT
  #define SHADOW_SSRT_STEPS 10 // [4 6 8 10 12 14 16 20 24]
  #define SHADOW_PCF
  #define SHADOW_COLOR
  #define SHADOW_VPS
  #define SHADOW_PENUMBRA_SCALE 1.0 // [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
  #define ENTITY_SHADOWS
//#define BLOCK_ENTITY_SHADOWS
//#define PIXELATED_SHADOWS
  #define PIXELATED_SHADOWS_RESOLUTION 16 // [4 8 16 32 64 128 256]
  #define SSS_STEPS 12 // [4 6 8 10 12 16 20 24]

  #define SHADOW_PCF_STEPS_MIN           6 // [4 6 8 12 16 20 24]
  #define SHADOW_PCF_STEPS_MAX          12 // [6 8 12 16 20 24 32]
  #define SHADOW_PCF_STEPS_SCALE       1.0 // [0.0 0.5 1.0 1.5 2.0]
  #define SHADOW_BLOCKER_SEARCH_RADIUS 0.5 // [0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0]

  #define SHADOW_DEPTH_SCALE 0.2
  #define SHADOW_DISTORTION 0.85

// Ambient Occlusion

  #define SHADER_AO_NONE 0 
  #define SHADER_AO_SSAO 1 
  #define SHADER_AO_GTAO 2 
  #define SHADER_AO SHADER_AO_SSAO // [SHADER_AO_NONE SHADER_AO_SSAO SHADER_AO_GTAO]

  #define SSAO_STEPS 12 // [4 6 8 10 12 16 20 24 32]
  #define SSAO_RADIUS 2.0 // [0.5 1.0 1.5 2.0 2.5 3.0 4.0 5.0]

  #define GTAO_SLICES 2 // [1 2 3 4]
  #define GTAO_HORIZON_STEPS 3 // [1 2 3 4 5 6]
  #define GTAO_RADIUS 2.0 // [0.5 1.0 1.5 2.0 2.5 3.0 4.0 5.0]

// Colored Lights Settings

  #define VOXEL_VOLUME_SIZE 128 // [64 96 128 192 256 512]
  
  #define VOXEL_VOLUME_CENTER_AHEAD 0
  #define VOXEL_VOLUME_CENTER_PLAYER 1
  #define VOXEL_VOLUME_CENTER VOXEL_VOLUME_CENTER_AHEAD // [VOXEL_VOLUME_CENTER_AHEAD VOXEL_VOLUME_CENTER_PLAYER]

// -----------------
//   Sky & Clouds
// -----------------

// Clouds (Complementary Reimagined Volumetric Box Clouds)

  #define VOLUMETRIC_CLOUDS
  #define CLOUD_ALTITUDE 160.0 // [64.0 96.0 128.0 144.0 160.0 176.0 192.0 208.0 224.0 256.0 288.0 320.0]
  #define CLOUD_THICKNESS 4.2 // [2.0 2.5 3.0 3.5 4.0 4.2 4.5 5.0 5.5 6.0 7.0 8.0]
  #define CLOUD_ROUNDNESS 0.125 // [0.000 0.050 0.100 0.125 0.150 0.200 0.250 0.300 0.400 0.500]
  #define CLOUD_SPEED 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00]
  #define CLOUD_SAMPLES 14 // [6 8 10 12 14 16 18 20 24 28 32]
//#define BLOCKY_CLOUDS

// Internal Cloud Constants (Cloud shadows & background pipeline compatibility)
  #define CLOUDS_SCALE 1.0
  #define CLOUDS_AERIAL_PERSPECTIVE_BOOST 0
  #define CLOUDS_CUMULUS
  #define CLOUDS_CUMULUS_ALTITUDE 800.0
  #define CLOUDS_CUMULUS_THICKNESS 0.35
  #define CLOUDS_CUMULUS_COVERAGE 1.00
  #define CLOUDS_CUMULUS_DETAIL_STRENGTH 1.00
  #define CLOUDS_CUMULUS_DENSITY 1.00
  #define CLOUDS_CUMULUS_WIND_SPEED 20.0
  #define CLOUDS_CUMULUS_WIND_ANGLE 45.0
  #define CLOUDS_CUMULUS_SIZE 1.00
  #define CLOUDS_CUMULUS_PRIMARY_STEPS_H 16
  #define CLOUDS_CUMULUS_PRIMARY_STEPS_Z 16
  #define CLOUDS_CUMULUS_LIGHTING_STEPS 4
  #define CLOUDS_CUMULUS_AMBIENT_STEPS 2
  #define CLOUDS_ALTOCUMULUS
  #define CLOUDS_ALTOCUMULUS_ALTITUDE 3000.0
  #define CLOUDS_ALTOCUMULUS_THICKNESS 0.35
  #define CLOUDS_ALTOCUMULUS_COVERAGE 1.00
  #define CLOUDS_ALTOCUMULUS_DETAIL_STRENGTH 1.00
  #define CLOUDS_ALTOCUMULUS_DENSITY 1.00
  #define CLOUDS_ALTOCUMULUS_SIZE 1.00
  #define CLOUDS_ALTOCUMULUS_WIND_SPEED 40.0
  #define CLOUDS_ALTOCUMULUS_WIND_ANGLE 45.0
  #define CLOUDS_ALTOCUMULUS_PRIMARY_STEPS_H 16
  #define CLOUDS_ALTOCUMULUS_PRIMARY_STEPS_Z 16
  #define CLOUDS_ALTOCUMULUS_LIGHTING_STEPS 4
  #define CLOUDS_ALTOCUMULUS_AMBIENT_STEPS 2
  #define CLOUDS_CIRRUS
  #define CLOUDS_CIRRUS_LIGHTING_STEPS 2
  #define CLOUDS_CIRRUS_AMBIENT_STEPS 1
  #define CLOUDS_CIRRUS_ALTITUDE 6000.0
  #define CLOUDS_CIRRUS_THICKNESS 0.35
  #define CLOUDS_CIRRUS_DENSITY 1.00
  #define CLOUDS_CIRRUS_COVERAGE 1.00
  #define CLOUDS_CIRRUS_SIZE 1.00
  #define CLOUDS_CIRRUS_DETAIL_STRENGTH 1.00
  #define CLOUDS_CIRRUS_CURL_STRENGTH 1.00
  #define CLOUDS_CIRRUS_WIND_SPEED 60.0
  #define CLOUDS_CIRRUS_WIND_ANGLE 45.0
  #define CLOUDS_CIRROCUMULUS_DENSITY 1.00
  #define CLOUDS_CIRROCUMULUS_COVERAGE 1.00
  #define CLOUDS_CIRROCUMULUS_SIZE 1.00
  #define CLOUDS_CIRROCUMULUS_DETAIL_STRENGTH 1.00
  #define CLOUDS_CIRROCUMULUS_CURL_STRENGTH 1.00
  #define CLOUDS_NOCTILUCENT 
  #define CLOUDS_NOCTILUCENT_INTENSITY 1.00
  #define CLOUDS_NOCTILUCENT_RARITY 0.70
  #define CLOUDS_CUMULUS_CONGESTUS
  #define CLOUDS_CUMULUS_CONGESTUS_ALTITUDE 800.0
  #define CLOUDS_CUMULUS_CONGESTUS_THICKNESS 3.0
  #define CLOUDS_CUMULUS_CONGESTUS_COVERAGE 1.00
  #define CLOUDS_CUMULUS_CONGESTUS_DETAIL_STRENGTH 1.00
  #define CLOUDS_CUMULUS_CONGESTUS_DENSITY 1.00
  #define CLOUDS_CUMULUS_CONGESTUS_SIZE 1.00
  #define CLOUDS_CUMULUS_CONGESTUS_PRIMARY_STEPS 16
  #define CLOUDS_CUMULUS_CONGESTUS_LIGHTING_STEPS 4
  #define CLOUDS_CUMULUS_CONGESTUS_AMBIENT_STEPS 2
  #define CLOUDS_TEMPORAL_UPSCALING 1
  #define CLOUDS_ACCUMULATION_LIMIT 20

// Sun, Moon & Stars

  #define SUN_ANGULAR_RADIUS 2.0 // [0.5 1.0 1.5 2.0 2.5 3.0 4.0 5.0]
  #define MOON_ANGULAR_RADIUS 3.0 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0 5.0]
//#define VANILLA_SUN
//#define VANILLA_MOON

  #define STARS
  #define STARS_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define STARS_COVERAGE 0.50 // [0.10 0.25 0.50 0.75 1.00]

// Galaxy & Atmosphere

//#define GALAXY
  #define GALAXY_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]

  #define ATMOSPHERE_SATURATION_BOOST 
  #define ATMOSPHERE_SATURATION_BOOST_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CREPUSCULAR_RAYS
  #define CREPUSCULAR_RAYS_INTENSITY 0.75 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define CREPUSCULAR_RAYS_STEPS_HORIZON 20 // [8 12 16 20 24 32 40]
  #define CREPUSCULAR_RAYS_STEPS_ZENITH 4 // [2 4 6 8]
  #define RAINBOWS

// Aurora

  #define AURORA_NEVER  1
  #define AURORA_RARELY 2
  #define AURORA_ALWAYS 3

  #define AURORA_NORMAL AURORA_NEVER // [AURORA_NEVER AURORA_RARELY AURORA_ALWAYS]
  #define AURORA_SNOW AURORA_RARELY // [AURORA_NEVER AURORA_RARELY AURORA_ALWAYS]
  #define AURORA_BRIGHTNESS 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define AURORA_FREQUENCY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
  #define AURORA_CLOUD_LIGHTING 0.40 // [0.00 0.20 0.40 0.60 0.80 1.00]
  #define AURORA_GROUND_LIGHTING 0.10 // [0.00 0.10 0.20 0.30 0.40 0.50]

// ---------------------------
//   Nether (Solas Inspired)
// ---------------------------

//#define NETHER_VL
  #define NETHER_SMOKE_STEPS 18 // [6 8 10 12 14 16 18 20 24 28 32]
  #define NETHER_SMOKE_STRENGTH 1.00 // [0.00 0.20 0.40 0.60 0.80 1.00 1.20 1.40 1.60 1.80 2.00]
  #define NETHER_SMOKE_SPEED 1.00 // [0.20 0.40 0.60 0.80 1.00 1.20 1.40 1.60 1.80 2.00 2.50 3.00]
  #define NETHER_FOG_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
  #define NETHER_USE_BIOME_COLOR
  #define NETHER_R 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define NETHER_G 0.25 // [0.00 0.25 0.50 0.75 1.00]
  #define NETHER_B 0.05 // [0.00 0.25 0.50 0.75 1.00]
  #define NETHER_I 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define NETHER_S 0.75 // [0.00 0.25 0.50 0.75 1.00]

// ------------------------------
//   End (IterationT Inspired)
// ------------------------------

  #define END_COSMIC_SKY
  #define END_PLANETS
  #define END_ORBITS
  #define END_LENS_FLARE
  #define END_LENS_FLARE_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define SATURN_REVOLUTION_TIME 300 // [10 15 20 30 45 60 90 120 180 240 300 450 600 900 1200 1800 2700 3600]
  #define PLANETS_REVOLUTION_TIME 120 // [10 15 20 30 45 60 90 120 180 240 300 450 600 900 1200 1800 2700 3600]
  #define END_LIGHT_R 1.00 // [0.00 0.25 0.50 0.75 1.00]
  #define END_LIGHT_G 0.95 // [0.00 0.25 0.50 0.75 1.00]
  #define END_LIGHT_B 0.90 // [0.00 0.25 0.50 0.75 1.00]
  #define END_LIGHT_I 1.15 // [0.00 0.25 0.50 0.75 1.00 1.15 1.25 1.50 2.00]
  #define END_AMBIENT_R 0.25 // [0.00 0.25 0.50 0.75 1.00]
  #define END_AMBIENT_G 0.28 // [0.00 0.25 0.50 0.75 1.00]
  #define END_AMBIENT_B 0.40 // [0.00 0.25 0.50 0.75 1.00]
  #define END_AMBIENT_I 0.22 // [0.00 0.10 0.22 0.30 0.40 0.50 0.75 1.00]

// -------------------------
//   Fog & Atmosphere (OW)
// -------------------------

  #define VL
  #define VL_RENDER_SCALE 0.50
  #define OVERWORLD_FOG_INTENSITY 0.50 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]

//#define LPV_VL
  #define LPV_VL_STEPS 24 // [8 12 16 20 24 28 32]
  #define LPV_VL_INTENSITY_OVERWORLD 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
  #define LPV_VL_INTENSITY_UNDERGROUND 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
  #define LPV_VL_INTENSITY_NETHER 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
  #define LPV_VL_INTENSITY_END 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
//#define AIR_FOG_COLORED_LIGHT_SHAFTS
  #define BORDER_FOG
  #define CAVE_FOG
  #define BLOOMY_FOG
  #define BLOOMY_FOG_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]

// Rayleigh & Mie
  #define AIR_FOG_RAYLEIGH_DENSITY        0.0007 // [0.0001 0.0003 0.0005 0.0007 0.0010 0.0020]
  #define AIR_FOG_RAYLEIGH_R              0.20
  #define AIR_FOG_RAYLEIGH_G              0.55
  #define AIR_FOG_RAYLEIGH_B              1.00
  #define AIR_FOG_RAYLEIGH_DENSITY_RAIN   0.0020
  #define AIR_FOG_RAYLEIGH_R_RAIN         0.80
  #define AIR_FOG_RAYLEIGH_G_RAIN         0.90
  #define AIR_FOG_RAYLEIGH_B_RAIN         1.00
  #define AIR_FOG_RAYLEIGH_DENSITY_ARID   0.0003
  #define AIR_FOG_RAYLEIGH_R_ARID         0.70
  #define AIR_FOG_RAYLEIGH_G_ARID         0.75
  #define AIR_FOG_RAYLEIGH_B_ARID         1.00
  #define AIR_FOG_RAYLEIGH_DENSITY_SNOWY  0.0010
  #define AIR_FOG_RAYLEIGH_R_SNOWY        0.80
  #define AIR_FOG_RAYLEIGH_G_SNOWY        0.90
  #define AIR_FOG_RAYLEIGH_B_SNOWY        1.00
  #define AIR_FOG_RAYLEIGH_DENSITY_TAIGA  0.0010
  #define AIR_FOG_RAYLEIGH_R_TAIGA        0.65
  #define AIR_FOG_RAYLEIGH_G_TAIGA        0.85
  #define AIR_FOG_RAYLEIGH_B_TAIGA        1.00
  #define AIR_FOG_RAYLEIGH_DENSITY_JUNGLE 0.0012
  #define AIR_FOG_RAYLEIGH_R_JUNGLE       0.70
  #define AIR_FOG_RAYLEIGH_G_JUNGLE       0.95
  #define AIR_FOG_RAYLEIGH_B_JUNGLE       1.00
  #define AIR_FOG_RAYLEIGH_DENSITY_SWAMP  0.0014
  #define AIR_FOG_RAYLEIGH_R_SWAMP        0.67
  #define AIR_FOG_RAYLEIGH_G_SWAMP        1.00
  #define AIR_FOG_RAYLEIGH_B_SWAMP        0.94
  #define AIR_FOG_RAYLEIGH_DENSITY_PALE_GARDEN 0.03
  #define AIR_FOG_RAYLEIGH_R_PALE_GARDEN       0.90
  #define AIR_FOG_RAYLEIGH_G_PALE_GARDEN       0.80
  #define AIR_FOG_RAYLEIGH_B_PALE_GARDEN       1.00
  #define AIR_FOG_RAYLEIGH_FALLOFF_START  32.0
  #define AIR_FOG_RAYLEIGH_FALLOFF_HALF_LIFE 64.0

  #define AIR_FOG_MIE_DENSITY_MORNING   0.0070
  #define AIR_FOG_MIE_DENSITY_NOON      0.0001
  #define AIR_FOG_MIE_DENSITY_EVENING   0.0050
  #define AIR_FOG_MIE_DENSITY_MIDNIGHT  0.0050
  #define AIR_FOG_MIE_DENSITY_RAIN      0.030
  #define AIR_FOG_MIE_DENSITY_SNOW      0.015
  #define AIR_FOG_MIE_DENSITY_BLUE_HOUR 0.0020
  #define AIR_FOG_MIE_FALLOFF_START     32.0
  #define AIR_FOG_MIE_FALLOFF_HALF_LIFE 64.0

// -------------------------------------
//   Water (Complementary Reimagined)
// -------------------------------------

  #define WATER_BUMPINESS 0.75 // [0.00 0.10 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
  #define WATER_SPEED_MULT 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
  #define WATER_FOAM
  #define WATER_PARALLAX
  #define WATER_CAUSTICS
  #define WATER_CAUSTICS_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
  #define SNELLS_WINDOW
  #define BIOME_WATER_COLOR
  #define WATER_TEXTURE WATER_TEXTURE_HIGHLIGHT_UNDERGROUND // [WATER_TEXTURE_OFF WATER_TEXTURE_HIGHLIGHT WATER_TEXTURE_VANILLA WATER_TEXTURE_HIGHLIGHT_UNDERGROUND]
  #define WATER_TEXTURE_OFF 0
  #define WATER_TEXTURE_HIGHLIGHT 1
  #define WATER_TEXTURE_VANILLA 2
  #define WATER_TEXTURE_HIGHLIGHT_UNDERGROUND 3

  #define REFRACTION_OFF 0
  #define REFRACTION_ALL 1
  #define REFRACTION_WATER_ONLY 2
  #define WATER_REFRACTION REFRACTION_ALL // [REFRACTION_OFF REFRACTION_ALL REFRACTION_WATER_ONLY]
  #define WATER_REFRACTION_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]

  #define WATER_ABSORPTION_R 0.39 // [0.00 0.10 0.20 0.30 0.39 0.50 0.75 1.00]
  #define WATER_ABSORPTION_G 0.14 // [0.00 0.05 0.10 0.14 0.25 0.50 0.75 1.00]
  #define WATER_ABSORPTION_B 0.07 // [0.00 0.03 0.07 0.15 0.25 0.50 0.75 1.00]
  #define WATER_SCATTERING 0.01 // [0.00 0.01 0.02 0.05 0.10]

  #define WATER_ABSORPTION_R_UNDERWATER 0.20
  #define WATER_ABSORPTION_G_UNDERWATER 0.08
  #define WATER_ABSORPTION_B_UNDERWATER 0.04
  #define WATER_SCATTERING_UNDERWATER 0.03

// Internal Water Wave Constants (Vertex displacement & normals compatibility)
  #define WATER_DISPLACEMENT
  #define WATER_EDGE_HIGHLIGHT
  #define WATER_EDGE_HIGHLIGHT_INTENSITY 1.00
  #define WATER_WAVES
  #define WATER_WAVE_ITERATIONS 3
  #define WATER_WAVE_STRENGTH 1.00
  #define WATER_WAVE_FREQUENCY 1.00
  #define WATER_WAVE_SPEED_STILL 1.00
  #define WATER_WAVE_SPEED_FLOWING 1.00
  #define WATER_WAVE_PERSISTENCE 1.00
  #define WATER_WAVE_LACUNARITY 1.00
  #define WATER_WAVES_HEIGHT_VARIATION

// -------------
//   Materials
// -------------

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
  #define EMISSION_STRENGTH 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
//#define DIRECTIONAL_LIGHTMAPS
  #define DIRECTIONAL_LIGHTMAPS_INTENSITY 0.20 // [0.00 0.10 0.20 0.30 0.40 0.50 1.00]
  #define POM_DEPTH 0.25 // [0.05 0.10 0.15 0.20 0.25 0.30 0.40 0.50]
  #define POM_SAMPLES 40 // [16 24 32 40 48 64 96 128]
//#define POM_SHADOW
  #define POM_SHADOW_SAMPLES 40 // [16 24 32 40 48 64]
  #define POM_DISTANCE 32 // [8 16 24 32 48 64]

// Reflections

  #define ENVIRONMENT_REFLECTIONS
  #define SKY_REFLECTIONS
  #define SSR_ROUGHNESS_SUPPORT
  #define SSR_RAY_COUNT 4 // [1 2 4 6 8]
  #define SSR_INTERSECTION_STEPS_SMOOTH 16 // [8 12 16 20 24 32]
  #define SSR_INTERSECTION_STEPS_ROUGH 8 // [4 6 8 12 16]
  #define SSR_REFINEMENT_STEPS 4 // [0 2 4 6 8]
  #define SSR_ROUGHNESS_THRESHOLD 2.0 // [0.5 1.0 1.5 2.0 2.5 3.0]

// -------------------
//   Post-Processing
// -------------------

  #define BLOOM
  #define BLOOM_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
//#define DOF
  #define DOF_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
  #define DOF_SAMPLES 40 // [16 24 32 40 48 64]
  #define DOF_FOCUS -1.0 // [-1.0 1.0 2.0 5.0 10.0 20.0 30.0 50.0]
//#define MOTION_BLUR
  #define MOTION_BLUR_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
  #define TAA
  #define FXAA
//#define TAAU
  #define TAAU_RENDER_SCALE 0.75 // [0.50 0.60 0.67 0.75 0.80 0.90 1.00]
  #define CAS
  #define CAS_INTENSITY 0.50 // [0.00 0.20 0.35 0.50 0.65 0.80 1.00]
  #define VIGNETTE
  #define VIGNETTE_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]

// Color Grading & Exposure

  #define tonemap tonemap_lottes // [tonemap_aces_fit tonemap_aces_full tonemap_lottes tonemap_hejl_2015 tonemap_hejl_burgess tonemap_tech tonemap_uncharted_2 tonemap_ozius tonemap_reinhard tonemap_reinhard_jodie]
  #define GRADE_BRIGHTNESS 1.00 // [0.50 0.75 0.90 1.00 1.10 1.25 1.50]
  #define GRADE_CONTRAST   1.00 // [0.50 0.75 0.90 1.00 1.10 1.25 1.50]
  #define GRADE_SATURATION 1.00 // [0.00 0.50 0.75 0.90 1.00 1.10 1.25 1.50 2.00]
  #define GRADE_WHITE_BALANCE 6500 // [4500 5000 5500 6000 6500 7000 7500 8000]
  #define GRADE_ORANGE_SAT_BOOST 0.00 // [-0.30 -0.20 -0.10 0.00 0.10 0.20 0.30]
  #define GRADE_TEAL_SAT_BOOST 0.10 // [-0.30 -0.20 -0.10 0.00 0.10 0.20 0.30]
  #define GRADE_GREEN_SAT_BOOST 0.00 // [-0.30 -0.20 -0.10 0.00 0.10 0.20 0.30]
  #define GRADE_GREEN_HUE_SHIFT 0.0 // [-4.0 -2.0 0.0 2.0 4.0]
  #define PURKINJE_SHIFT
  #define PURKINJE_SHIFT_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]

  #define AUTO_EXPOSURE_OFF 0
  #define AUTO_EXPOSURE_SIMPLE 1
  #define AUTO_EXPOSURE_HISTOGRAM 2
  #define AUTO_EXPOSURE AUTO_EXPOSURE_OFF // [AUTO_EXPOSURE_OFF AUTO_EXPOSURE_SIMPLE AUTO_EXPOSURE_HISTOGRAM]
  #define AUTO_EXPOSURE_BIAS 0.0 // [-1.5 -1.0 -0.5 0.0 0.5 1.0 1.5]
  #define AUTO_EXPOSURE_MIN -1.0
  #define AUTO_EXPOSURE_MAX 0.0
  #define AUTO_EXPOSURE_RATE_DIM_TO_BRIGHT 2.0
  #define AUTO_EXPOSURE_RATE_BRIGHT_TO_DIM 1.0
  #define MANUAL_EXPOSURE_VALUE 0.0 // [-4.0 -3.0 -2.0 -1.0 0.0 1.0 2.0 3.0 4.0]
//#define MANUAL_EXPOSURE_USE_SCREEN_BRIGHTNESS
  #define HISTOGRAM_BINS 32 // [32 64 128]
  #define HISTOGRAM_TARGET 0.5 // [0.2 0.3 0.4 0.5 0.6 0.7]

// -----------------
//   Miscellaneous
// -----------------

  #define INFO 1 // [0 1 2 3]

  #define DEBUG_VIEW_NONE      0
  #define DEBUG_VIEW_SAMPLER   1
  #define DEBUG_VIEW_HISTOGRAM 2
  #define DEBUG_VIEW_WEATHER   3
  #define DEBUG_VIEW DEBUG_VIEW_NONE // [DEBUG_VIEW_NONE DEBUG_VIEW_SAMPLER DEBUG_VIEW_HISTOGRAM DEBUG_VIEW_WEATHER]
  #define DEBUG_SAMPLER colortex1 // [colortex1 colortex2 colortex3 colortex4 colortex5 colortex6 colortex7 colortex8 depthtex0 depthtex1 shadowtex0 shadowcolor0]
//#define WHITE_WORLD
//#define TONEMAP_COMPARISON
  #define tonemap_left tonemap_lottes
  #define tonemap_right tonemap_lottes
  #define FANCY_NETHER_PORTAL
//#define CUSTOM_SKY
  #define CUSTOM_SKY_BRIGHTNESS 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
  #define ENCHANTMENT_GLINT_BRIGHTNESS 1.00 // [0.00 0.25 0.50 0.75 1.00 1.50 2.00]
//#define DITHERED_TRANSLUCENCY_FALLBACK

// Compatibility
  #define USE_HALF_PRECISION_FP

// Distance View
//#define DISTANCE_VIEW
  #define DISTANCE_VIEW_DISTANCE 0
  #define DISTANCE_VIEW_DEPTH 1
  #define DISTANCE_VIEW_METHOD DISTANCE_VIEW_DISTANCE // [DISTANCE_VIEW_DISTANCE DISTANCE_VIEW_DEPTH]
  #define DISTANCE_VIEW_MAX_DISTANCE 16.0 // [4.0 8.0 16.0 32.0 64.0 128.0]

// Box
  #define BOX_MODE_NONE 0
  #define BOX_MODE_COLOR  1
  #define BOX_MODE_RAINBOW 2
  #define BOX_MODE BOX_MODE_NONE // [BOX_MODE_NONE BOX_MODE_COLOR BOX_MODE_RAINBOW]
  #define BOX_COLOR_R 1.0
  #define BOX_COLOR_G 1.0
  #define BOX_COLOR_B 1.0
  #define BOX_EMISSION 1.0
  #define BOX_LINE_WIDTH 2 // [1 2 3 4 5 8]

  #define DH_OVERDRAW_DISTANCE 16.0 // [0.0 8.0 16.0 24.0 32.0 48.0 64.0]
  #define DH_OVERDRAW_FADE_LENGTH 16.0 // [4.0 8.0 16.0 24.0 32.0]
  #define NOISE_ON_DH_TERRAIN

// -----------------------------------------------------------------------------
//   OptiFine / Iris decoy declarations for boolean parser detection
// -----------------------------------------------------------------------------

#ifdef VANILLA_AO
#endif
#ifdef CAVE_FOG
#endif
#ifdef ENTITY_SHADOWS
#endif
#ifdef BLOCK_ENTITY_SHADOWS
#endif
#ifdef DOF
#endif
#ifdef MOTION_BLUR
#endif
#ifdef SSR_ROUGHNESS_SUPPORT
#endif
#ifdef FANCY_NETHER_PORTAL
#endif
#ifdef PURKINJE_SHIFT
#endif
#ifdef COLORED_LIGHTS
#endif
#ifdef MOON_PHASE_AFFECTS_BRIGHTNESS
#endif
#ifdef VL  
#endif
#ifdef LPV_VL 
#endif
#ifdef CREPUSCULAR_RAYS 
#endif
#ifdef VOLUMETRIC_CLOUDS
#endif
#ifdef NETHER_VL
#endif
#ifdef END_COSMIC_SKY
#endif
#ifdef END_PLANETS
#endif
#ifdef END_ORBITS
#endif
#ifdef END_LENS_FLARE
#endif
#ifdef WATER_FOAM
#endif
#ifdef WATER_PARALLAX
#endif
#ifdef WATER_CAUSTICS
#endif

#if MC_VERSION >= 260100
  #define USE_SEPARATE_ENTITY_DRAWS
#endif

#endif // SETTINGS_INCLUDED