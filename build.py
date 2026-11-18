"""Builds the Cornea website: plain, minimal pages that share one stylesheet (site.css).

    python build.py

writes index.html, features.html, install.html, download.html, transparency.html and
404.html. Each page's text lives below; the header and footer are shared. The header is
the only liquid-glass element (liquid-glass.css + .js); everything else is plain HTML.

Set SITE_BASE (e.g. SITE_BASE=/cornea/) if the site lives in a sub-folder, so 404.html
can find its images and links from any missing URL.
"""
import os

here = os.path.dirname(os.path.abspath(__file__))
site_base = os.environ.get("SITE_BASE", "")
DESC = ("Cornea is an Iris shaderpack for Minecraft 26.x with volumetric clouds, coloured light and soft shadows, "
        "tuned to run well on mid-range graphics cards.")
NAV = [("index.html", "Home"), ("features.html", "Features"), ("install.html", "Install"),
       ("download.html", "Download"), ("transparency.html", "Transparency")]

# 404.html is served for any missing address, so it sets a <base> to find its files.
BASE_SCRIPT = ("<script>(function(){var b=%s;if(!b){var h=location.hostname,s=location.pathname.split('/')[1];"
               "b=(/\\.github\\.io$/.test(h)&&s&&s.indexOf('.')<0)?'/'+s+'/':'/';}"
               "document.write('<base href=\"'+b+'\">');})();</script>\n") % (repr(site_base) if site_base else "''")


def page(file, title, body, scripts=(), current=None, base=False):
    current = current or file
    nav = "\n".join(f'    <a href="{f}"{" aria-current=\"page\"" if f == current else ""}>{label}</a>' for f, label in NAV)
    js = "".join(f'\n<script src="{s}" defer></script>' for s in scripts)
    html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
{BASE_SCRIPT if base else ""}<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="{DESC}">
<title>{title}</title>
<link rel="icon" type="image/png" href="img/icon.png">
<link rel="stylesheet" href="liquid-glass.css?v=2">
<link rel="stylesheet" href="site.css?v=1">
<script src="liquid-glass.js?v=2" data-auto defer></script>{js}
</head>
<body>
<header class="header" data-glass="60">
  <a class="name" href="index.html"><img src="img/icon.png" alt="" width="22" height="22">Cornea</a>
  <nav aria-label="Main">
{nav}
  </nav>
</header>

<main>
{body.strip()}
</main>

<footer>
  <p>&copy; Pavan Nemani · All Rights Reserved (ARR) · Not affiliated with Mojang or Microsoft.</p>
  <nav aria-label="Footer"><a href="https://modrinth.com/mod/iris">Iris</a><a href="https://ophidianp.github.io/chlorine">Chlorine</a><a href="transparency.html">Transparency</a></nav>
</footer>
</body>
</html>
"""
    open(os.path.join(here, file), "w", encoding="utf-8", newline="\n").write(html)


page("index.html", "Cornea Shaders", """
<h1>Light the world. Keep your frames.</h1>
<p class="lead">Cornea brings volumetric clouds, coloured light and soft shadows to Minecraft, tuned to run well on mid-range graphics cards.</p>
<div class="actions">
  <a class="button primary" href="download.html">Download for 26.3</a>
  <a class="button" href="features.html#compare">Compare with Photon</a>
</div>
<p class="muted">Iris shaderpack · For Iris · Minecraft 26.x · Free to use</p>

<h2>What Cornea adds</h2>
<ul>
  <li>Sky: volumetric clouds and godrays</li>
  <li>Light: coloured torchlight</li>
  <li>Shadow: soft penumbras</li>
  <li>Water: caustics</li>
  <li>Night: auroras</li>
  <li>End: a black hole</li>
  <li>Blocks: built-in shine</li>
  <li>Plants: grass that moves aside</li>
</ul>

<h2>Explore</h2>
<ul>
  <li><strong><a href="features.html">See what it does</a>.</strong> Coloured torchlight, soft shadows, two cloud layers and water you can see into.</li>
  <li><strong><a href="features.html#compare">Compare</a>.</strong> Seven scenes from the Overworld, Nether and End, shot in the same spot with Cornea and Photon.</li>
  <li><strong><a href="install.html">Three steps</a>.</strong> Add Iris and Sodium, drop in the zip, pick a profile. That is all of it.</li>
</ul>
""")

SCENES = [
    ("Cave mouth", "Overworld · cave", "a cave mouth"),
    ("River valley from above", "Overworld · day", "a river valley seen from high above"),
    ("Under the river", "Overworld · underwater", "the riverbed seen from underwater"),
    ("Crimson cliffs", "Nether · lava sea", "crimson cliffs over a lava sea"),
    ("Warped shore", "Nether · lava sea", "a warped forest on the shore of a lava sea"),
    ("The main island", "End · sky", "the main End island and its pillars"),
    ("City and ship", "End · outer islands", "an End city and End ship"),
]
pairs = "\n".join(f"""<figure class="pair">
  <figcaption><strong>{t}</strong> <span class="muted">· {tag}</span></figcaption>
  <div><img src="img/cmp-{i}-cornea.webp" alt="Cornea, {alt}" loading="lazy"><small>Cornea</small></div>
  <div><img src="img/cmp-{i}-photon.webp" alt="Photon, {alt}" loading="lazy"><small>Photon</small></div>
