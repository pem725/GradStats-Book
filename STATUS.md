# Book Build Dashboard — *Statistics by Us for You*

Living tracker for the book: what is built, what runs, and what is still open.
Claude updates this file each working session.

_Last updated: 2026-08-03_

---

## 1. Infrastructure & Publishing

| Item | Status | Notes |
|------|:------:|-------|
| GitHub Pages publishing | ✅ live | `.github/workflows/publish.yml` renders on push to `main` → `gh-pages`. Site: <https://pem725.github.io/GradStats-Book/> |
| `_book/` out of version control | ✅ done | `/_book/` and `/docs/` gitignored; a local render never dirties the tree. |
| Render time in CI | ~35–45 min | Four interpreters now run during the render, so it is no longer a two-minute job. |
| Bibliography | ✅ wired | Six files in `_quarto.yml`: `statbook.bib`, `packages.bib` (auto-generated), `Methods.bib`, `PSYC643.bib`, `Rasch.bib`, `mcknight-pubs.bib`. |
| CLAUDE.md | ✅ current | Guidance for future sessions; kept in step with the build. |

**Publishing model:** edit `.qmd` files and `git push`. The Action renders the whole
book — running every R, SPSS, Julia and Python chunk — and deploys. No local
render-and-commit needed.

**Two machines.** PEM also develops from Positron elsewhere and pushes to `main`
independently, so `main` can diverge. Always `git fetch` and merge before pushing.

---

## 2. The Four-Language Build

Every code tab in the book **executes**. This is the newest and most fragile part of
the machinery, so it gets its own section.

`_engines.R` (sourced by `_common.R`) defines knitr engines for `pspp`, `julia` and
`python`. Each writes the chunk to a scratch file, runs the real interpreter, captures
stdout, and collects any figure the chunk drew.

| | count |
|---|---:|
| tabsets | 109 |
| live `{r}` chunks | 191 |
| live `{pspp}` chunks | 106 |
| live `{julia}` chunks | 109 |
| live `{python}` chunks | 109 |

**Every Julia and Python tab in the book now executes.** The only tabs that do not
are the three SPSS ones below.

**Nothing is shared between chunks except through files.** Every non-R tab therefore
loads its own data — shared loaders in `setup/load_data.{R,sps,jl,py}`, per-dataset ones
like `data/knox.sps` and `data/mod3data.sps`.

**Graceful degradation.** A missing interpreter falls back to static text and logs
`BOOK-STATIC [engine] chapter label: why`. The build never goes red on a machine without
the toolchains, and grepping a render log says exactly which tabs showed less than they
promised. The workflow's "Verify the toolchains" step runs `_engines.R`'s own probes
*before* the render and fails the job if Julia or Python is unusable.

### Hard-won lessons (each cost a build)

- **`LD_LIBRARY_PATH`** — R exports it pointing at its own lib directory and children
  inherit it, so Python's compiled extensions resolved against R's BLAS/LAPACK and
  `import pandas` died. Worked from a shell, failed from R. `.book_run()` clears and
  restores it.
- **PSPP's `/DELIMITERS`** — it reads escapes literally, so `' \t'` is a backslash and a
  letter, not a tab. The Knox file mixes spaces and tabs, so values slid silently into
  the wrong variables. No error, no warning, just wrong numbers.
- **Julia on the runner** — Ubuntu ships a Julia binary, so the engine found it, the
  packages were absent, and the published book printed `Segmentation fault (core
  dumped)` as though it were a result. Pinned to 1.11.5 with the committed
  `Manifest.toml` instantiated.
- **PSPP is a subset of SPSS** — no `UNIANOVA /CONTRAST` (spell codes out with `COMPUTE`
  + `REGRESSION`), no `FACTOR /EXTRACTION=ML` (use PAF, note the one-word change),
  `GLM` not `UNIANOVA`. Factor signs are arbitrary and PSPP sometimes flips one.

### The three tabs that stay static

