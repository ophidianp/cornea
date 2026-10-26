#if !defined CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/include/sky.glsl"

// Three cloud layers:
//   1. cumulus   : volumetric, domed tops (this file: renderCumulus)
//   2. altocumulus: thin volumetric sheet of small puffs (renderAlto)
//   3. cirrus    : 2D streaks (renderCirrus)
// Everything is built from the 256^2 noise texture, no 3D textures, and is
// rendered at quarter resolution with temporal accumulation.

const float CLOUD_BOTTOM = float(CLOUD_ALTITUDE);
const float CLOUD_TOP    = float(CLOUD_ALTITUDE + CLOUD_THICKNESS);
const float CLOUD_SIGMA  = 0.07; // extinction per block at density 1

const float ALTO_BOTTOM  = float(CLOUD_ALTITUDE + CLOUD_THICKNESS) + 520.0;
const float ALTO_TOP     = ALTO_BOTTOM + 150.0;
const float ALTO_SIGMA   = 0.05;

vec2 cloudWind() {
    return vec2(1.0, 0.35) * frameTimeCounter * 2.2 * CLOUD_SPEED;
}

float cloudCoverageAmount() {
    return saturate(CLOUD_COVERAGE + 0.28 * rainStrength);
}

// 2D coverage: large weather blobs + medium detail
float cloudCoverage(vec2 xz) {
    vec2 p = (xz + cloudWind()) * 0.0035;
    float n = valueNoise(p * 0.35) * 0.55 + valueNoise(p * 1.1 + 31.0) * 0.30 + valueNoise(p * 3.1 - 17.0) * 0.15;
    float cov = cloudCoverageAmount();
    return linstep(1.0 - cov, 1.0 - cov + 0.32, n);
}

float cloudHeightProfile(float x) {
    // Flat-ish base, rounded top; x is height as a fraction of this cell's top
    return linstep(0.0, 0.12, x) * linstep(1.0, 0.45, x);
}

float cloudDensity(vec3 worldPos, bool detail, bool lite) {
    float h = (worldPos.y - CLOUD_BOTTOM) / (CLOUD_TOP - CLOUD_BOTTOM);
    if (h < 0.0 || h > 1.0) return 0.0;
    float cov = cloudCoverage(worldPos.xz);
    if (cov < 0.01) return 0.0;

    vec3 wp = worldPos + vec3(cloudWind().x, 0.0, cloudWind().y);
    // A big, slow 3D noise decides how tall each cell grows: this is what
    // makes separate towering domes rather than a flat sheet
    // (the light march uses a flat average height instead of the 3D noise)
    float puff = lite ? 0.5 : valueNoise3(wp * 0.0085);
    float limit = clamp(cov * (0.40 + 1.05 * puff), 0.12, 1.0);
    float shape = cov * cloudHeightProfile(h / limit);
    if (shape < 0.02) return 0.0;

    if (detail) {
        vec3 p = wp * 0.032;
        float erosion = valueNoise3(p) * 0.62 + valueNoise3(p * 2.9 + 11.0) * 0.38;
        // Erode more at the edges and base for wispy rims, less in the core
        shape = linstep(erosion * (0.60 - 0.30 * h), 1.0, shape);
    }
    return saturate(shape * 1.7);
}

// Optical depth toward the light using a few exponentially spaced samples
float cloudLightOpticalDepth(vec3 pos, vec3 dir) {
    float od = 0.0;
    float stepLen = 16.0;
    float t = 0.0;
    for (int i = 0; i < CLOUD_LIGHT_STEPS; ++i) {
        t += stepLen * 0.5;
        od += cloudDensity(pos + dir * t, false, true) * stepLen;
        t += stepLen * 0.5;
        stepLen *= 2.6;
    }
    return od * CLOUD_SIGMA;
}

// Approximate multiple scattering (sum of attenuated octaves)
float cloudScatter(float lightOD, float mu, float viewOD) {
    float s = 0.0;
    float a = 1.0, b = 1.0, c = 1.0;
    for (int i = 0; i < 3; ++i) {
        float phase = mix(henyeyGreenstein(mu, 0.75 * c), henyeyGreenstein(mu, -0.20 * c), 0.25);
        s += b * exp(-lightOD * a) * phase;
        a *= 0.30; b *= 0.55; c *= 0.5;
    }
    // Powder: darken thin edges facing the light
    float powder = 1.0 - 0.6 * exp(-viewOD * 2.0 - lightOD * 0.5);
    return s * powder;
}

