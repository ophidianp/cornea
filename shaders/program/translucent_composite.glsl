// composite1: water (refraction, absorption, SSR + sky reflection, sun
// glint), other translucents, underwater fog and the volumetric light.

#include "/include/common.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/space.glsl"
#include "/include/materials.glsl"
#include "/include/sky.glsl"
#ifdef SHADOWS
#include "/include/shadow.glsl"
#else
#include "/include/water.glsl"
#endif
#include "/include/lighting.glsl"
#include "/include/fog.glsl"
#ifdef WATER_RIPPLES
#include "/include/interact.glsl"
layout(r32ui) uniform writeonly uimage2D waterFlagImg;
#endif

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0; // opaque scene
uniform sampler2D colortex2; // translucent colour
uniform sampler2D colortex3; // translucent data
uniform sampler2D colortex7; // volumetric light

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

float fresnelSchlick(float cosTheta, float f0) {
    return f0 + (1.0 - f0) * pow5(1.0 - saturate(cosTheta));
}

float ggxSpecular(vec3 n, vec3 v, vec3 l, float roughness) {
    vec3 h = normalize(l + v);
    float NdotH = saturate(dot(n, h));
    float NdotL = saturate(dot(n, l));
    float a2 = sqr(roughness * roughness);
    float d = a2 / (PI * sqr(NdotH * NdotH * (a2 - 1.0) + 1.0));
    return d * NdotL * 0.25;
}

#ifdef WATER_SSR
// Screen-space ray march against opaque depth; returns hit uv or -1
vec2 traceSSR(vec3 viewPos, vec3 viewDir, float dither) {
    float rayLen = viewDir.z > 0.0 ? min(far, (-near * 1.5 - viewPos.z) / viewDir.z) : far;
    vec3 start = viewToScreen(viewPos);
    vec3 end = viewToScreen(viewPos + viewDir * max(rayLen, 0.1));
    vec3 delta = end - start;

    // Clip the ray to the screen so no steps are wasted off-screen
    vec2 scale = vec2(1.0);
    if (end.x < 0.0) scale.x = start.x / max(start.x - end.x, 1e-5);
    if (end.x > 1.0) scale.x = (1.0 - start.x) / max(end.x - start.x, 1e-5);
    if (end.y < 0.0) scale.y = start.y / max(start.y - end.y, 1e-5);
    if (end.y > 1.0) scale.y = (1.0 - start.y) / max(end.y - start.y, 1e-5);
    delta *= min(scale.x, scale.y);

    vec3 stepVec = delta / float(SSR_STEPS);
    vec3 p = start + stepVec * dither;
    for (int i = 0; i < SSR_STEPS; ++i) {
        p += stepVec;
        if (p.z >= 1.0) break;
        float d = textureLod(depthtex1, p.xy, 0.0).r;
        if (p.z > d && d < 1.0) {
            // Binary refinement
            vec3 lo = p - stepVec, hi = p;
            for (int j = 0; j < 4; ++j) {
                vec3 mid = (lo + hi) * 0.5;
                if (mid.z > textureLod(depthtex1, mid.xy, 0.0).r) hi = mid; else lo = mid;
            }
            float dHit = textureLod(depthtex1, hi.xy, 0.0).r;
            // Reject hits behind thick geometry
            if (linearDepth(hi.z) - linearDepth(dHit) < 2.0 + linearDepth(hi.z) * 0.05) return hi.xy;
            return vec2(-1.0);
        }
    }
    return vec2(-1.0);
}
#endif

