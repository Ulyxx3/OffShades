#define iterationT_VERSION AT // [AT BT]
#define iterationT_VERSION_TYPE AT // [AT BT]
#define iterationT_INFO AT // [AT BT]

//Renewed modified by Tahnass


#define PI           3.14159265359
#define hPI          1.57079632679
#define TAU          6.28318530718
#define rPI          0.31830988618
#define goldenRatio  1.61803398875
#define plasticRatio 1.32471795724
#define goldenAngle  2.39996322973

#define min3(a, b, c)                   min(a, min(b, c))
#define max3(a, b, c)                   max(a, max(b, c))
#define min4(a, b, c, d)                min(min(a, b), min(c, d))
#define max4(a, b, c, d)                max(max(a, b), max(c, d))
#define min5(a, b, c, d, e)             min(a, min(b, min(c, min(d, e))))
#define max5(a, b, c, d, e)             max(a, max(b, max(c, max(d, e))))
#define min9(a, b, c, d, e, f, g, h, i) min(a, min(b, min(c, min(d, min(e, min(f, min(g, min(h, i))))))))
#define max9(a, b, c, d, e, f, g, h, i) max(a, max(b, max(c, max(d, max(e, max(f, max(g, max(h, i))))))))
#define saturate(x)                     clamp(x, 0.0, 1.0)
#define curve(x)                        x * x * (3.0 - 2.0 * x)
#define Luminance(c)                    dot(c, vec3(0.2125, 0.7154, 0.0721))
#define fsign(x)                        uintBitsToFloat((floatBitsToUint(x) & 0x80000000u) | 0x3f800000u)
#define fsqrt(x)                        intBitsToFloat(0x1fbd1df5 + (floatBitsToInt(x) >> 1))


float minVec3(vec3 v){
	return min(v.x, min(v.y, v.z));
}

float maxVec3(vec3 v){
	return max(v.x, max(v.y, v.z));
}

float remapSaturate(float x, float e0, float e1){
	return saturate((x - e0) / (e1 - e0));
}

float remap(float x, float minOrigin, float maxOrigin, float minNew, float maxNew){
	return (x - minOrigin) / (maxOrigin - minOrigin) * (maxNew - minNew) + minNew;
}

vec2 remap(vec2 x, vec2 minOrigin, vec2 maxOrigin, vec2 minNew, vec2 maxNew){
	return (x - minOrigin) / (maxOrigin - minOrigin) * (maxNew - minNew) + minNew;
}

vec3 remap(vec3 x, vec3 minOrigin, vec3 maxOrigin, vec3 minNew, vec3 maxNew){
	return (x - minOrigin) / (maxOrigin - minOrigin) * (maxNew - minNew) + minNew;
}

vec4 remap(vec4 x, vec4 minOrigin, vec4 maxOrigin, vec4 minNew, vec4 maxNew){
	return (x - minOrigin) / (maxOrigin - minOrigin) * (maxNew - minNew) + minNew;
}


float atan2(vec2 v){
	return v.x == 0.0 ?
		(1.0 - step(abs(v.y), 0.0)) * sign(v.y) * hPI :
		atan(v.y / v.x) + step(v.x, 0.0) * sign(v.y) * PI;
}

float facos(float x){
	float ax = abs(x);
	float res = -0.156583 * ax + hPI; 
	res *= fsqrt(1.0 - ax);
	return x >= 0 ? res : PI - res;
}


vec3 LinearToGamma(vec3 c){
	return pow(c, vec3(1.0 / 2.2));
}

vec3 GammaToLinear(vec3 c){
	return pow(c, vec3(2.2));
}

float LinearToCurve(float c){
	return pow(c, 0.25);
}

float CurveToLinear(float c){
	c = c * c;
	return c * c;
}

vec3 LinearToCurve(vec3 c){
	return pow(c, vec3(0.25));
}

vec3 CurveToLinear(vec3 c){
	c = c * c;
	return c * c;
}