// Slab intersection along a ray from a camera at world height camY
vec2 cloudSlab(float camY, vec3 dir, float bottom, float top) {
    if (abs(dir.y) < 1e-4) {
        return (camY > bottom && camY < top) ? vec2(0.0, 6000.0) : vec2(-1.0);
    }
    float tb = (bottom - camY) / dir.y;
    float tt = (top - camY) / dir.y;
    float t0 = max(min(tb, tt), 0.0);
    float t1 = max(tb, tt);
    if (t1 <= 0.0) return vec2(-1.0);
    return vec2(t0, t1);
}

// Returns scattered light (rgb) and transmittance (a)
vec4 renderCumulus(vec3 dir, float maxDist, float dither, vec3 lightCol, vec3 skyAmbient) {
    vec3 cam = cameraPosition;
    vec2 slab = cloudSlab(cam.y, dir, CLOUD_BOTTOM, CLOUD_TOP);
    if (slab.y < 0.0) return vec4(0.0, 0.0, 0.0, 1.0);

    const float maxRange = 9000.0;
    float t0 = slab.x;
    float t1 = min(slab.y, min(t0 + 2400.0, maxRange));
    t1 = min(t1, maxDist);
    if (t1 <= t0) return vec4(0.0, 0.0, 0.0, 1.0);

    float stepLen = (t1 - t0) / float(CLOUD_STEPS);
    float mu = dot(dir, lightDir);
    float T = 1.0;
    vec3 scattering = vec3(0.0);
    float viewOD = 0.0;
    float weightedDist = 0.0, weightSum = 0.0;

    float t = t0 + stepLen * dither;
    for (int i = 0; i < CLOUD_STEPS; ++i) {
        vec3 pos = cam + dir * t;
        float dens = cloudDensity(pos, true, false);
        if (dens > 0.001) {
            float sigma = dens * CLOUD_SIGMA;
            float stepT = exp(-sigma * stepLen);
            float lightOD = cloudLightOpticalDepth(pos, lightDir);
            float h = (pos.y - CLOUD_BOTTOM) / (CLOUD_TOP - CLOUD_BOTTOM);

            vec3 direct = lightCol * cloudScatter(lightOD, mu, viewOD) * 3.2;
            // Sky light fills the tops; bases stay darker so the volume reads
            vec3 ambient = skyAmbient * (0.16 + 0.42 * h) * 1.3;
            vec3 S = (direct + ambient) * sigma;
            scattering += T * (S - S * stepT) / sigma;

            weightedDist += t * T;
            weightSum += T;
            viewOD += sigma * stepLen;
            T *= stepT;
            if (T < 0.02) break;
        }
        t += stepLen;
    }

    // Fade into the sky with distance (aerial perspective)
    float dist = weightSum > 0.0 ? weightedDist / weightSum : t0;
    float fade = exp(-dist * 0.00028);
    fade *= linstep(0.0, 0.06, dir.y + 0.02 * float(cam.y > CLOUD_BOTTOM));
    return vec4(scattering * fade, mix(1.0, T, fade));
}

// ----------------------------------------------------------------- Altocumulus

float altoDensity(vec3 worldPos, bool detail) {
    float h = (worldPos.y - ALTO_BOTTOM) / (ALTO_TOP - ALTO_BOTTOM);
    if (h < 0.0 || h > 1.0) return 0.0;
    vec2 p = (worldPos.xz + cloudWind() * 1.7 + vec2(4000.0, 900.0)) * 0.0024;
    // Warp then use two octaves of small cells
    p += (vec2(valueNoise(p * 0.7 + 3.0), valueNoise(p * 0.7 + 17.0)) - 0.5) * 0.9;
    float n = valueNoise(p * 1.3) * 0.6 + valueNoise(p * 3.1 + 9.0) * 0.4;
    float cov = 0.46 + 0.1 * rainStrength - 0.05 * (1.0 - cloudCoverageAmount());
    float shape = linstep(1.0 - cov, 1.0 - cov + 0.22, n);
    shape *= linstep(0.0, 0.25, h) * linstep(1.0, 0.5, h);
    if (detail && shape > 0.0) {
        shape = linstep(valueNoise3(vec3(worldPos.x, worldPos.y * 2.0, worldPos.z) * 0.02 + vec3(cloudWind().x, 0.0, cloudWind().y) * 0.02) * 0.35, 1.0, shape);
    }
    return saturate(shape * 1.6);
}

