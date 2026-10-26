// Player interaction: wave simulation for water ripples and a decaying dent
// for snow layers. One step per frame on a toroidal 256x256 grid that
// follows the camera; cells that change owner as you move are cleared.

#include "/include/common.glsl"

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const ivec3 workGroups = ivec3(16, 16, 1);

layout(rgba16f) uniform writeonly image2D interactImgA;
layout(rgba16f) uniform writeonly image2D interactImgB;
uniform sampler2D interactSamplerA;
uniform sampler2D interactSamplerB;
uniform usampler2D waterFlagSampler;

const float CELLS = 4.0;

ivec2 ownerCell(ivec2 t, ivec2 p) { return p + ((t - p + 128) & 255) - 128; }

vec4 fetchPrev(ivec2 t, bool fromA) {
    t &= 255;
    return fromA ? texelFetch(interactSamplerA, t, 0) : texelFetch(interactSamplerB, t, 0);
}

void main() {
    ivec2 t = ivec2(gl_GlobalInvocationID.xy);
    bool writeA = (frameCounter & 1) == 0;
    bool readA = !writeA;

    ivec2 p = ivec2(floor(cameraPosition.xz * CELLS));
    ivec2 pp = ivec2(floor(previousCameraPosition.xz * CELLS));
    ivec2 own = ownerCell(t, p);

    vec4 cur = vec4(0.0);
    float dt = clamp(frameTime, 0.004, 0.1);
    float dt60 = dt * 60.0;

    if (ownerCell(t, pp) == own) {
        cur = fetchPrev(t, readA);
        float hl = fetchPrev(t + ivec2(-1, 0), readA).r;
        float hr = fetchPrev(t + ivec2(1, 0), readA).r;
        float hd = fetchPrev(t + ivec2(0, -1), readA).r;
        float hu = fetchPrev(t + ivec2(0, 1), readA).r;
        float lap = (hl + hr + hd + hu) * 0.25 - cur.r;
        cur.g += lap * (0.012 * dt60 * dt60);
        cur.g *= exp(-dt * 1.0);
        cur.r += cur.g * dt60;
        cur.r *= exp(-dt * 0.5);
        cur.b = max(cur.b - dt / float(SNOW_RECOVERY), 0.0);
    }

    vec2 cellXZ = (vec2(own) + 0.5) / CELLS;
    vec3 feet = cameraPosition + relativeEyePosition - vec3(0.0, 1.62, 0.0);
    float d = length(cellXZ - feet.xz);

#ifdef SNOW_INTERACTION
    float s = smoothstep(0.65, 0.3, d);
    if (s > 0.0 && s >= cur.b) {
        cur.b = s;
        cur.a = feet.y;
    }
#endif

#ifdef WATER_RIPPLES
    // The water composite stamps the frame number when water is near the feet
    int flagFrame = int(texelFetch(waterFlagSampler, ivec2(0), 0).r);
    int age = frameCounter - flagFrame;
    if (age >= 0 && age <= 2) {
        vec2 move = (cameraPosition.xz - previousCameraPosition.xz) / dt;
        float speed = min(length(move), 8.0);
        float ring = smoothstep(0.7, 0.1, d);
        cur.g -= ring * (0.0004 + 0.0011 * speed) * dt60 * RIPPLE_STRENGTH;
    }
#endif

    cur.rg = clamp(cur.rg, vec2(-0.35), vec2(0.35));
    if (writeA) imageStore(interactImgA, t, cur);
    else        imageStore(interactImgB, t, cur);
}
