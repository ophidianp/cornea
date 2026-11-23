"""Page builder + component helpers for the Cornea site (used by build.py).

The design follows the Mouse 33 site (ophidianp.github.io/mouse33): light and dark themes with a
toggle, a fixed header that turns solid on scroll and never hides, an oversized hero, scroll
reveals (.rv), a pinned feature stage, spec grids, cards that lift on hover, pill buttons, mono
eyebrows, view-transition page swaps, a first-visit preloader and a big footer logo that fills in
as you reach it. Styles live in site.css, behaviour in site.js. The logo is brand/logo.svg, used
as a CSS mask so one file serves the header, preloader and footer (see brand/make_assets.py).
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com">\n'
         '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
         '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&amp;'
         'family=Inter+Tight:wght@500;600;700&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap">')
# Runs before first paint: the saved theme, and the once-per-visit preloader.
EARLY = ('<script>try{var t=localStorage.getItem("cornea-theme");if(t)document.documentElement.dataset.theme=t;'
         'if(!sessionStorage.getItem("cornea-pre")&&!matchMedia("(prefers-reduced-motion: reduce)").matches)'
         '{document.documentElement.classList.add("preload");sessionStorage.setItem("cornea-pre","1")}}catch(e){}</script>')
ICONS = {
    "moon": '<svg class="moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/></svg>',
    "sun": '<svg class="sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>',
    "gh": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 19c-4 1.3-4-2-6-2.5m12 4.5v-3.5c0-1 .1-1.4-.5-2 2.8-.3 5.5-1.4 5.5-6a4.6 4.6 0 0 0-1.3-3.2 4.2 4.2 0 0 0-.1-3.2s-1.1-.3-3.5 1.3a12 12 0 0 0-6.2 0C6.5 2.8 5.4 3.1 5.4 3.1a4.2 4.2 0 0 0-.1 3.2A4.6 4.6 0 0 0 4 9.5c0 4.6 2.7 5.7 5.5 6-.6.6-.6 1.2-.5 2V21"/></svg>',
    "menu": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" aria-hidden="true"><path d="M4 8h16M4 16h16"/></svg>',
}


def logo(cls="", label=None, tag="span", href=None):
    """The wordmark: a base layer and an accent layer that wipes in (clip-path) on top."""
    a = f' href="{href}"' if href else ""
    lab = f' aria-label="{label}"' if label else ' aria-hidden="true"'
    role = ' role="img"' if label and tag == "span" else ""
    return f'<{tag} class="lgs {cls}"{a}{role}{lab}><i class="base"></i><i class="fillp"></i></{tag}>'


class Site:
    def __init__(self, out, brand, url, nav, fine, css, js, cta, version="", github="", tagline="", og_desc=""):
        self.out, self.brand, self.url, self.nav, self.fine = out, brand, url, nav, fine
        self.css, self.js, self.cta, self.version, self.github = css, js, cta, version, github
        self.tagline, self.og_desc = tagline, og_desc
        self.home = nav[0][0]

    PORTFOLIO = "https://ophidianp.github.io/"

    def page(self, file, title, desc, body, scripts=(), current=None, head_top=""):
        current = file if current is None else current
        nav = "\n".join(f'      <a href="{f}"{" class=\"on\" aria-current=\"page\"" if f == current else ""}>{label}</a>'
                        for f, label in self.nav)
        menu = "\n".join(f'    <a href="{f}"{" aria-current=\"page\"" if f == current else ""}>{label}</a>' for f, label in self.nav)
        js = "".join(f'\n<script src="{s}" defer></script>' for s in (self.js, *scripts))
        page_url = self.url + ("" if file == "index.html" else file)
        gh = f'\n      <a class="ib gh" href="{self.github}" aria-label="Cornea on GitHub">{ICONS["gh"]}</a>' if self.github else ""
        ver = f'\n      <span class="kbd">{self.version}</span>' if self.version else ""
        html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
{head_top}<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{title}</title>
<meta name="description" content="{desc}">
<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#0a0c0c" media="(prefers-color-scheme: dark)">
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<meta property="og:type" content="website">
<meta property="og:site_name" content="{self.brand}">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{self.og_desc or desc}">
<meta property="og:url" content="{page_url}">
<meta property="og:image" content="{self.url}og.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
{EARLY}
{FONTS}
<link rel="stylesheet" href="{self.css}">{js}
</head>
<body>
<div class="pre" aria-hidden="true"><div class="pre-in">
  {logo()}
  <p>{self.tagline}</p>
</div></div>

<header class="hdr" id="hdr">
  <div class="wrap">
    {logo("logo", f"{self.brand}, home", "a", self.home)}
    <nav class="nav" aria-label="Main">
{nav}
    </nav>
    <div class="tools">{ver}
      <button class="ib" id="theme" type="button" aria-label="Switch light or dark mode">{ICONS["moon"]}{ICONS["sun"]}</button>{gh}
      <a class="pill sm get" href="{self.cta[0]}">{self.cta[1]}</a>
      <button class="ib menu-btn" id="menu-btn" type="button" aria-label="Menu" aria-expanded="false" aria-controls="menu">{ICONS["menu"]}</button>
    </div>
  </div>
  <nav class="menu" id="menu" aria-label="Menu" hidden>
{menu}
    <a class="pill acc" href="{self.cta[0]}">{self.cta[1]} <span class="ar">→</span></a>
  </nav>
</header>

<main>
{body.strip()}
</main>

<footer>
  <div class="wrap foot-logo">{logo("", self.brand)}<p class="foot-by">by <a href="{self.PORTFOLIO}">Pavan Nemani</a></p></div>
  <div class="wrap fine">{self.fine}</div>
</footer>
</body>
</html>
"""
        open(os.path.join(self.out, file), "w", encoding="utf-8", newline="\n").write(html)


