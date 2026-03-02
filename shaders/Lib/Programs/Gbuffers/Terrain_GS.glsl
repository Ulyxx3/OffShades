//Terrain_GS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;


uniform ivec2 atlasSize;


in vec3 v_color[];
in vec2 v_texCoord[];
in vec3 v_viewPos[];
#ifdef TERRAIN_VS_TBN
	in mat3 v_tbn[];
#endif
in vec2 v_blockLight[];
flat in float v_materialIDs[];


out vec3 color;
out vec2 texCoord;
out vec3 viewPos;
#ifdef TERRAIN_VS_TBN
	out mat3 tbn;
#endif
out vec2 blockLight;
flat out float materialIDs;
flat out float textureResolution;

void main(){
	#if TEXTURE_RESOLUTION == 0
		vec2 coordSize = max(max(abs(v_texCoord[0] - v_texCoord[1]) / distance(v_viewPos[0], v_viewPos[1]),
								 abs(v_texCoord[1] - v_texCoord[2]) / distance(v_viewPos[1], v_viewPos[2])),
								 abs(v_texCoord[2] - v_texCoord[0]) / distance(v_viewPos[2], v_viewPos[0]));

		textureResolution = floor(max(atlasSize.x * coordSize.x, atlasSize.y * coordSize.y) + 0.5);
		textureResolution = exp2(round(log2(textureResolution)));
	#else
		textureResolution = TEXTURE_RESOLUTION;
	#endif

	for (int i = 0; i < 3; i++){
		gl_Position = gl_in[i].gl_Position;

		color = v_color[i];
		texCoord = v_texCoord[i];
		viewPos = v_viewPos[i];
		#ifdef TERRAIN_VS_TBN
			tbn = v_tbn[i];
		#endif
		blockLight = v_blockLight[i];
		materialIDs = v_materialIDs[i];

		EmitVertex();
	}
	EndPrimitive();
}
