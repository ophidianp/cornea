// composite: half-res volumetric light. In air: sun shafts through a height
// fog, shadowed by terrain and clouds. Under water: light shafts through the
// water column, absorbed with depth and modulated by caustics.

#include "/include/common.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/space.glsl"
#include "/include/sky.glsl"
#if defined VL || defined UW_VL
#include "/include/shadow.glsl"
#include "/include/materials.glsl"
#include "/include/lighting.glsl"
#include "/include/fog.glsl"
#endif

in vec2 texcoord;

uniform sampler2D depthtex0;

/* RENDERTARGETS: 7 */
layout(location = 0) out vec4 outVL;

#if defined VL || defined UW_VL
vec3 shadowUvz(vec3 scenePos) {
    vec3 clip = (shadowProjection * (shadowModelView * vec4(scenePos, 1.0))).xyz;
    return distortShadowClip(clip) * 0.5 + 0.5;
}
#endif

void main() {
    vec3 result = vec3(0.0);

#if defined VL || defined UW_VL
    float depth = textureLod(depthtex0, texcoord, 0.0).r;
    vec3 scenePos = viewToScene(screenToView(vec3(texcoord, depth)));
    vec3 origin = gbufferModelViewInverse[3].xyz;
    vec3 ray = scenePos - origin;
    float dist = depth >= 1.0 ? 1e6 : length(ray);
    vec3 dir = ray / length(ray);
    float mu = dot(dir, lightDir);
    float dither = ignAnimated(gl_FragCoord.xy);
    vec3 lightCol = lightColor() * linstep(0.1, 0.6, eyeSkylight);

    if (isEyeInWater == 1) {
    #ifdef UW_VL
        float maxDist = min(dist, 48.0);
        float stepLen = maxDist / float(VL_STEPS);
        float phase = mix(henyeyGreenstein(mu, 0.65), 1.0 / (4.0 * PI), 0.25);
        vec3 scatter = vec3(0.0);
        vec3 glow = vec3(0.0);
        for (int i = 0; i < VL_STEPS; ++i) {
            float t = stepLen * (float(i) + dither);
            vec3 p = origin + dir * t;
            // Glow around torches, lava etc. from the coloured light volume,
            // shimmering with caustics; works with no sun at all (caves)
            vec3 blockLight = sampleColoredLightRaw(p);
            if (maxOf(blockLight) > 0.002) {
                float shimmer = 0.65 + 0.7 * waterCaustics(p + cameraPosition, vec3(0.0, 1.0, 0.0));
                glow += blockLight * shimmer * exp(-WATER_EXTINCTION * t);
            }
            vec3 uvz = shadowUvz(p);
            if (any(lessThan(uvz.xy, vec2(0.0))) || any(greaterThan(uvz.xy, vec2(1.0)))) continue;
            float vis = texture(shadowtex1, vec3(uvz.xy, uvz.z - 0.0003));
            if (vis < 0.01) continue;
            // Depth below the water surface along the light ray
            float surface = textureLod(shadowtex0, uvz.xy, 0.0).r;
            float waterDepth = uvz.z > surface ? shadowDepthToBlocks(uvz.z - surface) : 0.0;
            vec3 transmit = exp(-WATER_EXTINCTION * (waterDepth + t));
        #ifdef CAUSTICS
            float caustic = waterCaustics(p + cameraPosition, lightDir);
            vis *= mix(1.0, caustic * caustic, 0.8);
        #endif
            scatter += vis * transmit;
        }
        result = lightCol * WATER_SCATTERING * scatter * stepLen * phase * 3.0 * VL_STRENGTH;
        result += glow * WATER_SCATTERING * stepLen * 14.0 * VL_STRENGTH;
    #endif
    } else {
    #ifdef VL
        float maxDist = min(dist, shadowDistance);
        float stepLen = maxDist / float(VL_STEPS);
        float phase = mix(henyeyGreenstein(mu, 0.78), 1.0 / (4.0 * PI), 0.35);
        float transmittance = 1.0;
        float scatter = 0.0;
        for (int i = 0; i < VL_STEPS; ++i) {
            float t = stepLen * (float(i) + dither);
            vec3 p = origin + dir * t;
            float density = fogDensityAt(p.y + cameraPosition.y) * 1.5 + 0.00015 * FOG_DENSITY;
            vec3 uvz = shadowUvz(p);
            float vis = 1.0;
            if (all(greaterThan(uvz.xy, vec2(0.0))) && all(lessThan(uvz.xy, vec2(1.0)))) {
                vis = texture(shadowtex1, vec3(uvz.xy, uvz.z - 0.0003));
            }
            vis *= cloudShadow(p + cameraPosition);
            scatter += vis * density * transmittance * stepLen;
            transmittance *= exp(-density * stepLen);
        }
        // Less in caves (no sky to scatter), more at sunrise/sunset
        float lowSun = 1.0 + 1.5 * linstep(0.35, 0.05, abs(lightDir.y));
        result = lightCol * scatter * phase * lowSun * (1.0 - 0.7 * caveFactor) * VL_STRENGTH;
    #endif
    }
#endif

    outVL = vec4(result, 1.0);
}

#endif
