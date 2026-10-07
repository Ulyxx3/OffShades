#if !defined INCLUDE_SKY_END_COSMIC_SKY
#define INCLUDE_SKY_END_COSMIC_SKY

/*
--------------------------------------------------------------------------------

  OffShades - End Dimension Cosmic Sky System
  Inspired by IterationT 3.2.0 / 3.3

  Specifications:
  1. Saturn & Rings:
     - Pure inky black void (no green/purple fog or streaks).
     - Camera perspective floating directly within the ring plane.
     - Textured rings with Cassini division, fine ringlets, and bidirectional shadows.
  2. Radiant Sun & Compact Corona (lower elevation ~20°):
     - Placed at comfortable cinematic height.
     - Blazing white-hot core, tight corona, and clean contrast with surrounding space.
  3. Animated Keplerian Solar System & Orbits:
     - All 8 planetary orbits traced around the Sun.
     - Saturn's orbit passes directly through Saturn.
     - Every planet revolves along its orbit over time and lies exactly on its line.

--------------------------------------------------------------------------------
*/

#include "/include/sky/end_eclipse.glsl"
#include "/include/utility/color.glsl"
#include "/include/utility/fast_math.glsl"
#include "/include/utility/phase_functions.glsl"

// -----------------------------------------------------------------------------
//   Math & Raytracing Utilities
// -----------------------------------------------------------------------------

vec2 ray_sphere_intersection(vec3 ori, vec3 dir, float radius) {
    float b = dot(ori, dir);
    float c = dot(ori, ori) - radius * radius;
    float d = b * b - c;
    if (d < 0.0) return vec2(1e10, -1e10);
    float sqrtd = sqrt(d);
    return vec2(-b - sqrtd, -b + sqrtd);
}

vec3 ray_plane_intersection(vec3 ori, vec3 dir, vec3 normal) {
    float angle = dot(dir, normal);
    float dist = 1e8;
    if (abs(angle) > 1e-5) {
        dist = -dot(ori, normal) / angle;
    }
    return ori + dir * dist;
}

vec3 chandrasekhar_h(vec3 albedo, float a) {
    vec3 R = sqrt(max(vec3(0.0), vec3(1.0) - albedo));
    vec3 r = (1.0 - R) / (1.0 + R);
    vec3 H = r + (0.5 - r * a) * log((1.0 + a) / max(a, 1e-4));
    H *= albedo * a;
    return 1.0 / max(vec3(1e-4), vec3(1.0) - H);
}

vec3 planetary_ppss(vec3 albedo, vec3 normal, vec3 eyeDir, vec3 lightDir) {
    float NdotL = clamp(dot(normal, lightDir), 0.0, 1.0);
    float NdotV = clamp(dot(normal, eyeDir), 0.0, 1.0);
    float c = NdotL * NdotL * (3.0 - 2.0 * NdotL);
    albedo *= c;
    vec3 col = albedo * chandrasekhar_h(albedo, NdotL) * chandrasekhar_h(albedo, NdotV)
             / max(4.0 * pi * (NdotL + NdotV), 1e-4);
    return clamp(col, 0.0, 1.0);
}

float mie_phase_custom(float g, float nu) {
    float gg = g * g;
    float k = 0.1193662 * (1.0 - gg) / (2.0 + gg);
    return k * (1.0 + nu * nu) * pow(max(1e-4, 1.0 + gg - 2.0 * g * nu), -1.5);
}

// -----------------------------------------------------------------------------
//   Cosmic Starfield (Deep Black Space, No Green Wash)
// -----------------------------------------------------------------------------

