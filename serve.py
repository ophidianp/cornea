"""Local preview server: like `python -m http.server`, but unknown paths get 404.html.

    python serve.py [port]
"""
import http.server
import os
import sys

root = os.path.dirname(os.path.abspath(__file__))


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=root, **k)

    def send_error(self, code, message=None, explain=None):
        if code == 404:
            try:
                body = open(os.path.join(root, "404.html"), "rb").read()
            except OSError:
                return super().send_error(code, message, explain)
            self.send_response(404)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(body)
            return
        super().send_error(code, message, explain)


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    http.server.ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
