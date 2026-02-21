#version 330 compatibility
/* OffShades — world0/gbuffers_armor_glint.fsh */
#include "/include/global.glsl"
uniform sampler2D gtexture;
varying vec2 v_uv; varying vec4 v_color;
/* DRAWBUFFERS:0 */ layout(location = 0) out vec4 color_out;
void main() {
    vec4 col = texture(gtexture, v_uv) * v_color;
    // Animate glint
    vec2 anim_uv = v_uv + vec2(frameTimeCounter * 0.3, frameTimeCounter * 0.2);
    col.rgb      = mix(col.rgb, texture(gtexture, anim_uv).rgb * vec3(0.6, 0.3, 1.0), 0.5);
    color_out    = col;
}


