#!/usr/bin/env python3
"""Baton-passing between the two agents working this repo.

    python3 sync/handoff.py status
    python3 sync/handoff.py claim   "rewriting the ch09 power tab"
    python3 sync/handoff.py release "ch09 rewritten, rendered clean, not pushed"

Deliberately not a lock. Two agents driven by one person cannot be serialised by
software, and pretending otherwise would just add a file to delete when it goes
stale. What this does is make the state legible: who touched it last, when, what
they claim is true now, and what is unfinished. Everything else is Pat saying
"go" to one window at a time.

Set AGENT=codex (or anything) to sign as someone else. Defaults to claude.
"""

import os
import re
import subprocess
import sys
from datetime import datetime, timedelta

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(REPO, "HANDOFF.md")
STALE = timedelta(hours=4)
AGENT = os.environ.get("AGENT", "claude")
MARK = "<!-- newest first; sync/handoff.py writes here -->"


def now():
    return datetime.now().replace(microsecond=0)


def git(*a):
    r = subprocess.run(["git", "-C", REPO, *a], capture_output=True, text=True)
    return r.stdout.strip()


def entries(text):
    """Parsed log entries, newest first."""
    out = []
    for m in re.finditer(r"^- \*\*(CLAIM|RELEASE)\*\* `([^`]+)` +(\S+) +— (.*)$", text, re.M):
        kind, when, who, what = m.groups()
        try:
            ts = datetime.fromisoformat(when)
        except ValueError:
            continue
        out.append({"kind": kind, "at": ts, "who": who, "what": what})
    return out


def holder(text):
    """Who holds the baton, or None. A CLAIM with no later RELEASE."""
    for e in entries(text):
        if e["kind"] == "RELEASE":
            return None
        if e["kind"] == "CLAIM":
            return e
    return None


def write(kind, what):
    text = open(DOC, encoding="utf-8").read()
    head = git("rev-parse", "--short", "HEAD")
    dirty = " (uncommitted changes present)" if git("status", "--porcelain") else ""
    line = (f"- **{kind}** `{now().isoformat(sep=' ')}` {AGENT} — {what} "
            f"[at {head}{dirty}]")
    if MARK not in text:
        text = text.rstrip() + "\n\n## Log\n\n" + MARK + "\n"
    text = text.replace(MARK, MARK + "\n" + line, 1)
    open(DOC, "w", encoding="utf-8").write(text)
    print(f"  {kind} recorded as {AGENT}")


def main():
    if not os.path.exists(DOC):
        sys.exit(f"{DOC} not found")
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    msg = " ".join(sys.argv[2:]).strip()
    text = open(DOC, encoding="utf-8").read()
    h = holder(text)

    if cmd == "status":
        if not h:
            print("  baton is FREE")
        else:
            age = now() - h["at"]
            state = "STALE, take it" if age > STALE else "held"
            print(f"  {state}: {h['who']} since {h['at']} ({age} ago)")
            print(f"     {h['what']}")
        last = entries(text)[:3]
        for e in last:
            print(f"  · {e['at']} {e['kind']:7} {e['who']}: {e['what'][:70]}")
        return

    if cmd not in ("claim", "release"):
        sys.exit("usage: handoff.py [status|claim|release] \"message\"")
    if not msg:
        sys.exit(f"say what you are about to do:  handoff.py {cmd} \"...\"")

    if cmd == "claim" and h and h["who"] != AGENT:
        age = now() - h["at"]
        if age <= STALE:
            print(f"  WARNING: {h['who']} claimed it {age} ago — {h['what']}")
            print("  Claiming anyway; say in your message that you took it over.")
    write(cmd.upper(), msg)


if __name__ == "__main__":
    main()
