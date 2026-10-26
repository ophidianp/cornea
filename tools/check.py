"""Offline compile check for every program in shaders/world*/ with glslang.

Expands Iris-style #include, injects the macros Iris would define, and
compiles each program under several settings permutations (defaults, the LOW
profile, everything off) so #ifdef branches are covered too.

usage: python -I tools/check.py [path/to/glslang.exe]
"""
import os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "shaders"))
GLSLANG = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.environ["TEMP"], "glslang_dl", "g", "bin", "glslang.exe")

IRIS_DEFINES = {
    "MC_VERSION": "260300", "IS_IRIS": "1", "MC_GL_VERSION": "460", "MC_GLSL_VERSION": "460",
    "MC_HAND_DEPTH": "0.125",
    "MC_RENDER_STAGE_NONE": "0", "MC_RENDER_STAGE_SKY": "1", "MC_RENDER_STAGE_SUNSET": "2",
    "MC_RENDER_STAGE_TERRAIN_SOLID": "8", "MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED": "9",
    "MC_RENDER_STAGE_TERRAIN_CUTOUT": "10", "MC_RENDER_STAGE_TERRAIN_TRANSLUCENT": "13",
}

TOGGLES_OFF_ALL = ["SHADOWS", "SHADOW_PCSS", "COLORED_SHADOWS", "SSAO", "HANDHELD_LIGHT", "SSS",
                   "COLORED_LIGHTS", "CLOUDS", "CLOUD_SHADOWS", "CIRRUS", "STARS", "VL", "BORDER_FOG",
                   "WATER_WAVES", "WATER_SSR", "CAUSTICS", "UW_VL", "REFRACTION", "TAA", "BLOOM",
                   "AUTO_EXPOSURE", "WAVING_PLANTS", "PLANT_INTERACTION", "ALTO_CLOUDS", "TORCH_SHADOWS", "AURORA", "END_BLACK_HOLE", "EMISSIVE_ORES", "PBR_NORMALS", "REFLECTIVE_BLOCKS", "WET_SURFACES"]
PERMUTATIONS = {
    "default": ({}, []),
    "low": ({"SHADOW_SAMPLES": "4", "CLOUD_STEPS": "8", "CLOUD_LIGHT_STEPS": "2", "VL_STEPS": "4", "VOXEL_SIZE": "64"},
            ["SHADOW_PCSS", "SSAO", "COLORED_LIGHTS", "CIRRUS", "WATER_SSR", "UW_VL"]),
    "all_off": ({}, TOGGLES_OFF_ALL),
    "ultra": ({"SHADOW_SAMPLES": "16", "CLOUD_STEPS": "24", "CLOUD_LIGHT_STEPS": "6", "VL_STEPS": "16",
               "VOXEL_SIZE": "128", "SSR_STEPS": "24"}, []),
}

def settings_source(values, disabled):
    src = open(os.path.join(ROOT, "settings.glsl")).read()
    for name, val in values.items():
        src, n = re.subn(rf"^#define {name} \S+", f"#define {name} {val}", src, flags=re.M)
        assert n == 1, name
    for name in disabled:
        src, n = re.subn(rf"^#define {name}\b", f"//#define {name}", src, flags=re.M)
        assert n == 1, name
    return src

INCLUDE_RE = re.compile(r'^\s*#include\s+"([^"]+)"', re.M)

def expand(path, settings, depth=0):
    if depth > 20:
        raise RuntimeError("include depth")
    rel = os.path.relpath(path, ROOT).replace("\\", "/")
    src = settings if rel == "settings.glsl" else open(path).read()
    def repl(m):
        inc = m.group(1)
        target = os.path.join(ROOT, inc.lstrip("/")) if inc.startswith("/") else os.path.join(os.path.dirname(path), inc)
        return expand(os.path.normpath(target), settings, depth + 1)
    return INCLUDE_RE.sub(repl, src)

def compile_one(path, settings, tmpdir):
    stage = {".vsh": "vert", ".fsh": "frag", ".csh": "comp"}[os.path.splitext(path)[1]]
    src = expand(path, settings)
    # Inject Iris macros right after #version
    lines = src.split("\n")
    defs = [f"#define {k} {v}" for k, v in IRIS_DEFINES.items()]
    src = "\n".join([lines[0]] + defs + lines[1:])
    out = os.path.join(tmpdir, "prog." + stage)
    open(out, "w").write(src)
    r = subprocess.run([GLSLANG, out], capture_output=True, text=True)
    text = (r.stdout + r.stderr).strip()
    errors = [l for l in text.splitlines() if "ERROR" in l]
    return r.returncode == 0 and not errors, text, src

def main():
    failures = 0
    total = 0
    with tempfile.TemporaryDirectory() as tmp:
        for perm, (values, disabled) in PERMUTATIONS.items():
            settings = settings_source(values, disabled)
            for world in ("world0", "world-1", "world1"):
                d = os.path.join(ROOT, world)
                for f in sorted(os.listdir(d)):
                    if not f.endswith((".vsh", ".fsh", ".csh")):
                        continue
                    total += 1
                    ok, text, src = compile_one(os.path.join(d, f), settings, tmp)
                    if not ok:
                        failures += 1
                        print(f"FAIL [{perm}] {world}/{f}")
                        shown = 0
                        for line in text.splitlines():
                            if "ERROR" in line and shown < 6:
                                m = re.search(r":(\d+):", line)
                                ctx = ""
                                if m:
                                    n = int(m.group(1))
                                    sl = src.split("\n")
                                    if 0 < n <= len(sl):
                                        ctx = "   >> " + sl[n - 1].strip()
                                print("   ", line.strip(), ctx)
                                shown += 1
    print(f"{total - failures}/{total} programs compiled")
    sys.exit(1 if failures else 0)

if __name__ == "__main__":
    main()
