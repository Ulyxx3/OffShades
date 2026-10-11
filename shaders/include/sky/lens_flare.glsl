#if !defined INCLUDE_SKY_LENS_FLARE
#define INCLUDE_SKY_LENS_FLARE

#if defined WORLD_END
#include "/include/sky/end_eclipse.glsl"
#endif

/*
--------------------------------------------------------------------------------

  OffShades - Cinematic Anamorphic Lens Flare
  Adapted & enhanced from IterationT 3.2.0 / 3.3

  Simulates camera optics facing a bright celestial star:
  - Anamorphic glare starburst streaks
  - Ghost flare orbs with chromatic aberration
  - Diffraction rings with color dispersion
  - Smooth occlusion testing against the depth buffer

--------------------------------------------------------------------------------
*/

#define ORB_FLARE_COUNT 6.0
#define DISTORTION_BARREL 1.0

vec2 get_dist_offset(vec2 uv, vec2 pxoffset) {
    vec2 tocenter = uv.xy;
    vec3 prep = normalize(vec3(tocenter.y, -tocenter.x, 0.0));

    float angle = length(tocenter.xy) * 2.221 * DISTORTION_BARREL;
    vec3 oldoffset = vec3(pxoffset, 0.0);

    vec3 rotated = oldoffset * cos(angle)
                 + cross(prep, oldoffset) * sin(angle)
                 + prep * dot(prep, oldoffset) * (1.0 - cos(angle));

    return rotated.xy;
}

vec3 flare_element(vec2 uv, vec2 pos, float dist, float chromaOffset, float size) {
    pos = get_dist_offset(uv, pos);

    float r = max(0.01 - pow(length(uv + (dist - chromaOffset) * pos), 2.4) * (1.0 / (size * 2.0)), 0.0) * 0.85;
    float g = max(0.01 - pow(length(uv +  dist                 * pos), 2.4) * (1.0 / (size * 2.0)), 0.0) * 1.00;
    float b = max(0.01 - pow(length(uv + (dist + chromaOffset) * pos), 2.4) * (1.0 / (size * 2.0)), 0.0) * 1.50;

    return vec3(r, g, b);
}

vec3 flare_orb(vec2 uv, vec2 pos, float dist, float size) {
    vec3 c = vec3(0.0);

    for (float i = 0.0; i < ORB_FLARE_COUNT; i += 1.0) {
        float j = i + 1.0;
        float offset = j / (j + 0.1);
        float colOffset = j / ORB_FLARE_COUNT * 0.5;
        float ss = size / (j + 1.0);

        c += flare_element(uv, pos, dist + offset, ss * 2.0, ss) * vec3(1.0 - colOffset, 1.0, 0.5 + colOffset) * j;
    }

    c += flare_element(uv, pos, dist + 0.8, 0.05, 3.0 * size) * 0.5;
    return c;
}

vec3 flare_ring(vec2 uv, vec2 pos, float dist, float chromaOffset, float blur) {
    vec2 uvd = uv * length(uv);

    float r = max(1.0 / (1.0 + 250.0 * pow(length(uvd + (dist - chromaOffset) * pos), blur)), 0.0) * 0.8;
    float g = max(1.0 / (1.0 + 250.0 * pow(length(uvd +  dist                 * pos), blur)), 0.0) * 1.0;
    float b = max(1.0 / (1.0 + 250.0 * pow(length(uvd + (dist + chromaOffset) * pos), blur)), 0.0) * 1.5;

    return vec3(r, g, b);
}

