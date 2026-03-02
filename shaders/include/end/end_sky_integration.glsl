/*
--------------------------------------------------------------------------------
  OffShades Shader — Iteration End Sky Integration

  Source: Iteration T 3.2.0 by Tahnass
  Files: Lib/IndividualFounctions/EndSky.glsl, Lib/Utilities.glsl

  Adapted for the Photon shader base: uses Photon uniforms
  (noisetex, frameTimeCounter, frameCounter, sun_dir, etc.)

  Provides:
  - BlackHole_AccretionDisc_Stars()  — black hole + accretion disc + stars
  - PlanetEnd2()                     — ringed planet orbiting in the End
  - EndFog()                         — volumetric End fog

--------------------------------------------------------------------------------
*/

#ifndef INCLUDE_ITERATION_END_SKY
#define INCLUDE_ITERATION_END_SKY

// -----------------------------------------------
//  Constants & Utility macros (from Iteration)
// -----------------------------------------------

#define saturate(x)  clamp(x, 0.0, 1.0)
#define curve(x)     (x * x * (3.0 - 2.0 * x))
#define TAU          6.28318530718
#define hPI          1.57079632679
#define PI           3.14159265359
#define rPI          0.31830988618
#define goldenRatio  1.61803398875
#define plasticRatio 1.32471795724

float END_fsqrt(float x) { return intBitsToFloat(0x1fbd1df5 + (floatBitsToInt(x) >> 1)); }

float END_RayleighPhaseFunction(float nu) {
    return 0.059683104 * (nu * nu + 1.0);
}

float END_MiePhaseFunction(float g, float nu) {
    float gg = g * g;
    float k = 0.1193662 * (1.0 - gg) / (2.0 + gg);
    return k * (1.0 + nu * nu) * pow(1.0 + gg - 2.0 * g * nu, -1.5);
}

float END_InterleavedGradientNoise(vec2 c) {
    return fract(52.9829189 * fract(0.06711056 * c.x + 0.00583715 * c.y));
}

// Temporal blue noise (uses Photon's noisetex)
vec2 END_BlueNoiseTempoal() {
    return fract(
        texelFetch(noisetex, ivec2(gl_FragCoord.xy) % 64, 0).xy
        + vec2(goldenRatio, plasticRatio) * vec2(float(frameCounter % 64))
    );
}

// Blackbody colour (from Iteration Utilities.glsl)
vec3 END_Blackbody(float temperature) {
    const mat2x4 splineX = mat2x4(-0.2661293e9, -0.2343589e6, 0.8776956e3, 0.179910,
                                  -3.0258469e9,  2.1070479e6, 0.2226347e3, 0.240390);
    const mat3x4 splineY = mat3x4(-1.1063814, -1.34811020, 2.18555832, -0.20219683,
                                  -0.9549476, -1.37418593, 2.09137015, -0.16748867,
                                   3.0817580, -5.87338670, 3.75112997, -0.37001483);
    float rt = 1.0 / temperature;
    float rt2 = rt * rt;
    vec4 coeffX = vec4(rt2 * rt, rt2, rt, 1.0);
    float x = dot(coeffX, temperature < 4000.0 ? splineX[0] : splineX[1]);
    float x2 = x * x;
    vec4 coeffY = vec4(x2 * x, x2, x, 1.0);
    float z = 1.0 / dot(coeffY, temperature < 2222.0 ? splineY[0] : temperature < 4000.0 ? splineY[1] : splineY[2]);
    vec3 xyz = vec3(x * z, 1.0, z);
    xyz.z -= xyz.x + 1.0;
    const mat3 xyzToSrgb = mat3( 3.24097, -0.96924,  0.05563,
                                 -1.53738,  1.87597, -0.20398,
                                 -0.49861,  0.04156,  1.05697);
    return max(xyzToSrgb * xyz, vec3(0.0));
}

float END_atan2(vec2 v) {
    return v.x == 0.0
        ? (1.0 - step(abs(v.y), 0.0)) * sign(v.y) * hPI
        : atan(v.y / v.x) + step(v.x, 0.0) * sign(v.y) * PI;
}

vec3 END_RayPlaneIntersection(vec3 ori, vec3 dir, vec3 normal) {
    float rpA = dot(dir, normal);
    float dist = 1e8;
    vec3 result = dir * dist;
    if (abs(rpA) > 0.0001) {
        dist = dot(-ori, normal) / rpA;
        result = ori + dir * dist;
    }
    return result;
}

