#if !defined SHADOW_GLSL
#define SHADOW_GLSL

// Shadow map lookup: PCSS-lite (4-tap blocker search, early-out when nothing
// is in the way) + rotated Vogel-disk PCF on the hardware comparison sampler,
// coloured shadows from stained glass, and water absorption + caustics.

#include "/include/shadow_distort.glsl"
#include "/include/water.glsl"
#include "/include/caustics.glsl"

uniform sampler2D shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;

vec2 vogelDisk(int i, int n, float phi) {
    float r = sqrt((float(i) + 0.5) / float(n));
    float theta = float(i) * 2.39996323 + phi;
    return r * vec2(cos(theta), sin(theta));
}

// Shadow-map depth difference -> blocks
float shadowDepthToBlocks(float d) {
    return d * 2.0 / (SHADOW_DEPTH_SCALE * abs(shadowProjection[2][2]));
}

// Returns shadow-space uv + depth, already biased. w = world size of a texel.
vec4 getShadowCoord(vec3 scenePos, vec3 normal) {
    vec3 shadowView = (shadowModelView * vec4(scenePos, 1.0)).xyz;
    vec2 clipXY = (shadowProjection * vec4(shadowView, 1.0)).xy;
    float f = shadowDistortFactor(clipXY);
    float texelWorld = (2.0 * shadowDistance / float(shadowMapResolution)) * f * f / (1.0 - SHADOW_DISTORTION);

    // Small normal offset (large ones leave a lit gap where a block meets
    // the ground); the rest of the bias is in depth, scaled by slope
    vec3 shadowNormal = mat3(shadowModelView) * normal;
    float NdotL = saturate(shadowNormal.z);
    shadowView += shadowNormal * texelWorld * (0.35 + 0.5 * (1.0 - NdotL));

    vec3 clip = (shadowProjection * vec4(shadowView, 1.0)).xyz;
    vec3 uvz = distortShadowClip(clip) * 0.5 + 0.5;
    return vec4(uvz, texelWorld);
}

// Light visibility (rgb so glass and water can tint it)
vec3 getShadow(vec3 scenePos, vec3 worldPos, vec3 normal, float dither) {
#if SHADOW_MODE >= 2
    // Pixelated: look the shadow up at the centre of a world-space pixel,
    // slid back onto the surface plane so it can't self-shadow
    {
        vec3 snapped = (floor(worldPos * float(PIXEL_SHADOW_RES)) + 0.5) / float(PIXEL_SHADOW_RES);
        snapped -= normal * dot(snapped - worldPos, normal);
        scenePos += snapped - worldPos;
    }
#endif
    vec4 sc = getShadowCoord(scenePos, normal);
    vec3 uvz = sc.xyz;
    if (any(lessThan(uvz.xy, vec2(0.0))) || any(greaterThan(uvz.xy, vec2(1.0))) || uvz.z >= 1.0) {
        return vec3(1.0);
    }
    float slope = sqrt(max(1.0 - sqr(dot(normal, lightDir)), 0.0)) / max(abs(dot(normal, lightDir)), 0.1);
    float biasBlocks = sc.w * (0.6 + 0.9 * min(slope, 4.0));
    uvz.z -= biasBlocks * SHADOW_DEPTH_SCALE * abs(shadowProjection[2][2]) * 0.5;

    float texel = 1.0 / float(shadowMapResolution);
    float phi = dither * TAU;
    float shadow;

#if SHADOW_MODE == 0 || SHADOW_MODE == 2
    // Low: plain filtered lookup, fixed softness
    shadow = 0.0;
    for (int i = 0; i < SHADOW_SAMPLES_LOW; ++i) {
        vec2 o = vogelDisk(i, SHADOW_SAMPLES_LOW, phi) * 2.0 * texel;
        shadow += texture(shadowtex1, vec3(uvz.xy + o, uvz.z));
    }
    shadow /= float(SHADOW_SAMPLES_LOW);
#elif defined SHADOW_PCSS
    // Blocker search on the raw depth (includes translucents, close enough)
    const float searchRadius = 18.0;
    float blockerSum = 0.0;
    float blockerCount = 0.0;
    for (int i = 0; i < 4; ++i) {
        vec2 o = vogelDisk(i, 4, phi) * searchRadius * texel;
        float d = textureLod(shadowtex0, uvz.xy + o, 0.0).r;
        if (d < uvz.z) { blockerSum += d; blockerCount += 1.0; }
    }
    if (blockerCount < 0.5) {
        shadow = 1.0;
    } else {
        float blocker = blockerSum / blockerCount;
        // Soft everywhere, softer the further the shadow is from its caster
        float penumbraBlocks = (0.06 + shadowDepthToBlocks(uvz.z - blocker) * 0.07) * SHADOW_SOFTNESS;
        float radius = clamp(penumbraBlocks / sc.w, 1.5, searchRadius);
        shadow = 0.0;
        for (int i = 0; i < SHADOW_SAMPLES; ++i) {
            vec2 o = vogelDisk(i, SHADOW_SAMPLES, phi) * radius * texel;
            shadow += texture(shadowtex1, vec3(uvz.xy + o, uvz.z));
        }
        shadow /= float(SHADOW_SAMPLES);
    }
#else
    shadow = 0.0;
    float radius = 2.5 * SHADOW_SOFTNESS;
    for (int i = 0; i < SHADOW_SAMPLES; ++i) {
        vec2 o = vogelDisk(i, SHADOW_SAMPLES, phi) * radius * texel;
        shadow += texture(shadowtex1, vec3(uvz.xy + o, uvz.z));
    }
    shadow /= float(SHADOW_SAMPLES);
#endif

    vec3 result = vec3(shadow);

#ifdef COLORED_SHADOWS
    if (shadow > 0.001) {
        float s0 = textureLod(shadowtex0, uvz.xy, 0.0).r;
        if (s0 < uvz.z - 0.0002) {
            vec4 sc0 = textureLod(shadowcolor0, uvz.xy, 0.0);
            if (sc0.a < 0.5) {
                // Under water: absorb along the light path and add caustics
                float depthBlocks = shadowDepthToBlocks(uvz.z - s0);
                vec3 absorb = exp(-WATER_EXTINCTION * depthBlocks);
#ifdef CAUSTICS
                float causticFade = linstep(0.0, 1.5, depthBlocks);
                float caustic = mix(1.0, waterCaustics(worldPos, lightDir), causticFade);
                absorb *= caustic;
#endif
                result *= absorb;
            } else {
                result *= sc0.rgb;
            }
        }
    }
#endif
    return result;
}

// One-tap hardware shadow for forward shading and volumetrics
float getShadowFast(vec3 scenePos) {
    vec3 clip = (shadowProjection * (shadowModelView * vec4(scenePos, 1.0))).xyz;
    vec3 uvz = distortShadowClip(clip) * 0.5 + 0.5;
    if (any(lessThan(uvz.xy, vec2(0.0))) || any(greaterThan(uvz.xy, vec2(1.0))) || uvz.z >= 1.0) return 1.0;
    return texture(shadowtex1, vec3(uvz.xy, uvz.z - 0.0002));
}

#endif
