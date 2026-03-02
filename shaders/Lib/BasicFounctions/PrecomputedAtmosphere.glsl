#define TRANSMITTANCE_TEXTURE_WIDTH 256.0
#define TRANSMITTANCE_TEXTURE_HEIGHT 64.0

#define SCATTERING_TEXTURE_R_SIZE 32.0 //z
#define SCATTERING_TEXTURE_MU_SIZE 128.0 //y
#define SCATTERING_TEXTURE_MU_S_SIZE 32.0 //x
#define SCATTERING_TEXTURE_NU_SIZE 16.0 //x

#define COMBINED_TEXTURE_WIDTH 512.0
#define COMBINED_TEXTURE_HEIGHT 128.0
#define COMBINED_TEXTURE_DEPTH 33.0

#define IRRADIANCE_TEXTURE_WIDTH 64.0
#define IRRADIANCE_TEXTURE_HEIGHT 16.0


#define atmosphereModel_solar_irradiance 		vec3(1.68194, 1.85149, 1.91198)
#define atmosphereModel_sun_angular_radius 		0.005
#define atmosphereModel_bottom_radius 			6360.0
#define atmosphereModel_top_radius 				6420.0
#define atmosphereModel_rayleigh_scattering 	vec3(0.008396, 0.014590, 0.033100)
#define atmosphereModel_mie_scattering 			vec3(0.003996)
#define atmosphereModel_mie_extinction 			vec3(0.004440)
#define atmosphereModel_mie_phase_function_g 	0.8
#define atmosphereModel_absorption_extinction 	vec3(0.0020031, 0.0016555, 0.0000847)
#define atmosphereModel_ground_albedo 			vec3(0.1)
#define atmosphereModel_mu_s_min 				-0.5

#define atmosphereModel_densityProfile_rayleigh 			-0.1803369
#define atmosphereModel_densityProfile_mie 					-1.2022459
#define atmosphereModel_densityProfile_absorption_width 	25.0
#define atmosphereModel_densityProfile_absorption 			vec4(0.09617967, -0.9617967, -0.09617967, 3.847187)



//////////Utility functions///////////////////////
//////////Utility functions///////////////////////


float ClampRadius(float r){
	return clamp(r, atmosphereModel_bottom_radius, atmosphereModel_top_radius);
}

float SafeSqrt(float a){
	return sqrt(max(a, 0.0));
}

vec3 RenderSunDisc(vec3 worldDir, vec3 sunDir){
	float d = dot(worldDir, sunDir);

	float size = 5e-5;
	float hardness = 4e4;

	float disc = curve(saturate((d - (1.0 - size)) * hardness));
	disc *= disc;

	return vec3(1.1114, 0.9756, 0.9133) * disc;
}

float RenderMoonDisc(vec3 worldDir, vec3 moonDir){
	float d = dot(worldDir, moonDir);

	float size = 5e-5;
	float hardness = 1e5;

	float disc = curve(saturate((d - (1.0 - size)) * hardness));
	return disc * disc;
}

float RenderMoonDiscReflection(vec3 worldDir, vec3 moonDir){
	float d = dot(worldDir, moonDir);

	float size = 0.0025;
	float hardness = 300.0;

	float disc = curve(saturate((d - (1.0 - size)) * hardness));
	return disc * disc;
}



//////////Intersections///////////////////////////
//////////Intersections///////////////////////////

float DistanceToTopAtmosphereBoundary(
	float r,
	float mu
	){
		float discriminant = r * r * (mu * mu - 1.0) + atmosphereModel_top_radius * atmosphereModel_top_radius;
		return max(-r * mu + SafeSqrt(discriminant), 0.0);
}

float DistanceToBottomAtmosphereBoundary(
	float r,
	float mu
	){
		float discriminant = r * r * (mu * mu - 1.0) + atmosphereModel_bottom_radius * atmosphereModel_bottom_radius;
		return max(-r * mu - SafeSqrt(discriminant), 0.0);
}

bool RayIntersectsGround(
	float r,
	float mu
	){
		return mu < 0.0 && r * r * (mu * mu - 1.0) + atmosphereModel_bottom_radius * atmosphereModel_bottom_radius>= 0.0;
}



//////////Density at altitude/////////////////////
//////////Density at altitude/////////////////////


float GetProfileDensityRayleighMie(
	float exp_scale,
	float altitude
	){
		return exp2(exp_scale * altitude);
}

