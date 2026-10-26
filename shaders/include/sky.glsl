#if !defined SKY_GLSL
#define SKY_GLSL

// Sampling side of the sky: LUT lookup, light colours, sun/moon/stars, plus
// the Nether/End stand-ins.

#include "/include/atmosphere.glsl"

uniform sampler2D colortex4;

vec3 skyData(int row) {
    return texelFetch(colortex4, ivec2(SKY_LUT_W, row), 0).rgb;
}

#if defined WORLD_OVERWORLD
vec3 sunColor()     { return skyData(SKY_ROW_SUN); }
vec3 moonColor()    { return skyData(SKY_ROW_MOON); }
vec3 ambientColor() { return skyData(SKY_ROW_AMBIENT); }
vec3 lightColor()   { return skyData(SKY_ROW_LIGHT); }
vec3 horizonColor() { return skyData(SKY_ROW_HORIZON); }

vec3 skyLut(vec3 dir) {
    return textureLod(colortex4, skyLutUv(dir), 0.0).rgb;
}
#elif defined WORLD_NETHER
vec3 sunColor()     { return vec3(0.0); }
vec3 moonColor()    { return vec3(0.0); }
vec3 ambientColor() { return srgbToLinear(fogColor) * 0.45 + vec3(0.018, 0.008, 0.005); }
vec3 lightColor()   { return vec3(0.0); }
vec3 horizonColor() { return srgbToLinear(fogColor) * 0.40; }
vec3 skyLut(vec3 dir) { return horizonColor(); }
#else // End
vec3 sunColor()     { return vec3(0.0); }
vec3 moonColor()    { return vec3(0.0); }
vec3 ambientColor() { return vec3(0.16, 0.12, 0.24); }
vec3 lightColor()   { return vec3(1.00, 0.62, 0.80) * 2.4; }
vec3 horizonColor() { return vec3(0.05, 0.03, 0.08); }

// ----------------------------------------------------------------- The End: deep space
// Layered procedurally: star fields, a nebula-lit galactic band with dust
// lanes, distant edge-on galaxies, and a huge black hole with an accretion
// disc whose gravity bends the light of everything behind it.

// The black hole is the End's sun: it sits exactly where the shadow light is, so
// shadows fall away from it
vec3 blackHoleDir() { return lightDir; }

vec3 endStars(vec3 dir) {
    vec3 col = vec3(0.0);
    for (int layer = 0; layer < 3; ++layer) {
        float scale = layer == 0 ? 520.0 : (layer == 1 ? 240.0 : 100.0);
        float thr = layer == 0 ? 0.88 : (layer == 1 ? 0.93 : 0.985);
        vec3 p = dir * scale;
        vec3 cell = floor(p);
        float h = hash13(cell + float(layer) * 11.0);
        if (h > thr) {
            vec3 c = cell + 0.5 + (vec3(hash13(cell + 17.0), hash13(cell + 41.0), hash13(cell + 83.0)) - 0.5) * 0.6;
            float k = (h - thr) / (1.0 - thr);
            float star = linstep(layer == 0 ? 0.30 : 0.38, 0.0, length(p - c));
            float inten = layer == 0 ? 0.35 + 1.3 * k * k : (layer == 1 ? 0.7 + 2.5 * k * k : 1.6 + 5.0 * k * k);
            float twinkle = 0.8 + 0.2 * sin(frameTimeCounter * (1.5 + 3.0 * k) + h * 80.0);
            vec3 tint = mix(vec3(1.0, 0.75, 0.55), vec3(0.65, 0.8, 1.0), hash13(cell + 7.0));
            col += tint * star * inten * twinkle;
        }
    }
    return col;
}

vec3 endNebula(vec3 dir) {
    vec3 bandNormal = normalize(vec3(0.35, 0.78, 0.52));
    float band = exp(-sqr(dot(dir, bandNormal)) * 8.0);
    float n1 = valueNoise3(dir * 5.0 + 3.0);
    float n2 = valueNoise3(dir * 11.0 + 17.0);
    float n3 = 0.6 * valueNoise3(dir * 24.0 + 5.0) + 0.4 * valueNoise3(dir * 52.0 + 9.0);
    float fine = valueNoise3(dir * 110.0 + 2.0) * valueNoise3(dir * 230.0 + 6.0);
    float dens = band * (0.35 + 0.65 * n1) * (0.5 + 0.5 * n2);
    float dust = smoothstep(0.52, 0.72, 0.65 * valueNoise3(dir * 9.0 + 40.0) + 0.35 * valueNoise3(dir * 30.0 + 11.0));
    vec3 c = mix(vec3(0.55, 0.25, 0.95), vec3(0.15, 0.75, 0.90), n2);
    c = mix(c, vec3(1.0, 0.55, 0.75), smoothstep(0.55, 0.9, n1) * 0.5);
    vec3 nebula = c * dens * (0.45 + 0.6 * n3 + 0.9 * fine) * (1.0 - 0.8 * dust) * 0.9;
    // faint all-over glow so space is never flat black
    nebula += vec3(0.010, 0.006, 0.020) + c * 0.02 * n1 * n2;
    return nebula;
}

