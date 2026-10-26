// final: sharpen, bloom, exposure, filmic tonemap, grading, vignette, dither.

#include "/include/common.glsl"
#include "/include/buffers.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/bloom_tiles.glsl"

in vec2 texcoord;

uniform sampler2D colortex8;
uniform sampler2D colortex9;

layout(location = 0) out vec4 outColor;

// ACES RRT+ODT curve fit (Stephen Hill), applied in ACEScg-ish space
const mat3 ACES_IN = mat3(
    0.59719, 0.07600, 0.02840,
    0.35458, 0.90834, 0.13383,
    0.04823, 0.01566, 0.83777
);
const mat3 ACES_OUT = mat3(
     1.60475, -0.10208, -0.00327,
    -0.53108,  1.10813, -0.07276,
    -0.07367, -0.00605,  1.07602
);
vec3 rrtOdtFit(vec3 v) {
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}
vec3 tonemapAces(vec3 c) {
    c = ACES_IN * c;
    c = rrtOdtFit(c);
    return saturate(ACES_OUT * c);
}

vec3 tonemapSoft(vec3 c) {
    // Extended Reinhard: lifts shadows and keeps highlights from clipping
    const float W = 3.5;
    return min(c * (1.0 + c / (W * W)) / (1.0 + c), vec3(1.0));
}

vec3 sampleBloom(vec2 uv) {
    vec2 halfTexel = 0.5 / (viewSize * 0.5);
    vec3 sum = vec3(0.0);
    for (int i = 0; i < BLOOM_TILE_COUNT; ++i) {
        vec2 lo = bloomTileOffset[i] + halfTexel;
        vec2 hi = bloomTileOffset[i] + bloomTileSize[i] - halfTexel;
        vec2 tuv = clamp(bloomTileOffset[i] + uv * bloomTileSize[i], lo, hi);
        sum += textureLod(colortex9, tuv, 0.0).rgb;
    }
    return sum / float(BLOOM_TILE_COUNT);
}

void main() {
    ivec2 px = ivec2(gl_FragCoord.xy);
    vec3 color = texelFetch(colortex8, px, 0).rgb;

    // Contrast-adaptive-ish sharpening, limited to the local range
    ivec2 maxPx = ivec2(viewSize) - 1;
    vec3 n = texelFetch(colortex8, clamp(px + ivec2(0, 1), ivec2(0), maxPx), 0).rgb;
    vec3 s = texelFetch(colortex8, clamp(px - ivec2(0, 1), ivec2(0), maxPx), 0).rgb;
    vec3 e = texelFetch(colortex8, clamp(px + ivec2(1, 0), ivec2(0), maxPx), 0).rgb;
    vec3 w = texelFetch(colortex8, clamp(px - ivec2(1, 0), ivec2(0), maxPx), 0).rgb;
    vec3 mn = min(color, min(min(n, s), min(e, w)));
    vec3 mx = max(color, max(max(n, s), max(e, w)));
    vec3 blur = (n + s + e + w) * 0.25;
    color = clamp(color + (color - blur) * SHARPENING, mn, mx);

#ifdef BLOOM
    vec3 bloom = sampleBloom(texcoord);
    color = mix(color, bloom, 0.06 * BLOOM_STRENGTH * (1.0 + 0.5 * rainStrength));
#endif

    float exposure = texelFetch(colortex9, ivec2(viewSize * 0.5) - 1, 0).r;
    color *= exposure * exp2(EXPOSURE_BIAS);
    color *= vec3(1.07, 1.0, 0.90); // warm white balance

    color = mix(tonemapAces(color), tonemapSoft(color), 0.3);
    color = pow(color, vec3(0.95)); // lift midtones

    // Grading in display-ish space
    float l = luminance(color);
    color = mix(vec3(l), color, SATURATION);
    color = saturate((color - 0.5) * CONTRAST + 0.5);

    vec2 vc = texcoord - 0.5;
    color *= 1.0 - VIGNETTE * dot(vc, vc) * 1.6;

    color = linearToSrgb(color);
    color += (ign(gl_FragCoord.xy) - 0.5) / 255.0;
    outColor = vec4(color, 1.0);
}

#endif
