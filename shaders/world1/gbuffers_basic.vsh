/* OffShades — world1/gbuffers_basic.vsh — End proxy */
#define WORLD_END
#include "/include/global.glsl"
varying vec4 v_color;
void main() { v_color = gl_Color; gl_Position = ftransform(); }
