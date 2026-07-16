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
| — | intro | 🟨 helix works | — | — |
| 02 | Variables & Distributions | 🟨 4.9 KB | R/Basics.R, intro-stats lectures | ⬜ |
| 03 | Central Tendency | 🟥 | intro-stats lectures | ⬜ |
| 04 | Dispersion | 🟥 | intro-stats lectures | ⬜ |
| 05 | Data Cleaning | 🟥 empty | R/ data-wrangling scripts | ⬜ |
| 06 | z-Distribution | 🟨 | PSYC 611 | ⬜ |
| 07 | Covariance | 🟥 | PSYC 611/642 | ⬜ |
| 08 | Hypothesis Testing | 🟥 | PSYC 611, Methods.bib | ⬜ |
| 09 | Statistical Power | 🟨 | PSYC 611 | ⬜ |
| 10 | Reliability | 🟥 | Rasch/, measurement courses | ⬜ |
| 11 | Validity | 🟥 | Rasch/, measurement courses | ⬜ |
| 12 | GLM & Covariance | 🟥 | R/Regression1–2.R, PSYC 642 | ⬜ |
| 13 | Point-Biserial Correlation | 🟥 | PSYC 642/643 | ⬜ |
| 14 | Bivariate Regression | 🟩 **drafted** | **R/Regression1.R** (done) + 2–4.R, PSYC 612/642 | ✅ |
| 15 | Multiple Regression (MRC) | 🟥 | **R/Regression5–8.R**, PSYC 643, PSYC643.bib | ⬜ |
| 16 | ANOVA & GLM | 🟥 | **R/Regression9.R**, PSYC 643/644 | ⬜ |
| 17 | Basic ANOVA | 🟥 empty | PSYC 644 | ⬜ |

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
- [ ] **You:** review Ch. 14 for voice/structure/format; enable GitHub Pages.
- [ ] Draft a prose-heavy exemplar (Ch. 8 Hypothesis Testing) to test the approach on non-code material.
- [ ] On approval, roll the pattern out: Ch. 15 (MRC) & 16 (ANOVA/GLM) from Regression4–9.R, then the rest.
