# PACK-REVIEW-RULE-CLEANUP.md

**Date:** 2026-05-11
**Reviewer:** pack-reviewer (read-only on the codebase; one review pass)
**Scope:** Rule-cleanup batch removing the deprecated "BD-for-fix /
fix-follow BD" rule language from pack-ops files and replacing it with
the new affirmative wording.
**Inputs cited:**
- `maintenance-docs/v11-implementation/RULE-CLEANUP-DISCOVERY.md` (the spec)
- Working-tree diff vs. `HEAD` (in-repo files)
- Current state of out-of-repo memory files
  (`/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/`)
- `python3 scripts/validate-pack.py` rerun

---

## 1. Verdict

**Clean — ready for commit.**

The batch is mechanically faithful to `RULE-CLEANUP-DISCOVERY.md` §2,
applies all four EDGE CASE resolutions correctly, leaves
KEEP-HISTORICAL files untouched, encodes the user's three refinements
verbatim, preserves trinity byte-identity, and `validate-pack.py`
PASSES (30/30 checks). Two NITs noted in §6 (see findings list); no
BLOCKERs and no SHOULD-FIXs.

---

## 2. Coverage check (REMOVE / REWRITE sites)

Each row maps a site flagged in `RULE-CLEANUP-DISCOVERY.md` §2 to its
realization in the working tree.

