

#include "/Lib/Settings.glsl"

uniform int heldItemId;
uniform int heldBlockLightValue;
uniform int heldItemId2;
uniform int heldBlockLightValue2;
uniform int worldTime;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float sunAngle;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform float wetness;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform float nightVision;
uniform float blindness;
uniform int hideGUI;
uniform float darknessFactor;
uniform float darknessLightFactor;

uniform vec2 taaJitter;
uniform vec2 screenSize;
uniform vec2 pixelSize;
uniform float eyeBrightnessSmoothCurved;
uniform float eyeBrightnessZeroSmooth;
uniform float eyeSnowySmooth;
uniform float eyeNoPrecipitationSmooth;
uniform float eyeRxSmooth;
uniform float eyeRySmooth;
uniform float isSneakingSmooth;

#ifdef DISTANT_HORIZONS
	uniform float dhNearPlane;
	uniform float dhFarPlane;
	uniform int dhRenderDistance;
	uniform mat4 dhProjection;
	uniform mat4 dhProjectionInverse;
	uniform mat4 dhPreviousProjection;

	uniform sampler2D dhDepthTex0;
	uniform sampler2D dhDepthTex1;
#endif


uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2D noisetex;

#ifdef COLORTEX_CLOUDNOISE
	uniform sampler3D colortex4;
	uniform sampler3D colortex6;
#else
	uniform sampler2D colortex4;
	uniform sampler2D colortex6;
#endif

#if MC_VERSION >= 11605
	#ifdef COLORTEX8_2D
		uniform sampler2D colortex8;
	#else
		uniform sampler3D colortex8;
	#endif
	uniform sampler2D depthtex2;
#else
	#ifdef COLORTEX8_2D
		uniform sampler2D depthtex2;
	#else
		uniform sampler3D depthtex2;
	#endif
#endif

// colortex9 and colortex10: used in DIMENSION_END as full-resolution replacements
// for colortex4/6 (which Photon world0 declares at reduced resolution for sky/ambient maps).
uniform sampler2D colortex9;
uniform sampler2D colortex10;