vec4 renderAlto(vec3 dir, float maxDist, float dither, vec3 lightCol, vec3 skyAmbient) {
#ifdef ALTO_CLOUDS
    vec3 cam = cameraPosition;
    vec2 slab = cloudSlab(cam.y, dir, ALTO_BOTTOM, ALTO_TOP);
    if (slab.y < 0.0 || dir.y < 0.015) return vec4(0.0, 0.0, 0.0, 1.0);

    float t0 = slab.x;
    float t1 = min(slab.y, t0 + 5000.0);
    t1 = min(t1, maxDist);
    if (t1 <= t0) return vec4(0.0, 0.0, 0.0, 1.0);

    const int steps = 5;
    float stepLen = (t1 - t0) / float(steps);
    float mu = dot(dir, lightDir);
    float T = 1.0;
    vec3 scattering = vec3(0.0);
    float viewOD = 0.0;
    float weightedDist = 0.0, weightSum = 0.0;

    float t = t0 + stepLen * dither;
    for (int i = 0; i < steps; ++i) {
        vec3 pos = cam + dir * t;
        float dens = altoDensity(pos, true);
        if (dens > 0.001) {
            float sigma = dens * ALTO_SIGMA;
            float stepT = exp(-sigma * stepLen);
            // One density tap toward the light is enough for a thin sheet
            float lightOD = altoDensity(pos + lightDir * 45.0, false) * 45.0 * ALTO_SIGMA;
            float h = (pos.y - ALTO_BOTTOM) / (ALTO_TOP - ALTO_BOTTOM);
            vec3 direct = lightCol * cloudScatter(lightOD, mu, viewOD) * 2.4;
            vec3 ambient = skyAmbient * (0.22 + 0.4 * h) * 1.2;
            vec3 S = (direct + ambient) * sigma;
            scattering += T * (S - S * stepT) / sigma;
            weightedDist += t * T;
            weightSum += T;
            viewOD += sigma * stepLen;
            T *= stepT;
            if (T < 0.03) break;
        }
        t += stepLen;
    }
    float dist = weightSum > 0.0 ? weightedDist / weightSum : t0;
    float fade = exp(-dist * 0.00012) * linstep(0.015, 0.09, dir.y);
    return vec4(scattering * fade, mix(1.0, T, fade));
#else
    return vec4(0.0, 0.0, 0.0, 1.0);
#endif
}

// Both volumetric layers, near layer in front
vec4 renderClouds(vec3 dir, float maxDist, float dither, vec3 lightCol, vec3 skyAmbient) {
    vec4 low = renderCumulus(dir, maxDist, dither, lightCol, skyAmbient);
    vec4 high = renderAlto(dir, maxDist, fract(dither + 0.5), lightCol, skyAmbient);
    return vec4(low.rgb + low.a * high.rgb, low.a * high.a);
}

// Fraction of sunlight reaching a point through the cloud layer (cheap: one
// coverage lookup where the light ray crosses the middle of the layer)
float cloudShadow(vec3 worldPos) {
#if defined CLOUDS && defined CLOUD_SHADOWS
    float mid = (CLOUD_BOTTOM + CLOUD_TOP) * 0.5;
    if (worldPos.y > mid) return 1.0;
    vec3 p = worldPos + lightDir * ((mid - worldPos.y) / max(lightDir.y, 0.05));
    float cov = cloudCoverage(p.xz);
    return mix(1.0, 0.45, smoothstep(0.15, 0.9, cov));
#else
    return 1.0;
#endif
}

// Thin high cirrus, purely 2D: almost free
vec4 renderCirrus(vec3 dir, vec3 lightCol, vec3 skyAmbient) {
#ifdef CIRRUS
    if (dir.y < 0.01) return vec4(0.0, 0.0, 0.0, 1.0);
    const float alt = 2600.0;
    vec2 p = (cameraPosition.xz + dir.xz * ((alt - cameraPosition.y) / dir.y) + cloudWind() * 2.0) * 0.0009;
    p.x += valueNoise(p * 2.0) * 0.6;
    float n = valueNoise(p * vec2(1.0, 3.5)) * 0.6 + valueNoise(p * vec2(2.5, 8.0) + 7.0) * 0.4;
    float d = linstep(0.55 - 0.15 * rainStrength, 0.9, n) * 0.4;
    d *= linstep(0.01, 0.15, dir.y);
    float mu = dot(dir, lightDir);
    // Roughly as bright as the sky behind it so it never reads as a dark veil
    vec3 col = skyDisplay(skyLut(dir)) * 1.25 + lightCol * henyeyGreenstein(mu, 0.6) * 0.9;
    return vec4(col * d, 1.0 - d);
#else
    return vec4(0.0, 0.0, 0.0, 1.0);
#endif
}

#endif
