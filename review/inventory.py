"""Inventory executable teaching chunks in book order.

Run: python3 review/inventory.py
This is a source inventory, not a claim that outputs have been verified.
"""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
CHAPTER = re.compile(r"^\s+-\s+([\w-]+\.qmd)\s*$", re.MULTILINE)
FENCE = re.compile(r"^```\{(r|pspp|julia|python)(?=[\s}])")
LANGUAGES = ("r", "pspp", "julia", "python")
TAB_LANGUAGE = {"R": "r", "SPSS": "pspp", "Julia": "julia", "Python": "python"}


def inspect(path: Path) -> tuple[dict[str, int], dict[str, int], int]:
    """Return live chunks, deliberately static chunks, and tabset count."""
    lines = path.read_text(encoding="utf-8").splitlines()
    live = dict.fromkeys(LANGUAGES, 0)
    static = dict.fromkeys(LANGUAGES, 0)
    tabsets = sum(line.strip() == "::: {.panel-tabset}" for line in lines)

    for index, line in enumerate(lines):
        # A plain fence beneath a language tab is source shown to the reader,
        # but it never runs. Ch. 10 intentionally has three such SPSS tabs.
        if line.strip() in ("```", "```spss") and index > 0:
            heading = lines[index - 1].strip()
            if heading.startswith("### "):
                language = TAB_LANGUAGE.get(heading[4:])
                if language:
                    static[language] += 1
        match = FENCE.match(line)
        if not match:
            continue
        end = next(
            (j for j in range(index + 1, len(lines)) if lines[j].strip() == "```"),
            len(lines),
        )
        options = lines[index + 1 : end]
        disabled = any(re.match(r"^#\|\s*eval:\s*false\s*$", item, re.I) for item in options)
        (static if disabled else live)[match.group(1)] += 1

    return live, static, tabsets


def main() -> None:
    chapters = CHAPTER.findall((ROOT / "_quarto.yml").read_text(encoding="utf-8"))
    print("| Book-order source | Tabsets | R | SPSS/PSPP | Julia | Python | Static tabs |")
    print("|---|---:|---:|---:|---:|---:|---:|")
    totals = dict.fromkeys(LANGUAGES, 0)
    static_totals = dict.fromkeys(LANGUAGES, 0)
    total_tabsets = 0
    for chapter in chapters:
        path = ROOT / chapter
        live, static, tabsets = inspect(path)
        total_tabsets += tabsets
        for language in LANGUAGES:
            totals[language] += live[language]
            static_totals[language] += static[language]
        print(
            f"| {chapter} | {tabsets} | {live['r']} | {live['pspp']} | "
            f"{live['julia']} | {live['python']} | {sum(static.values())} |"
        )
    print(
        f"| **Total ({len(chapters)} sources)** | **{total_tabsets}** | "
        f"**{totals['r']}** | **{totals['pspp']}** | **{totals['julia']}** | "
        f"**{totals['python']}** | **{sum(static_totals.values())}** |"
    )
    print("Static tabs by language:", ", ".join(f"{k}={v}" for k, v in static_totals.items()))


if __name__ == "__main__":
    main()
