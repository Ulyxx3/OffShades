#version 330 compatibility
/* OffShades — world0/gbuffers_spidereyes.fsh — glowing spider eyes */
#include "/include/global.glsl"
uniform sampler2D gtexture;
varying vec2 v_uv; varying vec4 v_color;
/* DRAWBUFFERS:0 */ layout(location = 0) out vec4 color_out;
void main() {
    vec4 col = texture(gtexture, v_uv) * v_color;
    // Spider eyes emit red light
    col.rgb *= vec3(2.0, 0.5, 0.5) * 1.5;
    color_out = col;
}
