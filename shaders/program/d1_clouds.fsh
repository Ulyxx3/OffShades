/*
--------------------------------------------------------------------------------

  OffShades Shader (based on Photon by SixthSurge)

  program/d1_clouds:
  Render clouds (Complementary Reimagined style) and aurora (Photon)

  Cloud system: Complementary Reimagined r5.7.1 by EminGT
  Base shader:  Photon v1.2a by SixthSurge

--------------------------------------------------------------------------------
*/

#include "/include/global.glsl"

layout (location = 0) out vec4 clouds;
layout (location = 1) out vec2 clouds_data;

/* RENDERTARGETS: 9,10 */

in vec2 uv;

#if defined WORLD_OVERWORLD
flat in vec3 sun_color;
flat in vec3 moon_color;
flat in vec3 sky_color;

flat in float aurora_amount;
flat in mat2x3 aurora_colors;

#include "/include/sky/clouds/parameters.glsl"
flat in CloudsParameters clouds_params;
#endif

// ------------
//   Uniforms
// ------------

uniform sampler3D colortex6; // 3D bubbly worley noise
#define SAMPLER_WORLEY_BUBBLY colortex6
uniform sampler3D colortex7; // 3D swirley worley noise
#define SAMPLER_WORLEY_SWIRLEY colortex7

uniform sampler2D colortex8; // cloud shadow map

uniform sampler3D depthtex0; // atmospheric scattering LUT
uniform sampler2D depthtex1;

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float near;
uniform float far;

uniform int worldTime;
uniform float sunAngle;

uniform int frameCounter;
uniform float frameTimeCounter;

uniform int isEyeInWater;
uniform float eyeAltitude;
uniform float rainStrength;
uniform float wetness;

uniform vec3 light_dir;
uniform vec3 sun_dir;
uniform vec3 moon_dir;

uniform vec2 view_res;
uniform vec2 view_pixel_size;
uniform vec2 taa_offset;

uniform float world_age;

uniform float time_sunrise;
uniform float time_noon;
uniform float time_sunset;
uniform float time_midnight;

uniform float biome_cave;
uniform float biome_temperate;
uniform float biome_arid;
uniform float biome_snowy;
uniform float biome_taiga;
uniform float biome_jungle;
uniform float biome_swamp;
uniform float biome_may_rain;
uniform float biome_may_snow;
uniform float biome_temperature;
uniform float biome_humidity;

// ------------
//   Includes
// ------------

#define ATMOSPHERE_SCATTERING_LUT depthtex0
#define MIE_PHASE_CLAMP

#if defined WORLD_OVERWORLD
#include "/include/sky/atmosphere.glsl"
#include "/include/sky/aurora.glsl"

// Complementary Reimagined Cloud System
#define DEFERRED1
#include "/include/clouds_cr/cr_clouds_integration.glsl"

#if defined CREPUSCULAR_RAYS && !defined BLOCKY_CLOUDS
#include "/include/sky/crepuscular_rays.glsl"
#endif
#endif

#include "/include/misc/distant_horizons.glsl"
#include "/include/utility/checkerboard.glsl"
#include "/include/utility/random.glsl"
#include "/include/utility/space_conversion.glsl"

// We still use checkerboard for cloud temporal upscaling
const int checkerboard_area = CLOUDS_TEMPORAL_UPSCALING * CLOUDS_TEMPORAL_UPSCALING;

float depth_max_4x4(sampler2D depth_sampler) {
	vec4 depth_samples_0 = textureGather(depth_sampler, uv * taau_render_scale + vec2( 2.0 * view_pixel_size.x,  2.0 * view_pixel_size.y));
	vec4 depth_samples_1 = textureGather(depth_sampler, uv * taau_render_scale + vec2(-2.0 * view_pixel_size.x,  2.0 * view_pixel_size.y));
	vec4 depth_samples_2 = textureGather(depth_sampler, uv * taau_render_scale + vec2( 2.0 * view_pixel_size.x, -2.0 * view_pixel_size.y));
	vec4 depth_samples_3 = textureGather(depth_sampler, uv * taau_render_scale + vec2(-2.0 * view_pixel_size.x, -2.0 * view_pixel_size.y));

	return max(
		max(max_of(depth_samples_0), max_of(depth_samples_1)),
		max(max_of(depth_samples_2), max_of(depth_samples_3))
	);
}

