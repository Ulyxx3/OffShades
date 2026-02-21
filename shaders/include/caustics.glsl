// ── Underwater Caustics ───────────────────────────────────────────────────────

// Fast pseudo-Voronoi noise for dancing light caustics on the ocean floor
float getCaustics(vec3 worldPos, float time) {
    if (worldPos.y > 62.5) return 0.0; // Above sea level

    vec2 p = worldPos.xz * 1.2;
    
    // Two layers of moving sine waves to simulate refracting water surface
    float c1 = sin(p.x * 0.9 + time * 1.2) * cos(p.y * 0.9 + time * 0.9);
    float c2 = sin(p.x * 1.4 - time * 1.5) * cos(p.y * 1.4 + time * 1.3);
    
    // Sharpen the peaks to look like focused light banding
    float caustic = clamp(pow((c1 * c2 + 0.3) * 1.2, 3.0), 0.0, 1.0);
    
    // Fade out smoothly as depth increases (light is absorbed)
    float depthFade = clamp(1.0 - (62.5 - worldPos.y) / 20.0, 0.0, 1.0);
    
    return caustic * depthFade;
}
