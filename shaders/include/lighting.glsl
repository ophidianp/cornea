#if !defined LIGHTING_GLSL
#define LIGHTING_GLSL

// Shared surface lighting used by the deferred pass and forward translucents.
// Needs: sky.glsl, materials.glsl, and (with SHADOWS) shadow.glsl.

#include "/include/clouds.glsl"

#ifdef COLORED_LIGHTS
uniform sampler3D lightSamplerA;
uniform sampler3D lightSamplerB;
#include "/include/voxel.glsl"

// Hue of the flood-filled light at a point, or vec4(0) outside the volume.
// .a is how much to trust it (fades out at the volume edge / in weak light).
vec4 coloredLightHue(vec3 scenePos, vec3 normal) {
    vec3 voxelPos = sceneToVoxel(scenePos + normal * 0.5);
    vec3 uvw = voxelPos / vec3(VOXEL_SIZE);
    if (any(lessThan(uvw, vec3(0.0))) || any(greaterThan(uvw, vec3(1.0)))) return vec4(0.0);
    // The floodfill writes A on even frames, B on odd frames
    vec3 light = (frameCounter & 1) == 0 ? textureLod(lightSamplerA, uvw, 0.0).rgb
                                         : textureLod(lightSamplerB, uvw, 0.0).rgb;
    float m = maxOf(light);
    if (m < 1e-4) return vec4(0.0);
    vec3 hue = light / m;
    vec3 edge = min(uvw, 1.0 - uvw) * float(VOXEL_SIZE);
    float fade = linstep(0.0, 6.0, min(edge.x, min(edge.y, edge.z)));
    return vec4(hue, fade * linstep(0.0, 0.02, m));
}

// Raw flood-filled block light colour/intensity at a point (rgb), for
// volumetric glow around torches, lava, etc.
vec3 sampleColoredLightRaw(vec3 scenePos) {
    vec3 uvw = sceneToVoxel(scenePos) / vec3(VOXEL_SIZE);
    if (any(lessThan(uvw, vec3(0.0))) || any(greaterThan(uvw, vec3(1.0)))) return vec3(0.0);
    vec3 light = (frameCounter & 1) == 0 ? textureLod(lightSamplerA, uvw, 0.0).rgb
                                         : textureLod(lightSamplerB, uvw, 0.0).rgb;
    vec3 edge = min(uvw, 1.0 - uvw) * float(VOXEL_SIZE);
    return light * linstep(0.0, 6.0, min(edge.x, min(edge.y, edge.z)));
}

// Unit vector (scene space) from a point towards the strongest nearby
// coloured light, or 0 if there is no clear direction. Uses the gradient of
// the log of the light volume, which points at the source however far away.
vec3 blockLightGradient(vec3 scenePos) {
    const vec3 W = vec3(0.30, 0.59, 0.11);
    const float o = 0.9;
    vec3 g;
    g.x = log2(dot(sampleColoredLightRaw(scenePos + vec3(o, 0.0, 0.0)), W) + 1e-3)
        - log2(dot(sampleColoredLightRaw(scenePos - vec3(o, 0.0, 0.0)), W) + 1e-3);
    g.y = log2(dot(sampleColoredLightRaw(scenePos + vec3(0.0, o, 0.0)), W) + 1e-3)
        - log2(dot(sampleColoredLightRaw(scenePos - vec3(0.0, o, 0.0)), W) + 1e-3);
    g.z = log2(dot(sampleColoredLightRaw(scenePos + vec3(0.0, 0.0, o)), W) + 1e-3)
        - log2(dot(sampleColoredLightRaw(scenePos - vec3(0.0, 0.0, o)), W) + 1e-3);
    float l = length(g);
    return l > 0.25 ? g / l : vec3(0.0);
}
#else
vec3 sampleColoredLightRaw(vec3 scenePos) { return vec3(0.0); }
vec3 blockLightGradient(vec3 scenePos) { return vec3(0.0); }
#endif

