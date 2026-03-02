

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


//const float maxBloomHeight = 10000.0;


#ifndef PROGRAM_VSH

	/* DRAWBUFFERS:5 */
	layout(location = 0) out vec4 compositeOutput5;


	ivec2 texelCoord = ivec2(gl_FragCoord.xy);
	vec2 texCoord = gl_FragCoord.xy * pixelSize;


	vec3 BloomDownSample(sampler2D texSampler, vec2 sampleCoord){
		vec3 blur = CurveToLinear(textureLod(texSampler, sampleCoord, 0.0).rgb) * 0.125;

		blur += CurveToLinear(textureLod(texSampler, sampleCoord + vec2( pixelSize.x,  pixelSize.y), 0.0).rgb) * 0.5;
		blur += CurveToLinear(textureLod(texSampler, sampleCoord + vec2( pixelSize.x, -pixelSize.y), 0.0).rgb) * 0.5;
		blur += CurveToLinear(textureLod(texSampler, sampleCoord + vec2(-pixelSize.x,  pixelSize.y), 0.0).rgb) * 0.5;
		blur += CurveToLinear(textureLod(texSampler, sampleCoord + vec2(-pixelSize.x, -pixelSize.y), 0.0).rgb) * 0.5;

		blur += CurveToLinear(textureLod(texSampler, sampleCoord + 2.0 * vec2( pixelSize.x,  0.0), 0.0).rgb) * 0.25;
		blur += CurveToLinear(textureLod(texSampler, sampleCoord + 2.0 * vec2( 0.0,  pixelSize.y), 0.0).rgb) * 0.25;
		blur += CurveToLinear(textureLod(texSampler, sampleCoord + 2.0 * vec2(-pixelSize.x,  0.0), 0.0).rgb) * 0.25;
		blur += CurveToLinear(textureLod(texSampler, sampleCoord + 2.0 * vec2( 0.0, -pixelSize.y), 0.0).rgb) * 0.25;

		blur += CurveToLinear(textureLod(texSampler, sampleCoord + 2.0 * vec2( pixelSize.x,  pixelSize.y), 0.0).rgb) * 0.125;
		blur += CurveToLinear(textureLod(texSampler, sampleCoord + 2.0 * vec2( pixelSize.x, -pixelSize.y), 0.0).rgb) * 0.125;
		blur += CurveToLinear(textureLod(texSampler, sampleCoord + 2.0 * vec2(-pixelSize.x,  pixelSize.y), 0.0).rgb) * 0.125;
		blur += CurveToLinear(textureLod(texSampler, sampleCoord + 2.0 * vec2(-pixelSize.x, -pixelSize.y), 0.0).rgb) * 0.125;

		return LinearToCurve(blur * 0.25);
	}

	vec3 AxialGaussianBlur(sampler2D texSampler, vec2 coord, vec2 coordScale, float sampleOrigin, vec2 sampleSize, vec2 axis, const float alpha, const float steps){
		vec3 blur = vec3(0.0);
		float weights = 0.0;

		for (float i = -steps; i <= steps; i++){
			float sampleWeight = exp2(-i * i * alpha * 5.77);

			vec2 sampleCoord = coord + axis / coordScale * pixelSize * i * 2.0;

			vec2 tCoord = sampleCoord;
			sampleCoord = clamp(sampleCoord, vec2(sampleOrigin, 0.0), vec2(sampleOrigin + sampleSize.x, sampleSize.y));

			sampleWeight *= float(tCoord == sampleCoord) + 1e-20;

			sampleCoord *= coordScale;

			blur += CurveToLinear(textureLod(texSampler, sampleCoord, 0.0).rgb) * sampleWeight;
			weights += sampleWeight;
		}

		return blur / weights;
	}

	vec4 BicubicBlurTexture(sampler2D texSampler, vec2 coord, vec2 texSize){
		vec2 texPixelSize = 1.0 / texSize;
		coord = coord * texSize - 0.5;

		vec2 p = floor(coord);
		vec2 f = coord - p;

		vec2 ff = f * f;
		vec4 w0;
		vec4 w1;
		w0.xz = 1.0 - f; w0.xz *= w0.xz * w0.xz;
		w1.yw = ff * f;
		w1.xz = 3.0 * w1.yw + 4.0 - 6.0 * ff;
		w0.yw = 6.0 - w1.xz - w1.yw - w0.xz;

		vec4 s = w0 + w1;
		vec4 c = p.xxyy + vec2(-0.5, 1.5).xyxy + w1 / s;
		c *= texPixelSize.xxyy;

		vec2 m = s.xz / (s.xz + s.yw);
		return mix(mix(textureLod(texSampler, c.yw, 0.0), textureLod(texSampler, c.xw, 0.0), m.x),
				   mix(textureLod(texSampler, c.yz, 0.0), textureLod(texSampler, c.xz, 0.0), m.x),
				   m.y);
	}