void main() {
	ivec2 texel = ivec2(gl_FragCoord.xy);

	clouds = vec4(0.0, 0.0, 0.0, 1.0);
	clouds_data = vec2(1e6, 0.0);

#if defined WORLD_OVERWORLD
	ivec2 checkerboard_pos = CLOUDS_TEMPORAL_UPSCALING * texel + clouds_checkerboard_offsets[frameCounter % checkerboard_area];

	vec2 new_uv = vec2(checkerboard_pos) / vec2(view_res) * rcp(float(taau_render_scale));

	// Get maximum depth from area covered by this fragment
	float depth_max = depth_max_4x4(depthtex1);

	vec3 screen_pos = vec3(new_uv, depth_max);
	vec3 view_pos   = screen_to_view_space(screen_pos, false);

	// Distant Horizons support
#ifdef DISTANT_HORIZONS
	float depth_dh = depth_max_4x4(dhDepthTex);
	bool is_dh_terrain = is_distant_horizons_terrain(depth_max, depth_dh);
	if (is_dh_terrain) {
		screen_pos = vec3(new_uv, depth_dh);
		view_pos   = screen_to_view_space(screen_pos, false, true);
	}
#else
	const bool is_dh_terrain = false;
#endif

	vec3 ray_dir = mat3(gbufferModelViewInverse) * normalize(view_pos);

	// Camera position in world space (approximate with eyeAltitude for Y)
	vec3 cam_world = vec3(cameraPosition.x, eyeAltitude, cameraPosition.z);

	float distance_to_terrain = (depth_max == 1.0 && !is_dh_terrain)
		? 1.0e8
		: length(view_pos) * CLOUDS_SCALE;

	// Sky / terrain sky fade
	float skyFade = (depth_max == 1.0 && !is_dh_terrain) ? 1.0 : 0.0;

	float VdotS = dot(ray_dir, sun_dir);
	float VdotU = dot(ray_dir, vec3(0.0, 1.0, 0.0));

	float dither = texelFetch(noisetex, ivec2(checkerboard_pos & 511), 0).b;
	      dither = r1(frameCounter / checkerboard_area, dither);

	// -------------------------------------------------------
	//  Complementary Reimagined Volumetric Clouds
	// -------------------------------------------------------
	float cloudLinearDepth = 1.0;

	vec4 cr_clouds = CR_GetVolumetricClouds(
		cloudAlt1i,          // cloud altitude
		4000.0,              // distance threshold (blocks)
		cloudLinearDepth,
		skyFade,
		sun_color,
		moon_color,
		sky_color,
		ray_dir,
		cam_world,
		distance_to_terrain,
		VdotS,
		VdotU,
		dither
	);

	// Convert CR result into Photon output buffers
	// CR returns: rgb=cloud color, a=cloud opacity (0=transparent, 1=opaque)
	// Photon expects: rgb=scattering, w=transmittance (0=opaque, 1=transparent)
	if (cr_clouds.a > 0.001) {
		float transmittance = 1.0 - cr_clouds.a;
		clouds.rgb = cr_clouds.rgb * cr_clouds.a;
		clouds.w   = transmittance;
		clouds_data.x = cloudLinearDepth * far;
		clouds_data.y = 0.0;
	}

	// Crepuscular rays (Photon, keep original)
#if defined CREPUSCULAR_RAYS && !defined BLOCKY_CLOUDS
	vec4 crepuscular = draw_crepuscular_rays(
		colortex8,
		ray_dir,
		distance_to_terrain > 0.0 && distance_to_terrain < 1.0e6,
		dither
	);
	clouds   *= crepuscular.w;
	clouds.rgb += crepuscular.xyz;
#endif

	// Aurora (Photon, keep original)
	clouds.xyz += draw_aurora(ray_dir, dither) * clouds.w;
#endif
}
