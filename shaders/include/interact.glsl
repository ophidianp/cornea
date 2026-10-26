#if !defined INTERACT_GLSL
#define INTERACT_GLSL

// Player interaction map: a 256x256 toroidal grid (4 cells per block) centred
// on the camera. rgba16f per cell:
//   r wave height   g wave velocity   b snow dent (1 = just stepped on)
//   a player feet height when the dent was made
// Written by shadowcomp1 (ping-pong A/B), read by terrain and water.

uniform sampler2D interactSamplerA;
uniform sampler2D interactSamplerB;

#define INTERACT_CELLS 4.0
#define INTERACT_RANGE 28.0

vec4 interactFetch(ivec2 c) {
    c &= 255;
    return (frameCounter & 1) == 0 ? texelFetch(interactSamplerA, c, 0)
                                   : texelFetch(interactSamplerB, c, 0);
}

vec4 interactSample(vec2 worldXZ) {
    vec2 g = worldXZ * INTERACT_CELLS - 0.5;
    ivec2 i = ivec2(floor(g));
    vec2 f = fract(g);
    return mix(mix(interactFetch(i), interactFetch(i + ivec2(1, 0)), f.x),
               mix(interactFetch(i + ivec2(0, 1)), interactFetch(i + ivec2(1, 1)), f.x), f.y);
}

bool interactInRange(vec2 worldXZ) {
    vec2 d = worldXZ - cameraPosition.xz;
    return dot(d, d) < INTERACT_RANGE * INTERACT_RANGE;
}

// How far (blocks) a snow-layer vertex sinks. heightAbove is its height above the block floor.
float snowDent(vec3 worldPos, float heightAbove) {
    if (heightAbove < 0.01 || !interactInRange(worldPos.xz)) return 0.0;
    vec4 t = interactSample(worldPos.xz);
    float baseY = worldPos.y - heightAbove;
    float near = step(-0.4, t.a - baseY) * step(t.a - baseY, 1.2);
    return min(t.b * near * 0.45 * heightAbove, 0.18);
}

// Extra tilt on the water normal from player-made ripples
vec2 rippleSlope(vec2 worldXZ) {
    if (!interactInRange(worldXZ)) return vec2(0.0);
    const float e = 0.25;
    float hl = interactSample(worldXZ - vec2(e, 0.0)).r;
    float hr = interactSample(worldXZ + vec2(e, 0.0)).r;
    float hd = interactSample(worldXZ - vec2(0.0, e)).r;
    float hu = interactSample(worldXZ + vec2(0.0, e)).r;
    return vec2(hl - hr, hd - hu) / (2.0 * e);
}

#endif
