#if !defined FOG_GLSL
#define FOG_GLSL

// Distance/height fog tinted by the sky, grey haze underground, and the
// border fog that hides the edge of the loaded chunks. Needs sky.glsl.

float fogDensityAt(float worldY) {
#if defined WORLD_OVERWORLD
    // Thicker in the morning and in rain, thins out with altitude
    float morning = linstep(0.25, 0.0, abs(sunDir.y - 0.12)) * (1.0 - caveFactor);
    float base = 0.00045 + 0.0020 * morning + 0.006 * rainStrength;
    return base * exp(-max(worldY - 63.0, 0.0) / 60.0) * FOG_DENSITY;
#elif defined WORLD_NETHER
    return 0.012 * FOG_DENSITY;
#else
    return 0.004 * FOG_DENSITY;
#endif
}

// Colour of the distant haze in a direction: the sky just above the horizon,
// lifted towards the horizon average so it reads light rather than dark
vec3 hazeColor(vec3 dir) {
#if defined WORLD_OVERWORLD
    vec3 c = skyLut(normalize(vec3(dir.x, max(dir.y, 0.0) * 0.5 + 0.03, dir.z)));
    c = skyDisplay(mix(c, horizonColor(), 0.35));
    return mix(c, vec3(luminance(c)) * 0.85, rainStrength * 0.5);
#else
    return horizonColor();
#endif
}

// Underground haze: neutral grey that follows the minimum light level
vec3 caveFogColor() {
    return vec3(0.0030, 0.0032, 0.0036) * (0.4 + MIN_LIGHT);
}

// Applies aerial fog to a surface at scenePos (camera-relative)
vec3 applyFog(vec3 color, vec3 scenePos, vec3 dir) {
    float dist = length(scenePos);
    float midY = cameraPosition.y + scenePos.y * 0.5;

#if defined WORLD_OVERWORLD
    float outside = 1.0 - caveFactor;
    float fogAmount = 1.0 - exp(-dist * fogDensityAt(midY));
    color = mix(color, hazeColor(dir), fogAmount * outside);

    // Grey fog in caves
    float caveAmount = (1.0 - exp(-dist * 0.006)) * 0.12 * caveFactor;
    color = mix(color, caveFogColor(), caveAmount);
#else
    float fogAmount = 1.0 - exp(-dist * fogDensityAt(midY));
    color = mix(color, horizonColor(), fogAmount);
#endif

#ifdef BORDER_FOG
    // Fade terrain smoothly into the haze well before the render distance so
    // the jagged edge of the loaded chunks never shows
    float border = smoothstep(far * 0.62, far * 0.95, length(scenePos.xz));
    #if defined WORLD_OVERWORLD
    vec3 borderCol = mix(renderSky(dir, false), hazeColor(dir), 0.5);
    borderCol = mix(borderCol, caveFogColor(), caveFactor);
    #else
    vec3 borderCol = horizonColor();
    #endif
    color = mix(color, borderCol, border);
#endif
    return color;
}

// Blindness / darkness effects pull everything to black
vec3 applyStatusFog(vec3 color, float dist) {
    float k = max(blindness, darknessFactor);
    if (k > 0.0) color *= exp(-dist * 0.25 * k);
    return color;
}

#endif