vec3 endGalaxies(vec3 dir) {
    vec3 p = dir * 16.0;
    vec3 cell = floor(p);
    float h = hash13(cell + 77.0);
    if (h < 0.88) return vec3(0.0);
    vec3 c = cell + 0.35 + vec3(hash13(cell + 1.0), hash13(cell + 2.0), hash13(cell + 3.0)) * 0.3;
    vec3 d = p - c;
    vec3 axis = normalize(vec3(hash13(cell + 5.0) - 0.5, hash13(cell + 6.0) - 0.5, hash13(cell + 7.0) - 0.5) + 1e-3);
    float along = dot(d, axis);
    float across = length(d - axis * along);
    float body = exp(-(along * along) / 0.050 - (across * across) / 0.006);
    float core = exp(-dot(d, d) * 90.0);
    vec3 tint = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.75, 0.55), hash13(cell + 9.0));
    return tint * (body * 0.9 + core * 1.4) * (0.5 + hash13(cell + 12.0));
}

vec3 endBackground(vec3 dir) {
    return endNebula(dir) + endStars(dir) + endGalaxies(dir);
}

// Disc colour by radius: white-hot inside, orange, then deep red
vec3 diskColor(float R) {
    vec3 hot = vec3(1.0, 0.92, 0.78);
    vec3 mid = vec3(1.0, 0.52, 0.16);
    vec3 cold = vec3(0.60, 0.12, 0.04);
    return mix(mix(hot, mid, linstep(2.0, 3.6, R)), cold, linstep(3.6, 7.0, R));
}

