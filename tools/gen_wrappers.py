"""Generates the thin per-dimension program wrappers in shaders/world*/."""
import os, shutil

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "shaders")

# program name -> (source in /program, extra defines, stages)
VF = ("vsh", "fsh")
PROGRAMS = {
    "gbuffers_terrain":               ("gbuffers_solid.glsl", ["PROGRAM_TERRAIN"], VF),
    "gbuffers_block":                 ("gbuffers_solid.glsl", ["PROGRAM_BLOCK"], VF),
    "gbuffers_entities":              ("gbuffers_solid.glsl", ["PROGRAM_ENTITIES"], VF),
    "gbuffers_hand":                  ("gbuffers_solid.glsl", ["PROGRAM_HAND"], VF),
    "gbuffers_textured":              ("gbuffers_solid.glsl", ["PROGRAM_TEXTURED"], VF),
    "gbuffers_textured_lit":          ("gbuffers_solid.glsl", ["PROGRAM_TEXTURED"], VF),
    "gbuffers_particles":             ("gbuffers_solid.glsl", ["PROGRAM_PARTICLES"], VF),
    "gbuffers_basic":                 ("gbuffers_solid.glsl", ["PROGRAM_BASIC"], VF),
    "gbuffers_line":                  ("gbuffers_solid.glsl", ["PROGRAM_LINE"], VF),
    "gbuffers_water":                 ("gbuffers_translucent.glsl", ["PROGRAM_WATER"], VF),
    "gbuffers_hand_water":            ("gbuffers_translucent.glsl", ["PROGRAM_HAND_WATER"], VF),
    "gbuffers_entities_translucent":  ("gbuffers_translucent.glsl", ["PROGRAM_ENTITIES_TRANSLUCENT"], VF),
    "gbuffers_block_translucent":     ("gbuffers_translucent.glsl", ["PROGRAM_BLOCK_TRANSLUCENT"], VF),
    "gbuffers_particles_translucent": ("gbuffers_translucent.glsl", ["PROGRAM_PARTICLES"], VF),
    "gbuffers_weather":               ("gbuffers_translucent.glsl", ["PROGRAM_WEATHER"], VF),
    "gbuffers_beaconbeam":            ("gbuffers_translucent.glsl", ["PROGRAM_BEACON"], VF),
    "gbuffers_spidereyes":            ("gbuffers_translucent.glsl", ["PROGRAM_EMISSIVE"], VF),
    "gbuffers_lightning":             ("gbuffers_translucent.glsl", ["PROGRAM_EMISSIVE"], VF),
    "gbuffers_armor_glint":           ("gbuffers_translucent.glsl", ["PROGRAM_GLINT"], VF),
    "gbuffers_damagedblock":          ("gbuffers_translucent.glsl", ["PROGRAM_DAMAGE"], VF),
    "gbuffers_skybasic":              ("gbuffers_discard.glsl", [], VF),
    "gbuffers_skytextured":           ("gbuffers_discard.glsl", [], VF),
    "gbuffers_clouds":                ("gbuffers_discard.glsl", [], VF),
    "shadow":                         ("shadow.glsl", ["PROGRAM_SHADOW"], VF),
    "shadowcomp":                     ("floodfill.glsl", ["PROGRAM_SHADOWCOMP"], ("csh",)),
    "prepare":                        ("sky_lut.glsl", [], VF),
    "deferred":                       ("ssao.glsl", [], VF),
    "deferred1":                      ("clouds.glsl", [], VF),
    "deferred2":                      ("clouds_temporal.glsl", [], VF),
    "deferred3":                      ("deferred_lighting.glsl", [], VF),
    "composite":                      ("volumetrics.glsl", [], VF),
    "composite1":                     ("translucent_composite.glsl", [], VF),
    "composite2":                     ("taa.glsl", [], VF),
    "composite3":                     ("bloom.glsl", [], VF),
    "final":                          ("final.glsl", [], VF),
}
WORLDS = {"world0": "WORLD_OVERWORLD", "world-1": "WORLD_NETHER", "world1": "WORLD_END"}
STAGE_DEFINE = {"vsh": "VERTEX_SHADER", "fsh": "FRAGMENT_SHADER", "csh": "COMPUTE_SHADER"}

for world, world_define in WORLDS.items():
    d = os.path.join(ROOT, world)
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    for name, (src, defines, stages) in PROGRAMS.items():
        for stage in stages:
            version = "#version 430" if stage == "csh" else "#version 430 compatibility"
            body = [version, f"#define {world_define}", f"#define {STAGE_DEFINE[stage]}"]
            body += [f"#define {x}" for x in defines]
            body.append(f'#include "/program/{src}"')
            with open(os.path.join(d, f"{name}.{stage}"), "w", newline="\n") as f:
                f.write("\n".join(body) + "\n")
print("wrappers written for", ", ".join(WORLDS))