vec3 draw_cosmic_stars(vec3 worldDir) {
    float angleY = frameTimeCounter * 0.0002;
    mat3 rotY = mat3(cos(angleY), 0.0, sin(angleY),
                     0.0,         1.0, 0.0,
                    -sin(angleY), 0.0, cos(angleY));
    vec3 dir = rotY * worldDir;

    const float scale = 400.0;
    const float coverage = 0.008;
    const float maxLuminance = 1.8;

    vec3 axis = normalize(vec3(0.3, 0.9, 0.1));
    float cosine = dot(axis, vec3(0.0, 0.0, 1.0));
    vec3 crossA = cross(axis, vec3(0.0, 0.0, 1.0));
    float crossLen2 = dot(crossA, crossA);
    if (crossLen2 > 1e-4) {
        dir = cosine * dir + cross(crossA, dir) + (1.0 - cosine) * dot(crossA, dir) * crossA / crossLen2;
    }

    vec3 p = dir * scale;
    ivec3 i = ivec3(floor(p));
    vec3 f = p - vec3(i);
    float r = dot(f - 0.5, f - 0.5);

    vec3 i3 = fract(vec3(i) * vec3(443.897, 441.423, 437.195));
    i3 += dot(i3, i3.yzx + 19.19);
    vec2 hash = fract((i3.xx + i3.yz) * i3.zy);
    hash.y = 2.0 * hash.y - 4.0 * hash.y * hash.y + 3.0 * hash.y * hash.y * hash.y;

    float c = clamp((hash.x - (1.0 - coverage)) / coverage, 0.0, 1.0);
    float starPoint = clamp((0.25 - r) / 0.25, 0.0, 1.0);

    float twinkle = 0.85 + 0.15 * sin(frameTimeCounter * 2.5 + hash.x * 62.83);
    vec3 starCol = blackbody(mix(3600.0, 9500.0, hash.y));

    return (maxLuminance * starPoint * c * c * twinkle) * starCol;
}

// -----------------------------------------------------------------------------
//   Saturn & Planetary Rings
// -----------------------------------------------------------------------------

#ifndef SATURN_REVOLUTION_TIME
#define SATURN_REVOLUTION_TIME 300
#endif
#ifndef PLANETS_REVOLUTION_TIME
#define PLANETS_REVOLUTION_TIME 120
#endif

mat3 get_saturn_eye_rot() {
    return get_end_saturn_eye_rot(frameTimeCounter);
}

vec3 get_saturn_center_dir() {
    mat3 eyeRot = get_saturn_eye_rot();
    return transpose(eyeRot) * vec3(0.0, -1.0, 0.0);
}