float GetProfileDensityAbsorption(
	float width,
	vec4 profile,
	float altitude
	){
		return altitude < width ?
			profile.x * altitude + profile.y :
			profile.z * altitude + profile.w;
}


//////////Coord Transforms////////////////////////
//////////Coord Transforms////////////////////////

float GetTextureCoordFromUnitRange(float x, float texture_size) {
	return 0.5 / texture_size + x * (1.0 - 1.0 / texture_size);
}

float GetCombinedTextureCoordFromUnitRange(float x, float original_texture_size, float combined_texture_size) {
	return 0.5 / combined_texture_size + x * (original_texture_size / combined_texture_size - 1.0 / combined_texture_size);
}


vec4 GetScatteringTextureUvwzFromRMuMuSNu(
	float r,
	float mu,
	float mu_s,
	float nu,
	bool ray_r_mu_intersects_ground
	){
		float H = sqrt(atmosphereModel_top_radius * atmosphereModel_top_radius - atmosphereModel_bottom_radius* atmosphereModel_bottom_radius);

		float rho = SafeSqrt(r * r - atmosphereModel_bottom_radius* atmosphereModel_bottom_radius);
		float u_r = GetCombinedTextureCoordFromUnitRange(rho / H, SCATTERING_TEXTURE_R_SIZE, COMBINED_TEXTURE_DEPTH);

		float r_mu = r * mu;
		float discriminant = r_mu * r_mu - r * r + atmosphereModel_bottom_radius* atmosphereModel_bottom_radius;
		float u_mu;

		if (ray_r_mu_intersects_ground){
			float d = -r_mu - SafeSqrt(discriminant);
			float d_min = r - atmosphereModel_bottom_radius;
			float d_max = rho;
			u_mu = 0.5 - 0.5 * GetTextureCoordFromUnitRange(float(d_max != d_min) * (d - d_min) / (d_max - d_min), SCATTERING_TEXTURE_MU_SIZE / 2.0);
		}else{
			float d = -r_mu + SafeSqrt(discriminant + H * H);
			float d_min = atmosphereModel_top_radius - r;
			float d_max = rho + H;
			u_mu = 0.5 + 0.5 * GetTextureCoordFromUnitRange((d - d_min) / (d_max - d_min), SCATTERING_TEXTURE_MU_SIZE / 2.0);
		}

		float d = DistanceToTopAtmosphereBoundary(atmosphereModel_bottom_radius, mu_s);
		float d_min = atmosphereModel_top_radius - atmosphereModel_bottom_radius;
		float d_max = H;
		float a = (d - d_min) / (d_max - d_min);
		float D = DistanceToTopAtmosphereBoundary(atmosphereModel_bottom_radius, atmosphereModel_mu_s_min);
		float A = (D - d_min) / (d_max - d_min);
		float u_mu_s = GetTextureCoordFromUnitRange(max(1.0 - a / A, 0.0) / (1.0 + a), SCATTERING_TEXTURE_MU_S_SIZE);
		float u_nu = (nu + 1.0) / 2.0;
		return vec4(u_nu, u_mu_s, u_mu, u_r);
}



//////////Transmittance Lookup////////////////////
//////////Transmittance Lookup////////////////////

vec2 GetTransmittanceTextureUvFromRMu(
	float r,
	float mu
	){
		float H = sqrt(atmosphereModel_top_radius * atmosphereModel_top_radius - atmosphereModel_bottom_radius* atmosphereModel_bottom_radius);

		float rho = SafeSqrt(r * r - atmosphereModel_bottom_radius* atmosphereModel_bottom_radius);

		float d = DistanceToTopAtmosphereBoundary(r, mu);
		float d_min = atmosphereModel_top_radius - r;
		float d_max = rho + H;
		float x_mu = (d - d_min) / (d_max - d_min);
		float x_r = rho / H;
		return vec2(GetCombinedTextureCoordFromUnitRange(x_mu, TRANSMITTANCE_TEXTURE_WIDTH, COMBINED_TEXTURE_WIDTH),
					GetCombinedTextureCoordFromUnitRange(x_r, TRANSMITTANCE_TEXTURE_HEIGHT, COMBINED_TEXTURE_HEIGHT));
}

vec3 GetTransmittanceToTopAtmosphereBoundary(
	float r,
	float mu
	){
		vec2 uv = GetTransmittanceTextureUvFromRMu(r, mu);
		#if MC_VERSION >= 11605
			return vec3(textureLod(colortex8, vec3(uv, 32.5 / 33.0), 0.0));
		#else
			return vec3(textureLod(depthtex2, vec3(uv, 32.5 / 33.0), 0.0));
		#endif
}

