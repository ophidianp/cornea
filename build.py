"""Builds the Cornea website from this file: run `python build.py`.

Writes index.html, features.html, install.html, download.html, transparency.html and
404.html. Each page's text lives below; the shared header/footer and the small
components (hero, cards, rows, FAQ...) come from sitekit.py, and the styles from
site.css. The header is the only liquid-glass element (liquid-glass.css + .js).

Set SITE_BASE (e.g. SITE_BASE=/cornea/) if the site lives in a sub-folder, so 404.html
can find its images and links from any missing URL.
"""
import os
from sitekit import Site, hero, btn, head, section, card, grid, rows, steps, faq, tags, cta, chatlog, stats

here = os.path.dirname(os.path.abspath(__file__))
site_base = os.environ.get("SITE_BASE", "")
DESC = ("Cornea is an Iris shaderpack for Minecraft 26.x with volumetric clouds, coloured light and soft shadows, "
        "tuned to run well on mid-range graphics cards.")
# 404.html is served for any missing address, so it sets a <base> to find its files.
BASE_SCRIPT = ("<script>(function(){var b=%s;if(!b){var h=location.hostname,s=location.pathname.split('/')[1];"
               "b=(/\\.github\\.io$/.test(h)&&s&&s.indexOf('.')<0)?'/'+s+'/':'/';}"
               "document.write('<base href=\"'+b+'\">');})();</script>\n") % (repr(site_base) if site_base else "''")

S = Site(here, "Cornea", "img/icon.png",
         [("index.html", "Home"), ("features.html", "Features"), ("install.html", "Install"), ("transparency.html", "Transparency")],
         '&copy; Pavan Nemani · All Rights Reserved (ARR) · Not affiliated with Mojang or Microsoft. · '
         '<a href="https://modrinth.com/mod/iris">Iris ↗</a> <a href="https://ophidianp.github.io/chlorine">Chlorine ↗</a>',
         css="site.css?v=5", glass_css="liquid-glass.css?v=2", glass_js="liquid-glass.js?v=2", cta=("download.html", "Get Cornea"))