void draw_saturn_and_rings(
    inout vec3 sky,
    vec3 worldRayDir,
    vec3 worldLightDir,
    vec3 saturnCenterDir
) {
    float timeFactor = fract(frameTimeCounter / float(SATURN_REVOLUTION_TIME) + 0.282) * tau;
    float planetShadowFactor = smoothstep(0.62, 0.35, timeFactor) + smoothstep(1.6, 1.87, timeFactor);

    mat3 eyeRot = get_saturn_eye_rot();

    // Ring tilt relative to observer (very close to zero = floating in the rings)
    float ringAngle = 0.007 * sin(timeFactor + 4.6);
    mat3 ringRot = mat3(1.0, 0.0, 0.0,
                        0.0, cos(ringAngle), sin(ringAngle),
                        0.0, -sin(ringAngle), cos(ringAngle));

    vec3 rayDir = eyeRot * worldRayDir;
    vec3 lightDir = eyeRot * worldLightDir;

    vec3 rayDirRing = ringRot * rayDir;
    vec3 lightDirRing = ringRot * lightDir;

    const float Rground = 20e6;
    const float Ratmo   = 20.15e6;
    vec3 eye = vec3(0.0, Rground + 15e6, 0.0); // Inside the ring radial zone

    vec3 ringOrigin = vec3(0.0, cos(ringAngle), sin(ringAngle)) * (eye.y / Rground);
    vec2 ringRadius = vec2(1.52, 2.65); // Radii in units of Rground

    vec3 saturnSurface = vec3(0.0);
    float VdotL = dot(worldLightDir, worldRayDir);
    float mie = mie_phase_custom(0.80, VdotL);

    vec2 groundIntersection = ray_sphere_intersection(eye, rayDir, Rground);
    vec2 atmoIntersection   = ray_sphere_intersection(eye, rayDir, Ratmo);

    // 1. Saturn planet sphere: 100% OPAQUE (blocks all background stars, Sun, planets)
    if (groundIntersection.y > 0.0) {
        // Zero out whatever was behind Saturn in sky: Saturn is 100% solid and opaque!
        sky *= 0.0;

        vec3 surfacePos = rayDir * groundIntersection.x;
        vec3 surfaceNormal = normalize(surfacePos + vec3(0.0, eye.y, 0.0));

        // Atmospheric cloud banding with warm honey and caramel tones
        float lat = surfaceNormal.y;
        float band1 = sin(lat * 28.0) * 0.05;
        float band2 = sin(lat * 65.0) * 0.03;
        float band3 = sin(lat * 120.0) * 0.015;
        float stormTurbulence = (texture(noisetex, vec2(lat * 6.0, 0.5)).x - 0.5) * 0.03;
        float bands = band1 + band2 + band3 + stormTurbulence;

        float polarDarkening = mix(0.78, 1.0, smoothstep(0.85, 0.25, abs(lat)));

        // Warm golden honey & caramel ochre palette for Saturn
        vec3 baseHoney   = vec3(1.00, 0.84, 0.56);
        vec3 warmCaramel = vec3(0.96, 0.68, 0.40);
        vec3 surfaceAlbedo = mix(baseHoney, warmCaramel, clamp01(bands * 3.0 + 0.5)) * polarDarkening;

        // Realistic planetary scattering (Hapke / Chandrasekhar PPSS):
        // Automatically drops to 0 on the dark hemisphere (eclipse side) facing the player!
        saturnSurface = planetary_ppss(surfaceAlbedo, surfaceNormal, -rayDir, lightDir) * 1.5;

        // Shadow of the Rings cast onto Saturn's cloud tops!
        vec3 origin = ringOrigin + surfacePos / Rground;
        vec3 rayPos = ray_plane_intersection(origin, lightDirRing, vec3(0.0, 0.0, 1.0));
        float rayRad = length(rayPos);

        if (rayRad > ringRadius.x && rayRad < ringRadius.y && dot(rayPos - origin, lightDirRing) > 0.0) {
            float pos = rayRad * 0.5 + 0.69;
            float accum = 0.0;
            float alpha = 0.5;
            for (int i = 0; i < 5; ++i) {
                accum += alpha * textureLod(noisetex, vec2(pos, 0.0), 0.0).z;
                pos *= 4.0;
                alpha *= 0.5;
            }
            // Deep, sharp ring shadow extinction on the cloud tops
            float shadowExtinction = exp(-pow(clamp(accum - 0.05, 0.0, 1.0) * 1.6, 3.0)
                                   * smoothstep(ringRadius.x, ringRadius.x * 1.10, rayRad));
            saturnSurface *= shadowExtinction;
        }

        // Night-side ringlight: subtle illumination from the rings on the dark hemisphere
        mat3 ringRotInv = transpose(ringRot);
        float UdotN = clamp(dot(ringRotInv[2], surfaceNormal), 0.0, 1.0);
        float DdotN = clamp(dot(-ringRotInv[2], surfaceNormal), 0.0, 1.0);
        float OLdotN = clamp(dot(ringRotInv * normalize(vec3(-lightDir.xy, 0.0)), surfaceNormal), 0.0, 1.0);

        float discU = clamp((UdotN - (1.0 - 1.2)) * 1.5, 0.0, 1.0);
        discU = discU * discU * (3.0 - 2.0 * discU);
        float discU2 = clamp((UdotN - (1.0 - 3.4)) * 0.3, 0.0, 1.0);
        discU2 = discU2 * discU2 * (3.0 - 2.0 * discU2);
        float ringLighting = (discU * discU) * (1.0 - discU2 * discU2);

        float discD = clamp((DdotN - (1.0 - 1.2)) * 1.5, 0.0, 1.0);
        discD = discD * discD * (3.0 - 2.0 * discD);
        float discD2 = clamp((DdotN - (1.0 - 3.4)) * 0.3, 0.0, 1.0);
        discD2 = discD2 * discD2 * (3.0 - 2.0 * discD2);
        ringLighting += (discD * discD) * (1.0 - discD2 * discD2);

        float discOL = clamp((OLdotN - (1.0 - 0.7)) * 1.3, 0.0, 1.0);
        discOL = discOL * discOL * (3.0 - 2.0 * discOL);
        ringLighting *= (1.0 - discOL * discOL);

        saturnSurface += surfaceAlbedo * (1.5e-4 + ringLighting * 0.015);
    }

    // Atmospheric rim haze on Saturn (ONLY at the grazing silhouette limb, extinguished on the front face!)
    if (atmoIntersection.y > 0.0) {
        float isGround = step(0.0, groundIntersection.y);
        vec3 normalEye = isGround > 0.5 ? normalize(rayDir * groundIntersection.x + vec3(0.0, eye.y, 0.0)) : vec3(0.0, 1.0, 0.0);
        float thickness = (atmoIntersection.y - atmoIntersection.x
                        - (groundIntersection.y - groundIntersection.x) * isGround) * 1e-7;
        float atmoMie = mie * thickness * thickness;
        // Key: extinguish haze on the visible face facing the camera so night side is in deep shadow!
        atmoMie *= mix(1.0, smoothstep(0.9, 0.4, dot(normalEye, normalize(eye))), isGround);
        saturnSurface += atmoMie * vec3(0.95, 0.90, 0.75) * 1.5;
    }

    // Add Saturn's surface into sky (which already zeroed background if hitSaturn)
    sky += saturnSurface * 0.6;

    // 2. Saturn Ring System (IterationT-faithful: translucent cosmic dust with warm golden tones)
    float ring = 0.0;
    float ringTransmittance = 1.0;
    vec3 litRingColor = vec3(0.0);

    if (rayDirRing.z * ringAngle < 0.0) {
        vec3 origin = ringOrigin;
        vec3 ringPos = ray_plane_intersection(origin, rayDirRing, vec3(0.0, 0.0, 1.0));
        float rayRadius = length(ringPos);

        if (rayRadius > ringRadius.x && rayRadius < ringRadius.y) {
            float pos = rayRadius * 0.5 + 0.69;
            float accum = 0.0;
            float alpha = 0.5;
            for (int i = 0; i < 5; ++i) {
                accum += alpha * textureLod(noisetex, vec2(pos, 0.0), 0.0).z;
                pos *= 4.0;
                alpha *= 0.5;
            }

            // Natural ring density curve from IterationT
            ring = pow(clamp(accum - 0.08, 0.0, 1.0) * 1.5, 3.0);
            ring *= smoothstep(ringRadius.x, ringRadius.x * 1.10, rayRadius);
            ring *= smoothstep(ringRadius.y, ringRadius.y * 0.95, rayRadius);

            // Cassini Division gap (subtle translucent slit)
            float cassiniGap = smoothstep(0.015, 0.045, abs(rayRadius - 2.02));
            ring *= mix(0.15, 1.0, cassiniGap);

            if (ringPos.y < 0.0 && groundIntersection.y > 0.0) {
                // Far-side ring is behind Saturn: Saturn occludes it completely!
                ring = 0.0;
            } else {
                // Semi-transparent transmittance: stars and the Sun shine through!
                ringTransmittance = exp2(-ring * 2.5);
            }

            // Shadow of Saturn cast on the rings
            float shadowDist = length(cross(lightDirRing, ringPos));
            ring *= 0.98 * max(smoothstep(0.8, 1.2, shadowDist), step(0.0, dot(lightDirRing, ringPos))) + 0.02;

            // Warm natural golden-ochre dust color (IterationT palette, NOT white!)
            vec3 ringDustColor = vec3(0.88, 0.72, 0.50);
            float ringForwardScattering = 1.0 + mie * 6.0 * planetShadowFactor;
            litRingColor = ring * ringDustColor * ringForwardScattering * 0.035;
        }
    }

    // Edge-on view through the ring plane (delicate golden dust line)
    float inRingPlane = exp(-abs(rayDirRing.z) * 1200.0);
    if (inRingPlane > 0.01) {
        float edgeAlpha = clamp(inRingPlane * 0.8, 0.0, 1.0);
        float edgeTrans = mix(1.0, 0.55, edgeAlpha);
        ringTransmittance = min(ringTransmittance, edgeTrans);
        vec3 edgeColor = vec3(0.88, 0.72, 0.50) * edgeAlpha * (0.025 * planetShadowFactor + 0.008);
        litRingColor += edgeColor;
    }

    // Composite: background stars/sun are visible through the semi-transparent rings
    sky *= ringTransmittance;
    sky += litRingColor;
}

