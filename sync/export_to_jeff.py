#!/usr/bin/env python3
"""Book -> Jeff. Writes editable DOCX chapters into the shared folder.

    python3 sync/export_to_jeff.py            # only chapters that changed
    python3 sync/export_to_jeff.py --all      # re-export everything
    python3 sync/export_to_jeff.py 10-reliability.qmd

Code is NOT executed. Jeff receives the chapter source as prose plus literal
code blocks, so he can correct SPSS syntax in place and it comes back as text
we can find again. See sync/_common_sync.py for why a DOCX can never be turned
back into a .qmd, and what we do instead.
"""

import os
import shutil
import subprocess
import sys
from datetime import date

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _common_sync import (MD, OUTBOX, REPO, STATE, chapters, digest, git,
                          load_manifest, norm_lines, pandoc_to_text, save_manifest, sh)

PREAMBLE = """::: {{custom-style="Intro"}}
**{title}** — chapter source for review, exported {when}.

How to use this file: turn on Track Changes (Review > Track Changes) and edit
normally. Fix prose, fix code, leave comments — all three come back. The code
blocks below are the real source, not output, so a correction you make to SPSS
syntax here is the correction that lands in the book.

Do not renumber or reorder sections; everything else is fair game. Save the file
with the same name, in the same folder.
:::

"""


def export_one(qmd, manifest, force=False):
    src = os.path.join(REPO, qmd)
    stem = os.path.splitext(qmd)[0]
    docx = os.path.join(OUTBOX, stem + ".docx")
    qhash = digest(src)

    prev = manifest.get(qmd, {})
    if not force and prev.get("qmd_hash") == qhash and os.path.exists(docx):
        return "skip", None

    body = open(src, encoding="utf-8").read()
    title = stem.replace("-", " ").title()
    staged = os.path.join(STATE, "staged.md")
    os.makedirs(STATE, exist_ok=True)
    with open(staged, "w", encoding="utf-8") as fh:
        fh.write(PREAMBLE.format(title=title, when=date.today().isoformat()))
        fh.write(body)

    os.makedirs(OUTBOX, exist_ok=True)
    r = sh(["pandoc", "-f", MD, "-t", "docx", "--wrap=preserve",
            "--resource-path", REPO, staged, "-o", docx])
    if r.returncode != 0 or not os.path.exists(docx):
        return "fail", r.stderr.strip()[:200]

    # The baseline is the text of exactly what we shipped. Every later
    # comparison is against this, never against the .qmd.
    baseline = pandoc_to_text(docx)
    bdir = os.path.join(STATE, "baseline")
    os.makedirs(bdir, exist_ok=True)
    with open(os.path.join(bdir, stem + ".txt"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(norm_lines(baseline)))

    head = git("rev-parse", "--short", "HEAD").stdout.strip()
    manifest[qmd] = {
        "qmd_hash": qhash,
        "docx": os.path.relpath(docx, OUTBOX),
        "docx_hash": digest(docx),
        "exported": date.today().isoformat(),
        "book_commit": head,
    }
    return "ok", None


def main():
    args = [a for a in sys.argv[1:]]
    force = "--all" in args
    named = [a for a in args if a.endswith(".qmd")]

    if not shutil.which("pandoc"):
        sys.exit("pandoc is required and was not found on PATH.")

    todo = named or chapters()
    manifest = load_manifest()
    counts = {"ok": 0, "skip": 0, "fail": 0}
    fails = []

    for qmd in todo:
        status, err = export_one(qmd, manifest, force=force)
        counts[status] += 1
        if status == "ok":
            print(f"  exported  {qmd}")
        elif status == "fail":
            fails.append((qmd, err))

    save_manifest(manifest)
    print(f"\n{counts['ok']} exported, {counts['skip']} unchanged, {counts['fail']} failed")
    print(f"-> {OUTBOX}")
    for q, e in fails:
        print(f"  FAILED {q}: {e}")


if __name__ == "__main__":
    main()
