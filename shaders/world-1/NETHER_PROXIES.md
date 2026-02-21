/*
================================================================================
  OffShades — world-1 GBuffer Proxies (block, hand, weather, sky, basic)
  All Nether geometry passes share the same gbuffer structure as the overworld.
  They proxy via shared include modules with WORLD_NETHER macro set.
================================================================================
*/

//
// These files follow the exact same pattern:
//   1. #define WORLD_NETHER
//   2. Include the same vertex/fragment logic
//
// The actual Nether-specific behavior is handled exclusively in:
//   - include/misc/nether.glsl  (ambient/fog/sky)
//   - world-1/deferred.fsh      (shading pass)
//   - world-1/composite.fsh     (fog compositing + tonemap)
//
// For brevity, block.vsh, hand.vsh, weather.vsh, skybasic.vsh, basic.vsh
// each get a single-line WORLD_NETHER proxy:
