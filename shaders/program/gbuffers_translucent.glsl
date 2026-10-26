// Translucent geometry. Water only marks itself (normal + material in
// colortex3); its look is built in composite1. Everything else is lit here
// and written premultiplied into colortex2.

#include "/include/common.glsl"
#include "/include/materials.glsl"
#include "/include/space.glsl"

#if defined PROGRAM_WATER
    #define WRITES_TRANSLUCENT_DATA
#endif
#if defined PROGRAM_EMISSIVE || defined PROGRAM_GLINT || defined PROGRAM_DAMAGE || defined PROGRAM_BEACON
    #define UNLIT
#endif

#if defined VERTEX_SHADER // ============================================

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 scenePos;
out vec3 worldNormal;
flat out int material;

in vec2 mc_Entity;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = saturate(gl_MultiTexCoord1.xy / 240.0);
    glcolor = gl_Color;
    worldNormal = mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);

#if defined PROGRAM_WATER
    material = clamp(int(mc_Entity.x + 0.5), 0, 255);
#else
    material = MAT_NONE;
#endif

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    scenePos = viewToScene(viewPos.xyz);
    gl_Position = gl_ProjectionMatrix * viewPos;
    gl_Position.xy += taaOffset() * gl_Position.w;
}

#else // FRAGMENT_SHADER ===============================================

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 scenePos;
in vec3 worldNormal;
flat in int material;

uniform sampler2D gtexture;

#if !defined UNLIT
#include "/include/sky.glsl"
#ifdef SHADOWS
#include "/include/shadow.glsl"
#endif
#include "/include/lighting.glsl"
#include "/include/fog.glsl"

vec3 forwardLighting(vec3 albedo, vec3 normal) {
    vec3 light = getSkyAmbient(normal, lmcoord.y)
               + getBlockLight(scenePos, normal, lmcoord.x)
               + getMinLight();
#ifdef SHADOWS
    float NdotL = saturate(dot(normal, lightDir));
    #if defined PROGRAM_PARTICLES || defined PROGRAM_WEATHER
        NdotL = 0.6;
    #endif
    if (NdotL > 0.0) {
        float shadow = getShadowFast(scenePos + normal * 0.05);
        light += lightColor() * NdotL * shadow * cloudShadow(scenePos + cameraPosition);
    }
#endif
    return albedo * light;
}
#endif

#if defined WRITES_TRANSLUCENT_DATA
/* RENDERTARGETS: 2,3 */
layout(location = 0) out vec4 outTranslucent;
layout(location = 1) out vec4 outData;
#else
/* RENDERTARGETS: 2 */
layout(location = 0) out vec4 outTranslucent;
#endif

void main() {
    vec4 albedo = texture(gtexture, texcoord) * glcolor;
    vec3 n = normalize(worldNormal);
    if (!gl_FrontFacing) n = -n;

#if defined PROGRAM_WATER
    if (material == MAT_WATER) {
        // Water is drawn entirely in composite1
        outTranslucent = vec4(0.0);
        outData = vec4(octEncode(n), float(MAT_WATER) / 255.0, lmcoord.y);
        return;
    }
#endif

    if (albedo.a < 0.01) discard;

#if defined PROGRAM_EMISSIVE
    // Spider/enderman eyes, lightning: additive glow
    outTranslucent = vec4(srgbToLinear(albedo.rgb) * albedo.a * 3.0 * EMISSION_STRENGTH, 0.0);
#elif defined PROGRAM_GLINT
    outTranslucent = vec4(srgbToLinear(albedo.rgb) * albedo.a * 0.8, 0.0);
#elif defined PROGRAM_DAMAGE
    // Block breaking cracks: darken what's below
    outTranslucent = vec4(0.0, 0.0, 0.0, saturate((1.0 - albedo.r) * albedo.a * 1.2));
#elif defined PROGRAM_BEACON
    outTranslucent = vec4(srgbToLinear(albedo.rgb) * albedo.a * 6.0 * EMISSION_STRENGTH, albedo.a);
#else
    vec3 lin = srgbToLinear(albedo.rgb);
    float alpha = albedo.a;
    #if defined PROGRAM_WEATHER
        alpha *= 0.5;
        n = vec3(0.0, 1.0, 0.0);
    #endif
    vec3 col = forwardLighting(lin, n) + getEmission(lin, material);
    vec3 dir = normalize(scenePos);
    col = applyFog(col, scenePos, dir);
    outTranslucent = vec4(col * alpha, alpha);
#endif

#if defined WRITES_TRANSLUCENT_DATA
    int mat = material == MAT_NONE ? MAT_GLASS : material;
    outData = vec4(octEncode(n), float(mat) / 255.0, lmcoord.y);
#endif
}

#endif
