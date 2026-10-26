// deferred3: main lighting for opaque surfaces, sky + clouds for sky pixels,
// and aerial fog.

#include "/include/common.glsl"

#if defined VERTEX_SHADER
#include "/include/fullscreen_vsh.glsl"
#else

#include "/include/space.glsl"
#include "/include/materials.glsl"
#include "/include/sky.glsl"
#ifdef SHADOWS
#include "/include/shadow.glsl"
#endif
#include "/include/lighting.glsl"
#include "/include/fog.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D colortex1;
uniform sampler2D colortex6;  // clouds
uniform sampler2D colortex10; // SSAO

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

vec4 getClouds() {
#ifdef CLOUDS
    return textureLod(colortex6, texcoord, 0.0);
#else
    return vec4(0.0, 0.0, 0.0, 1.0);
#endif
}

void main() {
    ivec2 px = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex0, px, 0).r;
    vec3 viewPos = screenToView(vec3(texcoord, depth));
    vec3 scenePos = viewToScene(viewPos);
    vec3 dir = normalize(scenePos - gbufferModelViewInverse[3].xyz);

    if (depth >= 1.0) {
        vec3 sky = renderSky(dir, true);
        vec4 clouds = getClouds();
        sky = sky * clouds.a + clouds.rgb;
        outColor = vec4(sky, 1.0);
        return;
    }

    GbufferData g = unpackGbuffer(texelFetch(colortex1, px, 0));
    vec3 worldPos = scenePos + cameraPosition;
    bool isHand = depth < MC_HAND_DEPTH;

    float ao = g.ao;
#ifdef SSAO
    if (!isHand) ao *= textureLod(colortex10, texcoord, 0.0).r;
#endif
    // Stronger occlusion underground so corners and edges read
    ao = mix(1.0, ao, mix(0.75, 1.0, caveFactor));
    ao = mix(ao, ao * ao, 0.5 * caveFactor);

    // Ambient: sky + block light + floor
    vec3 light = getSkyAmbient(g.normal, g.lightmap.y) * ao;
    // Torches and other lights: shade by the direction the light comes from
    // and let nearby geometry block it (short screen-space ray towards the
    // light, found from the flood-filled light volume)
    float torchShadow = 1.0;
#ifdef TORCH_SHADOWS
    if (!isHand && g.lightmap.x > 0.35 && length(scenePos) < 48.0) {
        vec3 toLight = blockLightGradient(scenePos + g.normal * 0.5);
        if (dot(toLight, toLight) > 0.5) {
            torchShadow = mix(0.88, 1.0, saturate(dot(g.normal, toLight) * 0.5 + 0.5));
            if (dot(toLight, g.normal) > 0.2) {
                vec3 dv = mat3(gbufferModelView) * toLight;
                vec3 startV = viewPos + mat3(gbufferModelView) * g.normal * 0.06;
                float rayDither = ignAnimated(gl_FragCoord.xy + 17.0);
                float occluded = 0.0;
                for (int i = 0; i < TORCH_SHADOW_STEPS; ++i) {
                    float t = 2.5 * (float(i) + rayDither + 0.5) / float(TORCH_SHADOW_STEPS);
                    vec3 sv = startV + dv * t;
                    if (sv.z > -near) break;
                    vec3 sp = viewToScreen(sv);
                    if (any(lessThan(sp.xy, vec2(0.0))) || any(greaterThan(sp.xy, vec2(1.0)))) break;
                    float sd = textureLod(depthtex0, sp.xy, 0.0).r;
                    float diff = screenToView(vec3(sp.xy, sd)).z - sv.z; // > 0: something in front of the ray
                    if (diff > 0.12 && diff < 0.5 + t * 0.25) { occluded = 1.0; break; }
                }
                torchShadow *= 1.0 - 0.8 * occluded;
            }
        }
    }
#endif
    light += getBlockLight(scenePos, g.normal, g.lightmap.x) * mix(1.0, ao, 0.7) * torchShadow;
    light += getMinLight() * ao;
    // Soft neutral fill light in caves, shaped by AO and a little by facing
    light += vec3(0.060, 0.062, 0.068) * MIN_LIGHT * caveFactor * (0.8 + 0.2 * g.normal.y) * ao;

    // Direct sun / moon
    vec3 sunVis = vec3(0.0);
#if defined WORLD_OVERWORLD || defined WORLD_END
    float diffuse = diffuseTerm(g.normal, dir, g.material);
    if (diffuse > 0.0) {
        vec3 shadow = vec3(1.0);
    #ifdef SHADOWS
        float dither = ignAnimated(gl_FragCoord.xy);
        float distFade = linstep(shadowDistance * 0.85, shadowDistance, length(scenePos));
        if (distFade < 1.0) {
            shadow = getShadow(scenePos, worldPos, g.normal, dither);
        }
        // Past the shadow map, fall back to the skylight level as a shadow
        float fakeShadow = linstep(0.75, 0.95, g.lightmap.y);
        shadow = mix(shadow, vec3(fakeShadow), distFade);
    #else
        shadow = vec3(linstep(0.75, 0.95, g.lightmap.y));
    #endif
        shadow *= cloudShadow(worldPos);
        sunVis = shadow;
        light += lightColor() * vec3(1.04, 1.0, 0.92) * diffuse * shadow * mix(1.0, ao, 0.3);
        // Warm bounce light from the sunlit surroundings, present in shadow too
        light += lightColor() * vec3(1.08, 1.0, 0.85) * (0.045 * g.lightmap.y * g.lightmap.y) * ao;
    }