| Discovery site | Category | Realized at | Status |
|---|---|---|---|
| `MEMORY.md:13` (index entry for implicit-flip) | REWRITE | Memory `MEMORY.md:13` (re-worded to "review fixes are green and tests pass") | DONE |
| `feedback_review_fix_one_cycle.md:11` ("One fix-follow commit closes …") | REWRITE | Memory file line 11 ("One fix commit, in the current session, closes …") | DONE |
| `feedback_review_fix_one_cycle.md:19` ("After landing a fix-follow …") | REWRITE | Memory file line 19 ("After landing the in-session fix commit …") | DONE |
| `feedback_review_fix_one_cycle.md` D-5 addendum | NEW | Memory file lines 23-28 (new bullet at end of How-to-apply) | DONE |
| `feedback_implicit_status_flip.md:3` (description) | REMOVE/REWRITE | Memory file line 3 ("review fixes are committed") | DONE |
| `feedback_implicit_status_flip.md:7-11` (body) | REMOVE/REWRITE | Memory file lines 7-11 ("review fixes committed") | DONE |
| `feedback_implicit_status_flip.md:21-22` ("fix-follow commit if it's small") | REWRITE | Memory file line 22 ("review-fix commit if it's small") | DONE |
| `feedback_implicit_status_flip.md:27` ("fix-follow committed, CI green") | REWRITE | Memory file line 27 ("review fixes committed, CI green") | DONE |
| `CLAUDE.md:112-114` (trinity bullet — D-8 addendum) | EDGE CASE | `CLAUDE.md:113` (one-line append with active-prohibition refinement) | DONE |
| `AGENTS.md:106-108` (trinity copy) | EDGE CASE | `AGENTS.md:107` (byte-identical to CLAUDE) | DONE |
| `GEMINI.md:87-89` (trinity copy) | EDGE CASE | `GEMINI.md:87` (byte-identical to CLAUDE) | DONE |
| `EXECUTION-PLAN-V11.0.md:91` (BD-059 verify-then-close) | REMOVE | Plan line 91 (D-1 replacement applied) | DONE |
| `EXECUTION-PLAN-V11.0.md:205` (BD-128 Description "May spawn fix-follow BDs …") | REWRITE | Plan line 205 ("Pack Chat reports it and asks the user how to proceed; new BDs are opened only if the user directs.") | DONE |
| `EXECUTION-PLAN-V11.0.md:246` (Batch 14 Notes) | REMOVE | Plan line 246 (D-2 boilerplate applied) | DONE |
| `EXECUTION-PLAN-V11.0.md:247` (Batch 14b row) | REMOVE | Plan line 247 (rewritten as "(conditional in-session fix commit if needed — no BD)") | DONE |
| `EXECUTION-PLAN-V11.0.md:255` (Batch 21 Notes) | REMOVE | Plan line 255 (D-2 boilerplate applied) | DONE |
| `EXECUTION-PLAN-V11.0.md:256` (Batch 21b row) | REMOVE | Plan line 256 (rewritten as "(conditional in-session fix commit if needed — no BD)") | DONE |
| `EXECUTION-PLAN-V11.0.md:257` (Batch 22 Notes) | REMOVE | Plan line 257 (D-2 boilerplate adapted to "defects" wording) | DONE |
| `EXECUTION-PLAN-V11.0.md:258` (Batch 22b row) | REMOVE | Plan line 258 (rewritten as "(conditional in-session fix commit if needed — no BD)") | DONE |
| `EXECUTION-PLAN-V11.0.md:261` (Total math line trailing sentence) | REWRITE | Plan line 261 (renamed "fix-follow batches" → "in-session fix commits"; trailing sentence dropped — see finding F-1) | DONE |
| `EXECUTION-PLAN-V11.0.md:277-283` (entire §5.B subsection) | REMOVE | Plan lines 277-301 (D-3 replacement applied verbatim with the user's three refinements) | DONE |
| `EXECUTION-PLAN-V11.0.md:308` (validator regression note) | REWRITE | Plan line 326 (D-6 replacement applied) | DONE |
| `EXECUTION-PLAN-V11.0.md:361` (gate-table Final milestone audit) | REMOVE | Plan line 379 (rewritten as "Pack Chat presents findings, options, and asks the user how to proceed (per §B revised).") | DONE |
| `EXECUTION-PLAN-V11.0.md:362` (gate-table Dog-food migration) | REMOVE | Plan line 380 (same rewrite) | DONE |
| `PLAN-BD-119.md:914` ("one fix-follow batch") | REWRITE | Plan line 914 (D-7 replacement applied) | DONE |

**Coverage outcome:** 25 of 25 in-scope sites realized
(REMOVE + REWRITE + EDGE CASE = 12 + 6 + 7 per the discovery tally,
of which 4 EDGE CASE resolutions were applied per §3 below; the
remaining 3 EDGE CASE hits are KEEPs that require no edit and are
verified untouched).

No unmapped or partial sites detected.

---

## 3. EDGE CASE resolution check

| EDGE CASE | Resolution per spec | Realization | Status |
|---|---|---|---|
| **Decision 1** — trinity addendum (CLAUDE / AGENTS / GEMINI "One review/fix cycle per batch" bullet) | Apply D-8 with active-prohibition wording ("Pack Chat must not propose one") | One-line append at `CLAUDE.md:113` / `AGENTS.md:107` / `GEMINI.md:87`; byte-identical across all three | CORRECT |
| **Decision 2** — D-5 memory bullet for `feedback_review_fix_one_cycle.md` | Add affirmative bullet with active-prohibition wording ("never propose opening one") | New bullet at lines 23-28 of `feedback_review_fix_one_cycle.md`; includes "and never propose opening one" | CORRECT |
| **Decision 3** — `SEMANTIC-AUDIT-REPORT.md` disposition | Header note added; body frozen | One-line note at line 3: "Recommendations in §6 ('Followup BD list') and prose phrases like 'fix-follow' reflect the prior BD-for-fix policy, deprecated 2026-05-11. Treat the §6 entries as candidate in-session fixes for user approval, not as new BDs to open." Body unchanged. | CORRECT |
| **Decision 4** — KEEP supporting-docs end-user "file a BD" instructions (`DRY-RUN-MIGRATION.md:190` / `MIGRATION-v10-to-v11.md:336`) | KEEP — no edit | `git diff HEAD` shows neither file in the modified set; grep confirms the original wording is intact at the cited lines | CORRECT |

All four EDGE CASE resolutions are applied as specified.

---

## 4. KEEP-HISTORICAL spot-check

`git diff HEAD --name-only` returned six modified files, none in the
KEEP-HISTORICAL set (`AUDIT-*.md`, `IMPLEMENTATION-REPORT-*.md`,
`PACK-REVIEW-*.md`). Spot-checked three frozen files for any stray
edit:

| File | Modified in this batch? | Notes |
|---|---|---|
| `maintenance-docs/v11-implementation/AUDIT-BD-104.md` | NO | `git diff HEAD` shows no change |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-139.md` | NO | `git diff HEAD` shows no change |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-119.md` (and other PACK-REVIEW-*) | NO | None present in modified file list |

Additionally:
- `BACKLOG.md` is untouched — `git diff HEAD -- BACKLOG.md` returns
  empty. The 35+ Resolved-entry `fix-follow` mentions remain frozen
  per spec.
- `README.md`, `CHANGELOG.md`, `PACK-CHAT.md`, `PACK-AGENTS.md` are
  untouched — `git diff HEAD --` returns empty for all four.
- `RESEARCH-NON-APPLE-UI-SKILLS.md` is untouched (concurrent agent
  flag noted in discovery; no overlap on this batch's surface).

KEEP-HISTORICAL discipline is preserved.

---

## 5. Verbatim correctness check

### 5.1 §B replacement text (D-3 + three user refinements)

Spec text from `RULE-CLEANUP-DISCOVERY.md` §3 D-3 plus user refinements:
- Step 2 must add "Pack Chat does not start the fixes before approval."
- Step 5 must change to "without proposing a BD or asking whether to
  open one. The user alone decides…"
- Closing block must add "; Pack Chat must not propose one."

Realized text at `EXECUTION-PLAN-V11.0.md:277-301`:

```
### B. Audit / review-fix protocol (user rule, 2026-05-11)

1. Every audit/review pass that produces findings is fixed *in the
   current session*. No fix-follow BDs are opened.

2. Pack Chat reports the findings to the user (severity-grouped),
   presents fix options per finding (including NITs), and asks
   permission to fix. Pack Chat does not start the fixes before
   approval.

3. With user approval, Pack Chat ships the fixes in the same batch's
   commit, or in a small follow-up commit Pack Chat proposes and the
   user approves.

4. After review fixes land and validator/CI is clean, status flips
   per the implicit-flip rule (§C.4).

5. If review surfaces defects beyond the audit scope, Pack Chat
   surfaces them to the user as findings — without proposing a BD
   or asking whether to open one. The user alone decides whether
   a defect becomes a BD.

**BDs are reserved for new scope, new features, and new architecture —
never for closing audit findings. Only the user can initiate a
BD-for-fix conversation; Pack Chat must not propose one.**
```

All three user refinements present. Verbatim match. PASS.

### 5.2 Trinity addendum (D-8 + active-prohibition refinement)

Spec text: "Fixes land in the current session — never as a new BD.
BDs are reserved for new scope / new feature / new architecture; only
the user can initiate a BD-for-fix" + active-prohibition refinement
"Pack Chat must not propose one".

Realized text (`CLAUDE.md:113`, identical in AGENTS.md and GEMINI.md):

```
… is user-initiated. Fixes land in the current session — never as a new BD. BDs are reserved for new scope / new feature / new architecture; only the user can initiate a BD-for-fix, and Pack Chat must not propose one.
```

Verbatim match (with the active-prohibition refinement appended via
"and Pack Chat must not propose one"). PASS.

### 5.3 D-5 memory bullet (active-prohibition refinement)

Realized text at `feedback_review_fix_one_cycle.md:23-28`:

```
- **Fixes land in the current session.** Findings — at every severity,
  including NITs — are fixed inside the session that ran the review (or
  in a Pack-Chat-approved follow-up commit). Never open a new BD for an
  audit/review finding, and never propose opening one. BDs are reserved
  for new scope / new feature / new architecture work, and only the
  user can initiate a BD-for-fix conversation.
```

Active-prohibition refinement ("and never propose opening one")
present. PASS.

### 5.4 Trinity byte-identity

Diff command: `diff <(sed -n '110,118p' CLAUDE.md) <(sed -n '104,112p' AGENTS.md)`
Result: identical (zero output).

Diff command: `diff <(sed -n '110,118p' CLAUDE.md) <(sed -n '85,93p' GEMINI.md)`
Result: identical (zero output).

`git diff HEAD --shortstat -- CLAUDE.md AGENTS.md GEMINI.md`:
`3 files changed, 3 insertions(+), 3 deletions(-)` — exactly one line
replaced in each, no neighboring shift. PASS.

---

## 6. Semantic integrity findings

### F-1 (NIT) — Total commit-budget sentence drop in `EXECUTION-PLAN-V11.0.md:261`

**File:line:** `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md:261`

**Issue:** The original Total math line ended with "Could be more if
any audit / dog-food fix-follow needs more than one commit." The
revision drops this sentence and converts the budget into a hard
ceiling: "= max 28 commits … putting practical max at ~31 commits."
The new §B (point 3) still permits fixes to ship "in the same batch's
commit, OR in a small follow-up commit Pack Chat proposes and the
user approves" — which is per-batch single, but combined across all
three audit/dog-food gates (Batches 14b/21b/22b) the upper bound
remains "+3 conditional commits" only if each gate triggers and uses
a single follow-up commit. If a single conditional batch's fixes
require splitting (e.g., one commit per pack-coder run), the
"~31 commits" ceiling can still be exceeded. The dropped sentence
provided that escape hatch in prose.

**Severity:** NIT. The new wording reads "small follow-up commit"
(singular) which is a soft constraint that aligns with the affirmative
rule. Reasonable readers will not be misled. The NIT is purely
conservative — under the new rule "small follow-up commit" caps each
conditional gate at ~1 commit, so the math holds in the common case.

**Proposed wording (optional):** Append to the Total line: "Could be
slightly higher if any audit / dog-food gate needs more than one
small follow-up commit."

### F-2 (NIT) — "(§B revised)" cross-ref token

**File:lines:** `EXECUTION-PLAN-V11.0.md:246, 255, 257, 379, 380`

**Issue:** Five inline references read "(§B revised)" or "(per §B
revised)". The target section is now titled "B. Audit / review-fix
protocol (user rule, 2026-05-11)" — the word "revised" appears
nowhere in the section header. A reader unaware of this batch may
search for a literal "§B revised" header and not find it. The intent
("the revised §B") is clear from context, but the parenthetical
disambiguation lives only in the cross-ref token, not the section
title.

**Severity:** NIT. The single §B section is unambiguous; "revised"
just signals "the new replacement protocol, not the deprecated §5.B."
After the deprecated §5.B is fully purged from active prose (already
true in the modified files — only Resolved BACKLOG entries retain
"§5.B"), the qualifier is more historical-context than navigational.

**Proposed wording (optional):** Drop the "revised" qualifier in all
five sites: "Per the in-session fix rule (§B), …" / "(per §B)". The
section header date "(user rule, 2026-05-11)" carries the
revision-marker information.

### Semantic checks that PASSED (no findings)

- **`feedback_implicit_status_flip.md` end-to-end coherence.** Read
  the post-edit file (lines 1-36) end to end. Vocabulary is now
  uniformly "review fixes" / "review-fix commit"; no "fix-follow"
  surface remains. The internal cross-ref to
  `feedback_review_fix_one_cycle.md` at line 34 is still valid —
  the linked file's title ("One review/fix cycle per BD batch") is
  unchanged. No internal contradictions; no stale phrasing.
- **Implicit BD-opening language outside the locked negations.**
  Grep for `spawn.*BD`, `opens.*BD`, `open.*fix-follow`, `file.*fix-follow`,
  `queue.*BD` across the modified files yielded only:
  - The two locked negations in EXECUTION-PLAN ("No fix-follow BDs
    are opened" / "No fix-follow BD is opened") — correct per spec.
  - `EXECUTION-PLAN-V11.0.md:223` ("Batch 5 stops the BACKLOG from
    claiming work is open that's already done AND opens the 7 new
    BDs in one hygiene commit") — KEEP, refers to NEW-SCOPE BDs in
    Batch 5 hygiene, not BD-for-fix.
  - `EXECUTION-PLAN-V11.0.md:392` ("Ready to fire Batch 5 (BACKLOG
    hygiene + new-BD opens)…") — KEEP, same NEW-SCOPE meaning.
  - `PLAN-BD-119.md:610` ("PM chat opens the follow-up BD") — KEEP,
    refers to a *deferred new-architecture BD* ("a new BD in v11
    scope (\"BD-NNN — express init-project.sh --update as a vN→vN
    self-migration against the framework\")"), explicitly classified
    as KEEP in the discovery report (multi-site `…a new BD…`
    references at PLAN-BD-119 lines 110/455/603/671/762/843).
- **"fix-follow" outside negations.** All remaining `fix-follow`
  occurrences in the active-prose modified files are inside negation
  phrasings ("No fix-follow BDs are opened" / "No fix-follow BD is
  opened"). All other `fix-follow` mentions in the repo are in
  Resolved BACKLOG entries (KEEP-HISTORICAL) or in supporting-docs
  unrelated content (`5.B` Apple swift-format setup section).
- **§5.B repo-wide check.** Three remaining `§5.B` references all
  live in `BACKLOG.md` Resolved-status entries (BD-139 lines 1340 /
  1350; BD-137 line 1369). All KEEP-HISTORICAL. No active prose
  retains the deprecated section reference.

---

## 7. Trinity verification

```
$ diff <(sed -n '110,118p' CLAUDE.md) <(sed -n '104,112p' AGENTS.md)
(no output — identical)

$ diff <(sed -n '110,118p' CLAUDE.md) <(sed -n '85,93p' GEMINI.md)
(no output — identical)

$ git diff HEAD --shortstat -- CLAUDE.md AGENTS.md GEMINI.md
 3 files changed, 3 insertions(+), 3 deletions(-)
```

The trinity bullet is byte-identical across all three files. Single
line replaced in each — no neighboring content shift, no asymmetry
introduced.

---

## 8. Validator output

```
$ python3 scripts/validate-pack.py
…
── Check 30: Recommendation-state JSON schema (BD-079) ──
  OK: .pack-tracker/recommendation-state.json absent — lazy-create is by design, nothing to validate

============================================================
PASSED — all checks clean
```

All 30 checks PASSED. No new validator warnings introduced.

---

## 9. Findings list

| # | Severity | File:line | Issue | Proposed fix wording |
|---|---|---|---|---|
| F-1 | NIT | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md:261` | Total commit-budget converted from soft "max 28 + could be more" to hard "max 28" without an explicit escape clause for multi-commit conditional gates. | Append: "Could be slightly higher if any audit / dog-food gate needs more than one small follow-up commit." |
| F-2 | NIT | `EXECUTION-PLAN-V11.0.md:246, 255, 257, 379, 380` | Cross-ref token "(§B revised)" — section header does not contain the word "revised"; intent is clear from context but the qualifier is more historical-context than navigational once the deprecated §5.B is purged from active prose. | Drop "revised" in all five sites: "Per the in-session fix rule (§B), …" / "(per §B)". |

No BLOCKER findings. No SHOULD-FIX findings.

Per the new rule (codified by this very batch), the reviewer does
NOT propose opening BDs for these findings. Pack Chat presents the
NITs to the user and asks permission to fix in-session if the user
chooses.

---

## 10. Verdict rationale

The batch is a clean, faithful realization of
`RULE-CLEANUP-DISCOVERY.md`. Every REMOVE / REWRITE / EDGE CASE site
in §2 is realized; the four EDGE CASE resolutions are applied
exactly as decided; KEEP-HISTORICAL files (BACKLOG, all `AUDIT-*`,
`IMPLEMENTATION-REPORT-*`, `PACK-REVIEW-*`, the two supporting-docs
end-user instructions) are demonstrably untouched; the locked §B and
trinity-addendum and D-5 memory-bullet texts match the spec verbatim
including the user's three refinements (Step 2 "Pack Chat does not
start the fixes before approval", Step 5 "without proposing a BD or
asking whether to open one. The user alone decides…", closing-block
"Pack Chat must not propose one"); trinity edits are byte-identical
across CLAUDE / AGENTS / GEMINI per direct diff; `validate-pack.py`
PASSES (30/30); and no implicit BD-opening language remains in
active prose. The two NITs (F-1 commit-budget escape clause, F-2
"(§B revised)" cross-ref tokens) are stylistic and do not block
commit. Verdict: **Clean — ready for commit.**

---

**End of review.**
