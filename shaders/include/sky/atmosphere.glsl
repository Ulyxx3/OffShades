/*
================================================================================
  OffShades — include/sky/atmosphere.glsl
  Physically-based Rayleigh + Mie atmospheric scattering.
  Adapted from Photon Shaders by Sixthsurge.
================================================================================
*/

#ifndef ATMOSPHERE_INCLUDED
#define ATMOSPHERE_INCLUDED

#include "/include/utility/math.glsl"

// ─── Earth / atmosphere parameters ──────────────────────────────────────────
const float earth_radius       = 6.371e6;
const float atmosphere_radius  = 6.471e6;  // earth_radius + 100 km

// Rayleigh coefficients at sea-level density
const vec3  rayleigh_coeff     = vec3(5.802e-6, 13.558e-6, 33.1e-6);
const float rayleigh_scale_h   = 8.0e3;    // scale height (m)

// Mie coefficients
const float mie_coeff          = 3.996e-6;
const float mie_scale_h        = 1.2e3;
const float mie_g              = 0.8;       // asymmetry parameter

// Absorption (ozone layer)
const vec3  ozone_coeff        = vec3(0.65e-6, 1.881e-6, 0.085e-6);

// ─── Phase functions ─────────────────────────────────────────────────────────
float rayleigh_phase(float cos_theta) {
    return (3.0 / (16.0 * PI)) * (1.0 + cos_theta * cos_theta);
}

float mie_henyey_greenstein(float cos_theta, float g) {
    float g2 = g * g;
    return (1.0 - g2) / (4.0 * PI * pow(1.0 + g2 - 2.0 * g * cos_theta, 1.5));
}

// ─── Sphere intersection ─────────────────────────────────────────────────────
// Returns (near, far) distances to sphere centered at origin
vec2 sphere_intersect(vec3 ro, vec3 rd, float radius) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - radius * radius;
    float d = b * b - c;
    if (d < 0.0) return vec2(-1.0);
    d = sqrt(d);
    return vec2(-b - d, -b + d);
}

// ─── Optical depth along a ray ───────────────────────────────────────────────
vec2 optical_depth(vec3 pos, vec3 dir, float dist) {
    const int STEPS = 8;
    float step_size = dist / float(STEPS);
    vec2  od        = vec2(0.0);
    vec3  p         = pos + dir * step_size * 0.5;

    for (int i = 0; i < STEPS; ++i, p += dir * step_size) {
        float height = length(p) - earth_radius;
        od.x += exp(-height / rayleigh_scale_h) * step_size;
        od.y += exp(-height / mie_scale_h)       * step_size;
    }
    return od;
}

// ─── Full scattering integral ────────────────────────────────────────────────
// ro    : ray origin (above surface)
// rd    : ray direction
// sun_dir : normalized sun direction
// Returns: inscattered light RGB
vec3 compute_atmosphere(vec3 ro, vec3 rd, vec3 sun_dir) {
    const int  STEPS     = 16;
    const vec3 sun_irr   = vec3(20.0);  // approximate solar irradiance at TOA

    // Intersect atmosphere
    vec2 atm_t = sphere_intersect(ro, rd, atmosphere_radius);
    if (atm_t.x > atm_t.y || atm_t.y < 0.0) return vec3(0.0);

    float t0     = max(atm_t.x, 0.0);
    float t1     = atm_t.y;
    float dist   = t1 - t0;
    float step_size = dist / float(STEPS);

    float cos_theta  = dot(rd, sun_dir);
    float phase_r    = rayleigh_phase(cos_theta);
    float phase_m    = mie_henyey_greenstein(cos_theta, mie_g);

    vec3 sum_r = vec3(0.0);
    vec3 sum_m = vec3(0.0);

    vec3  transmittance = vec3(1.0);
    vec3  p             = ro + rd * (t0 + step_size * 0.5);

    for (int i = 0; i < STEPS; ++i, p += rd * step_size) {
        float height = max(length(p) - earth_radius, 0.0);
        float rho_r  = exp(-height / rayleigh_scale_h);
        float rho_m  = exp(-height / mie_scale_h);

        // Transmittance through this step
        vec3 sigma_ext = (rayleigh_coeff * rho_r + vec3(mie_coeff * 1.1) * rho_m + ozone_coeff * max(0.0, 1.0 - abs(height - 25e3) / 15e3));
        vec3 step_t    = exp(-sigma_ext * step_size);
        transmittance  *= step_t;

        // Sun visibility at this sample
        vec2 sun_t = sphere_intersect(p, sun_dir, atmosphere_radius);
        if (sun_t.y > 0.0) {
            vec2 od_sun = optical_depth(p, sun_dir, sun_t.y);
            vec3 sun_transmittance = exp(-(rayleigh_coeff * od_sun.x + vec3(mie_coeff * 1.1) * od_sun.y));

            sum_r += transmittance * rho_r * sun_transmittance * step_size;
            sum_m += transmittance * rho_m * sun_transmittance * step_size;
        }
    }

    vec3 scatter = sun_irr * (rayleigh_coeff * phase_r * sum_r + vec3(mie_coeff) * phase_m * sum_m);
    return max(scatter, vec3(0.0));
}

// ─── Sun disk ────────────────────────────────────────────────────────────────
float sun_disk(vec3 rd, vec3 sun_dir) {
    float cos_angle = dot(rd, sun_dir);
    float sun_radius = cos(radians(0.53 * 0.5)); // angular radius
    return smoothstep(sun_radius - 0.0005, sun_radius + 0.0005, cos_angle);
}

// ─── Moon disk ───────────────────────────────────────────────────────────────
float moon_disk(vec3 rd, vec3 moon_dir) {
    float cos_angle = dot(rd, moon_dir);
    float moon_radius = cos(radians(0.53 * 0.5));
    return smoothstep(moon_radius - 0.001, moon_radius + 0.001, cos_angle);
}

// ─── Sky color for a given view direction ────────────────────────────────────
// Handles sunset/sunrise tinting via sun_dir elevation
vec3 sky_color(vec3 rd, vec3 sun_dir, vec3 moon_dir) {
    // Place observer just above sea level
    vec3 ro = vec3(0.0, earth_radius + 200.0, 0.0);

    vec3 sky = compute_atmosphere(ro, rd, sun_dir);

    // Sun disk
    float sun = sun_disk(rd, sun_dir);
    sky += vec3(1.0, 0.9, 0.7) * sun * 5.0;

    // Moon (simple)
    float moon = moon_disk(rd, moon_dir);
    sky = mix(sky, vec3(0.9, 0.95, 1.0) * 0.3, moon * 0.5);

    // Night tint when sun is below horizon
    float day_factor = smoothstep(-0.1, 0.05, sun_dir.y);
    sky *= mix(0.04, 1.0, day_factor);

    return sky;
}

#endif // ATMOSPHERE_INCLUDED