#endif


////////////////////PROGRAM_BLOOM_0/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_BLOOM_0/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_BLOOM_0
#ifdef PROGRAM_VSH


void main(){
	vec2 texCoord = gl_Vertex.xy;
	//float scale = min(1.0, maxBloomHeight / screenSize.y) * 0.51;
	texCoord *= 0.51;
	gl_Position = vec4(texCoord * 2.0 - 1.0, 0.0, 1.0);
}


#else


void main(){
	//float rScale = max(1.0, screenSize.y / maxBloomHeight) * 2.0;
	vec2 sampleCoord = texCoord * 2.0;
	vec2 border = pixelSize * 4.0 + 1.0;

	vec3 blur = vec3(0.0);
	if (sampleCoord.x <= border.x && sampleCoord.y <= border.y)
	blur = BloomDownSample(colortex1, sampleCoord);

	compositeOutput5 = vec4(blur, 0.0);
}


#endif
#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////





////////////////////PROGRAM_BLOOM_1/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_BLOOM_1/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_BLOOM_1
#ifdef PROGRAM_VSH


void main(){
	vec2 texCoord = gl_Vertex.xy;
	//float scale = min(1.0, maxBloomHeight / screenSize.y) * 0.255;
	texCoord *= 0.255;
	gl_Position = vec4(texCoord * 2.0 - 1.0, 0.0, 1.0);
}


#else


void main(){
	vec2 sampleCoord = texCoord * 2.0;
	//vec2 border = pixelSize * 2.0 + min(1.0, maxBloomHeight / screenSize.y) * 0.5;
	vec2 border = pixelSize * 2.0 + 0.5;

	vec3 blur = vec3(0.0);
	if (sampleCoord.x <= border.x && sampleCoord.y <= border.y)
	blur = BloomDownSample(colortex5, sampleCoord);

	compositeOutput5 = vec4(blur, 0.0);
}


#endif
#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////



#define BLOOM_SIZE_LOD3 0.16
#define BLOOM_SIZE_LOD4 0.035
#define BLOOM_SIZE_LOD5 0.0085
#define BLOOM_SIZE_LOD6 0.002
#define BLOOM_SIZE_LOD7 0.0005
#define BLOOM_SIZE_LOD8 0.00015

#define BLOOM_STEP_LOD3 2.0
#define BLOOM_STEP_LOD4 5.0
#define BLOOM_STEP_LOD5 12.0
#define BLOOM_STEP_LOD6 28.0
#define BLOOM_STEP_LOD7 50.0
#define BLOOM_STEP_LOD8 90.0


////////////////////PROGRAM_BLOOM_2/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_BLOOM_2/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_BLOOM_2
#ifdef PROGRAM_VSH


void main(){
	vec2 texCoord = gl_Vertex.xy;
	//float scale = min(1.0, maxBloomHeight / screenSize.y);
	texCoord *= vec2(0.6, 0.255);
	gl_Position = vec4(texCoord * 2.0 - 1.0, 0.0, 1.0);
}


#else


