"""Shared plumbing for the Jeff DOCX round trip.

The one design constraint worth knowing before changing anything here:

    A DOCX cannot be turned back into a .qmd.

That was measured, not assumed. Round-tripping 10-reliability.qmd through
pandoc collapses fenced divs 24 -> 2, callouts 3 -> 0, panel-tabsets 7 -> 1,
and drops chunk options entirely. Reconstructing chapter sources from Word
would quietly destroy the four-language tabs.

So the sync never reconstructs. It exports a DOCX, keeps the exact text of
what it exported, and later diffs Jeff's returned file against *that baseline*.
The comparison is therefore Word-text vs Word-text and never has to understand
Quarto at all. Edits are then applied to the .qmd by unique string match, and
anything that is not unambiguous is reported instead of guessed.
"""

import hashlib
import json
import os
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHARED = os.environ.get(
    "JEFF_SHARED_DIR",
    os.path.expanduser("~/Google_SharedWithMe/Patrick & Jeff"),
)
OUTBOX = os.path.join(SHARED, "Book Chapters")
STATE = os.path.join(REPO, ".jeff-sync")

# tex_math_dollars OFF on purpose: it misreads "$" in R/dplyr code as math, and
# a Word equation cannot come back as $$...$$. Left literal, math survives.
MD = "markdown-tex_math_dollars+fenced_divs+pipe_tables+backtick_code_blocks"


def sh(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def pandoc_to_text(docx_path, track_changes="accept"):
    """DOCX -> normalised markdown text, for diffing."""
    r = sh(["pandoc", "-f", "docx", "-t", MD, "--wrap=none",
            f"--track-changes={track_changes}", docx_path])
    if r.returncode != 0:
        raise RuntimeError(f"pandoc failed on {docx_path}: {r.stderr.strip()[:300]}")
    return r.stdout


def norm_lines(text):
    """Comparable, non-empty lines. Word reflows whitespace; we do not care."""
    out = []
    for ln in text.splitlines():
        s = " ".join(ln.split())
        if s:
            out.append(s)
    return out


def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for block in iter(lambda: fh.read(65536), b""):
            h.update(block)
    return h.hexdigest()[:16]


def load_manifest():
    p = os.path.join(STATE, "manifest.json")
    if os.path.exists(p):
        with open(p, encoding="utf-8") as fh:
            return json.load(fh)
    return {}


def save_manifest(m):
    os.makedirs(STATE, exist_ok=True)
    with open(os.path.join(STATE, "manifest.json"), "w", encoding="utf-8") as fh:
        json.dump(m, fh, indent=1, sort_keys=True)


def chapters():
    """Chapter .qmd files, in book order, from _quarto.yml."""
    y = os.path.join(REPO, "_quarto.yml")
    names, seen = [], set()
    with open(y, encoding="utf-8") as fh:
        for ln in fh:
            s = ln.strip()
            if s.startswith("- ") and s.endswith(".qmd"):
                n = s[2:].strip()
                if n not in seen and os.path.exists(os.path.join(REPO, n)):
                    seen.add(n)
                    names.append(n)
    return names


def git(*args):
    return sh(["git", "-C", REPO] + list(args))
