# Codex review handoff — 2026-09-23

**Starting revision:** `1102cb7`. **Owner:** Codex. **State:** first pass in progress. `HANDOFF.md` governs the shared baton; Claude Code can claim any unclaimed item below after taking that baton. Please record a fix and its verification in this file rather than silently removing a finding.

## Coverage and limits

The source inventory scans every chapter in `_quarto.yml` in book order. At the starting revision it found **42 sources, 109 panel tabsets, 191 executable R chunks, 103 executable PSPP chunks, 108 executable Julia chunks, 108 executable Python chunks, and 8 deliberately static language tabs**. On 2026-09-23, three chapter 9 IBM power examples were added as static tabs; the current inventory is **100 executable PSPP chunks and 11 static language tabs** (9 SPSS, 1 Julia, 1 Python). Three SPSS static tabs are reserved for Jeff in `10-reliability.qmd`. The inventory is reproducible with `python3 review/inventory.py`.

I read the structure, build engines, and selected foundational, inference, causal, graphics, and case-study passages. A full `quarto render` completed locally on 2026-09-23. The targeted [SPSS Statistics documentation check](2026-09-23-spss-compatibility.md) records the highest-risk cross-program differences. None of the findings here claims a completed four-language numerical audit of every chunk.

## Findings to review

| ID | Priority | Source and evidence | Proposed action | State / owner |
|---|---|---|---|---|
| C-01 | Urgent | `_engines.R`, PSPP engine near line 300: it calls `system2("pspp", ...)` and passes output to `.book_output()` without checking exit status or diagnostic text. `HANDOFF.md` independently records ten raw PSPP errors already published across chs. 15, 20, 21, and 30. | Reproduce the engine failure path, then make executable PSPP tabs fail visibly or emit an unmistakable build diagnostic. Fix the ten known published errors first. | reproduced by source reading and existing handoff / unclaimed |
| C-02 | Medium | `STATUS.md`, section 2 says only three tabs stay static; `intro.qmd:266,287,300`, `02-distributions.qmd:375`, and `21-graphics.qmd:221` add five `eval: false` tabs. | Update the dashboard and instructions after confirming the exact inventory. Distinguish intentional platform limits from Jeff's reserved section. | reproduced by source inventory / unclaimed |
| S-01 | High | `07-covariance.qmd:14` says a cause with no covariance has no evidence. The same chapter's U-shaped example shows a relationship can have near-zero linear covariance. | Reword to say covariance only detects linear association; use the U-shape as an explicit counterexample. | reproduced by source reading / unclaimed |
| S-02 | High | `33-causal.qmd:218-224` says every DAG yields testable conditional independencies and data can confirm or refute them. Some DAGs have no independence restrictions among measured variables; failure to reject a restriction does not confirm it. | Qualify the claim, and distinguish a detected violation from a low-power or assumption-dependent test. | proposed / unclaimed |
| S-03 | Medium | `33-causal.qmd:228,236` calls a DAG and an SEM the same causal object. SEMs can contain latent variables, bidirected error correlations, and identifying assumptions absent from the simple DAG example. | Narrow the analogy to compatible path models, or explain which assumptions are shared. | proposed / unclaimed |
| S-04 | High | `17-basicANOVA.qmd:186` says an adjusted interval excluding zero is a "real difference" and one including zero "is not." | Explain what the interval and procedure support, without converting a decision threshold into certainty or evidence of equivalence. | reproduced by source reading / unclaimed |
| S-05 | Medium | `intro.qmd:407` calls every confidence interval a probability; `06-zdistribution.qmd:124` says 1.96 occurs in every 95% interval and two-tailed test. | Give a short, accurate bridge to confidence-interval coverage and the small-sample t critical value. Coordinate with the Bayesian distinction in ch. 20. | reproduced by source reading / unclaimed |
| V-01 | Medium | `21-graphics.qmd:200` promises small multiples on comparable axes, while the R example at line 215 uses `scales = "free_y"`. | Decide whether the lesson is trend shape or magnitude comparison; use fixed axes for direct magnitude comparison, or explain free scales clearly. Check the other language tabs too. | reproduced by source reading / unclaimed |

## Additions aligned with the authors' goal

These are proposals, not missing-code bugs. The book already has valuable examples: Anscombe's quartet in ch. 7, NHST criticism in ch. 8, misleading axes in ch. 21, and the sports prediction case in ch. 23.

| ID | Proposal | First useful placement | Evidence of need / learner task |
|---|---|---|---|
| A-01 | Add a short bridge on ratios, denominators, probability, deviations, and sums of squares. Use one tiny dataset throughout so learners calculate variance, standard error, R², and F as related ratios. | Before or within ch. 4, with links from the introduction and ch. 17. | The preface names arithmetic and probability as prerequisites, but ch. 4 moves directly to sample variance. A learner should be able to explain what changes when a numerator or denominator changes. |
| A-02 | Build a recurring "misleading claim → diagnostic → honest rewrite" exercise, ending in a compact synthesis chapter or appendix. Start with denominator choice, truncated axes, omitted uncertainty, subgroup selection, multiple testing, and prediction made from a fitted past. | Threads through chs. 2, 7, 8, 17, 21, and 23. | The existing examples are scattered; the authors want readers to recognize how a technically correct result can persuade an uncritical audience. Exercises should teach detection and repair, rather than provide standalone recipes for deception. |
| A-03 | Add a worked multiple-analysis example: test many outcomes or subgroups, show the false-positive count, then pre-specify one question and apply an appropriate multiplicity correction. | Ch. 8 or 9, with ch. 17's Tukey discussion as follow-up. | Ch. 17 mentions multiplicity, but the book has no worked demonstration of selection among many analyses. |
| A-04 | Add a two-group aggregation example (Simpson's paradox) with the same data shown overall and within groups, followed by a causal explanation of when adjustment is justified. | Ch. 7, then revisit in ch. 33. | The book teaches confounding and DAGs, but this would let students see a persuasive aggregate result reverse when group composition is revealed. |

## Verification record

| Check | Result | Follow-up |
|---|---|
| Source inventory | Ran `python3 review/inventory.py` on 2026-09-23; counts above. | Re-run after chapter edits. |
| PSPP IBM-compatible syntax mode | Ran `python3 review/check_pspp.py` on 2026-09-23: 100 executable chunks checked, exactly 10 failed in chs. 15, 20, 21, 30. | Fix those blocks, then re-run; the IBM-only commands also need IBM execution. |
| Full `quarto render` | Exited 0 on 2026-09-23; both book data zips built. Rendered HTML still contains 10 PSPP error-output blocks across chs. 15, 20, 21, 30. No Julia/Python traceback or `BOOK-STATIC` marker found in generated HTML. | Fix PSPP failure handling and the ten blocks; preserve full render output for a later log audit. |
| Cross-language numerical agreement | Not yet audited end to end. | Compare a checkpoint per procedure first, then extend to all tabsets. |
| IBM SPSS execution | Not available locally. | Ask Jeff to run exported syntax or the SPSS kit, and record exact version/output. |

## Next claimable tasks

1. Reproduce and address **C-01** before treating a green render as PSPP verification.
2. Review **S-01**, **S-02**, **S-04**, and **S-05** with the authors; these affect the book's core lesson on critical interpretation.
3. Choose one dataset and compare the four outputs for each major procedure. Log observed values, tolerance, and interpreter versions. Keep simulation-based tabs separate because their random streams differ.
4. Develop one complete misuse lesson from **A-02** and test it with a graduate learner before spreading the pattern across chapters.
