"""Draws icon.png (256x256) and icon-128.png: a minimalist white eye on a
green-teal square, in the same flat style as the Sodium / Chlorine icons.
Pure Python, no dependencies."""
import math, os, struct, zlib

TOP = (64, 205, 170)      # gradient top
BOTTOM = (34, 166, 138)   # gradient bottom
IRIS = (36, 170, 142)     # same teal as the background around it
WHITE = (255, 255, 255)

def sdf_lens(x, y, a, b):
    # intersection of two circles through (+-a, 0) with height b
    R = (a * a + b * b) / (2 * b)
    d1 = math.hypot(x, y + (R - b)) - R
    d2 = math.hypot(x, y - (R - b)) - R
    return max(d1, d2)

def sdf_circle(x, y, r):
    return math.hypot(x, y) - r

def shade(u, v):
    """u, v in [-0.5, 0.5]; returns rgb floats."""
    t = v + 0.5
    bg = tuple(TOP[i] + (BOTTOM[i] - TOP[i]) * t for i in range(3))
    col = bg
    e = 0.003  # edge softness
    def cover(d): return max(0.0, min(1.0, 0.5 - d / (2 * e)))
    # eye
    c = cover(sdf_lens(u, v, 0.375, 0.215))
    col = tuple(col[i] + (WHITE[i] - col[i]) * c for i in range(3))
    # iris (cut-out in the background colour), clipped to the eye
    c2 = cover(sdf_circle(u, v, 0.150)) * c
    iris = tuple(IRIS[i] + (BOTTOM[i] - IRIS[i]) * 0.3 * (v + 0.5) for i in range(3))
    col = tuple(col[i] + (iris[i] - col[i]) * c2 for i in range(3))
    # pupil
    c3 = cover(sdf_circle(u, v, 0.062))
    col = tuple(col[i] + (WHITE[i] - col[i]) * c3 for i in range(3))
    return col

def render(size, ss=4):
    rows = []
    for py in range(size):
        row = bytearray([0])
        for px in range(size):
            r = g = b = 0.0
            for sy in range(ss):
                for sx in range(ss):
                    u = (px + (sx + 0.5) / ss) / size - 0.5
                    v = (py + (sy + 0.5) / ss) / size - 0.5
                    c = shade(u, v)
                    r += c[0]; g += c[1]; b += c[2]
            n = ss * ss
            row += bytes((round(r / n), round(g / n), round(b / n), 255))
        rows.append(bytes(row))
    return b"".join(rows)

def png(size, raw):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)) \
        + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")

here = os.path.dirname(os.path.abspath(__file__))
for size, name in ((256, "icon.png"), (128, "icon-128.png")):
    path = os.path.join(here, "..", name)
    open(path, "wb").write(png(size, render(size)))
    print("wrote", os.path.normpath(path))