vec3 GetTransmittance(
	float r,
	float mu,
	float d,
	bool ray_r_mu_intersects_ground
	){
		float r_d = ClampRadius(sqrt(d * d + 2.0 * r * mu * d + r * r));
		float mu_d = clamp((r * mu + d) / r_d, -1.0, 1.0);

		if (ray_r_mu_intersects_ground) {
			return min(
				GetTransmittanceToTopAtmosphereBoundary(r_d, -mu_d) /
				GetTransmittanceToTopAtmosphereBoundary(r, -mu),
			vec3(1.0));
		} else {
			return min(
				GetTransmittanceToTopAtmosphereBoundary(r, mu) /
				GetTransmittanceToTopAtmosphereBoundary(r_d, mu_d),
			vec3(1.0));
		}
}

vec3 GetTransmittanceToSun(
	float r,
	float mu_s
	){
		float sin_theta_h = atmosphereModel_bottom_radius/ r;
		float cos_theta_h = -sqrt(max(1.0 - sin_theta_h * sin_theta_h, 0.0));

		return GetTransmittanceToTopAtmosphereBoundary(r, mu_s) *
			smoothstep(-sin_theta_h * atmosphereModel_sun_angular_radius,
					   sin_theta_h * atmosphereModel_sun_angular_radius,
					   mu_s - cos_theta_h);
}



//////////Scattering Lookup///////////////////////
//////////Scattering Lookup///////////////////////

vec3 GetExtrapolatedSingleMieScattering(
	vec4 scattering
	){
		if (scattering.r <= 0.0){
			return vec3(0.0);
		}
		return scattering.rgb * scattering.a / scattering.r *
			(atmosphereModel_rayleigh_scattering.r / atmosphereModel_mie_scattering.r) *
			(atmosphereModel_mie_scattering / atmosphereModel_rayleigh_scattering);
}

vec3 GetCombinedScattering(
	float r,
	float mu,
	float mu_s,
	float nu,
	bool ray_r_mu_intersects_ground,
	out vec3 single_mie_scattering
	){
		vec4 uvwz = GetScatteringTextureUvwzFromRMuMuSNu(r, mu, mu_s, nu, ray_r_mu_intersects_ground);
		float tex_coord_x = uvwz.x * (SCATTERING_TEXTURE_NU_SIZE - 1.0);
		float tex_x = floor(tex_coord_x);
		float lerp = tex_coord_x - tex_x;
		vec3 uvw0 = vec3((tex_x + uvwz.y) / SCATTERING_TEXTURE_NU_SIZE, uvwz.z, uvwz.w);
		vec3 uvw1 = vec3((tex_x + 1.0 + uvwz.y) / SCATTERING_TEXTURE_NU_SIZE, uvwz.z, uvwz.w);

		#if MC_VERSION >= 11605
			vec4 combined_scattering = textureLod(colortex8, uvw0, 0.0) * (1.0 - lerp) + textureLod(colortex8, uvw1, 0.0) * lerp;
		#else
			vec4 combined_scattering = textureLod(depthtex2, uvw0, 0.0) * (1.0 - lerp) + textureLod(depthtex2, uvw1, 0.0) * lerp;
		#endif

		vec3 scattering = vec3(combined_scattering);
		single_mie_scattering = GetExtrapolatedSingleMieScattering(combined_scattering);

		return scattering;
}



//////////Irradiance Lookup///////////////////////
//////////Irradiance Lookup///////////////////////

vec3 GetIrradiance(
	float r,
	float mu_s
	){
		float x_r = (r - atmosphereModel_bottom_radius) / (atmosphereModel_top_radius - atmosphereModel_bottom_radius);
		float x_mu_s = mu_s * 0.5 + 0.5;
		vec2 uv = vec2(GetCombinedTextureCoordFromUnitRange(x_mu_s, IRRADIANCE_TEXTURE_WIDTH, COMBINED_TEXTURE_WIDTH),
					   GetCombinedTextureCoordFromUnitRange(x_r, IRRADIANCE_TEXTURE_HEIGHT, COMBINED_TEXTURE_HEIGHT) + TRANSMITTANCE_TEXTURE_HEIGHT / COMBINED_TEXTURE_HEIGHT);

		#if MC_VERSION >= 11605
			return vec3(textureLod(colortex8, vec3(uv, 32.5 / 33.0), 0.0));
		#else
			return vec3(textureLod(depthtex2, vec3(uv, 32.5 / 33.0), 0.0));
		#endif
}



