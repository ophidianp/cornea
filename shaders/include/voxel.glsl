#if !defined VOXEL_GLSL
#define VOXEL_GLSL

// Voxel volume for coloured lights: a VOXEL_SIZE^3 grid centred on the block
// the camera is in. Voxel values (r8ui): 0 empty, 1 solid, else material ID.

#define VOXEL_EMPTY 0u
#define VOXEL_SOLID 1u
#define VOXEL_LEAVES 4u

vec3 sceneToVoxel(vec3 scenePos) {
    return scenePos + fract(cameraPosition) + float(VOXEL_SIZE / 2);
}

bool insideVoxelVolume(ivec3 p) {
    return all(greaterThanEqual(p, ivec3(0))) && all(lessThan(p, ivec3(VOXEL_SIZE)));
}

#endif
