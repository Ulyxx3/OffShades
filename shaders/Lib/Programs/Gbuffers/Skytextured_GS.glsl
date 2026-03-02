//Skytextured_GS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;


in vec3 v_color[];
in vec2 v_texCoord[];

out vec3 color;
out vec2 texCoord;
flat out float isMoon;

void main(){
	float coordDiff = max(max(abs(v_texCoord[0].x - v_texCoord[1].x),
							  abs(v_texCoord[1].x - v_texCoord[2].x)),
							  abs(v_texCoord[2].x - v_texCoord[0].x));

	isMoon = float(coordDiff == 0.25);

	for (int i = 0; i < 3; i++){
		gl_Position = gl_in[i].gl_Position;

		color = v_color[i];
		texCoord = v_texCoord[i];

		EmitVertex();
	}
	EndPrimitive();
}
