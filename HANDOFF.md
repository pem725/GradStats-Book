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

_Current as of 2026-09-25, HEAD `04a3655`, published and verified live._

Jeff is **teaching from the published book right now** — he told Pat on 2026-09-22 that
he sends students to the online chapters and that they were "spot on" for his notes.
Published defects are therefore live classroom material, not cosmetic.

### Closed since the last entry

- **The ten published PSPP errors are gone.** `_engines.R` now falls back when a run
  *fails*, not only when the interpreter is *missing* — the gap that let PSPP's
  diagnostics become page content. Each of the eight affected blocks shows IBM syntax
  plus a note saying PSPP cannot run it. Verified live: 0 raw errors, 0 temp paths,
  8 notes.
- **Nine more temp paths** came from matplotlib warning that `FigureCanvasAgg` cannot
  display under the Agg backend. Filtered in the Python engine.
- **Two blocks in `20-beyond` were simply broken** — the credible-interval and ROPE
  tabs used `theta` and `post` without creating them, so they would have failed in IBM
  SPSS too. They rebuild the grid now, and the grid is normalised, which it never was.
- **Chapter 9's power claim** is corrected and live (Codex).
- **New chapter: `34-bounded.qmd`**, bounded outcomes. Beta regression fitted from
  scratch and with `betareg`, agreeing to four decimals. Its centrepiece: `betareg`
  fits data containing exact zeros and reports a finite log-likelihood when the honest
  beta log-likelihood is `-Inf`, and the estimate moves 0.82 → 0.52 depending on how
  the boundary is handled. `06-zdistribution` now points forward to it.
- **CI is green and faster** — 27 min, down from 45. The Julia depot is cached, which
  is what fixed the osf.io 429 that had blocked publishing for 16 days.

### Open

1. **Jeff's `RELIABILITY /MODEL=ALPHA` section** — the last content gap. He now has a
   working SPSS kit, `.sav` data, and the one-folder starters.
2. **The foreword** — awaiting the invited colleague.
3. **Pat's voice and structure review.**
4. `.sav` files are in Jeff's Drive folder but **not** in the published zips, because
   no one has confirmed IBM SPSS opens a PSPP-written system file.
5. `09-statisticalpower.html` is **4.5 MB**, roughly 30× a comparable page. Students
   read these on phones.

### The habit worth keeping

Nearly every defect this project has hit has the same shape: something ran, nothing was
flagged, and the output was wrong or was not an answer. The `\t` delimiter. The `*`
continuation line read as a comment. `betareg` fitting an impossible model. PSPP's
complaint published as a result. Three of Claude's own: `statmod` verified on the one
machine that had it, a comment parsed as a package name, a regex that matched nothing
and silently degraded its own error message.

The fix is never more care in the moment. It is checking the thing that *consumes* the
output rather than the thing that produces it — unauthenticated `curl` rather than `gh`,
what `pak` reads rather than whether the YAML parses, the rendered page rather than the
source.

Codex's review evidence is in `handoffs/`; repeatable checks in `review/`.
`python3 review/check_pspp.py` is the regression test — it should report 8 failures,
all IBM-only commands, all now falling back cleanly rather than publishing.

## Log

<!-- newest first; sync/handoff.py writes here -->
- **RELEASE** `2026-09-25 02:18:25` claude — _engines.R now falls back on PSPP failure (was only on missing binary) + filters matplotlib's non-interactive warning. 0 raw errors, 0 temp paths across the 4 chapters. Pushed. [at 1144797]
- **CLAIM** `2026-09-25 02:11:48` claude — Making _engines.R fall back on a PSPP error instead of publishing it [at dd932e1]
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
