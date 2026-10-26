// deferred2: temporal accumulation of the half-res clouds. Clouds are far
// away, so reprojection only needs the camera rotation.

#include "/include/common.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/space.glsl"

in vec2 texcoord;

uniform sampler2D colortex5; // current
uniform sampler2D colortex6; // history

/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 outClouds;

void main() {
    ivec2 px = ivec2(gl_FragCoord.xy);
    ivec2 size = textureSize(colortex5, 0);
    vec4 current = texelFetch(colortex5, px, 0);

    // Neighbourhood bounds for history clamping
    vec4 mn = current, mx = current;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            if (x == 0 && y == 0) continue;
            vec4 c = texelFetch(colortex5, clamp(px + ivec2(x, y), ivec2(0), size - 1), 0);
            mn = min(mn, c);
            mx = max(mx, c);
        }
    }

    vec3 viewDir = screenToView(vec3(texcoord, 1.0));
    vec3 dir = mat3(gbufferModelViewInverse) * viewDir;
    vec2 prevUv = reprojectScene(dir, true).xy;

    float blend = 0.12;
    if (any(lessThan(prevUv, vec2(0.0))) || any(greaterThan(prevUv, vec2(1.0))) || frameCounter < 2) {
        blend = 1.0;
    }

    vec4 history = textureLod(colortex6, prevUv, 0.0);
    vec4 range = mx - mn;
    history = clamp(history, mn - range * 0.25, mx + range * 0.25);

    outClouds = mix(history, current, blend);
}

#endif