vec2 END_RaySphereIntersection(vec3 ori, vec3 dir, float radius) {
    float b = dot(ori, dir);
    float c = -radius * radius + dot(ori, ori);
    float d = b * b - c;
    vec2 intersection = vec2(1e10, -1e10);
    if (d >= 0.0) {
        d = sqrt(d);
        intersection = vec2(-b - d, -b + d);
    }
    return intersection;
}

// -----------------------------------------------
//  Planet cycle timing
// -----------------------------------------------
// planet cycles every END_PLANET_CYCLE minutes (default: 25 min)
#ifndef END_PLANET_CYCLE
#define END_PLANET_CYCLE 25.0
#endif
float end_timeFactor = fract(frameTimeCounter * ((1.0 / 60.0) / END_PLANET_CYCLE) + 0.282) * TAU;
float end_planetShadow = smoothstep(0.62, 0.35, end_timeFactor) + smoothstep(1.6, 1.87, end_timeFactor);

// -----------------------------------------------
//  Stars
// -----------------------------------------------
vec3 END_CalculateStars(vec3 worldDir, vec3 worldSunVec) {
    float angleY = frameTimeCounter * 0.001;
    mat3 rotY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));
    worldDir = rotY * worldDir;

    const float scale        = 384.0;
    const float coverage     = 0.007;
    const float maxLuminance = 0.04;
    const float minTemp      = 4000.0;
    const float maxTemp      = 8000.0;

    float cosine = dot(worldSunVec, vec3(0, 0, 1));
    vec3  axis   = cross(worldSunVec, vec3(0, 0, 1));
    float csc2   = 1.0 / dot(axis, axis);
    worldDir = cosine * worldDir + cross(axis, worldDir) + (csc2 - csc2 * cosine) * dot(axis, worldDir) * axis;

    vec3  p = worldDir * scale;
    ivec3 i = ivec3(floor(p));
    vec3  f = p - vec3(i);
    float r = dot(f - 0.5, f - 0.5);

    vec3 i3 = fract(vec3(i) * vec3(443.897, 441.423, 437.195));
    i3 += dot(i3, i3.yzx + 19.19);
    vec2 hash = fract((i3.xx + i3.yz) * i3.zy);
    hash.y = 2.0 * hash.y - 4.0 * hash.y * hash.y + 3.0 * hash.y * hash.y * hash.y;

    float c = clamp((hash.x - (1.0 - coverage)) / coverage, 0.0, 1.0);
    return (maxLuminance * clamp((0.25 - r) / (0.25 - 0.0), 0.0, 1.0) * c * c)
         * END_Blackbody(mix(minTemp, maxTemp, hash.y));
}

// -----------------------------------------------
//  Helper: pcurve for disc
// -----------------------------------------------
float END_pcurve(float x) {
    float x2 = x * x;
    return 12.207 * x2 * x2 * (1.0 - x);
}
float END_Disc(float a, float s, float h) {
    float disc = clamp((a - (1.0 - s)) * h, 0.0, 1.0);
    return disc * disc;
}

// -----------------------------------------------
//  Sub-surface scattering helper (planet surface)
// -----------------------------------------------
vec3 END_H(vec3 albedo, float a) {
    vec3 R = sqrt(vec3(1.0) - albedo);
    vec3 r = (1.0 - R) / (1.0 + R);
    vec3 Hv = r + (0.5 - r * a) * log((1.0 + a) / a);
    Hv *= albedo * a;
    return 1.0 / (1.0 - Hv);
}
vec3 END_ppss(vec3 albedo, vec3 normal, vec3 eyeDir, vec3 lightDir, float s) {
    float NdotL = dot(normal, lightDir);
    float NdotV = dot(normal, eyeDir);
    albedo *= clamp(NdotL * NdotL * (3.0 - 2.0 * NdotL), 0.0, 1.0);
    vec3 c = albedo * END_H(albedo, NdotL) * END_H(albedo, NdotV) / (4.0 * PI * (NdotL + NdotV));
    return clamp(c, vec3(0.0), vec3(1.0));
}

// -----------------------------------------------
//  3D noise utilities for cloud FBM (black hole disc)
// -----------------------------------------------
float END_3DNoise(vec3 position) {
    vec3 p = floor(position);
    vec3 b = curve(fract(position));
    vec2 uv = 17.0 * p.z + p.xy + b.xy;
    vec2 rg = textureLod(noisetex, (uv + 0.5) / 64.0, 0.0).zx;
    return mix(rg.x, rg.y, b.z);
}

