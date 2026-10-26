#if !defined ATMOSPHERE_GLSL
#define ATMOSPHERE_GLSL

// Single-scattering Rayleigh/Mie/ozone atmosphere with a cheap isotropic
// multiple-scattering term. Evaluated only into a 192x108 sky-view LUT
// (colortex4) once per frame; everything else samples the LUT.
// Units: kilometres.

const float ATMO_GROUND = 6360.0;
const float ATMO_TOP    = 6460.0;
const vec3  RAYLEIGH_SCATTER = vec3(5.802, 13.558, 33.100) * 1e-3;
const float MIE_SCATTER      = 3.996e-3;
const float MIE_EXTINCT      = 4.440e-3;
const vec3  OZONE_ABSORB     = vec3(0.650, 1.881, 0.085) * 1e-3;
const float MIE_G            = 0.78;

// Overall brightness scale of the sun. Auto exposure normalises the absolute
// level; what matters is the ratio to block light.
const float SUN_IRRADIANCE  = 10.0 * SUN_INTENSITY;
const float MOON_IRRADIANCE = SUN_IRRADIANCE * 0.0075;
const vec3  MOON_TINT       = vec3(0.70, 0.84, 1.00);

#define SKY_LUT_W 192
#define SKY_LUT_H 108
#define SKY_LUT_TEX_W 193.0

// Rows of the data column (x = 192) of colortex4
#define SKY_ROW_SUN     0
#define SKY_ROW_MOON    1
#define SKY_ROW_AMBIENT 2
#define SKY_ROW_LIGHT   3
#define SKY_ROW_HORIZON 4

vec2 raySphere(vec3 ro, vec3 rd, float r) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - r * r;
    float d = b * b - c;
    if (d < 0.0) return vec2(-1.0);
    d = sqrt(d);
    return vec2(-b - d, -b + d);
}

vec3 atmoDensity(float h) {
    return vec3(exp(-h / 8.0), exp(-h / 1.2), max(0.0, 1.0 - abs(h - 25.0) / 15.0));
}

vec3 atmoExtinction(vec3 dens) {
    return RAYLEIGH_SCATTER * dens.x + MIE_EXTINCT * dens.y + OZONE_ABSORB * dens.z;
}

vec3 atmoViewerPos() {
    float h = 0.35 + clamp(eyeAltitude - 63.0, 0.0, 4000.0) * 0.001;
    return vec3(0.0, ATMO_GROUND + h, 0.0);
}

vec3 atmoTransmittance(vec3 pos, vec3 dir) {
    if (raySphere(pos, dir, ATMO_GROUND).x > 0.0) return vec3(0.0);
    float len = raySphere(pos, dir, ATMO_TOP).y;
    const int steps = 8;
    float dt = len / float(steps);
    vec3 od = vec3(0.0);
    for (int i = 0; i < steps; ++i) {
        vec3 p = pos + dir * (dt * (float(i) + 0.5));
        od += atmoExtinction(atmoDensity(length(p) - ATMO_GROUND));
    }
    return exp(-od * dt);
}

// Radiance scattered towards the viewer along `dir` from a light of unit
// irradiance in direction `lightDir`.
vec3 atmoScattering(vec3 dir, vec3 L) {
    vec3 pos = atmoViewerPos();
    vec2 top = raySphere(pos, dir, ATMO_TOP);
    vec2 ground = raySphere(pos, dir, ATMO_GROUND);
    float len = ground.x > 0.0 ? ground.x : top.y;
    len = min(len, 400.0);

    const int steps = 16;
    float dt = len / float(steps);
    float mu = dot(dir, L);
    float phaseR = rayleighPhase(mu);
    float phaseM = henyeyGreenstein(mu, MIE_G);
    const float phaseIso = 1.0 / (4.0 * PI);

    vec3 transmittance = vec3(1.0);
    vec3 scattering = vec3(0.0);
    for (int i = 0; i < steps; ++i) {
        vec3 p = pos + dir * (dt * (float(i) + 0.5));
        float h = length(p) - ATMO_GROUND;
        vec3 dens = atmoDensity(h);
        vec3 stepT = exp(-atmoExtinction(dens) * dt);

        vec3 sunT = atmoTransmittance(p, L);
        vec3 scatR = RAYLEIGH_SCATTER * dens.x;
        float scatM = MIE_SCATTER * dens.y;

        // Multiple scattering: isotropic, lit by a softened sun so twilight
        // keeps some colour after the direct path is blocked
        float twilight = linstep(-0.25, 0.1, L.y);
        vec3 ms = (scatR + scatM) * phaseIso * (0.35 * twilight) * (sunT * 0.7 + 0.3 * twilight * twilight);

        vec3 S = (scatR * phaseR + scatM * phaseM) * sunT + ms;
        // Energy-conserving integration over the step
        vec3 ext = max(atmoExtinction(dens), 1e-7);
        scattering += transmittance * (S - S * stepT) / ext;
        transmittance *= stepT;
    }
    return scattering;
}

vec3 skyRadiance(vec3 dir) {
    vec3 sky = atmoScattering(dir, sunDir) * SUN_IRRADIANCE;
    sky += atmoScattering(dir, moonDir) * (MOON_IRRADIANCE * moonBrightness) * MOON_TINT;
    // Faint airglow so the night sky isn't pure black
    sky += vec3(0.0010, 0.0016, 0.0032) * SUN_IRRADIANCE * (0.5 + 0.5 * saturate(dir.y));
    return sky;
}

// ----------------------------------------------------------------- LUT mapping

vec3 skyLutDir(vec2 uv) {
    float az = (uv.x - 0.5) * TAU;
    float v = uv.y * 2.0 - 1.0;
    float el = sign(v) * v * v * (0.5 * PI);
    return vec3(cos(el) * cos(az), sin(el), cos(el) * sin(az));
}

vec2 skyLutUv(vec3 dir) {
    float u = atan(dir.z, dir.x) / TAU + 0.5;
    float el = asin(clamp(dir.y, -1.0, 1.0));
    float v = 0.5 + 0.5 * sign(el) * sqrt(abs(el) / (0.5 * PI));
    // Texel i holds u = i / (W - 1), so u = 0 and u = 1 share a direction
    return vec2((u * float(SKY_LUT_W - 1) + 0.5) / SKY_LUT_TEX_W,
                (v * float(SKY_LUT_H - 1) + 0.5) / float(SKY_LUT_H));
}

#endif
