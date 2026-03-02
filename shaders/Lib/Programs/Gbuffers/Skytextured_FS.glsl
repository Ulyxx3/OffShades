//Skytextured_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform int isEyeInWater;

uniform sampler2D tex;


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 gbufferOutput0;


in vec3 color;
in vec2 texCoord;
flat in float isMoon;

vec4 BilinearTexture(sampler2D texSampler, vec2 coord, vec2 texSize){
	coord = coord * texSize - 0.5;

	vec2 p = floor(coord);
	vec2 f = coord - p;

	ivec2 texelX = ivec2(p);
	ivec2 texelW = texelX + 1;

	return mix(mix(texelFetch(texSampler, texelX                   , 0), texelFetch(texSampler, ivec2(texelW.x, texelX.y), 0), f.x),
			   mix(texelFetch(texSampler, ivec2(texelX.x, texelW.y), 0), texelFetch(texSampler, texelW                   , 0), f.x),
			   f.y);
}

vec4 BilinearTextureSkybox(sampler2D texSampler, vec2 coord, vec2 texSize){
	ivec2 grid = ivec2(floor(coord * vec2(3.0, 2.0)));
	int gridSize = int(floor(texSize.y * 0.5));
	grid *= gridSize;
	ivec4 border = ivec4(grid, grid + gridSize - 1);

	coord = coord * texSize - 0.5;

	vec2 p = floor(coord);
	vec2 f = coord - p;

	ivec2 texelX = clamp(ivec2(p), border.xy, border.zw);
	ivec2 texelW = clamp(texelX + 1, border.xy, border.zw);

	return mix(mix(texelFetch(texSampler, texelX                   , 0), texelFetch(texSampler, ivec2(texelW.x, texelX.y), 0), f.x),
			   mix(texelFetch(texSampler, ivec2(texelX.x, texelW.y), 0), texelFetch(texSampler, texelW                   , 0), f.x),
			   f.y);
}

void main(){
	vec4 albedo = vec4(0.0);

	if (isMoon > 0.5){
		#ifdef MOON_TEXTURE
			if (isEyeInWater != 0) discard;
		#else
			discard;
		#endif

		#ifdef BILINEAR_MOON_TEXTURE
			albedo = BilinearTexture(tex, texCoord, vec2(textureSize(tex, 0)));
		#else
			albedo = textureLod(tex, texCoord, 0.0);
		#endif	
	}else{
		#ifndef SKYBOX_TEXTURE
			discard;
		#endif

		#ifdef BILINEAR_SKYBOX_TEXTURE
			albedo = BilinearTextureSkybox(tex, texCoord, vec2(textureSize(tex, 0)));
		#else
			albedo = textureLod(tex, texCoord, 0.0);
		#endif
	}
		
	albedo.rgb *= color;

	gbufferOutput0 = albedo;
}
