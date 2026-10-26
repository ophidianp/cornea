// Shadow pass: distorted shadow map, coloured/water flags in shadowcolor0,
// and (with coloured lights) voxelization of the terrain around the player.

#include "/include/common.glsl"
#include "/include/materials.glsl"
#include "/include/shadow_distort.glsl"

#if defined VERTEX_SHADER // ============================================

#include "/include/waving.glsl"

out vec2 texcoord;
out vec4 glcolor;
flat out int material;

in vec2 mc_Entity;
in vec2 mc_midTexCoord;
in vec3 at_midBlock;

uniform int renderStage;

#ifdef COLORED_LIGHTS
#include "/include/voxel.glsl"
layout(r8ui) uniform writeonly uimage3D voxelImg;
const float voxelDistance = 48.0;

void voxelize(vec3 scenePos) {
    bool terrain = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
                || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
                || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
                || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;
    if (!terrain) return;

    vec3 toCenter = at_midBlock / 64.0;
    ivec3 voxel = ivec3(floor(sceneToVoxel(scenePos + toCenter)));
    if (!insideVoxelVolume(voxel)) return;

    uint value = VOXEL_EMPTY;
    if (isEmitter(material) || isTintedGlass(material)) {
        value = uint(material);
    } else if (material == MAT_LEAVES) {
        value = VOXEL_LEAVES;
    } else if (material == MAT_NONE || isHardSurface(material)) {
        // Only full cubes block light: every vertex sits on a block corner
        if (all(greaterThan(abs(toCenter), vec3(0.49)))) value = VOXEL_SOLID;
    }
    if (value != VOXEL_EMPTY) imageStore(voxelImg, voxel, uvec4(value, 0u, 0u, 0u));
}
#endif

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    material = clamp(int(mc_Entity.x + 0.5), 0, 255);

    vec4 shadowView = gl_ModelViewMatrix * gl_Vertex;
    vec3 scenePos = (shadowModelViewInverse * shadowView).xyz;

#ifdef COLORED_LIGHTS
    voxelize(scenePos);
#endif

#if defined WORLD_OVERWORLD
    if (isFoliage(material)) {
        bool topVertex = texcoord.y < mc_midTexCoord.y;
        float skylight = saturate(gl_MultiTexCoord1.y / 240.0);
        scenePos += windOffset(scenePos + cameraPosition, material, topVertex, skylight);
        scenePos += playerPushOffset(scenePos, material, topVertex);
        shadowView = shadowModelView * vec4(scenePos, 1.0);
    }
#endif

    vec4 clip = gl_ProjectionMatrix * shadowView;
    gl_Position = vec4(distortShadowClip(clip.xyz), 1.0);
}

#else // FRAGMENT_SHADER ===============================================

in vec2 texcoord;
in vec4 glcolor;
flat in int material;

uniform sampler2D gtexture;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outShadowColor;

void main() {
    vec4 albedo = texture(gtexture, texcoord) * glcolor;

    if (material == MAT_WATER) {
        // a = 0 flags water so lookups can add absorption and caustics
        outShadowColor = vec4(1.0, 1.0, 1.0, 0.0);
        return;
    }
    if (albedo.a < 0.1) discard;

    if (material == MAT_GLASS || material == MAT_ICE || isTintedGlass(material)) {
        vec3 tint = mix(vec3(1.0), srgbToLinear(albedo.rgb), saturate(albedo.a * 1.4));
        outShadowColor = vec4(tint, 1.0);
    } else {
        outShadowColor = vec4(1.0);
    }
}

#endif
