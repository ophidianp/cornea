"""Builds the Cornea website from this file: run `python build.py`.

Writes index.html, features.html, install.html, download.html and
404.html. Each page's text lives below; the shared header/footer and the components (hero,
cards, spec grid, pinned stage, FAQ...) come from sitekit.py, the styles from site.css and the
behaviour from site.js. The logo and icons come from brand/make_assets.py.

Set SITE_BASE (e.g. SITE_BASE=/cornea/) if the site lives in a sub-folder, so 404.html
can find its images and links from any missing URL.
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sitekit import Site, hero, btn, head, section, split, card, grid, specgrid, marquee, rows, steps, tear, faq, cta

here = os.path.dirname(os.path.abspath(__file__))
site_base = os.environ.get("SITE_BASE", "")
DESC = ("Cornea is an Iris shaderpack for Minecraft 26.x with volumetric clouds, coloured light and soft shadows, "
        "tuned to run well on mid-range graphics cards.")
# 404.html is served for any missing address, so it sets a <base> to find its files.
BASE_SCRIPT = ("<script>(function(){var b=%s;if(!b){var h=location.hostname,s=location.pathname.split('/')[1];"
               "b=(/\\.github\\.io$/.test(h)&&s&&s.indexOf('.')<0)?'/'+s+'/':'/';}"
               "document.write('<base href=\"'+b+'\">');})();</script>\n") % (repr(site_base) if site_base else "''")

S = Site(here, "Cornea", "https://ophidianp.github.io/cornea/",
         [("index.html", "Home"), ("features.html", "Features"), ("install.html", "Install")],
         '<span>&copy; Pavan Nemani · All Rights Reserved (ARR) · Not affiliated with Mojang or Microsoft.</span>'
         '<span class="links"><a href="https://modrinth.com/mod/iris">Iris ↗</a> <a href="https://ophidianp.github.io/chlorine">Chlorine ↗</a> '
         '<a href="https://ophidianp.github.io/">Portfolio ↗</a></span>',
         css="site.css?v=8", js="site.js?v=1", cta=("download.html", "Get Cornea"), version="26.x",
         github="https://github.com/ophidianp/cornea", tagline="Light the world.<br>Keep your frames.",
         og_desc="Volumetric clouds, coloured light and soft shadows for Minecraft 26.x, tuned to run well on mid-range graphics cards.")

EFFECTS = [("Sky", "Volumetric clouds"), ("Light", "Coloured torchlight"), ("Shadow", "Soft penumbras"),
           ("Sky", "Godrays"), ("Water", "Caustics"), ("Night", "Auroras"),
           ("End", "A black hole"), ("Blocks", "Built-in shine"), ("Plants", "Grass that moves aside")]

S.page("index.html", "Cornea Shaders", DESC,
    hero("Iris shaderpack · <b>Minecraft 26.x</b>", "Light the world.<br><em>Keep your frames.</em>",
         "Cornea brings volumetric clouds, coloured light and soft shadows to Minecraft, tuned to run well on mid-range graphics cards.",
         btn("download.html", "Download for 26.3 ↓", True) + btn("features.html#compare", "Compare with Photon →"),
         "For Iris · Minecraft 26.x · Free to use",
         '<figure class="ph img stage zoom"><img class="par" src="img/cmp-2-cornea.webp" alt="Cornea, a river valley seen from high above" width="1606" height="903" fetchpriority="high">'
         '<figcaption class="tag">Cornea · river valley from above · Overworld, day</figcaption></figure>', split=True)
    + marquee([t for _, t in EFFECTS])
    + section("What Cornea adds", "Every effect, <em>tuned to stay fast.</em>", "", specgrid(EFFECTS))
    + section("Explore", "Look, compare, <em>install.</em>", "", grid([
        card("Look", "See what it does", "Coloured torchlight, soft shadows, two cloud layers and water you can see into.", ("features.html", "Features"),
             img=("img/cmp-5-cornea.webp", "Cornea, a warped forest on the shore of a lava sea"), i=0),
        card("Versus", "Side by side", "Seven scenes from the Overworld, Nether and End, shot in the same spot with Cornea and Photon.", ("features.html#compare", "Compare"),
             img=("img/cmp-7-cornea.webp", "Cornea, an End city and End ship"), i=1),
        card("Setup", "Three steps", "Add Iris and Sodium, drop in the zip, pick a profile. That is all of it.", ("install.html", "Install"),
             img=("img/cmp-1-cornea.webp", "Cornea, a cave mouth"), i=2),
    ]), cls="alt")
    + cta("Open your eyes to <em>a softer Minecraft.</em>", "One zip, every dimension. Drop it into your shaderpacks folder and pick a profile.",
          btn("download.html", "Download Cornea ↓", True)))

SCENES = [
    ("Cave mouth", "Overworld · cave", "a cave mouth"),
    ("River valley from above", "Overworld · day", "a river valley seen from high above"),
    ("Under the river", "Overworld · underwater", "the riverbed seen from underwater"),
    ("Crimson cliffs", "Nether · lava sea", "crimson cliffs over a lava sea"),
    ("Warped shore", "Nether · lava sea", "a warped forest on the shore of a lava sea"),
    ("The main island", "End · sky", "the main End island and its pillars"),
    ("City and ship", "End · outer islands", "an End city and End ship"),
]
pairs = '<div class="pairs">\n' + "\n".join(f"""<figure class="pair rv{' d1' if i % 2 == 0 else ''}">
  <figcaption>{t} <span>· {tag}</span></figcaption>
  <div class="shots"><div><img src="img/cmp-{i}-cornea.webp" alt="Cornea, {alt}" loading="lazy"><small>Cornea</small></div>
  <div><img src="img/cmp-{i}-photon.webp" alt="Photon, {alt}" loading="lazy"><small>Photon</small></div></div>
