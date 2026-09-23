#!/usr/bin/env python3
"""End-of-day sweep of the shared folder: what arrived, what changed, what is unhandled.

    python3 sync/daily_scan.py            # report
    python3 sync/daily_scan.py --quiet    # only speak up if something needs attention

Jeff works in the Drive folder, not in git. He edits chapter DOCX files, drops in
lecture recordings, transcripts and test material, and he is teaching from the
published book while he does it. Things therefore arrive without anyone saying so.

This answers one question: since the last sweep, what showed up or changed, and has
anything been done about it? It never modifies the book. Chapter edits are handed to
sync/import_from_jeff.py, which itself defaults to reporting rather than writing.

State lives in .jeff-sync/scan-state.json (gitignored, rebuildable). First run has no
prior state, so everything reads as new — that is correct, not a bug.
"""

import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "sync"))
from _common_sync import OUTBOX, SHARED, STATE  # noqa: E402

SCAN_STATE = os.path.join(STATE, "scan-state.json")
LOGDIR = os.path.join(SHARED, "Scans")

# Directories whose contents are Drive's business, not ours: very large media that
# we neither process nor want to hash on every sweep.
SKIP_DIRS = {".git", "Meeting Transcripts", "Lecture Recordings", "node_modules",
             "Scans"}
SKIP_EXT = {".tmp", ".crdownload", ".part"}

# Our own outputs. Without these the sweep reports its own churn and never goes
# quiet, which would train everyone to ignore it.
SKIP_FILES = {"JEFF-EDITS-REPORT.md"}


def walk():
    """Every file in the shared folder we care about, with size and mtime."""
    seen = {}
    for root, dirs, files in os.walk(SHARED):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        for f in files:
            if (f.startswith(".") or f in SKIP_FILES
                    or os.path.splitext(f)[1].lower() in SKIP_EXT):
                continue
            p = os.path.join(root, f)
            try:
                st = os.stat(p)
            except OSError:
                continue
            seen[os.path.relpath(p, SHARED)] = {"size": st.st_size,
                                                "mtime": int(st.st_mtime)}
    return seen


def digest(path, cap=4_000_000):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        h.update(fh.read(cap))
    return h.hexdigest()[:16]


def load():
    try:
        return json.load(open(SCAN_STATE, encoding="utf-8"))
    except Exception:
        return {"files": {}, "last": None}


def chapter_edits():
    """Ask the importer whether Jeff changed any chapters. Dry run, always."""
    r = subprocess.run([sys.executable, os.path.join(REPO, "sync", "import_from_jeff.py")],
                       capture_output=True, text=True, cwd=REPO)
    head = (r.stdout or r.stderr).strip().splitlines()
    return head[0] if head else "(importer produced no output)"


def main():
    quiet = "--quiet" in sys.argv
    if not os.path.isdir(SHARED):
        sys.exit(f"shared folder not found: {SHARED}")

    prev = load()
    old, cur = prev["files"], walk()

    new = sorted(k for k in cur if k not in old)
    changed = sorted(k for k in cur
                     if k in old and (cur[k]["size"] != old[k]["size"]
                                      or cur[k]["mtime"] != old[k]["mtime"]))
    gone = sorted(k for k in old if k not in cur)

    edits = chapter_edits()
    needs_attention = bool(new or changed or gone) or "0 applicable, 0 need review" not in edits

    if quiet and not needs_attention:
        return

    when = datetime.now().replace(microsecond=0)
    lines = [f"# Shared-folder sweep — {when.isoformat(sep=' ')}", ""]
    lines.append(f"Since: {prev['last'] or 'never (first sweep — everything reads as new)'}")
    lines.append("")
    lines.append(f"**Chapter edits:** {edits}")
    lines.append("")
    for label, items in (("New", new), ("Changed", changed), ("Removed", gone)):
        lines.append(f"## {label} ({len(items)})")
        if not items:
            lines.append("_none_")
        for k in items[:60]:
            lines.append(f"- `{k}`")
        if len(items) > 60:
            lines.append(f"- …and {len(items) - 60} more")
        lines.append("")

    if not needs_attention:
        lines.append("Nothing to do. Everything in the folder matches the last sweep.")

    report = "\n".join(lines)
    os.makedirs(LOGDIR, exist_ok=True)
    out = os.path.join(LOGDIR, f"{when.date().isoformat()}.md")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(report + "\n")

    print(report)
    print(f"\n-> {out}")

    os.makedirs(STATE, exist_ok=True)
    json.dump({"files": cur, "last": when.isoformat(sep=" ")},
              open(SCAN_STATE, "w", encoding="utf-8"))


if __name__ == "__main__":
    main()