// -----------------------------------------------------------------------------
//   The Solar System: 3D Perspective Revolution & Solar Eclipses / Transits
// -----------------------------------------------------------------------------

struct PlanetOrbit3D {
    float r;         // Orbital distance from Sun (relative to our distance = 1.0)
    float inc;       // Orbital plane inclination (rad)
    float periodMul; // Relative orbital period multiplier (Earth = 1.0)
    float initPhase; // Initial angle (rad)
    float radius;    // Angular disk radius
    vec3 baseCol;    // Planet surface color
    int planetId;    // Planet ID
};

void draw_planet_sphere(
    inout vec3 sky,
    vec3 rayDir,
    vec3 sunDir,
    vec3 planetPos,
    vec3 lightDirToSun,
    float planetRadius,
    vec3 baseCol,
    int planetId
) {
    float cosAngle = dot(rayDir, planetPos);
    float angle = fast_acos(clamp(cosAngle, -1.0, 1.0));

    // Subtle atmospheric / optical halo when not in front of the sun
    if (angle < planetRadius * 2.8) {
        float halo = exp(-angle / (planetRadius * 0.7));
        sky += halo * baseCol * 0.15 * max(0.0, dot(lightDirToSun, -planetPos));
    }

    if (angle > planetRadius) return;

    // Normal on the sphere
    vec3 tangentX = normalize(abs(planetPos.y) < 0.99 ? cross(planetPos, vec3(0.0, 1.0, 0.0)) : cross(planetPos, vec3(1.0, 0.0, 0.0)));
    vec3 tangentY = cross(tangentX, planetPos);

    vec2 offset = vec2(dot(rayDir - planetPos, tangentX), dot(rayDir - planetPos, tangentY)) / planetRadius;
    float r2 = dot(offset, offset);
    if (r2 > 1.0) return;

    float nz = sqrt(max(0.0, 1.0 - r2));
    vec3 sphereNormal = normalize(offset.x * tangentX + offset.y * tangentY + nz * planetPos);

    // Directional solar lighting from actual Sun direction relative to this planet!
    float NdotL = clamp(dot(sphereNormal, lightDirToSun), 0.0, 1.0);
    float limb = pow(1.0 - nz, 2.5);

    vec3 surfaceColor = baseCol;
    vec2 sphereUV = vec2(atan(sphereNormal.x, sphereNormal.z) / tau + 0.5, sphereNormal.y * 0.5 + 0.5);

    if (planetId == 0) { // Mercury: cratered rocky gray
        float craters = texture(noisetex, sphereUV * 6.0).x;
        surfaceColor = mix(baseCol * 0.8, baseCol * 1.15, craters);
    }
    else if (planetId == 1) { // Venus: thick golden clouds
        float clouds = sin(sphereNormal.y * 18.0 + texture(noisetex, sphereUV * 3.0).y * 2.0) * 0.06;
        surfaceColor = baseCol * (1.0 + clouds);
    }
    else if (planetId == 2) { // Earth: blue marble + continents + clouds + Rayleigh limb
        float continentNoise = texture(noisetex, sphereUV * 2.2).x + 0.3 * texture(noisetex, sphereUV * 5.0).y;
        float isLand = smoothstep(0.48, 0.53, continentNoise);
        vec3 oceanCol = vec3(0.04, 0.18, 0.62);
        vec3 landCol  = mix(vec3(0.18, 0.40, 0.15), vec3(0.55, 0.42, 0.22), texture(noisetex, sphereUV * 4.0).z);
        vec3 earthSurface = mix(oceanCol, landCol, isLand);

        float cloudSwirl = texture(noisetex, sphereUV * 3.0 + vec2(frameTimeCounter * 0.0005, 0.0)).z;
        float clouds = smoothstep(0.46, 0.70, cloudSwirl) * 0.85;
        surfaceColor = mix(earthSurface, vec3(1.0), clouds);
        surfaceColor += vec3(0.2, 0.5, 1.0) * limb * 0.75;
    }
    else if (planetId == 3) { // Mars: red desert, maria & polar caps
        float maria = texture(noisetex, sphereUV * 3.5).x;
        vec3 marsSurface = mix(baseCol, baseCol * 0.55, smoothstep(0.45, 0.65, maria));
        float polarCap = smoothstep(0.82, 0.92, abs(sphereNormal.y));
        surfaceColor = mix(marsSurface, vec3(0.95, 0.98, 1.0), polarCap);
    }
    else if (planetId == 4) { // Jupiter: gas bands + Great Red Spot
        float jupLat = sphereNormal.y;
        float bands = sin(jupLat * 28.0) * 0.5 + 0.5;
        vec3 bandCol = mix(vec3(0.92, 0.82, 0.65), vec3(0.70, 0.42, 0.25), bands);
        vec2 spotDist = (sphereUV - vec2(0.55, 0.38)) * vec2(10.0, 18.0);
        float spot = exp(-dot(spotDist, spotDist));
        surfaceColor = mix(bandCol, vec3(0.85, 0.25, 0.12), spot * 0.8);
    }
    else if (planetId == 6) { // Uranus: cyan ice giant
        float uBands = sin(sphereNormal.y * 12.0) * 0.04;
        surfaceColor = baseCol * (1.0 + uBands);
    }
    else if (planetId == 7) { // Neptune: deep royal azure with methane cirrus
        float storms = smoothstep(0.65, 0.85, texture(noisetex, sphereUV * 4.0).x);
        surfaceColor = mix(baseCol, vec3(0.85, 0.95, 1.0), storms * 0.5);
    }

    // Backlit atmospheric thin crescent when between us and Sun (eclipse phase)
    float backlit = pow(1.0 - nz, 4.0) * clamp(dot(lightDirToSun, -planetPos), 0.0, 1.0);
    vec3 litPlanet = surfaceColor * (NdotL * 1.6 + 0.008) + limb * baseCol * (NdotL * 0.3 + backlit * 0.9);

    // Planet completely occludes the background (whether stars OR the bright solar disk!)
    sky = mix(sky, litPlanet, smoothstep(planetRadius, planetRadius * 0.95, angle));
}