void DoNightEye(inout vec3 c){
	float luminance = Luminance(c);
	c = mix(c, luminance * vec3(0.7771, 1.0038, 1.6190), vec3(0.5));
}


float Pack2x8(vec2 x){
	uvec2 u = uvec2(x * 255.0);
	return float((u.x << 8u) | u.y) / 65535.0;
}

vec2 Unpack2x8(float x){
	uint u = uint(x * 65535.0);
	return vec2(u >> 8u, u & 255u) / 255.0;
}

float Pack2x16(vec2 x){
	uvec2 u = uvec2(x * 65535.0);
	return uintBitsToFloat((u.x << 16u) | u.y);
}

vec2 Unpack2x16(float x){
	uint u = floatBitsToUint(x);
	return vec2(u >> 16u, u & 65535u) / 65535.0;
}


vec3 DecodeNormalTex(vec3 texNormal){
	vec3 normal = vec3(0.0, 0.0, 1.0);

	if (abs(texNormal.x + texNormal.y + texNormal.z - 1.5) < 1.488){
		normal.xy = texNormal.xy * 2.0 - 1.0;
		normal.xy = max(abs(normal.xy) - 1.0 / 255.0, 0.0) * sign(normal.xy);
		normal.z = sqrt(1.0 - dot(normal.xy, normal.xy));
	}
	return normal;
}

vec2 OctWrap(vec2 v) {
	return (1.0 - abs(v.yx)) * fsign(v.xy);
}

vec2 EncodeNormal(vec3 n){
	n.xy /= (abs(n.x) + abs(n.y) + abs(n.z));
	n.xy = n.z >= 0.0 ? n.xy : OctWrap(n.xy);

	return n.xy * 0.5 + 0.5;
}

vec3 DecodeNormal(vec2 en){
	vec2 n = en * 2.0 - 1.0;

	float nz = 1.0 - abs(n.x) - abs(n.y);
	return normalize(vec3(nz >= 0 ? n : OctWrap(n), nz));
}


float D_Walter(float NdotH, float roughness){
	float roughness2 = roughness * roughness;
	float k = NdotH * NdotH * (roughness2 - 1.0) + 1.0;
	return roughness2 / (PI * k * k);
}

float F_Schlick(float VdotH, float f0, float f90){
	VdotH = 1.0 - VdotH;
	float VdotH2 = VdotH * VdotH;
	return f0 + (f90 - f0) * VdotH2 * VdotH2 * VdotH;
}

float V_Schlick(float NdotL, float NdotV, float roughness){
	float k = roughness * 0.5;
	return NdotL / ((NdotL * (1.0 - k) + k) * (NdotV * (1.0 - k) + k));
}

//Brent Burley. 2012. Physically Based Shading at Disney. Physically Based Shading in Film and Game Production, ACM SIGGRAPH 2012 Courses.
float Fd_Burley(vec3 n, vec3 v, vec3 l, float roughness){
	vec3 h = normalize(v + l);
	float LdotH = saturate(dot(l, h));
	float NdotL = saturate(dot(n, l));
	float NdotV = saturate(dot(n, v));

	float f90 = 0.5 + 2.0 * roughness * LdotH * LdotH;

	float lightScatter = F_Schlick(NdotL, 1.0, f90);
	float viewScatter = F_Schlick(NdotV, 1.0, f90);

	return NdotL * lightScatter * viewScatter * rPI;
}

float SpecularGGX(vec3 n, vec3 v, vec3 l, float roughness, float f0){
	vec3 h = normalize(v + l);
	float NdotH = saturate(dot(n, h));
	float LdotH = saturate(dot(l, h));
	float NdotL = saturate(dot(n, l));
	float NdotV = saturate(dot(n, v));

	float GGX = F_Schlick(LdotH, f0, 1.0);
	GGX *= V_Schlick(NdotL, NdotV, roughness);
	GGX *= D_Walter(NdotH, roughness);

	return GGX;
}


