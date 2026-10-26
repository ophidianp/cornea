// Opaque geometry: terrain, entities, block entities, hand, particles, lines.
// Writes the packed gbuffer; all lighting happens in the deferred pass.

#include "/include/common.glsl"
#include "/include/materials.glsl"
#include "/include/space.glsl"

#if defined VERTEX_SHADER // ============================================

#include "/include/waving.glsl"
#if defined PROGRAM_TERRAIN && defined SNOW_INTERACTION
#include "/include/interact.glsl"
#endif

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 worldNormal;
out vec3 scenePosV;
flat out int material;

in vec2 mc_Entity;
in vec2 mc_midTexCoord;
in vec3 at_midBlock;
#if defined PROGRAM_BLOCK
uniform int blockEntityId;
#endif

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = saturate(gl_MultiTexCoord1.xy / 240.0);
    glcolor = gl_Color;
    worldNormal = mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);

#if defined PROGRAM_TERRAIN
    material = clamp(int(mc_Entity.x + 0.5), 0, 255);
#elif defined PROGRAM_BLOCK
    material = clamp(blockEntityId, 0, 255);
#elif defined PROGRAM_HAND
    material = MAT_HAND;
#elif defined PROGRAM_ENTITIES
    material = MAT_ENTITY;
#else
    material = MAT_NONE;
#endif

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;

#if defined PROGRAM_TERRAIN && defined SNOW_INTERACTION
    if (material == MAT_SNOW) {
        vec3 scenePos = viewToScene(viewPos.xyz);
        float heightAbove = 0.5 - at_midBlock.y / 64.0;
        scenePos.y -= snowDent(scenePos + cameraPosition, heightAbove);
        viewPos.xyz = sceneToView(scenePos);
    }
#endif
#if defined PROGRAM_TERRAIN
    if (isFoliage(material)) {
        vec3 scenePos = viewToScene(viewPos.xyz);
        bool topVertex = texcoord.y < mc_midTexCoord.y;
        scenePos += windOffset(scenePos + cameraPosition, material, topVertex, lmcoord.y);
        scenePos += playerPushOffset(scenePos, material, topVertex);
        viewPos.xyz = sceneToView(scenePos);
    }
#endif

    scenePosV = viewToScene(viewPos.xyz);
    gl_Position = gl_ProjectionMatrix * viewPos;
    gl_Position.xy += taaOffset() * gl_Position.w;
}

#else // FRAGMENT_SHADER ===============================================

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 worldNormal;
in vec3 scenePosV;
flat in int material;

uniform sampler2D gtexture;

#if defined PROGRAM_BLOCK
// End portal: layers of drifting stars at increasing apparent depth below the
// surface. Each layer is offset along the view ray, which gives real parallax
// as you move (the vanilla texture just scrolls).
vec3 drawEndPortal(vec3 worldPos, vec3 worldDir, vec3 n) {
    const int layers = 8;
    const float layerDepth = 0.33;  // apparent gap between layers, in blocks
    const float threshold = 0.985;  // lower = more stars
    const vec3 c0 = vec3(0.60, 0.79, 0.98);
    const vec3 c1 = vec3(0.52, 0.13, 0.86);
    const vec3 c2 = vec3(0.03, 0.45, 0.80);

    vec2 tp, td;
    if (abs(n.x) > 0.5) {
        tp = worldPos.yz; td = worldDir.yz / max(abs(worldDir.x), 1e-3);
    } else if (abs(n.y) > 0.5) {
        tp = worldPos.xz; td = worldDir.xz / max(abs(worldDir.y), 1e-3);
    } else {
        tp = worldPos.xy; td = worldDir.xy / max(abs(worldDir.z), 1e-3);
    }

    vec3 result = vec3(0.004, 0.012, 0.016);
    for (int i = 0; i < layers; ++i) {
        float fi = float(i);
        vec2 offset = hash22(vec2(fi, 7.0)) * 512.0;
        float ang = fi * 2.39996;
        vec2 drift = 0.03 * vec2(cos(ang), sin(ang)) * frameTimeCounter * (0.4 + 0.6 * hash12(vec2(fi, 3.0)));
        vec2 p = tp + td * (fi * layerDepth + 0.1) + drift;

        vec2 cell = floor(p * 32.0 + offset);
        float h = hash12(cell);
        h *= 1.0 - 0.04 * cos(frameTimeCounter * 0.4 + TAU * hash12(cell + 3.3));
        float s = linstep(threshold, 1.0, h);
        float intensity = s * s * s;

        vec3 col = mix(c0, c1, hash12(cell + 1.7));
        col = mix(col, c2, hash12(cell + 9.1));
        float fade = exp(-fi * 0.35);

        // A faint swirl of colour in the deeper layers
        float swirl = valueNoise(p * 1.7 + fi * 5.0) * valueNoise(p * 0.6 - fi * 3.0);
        result += col * (intensity * 1.6 + swirl * 0.02 * (fi / float(layers))) * fade;
    }
    return result;
}
#endif

