# Book Build Dashboard — *Statistics by Us for You*

Living tracker for pulling ~20 years of teaching material into the book and getting
it published. Claude updates this file each working session.

_Last updated: 2026-07-16_

---

## 1. Infrastructure & Publishing

| Item | Status | Notes |
|------|:------:|-------|
| Stop version-controlling `_book/` | ✅ done | `git rm --cached _book`; added `/_book/` + `/docs/` to `.gitignore`. **Needs a commit.** |
| GitHub Pages publishing | ✅ workflow added | `.github/workflows/publish.yml` renders on push to `main` → `gh-pages` branch. |
| Enable Pages (one-time, in GitHub UI) | ⬜ **you** | Settings → Pages → Source: *Deploy from a branch* → `gh-pages` / `(root)`. Then site lives at https://pem725.github.io/GradStats-Book/ |
| CLAUDE.md for the repo | ✅ done | Guidance for future Claude sessions. |
| Import teaching BibTeX | ✅ done | `Methods.bib` (12 entries) + `PSYC643.bib` (14 entries) in repo & wired into `_quarto.yml`. Zotero library confirmed local: **5,082 PDFs** at `~/Zotero/storage/`. |

**Publishing model:** you just edit `.qmd` files and `git push`. The Action renders the
book (running all R chunks) and deploys. No local render-and-commit needed.

---

## 2. Source Material Found (Google Drive → `Teaching/`)

The archive is large (~30 course folders, 2004–2026). Key locations for *this* book:

| Drive location | Folder ID | Feeds chapters |
|----------------|-----------|----------------|
| `Teaching/R/` (Regression1–9.R, Basics.R, datasets, videos) | `0B1KESQbSMul1VWt2OTluc2NvRlk` | 12–17 (regression/GLM) + basics |
| `Teaching/PSYC/611` (Adv Stat Research Methods) | `0B1KESQbSMul1amdwRE9XclBzQXM` | 06–09 (inference, power) |
| `Teaching/PSYC/642` (GLM I) | `1lnNNP_2E-EBTvctziFyk1EKqjxqdPx4i` | 12–16 |
| `Teaching/PSYC/643` (GLM II) | `1kcGbfbX5oLRml-YqvszKpAnNXbZnm845` | 14–16 |
| `Teaching/PSYC/644` (GLM III / advanced) | `0B1KESQbSMul1TnhrS0VUaWtSYmc` | 15–16 |
| `Teaching/PSYC/612` (Regression / mediation) | `0B1KESQbSMul1M0ZsamVMSEVObFk` | 14–15 |
| `Teaching/PSYC/757 & 892` (Bayesian) | `1qN6IiOJS-BwP3YFBsnYK6NGsE02mvh8H` | future / inference |
| `Teaching/Rasch/` (measurement) | `0B1KESQbSMul1bDhHcG9qdHpvNm8` | 10–11 (reliability/validity) |
| `Teaching/Methods.bib` | `0B1KESQbSMul1ZFBYQ3k0SjdndkU` | references (sampling/design) |
| Local Zotero PDF library | `~/Zotero/storage/` | ✅ source PDFs live here (per PSYC643.bib) |

**Other bib files of interest:** `PSYC643.bib` (GLM/regression — Aiken/Cohen/West, Keppel,
MacKinnon), `596i_syllabus.bib`, `564_syllabus.bib`. Giant research libraries
(`CRC.bib` 4.9 MB, `delphi.bib` 3.8 MB) exist but are **excluded** from the book repo
unless you want them.

---

## 3. Chapter Synthesis Status

Legend: 🟥 stub/empty · 🟨 partial · 🟩 drafted · ⬜ not started synthesis