vec3 handLightColor(int itemId) {
    if (itemId >= MAT_EMITTER_FIRST && itemId <= MAT_EMITTER_LAST) {
        return emitterColor[itemId - MAT_EMITTER_FIRST].rgb;
    }
    return defaultBlocklightColor();
}

// Block light from the vanilla lightmap, coloured by the voxel floodfill
vec3 getBlockLight(vec3 scenePos, vec3 normal, float blocklight) {
    float bl = blocklight;
    vec3 color = defaultBlocklightColor();

#ifdef COLORED_LIGHTS
    vec4 hue = coloredLightHue(scenePos, normal);
    vec3 lpvColor = mix(vec3(luminance(hue.rgb)), hue.rgb, COLORED_LIGHT_SATURATION);
    color = mix(color, lpvColor * 1.15, hue.a);
#endif

    // Vanilla light falls off linearly; reshape to look like inverse square
    float intensity = pow(bl, 5.0) * 1.1 + bl * bl * 0.10;
    vec3 light = color * intensity;

#ifdef HANDHELD_LIGHT
    float dist = length(scenePos);
    float hl1 = max(float(heldBlockLightValue) - dist * 1.5, 0.0) / 15.0; // shorter reach than a placed torch
    float hl2 = max(float(heldBlockLightValue2) - dist * 1.5, 0.0) / 15.0;
    light += handLightColor(heldItemId) * (pow(hl1, 5.0) * 1.1 + hl1 * hl1 * 0.10) * 0.45;
    light += handLightColor(heldItemId2) * (pow(hl2, 5.0) * 1.1 + hl2 * hl2 * 0.10) * 0.45;
#endif

#if defined WORLD_NETHER
    light *= 0.75; // tighter pools of light, darker in between
#endif
    return light * (1.6 * BLOCKLIGHT_INTENSITY);
}

vec3 getEmission(vec3 albedo, int material) {
#ifdef EMISSIVE_ORES
    if (material == MAT_ORE) {
        // The ore specks are the saturated/bright texels; plain stone is grey
        vec3 srgb = linearToSrgb(albedo);
        float chroma = maxOf(srgb) - min(srgb.x, min(srgb.y, srgb.z));
        float mask = smoothstep(0.16, 0.38, chroma) * smoothstep(0.30, 0.55, maxOf(srgb));
        mask = max(mask, smoothstep(0.62, 0.85, luminance(srgb)));
        return albedo * mask * (2.6 * EMISSION_STRENGTH);
    }
#endif
    if (material == MAT_NETHER_PORTAL) return albedo * 2.0 * EMISSION_STRENGTH;
    if (!isEmitter(material)) return vec3(0.0);
    vec4 e = emitterColor[material - MAT_EMITTER_FIRST];
    vec3 srgb = linearToSrgb(albedo);
    float mask = e.a > 0.5 ? 1.0 : smoothstep(0.55, 0.85, maxOf(srgb));
    return albedo * mask * (4.0 * EMISSION_STRENGTH);
}

// Sky light reaching a surface (hemisphere approximation)
vec3 getSkyAmbient(vec3 normal, float skylight) {
    // Warmer, fuller fill than the raw sky dome so shadowed ground stays
    // readable and the overall tint isn't cold
    vec3 amb = ambientColor() * SKY_INTENSITY * 2.1 * vec3(1.2, 1.04, 0.82);
#if defined WORLD_OVERWORLD
    // Upward faces see the whole sky, downward ones only bounced light
    amb *= 0.65 + 0.35 * normal.y;
    amb *= skylight * skylight;
#endif
    return amb;
}

float getMinLight() {
    return 0.012 * MIN_LIGHT * (1.0 + 4.0 * nightVision);
}

// Sun/moon diffuse term including foliage subsurface scattering
float diffuseTerm(vec3 normal, vec3 viewDir, int material) {
    float NdotL = dot(normal, lightDir);
#ifdef SSS
    if (isFoliage(material)) {
        float back = pow(saturate(dot(viewDir, lightDir)), 6.0);
        return saturate(NdotL) * 0.55 + (0.30 + 0.05 * SSS_STRENGTH) + back * 0.6 * SSS_STRENGTH;
    }
#endif
    return saturate(NdotL);
}