void draw_solar_system(
    inout vec3 sky,
    vec3 rayDir,
    vec3 sunDir,
    vec3 saturnDir
) {
    // Ecliptic plane: spanned by sunDir and the vector towards Saturn
    vec3 sunAxis = normalize(sunDir);
    vec3 saturnProj = saturnDir - sunAxis * dot(saturnDir, sunAxis);
    float saturnLen = length(saturnProj);
    vec3 eclipticU = saturnLen > 1e-4 ? (saturnProj / saturnLen) : vec3(1.0, 0.0, 0.0);
    vec3 eclipticV = cross(sunAxis, eclipticU);

    // Full 3D Solar System (Mercury to Neptune)
    const int NUM_ORBITS = 7;
    PlanetOrbit3D orbits[NUM_ORBITS];

    // 0: Mercury (Fast central transit eclipse directly across the center of the Sun!)
    orbits[0] = PlanetOrbit3D(0.055, 0.003, 0.24, 1.20, 0.0036, vec3(0.72, 0.68, 0.65), 0);
    // 1: Venus (Golden atmospheric transit across the upper hemisphere of the Sun)
    orbits[1] = PlanetOrbit3D(0.090, 0.024, 0.61, 2.80, 0.0058, vec3(0.96, 0.90, 0.75), 1);
    // 2: Earth & Moon (Double transit across the lower hemisphere of the Sun)
    orbits[2] = PlanetOrbit3D(0.145, -0.018, 1.00, 4.30, 0.0070, vec3(0.20, 0.55, 0.95), 2);
    // 3: Mars (Passes close to the upper limb / corona of the Sun)
    orbits[3] = PlanetOrbit3D(0.220, 0.060, 1.88, 0.60, 0.0048, vec3(0.92, 0.38, 0.18), 3);
    // 4: Jupiter (Gas giant with bands, wide orbit passing below the Sun)
    orbits[4] = PlanetOrbit3D(0.380, -0.085, 4.00, 5.10, 0.0135, vec3(0.92, 0.78, 0.55), 4);
    // 5: Uranus (Cyan ice giant in deep space)
    orbits[5] = PlanetOrbit3D(0.650, 0.110, 8.00, 2.20, 0.0065, vec3(0.48, 0.88, 0.90), 6);
    // 6: Neptune (Deep royal azure ice giant)
    orbits[6] = PlanetOrbit3D(0.850, -0.140, 12.00, 3.70, 0.0060, vec3(0.18, 0.38, 0.95), 7);

    // Draw Planets with 3D Perspective & Solar Eclipse / Transit Support
    float basePeriod = float(PLANETS_REVOLUTION_TIME);
    for (int k = 0; k < NUM_ORBITS; ++k) {
        float orbitPeriod = max(1.0, basePeriod * orbits[k].periodMul);
        float theta = orbits[k].initPhase + fract(frameTimeCounter / orbitPeriod) * tau;
        float r = orbits[k].r;
        float inc = orbits[k].inc;

        // 3D position relative to the Sun:
        // When sin(theta) = 1, planet is in front of the Sun (between us and the Sun!)
        vec3 deltaPos = r * (cos(theta) * eclipticU + sin(theta) * (sin(inc) * eclipticV - cos(inc) * sunAxis));

        // 3D position vector relative to the observer (Sun is at distance 1.0):
        vec3 P_k = sunAxis + deltaPos;
        float distToPlanet = length(P_k);
        vec3 curDir = P_k / distToPlanet;

        // If the planet is on the FAR side of the Sun (distToPlanet > 1.0) and inside the solar disk,
        // it is occulted by the Sun!
        if (distToPlanet > 1.0) {
            float angToSun = fast_acos(clamp(dot(curDir, sunAxis), -1.0, 1.0));
            if (angToSun < 0.040) continue; // Occulted behind the Sun
        }

        // Direction from the planet to the Sun for accurate day/night phase & eclipse silhouette
        vec3 lightDirToSun = normalize(-deltaPos);

        // Apparent perspective disk radius (closer objects appear larger)
        float apparentRadius = orbits[k].radius / max(0.2, distToPlanet);

        draw_planet_sphere(sky, rayDir, sunAxis, curDir, lightDirToSun, apparentRadius, orbits[k].baseCol, orbits[k].planetId);

        // Draw Moon for Earth (k == 2)
        if (k == 2) {
            float moonPeriod = max(0.5, basePeriod * 0.08);
            float moonTheta = fract(frameTimeCounter / moonPeriod) * tau;
            vec3 moonOffset = (0.016 / distToPlanet) * (cos(moonTheta) * eclipticU + sin(moonTheta) * eclipticV);
            vec3 moonDir = normalize(curDir + moonOffset);
            draw_planet_sphere(sky, rayDir, sunAxis, moonDir, lightDirToSun, 0.0022 / distToPlanet, vec3(0.75, 0.75, 0.78), 0);
        }
    }
}