All three are the `RELIABILITY /MODEL=ALPHA` SPSS tabs in `10-reliability.qmd` (lines
332, 404, 481) — the section **reserved for Jeff Stuewig to write**. PSPP 2.0 does
implement `RELIABILITY`, so they could be made to run; they are held deliberately, not
for want of a toolchain. Their tabsets show output under R, Julia and Python and none
under SPSS until Jeff's section lands.

Where a language genuinely cannot do a procedure, its tab says so and names the tool
that can — base SPSS has no power analysis (G\*Power, SamplePower), no latent class
analysis (Latent GOLD, Mplus, `poLCA`), and no Rasch calibration (Winsteps, ConQuest,
`eRm`/`TAM`). That is the house include/exclude rule: name the gap, never manufacture
syntax that would not run.

---

## 3. Book Structure

Twelve parts, thirty-two numbered chapters, plus front and back matter. Order lives in
`_quarto.yml`, not in filename order.

| Part | Chapters |
|------|----------|
| _(front)_ | `index` · `foreword` · `preface` · `author` · `intro` |
| The Basics | 02 Distributions · 03 Central Tendency · 04 Dispersion · 05 Data Cleaning |
| Making Inferences with Data | 06 z-Distribution · 07 Covariance · 08 Hypothesis Testing · 09 Power |
| Checking Our Data | 10 Reliability · 11 Validity · 18 Rasch |
| Preparing Our Data | 31 Data Reduction |
| Using Models | 12 GLM & Covariance · 13 Point-Biserial · 14 Bivariate Regression · 15 MRC · 16 ANOVA & GLM · 17 Basic ANOVA · 19 Coding Categorical Predictors |
| Latent Variable Models | 28 CFA/SEM · 32 Measurement Invariance · 29 Latent Class · 30 IRT & Generalizability |
| Causal Inference | 33 DAGs and the back door |
| Beyond the Normal Curve | 20 Resampling, robust methods, Bayes |
| Displaying Data | 21 Graphics · 22 Tables |
| Statistics in the Wild | 23 The Sports Page · 24 Depression Profiles · 25 Building a Measure · 26 Missing Data |
| The Methods in Practice | 27 Showcase |
| Appendices | `three-languages` · `setup` · `required-packages` · `changelog` |
| _(back)_ | `references` |

**All chapters are drafted and render clean.** No stubs and no `foo`/`bar`/`baz`
placeholders remain. The one deliberate blank is `foreword.qmd`, held for an outside
colleague to write in their own words.

The largest chapters are `19-coding` (747 lines, 9 tabsets), `20-beyond` (708 / 10),
`10-reliability` (510 / 7), `15-MRC` (508 / 6), `21-graphics` (467 / 7), and
`18-rasch` (423 / 4).

**Ch. 18 — Rasch, honoring Ben Wright.** From-scratch JMLE (the BIGSTEPS/UCON engine)
running on Wright's *actual* Knox Cube Test data (`data/knox.dat`, 35 named children ×
18 tapping items from *Best Test Design*). Converges in 31 iterations, sets aside the 3
all-pass and 1 no-pass items automatically, and recovers Wright's difficulty ladder
(Spearman 0.97 against item order). All four languages read the same file and agree.
The source PDFs are gitignored — large and copyrighted, never committed.

---

## 4. Source Material (Google Drive → `Teaching/`)

| Drive location | Folder ID | Feeds |
|----------------|-----------|-------|
| `Teaching/R/` (Regression1–9.R, Basics.R, datasets) | `0B1KESQbSMul1VWt2OTluc2NvRlk` | 14–17, 19 |
| `Teaching/PSYC/611` (Adv Stat Research Methods) | `0B1KESQbSMul1amdwRE9XclBzQXM` | 06–09 |
| `Teaching/PSYC/642` (GLM I) | `1lnNNP_2E-EBTvctziFyk1EKqjxqdPx4i` | 12–16 |
| `Teaching/PSYC/643` (GLM II) | `1kcGbfbX5oLRml-YqvszKpAnNXbZnm845` | 14–16 |
| `Teaching/PSYC/644` (GLM III) | `0B1KESQbSMul1TnhrS0VUaWtSYmc` | 15–16 |
| `Teaching/PSYC/612` (Regression / mediation) | `0B1KESQbSMul1M0ZsamVMSEVObFk` | 14–15 |
| `Teaching/PSYC/757 & 892` (Bayesian) | `1qN6IiOJS-BwP3YFBsnYK6NGsE02mvh8H` | 20 |
| `Teaching/Rasch/` (measurement) | `0B1KESQbSMul1bDhHcG9qdHpvNm8` | 10, 11, 18, 30 |
| Local Zotero PDF library (5,082 PDFs) | `~/Zotero/storage/` | references |