| # | Chapter | Now | Primary source(s) to pull from | Synth |
|---|---------|-----|-------------------------------|:-----:|
| — | intro | 🟨 helix works; concept callouts filled | — | — |
| 02 | Variables & Distributions | 🟩 **drafted** | extended existing; distributions/PDFs | ✅ |
| 03 | Central Tendency | 🟩 **drafted** | mean=least-squares framing | ✅ |
| 04 | Dispersion | 🟩 **drafted** | variance/SD/df, the "VARIANCE" spine | ✅ |
| 05 | Data Cleaning | 🟩 **drafted** | sensors, missingness (MCAR/MAR/MNAR) | ✅ |
| 06 | z-Distribution | 🟩 **drafted** | extended existing; pnorm/qnorm | ✅ |
| 07 | Covariance | 🟩 **drafted** | covariance→correlation→slope engine | ✅ |
| 08 | Hypothesis Testing | 🟩 **drafted** | PSYC 611 Lec 6, Methods.bib (Meehl) | ✅ |
| 09 | Statistical Power | 🟩 **drafted** | PSYC 611 Lec 6; fixed the α→power error | ✅ |
| 10 | Reliability | 🟩 **drafted** | CTT (O=T+E), Cronbach α, dartboard | ✅ |
| 11 | Validity | 🟩 **drafted** | measure + inference validity, dartboard | ✅ |
| 12 | GLM & Covariance | 🟩 **drafted** | GLM overture; t=ANOVA=regression | ✅ |
| 13 | Point-Biserial Correlation | 🟩 **drafted** | continuous↔dichotomous bridge | ✅ |
| 14 | Bivariate Regression | 🟩 **drafted** | **R/Regression1.R** | ✅ |
| 15 | Multiple Regression (MRC) | 🟩 **drafted** | **R/Regression4.R**; fixed df & F errors | ✅ |
| 16 | ANOVA & GLM | 🟩 **drafted** | **R/Regression7.R** + 8–9.R | ✅ |
| 17 | Basic ANOVA | 🟩 **drafted** | SS partition; ANOVA=regression | ✅ |

**All 16 body chapters now drafted and rendering.** The whole book builds end-to-end
(`quarto render`, exit 0). Chapters 12/13/17 equivalence claims (t=ANOVA=regression,
point-biserial=t-test, SS partition, `lm` F = `aov` F) verified numerically.

Chapters 02–07, 10–13, 17 are drafted from the book's established voice/framework plus
the digested 611 lectures and CTT material — solid, correct, self-contained (base R +
ggplot2). They can be *enriched* later with specific lecture examples/data from the
Drive archive (measurement chapters especially could pull from Rasch/754).

---

## 4. Decisions Needed From You

1. **Synthesis strategy** — depth-first (finish a few chapters fully, review, then
   continue) vs. breadth-first (drop relevant material into all 16, then polish)?
2. **Canonical courses** — confirm 611 + 642/643/644 + 612 are the authoritative
   sources; ignore undergrad sections (300/325/etc.)?
3. **PDFs** — do you want the Zotero source PDFs referenced/linked, or copied into the
   repo? (Copying could add hundreds of MB.)
4. **Videos** — old `.avi` lecture videos exist in `Teaching/R/`. Re-host, link, or skip?

---

## 5. Next Actions (Claude)

- [x] Commit infra changes (gitignore, workflow, CLAUDE.md, bibs). _(commit 430970f, held locally — not pushed)_
- [x] Chapter 14 (Bivariate Regression) drafted to publication quality & renders clean.
- [x] Ch. 8 (Hypothesis Testing), Ch. 14 (Bivariate Regression) — drafted, render clean.
- [x] Ch. 15 (MRC) & Ch. 16 (ANOVA/GLM) — drafted from Regression4/7.R; by-hand values verified against `lm()`/`aov()`.
- [x] Ch. 9 (Power) — drafted; **fixed the α→power error** from the 611 slides; removed the "AI shit" placeholder.
- [x] Fixed intro placeholder callouts (foo/bar/baz) + removed a duplicated "Frequency" callout.
- [ ] **You:** review the drafted chapters for voice/structure; enable GitHub Pages.
- [ ] Remaining stubs to synthesize: 02–07, 10–13, 17 (measurement chapters need the Rasch/754 folders).

### Corrections made (fix-the-mistakes pass)
- MRC coefficient t-test df: `n-1` → **`n-k-1`** (Regression4.R).
- Omnibus F: replaced garbled comment formula with `F = (R²/k)/((1-R²)/(n-k-1))`.
- Separated *semipartial* vs *partial* correlation vs *standardized coefficient* (Regression4.R conflated them).
- Power: **stricter α lowers power** (slides had it backwards); n only lever that raises power without raising Type I.
- Dropped crash-causing typos from source (`summmary`, `Princpal`) and hardcoded local data paths.