# ---------- components ----------
def _delay(i):
    return f" d{i % 3}" if i % 3 else ""


def hero(eyebrow, h1, lede, actions="", fine="", extra="", split=False):
    e = f'<div class="eyebrow in">{eyebrow}</div>\n' if eyebrow else ""
    a = f'<div class="cta in d3">{actions}</div>\n' if actions else ""
    f = f'<p class="fine in d3">{fine}</p>\n' if fine else ""
    if split:
        top = (f'<div class="hero-grid">\n<div>{e}<h1 class="in d1">{h1}</h1></div>\n'
               f'<div class="hero-side">\n<p class="lede in d2">{lede}</p>\n{a}{f}</div>\n</div>\n')
    else:
        top = f'{e}<h1 class="in d1">{h1}</h1>\n<p class="lede in d2">{lede}</p>\n{a}{f}'
    return f'<section class="hero{" duo" if split else ""}">\n<div class="wrap">\n{top}{extra}</div>\n</section>\n'


def btn(href, text, primary=False, attrs=""):
    m = re.match(r"^(.*?)\s*([↓→↗])$", text)
    inner = f'{m.group(1)} <span class="ar">{m.group(2)}</span>' if m else text
    return f'<a class="pill{" acc" if primary else ""}" href="{href}"{attrs}>{inner}</a>'


def head(eyebrow, h2, intro="", hid=""):
    if not h2:
        return ""
    i = f' id="{hid}"' if hid else ""
    e = f'<div class="eyebrow rv">{eyebrow}</div>' if eyebrow else ""
    p = f'\n<p class="lede rv d2">{intro}</p>' if intro else ""
    return f'<div class="blk-head">\n<div>{e}<h2 class="rv d1"{i}>{h2}</h2></div>{p}\n</div>\n'


def section(eyebrow, h2, intro="", body="", sid="", cls="", tight=False):
    i = f' id="{sid}"' if sid else ""
    c = f"blk{' tight' if tight else ''}{' ' + cls if cls else ''}"
    return f'<section class="{c}"{i}>\n<div class="wrap">\n{head(eyebrow, h2, intro)}{body}</div>\n</section>\n'


def split(eyebrow, h2, intro, body, sid="", hid=""):
    """A sticky heading on the left, content on the right."""
    i = f' id="{sid}"' if sid else ""
    return (f'<section class="blk"{i}>\n<div class="wrap split">\n<div class="split-head">{head(eyebrow, h2, intro, hid)}</div>\n'
            f'<div class="split-body">\n{body}</div>\n</div>\n</section>\n')


