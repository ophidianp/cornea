"""Builds the multi-page Cornea site from page.html (the shared source).

page.html holds the styles, every section and the script once. This splits it
into real pages:

  index.html     hero, marquee, links to the other pages, download
  features.html  what it looks like, Cornea vs Photon slider, gallery, how it stays fast, what it works with
  install.html   install steps, FAQ, download
  transparency.html  made 100% with AI, Photon, and the chat log (chat-log.json from make_chatlog.py)
  404.html       "not found" page (host it at the site root)

Set SITE_BASE (e.g. SITE_BASE=/cornea/) if the site lives in a sub-folder, so
404.html can find its images and links from any missing URL.
"""
import os
import re

here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, "page.html"), encoding="utf-8").read()
site_base = os.environ.get("SITE_BASE", "")


def read(name):
    return open(os.path.join(here, name), encoding="utf-8").read()


def between(start, end, text=src, include_end=False):
    i = text.index(start)
    j = text.index(end, i)
    return text[i:j + (len(end) if include_end else 0)]


def drop_head(section):
    """Remove the section's own heading block (the page head replaces it)."""
    return re.sub(r'<div class="section-head reveal">.*?</p>\n      </div>\n', "", section, count=1, flags=re.S)


def first_section(section):
    return section.replace(' style="padding-top: 0"', "", 1)


# ---------------------------------------------------------------- slices of the source
style_end = src.index("</style>") + len("</style>")
head_src = src[:style_end]
chrome_top = between('<div class="backdrop"', '<main id="top">')
script = between("<script>", "</script>", include_end=True)

hero = between('<section class="hero"', "</section>", include_end=True)
marquee = between('<div class="marquee"', '  <div class="wrap">\n    <section class="section" id="features"')
marquee = marquee.rstrip()
features = between('<section class="section" id="features"', "</section>", include_end=True)
compare = between('<section class="section" id="compare"', "</section>", include_end=True)
inside = between('<section class="section" id="inside"', "</section>", include_end=True)
steps = between('<section class="section" id="install"', "</section>", include_end=True)
compat = between('<section class="section" aria-labelledby="compat-title"', "</section>", include_end=True)
faq = between('<section class="section" aria-labelledby="faq-title"', "</section>", include_end=True)
cta = between('<section id="download"', "</section>", include_end=True)

# ---------------------------------------------------------------- shared chrome
PAGES = [("home", "index.html", "Home"), ("features", "features.html", "Features"),
         ("install", "install.html", "Install"), ("download", "download.html", "Download"),
         ("transparency", "transparency.html", "Transparency")]

nav = "\n".join(f'        <a href="{f}" data-page="{k}">{label}</a>' for k, f, label in PAGES)
chrome_top = re.sub(r'<nav class="site-nav" id="nav" aria-label="Sections">.*?</nav>',
                    '<nav class="site-nav" id="nav" aria-label="Pages">\n        <span class="nav-pill" aria-hidden="true"></span>\n' + nav + "\n      </nav>",
                    chrome_top, count=1, flags=re.S)
chrome_top = chrome_top.replace('href="#top" aria-label="Cornea home"', 'href="index.html" aria-label="Cornea home"')
chrome_top = chrome_top.replace('href="#download">Get Cornea', 'href="download.html">Get Cornea')
# mobile menu button, after the theme toggle and Get Cornea button
menu_btn = ('<button class="menu-toggle" id="menu-toggle" type="button" aria-expanded="false" aria-controls="nav" aria-label="Open menu">'
            '<span></span><span></span><span></span></button>')
chrome_top = chrome_top.replace('Get Cornea <span class="arrow">↗</span></a>\n', 'Get Cornea <span class="arrow">↗</span></a>\n        ' + menu_btn + '\n', 1)
assert "menu-toggle" in chrome_top

footer = """    <footer class="site-footer">
      <a class="brand" href="index.html"><img src="img/icon.png" alt="">Cornea</a>
      <nav aria-label="Footer">
        <a href="index.html">Home</a>
        <a href="features.html">Features</a>
        <a href="install.html">Install</a>
        <a href="download.html">Download</a>
        <a href="transparency.html">Transparency</a>
        <a href="https://modrinth.com/mod/iris" target="_blank" rel="noopener">Iris ↗</a>
        <a href="https://ophidianp.github.io/chlorine" target="_blank" rel="noopener">Chlorine ↗</a>
      </nav>
      <span>Not affiliated with Mojang or Microsoft.</span>
    </footer>"""

