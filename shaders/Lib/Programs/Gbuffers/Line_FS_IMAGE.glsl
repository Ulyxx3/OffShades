//Line_FS


#extension GL_ARB_shader_image_load_store : require


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D depthtex0;


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 gbufferOutput0;

layout(rgba8) uniform image2D colorimg0;
layout(rgba16) uniform image2D colorimg5;


flat in vec4 color;


void main(){
	vec4 albedo = color;

	if(albedo.a > 0.1 && gl_FragCoord.z < texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x){
		if (albedo.a == 0.4)
			albedo.rgb = vec3(SELECTION_BOX_COLOR_R, SELECTION_BOX_COLOR_G, SELECTION_BOX_COLOR_B);

		imageStore(colorimg0, ivec2(gl_FragCoord.xy), vec4(albedo.rgb, 1.0));
		imageStore(colorimg5, ivec2(gl_FragCoord.xy), vec4(0.0, 0.0, 200.1 / 255.0, Pack2x8(vec2(0.0, 1.0))));
	}

	discard;

	gbufferOutput0 = vec4(0.0);
}
