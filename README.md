# OffShades 🌅

> A custom Minecraft shaderpack built from scratch — blending the vanilla-faithful style of **Complementary Reimagined** with the atmospheric richness of **Photon Shaders**.

## ✨ Artistic Direction

| Feature | Goal |
|---|---|
| **Terrain** | Vanilla block feel, readable textures |
| **Sky & Atmosphere** | Soft atmospheric scattering, beautiful sunrises/sunsets |
| **Water** | Clear, semi-realistic, not hyper-realist |
| **Shadows** | Sharp near, soft at distance |
| **Bloom** | Subtle and natural |
| **Clouds** | Slightly volumetric but geometric |

## 🗂️ File Structure

```
OffShades/
├── pack.mcmeta
├── pack.png
├── README.md
└── shaders/
    ├── shaders.properties       # Iris/OptiFine configuration
    ├── gbuffers_terrain.vsh     # Terrain vertex shader
    ├── gbuffers_terrain.fsh     # Terrain fragment shader
    ├── gbuffers_water.vsh       # Water vertex shader
    ├── gbuffers_water.fsh       # Water fragment shader
    ├── gbuffers_basic.vsh       # Misc geometry (lines, particles)
    ├── gbuffers_basic.fsh
    ├── composite.vsh            # Post-processing pass 1
    ├── composite.fsh
    ├── final.vsh                # Final output pass
    └── final.fsh
```

## 🔧 Compatibility

- **Loader**: [Iris Shaders](https://irisshaders.dev/) 1.7+ (recommended) / OptiFine
- **Minecraft**: 1.20+
- **OpenGL**: 4.0+

## 🚀 Installation

1. Download the latest release (or clone this repo)
2. Place the `OffShades` folder (or `.zip`) in your `.minecraft/shaderpacks/` directory
3. In-game: `Options → Video Settings → Shader Packs → OffShades`

## 🗺️ Roadmap

- [x] **Step 1** — Base structure & terrain passthrough (compile check)
- [ ] **Step 2** — Directional shadow mapping
- [ ] **Step 3** — Atmospheric scattering & sky
- [ ] **Step 4** — Bloom pass
- [ ] **Step 5** — Volumetric clouds
- [ ] **Step 6** — Water reflections & refraction

## 📄 License

MIT — Feel free to learn from it, but please credit if you redistribute.
