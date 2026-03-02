

/*
	Seven-segment display for glsl fragment shader by Tahnass

	- 1 1 -   24
	6 - - 2   20
	6 - - 2   16
	- 7 7 -   12
	5 - - 3   8
	5 - - 3   4
	- 4 4 -   0

	0: 0011 1111  0x0000003f numData[0]
	1: 0000 0110  0x00000006 numData[1]
	2: 0101 1011  0x0000005b numData[2]
	3: 0100 1111  0x0000004f numData[3]
	4: 0110 0110  0x00000066 numData[4]
	5: 0110 1101  0x0000006d numData[5]
	6: 0111 1101  0x0000007d numData[6]
	7: 0000 0111  0x00000007 numData[7]
	8: 0111 1111  0x0000007f numData[8]
	9: 0110 1111  0x0000006f numData[9]
	E: 0111 1001  0x00000079 numData[10]
	-: 0100 0000  0x00000040 numData[11]
	n: 0011 0111  0x00000037 numData[12]
	f: 0111 0001  0x00000071 numData[13]
	a: 0111 0111  0x00000077 numData[14]

*/

const int numData[15] = int[15](0x0000003f,
								0x00000006,
								0x0000005b,
								0x0000004f,
								0x00000066,
								0x0000006d,
								0x0000007d,
								0x00000007,
								0x0000007f,
								0x0000006f,
								0x00000079,
								0x00000040,
								0x00000037,
								0x00000071,
								0x00000077);

bool SevenSegment(int n, inout ivec2 pCoord, int coordShift){
	ivec2 coord = pCoord;
	pCoord.x += coordShift;

	if (coord.x < 0 ||
		coord.y < 0 ||
		coord.x > 3 ||
		coord.y > 6) return false;

	bool segments = false;
	int index = coord.x + coord.y * 4;

	switch (index){
		case 25: case 26:
			segments = (numData[n] & 0x00000001) > 0;
		break;

		case 19: case 23:
			segments = (numData[n] & 0x00000002) > 0;
		break;

		case 7: case 11:
			segments = (numData[n] & 0x00000004) > 0;
		break;

		case 1: case 2:
			segments = (numData[n] & 0x00000008) > 0;
		break;

		case 4: case 8:
			segments = (numData[n] & 0x00000010) > 0;
		break;

		case 16: case 20:
			segments = (numData[n] & 0x00000020) > 0;
		break;

		case 13: case 14:
			segments = (numData[n] & 0x00000040) > 0;
		break;
	}

	return segments;
}

bool DecimalPoint(int p, inout ivec2 pCoord, int coordShift){
	pCoord.x += coordShift;
	return pCoord == ivec2(p, 0);
}


float PrintFloat(float f, vec2 pixelShift, float scale){
	bool print = false;

	ivec2 oCoord = ivec2(floor((gl_FragCoord.xy - pixelShift) / scale));

	if (oCoord.x < -44 ||
		oCoord.x >  25 ||
		oCoord.y <   0 ||
		oCoord.y >   6) return 0.0;

	ivec2 pCoord = oCoord;
	pCoord.x += 5;


	uint bitsData = floatBitsToUint(f);
	uint S = bitsData >> 31;


	if (isinf(f)){

		print = print || SevenSegment(13, pCoord, 5);
		print = print || SevenSegment(12, pCoord, 5);
		print = print || SevenSegment(1, pCoord, 5);

		if (S > 0u) print = print || SevenSegment(11, pCoord, 5);

		return float(print);

	}else if (isnan(f)){

		print = print || SevenSegment(12, pCoord, 5);
		print = print || SevenSegment(14, pCoord, 5);
		print = print || SevenSegment(12, pCoord, 5);

		return float(print);
	}


	int E = int((bitsData & 0x7f800000u) >> 23) - 127;
	int shiftM = 23 - E;
	float af = abs(f);


	if (shiftM >= 0 && shiftM <= 32 || f == 0.0){

		uint M = (bitsData & 0x007fffffu) + 0x00800000u;
		int whole = int(M >> min(shiftM, 31));
		do{
			int n = whole % 10;
			print = print || SevenSegment(n, pCoord, 5);
			whole = whole / 10;
		}while (whole > 0);


		if (S > 0u) print = print || SevenSegment(11, pCoord, 5);


		int fraction = int(round(fract(af) * 1e5));
		if (fraction > 0){
			pCoord = oCoord;
			print = print || DecimalPoint(-22, pCoord, -22);

			for (int i = 0; i < 5; i++){
				int n = fraction % 10;
				print = print || SevenSegment(n, pCoord, 5);
				fraction = fraction / 10;
			}
		}


	}else{

		int exponent = int(floor(log2(af) / log2(10.0)));
		float decimalExponent = float(5 - exponent);

		if (shiftM > 32){
			exponent = -exponent;
			pCoord.x += exponent > 9 ? -25 : -20;
		}else{
			pCoord.x += exponent > 9 ? -20 : -15;
		}

		do{
			int n = exponent % 10;
			print = print || SevenSegment(n, pCoord, 5);
			exponent = exponent / 10;
		}while (exponent > 0);


		if (shiftM > 32) print = print || SevenSegment(11, pCoord, 5);


		print = print || SevenSegment(10, pCoord, 10);

		if (decimalExponent > 38.0){
			af *= 1e38;
			decimalExponent -= 38.0;
		}
		int decimal = int(round(af * pow(10.0, decimalExponent)));
		for (int i = 0; i < 5; i++){
			int n = decimal % 10;
			print = print || SevenSegment(n, pCoord, 5);
			decimal = decimal / 10;
		}


		print = print || DecimalPoint(5, pCoord, 2);


		print = print || SevenSegment(decimal, pCoord, 5);


		if (S > 0u) print = print || SevenSegment(11, pCoord, 5);
	}


	return float(print);
}

float PrintUintBinary(uint u, vec2 pixelShift, float scale){
	bool print = false;

	ivec2 oCoord = ivec2(floor((gl_FragCoord.xy - pixelShift) / scale));
	ivec2 pCoord = oCoord;
	pCoord.y += -9;

	for (int i = 0; i < 32; i++){
		int n = int(u << i >> 31);
		print = print || SevenSegment(n, pCoord, -5);

		pCoord.x += i % 4 == 3 ? -5 : 0;
		if(i == 15) pCoord = oCoord;
	}

	return float(print);
}
