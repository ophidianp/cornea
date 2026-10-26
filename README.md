# Cornea website

The site for [Cornea Shaders](../../tree/main), built from one source file.

- `page.html` holds the styles, sections and script once.
- `python build.py` writes `index.html`, `features.html`, `install.html`, `download.html`, `transparency.html` and `404.html`.
- `python make_chatlog.py <session.jsonl>` exports the chat log shown on the Transparency page to `chat-log.json`.
- `python serve.py` serves the site locally, with the 404 page for unknown addresses.
- `downloads/Cornea-Shaders.zip` is the shaderpack the Download page links to.

To host it on GitHub Pages, serve the `website` branch from the root.