extra_css = """
@view-transition { navigation: auto; }
.page-head { padding-block: 72px 24px; max-width: 780px; }
.page-head h1 { margin-bottom: 22px; }
a.card { display: block; color: inherit; text-decoration: none; }
.card-go { display: inline-flex; gap: 8px; align-items: center; margin-top: 22px; font: 500 13px var(--mono); color: var(--accent); letter-spacing: 0.02em; }
.card-go .arrow { transition: transform 0.4s var(--ease); }
a.card:hover .card-go .arrow { transform: translateX(4px); }
.next-grid { padding-block: 24px 40px; }
.notfound .hero-stage { cursor: crosshair; }
.nf-code { font: 500 13px var(--mono); color: var(--faint); letter-spacing: 0.04em; }
.menu-toggle { display: none; position: relative; width: 40px; height: 40px; border-radius: 50%; border: 1px solid var(--line); background: transparent; cursor: pointer; padding: 0; }
.menu-toggle span { position: absolute; left: 11px; right: 11px; height: 2px; border-radius: 2px; background: var(--ink); transition: transform 0.45s var(--ease), opacity 0.25s; }
.menu-toggle span:nth-child(1) { top: 14px; }
.menu-toggle span:nth-child(2) { top: 19px; }
.menu-toggle span:nth-child(3) { top: 24px; }
.menu-toggle[aria-expanded="true"] span:nth-child(1) { transform: translateY(5px) rotate(45deg); }
.menu-toggle[aria-expanded="true"] span:nth-child(2) { opacity: 0; }
.menu-toggle[aria-expanded="true"] span:nth-child(3) { transform: translateY(-5px) rotate(-45deg); }
.menu-toggle:hover { border-color: var(--line-strong); }
.dl-steps { padding-block: 24px 40px; }
@media (max-width: 860px) {
  .site-header { position: relative; }
  .menu-toggle { display: block; }
  .site-nav { display: flex !important; position: absolute; top: calc(100% + 10px); left: 0; right: 0; margin: 0;
    flex-direction: column; gap: 2px; padding: 8px; border-radius: 24px; border: 1px solid var(--line-strong);
    background: color-mix(in srgb, var(--bg) 94%, transparent); backdrop-filter: blur(18px); -webkit-backdrop-filter: blur(18px);
    box-shadow: var(--shadow); opacity: 0; visibility: hidden; transform: translateY(-8px); pointer-events: none;
    transition: opacity 0.3s var(--ease), transform 0.45s var(--ease), visibility 0s linear 0.45s; }
  .site-nav.is-open { opacity: 1; visibility: visible; transform: none; pointer-events: auto; transition-delay: 0s; }
  .site-nav a { padding: 14px 16px; font-size: 17px; border-radius: 16px; }
  .site-nav a.is-current { background: var(--accent-soft); }
  .nav-pill { display: none; }
}
"""
import perf

head_src = head_src.replace("</style>", extra_css + read("transparency.css") + perf.PERF_CSS + "</style>")

# ---------------------------------------------------------------- script adjustments
script = script.replace('const h1 = document.querySelector(".split");', 'const h1 = document.querySelector(".split");')
script = script.replace("if (!reduce) splitNode(h1);", "if (!reduce && h1) splitNode(h1);")
script = script.replace("let current = links[0];", 'let current = links.find((a) => a.dataset.page === document.body.dataset.page) || null;')
script = script.replace("    if (!a || !a.offsetWidth) return;", "    if (!a || !a.offsetWidth) { pill.style.opacity = 0; return; }")
# one page per link, so no scroll-spy
script = re.sub(r"  const sections = links\.map.*?addEventListener\(\"scroll\", spy, \{ passive: true \}\);\n", "", script, count=1, flags=re.S)
script = script.replace('  const track = document.getElementById("marquee");\n  track.innerHTML += track.innerHTML;',
                        '  const track = document.getElementById("marquee");\n  if (track) track.innerHTML += track.innerHTML;')
