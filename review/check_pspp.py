"""Check executable SPSS tabs with PSPP's IBM-compatible syntax mode.

Run: python3 review/check_pspp.py
Exit 1 if a chunk reports an error. IBM-only static tabs are intentionally skipped.
This check cannot certify that the syntax executes in IBM SPSS Statistics.
"""

from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
CHAPTER = re.compile(r"^\s+-\s+([\w-]+\.qmd)\s*$", re.MULTILINE)
OPEN = re.compile(r"^```\{pspp(?=[\s}])")
DIAGNOSTIC = re.compile(r"(?:^|\n)[^\n]*\berror:\s*[^\n]*", re.I)


def blocks(path: Path):
    """Yield source line and code for each PSPP chunk that Quarto executes."""
    lines = path.read_text(encoding="utf-8").splitlines()
    for index, line in enumerate(lines):
        if not OPEN.match(line):
            continue
        end = next(
            (j for j in range(index + 1, len(lines)) if lines[j].strip() == "```"),
            len(lines),
        )
        body = lines[index + 1 : end]
        if any(re.match(r"^#\|\s*eval:\s*false\s*$", item, re.I) for item in body):
            continue
        yield index + 1, "\n".join(item for item in body if not item.startswith("#|")) + "\n"


def main() -> int:
    chapters = CHAPTER.findall((ROOT / "_quarto.yml").read_text(encoding="utf-8"))
    checked = failures = 0
    with tempfile.TemporaryDirectory(prefix="book-pspp-audit-") as scratch:
        scratch = Path(scratch)
        for chapter in chapters:
            for line, code in blocks(ROOT / chapter):
                checked += 1
                source = scratch / f"chunk-{checked}.sps"
                output = scratch / f"chunk-{checked}.txt"
                source.write_text(code, encoding="utf-8")
                result = subprocess.run(
                    ["pspp", "--syntax=compatible", "--no-output", "-o", str(output),
                     "-O", "format=txt", str(source)],
                    cwd=ROOT, capture_output=True, text=True, check=False,
                )
                report = result.stdout + result.stderr
                if output.exists():
                    report += output.read_text(encoding="utf-8", errors="replace")
                errors = DIAGNOSTIC.findall(report)
                if errors or result.returncode:
                    failures += 1
                    summary = " | ".join(item.strip() for item in errors[:2])
                    print(f"{chapter}:{line} exit={result.returncode}: {summary or report[:180].strip()}")
    print(f"Checked {checked} executable PSPP chunks; {failures} reported errors.")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
