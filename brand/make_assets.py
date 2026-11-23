"""Writes the Cornea logo files: brand/logo.svg (wordmark), and in the site root favicon.svg
(the c mark on an accent tile), apple-touch-icon.png and og.png, plus brand/logo.json with the
path data that sitekit.py inlines into every page. Run: python -I brand/make_assets.py"""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw, ImageFilter
from shapely.geometry import MultiPolygon
from logo_gen import build, to_path

HERE = os.path.dirname(os.path.abspath(__file__)); SITE = os.path.join(HERE, "..")
ACCENT, ACCENT_L, INK, NIGHT = "#3fe0c5", "#087f6d", "#0b0b09", "#0b0d0e"
word, (ww, wh) = build()
mark, (mw, mh) = build(mark_only=True)
D_WORD, D_MARK = to_path(word), to_path(mark)
pad = 0.6


def svg_word(fill=ACCENT):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{-pad} {-pad} {ww+2*pad:.2f} {wh+2*pad:.2f}">'
            f'<title>Cornea</title><path fill="{fill}" d="{D_WORD}"/></svg>\n')


def svg_icon():
    s = 21 / max(mw, mh); ox, oy = (32 - mw*s)/2, (32 - mh*s)/2
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="8" fill="{ACCENT}"/>'
            f'<path fill="{INK}" transform="translate({ox:.2f} {oy:.2f}) scale({s:.4f})" d="{D_MARK}"/></svg>\n')


def raster(g, scale, offset, img, color, hole):
    """draw shapely geometry into a PIL image (already supersampled)."""
    d = ImageDraw.Draw(img)
    for p in (g.geoms if isinstance(g, MultiPolygon) else [g]):
        d.polygon([(offset[0] + x*scale, offset[1] + y*scale) for x, y in p.exterior.coords], fill=color)
        for ring in p.interiors:
            d.polygon([(offset[0] + x*scale, offset[1] + y*scale) for x, y in ring.coords], fill=hole)


def touch_icon(n=180, ss=4):
    N = n*ss; img = Image.new("RGB", (N, N), ACCENT)
    s = N*0.6 / max(mw, mh)
    raster(mark, s, ((N - mw*s)/2, (N - mh*s)/2), img, INK, ACCENT)
    return img.resize((n, n), Image.LANCZOS)


def og(ss=2):
    W, H = 1200*ss, 630*ss
    shot = Image.open(os.path.join(SITE, "img", "cmp-2-cornea.webp")).convert("RGB")
    k = max(W / shot.width, H / shot.height)
    shot = shot.resize((int(shot.width*k) + 1, int(shot.height*k) + 1), Image.LANCZOS).crop((0, 0, W, H))
    # darken towards the left so the wordmark sits on near-black
    shade = Image.new("L", (W, H))
    sd = ImageDraw.Draw(shade)
    for x in range(W):
        t = min(1.0, x / (W*0.78))
        sd.line([(x, 0), (x, H)], fill=int(255 * (0.94 - 0.62*t*t)))
    img = Image.composite(Image.new("RGB", (W, H), NIGHT), shot, shade)
    s = 640*ss / ww
    oy = (H - wh*s) / 2 - 20*ss
    mask = Image.new("L", (W, H), 0); raster(word, s, (84*ss, oy), mask, 255, 0)
    glow = mask.filter(ImageFilter.GaussianBlur(26*ss)).point(lambda v: int(v * 0.45))
    img = Image.composite(Image.new("RGB", (W, H), ACCENT), img, glow)
    img = Image.composite(Image.new("RGB", (W, H), ACCENT), img, mask)
    d = ImageDraw.Draw(img)
    try:
        from PIL import ImageFont
        f = ImageFont.truetype("consola.ttf", 22*ss)
        d.text((92*ss, oy + wh*s + 44*ss), "IRIS SHADERPACK  ·  MINECRAFT 26.X", font=f, fill="#a7b1ad")
    except OSError:
        pass
    return img.resize((1200, 630), Image.LANCZOS)


if __name__ == "__main__":
    n = len(getattr(word, "geoms", [word]))
    assert n == 1, f"wordmark is {n} pieces, expected one"
    open(os.path.join(HERE, "logo.svg"), "w").write(svg_word())
    open(os.path.join(HERE, "logo-light.svg"), "w").write(svg_word(ACCENT_L))
    open(os.path.join(SITE, "favicon.svg"), "w").write(svg_icon())
    touch_icon().save(os.path.join(SITE, "apple-touch-icon.png"))
    og().save(os.path.join(SITE, "og.png"), optimize=True)
    json.dump({"word": D_WORD, "w": round(ww+2*pad, 2), "h": round(wh+2*pad, 2), "pad": pad, "mark": D_MARK},
              open(os.path.join(HERE, "logo.json"), "w"))
    print("word", round(ww, 2), round(wh, 2), len(D_WORD), "chars, holes",
          sum(len(p.interiors) for p in getattr(word, "geoms", [word])), "; mark", round(mw, 2), round(mh, 2))