#endif

    // Baked reflectivity
    vec3 f0;
    float rough, metallic;
    getSurfaceSpec(g.material, g.albedo, g.normal, worldPos, g.lightmap.y, f0, rough, metallic);
    vec3 diffuseAlbedo = g.albedo * (1.0 - 0.9 * metallic);
#ifdef EDGE_HIGHLIGHT
    if (!isHand) {
        // Convex block edges catch a little extra light: the neighbours
        // fall away on both sides and the surface normal turns
        float cz = -viewPos.z;
        vec2 dx = vec2(1.0, 0.0), dy = vec2(0.0, 1.0);
        float zl = -screenToView(vec3(texcoord - dx * texelSize, texelFetch(depthtex0, px - ivec2(1, 0), 0).r)).z;
        float zr = -screenToView(vec3(texcoord + dx * texelSize, texelFetch(depthtex0, px + ivec2(1, 0), 0).r)).z;
        float zu = -screenToView(vec3(texcoord + dy * texelSize, texelFetch(depthtex0, px + ivec2(0, 1), 0).r)).z;
        float zd = -screenToView(vec3(texcoord - dy * texelSize, texelFetch(depthtex0, px - ivec2(0, 1), 0).r)).z;
        float tol = 0.08 + 0.06 * cz;
        float lapX = (abs(zl - cz) < tol && abs(zr - cz) < tol) ? (zl + zr - 2.0 * cz) : 0.0;
        float lapY = (abs(zu - cz) < tol && abs(zd - cz) < tol) ? (zu + zd - 2.0 * cz) : 0.0;
        float lap = max(lapX, lapY);
        float convex = saturate(lap / (0.003 * cz + 0.004));
        float turn = 0.0;
        turn = max(turn, 1.0 - dot(g.normal, unpackGbuffer(texelFetch(colortex1, px - ivec2(1, 0), 0)).normal));
        turn = max(turn, 1.0 - dot(g.normal, unpackGbuffer(texelFetch(colortex1, px + ivec2(1, 0), 0)).normal));
        turn = max(turn, 1.0 - dot(g.normal, unpackGbuffer(texelFetch(colortex1, px + ivec2(0, 1), 0)).normal));
        turn = max(turn, 1.0 - dot(g.normal, unpackGbuffer(texelFetch(colortex1, px - ivec2(0, 1), 0)).normal));
        float edge = convex * smoothstep(0.25, 0.7, turn) * (1.0 - smoothstep(60.0, 120.0, cz));
        light *= 1.0 + edge * 0.45 * EDGE_STRENGTH;
    }
#endif
    vec3 color = diffuseAlbedo * light + getEmission(g.albedo, g.material);
    if (f0.x + f0.y + f0.z > 0.0 && !isHand) {
        vec3 V = -dir;
        vec3 specN = g.normal;
    #if defined RAIN_RIPPLES && defined WORLD_OVERWORLD
        if (rainStrength > 0.2 && g.normal.y > 0.9 && !isHardSurface(g.material) && rough < 0.4) {
            float pud = saturate((0.4 - rough) / 0.3);
            vec2 sl = rainRippleSlope(worldPos.xz);
            specN = normalize(specN + vec3(sl.x, 0.0, sl.y) * (0.35 * pud * rainStrength));
        }
    #endif
        float NdotV = saturate(dot(specN, V));
        vec3 R = reflect(dir, specN);
        R = normalize(mix(R, specN, rough * rough));
        float openSky = linstep(0.0, 0.7, g.lightmap.y);
        // Closed spaces reflect their own ambient light instead of the sky
        vec3 env = mix(ambientColor() * 0.5, renderSky(R, false), openSky);
        vec3 F = f0 + (max(vec3(1.0 - rough), f0) - f0) * pow5(1.0 - NdotV);
        color += env * F * mix(0.6, 1.0, metallic);
    #if defined WORLD_OVERWORLD || defined WORLD_END
        color += lightColor() * sunVis * specGGX(g.normal, V, lightDir, rough) * F * (1.0 - rainStrength);
    #endif
    }

    if (!isHand) {
        if (isEyeInWater == 0) color = applyFog(color, scenePos, dir);
        // Clouds in front of distant terrain
        vec4 clouds = getClouds();
        color = color * clouds.a + clouds.rgb;
    }

    outColor = vec4(color, 1.0);
}

#endif