# hero lab and compare only run on pages that have them
script = script.replace("  const stage = document.getElementById(\"stage\");",
                        "  if (document.getElementById(\"stage\")) {\n  const stage = document.getElementById(\"stage\");", 1)
script = script.replace("  frame();\n\n  /* ---------- Compare", "  frame();\n  }\n\n  /* ---------- Compare", 1)
script = script.replace("  const box = document.getElementById(\"compare-box\");",
                        "  if (document.getElementById(\"compare-box\")) {\n  const box = document.getElementById(\"compare-box\");", 1)
script = script.replace("    io.observe(box);\n  }\n})();", "    io.observe(box);\n  }\n  }\n})();", 1)
script = script.replace("})();\n</script>", read("chat.js") + read("menu.js") + "})();\n</script>")
script = perf.apply(script)
assert script.count("if (document.getElementById(\"stage\"))") == 1 and script.count("compare-box\")) {") == 1

# ---------------------------------------------------------------- page bodies
def page_head(eyebrow, title_html, lede):
    return f"""    <header class="page-head">
      <p class="eyebrow">{eyebrow}</p>
      <h1 class="split">{title_html}</h1>
      <p class="lede">{lede}</p>
    </header>"""


def tile(tag, title, text, href, label):
    return f"""        <a class="card reveal" href="{href}">
          <span class="card-tag">{tag}</span>
          <h3>{title}</h3>
          <p>{text}</p>
          <span class="card-go">{label} <span class="arrow">→</span></span>
        </a>"""


home_hero = hero.replace('href="#compare"', 'href="features.html#compare"').replace('href="#download"', 'href="download.html"')
home = f"""  <div class="wrap">
    {home_hero}
  </div>

  {marquee}

  <div class="wrap">
    <section class="section next-grid" aria-label="Explore">
      <div class="cards">
{tile("LOOK", "See what it does", "Coloured torchlight, soft shadows, two cloud layers and water you can see into.", "features.html", "Features")}
{tile("VERSUS", "Drag the line", "Seven scenes from the Overworld, Nether and End, shot in the same spot with Cornea and Photon.", "features.html#compare", "Compare")}
{tile("SETUP", "Three steps", "Add Iris and Sodium, drop in the zip, pick a profile. That is all of it.", "install.html", "Install")}
      </div>
    </section>

{footer}
  </div>"""

features_page = f"""  <div class="wrap">
{page_head("What you see", "Photon's mood, <span class=\"grad\">on a smaller budget.</span>", "Cornea aims for the warm, soft look of the big shaderpacks and spends its frame time where your eye lands first: the light near you, the sky above you, and the water in front of you.")}
    {drop_head(first_section(features))}

    {compare}

    {inside}

    {compat}

{footer}
  </div>"""

install_page = f"""  <div class="wrap">
{page_head("Install", "Three steps <span class=\"grad\">to a new sky.</span>", "Cornea is a normal Iris shaderpack. If you've installed one before, you already know how.")}
    {drop_head(first_section(steps))}

    {faq}

    <section class="section" aria-label="Next step" style="padding-top: 0">
      <div class="button-row reveal">
        <a class="btn btn-primary" href="download.html">Go to the download <span class="arrow">→</span></a>
        <a class="btn btn-ghost" href="transparency.html">How it was made <span class="arrow">→</span></a>
      </div>
    </section>

{footer}
  </div>"""

download_page = f"""  <div class="wrap">
{page_head("Download", "Take Cornea <span class=\"grad\">with you.</span>", "One zip works in every dimension. It needs Iris and Sodium, and it has not been tested on every setup yet.")}
    {cta}

    <section class="section dl-steps" aria-label="Before and after" style="padding-top: 40px">
      <div class="cards">
{tile("FIRST", "What you need", "Minecraft 26.x with Iris and Sodium. Cornea runs best on the Medium profile and up to Ultra.", "install.html", "Install guide")}
{tile("COMPARE", "See it first", "Drag the slider over the same scenes in Photon before you decide.", "features.html#compare", "Compare")}
{tile("HONEST", "How it was made", "Cornea is 100% AI-written. Read how, and see the full conversation.", "transparency.html", "Transparency")}
      </div>
    </section>

{footer}
  </div>"""