// ----------------------------------------------------------------- Baked reflectivity
// Per-material specular without a resource pack: metals tint their own
// reflection, polished stone and gems get a clean glossy coat, and rain
// makes upward-facing ground reflective with patchy puddles.

float specFresnel(float cosTheta, float f0, float rough) {
    return f0 + (max(1.0 - rough, f0) - f0) * pow5(1.0 - saturate(cosTheta));
}

float specGGX(vec3 n, vec3 v, vec3 l, float rough) {
    vec3 h = normalize(l + v);
    float NdotH = saturate(dot(n, h));
    float NdotL = saturate(dot(n, l));
    float a2 = sqr(max(rough * rough, 0.002));
    float d = a2 / (PI * sqr(NdotH * NdotH * (a2 - 1.0) + 1.0));
    return d * NdotL * 0.25;
}

// Expanding rings from random raindrops, as a height-field slope
vec2 rainRippleSlope(vec2 p) {
    vec2 slope = vec2(0.0);
    for (int layer = 0; layer < 2; ++layer) {
        vec2 q = p * (layer == 0 ? 2.6 : 4.1) + float(layer) * 17.0;
        vec2 cell = floor(q);
        vec2 f = fract(q) - 0.5;
        float h = hash12(cell);
        vec2 off = (hash22(cell + 3.1) - 0.5) * 0.5;
        float t = fract(frameTimeCounter * (0.9 + 0.5 * h) + h * 7.0);
        vec2 v = f - off;
        float r = length(v);
        float ringR = t * 0.45;
        float w = exp(-sqr((r - ringR) * 14.0)) * (1.0 - t) * step(0.55, fract(h * 13.7) + 0.5 * rainStrength);
        slope += (v / max(r, 1e-3)) * w * cos((r - ringR) * 40.0);
    }
    return slope;
}

// Returns F0 (rgb) and roughness; F0 = 0 means "not reflective"
void getSurfaceSpec(int material, vec3 albedo, vec3 normal, vec3 worldPos, float skylight, out vec3 f0, out float rough, out float metallic) {
    f0 = vec3(0.0);
    rough = 1.0;
    metallic = 0.0;
#ifdef REFLECTIVE_BLOCKS
    if (material == MAT_METAL) {
        f0 = clamp(albedo * 1.6, vec3(0.2), vec3(1.0));
        rough = 0.30;
        metallic = 1.0;
    } else if (material == MAT_POLISHED) {
        f0 = vec3(0.05);
        rough = 0.22;
    } else if (material == MAT_GEM) {
        f0 = vec3(0.07);
        rough = 0.14;
    }
#endif
#if defined WET_SURFACES && defined WORLD_OVERWORLD
    float wet = wetness > 0.01 ? wetness * linstep(0.6, 0.95, skylight) * saturate(normal.y * 3.0 - 1.5) : 0.0;
#ifdef PUDDLES_LINGER
    // Puddles outlast the rain: the wet film goes first, then puddles shrink
    // from their edges and the deepest ones are the last to dry
    wet = max(wet, sqrt(wetness) * 0.6 * linstep(0.6, 0.95, skylight) * saturate(normal.y * 3.0 - 1.5));
#endif
    if (wet > 0.01 && !isFoliage(material) && f0.x == 0.0) {
        float pn = valueNoise(worldPos.xz * 0.4) * 0.65 + valueNoise(worldPos.xz * 1.3) * 0.35;
#ifdef PUDDLES_LINGER
        float wk = saturate(wetness * 1.6);
        float puddle = linstep(mix(0.62, 0.40, wk), mix(0.78, 0.65, wk), pn);
#else
        float puddle = linstep(0.40, 0.65, pn);
#endif
        float w = wet * (0.35 + 0.65 * puddle);
        f0 = vec3(0.03 + 0.03 * puddle) * saturate(w * 2.0);
        rough = mix(0.5, 0.06, puddle) * (1.0 - 0.5 * wet) + 0.02;
    }
#endif
}

#endif