// -----------------------------------------------------------------------------
//   The Radiant Sun: Incandescent Plasma Star (SDO Cosmic Visuals)
// -----------------------------------------------------------------------------

void draw_radiant_sun(inout vec3 sky, vec3 rayDir, vec3 sunDir) {
    float nu = dot(rayDir, sunDir);
    float r = fast_acos(clamp(nu, -1.0, 1.0));

    const float sunRadius = 0.040; // Balanced solar disk size
    vec3 sunLight = vec3(0.0);

    // Tangent plane for solar disk & prominences
    vec3 tangent = normalize(abs(sunDir.y) < 0.99 ? cross(sunDir, vec3(0.0, 1.0, 0.0)) : cross(sunDir, vec3(1.0, 0.0, 0.0)));
    vec3 bitangent = cross(sunDir, tangent);
    vec2 q = vec2(dot(rayDir - sunDir, tangent), dot(rayDir - sunDir, bitangent));
    float angle = atan(q.y, q.x);

    // 1. Solar Disk Surface & Boiling Plasma Granulation
    if (r < sunRadius) {
        // Occlude background stars 100% behind the Sun!
        sky = vec3(0.0);

        float normR = r / sunRadius;
        float nz = sqrt(max(0.0, 1.0 - normR * normR));
        vec3 sphereNormal = normalize(q.x / sunRadius * tangent + q.y / sunRadius * bitangent + nz * sunDir);

        // Spherical UV coords with slow solar rotation
        float phi = atan(dot(sphereNormal, tangent), dot(sphereNormal, sunDir));
        float theta = dot(sphereNormal, bitangent);
        vec2 p = vec2(phi / tau * 7.0 + frameTimeCounter * 0.003, theta * 3.0);

        // Swirling magnetic convection warp
        vec2 warp = vec2(
            texture(noisetex, p * 0.5 + vec2(frameTimeCounter * 0.006, frameTimeCounter * 0.004)).x,
            texture(noisetex, p * 0.5 + vec2(-frameTimeCounter * 0.005, frameTimeCounter * 0.007)).y
        ) - 0.5;
        p += warp * 0.85;

        // Multi-octave solar granulation (NASA SDO plasma convection)
        float n1 = texture(noisetex, p).x;
        float n2 = texture(noisetex, p * 2.4 + vec2(-frameTimeCounter * 0.012, frameTimeCounter * 0.010)).y;
        float n3 = texture(noisetex, p * 5.6 + vec2(frameTimeCounter * 0.016, -frameTimeCounter * 0.015)).z;
        float granulation = n1 * 0.50 + n2 * 0.32 + n3 * 0.18;

        // Boiling magnetic filaments
        float filaments = abs(granulation - 0.5) * 2.0;
        filaments = pow(1.0 - filaments, 2.5);

        // Active solar flare hotspots
        float hotspotNoise = texture(noisetex, vec2(phi / tau * 3.0 + frameTimeCounter * 0.002, theta * 2.0)).z;
        float hotspots = pow(smoothstep(0.55, 0.85, hotspotNoise), 2.5) * 2.5;

        // Incandescent solar color palette
        vec3 cEmber   = vec3(0.85, 0.22, 0.02); // Deep fiery red
        vec3 cOrange  = vec3(1.00, 0.52, 0.08); // Rich solar orange
        vec3 cGold    = vec3(1.00, 0.84, 0.25); // Blazing gold
        vec3 cWhite   = vec3(1.00, 0.98, 0.94); // Incandescent white-hot core

        vec3 surfaceColor = mix(cEmber, cOrange, smoothstep(0.20, 0.48, granulation));
        surfaceColor = mix(surfaceColor, cGold, smoothstep(0.45, 0.75, granulation));
        surfaceColor = mix(surfaceColor, cWhite, smoothstep(0.70, 0.95, granulation));

        // Magnetic filaments & hotspots
        surfaceColor += cWhite * (filaments * 0.70 + hotspots * 1.2);

        // Photospheric limb brightening & edge plasma depth
        float limb = pow(1.0 - nz, 2.0);
        surfaceColor += (cGold * 1.5 + cOrange * 1.8) * limb;

        sunLight += surfaceColor * 16.0;
    }

    // 2. Solar Prominences, Flares & Coronal Mass Ejections (Tighter to the rim)
    float h = (r - sunRadius) / sunRadius;
    if (h >= 0.0 && h < 0.45) {
        float polarU = angle / tau * 7.0 + frameTimeCounter * 0.005;
        vec2 rimCoord = vec2(polarU, h * 4.5);

        // Magnetic field twisting turbulence
        vec2 rimWarp = vec2(
            texture(noisetex, rimCoord * 0.8 + vec2(frameTimeCounter * 0.010, -frameTimeCounter * 0.015)).x,
            texture(noisetex, rimCoord * 0.8 + vec2(-frameTimeCounter * 0.012, frameTimeCounter * 0.014)).y
        ) - 0.5;
        rimCoord += rimWarp * 1.2;

        float p1 = texture(noisetex, rimCoord).y;
        float p2 = texture(noisetex, rimCoord * 2.6 + vec2(-frameTimeCounter * 0.020, frameTimeCounter * 0.028)).z;
        float promTurb = p1 * 0.62 + p2 * 0.38;

        // Flares and arching loops curling into space (rapid falloff)
        float flareArch = pow(promTurb, 2.5) * exp(-h * 11.0);
        float hotEjection = pow(smoothstep(0.60, 0.90, promTurb), 3.0) * exp(-h * 8.0);

        vec3 promColor = mix(vec3(1.0, 0.42, 0.06), vec3(1.0, 0.84, 0.25), flareArch);
        promColor = mix(promColor, vec3(1.0, 0.98, 0.92), hotEjection);

        sunLight += promColor * (flareArch * 20.0 + hotEjection * 45.0);
    }

    // 3. Golden Corona & Coronal Streamers (Tight falloff to keep surrounding space deep black)
    float coronaDist = max(0.0, r - sunRadius);
    float tightCorona = exp(-coronaDist * 65.0);
    float softCorona  = exp(-coronaDist * 28.0);

    float rayAngle = angle * 10.0;
    float streamers = 0.85 + 0.15 * sin(rayAngle + frameTimeCounter * 0.03) * cos(rayAngle * 0.7 - frameTimeCounter * 0.02);

    vec3 coronaCol = vec3(1.0, 0.72, 0.22) * tightCorona * 3.8
                   + vec3(1.0, 0.48, 0.08) * softCorona * 0.6 * streamers;

    sunLight += coronaCol;

    sky += sunLight;
}

