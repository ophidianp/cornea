"""Draws icon.png (256x256) and icon-128.png from icon.svg: the website's icon, the "c" from
the Cornea wordmark in ink on a rounded teal tile (the same file as the site's favicon.svg).
icon.svg is a 32x32 tile: a <rect> with rounded corners and one <path> made of straight
segments (M/L/Z) placed with translate() scale(). Needs Pillow: python tools/make_icon.py"""
import os, re
from PIL import Image, ImageDraw

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.join(here, "..")
svg = open(os.path.join(root, "icon.svg"), encoding="utf-8").read()

rect = re.search(r'<rect[^>]*\brx="([\d.]+)"[^>]*\bfill="(#[0-9a-fA-F]{6})"', svg)
path = re.search(r'<path[^>]*\bfill="(#[0-9a-fA-F]{6})"[^>]*\btransform="translate\(([\d.\-]+) ([\d.\-]+)\) scale\(([\d.]+)\)"[^>]*\bd="([^"]+)"', svg)
radius, tile = float(rect.group(1)), rect.group(2)
ink, tx, ty, k, d = path.group(1), float(path.group(2)), float(path.group(3)), float(path.group(4)), path.group(5)
rings = [[tuple(map(float, p.split(","))) for p in re.findall(r"-?[\d.]+,-?[\d.]+", sub)] for sub in d.split("Z") if sub.strip()]


def render(size, ss=8):
    n = size * ss
    u = n / 32                                   # svg units -> supersampled pixels
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    dr.rounded_rectangle([0, 0, n - 1, n - 1], radius=radius * u, fill=tile)
    for i, ring in enumerate(rings):            # the mark has no holes; later rings would be cut-outs
        dr.polygon([((tx + x * k) * u, (ty + y * k) * u) for x, y in ring], fill=ink if i == 0 else tile)
    return img.resize((size, size), Image.LANCZOS)


for size, name in ((256, "icon.png"), (128, "icon-128.png")):
    p = os.path.normpath(os.path.join(root, name))
    render(size).save(p, optimize=True)
    print("wrote", p)