float END_CloudFBM(vec3 position, vec3 shift) {
    const int   octaves  = 4;
    const float octAlpha = 0.87;
    const float octScale = 2.5;
    const float octShift = (octAlpha / octScale) / float(octaves);
    float accum = 0.0, alpha = 0.5;
    for (int i = 0; i < octaves; i++) {
        accum    += alpha * END_3DNoise(position);
        position  = (position + shift) * octScale;
        alpha    *= octAlpha;
    }
    return accum + octShift;
}

// -----------------------------------------------
//  WarpSpace (gravitational lensing)
// -----------------------------------------------
void END_WarpSpace(inout vec3 eyevec, inout vec3 raypos) {
    vec3  origin = vec3(0.0);
    float singularityDist = distance(raypos, origin);
    float warpFactor = 1.0 / (singularityDist * singularityDist + 0.000001);
    vec3  singularityVector = normalize(origin - raypos);
    float warpAmount = 0.06;
    eyevec = normalize(eyevec + singularityVector * warpFactor * warpAmount);
}

// -----------------------------------------------
//  Rotation matrix
// -----------------------------------------------
mat3 END_RotateMatrix(float x, float y, float z) {
    mat3 matx = mat3(1.0, 0.0, 0.0, 0.0, cos(x), sin(x), 0.0, -sin(x), cos(x));
    mat3 maty = mat3(cos(y), 0.0, -sin(y), 0.0, 1.0, 0.0, sin(y), 0.0, cos(y));
    mat3 matz = mat3(cos(z), sin(z), 0.0, -sin(z), cos(z), 0.0, 0.0, 0.0, 1.0);
    return maty * matx * matz;
}

// -----------------------------------------------
//  BLACK HOLE + ACCRETION DISC + STARS
// -----------------------------------------------
void BlackHole_AccretionDisc_Stars(inout vec3 color, in vec3 rayDir, in vec3 lightDir) {
    const float steps     = 50.0;
    const float rSteps    = 1.0 / steps;
    const float stepLength = 0.2;

    const float discRadius = 2.25;
    const float discWidth  = 3.5;
    const float discInner  = discRadius - discWidth * 0.5;
    const float discOuter  = discRadius + discWidth * 0.5;

    vec2  blueNoise = END_BlueNoiseTempoal();
    float noise     = blueNoise.x;

    vec3 eye    = -lightDir * 8.0;
    vec3 rayPos = eye + rayDir * 3.0;

    mat3 rotation = END_RotateMatrix(0.1, 0.0, -0.35);

    vec3  result       = vec3(0.0);
    float transmittance = 1.0;

    rayPos += rayDir * stepLength * noise;

    for (int i = 0; i < int(steps); i++) {
        if (transmittance < 0.0001) break;

        END_WarpSpace(rayDir, rayPos);
        rayPos += rayDir * stepLength;

        {
            vec3  discPos = rotation * rayPos;
            float r = length(discPos);
            float p = END_atan2(-discPos.zx);
            float h = discPos.y;

            float radialGradient  = 1.0 - clamp((r - discInner) / discWidth * 0.5, 0.0, 1.0);
            float dist            = abs(h);
            float discThickness   = 0.1 * radialGradient;

            float fr = abs(r - discInner) + 0.4;
            fr = fr * fr;
            float fade = fr * fr * 0.04;
            float bloomFactor = 1.0 / (h * h * 40.0 + fade + 0.00002);
            bloomFactor *= clamp(2.0 - abs(dist) / discThickness, 0.0, 1.0);
            bloomFactor  = bloomFactor * bloomFactor;

            float dr      = END_pcurve(radialGradient);
            float density = dr;
            density *= clamp(1.0 - abs(dist) / discThickness, 0.0, 1.0);
            density  = clamp(density * 0.7, 0.0, 1.0);
            density  = clamp(density + bloomFactor * 0.1, 0.0, 1.0);

            if (density > 0.0001) {
                vec3  discCoord = vec3(r, 0.0, h * 0.1) * 3.5;
                float fbm = END_CloudFBM(discCoord, frameTimeCounter * vec3(0.03, 0.05, 0.0));
                fbm = fbm * fbm; fbm = fbm * fbm;
                density *= fbm * dr;

                float gr = 1.0 - radialGradient;
                gr = gr * gr;
                float glowStrength = 1.0 / (gr * gr * 400.0 + 0.002);
                vec3  glow = END_Blackbody(2700.0 + glowStrength * 50.0) * glowStrength;

                float stepTransmittance = exp2(-density * 7.0);
                float integral = 1.0 - stepTransmittance;
                transmittance *= stepTransmittance;
                result += integral * transmittance * glow;
            }

            // Corona glow ring
            vec2  t        = vec2(1.0, 0.01);
            float torusDist = length(vec2(length(discPos + vec3(0.0, -0.05, 0.0))) - t);
            float bloomDisc = 1.0 / (pow(torusDist, 3.5) + 0.001);
            vec3  col       = END_Blackbody(12000.0);
            bloomDisc *= step(0.5, r);
            result += col * bloomDisc * 0.1 * transmittance;
        }
    }
    result *= rSteps;

    // Stars
    color += END_CalculateStars(rayDir, lightDir);

    color *= transmittance;
    color += result;
}

