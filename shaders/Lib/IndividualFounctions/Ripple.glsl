

float Get3DNoise(vec3 pos){
	vec3 p = floor(pos);
	vec3 f = pos - p;
	f = curve(f);

	vec2 uv = 17.0 * p.z + p.xy + f.xy;
	vec2 rg = textureLod(noisetex, (uv + 0.5) / 64.0, 0.0).zw;

	return mix(rg.x, rg.y, f.z);
}

float GetModulatedRainSpecular(vec3 pos){
	pos.y *= 0.2;

	float n = Get3DNoise(pos);
		  n += Get3DNoise(pos * 0.5) * 2.0;
		  n += Get3DNoise(pos * 0.25) * 4.0;

	n /= 7.0;

	return saturate(n) * 0.7 + 0.3;
}

vec2 GetRainAnimationTex(sampler2D texSampler, vec2 coord, float rp){
	vec2 n = textureLod(texSampler, coord, 0.0).rg;
	n =  n * vec2(2.0, -2.0) + vec2(-1.0, 1.0);
	n = pow(abs(n), vec2(rp)) * sign(n);
	return n;
}

vec2 GetRainNormal(vec3 pos, float strength, inout float wet){
	pos.xyz *= 0.5;
	#ifdef DISABLE_LOCAL_PRECIPITATION
		strength *= rainStrength;
	#else
		strength *= rainStrength * (1.0 - eyeSnowySmooth) * (1.0 - eyeNoPrecipitationSmooth);
	#endif

	float frame = fract(floor(frameTimeCounter * 60.0) / 60.0);
	vec2 coord = vec2(pos.x, fract(pos.z / 60.0) - frame);

	float wet2 = wet * wet;
	float rp = 2.0 - (wet2 * wet2) * 1.2;

	vec2 n1 = GetRainAnimationTex(gaux1, coord, rp);
	vec2 n2 = GetRainAnimationTex(gaux2, coord, rp);
	vec2 n3 = GetRainAnimationTex(gaux3, coord, rp);

	pos.x -= frameTimeCounter * 0.5;
	float downfall = textureLod(noisetex, pos.xz * 0.0025, 0.0).w;
	downfall = saturate(downfall - 0.25);

	vec2 n = n1;
	n += n2 * saturate(downfall * 2.0);
	n += n3 * saturate(downfall * 2.0 - 1.0);

	float lod = dot(fwidth(pos.xz), vec2(1.0));

	n /= lod * 5.0 + 1.0;
	n *= strength;

	wet = saturate(mix(downfall, wet, 1.0 - 0.4 * saturate(strength)));

	return n;
}
