# Book review handoffs

This versioned folder holds detailed review evidence and proposed changes. [HANDOFF.md](../HANDOFF.md) is the canonical claim/release log for Codex and Claude Code; use `sync/handoff.py` before editing. The book source remains in the `.qmd` files. Jeff's Word round trip stays in `sync/`.

## How to work together

1. Follow the claim/release rule in `HANDOFF.md`. Read `STATUS.md`, this file, and the latest dated review before editing. Run `git status --short` because another collaborator may be active in the same checkout.
2. Give each finding an ID. Record its source file and line, the observed behavior or exact claim, a proposed action, and one of these states: **proposed**, **reproduced**, **fixed**, **verified**, or **closed**. A successful render alone never upgrades a numerical or conceptual claim to verified.
3. Claim the work in `HANDOFF.md` before changing book sources. If another collaborator has claimed a file, leave a note here and work elsewhere. Do not overwrite uncommitted changes or generated files from another active render.
4. After a change, record the command used, whether all four interpreters ran, and whether their results agree to the precision promised in the text. Put uncertain SPSS behavior under **needs SPSS check** even if PSPP accepts it.
5. Keep proposed prose and pedagogical changes in the handoff until the authors choose wording. Preserve the reserved foreword and Jeff's reliability section.

## What counts as verification

- **Source inventory:** a chunk exists and is marked executable. Generate in book order with `python3 review/inventory.py`.
- **PSPP syntax check:** run `python3 review/check_pspp.py`. It executes each live SPSS chunk with PSPP's `--syntax=compatible` setting and reports failures by chapter and source line. A zero-error result would still need numerical and IBM checks.
- **Execution:** `quarto render` finishes and the render log has no unexplained `BOOK-STATIC` or interpreter errors. A successful render is insufficient if an engine has converted a failure into displayed text.
- **Output agreement:** compare corresponding R, SPSS/PSPP, Julia, and Python results on the *same shipped data*, allowing stated rounding, stochastic variation, and arbitrary factor signs.
- **Statistical check:** recompute key quantities independently or derive them by hand. Inspect whether the interpretation follows from the method and its assumptions.
- **Reader check:** test the published download and documented path from a folder outside the repository. PSPP is useful for syntax coverage, but it does not establish compatibility with IBM SPSS itself.

## Current handoff

See [2026-09-23 Codex review](2026-09-23-codex-review.md). The inventory script covers all 42 sources listed in `_quarto.yml`. The first review identifies high priority claims and a PSPP validation gap; it does **not** certify every code result in the book.
