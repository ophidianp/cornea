#if !defined COMMON_GLSL
#define COMMON_GLSL

#include "/settings.glsl"

#ifndef MC_HAND_DEPTH
#define MC_HAND_DEPTH 0.56
#endif

// Nether and End have no sun to cast shadows or light clouds
#if !defined WORLD_OVERWORLD
    #undef CLOUDS
    #undef CLOUD_SHADOWS
    #undef CIRRUS
    #undef VL
    #undef UW_VL
    #undef CAUSTICS
    #undef STARS
    #undef AURORA
#endif
#if !defined WORLD_END
    #undef END_BLACK_HOLE
#endif
#if !defined COLORED_LIGHTS
    #undef TORCH_SHADOWS
#endif
#if defined WORLD_NETHER
    #undef SHADOWS
#endif
#if !defined SHADOWS
    #undef COLORED_SHADOWS
    #undef CAUSTICS
    #undef UW_VL
    #undef VL
#endif

// ----------------------------------------------------------------- Uniforms
// Unused uniforms are stripped by the compiler, so one shared list is fine.

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

uniform vec3 cameraPosition;
uniform vec3 relativeEyePosition;
uniform vec3 previousCameraPosition;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;

uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform int worldTime;
uniform int moonPhase;
uniform float sunAngle;
uniform float rainStrength;
uniform float wetness;
uniform int isEyeInWater;
uniform float eyeAltitude;
uniform ivec2 eyeBrightnessSmooth;
uniform float blindness;
uniform float darknessFactor;
uniform float nightVision;
uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform vec4 entityColor;
uniform vec3 fogColor;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;

uniform sampler2D noisetex;

// Derived values. Computed in GLSL rather than as custom uniforms: they cost a
// handful of ALU ops and the compiler hoists them.
#define sunDir   normalize(mat3(gbufferModelViewInverse) * sunPosition)
#define moonDir  normalize(mat3(gbufferModelViewInverse) * moonPosition)
#define lightDir normalize(mat3(gbufferModelViewInverse) * shadowLightPosition)
#define eyeSkylight (float(eyeBrightnessSmooth.y) / 240.0)
// 1 when underground and away from the sky
#define caveFactor ((1.0 - eyeSkylight) * clamp((68.0 - eyeAltitude) / 16.0, 0.0, 1.0))
// moonPhase 0 is full, 4 is new
#define moonBrightness mix(1.0, 0.3, 1.0 - abs(float(moonPhase) - 4.0) / 4.0)

// Sub-pixel jitter for TAA, as an offset in NDC (R2 sequence)
vec2 taaOffset() {
#ifdef TAA
    vec2 j = fract(vec2(0.7548776662, 0.5698402910) * float(frameCounter % 128) + 0.5) * 2.0 - 1.0;
    return j / vec2(viewWidth, viewHeight);
#else
    return vec2(0.0);
#endif
}

// ----------------------------------------------------------------- Constants

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float RCP_PI = 0.31830988618;
const vec3 LUM = vec3(0.2126, 0.7152, 0.0722);

#define saturate(x) clamp(x, 0.0, 1.0)
#define viewSize vec2(viewWidth, viewHeight)
#define texelSize (1.0 / vec2(viewWidth, viewHeight))

float sqr(float x) { return x * x; }
vec3 sqr(vec3 x) { return x * x; }
float pow4(float x) { x *= x; return x * x; }
float pow5(float x) { return pow4(x) * x; }
float maxOf(vec3 v) { return max(v.x, max(v.y, v.z)); }
float luminance(vec3 c) { return dot(c, LUM); }
float linstep(float a, float b, float x) { return saturate((x - a) / (b - a)); }

vec3 srgbToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}
vec3 linearToSrgb(vec3 c) {
    c = max(c, 0.0);
    return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
}

// ----------------------------------------------------------------- Noise

// Interleaved gradient noise, animated per frame
float ign(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}
float ignAnimated(vec2 p) {
    return ign(p + 5.588238 * float(frameCounter & 63));
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}
float hash13(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

// noise.png: R is white noise, G is R shifted by (37, 17), so a single
// bilinear fetch yields two adjacent z-slices of a 3D value noise.
float valueNoise(vec2 p) {
    return textureLod(noisetex, p * (1.0 / 256.0), 0.0).r;
}
// Value noise with smoothstep interpolation (no bilinear grid artefacts)
float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return textureLod(noisetex, (i + f + 0.5) * (1.0 / 256.0), 0.0).r;
}
float valueNoise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    vec2 uv = i.xy + vec2(37.0, 17.0) * i.z + f.xy + 0.5;
    vec2 rg = textureLod(noisetex, uv * (1.0 / 256.0), 0.0).rg;
    return mix(rg.r, rg.g, f.z);
}

// ----------------------------------------------------------------- Encoding

vec2 octEncode(vec3 n) {
    n /= abs(n.x) + abs(n.y) + abs(n.z);
    vec2 e = n.z >= 0.0 ? n.xy : (1.0 - abs(n.yx)) * vec2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return e * 0.5 + 0.5;
}
vec3 octDecode(vec2 e) {
    e = e * 2.0 - 1.0;
    vec3 n = vec3(e, 1.0 - abs(e.x) - abs(e.y));
    float t = max(-n.z, 0.0);
    n.xy += vec2(n.x >= 0.0 ? -t : t, n.y >= 0.0 ? -t : t);
    return normalize(n);
}

// Two 8-bit values in one 16-bit unorm channel
float pack2x8(vec2 v) {
    uvec2 u = uvec2(round(saturate(v) * 255.0));
    return float(u.x | (u.y << 8u)) / 65535.0;
}
vec2 unpack2x8(float f) {
    uint u = uint(round(f * 65535.0));
    return vec2(u & 255u, u >> 8u) / 255.0;
}

// ----------------------------------------------------------------- Phase functions

float henyeyGreenstein(float cosTheta, float g) {
    float g2 = g * g;
    return (1.0 - g2) / (4.0 * PI * pow(1.0 + g2 - 2.0 * g * cosTheta, 1.5));
}
float rayleighPhase(float cosTheta) {
    return 3.0 / (16.0 * PI) * (1.0 + cosTheta * cosTheta);
}

#endif
