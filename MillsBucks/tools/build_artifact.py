#!/usr/bin/env python3
"""Derive the Artifact-hosted build from web/index.html.

The Artifact host wraps page content in its own <!doctype>/<head>/<body>, so the
published file must contain content only. It also serves a single page, so the
manifest, the apple-touch-icon and the service worker have nothing to point at
and are dropped. Everything else — markup, styles, logic, localStorage — is the
same file the repo ships.

    python3 tools/build_artifact.py [outfile]
"""
import io
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "web" / "index.html"
OUT = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "build" / "artifact.html"

html = io.open(SRC, encoding="utf-8").read()


def grab(pattern, required=True):
    m = re.search(pattern, html, re.S)
    if not m and required:
        raise SystemExit(f"could not find {pattern!r} in {SRC}")
    return m.group(0) if m else ""


title = grab(r"<title>.*?</title>")
fonts = "\n".join(re.findall(r'<link rel="(?:preconnect|stylesheet)"[^>]*>', html))
style = grab(r"<style>.*?</style>")
body = grab(r"<body>(.*)</body>").removeprefix("<body>").removesuffix("</body>").strip()

# single hosted page: nothing for the service worker to register or cache
body, n = re.subn(
    r'if\("serviceWorker" in navigator\)\{.*?\n\}\n', "", body, count=1, flags=re.S)
if n != 1:
    raise SystemExit("service-worker registration block not found; check web/index.html")

parts = [title, fonts, style, "", body, ""]
OUT.parent.mkdir(parents=True, exist_ok=True)
io.open(OUT, "w", encoding="utf-8").write("\n".join(parts))

for tag in ("<!doctype", "<html", "<head", "<body", "rel=\"manifest\"", "apple-touch-icon", "serviceWorker"):
    if tag.lower() in io.open(OUT, encoding="utf-8").read().lower():
        raise SystemExit(f"artifact build still contains {tag!r}")

print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")