</figure>""" for i, (t, tag, alt) in enumerate(SCENES, 1)) + "\n</div>\n"

S.page("features.html", "Features · Cornea Shaders", DESC,
    hero("What you see", "Photon's mood, <em>on a smaller budget.</em>",
         "Cornea aims for the warm, soft look of the big shaderpacks and spends its frame time where your eye lands first: the light near you, the sky above you, and the water in front of you.")
    + tear("Where your eye lands", "Light, sky <em>and water.</em>", [
        ("Light", "Light that has a colour", "Torches glow orange, soul fire glows blue and amethyst tints a cave purple. Light spreads through the blocks around you, and nearby blocks and mobs cast short shadows from it.",
         "img/cmp-4-cornea.webp", "Cornea, crimson cliffs over a lava sea", "Crimson cliffs · Nether"),
        ("Sky", "A sky worth looking up at", "Two layers of volumetric clouds with thin cirrus above them, auroras on clear nights, and in the End, a black hole that bends the starlight around it.",
         "img/cmp-6-cornea.webp", "Cornea, the main End island and its pillars under the black hole", "The main island · End"),
        ("Water", "Water you can see into", "Uneven waves that never line up in rows, caustics dancing on the seabed and godrays under the surface. A torch or lava pool lights the water from below.",
         "img/cmp-3-cornea.webp", "Cornea, the riverbed seen from underwater", "Under the river · Overworld"),
    ], "features")
    + section("Side by side", "Same spot. <em>Two shaderpacks.</em>",
        "Each pair was shot from the same place, with Cornea on the left and Photon on the right. Photon is made by SixthSurge and is shown here only for comparison.", pairs, "compare", cls="alt")
    + split("Under the hood", "Where the frames <em>come from.</em>",
        "Most of Cornea's speed comes from doing expensive work less often, at lower resolution, and only when it shows.", rows([
        ("A · Sky", "<h3>Half-size clouds and light shafts</h3><p>Clouds and godrays render at half resolution and fill in over a few frames, so they cost about a quarter of the pixels.</p>"),
        ("B · Light", "<h3>Light that spreads a step at a time</h3><p>Coloured light flows one block per frame through a 96-block volume around you, instead of being solved from scratch every frame.</p>"),
        ("C · Camera", "<h3>Exposure from the light, not the screen</h3><p>The camera sets its brightness from how much sun and sky reach you, so there's no costly average of the whole picture.</p>"),
        ("D · Blocks", "<h3>Shine built into the pack</h3><p>Metals, polished stone, gems and glowing ores get their gloss and surface detail from Cornea itself. No resource pack, no extra textures to read.</p>"),
        ("E · Settings", "<h3>Off really means off</h3><p>Every effect drops out of the shader when you switch it off, so the Low profile does less work, not just less drawing.</p>"),
    ]), "inside")
    + split("Works with", "Made for the setup <em>you already run.</em>",
        "Cornea needs Iris, and Iris needs Sodium, so install both. It is built and tested on Minecraft 26.x, including clients that bundle them such as OneClient.",
        card("Compatibility", "", "<p>Crossed out: not supported yet. Cornea skips far-distance terrain to keep its frame budget for what's close to you.</p>",
             cls="still", extra='<ul class="tags"><li class="on">Iris · required</li><li class="on">Sodium · required</li><li>Minecraft 26.x</li><li>OneClient</li><li>Chlorine</li><li class="off">Distant Horizons</li><li class="off">Voxy</li></ul>'))
    + cta("Take Cornea <em>with you.</em>", "One zip works in every dimension. It needs Iris and Sodium.", btn("download.html", "Download Cornea ↓", True)))

S.page("install.html", "Install · Cornea Shaders", DESC,
    hero("Install", "Three steps <em>to a new sky.</em>", "Cornea is a normal Iris shaderpack. If you've installed one before, you already know how.")
    + section("", "", "", steps([
        ("Install Iris and Sodium", 'Add <a href="https://modrinth.com/mod/iris">Iris</a> and <a href="https://modrinth.com/mod/sodium">Sodium</a> to your Minecraft 26.x instance. Iris needs Sodium to run, so you need both.'),
        ("Add Cornea", "Drop <code>Cornea Shaders.zip</code> into the <code>shaderpacks</code> folder. Leave it zipped."),
        ("Pick a profile", "Open Video Settings, then Shader Packs, select Cornea and choose Low, Medium, High or Ultra."),
    ]), "install", tight=True)
    + split("Good to know", "A few quick <em>answers.</em>", "", faq([
        ("Do I need a resource pack?", "No. Shine, surface detail and glowing ores are built in and work with the default textures."),
        ("Is Cornea a version of Photon?", "No. Cornea is a separate pack that aims for a similar warm, soft look. Photon is made by SixthSurge, and its screenshots here are only for comparison."),
        ("Why are there no sun shadows in the Nether?", "The Nether has no sun or moon, so there's nothing to cast them. Lava, fire and glowstone still light the world in colour, and nearby blocks still block that light."),
        ("What hardware was it tuned on?", "A Ryzen 5 5500 with a 4 GB RX 6500 XT and 16 GB of memory. If you have a slower card, start with the Medium profile and turn up what you miss."),
        ("Something looks wrong. What should I send?", "A screenshot, the profile you're using, and the Iris error log if the pack fails to load. That's usually enough to find the cause."),
    ]), hid="faq-title")
    + cta("Ready when <em>you are.</em>", "Grab the zip and pick a profile.",
          btn("download.html", "Go to the download →", True)))

S.page("download.html", "Download · Cornea Shaders", DESC,
    hero("Download", "Take Cornea <em>with you.</em>", "One zip works in every dimension. It needs Iris and Sodium, and it has not been tested on every setup yet.")
    + """<section class="blk tight" id="download">
