#!/usr/bin/env python3
"""Jeff -> book. Finds what Jeff changed in the DOCX chapters and lands it.

    python3 sync/import_from_jeff.py             # report only (default)
    python3 sync/import_from_jeff.py --apply     # write edits into the .qmd files
    python3 sync/import_from_jeff.py --apply --branch   # ...on a new git branch

Default is a dry run on purpose. This writes to the sources of a live book, so
the report comes first and the mutation is opt-in.

How a change is found
---------------------
Jeff's returned .docx is compared against the baseline text of the .docx we
exported to him -- Word text vs Word text. The .qmd is never parsed for the
comparison, so Quarto syntax cannot be misread. See sync/_common_sync.py.

How a change is landed
----------------------
Each changed line is located in the .qmd by whitespace-normalised match. It is
applied ONLY when it matches exactly one line. Ambiguous matches, multi-line
rewrites, insertions, and deletions are reported, never guessed. Word comments
are extracted separately and always reported, never applied.
"""

import difflib
import json
import os
import re
import sys
import zipfile
from datetime import date

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _common_sync import (OUTBOX, REPO, STATE, digest, git, load_manifest,
                          norm_lines, pandoc_to_text, save_manifest)

REPORT = os.path.join(OUTBOX, "JEFF-EDITS-REPORT.md")


def norm(s):
    return " ".join(s.split())


def unescape_md(s):
    """pandoc escapes markdown punctuation on the way out; undo for matching."""
    return re.sub(r"\\([\\`*_{}\[\]()#+\-.!$<>|~^])", r"\1", s)


def docx_comments(path):
    """Word comments, straight out of the package. pandoc drops these."""
    out = []
    try:
        with zipfile.ZipFile(path) as z:
            if "word/comments.xml" not in z.namelist():
                return out
            xml = z.read("word/comments.xml").decode("utf-8", "replace")
    except Exception:
        return out
    for m in re.finditer(r"<w:comment\b[^>]*?(?:w:author=\"([^\"]*)\")?[^>]*>(.*?)</w:comment>",
                         xml, re.S):
        author = m.group(1) or "unknown"
        text = " ".join(re.findall(r"<w:t[^>]*>(.*?)</w:t>", m.group(2), re.S))
        text = re.sub(r"\s+", " ", text).strip()
        if text:
            out.append({"author": author, "text": text})
    return out


def find_unique_line(qmd_lines, target):
    """Index of the single .qmd line matching target, or None."""
    for transform in (lambda s: norm(s), lambda s: unescape_md(norm(s))):
        want = transform(target)
        if len(want) < 4:
            return None
        hits = [i for i, ln in enumerate(qmd_lines) if transform(ln) == want]
        if len(hits) == 1:
            return hits[0]
        if len(hits) > 1:
            return None
    return None


def classify(qmd_lines, old, new):
    """Return (kind, index). kind in applied-candidate / ambiguous / not-found."""
    idx = find_unique_line(qmd_lines, old)
    if idx is None:
        return ("not_found", None)
    return ("ok", idx)


# pandoc normalises "2.  text" to "2. text". Rewriting the whole line would
# churn every list marker Jeff happens to touch and leave it inconsistent with
# its untouched neighbours, so keep the .qmd's own marker and swap only the prose.
MARKER = re.compile(r"^(\s*(?:[-*+]|\d+[.)])\s+)(.*)$")


def splice(qmd_line, new_text):
    """Put Jeff's text into the .qmd line, preserving its existing formatting."""
    m_old, m_new = MARKER.match(qmd_line), MARKER.match(new_text.strip())
    if m_old and m_new:
        return m_old.group(1) + m_new.group(2).strip()
    indent = re.match(r"^(\s*)", qmd_line).group(1)
    return indent + new_text.strip()


def is_code(line):
    return bool(re.match(r"^\s{4,}\S", line)) or line.strip().startswith("```")


def diff_chapter(baseline_lines, current_lines):
    """Yield structured changes between what we sent and what came back."""
    sm = difflib.SequenceMatcher(None, baseline_lines, current_lines, autojunk=False)
    changes = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        old = baseline_lines[i1:i2]
        new = current_lines[j1:j2]
        if tag == "replace" and len(old) == len(new):
            for o, n in zip(old, new):
                if norm(o) != norm(n):
                    changes.append({"kind": "replace", "old": o, "new": n})
        elif tag == "insert":
            changes.append({"kind": "insert", "old": None, "new": "\n".join(new),
                            "after": baseline_lines[i1 - 1] if i1 else None})
        elif tag == "delete":
            changes.append({"kind": "delete", "old": "\n".join(old), "new": None})
        else:
            changes.append({"kind": "rewrite", "old": "\n".join(old), "new": "\n".join(new)})
    return changes


