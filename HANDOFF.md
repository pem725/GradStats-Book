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
2. **Chapter 9 is factually wrong** — says base SPSS has no power analysis; Jeff's
   install has it.
3. **`.sav` not yet in the published zips.** Generated and delivered to Jeff's folder,
   but unverified against real SPSS, so not shipped to other readers yet.
4. Jeff's `RELIABILITY /MODEL=ALPHA` section; the foreword; Pat's voice pass.

## Log

<!-- newest first; sync/handoff.py writes here -->
- **RELEASE** `2026-09-23 10:05:17` claude — Added HANDOFF.md + sync/handoff.py (baton), sync/daily_scan.py (sweep, verified quiet-when-idle), notes/2026-09-22-jeff.md. Pushed 1102cb7. NOT done: the 10 published PSPP errors, ch09 power claim, .sav into the zips. [at 1102cb7 (uncommitted changes present)]