<div class="wrap">
<div class="dl-card rv">
  <div class="dl-text">
    <div class="eyebrow">Ready when you are</div>
    <h2 id="download-title">Open your eyes to a softer Minecraft.</h2>
    <p class="lede">One zip, every dimension. Drop it into your shaderpacks folder and pick a profile.</p>
    <div class="cta"><a class="pill acc" href="downloads/Cornea-Shaders.zip" download>Download Cornea <span class="ar">↓</span></a></div>
    <p class="fine">Cornea Shaders.zip · Iris · Minecraft 26.x</p>
  </div>
  <div class="ph img dl-shot"><img src="img/cmp-6-cornea.webp" alt="Cornea, the main End island and its pillars" loading="lazy"></div>
</div>
</div>
</section>
"""
    + section("Before and after", "Know what <em>you're getting.</em>", "", grid([
        card("First", "What you need", "Minecraft 26.x with Iris and Sodium. Cornea runs best on the Medium profile and up to Ultra.", ("install.html", "Install guide"), i=0),
        card("Compare", "See it first", "Look at the same scenes in Photon before you decide.", ("features.html#compare", "Compare"), i=1),
        card("Honest", "How it was made", "Cornea is 100% AI-written, steered and tested in game by a person.", i=2),
    ])))

S.page("404.html", "Page not found · Cornea Shaders", DESC,
    hero("Error 404", "This page is <em>in the dark.</em>",
         "There's nothing at this address. It may have moved, or the link may have a typo.",
         btn("index.html", "Back to Cornea →", True) + btn("install.html", "Install guide →")),
    current="", head_top=BASE_SCRIPT)

print("built index.html, features.html, install.html, download.html and 404.html")
