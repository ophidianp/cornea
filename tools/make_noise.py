"""Writes shaders/image/noise.png (256x256 RGBA).

R: white noise. G: R shifted by (37, 17) so one bilinear fetch gives two
adjacent z-slices of 3D value noise (see noise3 in common.glsl).
B, A: independent white noise.
"""
import random, struct, zlib, os, sys

N = 256
rng = random.Random(1337)
r = [[rng.randrange(256) for _ in range(N)] for _ in range(N)]
b = [[rng.randrange(256) for _ in range(N)] for _ in range(N)]
a = [[rng.randrange(256) for _ in range(N)] for _ in range(N)]

raw = bytearray()
for y in range(N):
    raw.append(0)
    for x in range(N):
        g = r[(y + 17) % N][(x + 37) % N]
        raw += bytes((r[y][x], g, b[y][x], a[y][x]))

def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)

png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0)) \
    + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "shaders", "image", "noise.png")
open(out, "wb").write(png)
print("wrote", os.path.normpath(out), len(png), "bytes")
