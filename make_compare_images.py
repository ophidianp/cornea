"""Crop comparison pairs past the Discord overlay and save near-lossless webp.
usage: mkcmp2.py <folder with 14 images in order: cornea1 photon1 cornea2 photon2 ...>"""
import os, sys
from PIL import Image
src = sys.argv[1]
files = sys.argv[2:] if len(sys.argv) > 2 else None
out = r"C:\Users\neman\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\scratch-workspaces\c350a62e-5935-41b2-aa6c-e8ce47a89901\bb9c45bc-df7d-4d3f-be13-bc6c22142123\scratch-2026-10-25-6a5390\Cornea-site\img"
names = files or [f"{n}.webp" for n in range(21, 35)]
for k in range(7):
    for which, name in (("cornea", names[2 * k]), ("photon", names[2 * k + 1])):
        im = Image.open(os.path.join(src, name)).convert("RGB")
        w, h = im.size
        x0 = round(w * 0.163)            # the overlay lives left of this
        cw = w - x0
        ch = round(cw * 9 / 16)
        y0 = max((h - ch) // 2, 0)
        im = im.crop((x0, y0, x0 + cw, min(y0 + ch, h)))
        p = os.path.join(out, f"cmp-{k + 1}-{which}.webp")
        im.save(p, "WEBP", quality=98, method=6)
        print(f"cmp-{k+1}-{which}", (w, h), "->", im.size, os.path.getsize(p) // 1024, "KB")
