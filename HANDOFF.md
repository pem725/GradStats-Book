# Handoff

Two agents work this repo: **Claude** (this terminal) and **Codex** (the other one).
Pat drives both, by voice, sometimes within minutes of each other. This file is how
we avoid stepping on each other, and how whoever picks up next knows where things
stand without re-deriving it.

## The rule

**Before touching anything:** `git fetch && git status`, and read the log below.
**After finishing:** append an entry. One command does both ends:

```sh
python3 sync/handoff.py claim  "what I am about to do"     # take the baton
python3 sync/handoff.py release "what I did, what is verified, what is next"
python3 sync/handoff.py status                             # who holds it
```

A claim older than 4 hours is stale — take it, and say so in your entry.

## Traps we have already paid for

- **Never run a full `quarto render` while the other agent is working.** Quarto
  empties `_book/` at render start. Killing one mid-flight destroys the rendered
  book and leaves `*_files/` litter in the repo root.
- **`_poc_engines_files/` is tracked on purpose.** A `rm -rf ./*_files` will eat it.
  Pat decided to keep it; restore with `git checkout --` if you do.
- **The shared Drive folder is a separate git repo** with no remote. Committing here
  does nothing there, and vice versa.
- **`.sav`, `.docx`, `_book/`, `.jeff-sync/` are all built, never committed.** If one
  is missing, rebuild it rather than hunting for it in git.
- **Pushes to `main` trigger a 35–45 minute render and a live deploy.** Do not push
  a doc-only change if the other agent is mid-experiment.
- GitHub occasionally returns a 500 on push. Retry before diagnosing.

## State

Jeff is **teaching from the published book right now** — he told Pat on 2026-09-22 that
he sends students to the online chapters and that they were "spot on" for his notes.
Published defects are therefore live classroom material, not cosmetic.

Open, in rough priority:

1. **10 raw PSPP errors still published** across `15-MRC`, `21-graphics`, `20-beyond`,
   `30-irt` — temp paths and all. `30-irt` is the free one: Jeff confirmed `VARCOMP`
   runs in real SPSS, even the student version.
2. **Chapter 9 power correction is written locally, not published** — IBM SPSS
   Statistics 27+ Base Edition documents `POWER MEANS INDEPENDENT`. The three
   examples now show IBM syntax as static PSPP tabs; Jeff still needs to run them.
3. **`.sav` not yet in the published zips.** Generated and delivered to Jeff's folder,
   but unverified against real SPSS, so not shipped to other readers yet.
4. Jeff's `RELIABILITY /MODEL=ALPHA` section; the foreword; Pat's voice pass.

Codex's review evidence is in `handoffs/`, with repeatable source and PSPP checks in
`review/`. The 2026-09-23 full render exited 0 but `review/check_pspp.py` found the
same ten failed SPSS chunks in PSPP's IBM-compatible syntax mode. IBM's documentation
supports the relevant commands, but IBM SPSS has not executed the exact blocks here.

**Repository cleanup before any push:** commit `2292b31` was made while Codex's full
Quarto render was running. It accidentally tracked temporary root-level HTML,
`*_files/`, and `site_libs/` output that Quarto then removed. The working tree shows
those as tracked deletions; do not stage or push blindly. `_book/` is intact locally.

## Log

<!-- newest first; sync/handoff.py writes here -->
- **RELEASE** `2026-09-24 21:06:15` codex — SPSS kit now has Windows/Mac starters that set the extracted folder path in every chapter file; zip builds (748 KB, 34 chapter files), extracted Mac starter and PSPP setup check passed (mean 67.99) from a path with spaces; 03-CTmeasures ran standalone. Windows starter not executed here; IBM SPSS still needs Jeff's run. Kit changes included in 7153e1b and 0d73127; not pushed. [at 0d73127]
- **RELEASE** `2026-09-24 20:50:58` claude — ch34-bounded written, renders clean (exit 0, 0 fallbacks, 0 PSPP errors), all 4 languages verified against R. POMP section in ch06 points forward. betareg in CI list, Optim in Julia project. NOT pushed. [at 7153e1b]
- **CLAIM** `2026-09-24 20:43:22` claude — Writing 34-bounded.qmd prose + tabs, POMP rework, CI deps [at 0485410 (uncommitted changes present)]
- **RELEASE** `2026-09-24 20:41:28` claude — ch34 data built (ch34-wellbeing, 240 rows, 17 exact zeros at the POMP floor). Verified: OLS 95% PI runs to -6.9 POMP; scratch MLE == betareg (-1.0846/0.8215/phi 3.984) after rescale; Python+Julia agreed on the earlier pilot. FINDING: betareg fits data containing exact zeros and reports logLik 42.72, but the beta logLik at its own fitted values over those 240 rows is -Inf, and coefficients differ from interior-only (-0.63/0.52 vs -0.81/0.68). Chapter prose not written yet. [at 0485410 (uncommitted changes present)]
- **CLAIM** `2026-09-24 20:39:29` claude — Writing 34-bounded.qmd (beta regression) + POMP rework [at 0485410 (uncommitted changes present)]
- **CLAIM** `2026-09-24 20:37:45` codex — Correcting mis-signed claim; building path-free SPSS kit launchers and standalone chapter syntax [at 0485410 (uncommitted changes present)]
- **RELEASE** `2026-09-24 20:37:20` claude — Beta regression core VERIFIED across 4 engines (R optim, R betareg, Python statsmodels BetaModel, Julia Optim) - all give -0.8963/0.7939/phi=9.337 on the same data. OLS 95% PI reaches -0.007, the hook. Added Optim to Julia deps (Manifest changed, NOT committed). betareg installed locally, NOT yet in CI list. Chapter itself not written yet. [at 0485410 (uncommitted changes present)]
- **CLAIM** `2026-09-24 20:37:13` claude — Make the SPSS zip configure its own absolute data path after extraction; no hand-edited paths [at 0485410 (uncommitted changes present)]
- **CLAIM** `2026-09-24 20:35:52` claude — Writing the bounded-outcomes chapter (beta regression) + POMP rework [at 0485410]
- **RELEASE** `2026-09-24 08:51:07` claude — Fixed 2 of 10 SPSS errors (20-beyond: blocks referenced undefined vars; also normalised the grid). Diagnosed CI: osf.io 429 during MixedModels precompile, not our code; added depot cache + retry. 5 commits ready, NOT pushed. Remaining 8 errors all IBM-only and all available at GMU; real fix is _engines.R falling back on PSPP error. [at ce0623e (uncommitted changes present)]
- **CLAIM** `2026-09-24 06:35:37` claude — Triaging the 10 published PSPP errors; GMU availability first [at bb25657]
- **RELEASE** `2026-09-23 12:20:13` codex — Reviewed all 42 sources for chunk inventory; full render exit 0 but ten PSPP chunks fail; IBM docs review and chapter 9 POWER correction recorded in handoffs; review scripts added. IBM execution and numeric audit remain. Commit 2292b31 accidentally tracked in-progress render files; clean before push. [at 2292b31 (uncommitted changes present)]
- **CLAIM** `2026-09-23 10:17:50` codex — Reviewing book code and pedagogy; full render in progress; handoffs review notes only [at 2292b31 (uncommitted changes present)]
- **RELEASE** `2026-09-23 10:05:17` claude — Added HANDOFF.md + sync/handoff.py (baton), sync/daily_scan.py (sweep, verified quiet-when-idle), notes/2026-09-22-jeff.md. Pushed 1102cb7. NOT done: the 10 published PSPP errors, ch09 power claim, .sav into the zips. [at 1102cb7 (uncommitted changes present)]
