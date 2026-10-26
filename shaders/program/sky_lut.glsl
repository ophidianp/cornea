// prepare: 192x108 sky-view LUT plus a data column (x = 192) holding the sun,
// moon, ambient, shadow-light and horizon colours for every later pass.

#include "/include/common.glsl"
#include "/include/buffers.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/atmosphere.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 4 */
layout(location = 0) out vec4 outSky;

#if defined WORLD_OVERWORLD
vec3 computeAmbient() {
    // Cosine-weighted hemisphere: E = pi * mean(L) over cosine-distributed rays
    const int rings = 3;
    const int perRing = 6;
    vec3 sum = vec3(0.0);
    for (int r = 0; r < rings; ++r) {
        float radius = sqrt((float(r) + 0.5) / float(rings));
        float y = sqrt(1.0 - radius * radius);
        for (int a = 0; a < perRing; ++a) {
            float phi = (float(a) + 0.5 * float(r)) * (TAU / float(perRing));
            sum += skyRadiance(vec3(radius * cos(phi), y, radius * sin(phi)));
        }
    }
    vec3 E = sum * (PI / float(rings * perRing));
    return E * (1.0 - 0.55 * rainStrength);
}

vec3 computeHorizon() {
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 6; ++i) {
        float phi = float(i) * (TAU / 6.0);
        sum += skyRadiance(normalize(vec3(cos(phi), 0.06, sin(phi))));
    }
    return sum / 6.0;
}
#endif

void main() {
    ivec2 px = ivec2(gl_FragCoord.xy);

#if defined WORLD_OVERWORLD
    if (px.x < SKY_LUT_W) {
        vec2 uv = vec2(px) / vec2(SKY_LUT_W - 1, SKY_LUT_H - 1);
        outSky = vec4(skyRadiance(skyLutDir(uv)), 1.0);
        return;
    }

    vec3 viewer = atmoViewerPos();
    vec3 sun = SUN_IRRADIANCE * atmoTransmittance(viewer, sunDir) * linstep(-0.02, 0.03, sunDir.y);
    vec3 moon = (MOON_IRRADIANCE * moonBrightness) * MOON_TINT * atmoTransmittance(viewer, moonDir) * linstep(-0.02, 0.03, moonDir.y);

    vec3 data = vec3(0.0);
    if (px.y == SKY_ROW_SUN) {
        data = sun;
    } else if (px.y == SKY_ROW_MOON) {
        data = moon;
    } else if (px.y == SKY_ROW_AMBIENT) {
        data = computeAmbient();
    } else if (px.y == SKY_ROW_LIGHT) {
        // Whichever body casts shadows, dimmed under rain clouds
        vec3 l = sunDir.y > 0.0 ? sun : moon;
        data = l * (1.0 - 0.85 * rainStrength);
    } else if (px.y == SKY_ROW_HORIZON) {
        data = computeHorizon();
    }
    outSky = vec4(data, 1.0);
#else
    outSky = vec4(0.0);
#endif
}

#endif