// -----------------------------------------------------------------------------
//   Main End Cosmic Sky Pipeline
// -----------------------------------------------------------------------------

vec3 draw_end_cosmic_sky(vec3 ray_dir) {
    // 1. Pure inky black void (no green/purple fog)
    vec3 sky = vec3(0.0);

    // 2. High-precision 3D Starfield
    sky += draw_cosmic_stars(ray_dir);

    // 3. Lowered Sun direction (~20° elevation)
    vec3 end_sun = get_end_sun_dir(sun_dir);

    // 4. Direction to Saturn center
    vec3 saturnDir = get_saturn_center_dir();

    // 5. BACKGROUND: Radiant Sun (occludes stars, boiling plasma & prominences)
    // Omit from low-res 191x108 sky map (PROGRAM_DEFERRED0) so SSR does not create
    // a blocky pixelated square on terrain. Sun specular highlight is analytically
    // computed by get_specular_highlight.
#if !defined PROGRAM_DEFERRED0
    draw_radiant_sun(sky, ray_dir, end_sun);
#endif

    // 6. BACKGROUND: Solar System with 3D Perspective & Solar Eclipses / Transits
    // (Planets transit across the face of the Sun)
    draw_solar_system(sky, ray_dir, end_sun, saturnDir);

    // 7. FOREGROUND: Saturn & Rings (100% opaque foreground, everything passes behind!)
    draw_saturn_and_rings(sky, ray_dir, end_sun, saturnDir);

    return sky;
}

#endif // INCLUDE_SKY_END_COSMIC_SKY