//////////Rendering///////////////////////////////
//////////Rendering///////////////////////////////


const mat3 LMS = mat3(1.6858, -0.4624, -0.0069, -0.0374, 1.0598, -0.0742, -0.0283, -0.1119, 1.0491);


vec3 GetSunAndSkyIrradiance(
	vec3 point,
	vec3 sun_direction,
	vec3 moon_direction,
	out vec3 moon_irradiance,
	out vec3 sun_sky_irradiance,
	out vec3 moon_sky_irradiance
	){
		float r = length(point);
		float sun_mu_s = dot(point, sun_direction) / r;
		float moon_mu_s = dot(point, moon_direction) / r;

		sun_sky_irradiance = GetIrradiance(r, sun_mu_s) * LMS;
		moon_sky_irradiance = GetIrradiance(r, moon_mu_s) * NIGHT_BRIGHTNESS * LMS;

		vec3 sun_irradiance = atmosphereModel_solar_irradiance;
		moon_irradiance = sun_irradiance * GetTransmittanceToSun(r, moon_mu_s) * NIGHT_BRIGHTNESS * LMS;
		sun_irradiance *= GetTransmittanceToSun(r, sun_mu_s);

		return sun_irradiance * LMS;
}


vec3 GetSkyRadiance(
	vec3 camera,
	vec3 view_ray,
	vec3 sun_direction,
	vec3 moon_direction,
	bool horizon,
	out vec3 transmittance,
	out bool ray_r_mu_intersects_ground
	){
		float r = length(camera);
		float rmu = dot(camera, view_ray);
		float distance_to_top_atmosphere_boundary = -rmu - sqrt(rmu * rmu - r * r + atmosphereModel_top_radius * atmosphereModel_top_radius);

		if (distance_to_top_atmosphere_boundary > 0.0){
			camera = camera + view_ray * distance_to_top_atmosphere_boundary;
			r = atmosphereModel_top_radius;
			rmu += distance_to_top_atmosphere_boundary;
		} else if (r > atmosphereModel_top_radius) {
			transmittance = vec3(1.0);
			return vec3(0.0);
		}

		float mu = rmu / r;
		float sun_mu_s = dot(camera, sun_direction) / r;
		float sun_nu = dot(view_ray, sun_direction);

		float moon_mu_s = dot(camera, moon_direction) / r;
		float moon_nu = dot(view_ray, moon_direction);


		ray_r_mu_intersects_ground = RayIntersectsGround(r, mu);


		transmittance = ray_r_mu_intersects_ground ? vec3(0.0) : GetTransmittanceToTopAtmosphereBoundary(r, mu);

		vec3 sun_single_mie_scattering;
		vec3 sun_scattering;

		vec3 moon_single_mie_scattering;
		vec3 moon_scattering;

		horizon = horizon && ray_r_mu_intersects_ground;

		sun_scattering = GetCombinedScattering(r, mu, sun_mu_s, sun_nu, horizon, sun_single_mie_scattering);
		moon_scattering = GetCombinedScattering(r, mu, moon_mu_s, moon_nu, horizon, moon_single_mie_scattering);


		vec3 groundDiffuse = vec3(0.0);
		#ifdef ATMO_HORIZON
		if (horizon){
			vec3 planet_surface = camera + view_ray * DistanceToBottomAtmosphereBoundary(r, mu);

			float r = length(planet_surface);
			float sun_mu_s = dot(planet_surface, sun_direction) / r;
			float moon_mu_s = dot(planet_surface, moon_direction) / r;

			vec3 sky_irradiance = GetIrradiance(r, sun_mu_s);
			sky_irradiance += GetIrradiance(r, moon_mu_s) * NIGHT_BRIGHTNESS;
			vec3 sun_irradiance = atmosphereModel_solar_irradiance * GetTransmittanceToSun(r, sun_mu_s);

			float d = distance(camera, planet_surface);
			vec3 surface_transmittance = GetTransmittance(r, mu, d, ray_r_mu_intersects_ground);

			groundDiffuse = mix(sky_irradiance * 0.1, sun_irradiance * 0.008, wetness * 0.6) * surface_transmittance;
		}
		#endif


		vec3 rayleigh = sun_scattering * RayleighPhaseFunction(sun_nu)
					 + moon_scattering * RayleighPhaseFunction(moon_nu) * NIGHT_BRIGHTNESS;

		vec3 mie = sun_single_mie_scattering * MiePhaseFunction(atmosphereModel_mie_phase_function_g, sun_nu)
				+ moon_single_mie_scattering * MiePhaseFunction(atmosphereModel_mie_phase_function_g, moon_nu) * NIGHT_BRIGHTNESS;

		rayleigh = mix(rayleigh,  vec3(Luminance(rayleigh)) * atmosphereModel_solar_irradiance, wetness * 0.5);

		return (rayleigh + mie + groundDiffuse) * (1.0 - wetness * 0.4) * LMS;
}


