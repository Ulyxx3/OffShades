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
  - Transparence de la surface vers le ciel depuis sous l'eau (Fenêtre de Snell) : frontière ondulante animée en temps réel par les vagues multi-octaves sans aucun artefact de dédoublement ni ghosting sur les entités (dauphins, poissons).
  - Suppression complète des duplications de soleil (`sun_corona`) et du scintillement de brume sous-marine.
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

## 🪐 3. Réalisations de l'End (Inspiré d'IterationT 3.2.0 / 3.3)

Dossier source de référence : `inspiration_shaders/iterationT 3.2.0 (1)/`

### Réalisations pour l'End (`world1/` / `WORLD_END`)
- [x] **Perspective spatiale sur les Anneaux de Saturne (IterationT Style)** :
  - Création de `shaders/include/sky/end_cosmic_sky.glsl`.
  - Positionnement de l'observateur au ras et à l'intérieur du plan orbital des anneaux ($35\,000\,\text{km}$ du centre, entre $31\,000$ et $53\,000\,\text{km}$).
  - Les îles de l'End flottent au cœur de la ceinture d'astéroïdes et de poussières de glace : le plan des anneaux s'étend comme une autoroute cosmique étincelante à l'horizon.
  - Rendu de la planète géante gazeuse avec bandes nuageuses latitudinales animées, vortex polaire et diffusion de Lommel-Seeliger / Chandrasekhar ($H$-function `ppss`).
  - Anneaux texturés multi-octaves échantillonnés radialement avec division de Cassini, fentes d'Encke et diffusion avant/arrière de Mie sur les particules de glace.
  - Ombres croisées 3D bidirectionnelles : ombre portée tranchante des anneaux sur les nuages de Saturne, et ombre elliptique géante de Saturne projetée sur les anneaux.
- [x] **Source lumineuse solaire & Lens Flares (Remplacement du trou noir)** :
  - Disque solaire radiant avec assombrissement au limbe d'Eddington ($65\times$ HDR luminance), filaments coronaux et lueur diffuse.
  - Système de Lens Flare anamorphique cinématique dans `shaders/include/sky/lens_flare.glsl` intégré dans `c1_blend_layers.fsh` :
    - Étoilement et aigrettes de diffraction anamorphiques (`gl`).
    - Réflexions d'optiques multiples (`orb`) avec aberration chromatique (dispersion $R, G, B$).
    - Anneaux de diffraction colorés (`flare_ring`).
    - Occlusion en temps réel contre `depthtex0` (`texelFetch`) : le flare disparaît proprement derrière les piliers d'obsidienne et les îles.
  - Reflets spéculaires intenses du soleil et du ciel cosmique synchronisés dans la carte du ciel (`d0_sky_map.fsh`) et sur les surfaces (`d4_deferred_shading.fsh`).
- [x] **Le Système Solaire & Traçage des Orbites Elliptiques** :
  - 7 planètes supplémentaires modélisées en sphères 3D texturées avec phases lumineuses réalistes selon l'angle au Soleil :
    - *Mercure* : Disque gris rocheux cratérisé.
    - *Vénus* : Balise dorée étincelante à atmosphère dense.
    - *Terre* : Bille bleue océanique, continents vert/ocre, tourbillons nuageux animés, limbe atmosphérique de Rayleigh et Lune compagne.
    - *Mars* : Planète rouge martienne, maria sombres et calottes polaires blanches.
    - *Jupiter* : Colosse gazeux aux bandes zonales ambrées et Grande Tache Rouge.
    - *Uranus* : Géante de glace aigue-marine / cyan.
    - *Neptune* : Disque bleu azur profond et cirrus de méthane.
  - Traçage cartographique sci-fi des trajectoires orbitales képlériennes (ellipses polaires $r(\theta) = \frac{a(1-e^2)}{1+e\cos(\theta-\omega)}$) sous forme de filaments lumineux anti-aliasés aux teintes spectrales avec impulsions subtiles.
- [x] **Ambiance Cosmique & Suppression des Voiles Parasites** :
  - Ciel spatial noir profond pur (suppression des voiles verts, des traînées violettes et du brouillard sous les îles de l'End).
  - Champ d'étoiles 3D cellulaire sans distorsion polaire avec spectre de corps noir physique ($3600\,\text{K} - 9500\,\text{K}$) et scintillement astronomique.
  - Opacité 100% de Saturne et des anneaux denses bloquant intégralement les étoiles d'arrière-plan.
  - Palette chaude et harmonieuse : Saturne aux nuances de miel doré et caramel ocre, anneaux champagne/miel glacé.
- [x] **Soleil Radiant en Plasma Incandescent & Éclipses Planétaires** :
  - Disque solaire compact et équilibré ($R = 0.040$), convection turbulente multi-octaves animée (granulation solaire SDO), filaments magnétiques, protubérances et éruptions au limbe.
  - Couronne resserrée évitant la surexposition du ciel et préservant le vide cosmique.
  - Système orbital 3D en perspective : les planètes intérieures (Mercure, Vénus, Terre + Lune) transitent périodiquement en avant du Soleil, créant de véritables éclipses solaires (silhouettes sombres rétro-éclairées défilant sur le disque solaire).
  - Occultation naturelle des planètes passant derrière le disque solaire.
  - **Gestion stricte des plans de profondeur (Z-Ordering cosmique)** :
    - Étoiles, Soleil radiant et Système solaire positionnés en arrière-plan distant.
    - Saturne 100% opaque (occultation totale du fond stellaire et solaire).
    - Anneaux semi-transparents et chauds (poussière ocre-dorée `vec3(0.88, 0.72, 0.50)` à intensité calibrée $0.035$, transmittance `exp2(-ring * 2.5)` laissant passer les étoiles et le Soleil sans brûler en blanc).
    - Ombres profondes et réalistes lors de l'éclipse : face sombre de Saturne plongée dans le noir absolu (modèle Hapke/Chandrasekhar `planetary_ppss`), masquage du voile atmosphérique sur la face visible avec croissant rétro-éclairé au limbe.
    - Projection nette et détaillée de l'ombre des anneaux sur les nuages de Saturne (`shadowExtinction = exp(-pow(...) * smoothstep(...))`).
    - Extinction automatique du Lens Flare anamorphique lorsque le Soleil est masqué par le corps de Saturne.
  - Sliders de temps de révolution configurables dans les options du shader (`screen.end_sky`) de 10 secondes (ultra rapide) à 1 heure (majestueux) :
    - `SATURN_REVOLUTION_TIME` : période de révolution complète (360°) dans les anneaux autour de Saturne.
    - `PLANETS_REVOLUTION_TIME` : période de révolution de référence des planètes autour du Soleil.
- [x] **Éclairage des Îles de l'End & Boss Fight** :
  - Calibration solaire spatiale dans `settings.glsl` : lumière directe solaire vive (`END_LIGHT_I 1.15`, teintes blanches pures) et contraste d'ombre spatial (`END_AMBIENT_I 0.22`).
  - Spéculaire et SSR configurés pour l'End Stone (`block.10017`), les briques de l'End, les blocs de purpur, et l'obsidienne pleureuse dans `block.properties`.
  - Émission et bloom boostés pour les Cristaux de l'End (`entity.10047`), les yeux et la tête de l'Ender Dragon (`entity.properties` & `material.glsl`).
