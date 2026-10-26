#if !defined MATERIALS_GLSL
#define MATERIALS_GLSL

// Material IDs. These match block.properties / entity.properties and are stored
// in 8 bits in the gbuffer.

#define MAT_NONE         0
#define MAT_WATER        1
#define MAT_PLANT_SHORT  2   // bottom-anchored foliage, top vertices wave
#define MAT_PLANT_TALL   3   // vines, upper halves: all vertices wave
#define MAT_LEAVES       4
#define MAT_GLASS        5
#define MAT_ICE          6
#define MAT_HAND         7
#define MAT_ENTITY       8
#define MAT_NETHER_PORTAL 9
#define MAT_METAL        10  // iron/gold/copper blocks, anvils...
#define MAT_POLISHED     11  // polished stone, quartz, obsidian, glazed terracotta
#define MAT_GEM          12  // diamond/emerald/lapis/amethyst blocks
#define MAT_ORE          13  // ores: the coloured specks glow
#define MAT_SNOW         14  // snow layers, dent under the player
#define MAT_END_PORTAL   59  // end portal + gateway (block entities, drawn procedurally)

// 32..63: light emitters (index into emitterColor)
#define MAT_EMITTER_FIRST 32
#define MAT_EMITTER_LAST  63
// 64..80: stained glass (16 colours) + tinted glass
#define MAT_TINTED_FIRST  64
#define MAT_TINTED_LAST   80

bool isEmitter(int id) { return id >= MAT_EMITTER_FIRST && id <= MAT_EMITTER_LAST; }
bool isTintedGlass(int id) { return id >= MAT_TINTED_FIRST && id <= MAT_TINTED_LAST; }
bool isFoliage(int id) { return id >= MAT_PLANT_SHORT && id <= MAT_LEAVES; }
bool isHardSurface(int id) { return id == MAT_METAL || id == MAT_POLISHED || id == MAT_GEM || id == MAT_ORE; }

// Linear RGB colour of each emitter; .a = 1 when the whole surface glows,
// 0 when only the bright texels of the texture glow (torches, lanterns).
const vec4 emitterColor[32] = vec4[32](
    vec4(1.00, 0.52, 0.18, 0.0), // 32 torch / lantern
    vec4(0.20, 0.72, 1.00, 0.0), // 33 soul torch / lantern / fire
    vec4(1.00, 0.08, 0.02, 0.0), // 34 redstone torch / ore
    vec4(1.00, 0.36, 0.06, 1.0), // 35 lava
    vec4(1.00, 0.74, 0.38, 1.0), // 36 glowstone
    vec4(0.62, 0.90, 1.00, 1.0), // 37 sea lantern
    vec4(1.00, 0.92, 0.86, 0.0), // 38 end rod
    vec4(0.62, 0.30, 1.00, 0.0), // 39 amethyst
    vec4(1.00, 0.48, 0.20, 1.0), // 40 shroomlight
    vec4(1.00, 0.80, 0.38, 1.0), // 41 ochre froglight
    vec4(0.48, 1.00, 0.42, 1.0), // 42 verdant froglight
    vec4(1.00, 0.52, 0.88, 1.0), // 43 pearlescent froglight
    vec4(0.52, 0.90, 0.62, 0.0), // 44 glow lichen / glow berries
    vec4(0.58, 0.18, 1.00, 1.0), // 45 nether portal
    vec4(0.36, 1.00, 0.46, 0.0), // 46 copper torch / lantern
    vec4(1.00, 0.46, 0.12, 0.0), // 47 fire / campfire
    vec4(1.00, 0.22, 0.04, 0.0), // 48 magma block
    vec4(0.80, 0.94, 1.00, 1.0), // 49 beacon
    vec4(0.50, 0.16, 1.00, 0.0), // 50 crying obsidian
    vec4(1.00, 0.70, 0.40, 1.0), // 51 redstone lamp (lit)
    vec4(1.00, 0.56, 0.16, 0.0), // 52 jack o'lantern
    vec4(1.00, 0.50, 0.20, 0.0), // 53 lit furnace / smoker / blast furnace
    vec4(1.00, 0.60, 0.28, 0.0), // 54 candles
    vec4(0.40, 1.00, 0.70, 0.0), // 55 sea pickle
    vec4(0.62, 0.20, 1.00, 0.0), // 56 respawn anchor
    vec4(1.00, 0.84, 0.60, 1.0), // 57 copper bulb (lit)
    vec4(0.30, 0.80, 1.00, 0.0), // 58 conduit
    vec4(1.00, 0.30, 0.90, 1.0), // 59 end portal / gateway
    vec4(0.18, 0.82, 0.92, 0.0), // 60 sculk
    vec4(1.00, 0.70, 0.40, 0.0), // 61
    vec4(1.00, 0.70, 0.40, 0.0), // 62
    vec4(1.00, 0.70, 0.40, 0.0)  // 63
);

