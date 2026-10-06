# OffShades - Roadmap & TODO List

Ce document récapitule l'état actuel du shaderpack **OffShades** et liste les prochaines étapes, en particulier l'intégration du **Nether inspiré de Solas Shader V3.7b**.

---

## 📌 1. Réalisations actuelles (Overworld)

### Socle & Architecture
- [x] **Base Photon v1.3b** : Pipeline deferred complet, passes de composition, PBR, buffers colortex/depthtex.
- [x] **Compatibilité Iris / OptiFine** : Résolution des bugs de directive Iris (textures multi-pass déclarées en `texture.<stage>.<sampler>`).
- [x] **Atlas d'animation** : Intégration de `cloud-water.png` de Complementary dans `shaders/image/` et liaison aux samplers `gaux4`.

### Ciel & Nuages
- [x] **Nuages volumétriques Complementary Reimagined** :
  - Intégrés dans `shaders/include/sky/clouds_reimagined.glsl` et `shaders/program/d1_clouds.fsh`.
  - Éclairage HDR calibré, lissage d'horizon (`distance_threshold`) supprimant la surexposition blanche.
  - Synchronisation de la carte du ciel (`d0_sky_map.fsh` / `colortex4`) : les reflets dans l'eau et sur les surfaces spéculaires affichent désormais les vrais nuages cubiques de Complementary Reimagined au lieu des anciens nuages de bruit procéduraux de Photon.
  - Synchronisation des ombres portées des nuages (`cloud_shadows.glsl`) : évaluation directe en espace monde par pixel d'écran (style Complementary Reimagined) depuis `gaux4` (`cloud-water.png`). Suppression complète des crénelages/dents de scie et du tremblement/décalage lors des déplacements du joueur. Contours voxels nets et stables ancrés dans le monde.

### Eau & Atmosphère sous-marine
- [x] **Surface de l'eau Complementary Reimagined** :
  - Ondulations multi-octaves avec parallaxe, écume de contact et bords de blocs.
  - Extraction sélective des détails de la texture animée vanille (`get_vanilla_water_detail()`).
  - Réflexions SSR nettes (`ENVIRONMENT_REFLECTIONS`) et réfraction de fond.
  - Correction des reflets lointains sur l'eau : suppression de la soustraction de brume basse résolution (qui provoquait des artefacts magenta/cyan et un assombrissement excessif) et restitution fidèle 1:1 de la luminance et des couleurs de l'environnement reflété.
- [x] **Intérieur de l'eau & Caustiques** :
  - Remplacement du voile turquoise laiteux par la brume quadratique sombre/saphir de Complementary.
  - Premier plan cristallin ($0-10\,\text{m}$) et profondeur océanique progressive.
  - Puits de lumière volumétriques (godrays) sous l'eau dans `water_fog_vl.glsl`.
  - Caustiques animées projetées sur le sable et les fonds marins (`shadow.fsh`).
  - Transparence de la surface vers le ciel depuis sous l'eau (Fenêtre de Snell) et rond lumineux du soleil déformés et ondulants selon les vagues de surface multi-octaves.
  - Réfraction aquatique animée du ciel, des nuages et de la lumière volumétrique sous-marine.
  - Occlusion parfaite du soleil derrière les blocs solides sous l'eau.
- [x] **Météo / Pluie** :
  - Atténuation de la luminosité et disparition des godrays sous l'eau pendant la pluie.
  - Désaturation réaliste du soleil et du ciel hors de l'eau par temps de pluie (grisaille couverte au lieu du bleu).

---

## 📌 2. Réalisations du Nether (Inspiré de Solas Shader V3.7b)

Dossier source de référence : `inspiration_shaders/Solas Shader V3.7b/`

### Réalisations pour le Nether
- [x] **Couleurs et Atmosphère par Biome (Solas Style)** :
  - Extraction chromatique dynamique depuis `fogColor` via racine 8e : `pow(normalize(fogColor), vec3(0.125))`.
  - Restitution fidèle et éclatante des 5 biomes majeurs sans assombrissement terne :
    - *Nether Wastes* : Rouge-orangé chaud volcanique.
    - *Crimson Forest* : Rouge carmin / sang profond.
    - *Warped Forest* : Cyan et sarcelle spectral éclatant.
    - *Soul Sand Valley* : Bleu pâle glacé et brume fantomatique.
    - *Basalt Deltas* : Gris sombre cendreux et dense.
- [x] **Brouillard Volumétrique 3D du Nether (Solas VL)** :
  - Création de `shaders/include/fog/nether_fog_vl.glsl` et intégration dans la passe `c0_vl.fsh` (`#elif defined WORLD_NETHER`).
  - Raymarching avec simulation de volutes de fumée 3D animées (`noisetex`), vent convectif et inscattering coloré réactif au biome.
  - Diffusion de la lueur atmosphérique et couplage au `bloomy_fog` dans `c1_blend_layers.fsh`.
- [x] **Rendu de la Lave & Émissifs (Solas Style)** :
  - Rendu procédural de la lave dans `gbuffers_all_solid.fsh` : flux à double courant croisé tourbillonnaire (interférence non-rectiligne).
  - Modulation dynamique selon l'échelle (grands lacs calmes et dorés avec motifs atténués vs petites coulées et cascades très contrastées et rapides).
  - Détection screen-space des rivages rocheux (`d4_deferred_shading.fsh`) : 
    - Lisière de 4 pixels Minecraft ($0.25\,\text{m}$) avec pixel doré incandescent contre la roche et transition en croûte sombre vers le lac.
    - Support complet 3D : appliqué sur la surface horizontale (lacs) ainsi que sur toutes les faces verticales latérales (cascades, coulées, parois rocheuses).
    - Coins diagonaux fermés et continus avec distance euclidienne arrondie sur chaque face.
    - Élimination des artefacts d'occlusion au premier plan par validation 3D de profondeur (aucun faux liseré sur les blocs en avant-plan).
    - Aléatoire organique subtil animé pour casser la rigidité polygonale.
  - Émission de la lave calibrée (`material.glsl`) pour faire luire les courants chauds avec un bloom intense sans brûlure blanche.
  - Boost de lueur et bloom calibrés pour les blocs émissifs emblématiques :
    - *Magma Blocks, Shroomlights, Feu* (veines vives).
    - *Lanternes, torches et feux des âmes* (lueur cyan spectral vibrante).
    - *Champignons biscornus et carmin* (bioluminescence subtile).
- [x] **Bloom calibré du Nether** :
  - Augmentation ciblée de l'intensité du bloom (`0.20 * BLOOM_INTENSITY` sous `WORLD_NETHER`) dans `c14_color_grading.fsh` pour créer l'ambiance vaporeuse et lumineuse caractéristique de Solas.
- [x] **Intégration propre & Aucune Régression** :
  - Parfaite isolation sous `#ifdef WORLD_NETHER` et conservation intégrale des systèmes Overworld (eau Reimagined, nuages volumétriques, caustiques).

---

## 🔮 3. Étapes Futures (End Dimension)
- [ ] **End (IterationT 3.2.0)** :
  - Atmosphère cosmique et mystique d'IterationT dans `world1/` (`WORLD_END`).
  - Nébuleuses, ciel de l'End personnalisé et éclairage de l'Ender Dragon / îles.