</figure>""" for i, (t, tag, alt) in enumerate(SCENES, 1))

page("features.html", "Features · Cornea Shaders", f"""
<h1>Photon's mood, on a smaller budget.</h1>
<p class="lead">Cornea aims for the warm, soft look of the big shaderpacks and spends its frame time where your eye lands first: the light near you, the sky above you, and the water in front of you.</p>
<ul id="features">
  <li><strong>Light that has a colour.</strong> Torches glow orange, soul fire glows blue and amethyst tints a cave purple. Light spreads through the blocks around you, and nearby blocks and mobs cast short shadows from it.</li>
  <li><strong>A sky worth looking up at.</strong> Two layers of volumetric clouds with thin cirrus above them, auroras on clear nights, and in the End, a black hole that bends the starlight around it.</li>
  <li><strong>Water you can see into.</strong> Uneven waves that never line up in rows, caustics dancing on the seabed and godrays under the surface. A torch or lava pool lights the water from below.</li>
</ul>

<h2 id="compare">Same spot, side by side.</h2>
<p>Each pair was shot from the same place, with Cornea on the left and Photon on the right. Photon is made by SixthSurge and is shown here only for comparison.</p>
{pairs}

<h2 id="inside">Where the frames come from.</h2>
<p>Most of Cornea's speed comes from doing expensive work less often, at lower resolution, and only when it shows.</p>
<ul>
  <li><strong>Half-size clouds and light shafts</strong> (sky). Clouds and godrays render at half resolution and fill in over a few frames, so they cost about a quarter of the pixels.</li>
  <li><strong>Light that spreads a step at a time</strong> (light). Coloured light flows one block per frame through a 96-block volume around you, instead of being solved from scratch every frame.</li>
  <li><strong>Exposure from the light, not the screen</strong> (camera). The camera sets its brightness from how much sun and sky reach you, so there's no costly average of the whole picture.</li>
  <li><strong>Shine built into the pack</strong> (blocks). Metals, polished stone, gems and glowing ores get their gloss and surface detail from Cornea itself. No resource pack, no extra textures to read.</li>
  <li><strong>Off really means off</strong> (settings). Every effect drops out of the shader when you switch it off, so the Low profile does less work, not just less drawing.</li>
</ul>

<h2 id="compat-title">Made for the setup you already run.</h2>
<p>Cornea needs Iris, and Iris needs Sodium, so install both. It is built and tested on Minecraft 26.x, including clients that bundle them such as OneClient.</p>
<ul>
  <li>Required: Iris, Sodium, Minecraft 26.x</li>
  <li>Works with: OneClient, Chlorine</li>
  <li>Not supported yet: <s>Distant Horizons</s>, <s>Voxy</s></li>
</ul>
<p class="muted">Crossed out: not supported yet. Cornea skips far-distance terrain to keep its frame budget for what's close to you.</p>
""")

page("install.html", "Install · Cornea Shaders", """
<h1>Three steps to a new sky.</h1>
<p class="lead">Cornea is a normal Iris shaderpack. If you've installed one before, you already know how.</p>
<ol id="install">
  <li><strong>Install Iris and Sodium.</strong> Add <a href="https://modrinth.com/mod/iris">Iris</a> and <a href="https://modrinth.com/mod/sodium">Sodium</a> to your Minecraft 26.x instance. Iris needs Sodium to run, so you need both.</li>
  <li><strong>Add Cornea.</strong> Drop <code>Cornea Shaders.zip</code> into the <code>shaderpacks</code> folder. Leave it zipped.</li>
  <li><strong>Pick a profile.</strong> Open Video Settings, then Shader Packs, select Cornea and choose Low, Medium, High or Ultra.</li>
</ol>

<h2 id="faq-title">A few quick answers.</h2>
<div class="faq">
  <details><summary>Do I need a resource pack?</summary><p>No. Shine, surface detail and glowing ores are built in and work with the default textures.</p></details>
  <details><summary>Is Cornea a version of Photon?</summary><p>No. Cornea is a separate pack that aims for a similar warm, soft look. Photon is made by SixthSurge, and its screenshots here are only for comparison.</p></details>
  <details><summary>Why are there no sun shadows in the Nether?</summary><p>The Nether has no sun or moon, so there's nothing to cast them. Lava, fire and glowstone still light the world in colour, and nearby blocks still block that light.</p></details>
  <details><summary>What hardware was it tuned on?</summary><p>A Ryzen 5 5500 with a 4 GB RX 6500 XT and 16 GB of memory. If you have a slower card, start with the Medium profile and turn up what you miss.</p></details>
  <details><summary>Something looks wrong. What should I send?</summary><p>A screenshot, the profile you're using, and the Iris error log if the pack fails to load. That's usually enough to find the cause.</p></details>