TR_LEDE = ("Every line of Cornea's shader code, this website and all of its text was written by AI. "
           "A person steered it, tested it in game and made the calls. This page says exactly what that means.")
transparency_body = ('  <div class="wrap">' + chr(10)
                     + page_head("Transparency", 'Made by AI, <span class="grad">start to finish.</span>', TR_LEDE)
                     + chr(10) * 2 + read("transparency.part.html") + chr(10) + footer + chr(10) + '  </div>')

nf_inner = """  <div class="wrap">
    <section class="hero notfound" aria-labelledby="hero-title">
      <div>
        <p class="eyebrow"><span class="status-dot"></span><span class="nf-code">Error 404</span></p>
        <h1 class="split" id="hero-title">This page is <span class="grad">in the dark.</span></h1>
        <p class="lede">There's nothing at this address. It may have moved, or the link may have a typo. Move the sun around on the right and see if you can find it.</p>
        <div class="button-row">
          <a class="btn btn-primary" href="index.html">Back to Cornea <span class="arrow">→</span></a>
          <a class="btn btn-ghost" href="install.html">Install guide <span class="arrow">→</span></a>
        </div>
      </div>
      <div class="hero-stage" id="stage" aria-label="Interactive demo: move the sun and watch the shadows follow">
        <canvas id="light-canvas"></canvas>
        <div class="hero-icon"><img src="img/icon.png" alt=""></div>
        <div class="hero-readout r1"><span>Sun elevation</span><strong id="ro-sun">38°</strong></div>
        <div class="hero-readout r2"><span>Shadow edge</span><strong id="ro-soft">Soft</strong></div>
        <span class="hero-hint" id="hero-hint">Move your cursor to move the sun</span>
      </div>
    </section>

""" + footer + """
  </div>"""

# the 404 can be served from any depth, so it works out its own base URL
base_script = ("<script>(function(){var b=%s;if(!b){var h=location.hostname,s=location.pathname.split('/')[1];"
               "b=(/\\.github\\.io$/.test(h)&&s&&s.indexOf('.')<0)?'/'+s+'/':'/';}"
               "document.write('<base href=\"'+b+'\">');})();</script>\n") % (repr(site_base) if site_base else "''")

PAGE_META = {
    "transparency": ("transparency.html", "Transparency · Cornea Shaders", transparency_body),
    "home": ("index.html", "Cornea Shaders", home),
    "features": ("features.html", "Features · Cornea Shaders", features_page),
    "install": ("install.html", "Install · Cornea Shaders", install_page),
    "download": ("download.html", "Download · Cornea Shaders", download_page),
}

download = ('<a class="btn btn-primary" href="downloads/Cornea-Shaders.zip" download>'
            'Download Cornea <span class="arrow">↓</span></a>\n'
            '          <small>Cornea Shaders.zip · Iris · Minecraft 26.x</small>')

docstart = ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n')


def assemble(key, title, body, extra_head=""):
    head = head_src.replace("<title>Cornea Shaders</title>", f"<title>{title}</title>")
    # the drop-in head had its own loose tags; the shell supplies charset/viewport
    return (docstart + extra_head + head + f'\n</head>\n<body data-page="{key}">\n'
            + chrome_top + f"<main id=\"top\">\n{body}\n</main>\n\n" + script + "\n</body>\n</html>\n").replace("<!--DOWNLOAD-->", download)


# chrome_top runs from the backdrop to just before <main>, which is what we want
for key, (fname, title, body) in PAGE_META.items():
    open(os.path.join(here, fname), "w", encoding="utf-8", newline="\n").write(assemble(key, title, body))

nf = assemble("404", "Page not found · Cornea Shaders", nf_inner, extra_head=base_script)
nf = nf.replace('<meta name="description"', '<meta name="robots" content="noindex">\n<meta name="description"', 1)
open(os.path.join(here, "404.html"), "w", encoding="utf-8", newline="\n").write(nf)

# the old single-page build is gone
for old in ("artifact.html", "compare.html"):
    p = os.path.join(here, old)
    if os.path.exists(p):
        os.remove(p)
print("built", ", ".join(f for f, _, _ in PAGE_META.values()), "and 404.html")
