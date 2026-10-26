#if !defined WATER_GLSL
#define WATER_GLSL

// Water optical properties (per block) and procedural wave normals.

// Seen from outside: strong absorption and weak scattering give the dark
// navy look of deep water
const vec3 SURFACE_ABSORPTION = vec3(0.39, 0.14, 0.07);
const vec3 SURFACE_SCATTERING = vec3(0.010);
const vec3 SURFACE_EXTINCTION = SURFACE_ABSORPTION + SURFACE_SCATTERING;

// Seen from inside (and for light shafts / caustics): clearer, brighter
const vec3 WATER_ABSORPTION = vec3(0.20, 0.08, 0.04);
const vec3 WATER_SCATTERING = vec3(0.030);
const vec3 WATER_EXTINCTION = WATER_ABSORPTION + WATER_SCATTERING;

// Irregular waves: domain-warped noise octaves, each rotated and drifting in
// its own direction so no regular swell pattern shows up.
float waveHeight(vec2 p, float t) {
    vec2 warp = vec2(smoothNoise(p * 0.45 + vec2(t * 0.07, 0.0)),
                     smoothNoise(p * 0.45 + vec2(19.3, -t * 0.06))) - 0.5;
    p += warp * 2.2;

    const mat2 rot = mat2(0.80, -0.60, 0.60, 0.80);
    vec2 drift = vec2(0.55, 0.32) * t;
    float h = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; ++i) {
        h += smoothNoise(p + drift) * amp;
        p = rot * p * 1.85 + 7.1;
        drift = rot * drift * 1.25;
        amp *= 0.48;
    }
    return h;
}

// World-space normal of a horizontal water surface at world xz
vec3 waterNormal(vec2 worldXZ) {
    float t = frameTimeCounter;
    vec2 p = worldXZ * 0.9;
    const float e = 0.06;
    float h0 = waveHeight(p, t);
    float hx = waveHeight(p + vec2(e, 0.0), t);
    float hz = waveHeight(p + vec2(0.0, e), t);
    float s = 0.10 * WAVE_STRENGTH;
    return normalize(vec3((h0 - hx) * s / e, 1.0, (h0 - hz) * s / e));
}

#endif
