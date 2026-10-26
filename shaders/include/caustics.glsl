#if !defined CAUSTICS_GLSL
#define CAUSTICS_GLSL

// Animated water caustics: two layers of moving Voronoi edges multiplied
// together give the bright, shifting web of lines seen on a sea floor.

float voronoiEdge(vec2 p, float t) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float f1 = 8.0, f2 = 8.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 cell = vec2(x, y);
            vec2 h = hash22(i + cell);
            vec2 o = 0.5 + 0.42 * sin(t + TAU * h);
            float d = dot(cell + o - f, cell + o - f);
            if (d < f1) { f2 = f1; f1 = d; }
            else if (d < f2) { f2 = d; }
        }
    }
    return sqrt(f2) - sqrt(f1);
}

// Returns a multiplier with mean around 1.0
float waterCaustics(vec3 worldPos, vec3 lightDirection) {
    float t = frameTimeCounter * 1.1;
    // Project along the light so the pattern sits on the floor, not on xz
    vec2 p = worldPos.xz - lightDirection.xz / max(lightDirection.y, 0.2) * worldPos.y;
    p *= 0.55;
    float a = voronoiEdge(p + vec2(t * 0.11, t * 0.07), t);
    float b = voronoiEdge(p * 1.37 + vec2(-t * 0.09, t * 0.13) + 13.7, -t * 1.13);
    float ca = exp(-a * 9.0);
    float cb = exp(-b * 9.0);
    float c = ca * 0.6 + cb * 0.6 + ca * cb * 1.5;
    return mix(1.0, 0.25 + c * 1.6, CAUSTICS_STRENGTH * 0.8);
}

#endif