vec3 Blackbody(float temperature){
	// https://en.wikipedia.org/wiki/Planckian_locus
	const mat2x4 splineX = mat2x4(-0.2661293e9, -0.2343589e6, 0.8776956e3, 0.179910,
								  -3.0258469e9,  2.1070479e6, 0.2226347e3, 0.240390);

	const mat3x4 splineY = mat3x4(-1.1063814, -1.34811020, 2.18555832, -0.20219683,
								  -0.9549476, -1.37418593, 2.09137015, -0.16748867,
								   3.0817580, -5.87338670, 3.75112997, -0.37001483);

	float rt = 1.0 / temperature;
	float rt2 = rt * rt;
	vec4 coeffX = vec4(rt2 * rt, rt2, rt, 1.0);

	float x = dot(coeffX, temperature < 4000.0 ? splineX[0] : splineX[1]);
	float x2 = x * x;
	vec4 coeffY = vec4(x2 * x, x2, x, 1.0);

	float z = 1.0 / dot(coeffY, temperature < 2222.0 ? splineY[0] : temperature < 4000.0 ? splineY[1] : splineY[2]);

	vec3 xyz = vec3(x * z, 1.0, z);
	xyz.z -= xyz.x + 1.0;

	const mat3 xyzToSrgb = mat3( 3.24097, -0.96924,  0.05563,
								-1.53738,  1.87597, -0.20398,
								-0.49861,  0.04156,  1.05697);

	return max(xyzToSrgb * xyz, vec3(0.0));
}


vec3 RayPlaneIntersection(vec3 ori, vec3 dir, vec3 normal){
	float rayPlaneAngle = dot(dir, normal);

	float planeRayDist = 1e8;
	vec3 intersectionPos = dir * planeRayDist;

	if (rayPlaneAngle > 0.0001 || rayPlaneAngle < -0.0001){
		planeRayDist = dot(-ori, normal) / rayPlaneAngle;
		intersectionPos = ori + dir * planeRayDist;
	}

	return intersectionPos;
}

vec2 RaySphereIntersection(vec3 ori, vec3 dir, float radius){
	float b = dot(ori, dir);
	float c = -radius * radius + dot(ori, ori);
	float d = b * b - c;

	vec2 intersection = vec2(1e10, -1e10);

	if (d >= 0.0){
		d = sqrt(d);
		intersection = vec2(-b - d, -b + d);
	}

	return intersection;
}


float RayleighPhaseFunction(float nu) {
	return 0.059683104 * (nu * nu + 1.0);
}

float MiePhaseFunction(float g, float nu) {
	float gg = g * g;
	float k = 0.1193662 * (1.0 - gg) / (2.0 + gg);
	return k * (1.0 + nu * nu) * pow(1.0 + gg - 2.0 * g * nu, -1.5);
}


float InterleavedGradientNoise(vec2 c){
	return fract(52.9829189 * fract(0.06711056 * c.x + 0.00583715 * c.y));
}

float bayer2(vec2 a) {
	a = floor(a);

	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float bayer4  (vec2 a) { return bayer2 (0.5   * a) * 0.25     + bayer2(a); }
float bayer8  (vec2 a) { return bayer4 (0.5   * a) * 0.25     + bayer2(a); }
float bayer16 (vec2 a) { return bayer4 (0.25  * a) * 0.0625   + bayer4(a); }
float bayer32 (vec2 a) { return bayer8 (0.25  * a) * 0.0625   + bayer4(a); }
float bayer64 (vec2 a) { return bayer8 (0.125 * a) * 0.015625 + bayer8(a); }
float bayer128(vec2 a) { return bayer16(0.125 * a) * 0.015625 + bayer8(a); }

//https://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
float Sequences_R1(float n) {
	const float alpha = 1.0 / goldenRatio;
	return fract(0.5 + n * alpha);
}

vec2 Sequences_R2(float n) {
	const vec2 alpha = 1.0 / vec2(plasticRatio, plasticRatio * plasticRatio);
	return fract(0.5 + n * alpha);
}