// -----------------------------------------------
//  RINGED PLANET (PlanetEnd2 from Iteration)
// -----------------------------------------------
void PlanetEnd2(inout vec3 color, in vec3 eye_offset, in vec3 rayDir, in vec3 lightDir) {
    const float Rground = 20e6;
    const float Ratmo   = 20.1e6;
    vec3 eye = eye_offset;
    eye.y += Rground;
    eye.y += 15e6;

    float VdotL = dot(lightDir, rayDir);
    float mie   = END_MiePhaseFunction(0.8, VdotL);

    float angleX = -hPI + (0.2 * sin(end_timeFactor + 3.0) - 0.1);
    float angleY = end_timeFactor;

    mat3 rotX = mat3(1, 0, 0, 0, cos(angleX), -sin(angleX), 0, sin(angleX), cos(angleX));
    mat3 rotY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));
    mat3 eyeRot = rotX * rotY;

    float ringAngle = 0.008 * sin(end_timeFactor + 4.6);
    mat3 ringRot    = mat3(1.0, 0.0, 0.0,
                           0.0, cos(ringAngle), sin(ringAngle),
                           0.0, -sin(ringAngle), cos(ringAngle));
    mat3 ringRotInv = transpose(ringRot);

    vec3 rd    = eyeRot * rayDir;
    vec3 ld    = eyeRot * lightDir;
    vec3 rdRing = ringRot * rd;
    vec3 ldRing = ringRot * ld;
    vec3 ringOrigin = vec3(0.0, cos(ringAngle), sin(ringAngle)) * (eye.y / Rground);
    vec2 ringRadius = vec2(1.6, 2.6);

    vec3  surface = vec3(0.0);
    vec2  groundIntersection = END_RaySphereIntersection(eye, rd, Rground);
    vec2  topAtmoIntersection = END_RaySphereIntersection(eye, rd, Ratmo);

    vec3 surfacePos    = rd * groundIntersection.x;
    vec3 surfaceNormal = normalize(surfacePos + vec3(0.0, eye.y, 0.0));

    if (groundIntersection.y > 0.0) {
        color *= 0.0;
        vec3 surfaceAlbedo = vec3(0.98, 0.87, 0.55);
        surface = END_ppss(surfaceAlbedo, surfaceNormal, -rd, ld, 1.0);

        // Ring shadow on planet surface
        vec3 rayPos2 = ringOrigin + surfacePos / Rground;
        vec3 rayPos3 = END_RayPlaneIntersection(rayPos2, ldRing, vec3(0.0, 0.0, 1.0));
        float rayRadius3 = length(rayPos3);
        if (rayRadius3 > ringRadius.x && rayRadius3 < ringRadius.y && dot(rayPos3 - rayPos2, ldRing) > 0.0) {
            const float octAlpha = 0.5;
            float octScale = 4.0;
            float accum = 0.0, alpha2 = 0.5;
            float position = rayRadius3 * 0.5 + 0.69;
            for (int i = 0; i < 5; i++) {
                accum += alpha2 * textureLod(noisetex, vec2(position, 0.0), 0.0).z;
                position = position * octScale;
                alpha2  *= octAlpha;
            }
            surface *= exp(-pow(clamp(accum + (octAlpha / octScale) / 5.0 - 0.1, 0.0, 1.0) * 1.5, 3.0)
                          * smoothstep(ringRadius.x, ringRadius.x * 1.1, rayRadius3));
        }

        float UdotN   = clamp(dot(ringRotInv[2], surfaceNormal), 0.0, 1.0);
        float DdotN   = clamp(dot(-ringRotInv[2], surfaceNormal), 0.0, 1.0);
        float OLdotN  = clamp(dot(ringRotInv * normalize(vec3(-ld.xy, 0.0)), surfaceNormal), 0.0, 1.0);
        float ringLighting  = END_Disc(UdotN, 1.2, 1.5) * (1.0 - END_Disc(UdotN, 3.4, 0.3));
              ringLighting += END_Disc(DdotN, 1.2, 1.5) * (1.0 - END_Disc(DdotN, 3.4, 0.3));
              ringLighting *= 1.0 - END_Disc(OLdotN, 0.7, 1.3);
        surface += surfaceAlbedo * (1.5e-4 + ringLighting * 0.01);
    }

    if (topAtmoIntersection.y > 0.0) {
        float isGround   = step(0.0, groundIntersection.y);
        float thickness  = (topAtmoIntersection.y - topAtmoIntersection.x
                          - (groundIntersection.y - groundIntersection.x) * isGround) * 1e-7;
        float topAtmoMie = mie * thickness * thickness;
        topAtmoMie *= mix(1.0, smoothstep(0.9, 0.4, dot(surfaceNormal, normalize(eye))), isGround);
        surface += topAtmoMie * vec3(0.65, 0.7, 1.0);
    }

    color += surface * 0.6;

    // Rings
    float inRing = clamp(abs(ringAngle) * 3000.0 - 0.8, 0.0, 1.0);
    float ring = 0.0;
    float ringTransmittance = 1.0;

    if (rdRing.z * ringAngle < 0.0) {
        vec3  ringorig  = vec3(0.0, cos(ringAngle), sin(ringAngle)) * (eye.y / Rground);
        vec3  ringPos   = END_RayPlaneIntersection(ringorig, rdRing, vec3(0.0, 0.0, 1.0));
        float rayRadius4 = length(ringPos);

        if (rayRadius4 > ringRadius.x && rayRadius4 < ringRadius.y) {
            const float octAlpha2 = 0.5;
            float octScale2 = 4.0;
            float accum2 = 0.0, alpha3 = 0.5;
            float position2 = rayRadius4 * 0.5 + 0.69;
            for (int i = 0; i < 5; i++) {
                accum2   += alpha3 * textureLod(noisetex, vec2(position2, 0.0), 0.0).z;
                position2 = position2 * octScale2;
                alpha3   *= octAlpha2;
            }
            ring += pow(clamp(accum2 + (octAlpha2 / octScale2) / 5.0 - 0.1, 0.0, 1.0) * 1.5, 3.0);
            ring *= smoothstep(ringRadius.x, ringRadius.x * 1.1, rayRadius4);

            if (ringPos.y < 0.0 && groundIntersection.y > 0.0) {
                ring *= 0.0;
            } else {
                ringTransmittance *= exp2(-ring * 3.0);
            }

            float d = length(cross(ldRing, ringPos));
            ring *= 0.98 * max(smoothstep(0.8, 1.2, d), step(0.0, dot(ldRing, ringPos))) + 0.02;
        }
    }

    ring = mix(end_planetShadow * 0.49 + 0.01, ring, inRing);
    ringTransmittance = mix(0.7, ringTransmittance, inRing);

    color *= ringTransmittance;

    float mieVdotL = END_MiePhaseFunction(0.8, dot(lightDir, rayDir));
    ring  *= 1.0 + mieVdotL * 10.0 * end_planetShadow;
    color += ring * 0.012 * vec3(1.0, 0.85, 0.60);
}

// -----------------------------------------------
//  END FOG (Iteration)
// -----------------------------------------------
vec3 EndFog(float dist, vec3 worldDir, vec3 lightDir) {
    float VdotL = dot(lightDir, worldDir);
    float angleX = -hPI + (0.2 * sin(end_timeFactor + 3.0) - 0.1) - 0.008 * sin(end_timeFactor + 4.7);
    float angleY = end_timeFactor;
    mat3 rotX = mat3(1.0, 0.0, 0.0, 0.0, cos(angleX), -sin(angleX), 0.0, sin(angleX), cos(angleX));
    mat3 rotY = mat3(cos(angleY), 0.0, sin(angleY), 0.0, 1.0, 0.0, -sin(angleY), 0.0, cos(angleY));
    worldDir = rotX * rotY * worldDir;
    dist = min(dist, 512.0);
    float h = abs(worldDir.z) * dist * 0.03;
    float density = (1.0 - exp(-h)) / max(h, 0.001) * dist;
    density *= END_MiePhaseFunction(0.3, VdotL) * 10.0 * end_planetShadow + 0.25;
    density *= end_planetShadow * 0.93 + 0.07;
    return vec3(density * 1e-5);
}

#endif // INCLUDE_ITERATION_END_SKY
