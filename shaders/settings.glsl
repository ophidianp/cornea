#if !defined SETTINGS_GLSL
#define SETTINGS_GLSL

// Cornea settings. Every feature is a compile-time switch so disabled
// features cost nothing.

// ----------------------------------------------------------------- Shadows
// 0 Low, 1 High, 2 Low pixelated, 3 High pixelated
#define SHADOW_MODE 1 // [0 1 2 3]
#define PIXEL_SHADOW_RES 16 // [4 8 12 16 24 32 48 64]
#define SHADOW_SAMPLES_LOW 4 // [2 3 4 6 8]
// Advanced (High modes only; Low always uses a 1024 map and basic filtering)
#define SHADOW_RES 2048 // [1024 1536 2048 3072 4096]
#if SHADOW_MODE == 0 || SHADOW_MODE == 2
const int shadowMapResolution = 1024;
#else
const int shadowMapResolution = SHADOW_RES;
#endif
const float shadowDistance = 112.0; // [64.0 80.0 96.0 112.0 128.0 160.0 192.0 256.0]
const float shadowDistanceRenderMul = 1.0; // [-1.0 1.0]
const float sunPathRotation = -25.0; // [-50.0 -40.0 -30.0 -25.0 -20.0 -10.0 0.0 10.0 20.0 30.0]
const bool shadowHardwareFiltering1 = true;

#define SHADOWS
#define SHADOW_PCSS
#define SHADOW_SAMPLES 8 // [4 8 12 16]
#define SHADOW_SOFTNESS 1.0 // [0.25 0.5 0.75 1.0 1.5 2.0 3.0]
#define SHADOW_DISTORTION 0.85 // [0.70 0.75 0.80 0.85 0.90]
#define COLORED_SHADOWS
//#define ENTITY_SHADOWS

// ----------------------------------------------------------------- Lighting
#define SUN_INTENSITY 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]
#define SKY_INTENSITY 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]
#define BLOCKLIGHT_INTENSITY 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0 3.0]
#define BLOCKLIGHT_TEMP 0 // [0 1 2]
#define MIN_LIGHT 1.0 // [0.0 0.3 0.6 1.0 1.5]
#define EMISSION_STRENGTH 1.4 // [0.5 1.0 1.5 2.0 3.0]
#define SSAO
#define AO_STRENGTH 0.8 // [0.5 0.75 1.0 1.25 1.5]
#define HANDHELD_LIGHT
#define SSS
#define SSS_STRENGTH 2.0 // [0.5 1.0 1.5 2.0 2.5 3.0 4.0]
#define EDGE_HIGHLIGHT
#define EDGE_STRENGTH 1.0 // [0.25 0.5 0.75 1.0 1.5 2.0 3.0]

// ----------------------------------------------------------------- Coloured lights
#define COLORED_LIGHTS
#define TORCH_SHADOWS
#define TORCH_SHADOW_STEPS 6 // [4 6 8 12]
#define VOXEL_SIZE 96 // [64 96 128]
#define COLORED_LIGHT_SATURATION 1.0 // [0.5 0.75 1.0 1.25 1.5]

// ----------------------------------------------------------------- Sky & clouds
#define CLOUDS
#define CLOUD_STEPS 12 // [8 10 12 14 18 24 32]
#define CLOUD_LIGHT_STEPS 3 // [2 3 4 6]
#define CLOUD_ALTITUDE 380 // [256 320 380 450 550 700 900]
#define CLOUD_THICKNESS 320 // [120 160 220 300 400]
#define CLOUD_COVERAGE 0.50 // [0.30 0.40 0.45 0.50 0.55 0.60 0.70 0.80]
#define CLOUD_SPEED 1.0 // [0.0 0.5 1.0 2.0 4.0]
#define CLOUD_SHADOWS
#define CIRRUS
#define ALTO_CLOUDS
#define STARS
#define AURORA
#define AURORA_STEPS 8 // [4 6 8 12]
#define AURORA_STRENGTH 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define END_BLACK_HOLE
#define BLACK_HOLE_SIZE 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define SUN_SIZE 1.0 // [0.5 1.0 1.5 2.0 3.0]
#define MOON_SIZE 1.0 // [0.5 1.0 1.5 2.0 3.0]

// ----------------------------------------------------------------- Fog & godrays
#define VL
#define VL_STEPS 8 // [4 6 8 10 12 16]
#define VL_STRENGTH 0.8 // [0.25 0.5 0.75 1.0 1.5 2.0 3.0]
#define FOG_DENSITY 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#define BORDER_FOG

// ----------------------------------------------------------------- Water
#define WATER_WAVES
#define WAVE_STRENGTH 1.0 // [0.25 0.5 0.75 1.0 1.5 2.0]
#define WATER_SSR
#define SSR_STEPS 12 // [8 12 16 24]
#define CAUSTICS
#define CAUSTICS_STRENGTH 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define UW_VL
#define REFRACTION

// ----------------------------------------------------------------- Post
#define TAA
#define BLOOM
#define BLOOM_STRENGTH 1.0 // [0.25 0.5 0.75 1.0 1.5 2.0]
#define AUTO_EXPOSURE
#define EXPOSURE_BIAS 0.0 // [-2.0 -1.5 -1.0 -0.5 0.0 0.5 1.0 1.5 2.0]
#define SHARPENING 0.4 // [0.0 0.2 0.4 0.6 0.8 1.0]
#define SATURATION 1.0 // [0.8 0.9 1.0 1.05 1.1 1.2 1.3]
#define CONTRAST 0.97 // [0.8 0.9 1.0 1.1 1.2]
#define VIGNETTE 0.15 // [0.0 0.15 0.25 0.4 0.6]

// ----------------------------------------------------------------- Materials (baked in, no resource pack needed)
#define PBR_NORMALS
#define NORMAL_STRENGTH 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define REFLECTIVE_BLOCKS
#define EMISSIVE_ORES
#define WET_SURFACES
#define PUDDLES_LINGER
#define RAIN_RIPPLES
#define RAINBOW
#define RAINBOW_STRENGTH 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define WATER_RIPPLES
#define RIPPLE_STRENGTH 1.0 // [0.5 0.75 1.0 1.5 2.0 3.0]
#define SNOW_INTERACTION
#define SNOW_RECOVERY 6 // [3 4 6 8 12 20]

// ----------------------------------------------------------------- Misc
#define WAVING_PLANTS
#define WAVING_SPEED 1.0 // [0.5 1.0 1.5 2.0]
#define PLANT_INTERACTION

// Unused in code, referenced so Iris shows them as toggles.
#ifdef ENTITY_SHADOWS
#endif
#ifdef BORDER_FOG
#endif

#endif
