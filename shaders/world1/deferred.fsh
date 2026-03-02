#version 330

// deferred.fsh — OffShades / Iteration End pipeline
// This pass originally wrote colortex3→colortex4 and initialized colortex6,
// but in the End dimension, colortex4 and colortex6 are kept at reduced size by Photon.
// We completely bypass this pass and recreate the needed data directly in GbufferData.glsl
// to avoid Iris Index -1 crashes or buffer size mismatch errors.

void main() {
    // Intentionally empty.
}
