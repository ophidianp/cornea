# Cornea website

The site for [Cornea Shaders](../../tree/main), built by one script. The design matches the
[Mouse 33 site](https://ophidianp.github.io/mouse33/), in Cornea's teal.

- `build.py` holds every page's text and writes `index.html`, `features.html`, `install.html`, `download.html`, `transparency.html` and `404.html` (run `python -I build.py`).
- `sitekit.py` has the shared page shell (header, preloader, footer) and the page components (hero, cards, spec grid, pinned feature stage, FAQ, ...) that `build.py` uses.
- `site.css` is the shared stylesheet (light and dark themes). `site.js` runs the theme toggle, the header, the phone menu, the pinned stage, the preloader and the FAQ.
- `brand/logo_gen.py` draws the "cornea" wordmark: a flat pen nib swept along Bezier centrelines, unioned into one piece and slanted 44°. `python -I brand/make_assets.py` writes `brand/logo.svg` (used by the site as a mask), `favicon.svg`, `apple-touch-icon.png` and `og.png`.
- `chat.js` shows the chat log on the Transparency page.
- `python make_chatlog.py <session.jsonl>` exports the chat log shown on the Transparency page to `chat-log.json`.
- `python serve.py` serves the site locally, with the 404 page for unknown addresses.
- `downloads/Cornea-Shaders.zip` is the shaderpack the Download page links to.

To host it on GitHub Pages, serve the `website` branch from the root.