Giant research libraries (`CRC.bib` 4.9 MB, `delphi.bib` 3.8 MB) are deliberately
**excluded** from the repo.

---

## 5. Open Items

- [ ] **Ch. 10 `RELIABILITY /MODEL=ALPHA`** — reserved for Jeff Stuewig to write.
- [ ] **`foreword.qmd`** — awaiting the invited colleague.
- [ ] **Voice/structure review** of the drafted chapters (PEM).
- [ ] **`10-reliability.qmd` tabsets 1–4 print full precision in Julia and Python** —
      `0.8031550441308491` where the R tab prints `0.80`. The house rule is two decimals.
      Four chunks; they were live before this pass and were not touched by it.
- [ ] **Tabset 3's Julia tab leaks a stray vector.** The line
      `lam = vec(loadings(fa)); psi = var(fa)` is echoed by the engine because a
      semicolon-joined line takes the value of its last statement, so five noise
      variances print before the answer. The answer itself is correct.
- [ ] **Prose/output mismatch in `10-reliability.qmd`.** The text says "About 0.78 of the
      variance … is real signal," which is the population value (225/289 = 0.7785), but
      every tab prints the realized sample value, `0.80`. Author's call which to change.

### Known quirks, deliberately left alone

- **`.gitignore` patterns are literal, not stems.** The rule `pspp.png` does not match
  `pspp.png-2`, so `pspp.png-2` … `-7` and `pspp.svg` are tracked in the repo even
  though the same commit that added the rule meant to exclude them. Widening it to
  `pspp.png*` would catch future spill, but gitignore never retroactively untracks a
  file, so the existing seven would still need `git rm --cached`. Kept as is, on purpose.
- `_poc_engines.*` is the proof-of-concept that became `_engines.R`. Nothing in the book
  references it; it is kept as a record of the scratch work.
- `statbook.bib.bak` is a 70-line backup from the initial commit; the live file is 79
  lines. Kept.
- `Module{1,2}demostration.qmd` are standalone demos rendered outside the book. The
  `.qmd` sources are tracked on purpose; their `.html` and `_files/` output is ignored.

### Corrections made along the way

- MRC coefficient t-test df: `n-1` → **`n-k-1`**.
- Omnibus F comment replaced with `F = (R²/k)/((1-R²)/(n-k-1))`.
- Separated *semipartial* vs *partial* correlation vs *standardized coefficient*.
- Power: **stricter α lowers power** — the 611 slides had it backwards.
- Knox Cube SPSS loader read a literal `\t` and silently mis-parsed every item.
- **The depression chapter's SPSS block returned 0, not 1,653,955,415.** A continuation
  line beginning with `*` is a comment in SPSS syntax, so the two `* (EXP(...))` lines of
  the inclusion-exclusion sum were silently dropped and the loop summed $(-1)^i$ to zero.
  Operators now end their lines. One occurrence book-wide; the trap is written up in the
  [four-language appendix](three-languages.qmd).
- **The reliability chapter's Python Cohen's *d* had the wrong sign.** `sorted(pd.unique())`
  ordered the groups F, M while R's `as_factor()` orders by appearance, M, F — so Python
  would have printed +2.62 against R's −2.62 the moment the tab went live.
- Seven contrast-coding schemes in Ch. 19 rewritten to run in PSPP; all reproduce the R
  coefficients exactly, and the regression sums of squares come out identical across all
  five pet schemes — which is the chapter's whole argument.
