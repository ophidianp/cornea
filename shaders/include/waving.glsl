#if !defined WAVING_GLSL
#define WAVING_GLSL

// Wind animation for foliage, shared by gbuffers and the shadow pass so the
// shadows move with the plants.

vec3 windOffset(vec3 worldPos, int material, bool topVertex, float skylight) {
#ifdef WAVING_PLANTS
    float amount;
    if (material == MAT_PLANT_SHORT) amount = topVertex ? 1.0 : 0.0;
    else if (material == MAT_PLANT_TALL) amount = 1.0;
    else if (material == MAT_LEAVES) amount = 0.45;
    else return vec3(0.0);

    float t = frameTimeCounter * WAVING_SPEED;
    vec2 w = vec2(
        sin(t * 1.7 + worldPos.x * 0.6 + worldPos.z * 0.3),
        cos(t * 1.3 + worldPos.z * 0.7 - worldPos.x * 0.2)
    );
    w += 0.35 * sin(t * 3.9 + dot(worldPos, vec3(1.9, 1.1, 2.3)));
    float strength = 0.055 * (1.0 + 1.5 * rainStrength) * smoothstep(0.3, 0.9, skylight);
    return vec3(w.x, 0.0, w.y) * (amount * strength);
#else
    return vec3(0.0);
#endif
}

// Plants bend away from the player's legs. scenePos is camera-relative, so
// the feet are ~1.62 blocks below the origin (first person).
vec3 playerPushOffset(vec3 scenePos, int material, bool topVertex) {
#ifdef PLANT_INTERACTION
    float amount;
    if (material == MAT_PLANT_SHORT) amount = topVertex ? 1.0 : 0.0;
    else if (material == MAT_PLANT_TALL) amount = 0.7;
    else return vec3(0.0);

    vec3 fromFeet = scenePos - vec3(0.0, -1.62, 0.0);
    if (fromFeet.y < -0.5 || fromFeet.y > 2.2) return vec3(0.0);
    float d = length(fromFeet.xz);
    const float radius = 1.3;
    if (d > radius || d < 1e-3) return vec3(0.0);
    float push = sqr(1.0 - d / radius) * amount;
    vec2 away = fromFeet.xz / d;
    // Bend outwards and a little down so the stem looks flattened
    return vec3(away.x * 0.55, -0.28, away.y * 0.55) * push;
#else
    return vec3(0.0);
#endif
}

#endif
