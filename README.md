# Cornea website

The site for [Cornea Shaders](../../tree/main), built by one script.

- `build.py` holds every page's text and writes `index.html`, `features.html`, `install.html`, `download.html`, `transparency.html` and `404.html` (run `python build.py`).
- `sitekit.py` has the shared header/footer and the small page components (hero, cards, rows, FAQ, ...) that `build.py` uses.
- `site.css` is the shared stylesheet. The header is the only liquid-glass element (`liquid-glass.css` + `liquid-glass.js`).
- `chat.js` shows the chat log on the Transparency page.
- `python make_chatlog.py <session.jsonl>` exports the chat log shown on the Transparency page to `chat-log.json`.
- `python serve.py` serves the site locally, with the 404 page for unknown addresses.
- `downloads/Cornea-Shaders.zip` is the shaderpack the Download page links to.

To host it on GitHub Pages, serve the `website` branch from the root.
