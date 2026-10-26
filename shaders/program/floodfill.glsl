// Coloured light floodfill: one propagation step per frame. Each voxel takes
// the average of itself and its 6 neighbours from last frame (shifted for
// camera movement), tinted by glass/leaves, blocked by solid cubes, plus its
// own emission. Ping-pongs between two volumes.

#include "/include/common.glsl"
#include "/include/materials.glsl"
#include "/include/voxel.glsl"

layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;
const ivec3 workGroups = ivec3(VOXEL_SIZE / 4, VOXEL_SIZE / 4, VOXEL_SIZE / 4);

layout(rgba16f) uniform writeonly image3D lightImgA;
layout(rgba16f) uniform writeonly image3D lightImgB;
uniform sampler3D lightSamplerA;
uniform sampler3D lightSamplerB;
uniform usampler3D voxelSampler;

vec3 fetchLight(ivec3 p, bool fromA) {
    if (!insideVoxelVolume(p)) return vec3(0.0);
    return fromA ? texelFetch(lightSamplerA, p, 0).rgb : texelFetch(lightSamplerB, p, 0).rgb;
}

void main() {
    ivec3 pos = ivec3(gl_GlobalInvocationID);
    if (!insideVoxelVolume(pos)) return;

    // Even frames write A and read B; odd frames the reverse
    bool writeA = (frameCounter & 1) == 0;
    bool readA = !writeA;

    uint voxel = texelFetch(voxelSampler, pos, 0).r;
    vec3 light = vec3(0.0);

    if (voxel != VOXEL_SOLID) {
        ivec3 prev = pos + ivec3(floor(cameraPosition) - floor(previousCameraPosition));
        vec3 sum = fetchLight(prev, readA)
                 + fetchLight(prev + ivec3(1, 0, 0), readA)
                 + fetchLight(prev - ivec3(1, 0, 0), readA)
                 + fetchLight(prev + ivec3(0, 1, 0), readA)
                 + fetchLight(prev - ivec3(0, 1, 0), readA)
                 + fetchLight(prev + ivec3(0, 0, 1), readA)
                 + fetchLight(prev - ivec3(0, 0, 1), readA);
        light = sum * (0.985 / 7.0);

        int id = int(voxel);
        if (voxel == VOXEL_LEAVES) {
            light *= 0.7;
        } else if (isTintedGlass(id)) {
            light *= glassTint[id - MAT_TINTED_FIRST];
        } else if (isEmitter(id)) {
            light += emitterColor[id - MAT_EMITTER_FIRST].rgb;
        }
    }

    if (writeA) imageStore(lightImgA, pos, vec4(light, 1.0));
    else        imageStore(lightImgB, pos, vec4(light, 1.0));
}
