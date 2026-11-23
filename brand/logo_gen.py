"""Cornea logo: "cornea" written as one connected piece with a flat, horizontal pen nib
(thick strokes on the climbs, hairlines on the turns), swept along smooth Bezier centrelines
and sheared forward. Same technique as the Mouse 33 wordmark (mouse33/brand/logo_gen.py):
nib W=5.6 x T=2.2, union, 44 degree skew. Writes the path data used by the site's logo,
favicon and images (see make_assets.py)."""
import sys, json, math
import numpy as np
from shapely.geometry import Polygon, MultiPolygon
from shapely.ops import unary_union
from shapely import affinity

H = 27.0
W_NIB, T_NIB = 5.6, 2.2
TOP, BOT = T_NIB / 2, H - T_NIB / 2
MID = H / 2


def bez(p0, p1, p2, p3, n=56):
    t = np.linspace(0, 1, n)[:, None]
    p0, p1, p2, p3 = map(np.array, (p0, p1, p2, p3))
    return (1-t)**3*p0 + 3*(1-t)**2*t*p1 + 3*(1-t)*t**2*p2 + t**3*p3


def hermite(nodes, k=0.42):
    """nodes: (x, y, tx, ty[, k_out]) -> cubic segments with those tangent directions.
    The handle length is k times the chord, so the curve stays smooth through each node."""
    segs = []
    for a, b in zip(nodes[:-1], nodes[1:]):
        (x0, y0, tx0, ty0), (x1, y1, tx1, ty1) = a[:4], b[:4]
        ka = a[4] if len(a) > 4 else k
        kb = b[5] if len(b) > 5 else (b[4] if len(b) > 4 else k)
        d = math.hypot(x1 - x0, y1 - y0)
        n0, n1 = math.hypot(tx0, ty0), math.hypot(tx1, ty1)
        segs.append(((x0, y0), (x0 + tx0/n0*d*ka, y0 + ty0/n0*d*ka),
                     (x1 - tx1/n1*d*kb, y1 - ty1/n1*d*kb), (x1, y1)))
    return segs


def stroke(curves, w=W_NIB, t=T_NIB):
    pts = np.vstack([bez(*c) for c in curves])
    nib = np.array([[-w/2, -t/2], [w/2, -t/2], [w/2, t/2], [-w/2, t/2]])
    return unary_union([Polygon(np.vstack([nib + a, nib + b])).convex_hull for a, b in zip(pts[:-1], pts[1:])])


def to_path(g, nd=2):
    out = []
    for p in (g.geoms if isinstance(g, MultiPolygon) else [g]):
        for ring in [p.exterior, *p.interiors]:
            c = list(ring.coords)[:-1]
            out.append("M" + " L".join(f"{x:.{nd}f},{y:.{nd}f}" for x, y in c) + "Z")
    return "".join(out)


R, D, U, L = (1, 0), (0, 1), (0, -1), (-1, 0)


def centrelines(mark_only=False, gap=2.4):
    """Unskewed centrelines (y down). Every letter sits on the full height and the letters are
    joined by hairlines along the baseline; the skew does the slant."""
    q = 3.4                                   # radius of the turns from the baseline into a stem
    # c: top terminal, round over the top, down the back, out along the baseline
    c = [(15.2, 6.4, -0.45, -1), (9.0, TOP, *L), (1.4, MID, *D), (8.6, BOT, *R)]
    if mark_only:
        return [hermite(c + [(16.5, BOT - 1.6, 1, -0.3)])]
    x = 18.4 + gap                            # o: from its bottom, anticlockwise round once
    o = [(x + 7.4, BOT, *R), (x + 15.0, MID, *U), (x + 7.4, TOP, *L), (x, MID, *D), (x + 7.4, BOT, *R)]
    xr = x + 19.6 + gap                       # r: along the baseline, up the stem, an arm off the top
    r_up = [(x + 7.4, BOT, *R), (xr - q, BOT, *R), (xr, BOT - q, *U), (xr, TOP + 3.4, *U)]
    arm = [(xr, TOP + 3.4, *U), (xr + 3.6, TOP, *R), (xr + 7.6, TOP + 2.6, 1, 0.9)]
    xn = xr + 11.2 + gap                      # n: back down the stem, along the baseline, up, over the arch, down
    n = [(xr, TOP + 3.4, *D), (xr, BOT - q, *D), (xr + q, BOT, *R), (xn - q, BOT, *R), (xn, BOT - q, *U),
         (xn, 8.0, *U), (xn + 5.6, TOP, *R), (xn + 11.2, 8.0, *D), (xn + 11.2, BOT - q, *D), (xn + 11.2 + q, BOT, *R)]
    xe = xn + 19.6 + gap                      # e: along the baseline, rise into a loop in the top half, round the bottom
    e = [(xn + 11.2 + q, BOT, *R), (xe - 3.0, BOT, *R), (xe + 10.6, 13.0, 1, -0.8), (xe + 13.0, 7.2, *U),
         (xe + 7.0, TOP, *L), (xe, MID + 0.6, *D), (xe + 6.8, BOT, *R)]
    xa = xe + 17.0 + gap                      # a: a bowl with a straight back, then the stem and a tail
    a = [(xe + 6.8, BOT, *R), (xa + 7.0, BOT, *R), (xa + 13.6, 12.0, 0.03, -1), (xa + 14.0, TOP, 0, -1, 0.3, 0.3)]
    bowl = [(xa + 14.0, TOP, -1, 0, 0.42), (xa + 7.0, TOP, *L), (xa, MID, *D), (xa + 7.0, BOT, *R)]
    leg = [(xa + 14.0, TOP, 0.0, 1), (xa + 14.0, BOT - q, 0, 1), (xa + 14.0 + q, BOT, *R), (xa + 21.0, BOT - 3.0, 1, -0.6)]
    return [hermite(c + o), hermite(r_up), hermite(arm), hermite(n), hermite(e), hermite(a), hermite(bowl), hermite(leg)]


def build(skew=44.0, mark_only=False, W=W_NIB, T=T_NIB):
    g = unary_union([stroke(c, W, T) for c in centrelines(mark_only)])
    g = affinity.skew(g, xs=-skew, origin=(0, H)).simplify(0.035)
    minx, miny, maxx, maxy = g.bounds
    g = affinity.translate(g, -minx, -miny)
    return g, (maxx - minx, maxy - miny)


if __name__ == "__main__":
    g, (w, h) = build()
    print(json.dumps({"w": round(w, 2), "h": round(h, 2), "parts": len(getattr(g, "geoms", [g])),
                      "holes": sum(len(p.interiors) for p in getattr(g, "geoms", [g]))}))
