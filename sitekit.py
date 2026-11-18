"""Page builder + component helpers for the Cornea site (used by build.py). site.css holds the styles."""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com">\n'
         '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
         '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600&amp;'
         'family=Geist+Mono:wght@400;500&amp;family=Instrument+Serif:ital@0;1&amp;display=swap">')


def write_css(path, name, accent):
    css = open(os.path.join(HERE, "kit.css"), encoding="utf-8").read()
    open(path, "w", encoding="utf-8").write(css.replace("__NAME__", name).replace("__ACCENT__", accent))


class Site:
    def __init__(self, out, brand, icon, nav, fine, css, glass_css, glass_js, prefix="", cta=None, head_extra="", home=None, logo=True, portfolio=True):
        self.out, self.brand, self.icon, self.nav, self.fine = out, brand, icon, nav, fine
        self.css, self.glass_css, self.glass_js, self.prefix, self.cta, self.head_extra = css, glass_css, glass_js, prefix, cta, head_extra
        self.home = home or nav[0][0]
        self.logo = logo
        self.portfolio = portfolio  # footer links to ophidianp.github.io (off on the portfolio itself)

    PORTFOLIO = "https://ophidianp.github.io/"

    def _me(self):
        return f'<a href="{self.PORTFOLIO}">Pavan Nemani</a>' if self.portfolio else "Pavan Nemani"

    def _portfolio_link(self):
        return f' <a href="{self.PORTFOLIO}">Portfolio ↗</a>' if self.portfolio else ""

    def page(self, file, title, desc, body, scripts=(), current=None, head_top=""):
        current = file if current is None else current
        nav = "\n".join(f'    <a href="{f}"{" aria-current=\"page\"" if f == current else ""}>{label}</a>' for f, label in self.nav)
        if self.cta:
            nav += f'\n    <a class="cta-link" href="{self.cta[0]}">{self.cta[1]}</a>'
        js = "".join(f'\n<script src="{self.prefix}{s}" defer></script>' for s in scripts)
        icon = f'<img src="{self.icon}" alt="" width="22" height="22">' if self.icon and self.logo else ""
        html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
{head_top}<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="{desc}">
<meta name="theme-color" content="#0c0c0a">
<title>{title}</title>
<link rel="icon" href="{self.icon}">
{FONTS}
<link rel="stylesheet" href="{self.glass_css}">
<link rel="stylesheet" href="{self.css}">
<script src="{self.glass_js}" data-auto defer></script>{js}{self.head_extra}
</head>
<body>
<header class="header" data-glass="60">
  <a class="name" href="{self.home}">{icon}{self.brand}</a>
  <nav aria-label="Main">
{nav}
  </nav>
</header>

<main>
{body.strip()}
</main>

<footer>
  <p class="made"><span>Made by</span> {self._me()}</p>
  <p class="fine">{self.fine}{self._portfolio_link()}</p>
</footer>
</body>
</html>
"""
        open(os.path.join(self.out, file), "w", encoding="utf-8", newline="\n").write(html)


# ---------- components ----------
def hero(badge, h1, lead, actions="", fine="", extra=""):
    b = f'<span class="badge">{badge}</span>\n' if badge else ""
    a = f'<div class="actions">{actions}</div>\n' if actions else ""
    f = f'<p class="fine">{fine}</p>\n' if fine else ""
    return f'<section class="wrap hero">\n{b}<h1>{h1}</h1>\n<p class="lead">{lead}</p>\n{a}{f}{extra}</section>\n'


def btn(href, text, primary=False, attrs=""):
    return f'<a class="btn{" primary" if primary else ""}" href="{href}"{attrs}>{text}</a>'


def head(eyebrow, h2, intro="", hid=""):
    if not h2:
        return ""
    i = f' id="{hid}"' if hid else ""
    e = f'<p class="eyebrow">{eyebrow}</p>' if eyebrow else ""
    p = f"\n<p>{intro}</p>" if intro else ""
    return f'<div class="section-head">{e}\n<h2{i}>{h2}</h2>{p}\n</div>\n'


def section(eyebrow, h2, intro="", body="", sid=""):
    i = f' id="{sid}"' if sid else ""
    return f'<section class="wrap section"{i}>\n{head(eyebrow, h2, intro)}{body}</section>\n'


def card(label, title, text, more=None, cls="", extra="", serif=False):
    l = f'<p class="label">{label}</p>' if label else ""
    t = (f'<p class="serif">{title}</p>' if serif else f"<h3>{title}</h3>") if title else ""
    m = f'<a class="more" href="{more[0]}">{more[1]} →</a>' if more else ""
    paras = text if text.startswith("<") else f"<p>{text}</p>"
    return f'<article class="card {cls}">{l}{t}{paras}{extra}{m}</article>'


def grid(cards, cls=""):
    return f'<div class="grid {cls}">\n' + "\n".join(cards) + "\n</div>\n"


def rows(items):
    """items: (label, inner_html)"""
    return '<div class="rows">\n' + "\n".join(f'<div class="row"><p class="label">{l}</p><div>{h}</div></div>' for l, h in items) + "\n</div>\n"


def steps(items):
    return '<ol class="steps">\n' + "\n".join(f"<li><h3>{t}</h3><p>{d}</p></li>" for t, d in items) + "\n</ol>\n"


def stats(items):
    return '<div class="stats">\n' + "\n".join(f'<div class="stat"><span>{l}</span><b>{v}</b>{f"<small>{s}</small>" if s else ""}</div>' for l, v, s in items) + "\n</div>\n"


def faq(items):
    return '<div class="faq">\n' + "\n".join(f"<details><summary>{q}</summary><p>{a}</p></details>" for q, a in items) + "\n</div>\n"


def tags(items, on=()):
    return '<ul class="tags">' + "".join(f'<li{" class=\"on\"" if t in on else ""}>{t}</li>' for t in items) + "</ul>"


def cta(h2, text, actions):
    return f'<section class="wrap"><div class="cta">\n<h2>{h2}</h2>\n<p>{text}</p>\n<div class="actions">{actions}</div>\n</div></section>\n'


def chatlog(title):
    return f"""<div class="chatlog">
  <div class="chatlog-head">
    <div><b>{title}</b><small id="chat-meta">Loading the conversation…</small></div>
    <button class="btn" type="button" id="chat-jump">Jump to start</button>
  </div>
  <div id="chat" tabindex="0" aria-label="Full chat log"><p class="chat-empty">Loading…</p></div>
  <div class="chatlog-foot" id="chat-foot">Read-only copy of the session. Scroll to read.</div>
</div>
"""
