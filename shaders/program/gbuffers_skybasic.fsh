
// ─────────────────────────────────────────────────────────────────────────────
// OffShades — gbuffers_skybasic.fsh  (Step 3)
//
// Analytical sky gradient with Rayleigh-inspired scattering:
//  - Zenith: deep blue at noon → dark navy at night
//  - Horizon: warm orange/red at sunrise/sunset → pale blue → dark at night
//  - All driven by the current shadow light (sun or moon) elevation
// ─────────────────────────────────────────────────────────────────────────────

in vec4 glColor;
in vec3 viewDirWorld;   // world-space view direction from VSH

uniform vec3 shadowLightPosition;           // eye-space
uniform mat4 gbufferModelViewInverse;

/* DRAWBUFFERS:0 */
out vec4 fragColor;

void main() {
    // Shadow light direction in world space
    vec3 lightDirWorld = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float sunHeight    = lightDirWorld.y;  // -1 = below, +1 = zenith

    // ── Time-of-day factors ───────────────────────────────────────────────────
    float dayFactor     = smoothstep(-0.10, 0.30, sunHeight);
    // Sunrise/sunset: peaks when sun is near horizon
    float sunriseFactor = pow(clamp(1.0 - abs(sunHeight) * 3.5, 0.0, 1.0), 2.5);

    // ── Sky color palette ─────────────────────────────────────────────────────
    vec3 dayZenith    = vec3(0.08, 0.30, 0.82);   // deep Rayleigh blue
    vec3 dayHorizon   = vec3(0.52, 0.73, 1.00);   // pale blue-white
    vec3 sunsetHorizon= vec3(1.00, 0.42, 0.08);   // deep orange-red
    vec3 nightZenith  = vec3(0.01, 0.02, 0.06);   // near-black navy
    vec3 nightHorizon = vec3(0.03, 0.04, 0.09);   // dark indigo

    // ── Compute zenith and horizon colors for this time of day ────────────────
    vec3 zenithColor  = mix(nightZenith, dayZenith, dayFactor);

    vec3 horizonBase  = mix(nightHorizon, dayHorizon, dayFactor);
    // Sunset: push horizon toward orange (only during day fraction of transition)
    vec3 horizonColor = mix(horizonBase, sunsetHorizon, sunriseFactor * dayFactor);

    // ── Sky gradient: blend by view elevation ─────────────────────────────────
    // Use a power curve so the blue zenith takes up more of the sky
    float elevation   = clamp(viewDirWorld.y, 0.0, 1.0);
    float skyBlend    = pow(elevation, 0.6);
    vec3 sky          = mix(horizonColor, zenithColor, skyBlend);

    // ── Below-horizon fade (void / underground fog color) ─────────────────────
    // When viewDirWorld.y < 0, fade quickly toward a dark horizon
    float belowFade   = clamp(-viewDirWorld.y * 4.0, 0.0, 1.0);
    sky = mix(sky, horizonColor * 0.2, belowFade);

    // Keep Iris vanilla blend by mixing with glColor (handles fog etc.)
    fragColor = vec4(mix(sky, glColor.rgb, glColor.a * 0.4), 1.0);
}
