// composite3: one pass builds every bloom level from colortex8's mip chain
// into a tile atlas, and updates the smoothed auto-exposure value stored in
// the atlas' top-right texel.

#include "/include/common.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/bloom_tiles.glsl"
#include "/include/sky.glsl"

in vec2 texcoord;

const bool colortex8MipmapEnabled = true;
uniform sampler2D colortex8;
uniform sampler2D colortex9;

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 outBloom;

float computeExposure() {
    // Driven by how much light the scene actually receives, not by the
    // average screen colour (which greys out bright skies). Underground the
    // eye adapts up, outdoors by day it sits low.
#if defined WORLD_OVERWORLD
    float sky = eyeSkylight;
    float ref = 0.35 * luminance(lightColor()) * sky + luminance(ambientColor()) * (0.3 + 0.7 * sky);
#else
#if defined WORLD_NETHER
    float ref = 0.22; // fixed: the Nether should stay dark and moody
#else
    float ref = luminance(ambientColor()) + 0.1 + 0.35 * luminance(lightColor());
#endif
#endif
    ref = max(ref, 0.004);
    return clamp(0.70 / pow(ref, 0.55), 0.12, 3.0);
}

void main() {
    ivec2 px = ivec2(gl_FragCoord.xy);
    ivec2 size = ivec2(viewSize * 0.5);

    if (px == size - 1) {
#ifdef AUTO_EXPOSURE
        float target = computeExposure();
        float prev = texelFetch(colortex9, px, 0).r;
        if (!(prev > 0.0) || frameCounter < 2) prev = target;
        // Faster to adapt to brightness than to darkness
        float speed = target < prev ? 3.0 : 1.2;
        float exposure = mix(prev, target, 1.0 - exp(-frameTime * speed));
#else
        float exposure = 0.25;
#endif
        outBloom = vec4(exposure, 0.0, 0.0, 1.0);
        return;
    }

#ifdef BLOOM
    vec2 bufUv = gl_FragCoord.xy / vec2(size);
    for (int i = 0; i < BLOOM_TILE_COUNT; ++i) {
        vec2 local = (bufUv - bloomTileOffset[i]) / bloomTileSize[i];
        if (all(greaterThanEqual(local, vec2(0.0))) && all(lessThanEqual(local, vec2(1.0)))) {
            float lod = float(i + 2);
            vec2 texel = exp2(lod) * texelSize;
            // 3x3 tent at this mip level
            vec3 sum = vec3(0.0);
            float wsum = 0.0;
            for (int y = -1; y <= 1; ++y) {
                for (int x = -1; x <= 1; ++x) {
                    float w = (2.0 - abs(float(x))) * (2.0 - abs(float(y)));
                    sum += textureLod(colortex8, local + vec2(x, y) * texel, lod).rgb * w;
                    wsum += w;
                }
            }
            outBloom = vec4(sum / wsum, 1.0);
            return;
        }
    }
#endif
    outBloom = vec4(0.0);
}

#endif
