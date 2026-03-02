

const vec3 roataionAngle = vec3(0.28, -1.1, 1.0);

const mat3 rotX = mat3(1.0, 0.0, 0.0,
                       0.0, cos(roataionAngle.x), sin(roataionAngle.x),
                       0.0, -sin(roataionAngle.x), cos(roataionAngle.x));

const mat3 rotY = mat3(cos(roataionAngle.y), 0.0, -sin(roataionAngle.y),
                       0.0, 1.0, 0.0,
                       sin(roataionAngle.y), 0.0, cos(roataionAngle.y));

const mat3 rotZ = mat3(cos(roataionAngle.z), sin(roataionAngle.z), 0.0,
                       -sin(roataionAngle.z), cos(roataionAngle.z), 0.0,
                       0.0, 0.0, 1.0);

const mat3 rot = rotZ * rotX * rotY;

vec3 shadowInterval = fract(rot * cameraPosition * 0.25) * 4.0;

mat4 shadowModelViewEnd = mat4(vec4(rot[0], 0.0),
                               vec4(rot[1], 0.0),
                               vec4(rot[2], 0.0),
                               vec4(shadowInterval.xy, shadowInterval.z - 100.0, 1.0));

const mat3 rotInverse = transpose(rot);

mat4 shadowModelViewInverseEnd = mat4(vec4(rotInverse[0], 0.0),
                                      vec4(rotInverse[1], 0.0),
                                      vec4(rotInverse[2], 0.0),
                                      vec4(-shadowInterval.xy, 100 - shadowInterval.z, 1.0));