/* RENDERTARGETS: 1 */
layout(location = 0) out vec4 outGbuffer;

void main() {
#if defined PROGRAM_BASIC || defined PROGRAM_LINE
    vec4 albedo = glcolor;
#else
    vec4 albedo = texture(gtexture, texcoord);
#endif
#if defined PROGRAM_BLOCK
    if (material == MAT_END_PORTAL) albedo.a = 1.0;
#endif
    if (albedo.a < 0.1) discard;

    float ao = 1.0;
#if defined PROGRAM_TERRAIN
    // separateAo: gl_Color.a carries vanilla AO, rgb the biome tint
    albedo.rgb *= glcolor.rgb;
    ao = glcolor.a < 0.1 ? 1.0 : glcolor.a;
    if (material == MAT_LEAVES) ao = mix(ao, 1.0, 0.6);
#elif !defined PROGRAM_BASIC && !defined PROGRAM_LINE
    albedo *= glcolor;
#endif

#if defined PROGRAM_ENTITIES
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#endif
#if defined PROGRAM_BLOCK
    if (material == MAT_END_PORTAL) {
        vec3 portalDir = normalize(scenePosV - gbufferModelViewInverse[3].xyz);
        albedo.rgb = linearToSrgb(drawEndPortal(scenePosV + cameraPosition, portalDir, normalize(worldNormal)));
    }
#endif
#if defined PROGRAM_LINE
    albedo.rgb = vec3(0.0);
#endif

    vec3 n = normalize(worldNormal);
#if defined PBR_NORMALS && (defined PROGRAM_TERRAIN || defined PROGRAM_BLOCK)
    // Baked normals: treat the texture's brightness as a height field and
    // tilt the normal by its screen-space gradient (no normal map needed).
    // Skipped for foliage (flat quads) and faded out with distance.
    if (!isFoliage(material) && material != MAT_END_PORTAL) {
        float dist2 = dot(scenePosV, scenePosV);
        if (dist2 < 900.0) { // within 30 blocks
            float fade = 1.0 - dist2 * (1.0 / 900.0);
            float height = (albedo.g + albedo.r * 0.5) * (0.0075 * NORMAL_STRENGTH);
            vec3 dpx = dFdx(scenePosV);
            vec3 dpy = dFdy(scenePosV);
            vec3 r1 = cross(dpy, n);
            vec3 r2 = cross(n, dpx);
            float det = dot(dpx, r1);
            vec3 grad = sign(det) * (dFdx(height) * r1 + dFdy(height) * r2);
            // Never tilt more than ~50 degrees, however close the surface is
            grad *= min(1.0, 1.2 * abs(det) / max(length(grad), 1e-12));
            vec3 bumped = abs(det) * n - grad;
            n = normalize(mix(n, normalize(bumped), fade * 0.9));
        }
    }
#endif
#if defined PROGRAM_PARTICLES
    // Particles are camera-facing quads; light them as if facing up
    n = vec3(0.0, 1.0, 0.0);
#endif

    outGbuffer = packGbuffer(albedo.rgb, material, n, lmcoord, ao);
}

#endif
