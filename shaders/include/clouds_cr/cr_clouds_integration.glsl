/*
--------------------------------------------------------------------------------
  OffShades Shader
  Complementary Reimagined Clouds Integration for Photon base

  This file bridges the CR cloud system into the Photon shader architecture.
  Sources: Complementary Reimagined r5.7.1 by EminGT (lib/atmospherics/clouds/)
--------------------------------------------------------------------------------
*/

#ifndef INCLUDE_CR_CLOUDS_INTEGRATION
#define INCLUDE_CR_CLOUDS_INTEGRATION

// -------------------------------------------------------
//  Cloud geometry and coordinate helpers (from CR)
// -------------------------------------------------------

const float cloudStretch    = 4.2;
const float cloudTallness   = cloudStretch * 2.0;
const float cloudRoundness  = 0.125;
const float cloudNarrowness = 0.07;

// Altitude of cloud layer (blocks above sea level)
#ifndef CLOUD_ALT_1
#define CLOUD_ALT_1 320
#endif
const int cloudAlt1i = CLOUD_ALT_1;

// Animated wind offset using Photon's world_age
vec3 CR_ModifyTracePos(vec3 tracePos, int cloudAltitude) {
    float wind = world_age * 0.5; // world_age in Photon is time-based
    tracePos.z -= wind;
    tracePos.x += float(cloudAltitude) * 64.0;
    tracePos.xz *= cloudNarrowness;
    return tracePos;
}

// Rounded tile coordinate for cloud 2D noise sampling
vec2 CR_GetRoundedCloudCoord(vec2 pos, float cloudRound) {
    vec2 coord = pos.yx + 0.5;
    vec2 signCoord = sign(coord);
    coord = abs(coord) + 1.0;
    vec2 i, f = modf(coord, i);
    f = smoothstep(0.5 - cloudRound, 0.5 + cloudRound, f);
    coord = i + f;
    return (coord - 0.5) * signCoord / 256.0;
}

// Sample the 2D cloud noise from Photon's noisetex (blue channel)
bool CR_GetCloudNoise(vec3 tracePos, inout vec3 tracePosM, int cloudAltitude) {
    tracePosM = CR_ModifyTracePos(tracePos, cloudAltitude);
    vec2 coord = CR_GetRoundedCloudCoord(tracePosM.xz, cloudRoundness);
    float noise = texture(noisetex, coord).b;
    float threshold = clamp(abs(float(cloudAltitude) - tracePos.y) / cloudStretch, 0.001, 0.999);
    threshold = threshold * threshold; threshold = threshold * threshold; threshold = threshold * threshold;
    return noise > threshold * 0.5 + 0.25;
}

float CR_Get2DCloudSample(vec2 pos) {
    return texture(noisetex, CR_GetRoundedCloudCoord(pos, cloudRoundness)).b;
}

// -------------------------------------------------------
//  Main cloud color computation adapted for Photon
// -------------------------------------------------------
//  In Photon:
//   sun_color   → directional sunlight (similar to CR's lightColor)
//   sky_color   → ambient sky RGB (similar to CR's ambientColor)
//   rainStrength → already available
//
// We derive cloudLightColor and cloudAmbientColor from Photon's data.

