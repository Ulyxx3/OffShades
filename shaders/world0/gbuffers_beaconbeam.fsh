/* OffShades — world0/gbuffers_beaconbeam.fsh — beacon beam */
#include "/include/global.glsl"
varying vec4 v_color;
/* DRAWBUFFERS:0 */ layout(location = 0) out vec4 color_out;
void main() {
    // Beacon beam shows as bright colored column
    color_out = vec4(v_color.rgb * 3.0, v_color.a * 0.7);
}
