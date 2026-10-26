#if !defined SHADOW_DISTORT_GLSL
#define SHADOW_DISTORT_GLSL

// Fisheye shadow distortion: more texels near the player. Shared by the
// shadow pass and every lookup so they always agree.

const float SHADOW_DEPTH_SCALE = 0.2;

float shadowDistortFactor(vec2 p) {
    return length(p) * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
}

vec3 distortShadowClip(vec3 p) {
    return vec3(p.xy / shadowDistortFactor(p.xy), p.z * SHADOW_DEPTH_SCALE);
}

#endif