</div>
<div class="actions">
  <a class="button primary" href="download.html">Go to the download</a>
  <a class="button" href="transparency.html">How it was made</a>
</div>
""")

page("download.html", "Download · Cornea Shaders", """
<h1>Take Cornea with you.</h1>
<p class="lead">One zip works in every dimension. It needs Iris and Sodium, and it has not been tested on every setup yet.</p>

<h2 id="download">Open your eyes to a softer Minecraft.</h2>
<p>One zip, every dimension. Drop it into your shaderpacks folder and pick a profile.</p>
<p><a class="button primary" href="downloads/Cornea-Shaders.zip" download>Download Cornea</a></p>
<p class="muted">Cornea Shaders.zip · Iris · Minecraft 26.x</p>

<h2>Before you download</h2>
<ul>
  <li><strong>What you need.</strong> Minecraft 26.x with Iris and Sodium. Cornea runs best on the Medium profile and up to Ultra. <a href="install.html">Install guide</a></li>
  <li><strong>See it first.</strong> Look at the same scenes in Photon before you decide. <a href="features.html#compare">Compare</a></li>
  <li><strong>How it was made.</strong> Cornea is 100% AI-written. Read how, and see the full conversation. <a href="transparency.html">Transparency</a></li>
</ul>
""")

page("transparency.html", "Transparency · Cornea Shaders", """
<h1>Made by AI, start to finish.</h1>
<p class="lead">Every line of Cornea's shader code, this website and all of its text was written by AI. A person steered it, tested it in game and made the calls. This page says exactly what that means.</p>
<ul>
  <li><strong>100%: written entirely by AI.</strong> The shaders, the settings menus, the build tools, this site and its copy. <strong>Nothing was written by hand.</strong> You can read the whole conversation at the bottom of this page.</li>
  <li><strong>Models: Claude Opus 5.5 and Sonnet 5.5.</strong> Both ran through Claude Code. In the log below, <span id="n-opus">Opus</span> and <span id="n-sonnet">Sonnet</span> wrote the replies, and each one is labelled with the model that wrote it.</li>
  <li><strong>Human: one person steering.</strong> A person set the goals, sent screenshots, tested in game on a Ryzen 5 5500 and an RX 6500 XT, and decided what to keep. The AI can't see the game, so tuning followed that feedback.</li>
</ul>

<h2 id="photon-title">Inspired by Photon. Not Photon.</h2>
<p>Cornea chases the warm, soft look of Photon by SixthSurge. Here is how close the two really are, and where the line sits.</p>
<ul>
  <li><strong>Photon was the target</strong> (goal). The goal was Photon's mood at a higher frame rate on a modest card. The comparison screenshots on the Features page are Photon, shown only so you can judge for yourself.</li>
  <li><strong>Its source was read as a reference</strong> (study). The AI studied Photon's shader files to learn techniques such as the sky look-up table, the light volume for coloured torches, soft shadows and temporal anti-aliasing. Photon's licence allows examining and learning from its source.</li>
  <li><strong>The code was written fresh</strong> (code). Cornea's files were written new, with their own structure and many different choices, and no Photon file was copied in. But reading Photon shaped the design, so the two share ideas and some layout. We can't promise no passage ever resembles it.</li>
  <li><strong>Only on this site, for now</strong> (sharing). Cornea is not on Modrinth, because it is AI-generated work. A CurseForge release may come later, but not yet, so this site is the only place to get it.</li>
  <li><strong>Checked, but young</strong> (status). Every program was compile-checked in several setting combinations and the author tested it in game. It is new, so expect rough edges and report what you find.</li>
</ul>

<h2 id="log-title">The whole conversation.</h2>
<p>From the first message to the request for this page. Only what was said in the chat is shown: tool use is left out, and file paths, local addresses and emails are masked. It reads like a messaging app, but you can't reply.</p>
<div class="chatlog">
  <div class="chatlog-head">
    <div><b>Claude Code · Cornea</b><small id="chat-meta">Loading the conversation…</small></div>
    <button class="button" type="button" id="chat-jump">Jump to start</button>
  </div>
  <div id="chat" tabindex="0" aria-label="Full chat log"><p class="chat-empty">Loading…</p></div>
  <div class="chatlog-foot" id="chat-foot">Read-only copy of the session. Scroll to read.</div>
</div>
<p class="muted">Not affiliated with SixthSurge, Mojang, Microsoft or Anthropic.</p>
""", scripts=("chat.js?v=2",))

page("404.html", "Page not found · Cornea Shaders", """
<p class="muted">Error 404</p>
<h1>This page is in the dark.</h1>
<p class="lead">There's nothing at this address. It may have moved, or the link may have a typo.</p>
<div class="actions">
  <a class="button primary" href="index.html">Back to Cornea</a>
  <a class="button" href="install.html">Install guide</a>
</div>
""", current="", base=True)

print("built index.html, features.html, install.html, download.html, transparency.html and 404.html")
