#version 330 compatibility


//#define LINE_IMAGE_OUTPUT


#ifdef LINE_IMAGE_OUTPUT
    #include "/Lib/Programs/Gbuffers/Line_FS_IMAGE.glsl"
#else
    #include "/Lib/Programs/Gbuffers/Line_FS.glsl"
#endif