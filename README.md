# Cornea Shaders

A Photon-inspired Iris shaderpack built to run fast on mid/low-end GPUs
(target: RX 6500 XT, 1080p, 100–120 fps on the Ultra profile).

Made entirely with AI (Claude Opus 5.5 and Sonnet 5.5), steered and tested by
one person. The code was written fresh and no Photon file is included, but
Photon's source was read as a reference while building it, so the two share
ideas and some structure. Photon is by SixthSurge and is the look this pack
chases; Cornea is not affiliated with it. Details and the full chat log are on
the website (the `website` branch).

## Install
Click the green code button on the top right, then select download as a `.zip` file, or just download from the website.
Then drop `Cornea Shaders.zip` into your instance's `shaderpacks` folder and pick it
in Iris (Video Settings → Shader Packs). Requires Iris 1.7+ (tested to compile
for Iris 1.11 / MC 26.x).

## Features
- Physically based sky (Rayleigh/Mie/ozone) baked into a tiny LUT every frame
- Volumetric cumulus clouds (half-res + temporal accumulation) and cirrus
- Cloud shadows
- Soft shadows (PCSS-lite: 4-tap blocker search that skips filtering when
  nothing is in the way), coloured shadows through stained glass
- Coloured block lights via a voxel floodfill computed on the GPU
- Godrays (half-res volumetric light through height fog)
- Underwater godrays + animated caustics on the sea floor
- Water: wave normals, refraction, absorption, screen-space + sky reflections,
  sun glint
- SSAO (half-res), foliage subsurface scattering, waving plants
- TAA, single-pass bloom, auto exposure, ACES tonemap, sharpening
- Profiles: Low / Medium (default) / High / Ultra

## Pipeline (8 screen passes + shadow)
| Pass | What | Resolution |
|---|---|---|
| shadow / shadowcomp | shadow map, voxelization, light floodfill | 2048² / 96³ |
| prepare | sky LUT + light colours | 193×108 |
| deferred | SSAO | ½ |
| deferred1 / 2 | clouds + temporal accumulation | ½ |
| deferred3 | lighting, sky, fog | full |
| composite | godrays | ½ |
| composite1 | water, translucents, underwater fog | full |
| composite2 | TAA | full |
| composite3 | bloom atlas + exposure | ½ |
| final | tonemap, grade | full |

## Development
- `tools/gen_wrappers.py` regenerates `shaders/world*/` program wrappers.
- `tools/check.py [glslang.exe]` compile-checks every program in 4 settings
  permutations with glslang.
- `tools/make_noise.py` regenerates `shaders/image/noise.png`.

## Status
Compiles cleanly for all programs and setting presets. **Not yet tested
in-game**, so expect brightness and colour tuning to be needed.
