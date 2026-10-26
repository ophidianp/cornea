"""Scroll smoothness fixes, applied on top of page.html by build.py.

What made scrolling stutter, especially on phones:
  - the hero light demo redrew ~530 dots (9 shadow rays each) every frame, even offscreen or mid-scroll
  - two big blurred, animated background glows (filter: blur(90px)) repainted every frame
  - the headline gradient animated background-position on clipped text, repainting it forever
  - backdrop-filter blur on the sticky header and overlays recomputed on every scrolled frame
  - the scroll handler read layout (scrollHeight) on every scroll event
"""

PERF_CSS = """
/* smoother scrolling */
.aurora { filter: none; animation: none; will-change: auto; }
.aurora-a { background: radial-gradient(circle closest-side, var(--glow), transparent); width: 70vw; height: 70vw; }
.aurora-b { background: radial-gradient(circle closest-side, rgba(255, 184, 107, 0.16), transparent); width: 60vw; height: 60vw; }
.grad { animation: none; }
.marquee-track { will-change: transform; }
.cta::before { will-change: transform; }
@media (max-width: 860px), (hover: none) {
  .site-header, .hero-readout, .cmp-label, .site-nav { backdrop-filter: none !important; -webkit-backdrop-filter: none !important; }
  .site-header { background: color-mix(in srgb, var(--bg) 90%, transparent); }
  .hero-readout { background: var(--surface); }
  .reveal { animation: none !important; opacity: 1 !important; transform: none !important; }
  .cta::before { animation: none; }
  html { scroll-behavior: auto; }
}
"""

SCROLL_OLD_START = "  const onScroll = () => {"
SCROLL_NEW = """  let maxScroll = 0, ticking = false;
  const measure = () => { maxScroll = document.documentElement.scrollHeight - innerHeight; };
  const paint = () => {
    ticking = false;
    bar.style.setProperty("--progress", maxScroll > 0 ? Math.min(scrollY / maxScroll, 1) : 0);
    header.classList.toggle("is-scrolled", scrollY > 8);
  };
  const onScroll = () => { if (!ticking) { ticking = true; requestAnimationFrame(paint); } };
  addEventListener("scroll", onScroll, { passive: true });
  addEventListener("resize", () => { measure(); onScroll(); });
  addEventListener("load", () => { measure(); onScroll(); });
  measure(); onScroll();
"""


def apply(script):
    import re

    # scroll handler: no layout reads per event, painted once per frame
    i = script.index(SCROLL_OLD_START)
    j = script.index("addEventListener(\"scroll\", onScroll, { passive: true }); onScroll();", i)
    j += len("addEventListener(\"scroll\", onScroll, { passive: true }); onScroll();\n")
    script = script[:i] + SCROLL_NEW + script[j:]

    def sub(a, b):
        nonlocal script
        assert a in script, a[:60]
        script = script.replace(a, b, 1)

    # hero demo: lighter on phones, paused offscreen and while scrolling
    sub("  const N = 23;",
        "  const small = matchMedia(\"(max-width: 860px)\").matches || matchMedia(\"(hover: none)\").matches;\n  const N = small ? 15 : 23;")
    sub("dpr = Math.min(devicePixelRatio || 1, 2);", "dpr = Math.min(devicePixelRatio || 1, small ? 1.5 : 2);")
    sub("[0.7, -0.7], [-0.7, 0.7]];", "[0.7, -0.7], [-0.7, 0.7]].slice(0, small ? 5 : 9);")
    sub("  const frame = () => {\n    t += 1 / 60;",
        "  let skip = 0;\n  const frame = () => {\n    if (performance.now() < scrollingUntil || (small && (skip ^= 1))) { requestAnimationFrame(frame); return; }\n    t += (small ? 2 : 1) / 60;")
    sub("    if (!reduce) requestAnimationFrame(frame);\n  };\n  frame();",
        "    if (!reduce && visible) requestAnimationFrame(frame); else running = false;\n  };\n"
        "  let visible = true, running = true, scrollingUntil = 0;\n"
        "  addEventListener(\"scroll\", () => { scrollingUntil = performance.now() + 140; }, { passive: true });\n"
        "  new IntersectionObserver((e) => {\n    visible = e[0].isIntersecting;\n    if (visible && !running && !reduce) { running = true; requestAnimationFrame(frame); }\n  }).observe(stage);\n"
        "  frame();")
    return script