def card(label, title, text, more=None, cls="", extra="", img=None, i=0):
    """img: (src, alt). A card with a 'more' link is clickable all over."""
    ph = f'<div class="ph img"><img src="{img[0]}" alt="{img[1]}" loading="lazy"></div>' if img else ""
    l = f'<div class="eyebrow">{label}</div>' if label else ""
    t = f"<h3>{title}</h3>" if title else ""
    paras = text if text.startswith("<") else f"<p>{text}</p>"
    m = f'<a class="more" href="{more[0]}">{more[1]} <span class="ar">→</span></a>' if more else ""
    c = "card rv" + _delay(i) + (" link" if more else "") + (" txt" if not img else "") + (f" {cls}" if cls else "")
    return f'<article class="{c}">{ph}<div class="body">{l}{t}{paras}{extra}{m}</div></article>'


def grid(cards, cls=""):
    return f'<div class="cards{" " + cls if cls else ""}">\n' + "\n".join(cards) + "\n</div>\n"


def specgrid(items):
    """items: (label, value)"""
    return ('<dl class="specgrid rv">\n' + "\n".join(f"<div><dt>{l}</dt><dd>{v}</dd></div>" for l, v in items) + "\n</dl>\n")


def marquee(items):
    run = "".join(f"<span>{t}</span>" for t in items)
    return f'<div class="marq" aria-hidden="true"><div class="track">{run}{run}</div></div>\n'


def rows(items):
    """items: (label, inner_html)"""
    return '<div class="rows">\n' + "\n".join(f'<div class="row rv"><div class="eyebrow">{l}</div><div>{h}</div></div>' for l, h in items) + "\n</div>\n"


def steps(items):
    return '<ol class="nsteps">\n' + "\n".join(f'<li class="card txt rv{_delay(i)}"><h3>{t}</h3><p>{d}</p></li>' for i, (t, d) in enumerate(items)) + "\n</ol>\n"


def tear(eyebrow, h2, items, sid=""):
    """A pinned stage: the steps on the left light up one by one as you scroll, and the picture
    on the right changes with them. items: (label, title, text, img, alt, tag)."""
    n = len(items)
    lis = "\n".join(f'<li{" class=\"on\"" if k == 0 else ""} data-i="{k}"><div class="t">{t} <small>{k + 1:02d} / {n:02d}</small></div>'
                    f'<div class="eyebrow">{l}</div><p>{x}</p></li>' for k, (l, t, x, _, _, _) in enumerate(items))
    imgs = "\n".join(f'<img class="layer{" on" if k == 0 else ""}" data-l="{k}" data-tag="{tag}" src="{src}" alt="{alt}"{" loading=\"lazy\"" if k else ""}>'
                     for k, (_, _, _, src, alt, tag) in enumerate(items))
    i = f' id="{sid}"' if sid else ""
    return f"""<section class="tear" style="--n:{n}"{i}>
<div class="pin"><div class="wrap grid">
<div>
<div class="eyebrow">{eyebrow}</div>
<h2 style="margin-top:18px">{h2}</h2>
<ol class="steps">
{lis}
</ol>
<div class="bar"><i></i></div>
</div>
<div class="ph img tstage">
{imgs}
<span class="lbl">{items[0][5]}</span>
</div>
</div></div>
</section>
"""


def faq(items):
    return '<div class="faq">\n' + "\n".join(f"<details><summary>{q}</summary><p>{a}</p></details>" for q, a in items) + "\n</div>\n"


def tags(items, on=()):
    return '<ul class="tags">' + "".join(f'<li{" class=\"on\"" if t in on else ""}>{t}</li>' for t in items) + "</ul>"


def cta(h2, text, actions):
    return (f'<section class="blk close-blk">\n<div class="wrap close">\n<h2 class="rv d1">{h2}</h2>\n'
            f'<p class="lede rv d2">{text}</p>\n<div class="cta rv d2">{actions}</div>\n</div>\n</section>\n')


def chatlog(title):
    return f"""<div class="chatlog rv">
  <div class="chatlog-head">
    <div><b>{title}</b><small id="chat-meta">Loading the conversation…</small></div>
    <button class="pill sm" type="button" id="chat-jump">Jump to start</button>
  </div>
  <div id="chat" tabindex="0" aria-label="Full chat log"><p class="chat-empty">Loading…</p></div>
  <div class="chatlog-foot" id="chat-foot">Read-only copy of the session. Scroll to read.</div>
</div>
"""
