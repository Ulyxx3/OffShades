#if !defined INCLUDE_LIGHTING_COLORS_END_COLOR
#define INCLUDE_LIGHTING_COLORS_END_COLOR

#include "/include/sky/end_eclipse.glsl"
#include "/include/utility/color.glsl"

vec3 get_light_color() {
    vec3 end_sun = get_end_sun_dir(sun_dir);
    float eclipse = get_end_sun_visibility(end_sun, frameTimeCounter);
    return from_srgb(vec3(END_LIGHT_R, END_LIGHT_G, END_LIGHT_B)) * (END_LIGHT_I * eclipse);
}

vec3 get_ambient_color() {
    vec3 end_sun = get_end_sun_dir(sun_dir);
    float eclipse = get_end_sun_visibility(end_sun, frameTimeCounter);
    // Keep ambient lighting at 55% during total eclipse so the environment remains visible
    float ambientFade = mix(0.55, 1.0, eclipse);
    vec3 eclipseTint = mix(vec3(0.92, 0.88, 1.06), vec3(1.0), eclipse);
    return from_srgb(vec3(END_AMBIENT_R, END_AMBIENT_G, END_AMBIENT_B)) *
        (END_AMBIENT_I * ambientFade) * eclipseTint;
}

#endif

