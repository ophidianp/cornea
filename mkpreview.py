"""Makes preview/ for the claude.ai artifact: same pages, no zip link (downloads are blocked there),
and index.html as a fragment because the artifact tool adds the document shell itself."""
import os, re
here = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(here, "preview"); os.makedirs(out, exist_ok=True)
dl = re.compile(r'<a class="btn btn-primary" href="downloads/Cornea-Shaders.zip" download>.*?</small>', re.S)
new = ('<a class="btn btn-primary" href="install.html">How to install <span class="arrow">→</span></a>\n'
       '          <small>The download is on the hosted site, not in this preview.</small>')
for f in ("index.html", "features.html", "install.html", "download.html", "transparency.html"):
    s = open(os.path.join(here, f), encoding="utf-8").read()
    s = dl.sub(new, s)
    if f == "index.html":
        s = s[s.index("<title>"):]
        s = re.sub(r"</head>\s*<body[^>]*>\n", "\n", s, count=1)
        s = s.replace("</body>\n</html>\n", "")
    open(os.path.join(out, f), "w", encoding="utf-8", newline="\n").write(s)
print("preview ready")
