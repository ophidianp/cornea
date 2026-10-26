#if !defined BLOOM_TILES_GLSL
#define BLOOM_TILES_GLSL

// Bloom tile atlas in colortex9 (half-res buffer, uv in [0, 1]).
// Tile i holds the scene blurred at mip level i + 2.

#define BLOOM_TILE_COUNT 6

const vec2 bloomTileOffset[BLOOM_TILE_COUNT] = vec2[BLOOM_TILE_COUNT](
    vec2(0.00, 0.00), vec2(0.52, 0.00), vec2(0.79, 0.00),
    vec2(0.93, 0.00), vec2(0.52, 0.30), vec2(0.58, 0.30)
);
const float bloomTileSize[BLOOM_TILE_COUNT] = float[BLOOM_TILE_COUNT](
    0.5, 0.25, 0.125, 0.0625, 0.03125, 0.015625
);

#endif
