

const float min_ev = -6.0;
const float max_ev = 6.0;
const float slope = 2.3;
const float toe_power = 1.9;
const float shoulder_power = 2.5;
const vec3 compression = vec3(0.0);
const vec3 rotation = vec3(0.0, 0.0, -2.0);
const float saturation = 1.0;


vec3 unproject(vec2 xy){
	if(xy.y == 0.0)
		return vec3(0.0);

	float Y = 1.0;
	float X = xy.x / xy.y;
	float Z = (1.0 - xy.x - xy.y) / xy.y;

	return vec3(X, Y, Z);
}

mat3 primaries_to_matrix(vec2 xy_red, vec2 xy_green, vec2 xy_blue, vec2 xy_white)
{
	vec3 XYZ_red = unproject(xy_red);
	vec3 XYZ_green = unproject(xy_green);
	vec3 XYZ_blue = unproject(xy_blue);

	vec3 XYZ_white = unproject(xy_white);

	mat3 temp = mat3(
				XYZ_red.x,	XYZ_green.x,	XYZ_blue.x,
				1.0,        1.0,            1.0,
				XYZ_red.z,	XYZ_green.z,	XYZ_blue.z);

	mat3 inverse = inverse(temp);
	vec3 scale = XYZ_white * inverse;

	return mat3(
		scale.x * XYZ_red.x, scale.y * XYZ_green.x,	scale.z * XYZ_blue.x,
		scale.x * XYZ_red.y, scale.y * XYZ_green.y,	scale.z * XYZ_blue.y,
		scale.x * XYZ_red.z, scale.y * XYZ_green.z,	scale.z * XYZ_blue.z);
}


float RotationToSlide(vec2 primary, vec2 neighborA, vec2 neighborB, float angle){
	vec2 neighbor = mix(neighborB, neighborA, float(angle >= 0.0));

	float distance_to_neighbor = distance(primary, neighbor);
	float distance_to_center = length(primary);

	float side = sin(angle / 180.0 * PI) * distance_to_center;

	return side / distance_to_neighbor;
}

vec2 SlidePrimary(vec2 primary, vec2 neighborA, vec2 neighborB, float amount){
	return mix(primary, mix(neighborB, neighborA, float(amount >= 0.0)), saturate(abs(amount)));
}

mat3 ComputeCompressionMatrix(vec2 xyR, vec2 xyG, vec2 xyB, vec2 xyW){
	vec2 offsetR = xyR - xyW;
	vec2 offsetG = xyG - xyW;
	vec2 offsetB = xyB - xyW;

	vec3 slide = vec3(0.0);
	slide.r = RotationToSlide(offsetR, offsetB, offsetG, rotation.r);
	slide.g = RotationToSlide(offsetG, offsetR, offsetB, rotation.g);
	slide.b = RotationToSlide(offsetB, offsetG, offsetR, rotation.b);

	vec3 scale_factor = 1.0 / (1.0 - compression);

	vec2 R = (SlidePrimary(offsetR, offsetB, offsetG, slide.r) * scale_factor.r) + xyW;
	vec2 G = (SlidePrimary(offsetG, offsetR, offsetB, slide.g) * scale_factor.g) + xyW;
	vec2 B = (SlidePrimary(offsetB, offsetG, offsetR, slide.b) * scale_factor.b) + xyW;
	vec2 W = xyW;

	return primaries_to_matrix(R, G, B, W);
}


vec3 open_domain_to_normalized_log2(vec3 in_od, float minimum_ev, float maximum_ev)
{
	const float middle_grey = 0.18;
	float total_exposure = maximum_ev - minimum_ev;

	vec3 output_log = clamp(log2(in_od / middle_grey), minimum_ev, maximum_ev);

	return (output_log - minimum_ev) / total_exposure;
}


float equation_scale(float x_pivot, float y_pivot, float slope_pivot, float power){
	return pow(pow((slope_pivot * x_pivot), -power) * (pow((slope_pivot * (x_pivot / y_pivot)), power) - 1.0), -1.0 / power);
}

float equation_full_curve(float x, float x_pivot, float y_pivot, float slope_pivot, float toe_power, float shoulder_power){
	float bpivot = float(x >= x_pivot);
	float scale_x_pivot = mix(x_pivot, 1.0 - x_pivot, bpivot);
	float scale_y_pivot = mix(y_pivot, 1.0 - y_pivot, bpivot);

	float toe_scale = equation_scale(scale_x_pivot, scale_y_pivot, slope_pivot, toe_power);
	float shoulder_scale = equation_scale(scale_x_pivot, scale_y_pivot, slope_pivot, shoulder_power);

	float scale = mix(-toe_scale, shoulder_scale, bpivot);

	float term = (slope_pivot * (x - x_pivot)) / scale;
	float power = mix(toe_power, shoulder_power, float(scale >= 0));
	float hyperbolic = term / pow(1.0 + pow(term, power), 1.0 / power);

	return scale * hyperbolic + y_pivot;
}


vec3 AgXConfigurable(vec3 rgb){
	mat3 sRGB_to_XYZ = primaries_to_matrix(vec2(0.64,0.33),
													vec2(0.3,0.6),
													vec2(0.15,0.06),
													vec2(0.3127, 0.3290));

	mat3 adjusted_to_XYZ = ComputeCompressionMatrix(vec2(0.64,0.33),
														vec2(0.3,0.6),
														vec2(0.15,0.06),
														vec2(0.3127, 0.3290));

	mat3 XYZ_to_adjusted = inverse(adjusted_to_XYZ);
	mat3 XYZ_to_sRGB = inverse(sRGB_to_XYZ);

	vec3 xyz = rgb * sRGB_to_XYZ;
	vec3 ajustedRGB = xyz * XYZ_to_adjusted;


	float x_pivot = abs(min_ev) / (max_ev - min_ev);
	float y_pivot = 0.5;

	vec3 log = open_domain_to_normalized_log2(ajustedRGB, min_ev, max_ev);

	float outputR = equation_full_curve(log.r, x_pivot, y_pivot, slope, toe_power, shoulder_power);
	float outputG = equation_full_curve(log.g, x_pivot, y_pivot, slope, toe_power, shoulder_power);
	float outputB = equation_full_curve(log.b, x_pivot, y_pivot, slope, toe_power, shoulder_power);

	return vec3(outputR, outputG, outputB);
}



mat3 AgXConfigurable1(){
	mat3 sRGB_to_XYZ = primaries_to_matrix(vec2(0.64,0.33),
													vec2(0.3,0.6),
													vec2(0.15,0.06),
													vec2(0.3127, 0.3290));

	mat3 adjusted_to_XYZ = ComputeCompressionMatrix(vec2(0.64,0.33),
														vec2(0.3,0.6),
														vec2(0.15,0.06),
														vec2(0.3127, 0.3290));

	mat3 XYZ_to_adjusted = inverse(adjusted_to_XYZ);
	mat3 XYZ_to_sRGB = inverse(sRGB_to_XYZ);

	return sRGB_to_XYZ * XYZ_to_adjusted;
}
