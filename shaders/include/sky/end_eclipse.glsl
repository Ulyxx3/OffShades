#if !defined INCLUDE_SKY_END_ECLIPSE
#define INCLUDE_SKY_END_ECLIPSE

/*
--------------------------------------------------------------------------------
  OffShades - End Dimension Solar Alignment & Eclipse System
--------------------------------------------------------------------------------
*/

#ifndef SATURN_REVOLUTION_TIME
#define SATURN_REVOLUTION_TIME 300
#endif

// -----------------------------------------------------------------------------
//   End Sun Direction (~20° Cinematic Elevation)
// -----------------------------------------------------------------------------

vec3 get_end_sun_dir(vec3 rawSunDir) {
    vec2 xz = normalize(rawSunDir.xz);
    const float elevationSin = 0.35; // ~20.5 degrees elevation
    const float elevationCos = 0.9367497; // sqrt(1 - 0.35^2)
    return normalize(vec3(xz.x * elevationCos, elevationSin, xz.y * elevationCos));
}

// -----------------------------------------------------------------------------
//   End Shadow Alignment Rotation
//   Rotates world-space coordinates such that the visual Sun direction (endSun)
//   aligns with the engine's shadow camera optical axis (origSun).
// -----------------------------------------------------------------------------

mat3 get_end_shadow_rotation(vec3 endSun, vec3 origSun) {
    vec3 v = cross(endSun, origSun);
    float c = dot(endSun, origSun);
    float s2 = dot(v, v);
    if (s2 < 1e-9) {
        return c > 0.0 ? mat3(1.0) : mat3(-1.0);
    }
    float f = (1.0 - c) / s2;
    return mat3(
        1.0 + f * (-v.z * v.z - v.y * v.y),
        v.z + f * (v.x * v.y),
        -v.y + f * (v.x * v.z),

        -v.z + f * (v.x * v.y),
        1.0 + f * (-v.z * v.z - v.x * v.x),
        v.x + f * (v.y * v.z),

        v.y + f * (v.x * v.z),
        -v.x + f * (v.y * v.z),
        1.0 + f * (-v.y * v.y - v.x * v.x)
    );
}

// -----------------------------------------------------------------------------
//   Saturn Observer Eye Rotation Matrix
// -----------------------------------------------------------------------------

mat3 get_end_saturn_eye_rot(float time) {
    float timeFactor = fract(time / float(SATURN_REVOLUTION_TIME) + 0.282) * 6.283185307;
    float angleX = -1.57079633 + (0.10 * sin(timeFactor + 3.0) - 0.03);
    float angleY = timeFactor;

    mat3 eyeRotX = mat3(1.0, 0.0, 0.0,
                        0.0, cos(angleX), -sin(angleX),
                        0.0, sin(angleX),  cos(angleX));
    mat3 eyeRotY = mat3(cos(angleY), 0.0, sin(angleY),
                        0.0,         1.0, 0.0,
                       -sin(angleY), 0.0, cos(angleY));
    return eyeRotX * eyeRotY;
}

// -----------------------------------------------------------------------------
//   Solar Eclipse Occlusion Factor (0.0 = total eclipse, 1.0 = full sun)
// -----------------------------------------------------------------------------

float get_end_sun_visibility(vec3 sunDir, float time) {
    float timeFactor = fract(time / float(SATURN_REVOLUTION_TIME) + 0.282) * 6.283185307;
    mat3 eyeRot = get_end_saturn_eye_rot(time);
    vec3 sunRay = eyeRot * sunDir;

    const float Rground = 20e6;
    vec3 eye = vec3(0.0, Rground + 15e6, 0.0);

    float b = dot(eye, sunRay);
    float visibility = 1.0;

    // 1. Saturn planet sphere eclipse (penumbra & total eclipse)
    if (b < 0.0) {
        float distSq = dot(eye, eye) - b * b;
        float dist = sqrt(max(0.0, distSq));
        float penumbraWidth = Rground * 0.055;
        float eclipseFactor = smoothstep(Rground - penumbraWidth, Rground + penumbraWidth, dist);
        visibility *= eclipseFactor;
    }

    // 2. Ring occlusion (attenuates sunlight when passing behind rings)
    float ringAngle = 0.007 * sin(timeFactor + 4.6);
    mat3 ringRot = mat3(1.0, 0.0, 0.0,
                        0.0, cos(ringAngle), sin(ringAngle),
                        0.0, -sin(ringAngle), cos(ringAngle));
    vec3 rayRing = ringRot * sunRay;

    if (rayRing.z * ringAngle < 0.0) {
        vec3 ringOrigin = vec3(0.0, cos(ringAngle), sin(ringAngle)) * (eye.y / Rground);
        float ringDist = -ringOrigin.z / (abs(rayRing.z) > 1e-5 ? rayRing.z : 1e-5);
        vec3 ringPos = ringOrigin + rayRing * ringDist;
        float rayRad = length(ringPos);
        vec2 ringRadius = vec2(1.52, 2.65);
        if (rayRad > ringRadius.x && rayRad < ringRadius.y) {
            float cassiniGap = smoothstep(0.015, 0.045, abs(rayRad - 2.02));
            float ringShadow = mix(0.35, 0.75, cassiniGap);
            visibility *= ringShadow;
        }
    }

    return visibility;
}

#endif // INCLUDE_SKY_END_ECLIPSE