def main():
    apply_ = "--apply" in sys.argv
    branch = "--branch" in sys.argv
    manifest = load_manifest()
    if not manifest:
        sys.exit("No manifest. Run sync/export_to_jeff.py first.")

    findings, touched = [], []

    for qmd, rec in sorted(manifest.items()):
        stem = os.path.splitext(qmd)[0]
        docx = os.path.join(OUTBOX, rec["docx"])
        if not os.path.exists(docx):
            continue
        if digest(docx) == rec.get("docx_hash"):
            continue  # untouched since we sent it

        bpath = os.path.join(STATE, "baseline", stem + ".txt")
        if not os.path.exists(bpath):
            findings.append({"qmd": qmd, "error": "no baseline; re-export this chapter"})
            continue

        baseline = open(bpath, encoding="utf-8").read().splitlines()
        try:
            returned = norm_lines(pandoc_to_text(docx, track_changes="accept"))
        except RuntimeError as e:
            findings.append({"qmd": qmd, "error": str(e)})
            continue

        changes = diff_chapter(baseline, returned)
        comments = docx_comments(docx)
        if not changes and not comments:
            continue

        qpath = os.path.join(REPO, qmd)
        qlines = open(qpath, encoding="utf-8").read().splitlines()
        applied, blocked = [], []

        for ch in changes:
            if ch["kind"] != "replace":
                blocked.append(ch)
                continue
            kind, idx = classify(qlines, ch["old"], ch["new"])
            if kind != "ok":
                ch["why"] = ("that line is not in the .qmd (it may be generated output, "
                             "or Jeff rewrote it beyond recognition)"
                             if kind == "not_found" else "matches more than one line")
                blocked.append(ch)
                continue
            ch["line"] = idx + 1
            ch["code"] = is_code(qlines[idx])
            applied.append((idx, ch))

        if apply_ and applied:
            for idx, ch in applied:
                qlines[idx] = splice(qlines[idx], ch["new"])
            with open(qpath, "w", encoding="utf-8") as fh:
                fh.write("\n".join(qlines) + "\n")
            touched.append(qmd)
            rec["docx_hash"] = digest(docx)
            rec["last_import"] = date.today().isoformat()

        findings.append({
            "qmd": qmd, "docx": rec["docx"],
            "applied": [c for _, c in applied],
            "blocked": blocked, "comments": comments,
        })

    write_report(findings, apply_, touched)

    if apply_ and touched:
        save_manifest(manifest)
        if branch:
            b = f"jeff-edits/{date.today().isoformat()}"
            git("checkout", "-B", b)
            git("add", *touched)
            git("commit", "-m",
                f"Fold in Jeff's chapter edits ({len(touched)} chapters)\n\n"
                "Applied by sync/import_from_jeff.py from the DOCX round trip.\n"
                "Only unambiguous single-line matches were applied; everything\n"
                "else is listed in Book Chapters/JEFF-EDITS-REPORT.md.")
            print(f"\nCommitted on branch {b}")


def write_report(findings, applied_mode, touched):
    n_app = sum(len(f.get("applied", [])) for f in findings)
    n_blk = sum(len(f.get("blocked", [])) for f in findings)
    n_com = sum(len(f.get("comments", [])) for f in findings)

    with open(REPORT, "w", encoding="utf-8") as fh:
        fh.write("# Jeff's edits\n\n")
        fh.write(f"*Generated {date.today().isoformat()} by `sync/import_from_jeff.py`.*\n\n")
        if not findings:
            fh.write("No changed chapters. Every DOCX matches what was exported.\n")
        else:
            fh.write(f"- **{n_app}** edits matched a single line and "
                     f"{'were applied' if applied_mode else 'are ready to apply'}\n")
            fh.write(f"- **{n_blk}** need a human\n")
            fh.write(f"- **{n_com}** Word comments (never applied automatically)\n\n")
            if not applied_mode:
                fh.write("This was a dry run. Re-run with `--apply` to write them in.\n\n")
            fh.write("---\n")

        for f in findings:
            if f.get("error"):
                fh.write(f"\n## {f['qmd']}\n\n**Could not read:** {f['error']}\n")
                continue
            if not (f["applied"] or f["blocked"] or f["comments"]):
                continue
            fh.write(f"\n## {f['qmd']}\n\n")
            if f["applied"]:
                fh.write(f"### Clean edits ({len(f['applied'])})\n\n")
                for c in f["applied"]:
                    tag = " *(code)*" if c.get("code") else ""
                    fh.write(f"- **line {c['line']}**{tag}\n"
                             f"  - was: `{c['old'][:200]}`\n"
                             f"  - now: `{c['new'][:200]}`\n")
            if f["blocked"]:
                fh.write(f"\n### Needs you ({len(f['blocked'])})\n\n")
                for c in f["blocked"]:
                    fh.write(f"- **{c['kind']}**"
                             + (f" — {c['why']}" if c.get("why") else "") + "\n")
                    if c.get("old"):
                        fh.write(f"  - was: `{c['old'][:300]}`\n")
                    if c.get("new"):
                        fh.write(f"  - Jeff wrote: `{c['new'][:300]}`\n")
            if f["comments"]:
                fh.write(f"\n### Comments ({len(f['comments'])})\n\n")
                for c in f["comments"]:
                    fh.write(f"- **{c['author']}:** {c['text']}\n")

    print(f"{n_app} applicable, {n_blk} need review, {n_com} comments")
    if applied_mode:
        print(f"applied to {len(touched)} chapter(s)")
    else:
        print("dry run — nothing written. Re-run with --apply")
    print(f"report: {REPORT}")


if __name__ == "__main__":
    main()