vec3 endSkyColor(vec3 dir) {
#ifdef END_BLACK_HOLE
    vec3 bh = blackHoleDir();
    vec3 right = normalize(cross(bh, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, bh);
    float rsAngle = 0.085 * BLACK_HOLE_SIZE; // angular radius of the shadow
    float fwd = dot(dir, bh);

    if (fwd > 0.05) {
        vec2 p = vec2(dot(dir, right), dot(dir, up)) / (rsAngle * fwd);
        float r = length(p);
        if (r < 16.0) {
            // Gravitational lensing: look up the background where the light
            // really came from (bent around the hole)
            const float E = 1.25; // Einstein radius in shadow radii
            float rr = max(r, 0.9);
            vec2 shift = -p * (E * E / (rr * rr));
            vec3 srcDir = normalize(dir + (right * shift.x + up * shift.y) * (rsAngle * fwd));
            vec3 col = endBackground(srcDir);

            // Black shadow (soft edge for TAA)
            float shadow = linstep(1.0, 0.955, r);
            col *= 1.0 - shadow;

            // Photon ring + lensed far side of the disc arching over the top
            // and under the bottom of the shadow
            float ring = exp(-sqr((r - 1.07) / 0.028)) * 3.2;
            float arcs = exp(-sqr((r - 1.38) / 0.30)) * (0.30 + 0.70 * pow(abs(p.y) / max(r, 1e-3), 1.5));
            col += (vec3(1.0, 0.86, 0.62) * ring + vec3(1.0, 0.62, 0.30) * arcs * 2.4) * (1.0 - shadow);

            // Accretion disc, seen almost edge-on and slightly rolled
            const float roll = 0.18;
            const float sinI = 0.16;
            vec2 q = mat2(cos(roll), -sin(roll), sin(roll), cos(roll)) * p;
            float R = length(vec2(q.x, q.y / sinI));
            float edge = linstep(1.9, 2.3, R) * linstep(7.2, 5.0, R);
            if (edge > 0.0) {
                float phi = atan(q.y / sinI, q.x);
                float spin = frameTimeCounter * 0.35 / pow(R, 1.5);
                float streaks = 0.5 + 1.0 * valueNoise(vec2((phi - spin) * 5.0, R * 3.5));
                float doppler = 1.0 + 0.75 * q.x / R; // approaching side is brighter
                float bright = pow(2.0 / R, 2.4) * 6.0 * doppler * streaks;
                bool nearSide = q.y < 0.0;
                // The far half is hidden behind the shadow
                col += diskColor(R) * bright * edge * (nearSide ? 1.0 : 1.0 - shadow);
            }

            // Glow around the whole thing
            col += vec3(1.0, 0.55, 0.25) * exp(-r * 0.55) * 0.10 * (1.0 - shadow);
            return col;
        }
    }
#endif
    return endBackground(dir);
}

vec3 skyLut(vec3 dir) {
    return endSkyColor(dir);
}
#endif

// The physical sky is dim next to sunlit ground (surfaces here skip the 1/pi
// of Lambert). This lifts it into a pale, slightly saturated blue with a
// hazy floor, tuned against a CPU model of the atmosphere.
#if defined WORLD_OVERWORLD
vec3 skyDisplay(vec3 c) {
    c *= 2.8;
    c = mix(vec3(luminance(c)), c, 1.3) * vec3(0.92, 0.97, 1.2);
    float day = linstep(-0.12, 0.1, sunDir.y);
    return c + vec3(0.033, 0.049, 0.072) * day * (1.0 - 0.6 * rainStrength);
}
#endif

// ----------------------------------------------------------------- Aurora
#if defined WORLD_OVERWORLD && defined AURORA
// Curtains of light high above the clouds, only on clear-ish nights.
// A few stacked layers: parallax between them gives the vertical streaks.
vec3 drawAurora(vec3 dir) {
    float night = linstep(0.03, -0.20, sunDir.y) * (1.0 - rainStrength);
    if (night < 0.01 || dir.y < 0.02) return vec3(0.0);
    float dither = ignAnimated(gl_FragCoord.xy);
    vec3 col = vec3(0.0);
    for (int i = 0; i < AURORA_STEPS; ++i) {
        float fi = (float(i) + dither) / float(AURORA_STEPS);
        float h = 2200.0 + fi * 1600.0;
        float t = (h - cameraPosition.y) / dir.y;
        vec2 p = (cameraPosition.xz + dir.xz * t) * 0.00028 + vec2(frameTimeCounter * 0.0035, 0.0);
        vec2 w = vec2(valueNoise(p * 1.7 + 3.0), valueNoise(p * 1.7 + 11.0)) - 0.5;
        vec2 q = p + w * 0.6;
        float ridge = 1.0 - abs(valueNoise(q * vec2(1.0, 0.45) * 2.2) * 2.0 - 1.0);
        float curtain = pow(ridge, 7.0);
        float mask = smoothstep(0.35, 0.70, valueNoise(p * 0.45 + 20.0));
        float flick = 0.7 + 0.3 * valueNoise(q * 9.0 + frameTimeCounter * 0.4);
        vec3 c = mix(vec3(0.12, 1.0, 0.45), vec3(0.55, 0.25, 1.0), smoothstep(0.35, 1.0, fi));
        c = mix(c, vec3(1.0, 0.25, 0.35), smoothstep(0.85, 1.0, fi) * 0.6);
        float vert = (1.0 - fi) * (1.0 - fi) * 0.9 + 0.1; // bright lower edge
        col += c * curtain * mask * flick * vert;
    }
    return col * (8.0 / float(AURORA_STEPS)) * night * linstep(0.02, 0.25, dir.y) * AURORA_STRENGTH;
}
#endif

// ----------------------------------------------------------------- Celestial bodies

#if defined WORLD_OVERWORLD
vec3 drawSun(vec3 dir) {
    const float radius = 0.0105 * SUN_SIZE;
    float cosA = dot(dir, sunDir);
    float d = sqrt(max(0.0, 2.0 - 2.0 * cosA)); // chord ~ angle for small angles
    if (d > radius * 1.2) return vec3(0.0);
    float r = d / radius;
    // Limb darkening + a soft edge so TAA doesn't shimmer
    float limb = sqrt(max(0.0, 1.0 - r * r));
    float disc = linstep(1.15, 0.95, r) * (0.4 + 0.6 * limb);
    return sunColor() * disc * 70.0;
}

vec3 drawMoon(vec3 dir) {
    const float radius = 0.018 * MOON_SIZE;
    vec3 toMoon = dir - moonDir * dot(dir, moonDir);
    float d = length(toMoon);
    if (dot(dir, moonDir) < 0.0 || d > radius * 1.1) return vec3(0.0);

    // Build a sphere normal on the disc and light it according to moon phase
    vec3 right = normalize(cross(moonDir, vec3(0.0, 0.0, 1.0)));
    vec3 up = cross(right, moonDir);
    vec2 p = vec2(dot(toMoon, right), dot(toMoon, up)) / radius;
    float rr = dot(p, p);
    vec3 n = vec3(p, sqrt(max(0.0, 1.0 - rr)));
    float phaseAngle = float(moonPhase) * (TAU / 8.0);
    vec3 phaseLight = vec3(sin(phaseAngle), 0.0, cos(phaseAngle));
    float lit = smoothstep(-0.05, 0.15, dot(n, phaseLight));

    // A little low-frequency mottling for maria
    float maria = 0.75 + 0.25 * valueNoise(p * 18.0 + 40.0) + 0.1 * valueNoise(p * 40.0);
    float edge = linstep(1.0, 0.96, sqrt(rr));
    return MOON_TINT * (lit * maria * edge) * (MOON_IRRADIANCE * 220.0);
}

vec3 drawStars(vec3 dir) {
#ifdef STARS
    // Rotate with the celestial sphere
    float a = sunAngle * TAU;
    float c = cos(a), s = sin(a);
    vec3 d = vec3(c * dir.x + s * dir.y, -s * dir.x + c * dir.y, dir.z);

    vec3 p = d * 220.0;
    vec3 cell = floor(p);
    float h = hash13(cell);
    if (h < 0.9935) return vec3(0.0);
    vec3 center = cell + 0.5 + (vec3(hash13(cell + 17.0), hash13(cell + 41.0), hash13(cell + 83.0)) - 0.5) * 0.6;
    float dist = length(p - center);
    float star = linstep(0.22, 0.0, dist);
    float twinkle = 0.75 + 0.25 * sin(frameTimeCounter * (2.0 + 3.0 * h) + h * 100.0);
    vec3 tint = mix(vec3(1.0, 0.8, 0.6), vec3(0.7, 0.85, 1.0), hash13(cell + 7.0));
    float night = linstep(0.05, -0.12, sunDir.y);
    return tint * star * twinkle * night * (1.0 - rainStrength) * 0.12 * SUN_IRRADIANCE * (h - 0.9935) * 150.0;
#else
    return vec3(0.0);
#endif
}
#endif

// Full sky colour for a direction, without clouds
// Rainbow: a ring around the point opposite the sun (42 degrees, red outside),
// visible when the sun is fairly low and the ground is still wet but the rain
// has stopped. A fainter, reversed secondary sits outside it.
vec3 rainbowSpectrum(float t) {
    // t = 0 violet ... 1 red
    float hue = (1.0 - saturate(t)) * 0.78;
    vec3 k = clamp(abs(fract(vec3(hue) + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    return k * k * (3.0 - 2.0 * k);
}

float rainbowAmount(vec3 dir) {
    vec3 sd = sunDir;
    float sunUp = linstep(0.02, 0.12, sd.y) * (1.0 - linstep(0.55, 0.8, sd.y));
    float presence = smoothstep(0.12, 0.6, wetness) * (1.0 - smoothstep(0.0, 0.15, rainStrength));
    return sunUp * presence * linstep(-0.02, 0.1, dir.y);
}

vec3 drawRainbow(vec3 dir) {
    float amount = rainbowAmount(dir);
    if (amount <= 0.0) return vec3(0.0);
    float ang = degrees(acos(clamp(dot(dir, -sunDir), -1.0, 1.0)));
    float tp = (ang - 40.0) / 2.6;
    float primary = smoothstep(0.0, 0.18, tp) * smoothstep(1.0, 0.82, tp);
    float ts = 1.0 - (ang - 50.5) / 3.2;
    float secondary = smoothstep(0.0, 0.18, ts) * smoothstep(1.0, 0.82, ts) * 0.25;
    return rainbowSpectrum(tp) * primary * amount + rainbowSpectrum(ts) * secondary * amount;
}

vec3 renderSky(vec3 dir, bool withBodies) {
#if defined WORLD_OVERWORLD
    // Below the horizon, show the horizon haze (slightly dimmer looking
    // down) instead of the dark ground the atmosphere model would give
    vec3 sky = dir.y >= 0.0
        ? skyLut(dir)
        : skyLut(normalize(vec3(dir.x, 0.02, dir.z))) * mix(1.0, 0.7, linstep(0.0, -0.6, dir.y));
    sky = skyDisplay(sky);
    if (withBodies) {
        float horizonMask = linstep(-0.02, 0.02, dir.y) * (1.0 - rainStrength * 0.9);
        sky += (drawSun(dir) + drawMoon(dir)) * horizonMask;
        sky += drawStars(dir) * linstep(0.0, 0.1, dir.y);
#ifdef RAINBOW
        sky += sky * drawRainbow(dir) * (0.9 * RAINBOW_STRENGTH);
#endif
#ifdef AURORA
        sky += drawAurora(dir);
#endif
    }
    // Rain greys the sky out
    float l = luminance(sky);
    sky = mix(sky, vec3(l) * vec3(0.85, 0.9, 1.0) * 0.7, rainStrength * 0.7);
#else
    vec3 sky = skyLut(dir);
#endif
    return sky;
}

#endif
