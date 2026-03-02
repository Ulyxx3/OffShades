

vec2 BlueNoise(){
	return texelFetch(noisetex, ivec2(gl_FragCoord.xy) % 64, 0).xy;
}

vec2 BlueNoiseTemproal(){
	return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) % 64, 0).xy + vec2(goldenRatio, plasticRatio) * vec2(frameCounter % 64));
}

float BayerTemproal(){
	return fract(bayer64(gl_FragCoord.xy) + goldenRatio * float(frameCounter % 128));
}