S.page("index.html", "Cornea Shaders", DESC,
    hero("Iris shaderpack · <b>Minecraft 26.x</b>", "Light the world.<br><em>Keep your frames.</em>",
         "Cornea brings volumetric clouds, coloured light and soft shadows to Minecraft, tuned to run well on mid-range graphics cards.",
         btn("download.html", "Download for 26.3 ↓", True) + btn("features.html#compare", "Compare with Photon →"),
         "For Iris · Minecraft 26.x · Free to use",
         '<figure style="margin-top:56px"><img src="img/cmp-2-cornea.webp" alt="Cornea, a river valley seen from high above" width="1600" height="900"><figcaption>Cornea · river valley from above · Overworld, day</figcaption></figure>')
    + section("What Cornea adds", "Every effect, <em>tuned to stay fast.</em>", "", grid([
        card("Sky", "Volumetric clouds", "<p></p>"), card("Light", "Coloured torchlight", "<p></p>"), card("Shadow", "Soft penumbras", "<p></p>"),
        card("Sky", "Godrays", "<p></p>"), card("Water", "Caustics", "<p></p>"), card("Night", "Auroras", "<p></p>"),
        card("End", "A black hole", "<p></p>"), card("Blocks", "Built-in shine", "<p></p>"), card("Plants", "Grass that moves aside", "<p></p>"),
    ]))
    + section("Explore", "Look, compare, <em>install.</em>", "", grid([
        card("Look", "See what it does", "Coloured torchlight, soft shadows, two cloud layers and water you can see into.", ("features.html", "Features")),
        card("Versus", "Side by side", "Seven scenes from the Overworld, Nether and End, shot in the same spot with Cornea and Photon.", ("features.html#compare", "Compare")),
        card("Setup", "Three steps", "Add Iris and Sodium, drop in the zip, pick a profile. That is all of it.", ("install.html", "Install")),
    ]))
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
pairs = '<div class="pairs">\n' + "\n".join(f"""<figure class="pair">
  <figcaption>{t} <span>· {tag}</span></figcaption>
  <div><img src="img/cmp-{i}-cornea.webp" alt="Cornea, {alt}" loading="lazy"><small>Cornea</small></div>
  <div><img src="img/cmp-{i}-photon.webp" alt="Photon, {alt}" loading="lazy"><small>Photon</small></div>
</figure>""" for i, (t, tag, alt) in enumerate(SCENES, 1)) + "\n</div>\n"

S.page("features.html", "Features · Cornea Shaders", DESC,
    hero("What you see", "Photon's mood, <em>on a smaller budget.</em>",
         "Cornea aims for the warm, soft look of the big shaderpacks and spends its frame time where your eye lands first: the light near you, the sky above you, and the water in front of you.")
    + section("", "", "", grid([
        card("Light", "Light that has a colour", "Torches glow orange, soul fire glows blue and amethyst tints a cave purple. Light spreads through the blocks around you, and nearby blocks and mobs cast short shadows from it."),
        card("Sky", "A sky worth looking up at", "Two layers of volumetric clouds with thin cirrus above them, auroras on clear nights, and in the End, a black hole that bends the starlight around it."),
        card("Water", "Water you can see into", "Uneven waves that never line up in rows, caustics dancing on the seabed and godrays under the surface. A torch or lava pool lights the water from below."),
    ]), "features").replace('class="wrap section"', 'class="wrap" style="padding-top:56px"', 1)
    + section("Side by side", "Same spot. <em>Two shaderpacks.</em>",
        "Each pair was shot from the same place, with Cornea on the left and Photon on the right. Photon is made by SixthSurge and is shown here only for comparison.", pairs, "compare")
    + '<section class="wrap section split" style="align-items:start" id="inside">\n' + head("Under the hood", "Where the frames <em>come from.</em>",
        "Most of Cornea's speed comes from doing expensive work less often, at lower resolution, and only when it shows.")
    + rows([
        ("A · Sky", "<h3>Half-size clouds and light shafts</h3><p>Clouds and godrays render at half resolution and fill in over a few frames, so they cost about a quarter of the pixels.</p>"),
        ("B · Light", "<h3>Light that spreads a step at a time</h3><p>Coloured light flows one block per frame through a 96-block volume around you, instead of being solved from scratch every frame.</p>"),
        ("C · Camera", "<h3>Exposure from the light, not the screen</h3><p>The camera sets its brightness from how much sun and sky reach you, so there's no costly average of the whole picture.</p>"),
        ("D · Blocks", "<h3>Shine built into the pack</h3><p>Metals, polished stone, gems and glowing ores get their gloss and surface detail from Cornea itself. No resource pack, no extra textures to read.</p>"),
        ("E · Settings", "<h3>Off really means off</h3><p>Every effect drops out of the shader when you switch it off, so the Low profile does less work, not just less drawing.</p>"),
    ]) + "</section>\n"
    + '<section class="wrap section split">\n' + head("Works with", "Made for the setup <em>you already run.</em>",
        "Cornea needs Iris, and Iris needs Sodium, so install both. It is built and tested on Minecraft 26.x, including clients that bundle them such as OneClient.")
    + card("Compatibility", "", "<p>Crossed out: not supported yet. Cornea skips far-distance terrain to keep its frame budget for what's close to you.</p>",
           extra='<ul class="tags"><li class="on">Iris · required</li><li class="on">Sodium · required</li><li>Minecraft 26.x</li><li>OneClient</li><li>Chlorine</li><li class="off">Distant Horizons</li><li class="off">Voxy</li></ul>')
    + "</section>\n"
    + cta("Take Cornea <em>with you.</em>", "One zip works in every dimension. It needs Iris and Sodium.", btn("download.html", "Download Cornea ↓", True)))

S.page("install.html", "Install · Cornea Shaders", DESC,
    hero("Install", "Three steps <em>to a new sky.</em>", "Cornea is a normal Iris shaderpack. If you've installed one before, you already know how.")
    + section("", "", "", steps([
        ("Install Iris and Sodium", 'Add <a href="https://modrinth.com/mod/iris">Iris</a> and <a href="https://modrinth.com/mod/sodium">Sodium</a> to your Minecraft 26.x instance. Iris needs Sodium to run, so you need both.'),
        ("Add Cornea", "Drop <code>Cornea Shaders.zip</code> into the <code>shaderpacks</code> folder. Leave it zipped."),
        ("Pick a profile", "Open Video Settings, then Shader Packs, select Cornea and choose Low, Medium, High or Ultra."),
    ]), "install").replace('class="wrap section"', 'class="wrap" style="padding-top:56px"', 1)
    + '<section class="wrap section split" style="align-items:start">\n' + head("Good to know", "A few quick <em>answers.</em>", hid="faq-title") + faq([
        ("Do I need a resource pack?", "No. Shine, surface detail and glowing ores are built in and work with the default textures."),
        ("Is Cornea a version of Photon?", "No. Cornea is a separate pack that aims for a similar warm, soft look. Photon is made by SixthSurge, and its screenshots here are only for comparison."),
        ("Why are there no sun shadows in the Nether?", "The Nether has no sun or moon, so there's nothing to cast them. Lava, fire and glowstone still light the world in colour, and nearby blocks still block that light."),
        ("What hardware was it tuned on?", "A Ryzen 5 5500 with a 4 GB RX 6500 XT and 16 GB of memory. If you have a slower card, start with the Medium profile and turn up what you miss."),
        ("Something looks wrong. What should I send?", "A screenshot, the profile you're using, and the Iris error log if the pack fails to load. That's usually enough to find the cause."),
    ]) + "</section>\n"
    + cta("Ready when <em>you are.</em>", "Grab the zip, or read how Cornea was made first.",
          btn("download.html", "Go to the download →", True) + btn("transparency.html", "How it was made →")))

S.page("download.html", "Download · Cornea Shaders", DESC,
    hero("Download", "Take Cornea <em>with you.</em>", "One zip works in every dimension. It needs Iris and Sodium, and it has not been tested on every setup yet.")
    + f"""<section class="wrap" style="padding-top:48px" id="download">
<div class="card" style="padding:clamp(24px,4vw,40px)">
  <p class="label">Ready when you are</p>
  <p class="serif" id="download-title">Open your eyes to a softer Minecraft.</p>
  <p>One zip, every dimension. Drop it into your shaderpacks folder and pick a profile.</p>
  <div class="actions" style="margin-top:20px"><a class="btn primary" href="downloads/Cornea-Shaders.zip" download>Download Cornea ↓</a></div>
  <p class="fine" style="margin-top:14px">Cornea Shaders.zip · Iris · Minecraft 26.x</p>
</div>
</section>
"""
    + section("Before and after", "Know what <em>you're getting.</em>", "", grid([
        card("First", "What you need", "Minecraft 26.x with Iris and Sodium. Cornea runs best on the Medium profile and up to Ultra.", ("install.html", "Install guide")),
        card("Compare", "See it first", "Look at the same scenes in Photon before you decide.", ("features.html#compare", "Compare")),
        card("Honest", "How it was made", "Cornea is 100% AI-written. Read how, and see the full conversation.", ("transparency.html", "Transparency")),
    ])))

S.page("transparency.html", "Transparency · Cornea Shaders", DESC,
    hero("Transparency", "Made by AI, <em>start to finish.</em>",
         "Every line of Cornea's shader code, this website and all of its text was written by AI. A person steered it, tested it in game and made the calls. This page says exactly what that means.")
    + section("", "", "", grid([
        card("100%", "Written entirely by AI", "The shaders, the settings menus, the build tools, this site and its copy. <strong>Nothing was written by hand.</strong> You can read the whole conversation at the bottom of this page."),
        card("Models", "Claude Opus 5.5 and Sonnet 5.5", 'Both ran through Claude Code. In the log below, <span id="n-opus">Opus</span> and <span id="n-sonnet">Sonnet</span> wrote the replies, and each one is labelled with the model that wrote it.'),
        card("Human", "One person steering", "A person set the goals, sent screenshots, tested in game on a Ryzen 5 5500 and an RX 6500 XT, and decided what to keep. The AI can't see the game, so tuning followed that feedback."),
    ])).replace('class="wrap section"', 'class="wrap" style="padding-top:56px"', 1)
    + section("Where it comes from", "Inspired by Photon. <em>Not Photon.</em>",
        "Cornea chases the warm, soft look of Photon by SixthSurge. Here is how close the two really are, and where the line sits.", rows([
        ("A · Goal", "<h3>Photon was the target</h3><p>The goal was Photon's mood at a higher frame rate on a modest card. The comparison screenshots on the Features page are Photon, shown only so you can judge for yourself.</p>"),
        ("B · Study", "<h3>Its source was read as a reference</h3><p>The AI studied Photon's shader files to learn techniques such as the sky look-up table, the light volume for coloured torches, soft shadows and temporal anti-aliasing. Photon's licence allows examining and learning from its source.</p>"),
        ("C · Code", "<h3>The code was written fresh</h3><p>Cornea's files were written new, with their own structure and many different choices, and no Photon file was copied in. But reading Photon shaped the design, so the two share ideas and some layout. We can't promise no passage ever resembles it.</p>"),
        ("D · Sharing", "<h3>Only on this site, for now</h3><p>Cornea is not on Modrinth, because it is AI-generated work. A CurseForge release may come later, but not yet, so this site is the only place to get it.</p>"),
        ("E · Status", "<h3>Checked, but young</h3><p>Every program was compile-checked in several setting combinations and the author tested it in game. It is new, so expect rough edges and report what you find.</p>"),
    ]), "photon-title")
    + section("The receipts", "The whole <em>conversation.</em>",
        "From the first message to the request for this page. Only what was said in the chat is shown: tool use is left out, and file paths, local addresses and emails are masked. It reads like a messaging app, but you can't reply.",
        chatlog("Claude Code · Cornea") + '<p class="fine" style="margin-top:14px">Not affiliated with SixthSurge, Mojang, Microsoft or Anthropic.</p>\n', "log-title"),
    scripts=("chat.js?v=2",))

S.page("404.html", "Page not found · Cornea Shaders", DESC,
    hero("Error 404", "This page is <em>in the dark.</em>",
         "There's nothing at this address. It may have moved, or the link may have a typo.",
         btn("index.html", "Back to Cornea →", True) + btn("install.html", "Install guide →")),
    current="", head_top=BASE_SCRIPT)

print("built index.html, features.html, install.html, download.html, transparency.html and 404.html")