void main(){
	//vec2 originSize = vec2(min(1.0, maxBloomHeight / screenSize.y) * 0.25);
	vec2 originSize = vec2(0.25);
	vec2 borderWidth = pixelSize;
	const float intervalWidth = 3.0;
	vec2 border = originSize + borderWidth;

	vec2 axis = vec2(1.0, 0.0);
	vec3 blur = vec3(0.0);

	vec2 coord = texCoord;

	// Lod 2
	if (coord.x <= border.x && coord.y <= border.y){
		blur = CurveToLinear(textureLod(colortex5, clamp(coord, vec2(0.0), originSize), 0.0).rgb);
	}
	coord.x -= originSize.x + pixelSize.x * intervalWidth;
	originSize.x *= 0.5;
	border = originSize + borderWidth;

	// Lod 3
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, coord, vec2(2.0, 1.0), 0.0, originSize, axis, BLOOM_SIZE_LOD3, BLOOM_STEP_LOD3);
	}
	coord.x -= originSize.x + pixelSize.x * intervalWidth;
	originSize.x *= 0.5;
	border = originSize + borderWidth;

	// Lod 4
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, coord, vec2(4.0, 1.0), 0.0, originSize, axis, BLOOM_SIZE_LOD4, BLOOM_STEP_LOD4);
	}
	coord.x -= originSize.x + pixelSize.x * intervalWidth;
	originSize.x *= 0.5;
	border = originSize + borderWidth;

	// Lod 5
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, coord, vec2(8.0, 1.0), 0.0, originSize, axis, BLOOM_SIZE_LOD5, BLOOM_STEP_LOD5);
	}
	coord.x -= originSize.x + pixelSize.x * intervalWidth;
	originSize.x *= 0.5;
	border = originSize + borderWidth;

	// Lod 6
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, coord, vec2(16.0, 1.0), 0.0, originSize, axis, BLOOM_SIZE_LOD6, BLOOM_STEP_LOD6);
	}
	coord.x -= originSize.x + pixelSize.x * intervalWidth;
	originSize.x *= 0.5;
	border = originSize + borderWidth;

	// Lod 7
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, coord, vec2(32.0, 1.0), 0.0, originSize, axis, BLOOM_SIZE_LOD7, BLOOM_STEP_LOD7);
	}
	coord.x -= originSize.x + pixelSize.x * intervalWidth;
	originSize.x *= 0.5;
	border = originSize + borderWidth;

	// Lod 8
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, coord, vec2(64.0, 1.0), 0.0, originSize, axis, BLOOM_SIZE_LOD8, BLOOM_STEP_LOD8);
	}

	compositeOutput5 = vec4(LinearToCurve(blur), 0.0);
}


#endif
#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////





////////////////////PROGRAM_BLOOM_3/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_BLOOM_3/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_BLOOM_3
#ifdef PROGRAM_VSH


void main(){
	vec2 texCoord = gl_Vertex.xy;
	//float scale = min(1.0, maxBloomHeight / screenSize.y);
	texCoord *= vec2(0.6, 0.255);
	gl_Position = vec4(texCoord * 2.0 - 1.0, 0.0, 1.0);
}


#else


void main(){
	//vec2 originSize = vec2(min(1.0, maxBloomHeight / screenSize.y) * 0.25);
	vec2 originSize = vec2(0.25);
	vec2 borderWidth = pixelSize;
	const float intervalWidth = 3.0;
	vec2 border = originSize + borderWidth;

	vec2 axis = vec2(0.0, 1.0);
	vec3 blur = vec3(0.0);

	vec2 coord = texCoord;
	float currInterval = 0.0;
	float sampleOrigin = 0.0;

	// Lod 2
	if (coord.x <= border.x && coord.y <= border.y){
		blur = CurveToLinear(textureLod(colortex5, clamp(coord, vec2(0.0), originSize), 0.0).rgb);
	}
	currInterval = originSize.x + pixelSize.x * intervalWidth;
	coord.x -= currInterval;
	sampleOrigin += currInterval;
	originSize *= 0.5;
	border = originSize + borderWidth;

	// Lod 3
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, texCoord, vec2(1.0, 2.0), sampleOrigin, originSize, axis, BLOOM_SIZE_LOD3, BLOOM_STEP_LOD3);
	}
	currInterval = originSize.x + pixelSize.x * intervalWidth;
	coord.x -= currInterval;
	sampleOrigin += currInterval;
	originSize *= 0.5;
	border = originSize + borderWidth;

	// Lod 4
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, texCoord, vec2(1.0, 4.0), sampleOrigin, originSize, axis, BLOOM_SIZE_LOD4, BLOOM_STEP_LOD4);
	}
	currInterval = originSize.x + pixelSize.x * intervalWidth;
	coord.x -= currInterval;
	sampleOrigin += currInterval;
	originSize *= 0.5;
	border = originSize + borderWidth;

	// Lod 5
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, texCoord, vec2(1.0, 8.0), sampleOrigin, originSize, axis, BLOOM_SIZE_LOD5, BLOOM_STEP_LOD5);
	}
	currInterval = originSize.x + pixelSize.x * intervalWidth;
	coord.x -= currInterval;
	sampleOrigin += currInterval;
	originSize *= 0.5;
	border = originSize + borderWidth;

	// Lod 6
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, texCoord, vec2(1.0, 16.0), sampleOrigin, originSize, axis, BLOOM_SIZE_LOD6, BLOOM_STEP_LOD6);
	}
	currInterval = originSize.x + pixelSize.x * intervalWidth;
	coord.x -= currInterval;
	sampleOrigin += currInterval;
	originSize *= 0.5;
	border = originSize + borderWidth;

	// Lod 7
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, texCoord, vec2(1.0, 32.0), sampleOrigin, originSize, axis, BLOOM_SIZE_LOD7, BLOOM_STEP_LOD7);
	}
	currInterval = originSize.x + pixelSize.x * intervalWidth;
	coord.x -= currInterval;
	sampleOrigin += currInterval;
	originSize *= 0.5;
	border = originSize + borderWidth;

	// Lod 8
	if (coord.x >= -borderWidth.x && coord.x <= border.x && coord.y <= border.y){
		blur = AxialGaussianBlur(colortex5, texCoord, vec2(1.0, 64.0), sampleOrigin, originSize, axis, BLOOM_SIZE_LOD8, BLOOM_STEP_LOD8);
	}

	compositeOutput5 = vec4(LinearToCurve(blur), 0.0);
}


