# The Jeff round trip

Jeff edits Word. The book is Quarto. This moves changes both ways without
either of us changing tools.

```
python3 sync/export_to_jeff.py            # book  -> DOCX in the shared folder
python3 sync/import_from_jeff.py          # DOCX  -> report of what Jeff changed
python3 sync/import_from_jeff.py --apply  # ...and write it into the .qmd files
python3 sync/import_from_jeff.py --apply --branch   # ...on a dated git branch
```

Chapters land in `Patrick & Jeff/Book Chapters/`. Override with `JEFF_SHARED_DIR`.

## The constraint everything else follows from

**A DOCX cannot be turned back into a `.qmd`.** Measured, not assumed — round
-tripping `10-reliability.qmd` through pandoc collapses:

| | before | after |
|---|---|---|
| fenced divs `:::` | 24 | 2 |
| callouts | 3 | 0 |
| panel-tabsets | 7 | 1 |
| chunk options `#|` | 1 | 0 |

Rebuilding chapter sources from Word would quietly destroy the four-language
tabs. So the sync never rebuilds anything.

## What it does instead

Export keeps the exact text of the DOCX it shipped, in `.jeff-sync/baseline/`.
On import, Jeff's returned file is compared **against that baseline** — Word text
vs Word text. The `.qmd` is never parsed for the comparison, so Quarto syntax
cannot be misread.

Each changed line is then located in the `.qmd` by whitespace-normalised match
and applied **only when it matches exactly one line**. Ambiguous matches,
multi-line rewrites, insertions, deletions, and every Word comment are reported
and never guessed. The report is `Book Chapters/JEFF-EDITS-REPORT.md`.

Import defaults to a dry run. It writes to the sources of a live book, so the
mutation is opt-in.

## Things that will bite you

- **`tex_math_dollars` must stay off.** It reads `$` in R/dplyr code as math, and
  a Word equation cannot come back as `$$...$$`. Left literal, math survives.
- **Code is exported unexecuted.** Jeff sees real source, not output, so an SPSS
  correction he makes is the correction that lands in the book.
- **List markers are preserved on apply.** pandoc normalises `2.  x` to `2. x`;
  rewriting whole lines would churn markers and leave them inconsistent with
  untouched neighbours.
- **`.jeff-sync/` is gitignored** — a local cache, rebuildable by re-exporting.
- Export skips chapters whose `.qmd` has not changed. `--all` forces.

## Automating it

There is no watcher. Both directions are one command, and import defaults to
reporting, so the honest wiring is a cron entry or a shell alias you run when
Jeff says he has sent something back:

```
cd ~/GitTemp/GradStats-Book && python3 sync/export_to_jeff.py && python3 sync/import_from_jeff.py
```

Do not put `--apply` in an unattended job until you have watched a few imports
land correctly.
