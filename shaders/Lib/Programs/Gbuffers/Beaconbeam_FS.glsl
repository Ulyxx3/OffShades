//Textured_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D tex;
uniform sampler2D specular;
uniform sampler2D normals;


/* DRAWBUFFERS:035 */
layout(location = 0) out vec4 gbufferOutput0;
layout(location = 1) out vec4 gbufferOutput3;
layout(location = 2) out vec4 gbufferOutput5;


in vec4 color;
in vec2 texCoord;
in vec3 viewPos;
in vec2 blockLight;


void main(){
//albedo
	vec4 albedo = textureLod(tex, texCoord, 0.0);
	albedo *= color;

	#ifdef WHITE_DEBUG_WORLD
		albedo.rgb = vec3(1.0);
	#endif


//TBN
	vec2 duv1 = dFdx(texCoord);
	vec2 duv2 = dFdy(texCoord);

	vec3 dp1 = dFdx(viewPos);
	vec3 dp2 = dFdy(viewPos);

	if (albedo.a < 0.122) discard;

	vec3 N = normalize(cross(dp1, dp2));
	vec3 dp2perp = cross(dp2, N);
	vec3 dp1perp = cross(N, dp1);
	vec3 T = normalize(dp2perp * duv1.x + dp1perp * duv2.x);
	vec3 B = normalize(dp2perp * duv1.y + dp1perp * duv2.y);
	float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
	mat3 tbn = mat3(T * invmax, B * invmax, N);


//normal
	#ifdef MC_NORMAL_MAP
		vec3 normalTex = DecodeNormalTex(textureLod(normals, texCoord, 0.0).rgb);
	#else
		vec3 normalTex = vec3(0.0, 0.0, 1.0);
	#endif

	normalTex = vec3(0.0, 0.0, 1.0);

	vec3 viewNormal = tbn * normalize(normalTex);

	#ifdef ENTITIES_NORMAL_CLAMP
		vec3 viewDir = -normalize(viewPos);
		viewNormal = normalize(viewNormal + tbn[2] * inversesqrt(saturate(dot(viewNormal, viewDir)) + 0.001));
	#endif

	vec2 normalEnc = EncodeNormal(viewNormal);



	#ifdef MC_SPECULAR_MAP
		vec2 specularTex = textureLod(specular, texCoord, 0.0).ba;
		#if TEXTURE_PBR_FORMAT == 2
			specularTex.g = specularTex.r;
		#endif
	#else
		vec2 specularTex = vec2(0.0);
	#endif


	gbufferOutput0 = vec4(albedo.rgb, 1.0);
	gbufferOutput3 = vec4(normalEnc, blockLight);
	gbufferOutput5 = vec4(0.0, Pack2x8(specularTex), (MATID_BEACON_BEAM + 0.1) / 255.0, Pack2x8(vec2(0.0, 1.0)));
}