vec3 calculate_lens_flare(
    vec2 texCoord,
    vec3 sunDir,
    mat4 modelView,
    mat4 projection,
    sampler2D depthSampler,
    vec2 viewRes
) {
#ifndef END_LENS_FLARE
    return vec3(0.0);
#endif
#ifndef END_LENS_FLARE_INTENSITY
#define END_LENS_FLARE_INTENSITY 1.00
#endif

    // 1. Transform Sun to View Space
    vec3 sunView = mat3(modelView) * sunDir;
    if (sunView.z >= -0.01) return vec3(0.0); // Behind the camera plane

    // 2. Project Sun to Normalized Device Coordinates (NDC) & Screen UV
    vec4 sunClip = projection * vec4(sunView, 1.0);
    vec3 sunNDC = sunClip.xyz / sunClip.w;
    vec2 sunCoord = sunNDC.xy * 0.5 + 0.5;

    // Check if the sun is anywhere near the visible screen bounds
    if (sunCoord.x < -0.3 || sunCoord.x > 1.3 || sunCoord.y < -0.3 || sunCoord.y > 1.3) {
        return vec3(0.0);
    }

    // 3. Occlusion testing against Depth Buffer
    float sunVisibility = 0.0;
    if (sunCoord.x >= 0.0 && sunCoord.x <= 1.0 && sunCoord.y >= 0.0 && sunCoord.y <= 1.0) {
        ivec2 sunTexel = ivec2(sunCoord * viewRes * taau_render_scale);
        ivec2 maxTexel = ivec2(viewRes * taau_render_scale) - ivec2(1);
        sunVisibility += float(texelFetch(depthSampler, clamp(sunTexel, ivec2(0), maxTexel), 0).x >= 0.9999);
        sunVisibility += float(texelFetch(depthSampler, clamp(sunTexel + ivec2( 4,  0), ivec2(0), maxTexel), 0).x >= 0.9999);
        sunVisibility += float(texelFetch(depthSampler, clamp(sunTexel + ivec2(-4,  0), ivec2(0), maxTexel), 0).x >= 0.9999);
        sunVisibility += float(texelFetch(depthSampler, clamp(sunTexel + ivec2( 0,  4), ivec2(0), maxTexel), 0).x >= 0.9999);
        sunVisibility += float(texelFetch(depthSampler, clamp(sunTexel + ivec2( 0, -4), ivec2(0), maxTexel), 0).x >= 0.9999);
        sunVisibility *= 0.2;
    } else {
        // Just off-screen edge bleed
        float edgeDist = max(abs(sunCoord.x - 0.5) - 0.5, abs(sunCoord.y - 0.5) - 0.5);
        sunVisibility = clamp(1.0 - edgeDist * 3.5, 0.0, 1.0);
    }

#ifdef WORLD_END
    sunVisibility *= get_end_sun_visibility(sunDir, frameTimeCounter);
#endif

    if (sunVisibility <= 0.002) return vec3(0.0);

    // 4. Screen-space optical calculations
    float aspect = viewRes.x / viewRes.y;
    vec2 coord  = texCoord - 0.5;
    vec2 sunPos = sunCoord - 0.5;
    coord.x  *= aspect;
    sunPos.x *= aspect;

    float fovFactor = max(projection[1][1], 1.8);

    // 5. Central glare & Anamorphic Starburst Spikes
    vec2 v = coord - sunPos;
    float dist = length(v);
    float gDist = dist * 13.0 / fovFactor;
    float phase = atan(v.y, v.x) + 0.131;

    float gl = 2.0 - clamp(gDist, 0.0, 1.0) + sin(phase * 12.0) * clamp(gDist * 2.5 - 0.2, 0.0, 1.0);
    gl = gl * gl;
    gDist = gDist * gDist;
    gl *= 8e-5 / max(gDist * gDist, 1e-6);
    gl = min(gl, 90.0);

    vec3 lf = vec3(gl * 0.35);

    // 6. Secondary Ghost Flares, Diffraction Rings & Orbs
    float size = 0.5 * fovFactor;
    vec3 fl = vec3(0.0);

    fl += flare_orb(coord, sunPos, 0.0, size * 0.01) * 0.10;
    fl += flare_ring(coord, sunPos,  1.0, 0.02, 1.4) * 0.01;
    fl += flare_ring(coord, sunPos, -1.0, 0.02, 1.4) * 0.01;

    fl += flare_element(coord, sunPos, -2.00, 0.05, size * 0.05) * 0.50;
    fl += flare_element(coord, sunPos, -0.90, 0.02, size * 0.03) * 0.30;
    fl += flare_element(coord, sunPos, -0.70, 0.01, size * 0.06) * 0.50;
    fl += flare_element(coord, sunPos, -0.55, 0.02, size * 0.02) * 0.20;
    fl += flare_element(coord, sunPos, -0.35, 0.02, size * 0.04) * 0.70;
    fl += flare_element(coord, sunPos, -0.25, 0.01, size * 0.15) * vec3(0.3, 0.4, 0.38);
    fl += flare_element(coord, sunPos, -0.25, 0.02, size * 0.08) * 0.20;
    fl += flare_element(coord, sunPos,  0.05, 0.01, size * 0.03) * 0.10;
    fl += flare_element(coord, sunPos,  0.30, 0.02, size * 0.20) * vec3(0.2, 0.18, 0.14);
    fl += flare_element(coord, sunPos,  1.20, 0.03, size * 0.10) * 0.20;

    lf += fl * 0.55;
    lf *= sunVisibility * vec3(1.0, 0.95, 0.88) * (1.8 * END_LENS_FLARE_INTENSITY);

    return lf;
}

#endif // INCLUDE_SKY_LENS_FLARE