// Light transmitted through stained glass (64..79) and tinted glass (80)
const vec3 glassTint[17] = vec3[17](
    vec3(1.00, 1.00, 1.00), // white
    vec3(1.00, 0.55, 0.15), // orange
    vec3(0.90, 0.30, 0.90), // magenta
    vec3(0.45, 0.70, 1.00), // light blue
    vec3(1.00, 0.95, 0.20), // yellow
    vec3(0.55, 1.00, 0.20), // lime
    vec3(1.00, 0.55, 0.70), // pink
    vec3(0.35, 0.35, 0.35), // gray
    vec3(0.70, 0.70, 0.70), // light gray
    vec3(0.20, 0.70, 0.80), // cyan
    vec3(0.55, 0.25, 0.90), // purple
    vec3(0.20, 0.30, 1.00), // blue
    vec3(0.60, 0.40, 0.25), // brown
    vec3(0.35, 0.60, 0.15), // green
    vec3(1.00, 0.15, 0.15), // red
    vec3(0.12, 0.12, 0.12), // black
    vec3(0.10, 0.08, 0.12)  // tinted glass
);

vec3 defaultBlocklightColor() {
#if BLOCKLIGHT_TEMP == 0
    return vec3(1.00, 0.56, 0.24);
#elif BLOCKLIGHT_TEMP == 1
    return vec3(1.00, 0.68, 0.40);
#else
    return vec3(1.00, 0.80, 0.60);
#endif
}

// ----------------------------------------------------------------- Gbuffer
// colortex1 (RGBA16):
//   x: albedo.rg   y: albedo.b, material   z: octahedral normal
//   w: skylight (6 bits) | blocklight (5 bits) | vanilla AO (5 bits)

vec4 packGbuffer(vec3 albedoSrgb, int material, vec3 worldNormal, vec2 lightmap, float ao) {
    uint sky = uint(round(saturate(lightmap.y) * 63.0));
    uint blk = uint(round(saturate(lightmap.x) * 31.0));
    uint occ = uint(round(saturate(ao) * 31.0));
    float w = float(sky | (blk << 6u) | (occ << 11u)) / 65535.0;
    return vec4(
        pack2x8(albedoSrgb.rg),
        pack2x8(vec2(albedoSrgb.b, float(material) / 255.0)),
        pack2x8(octEncode(worldNormal)),
        w
    );
}

struct GbufferData {
    vec3 albedo;    // linear
    int material;
    vec3 normal;    // world space
    vec2 lightmap;  // x block, y sky
    float ao;
};

GbufferData unpackGbuffer(vec4 g) {
    GbufferData d;
    vec2 rg = unpack2x8(g.x);
    vec2 bm = unpack2x8(g.y);
    d.albedo = srgbToLinear(vec3(rg, bm.x));
    d.material = int(round(bm.y * 255.0));
    d.normal = octDecode(unpack2x8(g.z));
    uint w = uint(round(g.w * 65535.0));
    d.lightmap = vec2(float((w >> 6u) & 31u) / 31.0, float(w & 63u) / 63.0);
    d.ao = float((w >> 11u) & 31u) / 31.0;
    return d;
}

#endif
