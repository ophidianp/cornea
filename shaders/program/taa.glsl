// composite2: temporal anti-aliasing. Reprojects history with depth,
// samples it with a 5-tap Catmull-Rom, clips it to the current
// neighbourhood in YCoCg and blends with luminance weighting.

#include "/include/common.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/space.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D colortex0; // current frame
uniform sampler2D colortex8; // history

/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 outColor;

vec3 rgbToYcocg(vec3 c) {
    return vec3(0.25 * c.r + 0.5 * c.g + 0.25 * c.b, 0.5 * c.r - 0.5 * c.b, -0.25 * c.r + 0.5 * c.g - 0.25 * c.b);
}
vec3 ycocgToRgb(vec3 c) {
    return vec3(c.x + c.y - c.z, c.x + c.z, c.x - c.y - c.z);
}

// Catmull-Rom with 5 bilinear taps (corners dropped)
vec3 sampleHistory(vec2 uv) {
    vec2 size = viewSize;
    vec2 pos = uv * size;
    vec2 center = floor(pos - 0.5) + 0.5;
    vec2 f = pos - center;
    vec2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
    vec2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
    vec2 w3 = f * f * (-0.5 + 0.5 * f);
    vec2 w12 = w1 + w2;
    vec2 tc0 = (center - 1.0) / size;
    vec2 tc3 = (center + 2.0) / size;
    vec2 tc12 = (center + w2 / w12) / size;

    vec3 c = textureLod(colortex8, vec2(tc12.x, tc0.y), 0.0).rgb * (w12.x * w0.y)
           + textureLod(colortex8, vec2(tc0.x, tc12.y), 0.0).rgb * (w0.x * w12.y)
           + textureLod(colortex8, vec2(tc12.x, tc12.y), 0.0).rgb * (w12.x * w12.y)
           + textureLod(colortex8, vec2(tc3.x, tc12.y), 0.0).rgb * (w3.x * w12.y)
           + textureLod(colortex8, vec2(tc12.x, tc3.y), 0.0).rgb * (w12.x * w3.y);
    float wsum = w12.x * w0.y + w0.x * w12.y + w12.x * w12.y + w3.x * w12.y + w12.x * w3.y;
    return max(c / wsum, 0.0);
}

void main() {
    ivec2 px = ivec2(gl_FragCoord.xy);
    vec3 current = texelFetch(colortex0, px, 0).rgb;

#ifndef TAA
    outColor = vec4(current, 1.0);
#else
    // Neighbourhood statistics (variance clipping)
    vec3 m1 = vec3(0.0), m2 = vec3(0.0);
    vec3 mn = vec3(1e9), mx = vec3(-1e9);
    float closestDepth = 1.0;
    ivec2 closestOffset = ivec2(0);
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            ivec2 q = clamp(px + ivec2(x, y), ivec2(0), ivec2(viewSize) - 1);
            vec3 c = rgbToYcocg(texelFetch(colortex0, q, 0).rgb);
            m1 += c; m2 += c * c;
            mn = min(mn, c); mx = max(mx, c);
            float d = texelFetch(depthtex0, q, 0).r;
            if (d < closestDepth) { closestDepth = d; closestOffset = ivec2(x, y); }
        }
    }
    vec3 mean = m1 / 9.0;
    vec3 sigma = sqrt(max(m2 / 9.0 - mean * mean, 0.0));
    vec3 boxMin = max(mn, mean - sigma * 1.25);
    vec3 boxMax = min(mx, mean + sigma * 1.25);

    // Reproject using the closest depth in the neighbourhood (sharper edges)
    float depth = closestDepth;
    vec2 uv = texcoord + vec2(closestOffset) * texelSize;
    vec2 prevUv;
    if (depth < MC_HAND_DEPTH) {
        prevUv = texcoord;
    } else {
        vec3 viewPos = screenToView(vec3(uv, depth));
        bool isSky = depth >= 1.0;
        vec3 scenePos = isSky ? mat3(gbufferModelViewInverse) * viewPos : viewToScene(viewPos);
        prevUv = reprojectScene(scenePos, isSky).xy - vec2(closestOffset) * texelSize;
    }

    if (any(lessThan(prevUv, vec2(0.0))) || any(greaterThan(prevUv, vec2(1.0))) || frameCounter < 2) {
        outColor = vec4(current, 1.0);
        return;
    }

    vec3 history = rgbToYcocg(sampleHistory(prevUv));
    // Clip towards the box centre rather than clamping per channel
    vec3 center = (boxMin + boxMax) * 0.5;
    vec3 extent = max((boxMax - boxMin) * 0.5, 1e-5);
    vec3 offset = history - center;
    vec3 ts = abs(offset / extent);
    float tMax = max(ts.x, max(ts.y, ts.z));
    if (tMax > 1.0) history = center + offset / tMax;
    history = ycocgToRgb(history);

    // Motion lowers the history weight slightly to limit blur
    float motion = length((texcoord - prevUv) * viewSize);
    float weight = mix(0.92, 0.80, saturate(motion / 8.0));

    // Luminance weighting suppresses fireflies
    float wc = (1.0 - weight) / (1.0 + luminance(current));
    float wh = weight / (1.0 + luminance(history));
    vec3 result = (current * wc + history * wh) / (wc + wh);

    outColor = vec4(result, 1.0);
#endif
}

#endif
