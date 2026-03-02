

void FsrEasuTap(inout vec3 aC, inout float aW, vec2 off, vec2 dir, vec2 len, float lob, float clp, vec3 c){
	vec2 rotOff = vec2(dot(off, dir), dot(off, vec2(-dir.y, dir.x)));
	rotOff *= len;
	float d2 = min(dot(rotOff, rotOff), clp);
	float wB = 0.4 * d2 - 1.0;
	float wA = lob * d2 - 1.0;
	wB *= wB;
	wA *= wA;
	wB = 1.5625 * wB - 0.5625;
	float w = wB * wA;
	aC += c * w;
	aW += w;
}

void FsrEasuSet(inout vec2 dir, inout float len, float w, float lA, float lB, float lC, float lD, float lE){
	float lenX = 1.0 / max(abs(lD - lC), abs(lC - lB));
	float dirX = lD - lB;
	dir.x += dirX * w;
	lenX = saturate(abs(dirX) * lenX);
	lenX *= lenX;
	len += lenX * w;

	float lenY = 1.0 / max(abs(lE - lC), abs(lC - lA));
	float dirY = lE - lA;
	dir.y += dirY * w;
	lenY = saturate(abs(dirY) * lenY);
	lenY *= lenY;
	len += lenY * w;
}

vec3 FsrEasu(vec2 fragCoord, vec2 inputScreenSize, vec2 outputScreenSize){
	//      +---+---+
	//    m | n | o | p
	//  +---+---+---+---+
	//  | i | j | k | l |
	//  +---+---+---+---+
	//  | e | f | g | h |
	//  +-- C --+---+---+
	//    a | b | c | d
	//      +---+---+
	// C represents sampleCenter
	vec2 sizeRatio = inputScreenSize / outputScreenSize;

	vec2 subPixelOffset = fragCoord * sizeRatio - 0.5;
	vec2 sampleCenter = floor(subPixelOffset);
	subPixelOffset -= sampleCenter;

	ivec2 texelCoordF = ivec2(sampleCenter);

	vec3 sampleB = texelFetch(colortex1, texelCoordF + ivec2( 0, -1), 0).rgb;
	vec3 sampleC = texelFetch(colortex1, texelCoordF + ivec2( 1, -1), 0).rgb;
	vec3 sampleE = texelFetch(colortex1, texelCoordF + ivec2(-1,  0), 0).rgb;
	vec3 sampleF = texelFetch(colortex1, texelCoordF + ivec2( 0,  0), 0).rgb;
	vec3 sampleG = texelFetch(colortex1, texelCoordF + ivec2( 1,  0), 0).rgb;
	vec3 sampleH = texelFetch(colortex1, texelCoordF + ivec2( 2,  0), 0).rgb;
	vec3 sampleI = texelFetch(colortex1, texelCoordF + ivec2(-1,  1), 0).rgb;
	vec3 sampleJ = texelFetch(colortex1, texelCoordF + ivec2( 0,  1), 0).rgb;
	vec3 sampleK = texelFetch(colortex1, texelCoordF + ivec2( 1,  1), 0).rgb;
	vec3 sampleL = texelFetch(colortex1, texelCoordF + ivec2( 2,  1), 0).rgb;
	vec3 sampleN = texelFetch(colortex1, texelCoordF + ivec2( 0,  2), 0).rgb;
	vec3 sampleO = texelFetch(colortex1, texelCoordF + ivec2( 1,  2), 0).rgb;

	float luminanceB = Luminance(sampleB);
	float luminanceC = Luminance(sampleC);
	float luminanceE = Luminance(sampleE);
	float luminanceF = Luminance(sampleF);
	float luminanceG = Luminance(sampleG);
	float luminanceH = Luminance(sampleH);
	float luminanceI = Luminance(sampleI);
	float luminanceJ = Luminance(sampleJ);
	float luminanceK = Luminance(sampleK);
	float luminanceL = Luminance(sampleL);
	float luminanceN = Luminance(sampleN);
	float luminanceO = Luminance(sampleO);

	vec2 dir = vec2(0.0);
	float len = 0.0;

	FsrEasuSet(dir, len, (1.0 - subPixelOffset.x) * (1.0 - subPixelOffset.y), luminanceB, luminanceE, luminanceF, luminanceG, luminanceJ);
	FsrEasuSet(dir, len,        subPixelOffset.x  * (1.0 - subPixelOffset.y), luminanceC, luminanceF, luminanceG, luminanceH, luminanceK);
	FsrEasuSet(dir, len, (1.0 - subPixelOffset.x) *        subPixelOffset.y , luminanceF, luminanceI, luminanceJ, luminanceK, luminanceN);
	FsrEasuSet(dir, len,        subPixelOffset.x  *        subPixelOffset.y , luminanceG, luminanceJ, luminanceK, luminanceL, luminanceO);

	vec2 dir2 = dir * dir;
	float dirR = dir2.x + dir2.y;
	bool zro = dirR < (1.0 / 32768.0);
	dirR = inversesqrt(dirR);
	dirR = zro ? 1.0 : dirR;
	dir.x = zro ? 1.0 : dir.x;
	dir *= vec2(dirR);

	len = len * 0.5;
	len *= len;

	float stretch = dot(dir, dir) / (max(abs(dir.x), abs(dir.y)));
	vec2 len2 = vec2(1.0 + (stretch - 1.0) * len, 1.0 - 0.5 * len);
	float lob = 0.5 - 0.29 * len;
	float clp = 1.0 / lob;

	vec3 min4 = min4(sampleF, sampleG, sampleJ, sampleK);
	vec3 max4 = max4(sampleF, sampleG, sampleJ, sampleK);

	vec3 aC = vec3(0.0);
	float aW = 0.0;
	FsrEasuTap(aC, aW, vec2( 0.0, -1.0) - subPixelOffset, dir, len2, lob, clp, sampleB);
	FsrEasuTap(aC, aW, vec2( 1.0, -1.0) - subPixelOffset, dir, len2, lob, clp, sampleC);
	FsrEasuTap(aC, aW, vec2(-1.0,  0.0) - subPixelOffset, dir, len2, lob, clp, sampleE);
	FsrEasuTap(aC, aW, vec2( 0.0,  0.0) - subPixelOffset, dir, len2, lob, clp, sampleF);
	FsrEasuTap(aC, aW, vec2( 1.0,  0.0) - subPixelOffset, dir, len2, lob, clp, sampleG);
	FsrEasuTap(aC, aW, vec2( 2.0,  0.0) - subPixelOffset, dir, len2, lob, clp, sampleH);
	FsrEasuTap(aC, aW, vec2(-1.0,  1.0) - subPixelOffset, dir, len2, lob, clp, sampleI);
	FsrEasuTap(aC, aW, vec2( 0.0,  1.0) - subPixelOffset, dir, len2, lob, clp, sampleJ);
	FsrEasuTap(aC, aW, vec2( 1.0,  1.0) - subPixelOffset, dir, len2, lob, clp, sampleK);
	FsrEasuTap(aC, aW, vec2( 2.0,  1.0) - subPixelOffset, dir, len2, lob, clp, sampleL);
	FsrEasuTap(aC, aW, vec2( 0.0,  2.0) - subPixelOffset, dir, len2, lob, clp, sampleN);
	FsrEasuTap(aC, aW, vec2( 1.0,  2.0) - subPixelOffset, dir, len2, lob, clp, sampleO);

	return min(max4, max(min4, aC / aW));
}