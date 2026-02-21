/*
================================================================================
  OffShades — include/misc/end.glsl
  The End dimension atmosphere: void sky gradient, End star field, purple ambient.
  Adapted from Iteration T Shaders by Lolcat.
================================================================================
*/

#ifndef END_INCLUDED
#define END_INCLUDED

#include "/include/utility/math.glsl"
#include "/include/utility/color.glsl"
#include "/include/sky/stars.glsl"

// ─── End sky ──────────────────────────────────────────────────────────────────
// The End has a distinctive purple/black void sky
vec3 end_sky(vec3 rd) {
    // Gradient from void (black at bottom) to purple at top
    float up = rd.y * 0.5 + 0.5;
    vec3  void_color   = vec3(0.02, 0.01, 0.06);
    vec3  upper_color  = srgb_to_linear(vec3(END_SKY_R, END_SKY_G, END_SKY_B)) * END_SKY_BRIGHTNESS;

    vec3 sky = mix(void_color, upper_color, smoothstep(0.0, 0.5, up));

    // End stars (dense starfield)
    float star = 0.0;
    vec2 star_uv;
    star_uv.x = atan(rd.x, rd.z) * INV_PI * 0.5 + 0.5;
    star_uv.y = rd.y * 0.5 + 0.5;
    vec2 cell = floor(star_uv * 300.0);
    vec2 fc   = fract(star_uv * 300.0);
    float rnd = hash12(cell);
    vec2 sp   = hash22(cell + 17.3);
    vec2 diff = fc - sp;
    float d   = length(diff);
    if (rnd < END_STAR_DENSITY) {
        star = max(0.0, 1.0 - d * 60.0) * END_STAR_BRIGHTNESS;
    }

    sky += vec3(0.8, 0.85, 1.0) * star;

    // End "sun" effect — a bright patch in a fixed direction
    vec3  end_sun_dir = normalize(vec3(0.0, 0.5, 1.0));
    float end_sun     = pow(max(0.0, dot(rd, end_sun_dir)), 40.0) * END_SUN_STRENGTH;
    sky += srgb_to_linear(vec3(0.9, 0.7, 1.0)) * end_sun;

    return sky;
}

// ─── End ambient light ────────────────────────────────────────────────────────
vec3 end_ambient() {
    return srgb_to_linear(vec3(END_AMBIENT_R, END_AMBIENT_G, END_AMBIENT_B))
           * END_AMBIENT_BRIGHTNESS;
}

// ─── End fog ──────────────────────────────────────────────────────────────────
vec3 apply_end_fog(vec3 scene_color, vec3 view_dir, float view_dist) {
    float fog   = 1.0 - exp(-view_dist * END_FOG_DENSITY);
    vec3  color = end_sky(view_dir);

    return mix(scene_color, color, fog * END_FOG_INTENSITY);
}

// ─── End shading (directional light from "End sun") ──────────────────────────
vec3 end_shade(vec3 albedo, vec3 normal, float emission, float blocklight) {
    vec3 end_sun_dir = normalize(vec3(0.0, 0.5, 1.0));
    float NoL        = max(0.0, dot(normal, end_sun_dir));

    vec3 direct  = albedo * srgb_to_linear(vec3(0.9, 0.7, 1.0)) * END_SUN_STRENGTH * NoL;
    vec3 ambient = albedo * end_ambient();
    vec3 emissive = albedo * emission * EMISSION_STRENGTH;

    float bl = blocklight * blocklight;
    vec3 block_contrib = albedo * blocklight_color() * bl * BLOCKLIGHT_I;

    return direct + ambient + emissive + block_contrib;
}

#endif // END_INCLUDED