#endif
#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////





////////////////////PROGRAM_BLOOM_4/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_BLOOM_4/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_BLOOM_4
#ifdef PROGRAM_VSH


void main(){
	vec2 texCoord = gl_Vertex.xy;
	//float scale = min(1.0, maxBloomHeight / screenSize.y) * 0.51;
	texCoord *= 0.51;
	gl_Position = vec4(texCoord * 2.0 - 1.0, 0.0, 1.0);
}


#else


void main(){
	//vec2 originSize = vec2(min(1.0, maxBloomHeight / screenSize.y) * 0.25);
	vec2 originSize = vec2(0.25);
	const float intervalWidth = 3.0;

	//float rScale = max(1.0, screenSize.y / maxBloomHeight) * 2.0;
	vec2 tCoord = texCoord * 2.0;
	vec2 border = pixelSize * 8.0 + 1.0;
	

	float rainAlpha = 0.0;
	#ifdef DIMENSION_MAIN
		rainAlpha = 1.0 - textureLod(colortex0, tCoord, 0.0).a;
		rainAlpha = saturate(rainAlpha * RAIN_VISIBILITY);
	#endif

	vec2 coord = texCoord;
	vec2 sampleOrigin = vec2(0.0);

	vec3 bloom = vec3(0.0);
	if (tCoord.x <= border.x && tCoord.y <= border.y){

		bloom += CurveToLinear(BicubicBlurTexture(colortex5, coord * 0.5, screenSize).rgb) * 1.0;

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += CurveToLinear(BicubicBlurTexture(colortex5, coord * 0.25 - sampleOrigin, screenSize).rgb) * mix(0.83333333, 1.0, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += CurveToLinear(BicubicBlurTexture(colortex5, coord * 0.125 - sampleOrigin, screenSize).rgb) * mix(0.69444444, 1.0, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += CurveToLinear(BicubicBlurTexture(colortex5, coord * 0.0625 - sampleOrigin, screenSize).rgb) * mix(0.57870370, 1.0, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += CurveToLinear(BicubicBlurTexture(colortex5, coord * 0.03125 - sampleOrigin, screenSize).rgb) * mix(0.48225309, 1.0, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += CurveToLinear(BicubicBlurTexture(colortex5, coord * 0.015625 - sampleOrigin, screenSize).rgb) * mix(0.40187757, 1.0, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += CurveToLinear(BicubicBlurTexture(colortex5, coord * 0.0078125 - sampleOrigin, screenSize).rgb) * mix(0.33489798, 1.0, rainAlpha);

	}

	bloom *= mix(0.2774, 1.2 / 7.0, rainAlpha); // 0.23118661


	compositeOutput5 = vec4(LinearToCurve(bloom), 0.0);
}


#endif
#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////