vec3 GetSkyRadianceToPoint(
	vec3 camera,
	vec3 point,
	vec3 sun_direction,
	vec3 moon_direction,
	out vec3 transmittance
	){
		vec3 view_ray = normalize(point - camera);
		float r = length(camera);
		float rmu = dot(camera, view_ray);
		float distance_to_top_atmosphere_boundary = -rmu - sqrt(rmu * rmu - r * r + atmosphereModel_top_radius * atmosphereModel_top_radius);

		if (distance_to_top_atmosphere_boundary > 0.0){
			camera = camera + view_ray * distance_to_top_atmosphere_boundary;
			r = atmosphereModel_top_radius;
			rmu += distance_to_top_atmosphere_boundary;
		}

		float mu = rmu / r;
		float sun_mu_s = dot(camera, sun_direction) / r;
		float sun_nu = dot(view_ray, sun_direction);
		float moon_mu_s = dot(camera, moon_direction) / r;
		float moon_nu = dot(view_ray, moon_direction);
		float d = length(point - camera);

		#ifdef CLOUD_LOCAL_LIGHTING
			bool ray_r_mu_intersects_ground = RayIntersectsGround(r, mu);
		#else
			bool ray_r_mu_intersects_ground = false;
		#endif

		transmittance = GetTransmittance(r, mu, d, ray_r_mu_intersects_ground);

		vec3 sun_single_mie_scattering;
		vec3 sun_scattering = GetCombinedScattering(r, mu, sun_mu_s, sun_nu, ray_r_mu_intersects_ground, sun_single_mie_scattering);
		vec3 moon_single_mie_scattering;
		vec3 moon_scattering = GetCombinedScattering(r, mu, moon_mu_s, moon_nu, ray_r_mu_intersects_ground, moon_single_mie_scattering);

		float r_p = ClampRadius(sqrt(d * d + 2.0 * r * mu * d + r * r));
		float mu_p = (r * mu + d) / r_p;
		float sun_mu_s_p = (r * sun_mu_s + d * sun_nu) / r_p;
		float moon_mu_s_p = (r * moon_mu_s + d * moon_nu) / r_p;

		vec3 sun_single_mie_scattering_p;
		vec3 sun_scattering_p = GetCombinedScattering(r_p, mu_p, sun_mu_s_p, sun_nu, ray_r_mu_intersects_ground, sun_single_mie_scattering_p);
		vec3 moon_single_mie_scattering_p;
		vec3 moon_scattering_p = GetCombinedScattering(r_p, mu_p, moon_mu_s_p, moon_nu, ray_r_mu_intersects_ground, moon_single_mie_scattering_p);

		sun_scattering = sun_scattering - transmittance * sun_scattering_p;
		sun_single_mie_scattering = sun_single_mie_scattering - transmittance * sun_single_mie_scattering_p;
		moon_scattering = moon_scattering - transmittance * moon_scattering_p;
		moon_single_mie_scattering = moon_single_mie_scattering - transmittance * moon_single_mie_scattering_p;

		sun_single_mie_scattering = sun_single_mie_scattering * smoothstep(0.0, 0.01, sun_mu_s);
		moon_single_mie_scattering = moon_single_mie_scattering * smoothstep(0.0, 0.01, moon_mu_s);

		vec3 rayleigh = sun_scattering * RayleighPhaseFunction(sun_nu)
					 + moon_scattering * RayleighPhaseFunction(moon_nu) * NIGHT_BRIGHTNESS;

		vec3 mie = sun_single_mie_scattering * MiePhaseFunction(atmosphereModel_mie_phase_function_g, sun_nu)
				+ moon_single_mie_scattering * MiePhaseFunction(atmosphereModel_mie_phase_function_g, moon_nu) * NIGHT_BRIGHTNESS;

		rayleigh = mix(rayleigh, vec3(Luminance(rayleigh)) * atmosphereModel_solar_irradiance, wetness * 0.5);

		return (rayleigh + mie) * (1.0 - wetness * 0.4) * LMS;
}