vec3 shadeWater(vec3 color, vec4 data, float depth0, float depth1, inout vec2 refractUv) {
    vec3 viewPos0 = screenToView(vec3(texcoord, depth0));
    vec3 scenePos0 = viewToScene(viewPos0);
    vec3 worldPos0 = scenePos0 + cameraPosition;
    vec3 dir = normalize(scenePos0 - gbufferModelViewInverse[3].xyz);
    float skylight = data.a;
    bool underwater = isEyeInWater == 1;

    vec3 geoNormal = octDecode(data.rg);
    vec3 n = geoNormal;
#ifdef WATER_WAVES
    if (abs(geoNormal.y) > 0.9) {
        n = waterNormal(worldPos0.xz);
#ifdef WATER_RIPPLES
        {
            vec2 rs = rippleSlope(worldPos0.xz) * (2.0 * RIPPLE_STRENGTH);
            n = normalize(n + vec3(rs.x, 0.0, rs.y));
            vec3 feet = cameraPosition + relativeEyePosition - vec3(0.0, 1.62, 0.0);
            vec3 dFeet = worldPos0 - feet;
            if (dot(dFeet.xz, dFeet.xz) < 2.25 && abs(dFeet.y) < 1.3) {
                imageStore(waterFlagImg, ivec2(0), uvec4(uint(frameCounter)));
            }
        }
#endif
        if (geoNormal.y < 0.0) n = -n;
    }
#endif
    vec3 viewN = mat3(gbufferModelView) * n;
    vec3 viewGeoN = mat3(gbufferModelView) * geoNormal;

    // Refraction: offset the background lookup by the wave normal
    vec2 uv = texcoord;
#ifdef REFRACTION
    vec2 offset = clamp((viewN.xy - viewGeoN.xy) * 0.3 / (1.0 + length(viewPos0) * 0.04), vec2(-0.02), vec2(0.02));
    vec2 uvR = clamp(texcoord + offset, vec2(0.001), vec2(0.999));
    if (textureLod(depthtex1, uvR, 0.0).r > depth0) uv = uvR;
#endif
    refractUv = uv;
    vec3 bg = textureLod(colortex0, uv, 0.0).rgb;
    float d1 = textureLod(depthtex1, uv, 0.0).r;

    vec3 ambient = ambientColor() * skylight * skylight + getMinLight() * 10.0;
    // No sunlight on water that has a roof over it
    vec3 light = lightColor() * linstep(0.25, 0.85, skylight);
    float surfaceShadow = 1.0;
#if defined SHADOWS
    surfaceShadow = getShadowFast(scenePos0 + geoNormal * 0.1) * cloudShadow(worldPos0);
#endif

    if (!underwater) {
        // Absorption + in-scatter through the water body
        float thickness = d1 >= 1.0 ? 64.0
            : max(length(viewToScene(screenToView(vec3(uv, d1)))) - length(scenePos0), 0.0);
        vec3 T = exp(-SURFACE_EXTINCTION * thickness);
        vec3 inscatter = (ambient * 0.6 + light * surfaceShadow * 0.25) * (SURFACE_SCATTERING / SURFACE_EXTINCTION);
        bg = bg * T + inscatter * (1.0 - T);
    }

    // Reflection
    vec3 V = -dir;
    vec3 Rw = reflect(dir, normalize(mix(geoNormal, n, 0.5)));
    float NdotV = saturate(dot(n, V));
    float fresnel = underwater ? fresnelSchlick(NdotV, 0.1) : fresnelSchlick(NdotV, 0.02);

    vec3 reflection;
    if (underwater) {
        // Seen from below, reflections show the water itself
        reflection = ambient * (WATER_SCATTERING / WATER_EXTINCTION) * 0.5;
    } else {
        vec3 skyRefl = renderSky(Rw, false);
        float openSky = linstep(0.0, 0.6, skylight);
        // Where the sky isn't visible (caves, under overhangs) fall back to a
        // muted copy of what is under the surface instead of black, so a
        // missed reflection doesn't leave a hard seam against a hit one
        reflection = mix(bg * 0.5 + getMinLight() * 6.0, skyRefl, openSky);
    #ifdef WATER_SSR
        vec3 viewR = mat3(gbufferModelView) * Rw;
        vec2 hit = traceSSR(viewPos0, viewR, ignAnimated(gl_FragCoord.xy));
        if (hit.x >= 0.0) {
            float edge = linstep(0.0, 0.12, min(min(hit.x, 1.0 - hit.x), min(hit.y, 1.0 - hit.y)));
            // Three taps at a coarser mip: a slightly rough, continuous reflection
            vec2 o = (viewN.xy - viewGeoN.xy) * 0.02 + texelSize * 3.0;
            vec3 hitCol = (textureLod(colortex0, hit, 1.5).rgb
                         + textureLod(colortex0, hit + o, 1.5).rgb
                         + textureLod(colortex0, hit - o, 1.5).rgb) * (1.0 / 3.0);
            reflection = mix(reflection, hitCol, edge);
        }
    #endif
        reflection = applyFog(reflection, scenePos0, dir);
    }

    vec3 result = mix(bg, reflection, fresnel);

#if defined WORLD_OVERWORLD
    if (!underwater) {
        result += light * surfaceShadow * ggxSpecular(n, V, lightDir, 0.06) * (1.0 - rainStrength);
    }
#endif
    return result;
}

void main() {
    ivec2 px = ivec2(gl_FragCoord.xy);
    float depth0 = texelFetch(depthtex0, px, 0).r;
    float depth1 = texelFetch(depthtex1, px, 0).r;
    vec3 color = texelFetch(colortex0, px, 0).rgb;
    vec4 data = texelFetch(colortex3, px, 0);
    int material = int(round(data.b * 255.0));

    vec2 refractUv = texcoord;
    if (material == MAT_WATER && depth0 < depth1) {
        color = shadeWater(color, data, depth0, depth1, refractUv);
    } else if (material != MAT_NONE && depth0 < depth1) {
        // Glass / ice: a light Fresnel sky reflection on top of the forward-lit colour
        vec3 scenePos0 = viewToScene(screenToView(vec3(texcoord, depth0)));
        vec3 dir = normalize(scenePos0 - gbufferModelViewInverse[3].xyz);
        vec3 n = octDecode(data.rg);
        float f = fresnelSchlick(saturate(dot(n, -dir)), 0.04);
        color += renderSky(reflect(dir, n), false) * f * linstep(0.0, 0.6, data.a) * 0.6;
    }

    vec4 translucent = texelFetch(colortex2, px, 0);
    color = color * (1.0 - translucent.a) + translucent.rgb;

    // Fog for the camera's own medium
    float dist0 = length(screenToView(vec3(texcoord, depth0)));
    if (isEyeInWater == 1) {
        float open = linstep(0.15, 0.8, eyeSkylight);
        vec3 ambient = ambientColor() * eyeSkylight * eyeSkylight + getMinLight() * 5.0;
        vec3 waterFog = (ambient * 0.6 + lightColor() * 0.15 * open) * (WATER_SCATTERING / WATER_EXTINCTION);
        vec3 T = exp(-WATER_EXTINCTION * min(dist0, 256.0));
        color = color * T + waterFog * (1.0 - T);
    } else if (isEyeInWater == 2) {
        color = mix(color, vec3(2.0, 0.5, 0.08), 1.0 - exp(-dist0 * 1.2));
    } else if (isEyeInWater == 3) {
        color = mix(color, vec3(0.7, 0.8, 0.95) * ambientColor() * 0.5, 1.0 - exp(-dist0 * 1.0));
    }

#if defined VL || defined UW_VL
    color += textureLod(colortex7, texcoord, 0.0).rgb;
#endif

    color = applyStatusFog(color, dist0);
    outColor = vec4(max(color, 0.0), 1.0);
}

#endif