vec4 CR_GetVolumetricClouds(
    int   cloudAltitude,
    float distanceThreshold,
    inout float cloudLinearDepth,
    float skyFade,          // 0=terrain, 1=pure sky
    vec3  sun_col,          // Photon sun_color
    vec3  moon_col,         // Photon moon_color
    vec3  sky_col,          // Photon sky_color (ambient)
    vec3  ray_dir,          // world-space ray direction
    vec3  cameraPos,        // world camera position (vec3)
    float lViewPos,         // distance to terrain (or huge)
    float VdotS,            // dot(ray_dir, sun_dir)
    float VdotU,            // dot(ray_dir, up)
    float dither
) {
    vec4 volumetricClouds = vec4(0.0);

    // Choose light vs ambient from Photon color data
    // Mimic CR: lightColor ~ sun/moon color, ambientColor ~ sky ambient
    float isDay = clamp(sun_dir.y * 5.0 + 0.5, 0.0, 1.0); // 0=night, 1=day
    vec3 cloudLightColor   = mix(moon_col, sun_col, isDay) * 1.3;
    vec3 cloudAmbientColor = sky_col * 0.5 * (1.0 - 0.25 * rainStrength);

    // Rain color mixing (CR approach)
    vec3 cloudRainColor  = sky_col * 0.6;
    cloudAmbientColor    = mix(cloudAmbientColor, cloudRainColor * 0.5, rainStrength);
    cloudLightColor      = mix(cloudLightColor, cloudRainColor * 0.45, rainStrength);

    float higherPlaneAltitude = float(cloudAltitude) + cloudStretch;
    float lowerPlaneAltitude  = float(cloudAltitude) - cloudStretch;

    vec3 nPlayerPos = normalize(ray_dir);

    float lowerPlaneDistance  = (lowerPlaneAltitude  - cameraPos.y) / nPlayerPos.y;
    float higherPlaneDistance = (higherPlaneAltitude - cameraPos.y) / nPlayerPos.y;
    float minPlaneDistance = max(min(lowerPlaneDistance, higherPlaneDistance), 0.0);
    float maxPlaneDistance = max(lowerPlaneDistance, higherPlaneDistance);
    if (maxPlaneDistance < 0.0) return vec4(0.0);

    float planeDistanceDif = maxPlaneDistance - minPlaneDistance;

    // Dynamic sample count (quality tier)
    int sampleCount = max(int(planeDistanceDif) / 8, 12);
    sampleCount = min(sampleCount, 48); // cap for performance

    float stepMult = planeDistanceDif / float(sampleCount);
    vec3  traceAdd = nPlayerPos * stepMult;
    vec3  tracePos = cameraPos + minPlaneDistance * nPlayerPos;
    tracePos += traceAdd * dither;
    tracePos.y -= traceAdd.y;

    float lViewPosM = lViewPos < 1.0e6 ? lViewPos - 1.0 : 1.0e8;
    float skyMult0  = (skyFade * 3.333333 - 2.333333);
    skyMult0 = skyMult0 * skyMult0;

    for (int i = 0; i < sampleCount; i++) {
        tracePos += traceAdd;

        vec3  cloudPlayerPos = tracePos - cameraPos;
        float lTracePos      = length(cloudPlayerPos);
        float lTracePosXZ    = length(cloudPlayerPos.xz);
        float cloudMult = 1.0;

        if (lTracePosXZ > distanceThreshold) break;
        if (lTracePos > lViewPosM) {
            if (skyFade < 0.7) continue;
            else cloudMult = skyMult0;
        }

        vec3 tracePosM;
        if (CR_GetCloudNoise(tracePos, tracePosM, cloudAltitude)) {
            float lightMult = 1.0;

            // Approximate self-shadowing from top of cloud
            float cloudShading = 1.0 - (higherPlaneAltitude - tracePos.y) / cloudTallness;
            cloudShading = pow(max(cloudShading, 0.0), 0.8);

            // Secondary cloud self-shadow samples
            float cloudShadingM = 1.0 - cloudShading;
            float gradientNoise = fract(52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y));

            vec3 cLightPos    = tracePosM;
            vec3 cLightPosAdd = normalize(vec3(sun_dir.x, 0.1, sun_dir.z)) * 0.08;
            float VdotSM1 = max(isDay > 0.5 ? VdotS : -VdotS, 0.0);
            float VdotSM2 = VdotSM1 * 0.25 + 0.5 * cloudShading + 0.08;

            float light = 2.0;
            cLightPos += (1.0 + gradientNoise) * cLightPosAdd;
            light -= CR_Get2DCloudSample(cLightPos.xz) * cloudShadingM;
            cLightPos += gradientNoise * cLightPosAdd;
            light -= CR_Get2DCloudSample(cLightPos.xz) * cloudShadingM;
            cloudShading = VdotSM2 * light * lightMult;

            // Final cloud color
            vec3 colorSample = cloudAmbientColor * 0.95 * (1.0 - 0.35 * cloudShading)
                             + cloudLightColor * (0.1 + cloudShading);

            // Fog towards horizon
            float distanceRatio   = (distanceThreshold - lTracePosXZ) / distanceThreshold;
            float cloudFogFactor  = (distanceRatio * distanceRatio) * 0.75;
            float skyMult1 = 1.0 - 0.2 * (1.0 - skyFade) * max(isDay, 0.5 * (1.0 - isDay));
            float skyMult2 = 1.0 - 0.33333 * skyFade;
            colorSample = mix(sky_col, colorSample * skyMult1, cloudFogFactor * skyMult2);

            float cloudDistanceFactor = clamp(distanceRatio, 0.0, 0.75);
            volumetricClouds.a   = sqrt(cloudDistanceFactor * 1.33333) * cloudMult;
            volumetricClouds.rgb = colorSample;

            cloudLinearDepth = sqrt(lTracePos / far);
            break;
        }
    }

    return volumetricClouds;
}

#endif // INCLUDE_CR_CLOUDS_INTEGRATION
