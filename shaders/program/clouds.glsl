// deferred1: raymarch the cloud layer at half resolution (1/4 of the pixels)
// with a per-frame jittered start; deferred2 accumulates over time.

#include "/include/common.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/space.glsl"
#include "/include/sky.glsl"
#include "/include/clouds.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;

/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 outClouds;

void main() {
    float depth = textureLod(depthtex0, texcoord, 0.0).r;
    vec3 viewPos = screenToView(vec3(texcoord, depth));
    vec3 scenePos = viewToScene(viewPos);
    vec3 dir = normalize(scenePos - gbufferModelViewInverse[3].xyz);
    float maxDist = depth >= 1.0 ? 1e9 : length(scenePos);

    float dither = ign(gl_FragCoord.xy + 7.13 * float(frameCounter % 64));
    vec3 lightCol = lightColor();
    vec3 amb = ambientColor();

    vec4 clouds = renderClouds(dir, maxDist, dither, lightCol, amb);
    if (depth >= 1.0) {
        vec4 cirrus = renderCirrus(dir, lightCol, amb);
        // Cirrus sits above the cumulus layer
        clouds.rgb += clouds.a * cirrus.rgb;
        clouds.a *= cirrus.a;
    }
    outClouds = clouds;
}

#endif
