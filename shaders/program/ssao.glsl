// deferred: half-resolution SSAO (normal-oriented hemisphere, 6 taps).
// TAA and the bilinear upsample in the lighting pass smooth the noise.

#include "/include/common.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/space.glsl"
#include "/include/materials.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D colortex1;

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 outAO;

void main() {
    // One full-res texel of the 2x2 block, rotating per frame
    ivec2 offset = ivec2(frameCounter & 1, (frameCounter >> 1) & 1);
    ivec2 fullPx = ivec2(gl_FragCoord.xy) * 2 + offset;
    vec2 uv = (vec2(fullPx) + 0.5) * texelSize;
    float depth = texelFetch(depthtex0, fullPx, 0).r;

    if (depth >= 1.0 || depth < MC_HAND_DEPTH) {
        outAO = vec4(1.0);
        return;
    }

    vec3 viewPos = screenToView(vec3(uv, depth));
    GbufferData g = unpackGbuffer(texelFetch(colortex1, fullPx, 0));
    vec3 n = mat3(gbufferModelView) * g.normal;

    const int taps = 6;
    const float radius = 0.6;
    float noise = ignAnimated(gl_FragCoord.xy);
    float occlusion = 0.0;
    for (int i = 0; i < taps; ++i) {
        // Spherical fibonacci direction, rotated by noise, flipped into the hemisphere
        float fi = float(i) + noise;
        float z = 1.0 - (2.0 * fi + 1.0) / float(2 * taps);
        float r = sqrt(1.0 - z * z);
        float phi = fi * 2.39996323 + noise * TAU;
        vec3 dir = vec3(r * cos(phi), r * sin(phi), z);
        dir = dot(dir, n) < 0.0 ? -dir : dir;
        float scale = mix(0.25, 1.0, sqr(fract(noise + float(i) * 0.618)));

        vec3 samplePos = viewPos + dir * (radius * scale) + n * 0.05;
        vec3 sampleScreen = viewToScreen(samplePos);
        if (any(lessThan(sampleScreen.xy, vec2(0.0))) || any(greaterThan(sampleScreen.xy, vec2(1.0)))) continue;

        float sceneDepth = textureLod(depthtex0, sampleScreen.xy, 0.0).r;
        float sceneZ = screenToView(vec3(sampleScreen.xy, sceneDepth)).z;
        float diff = sceneZ - samplePos.z;
        // Occluded if the scene is in front of the sample, within range
        occlusion += step(0.02, diff) * linstep(radius * 2.0, radius * 0.5, diff);
    }

    float ao = 1.0 - occlusion / float(taps);
    ao = pow(saturate(ao), AO_STRENGTH * 1.4);
    outAO = vec4(ao);
}

#endif
