# IMPLEMENTATION-REPORT-BD-175-COMMIT-9B

**Commit:** 9b of BD-175 Phase 5
**Task:** TASK-T5 MERGE-STRATEGY D8.6 ref-update (Override 8 cascade)
**Branch:** `v11-dev`
**HEAD at start:** `4e240eca46e33940e52e3ab5953b406f72e4e832`
**HEAD at PREFLIGHT:** `4e240eca46e33940e52e3ab5953b406f72e4e832` (unchanged; no commits run by coder)
**Path A partition:** second half of TASK-T5 (Commit 9a landed audience-header amendment in parallel set ALPHA-EXPANDED; this commit lands the D8.6 ref-update sequentially after Commit 10).

---

## §1 Summary

Single-hunk REPLACE per PLAN-BD-175-PHASE-5.md §2.9b. At `pack-ops/MERGE-STRATEGY.md` Cross-references list, replaced the bare `` `OPTIONAL-FEATURES.md` `` reference with the resolvable `` `docs/pack/OPTIONAL-FEATURES.md` `` path. This is the D8.6 ref-update half of TASK-T5 under Path A (OQ-1 RESOLVED 2026-05-19), unblocked by Commit 10 which just created the project-side `project-template/docs/pack/OPTIONAL-FEATURES.md` SPLIT file. The reference now resolves cleanly at client repos after `init-project.sh` installs the project-side OPTIONAL-FEATURES.md to `<client-repo>/docs/pack/`. One file modified, one line changed (1 insertion, 1 deletion). No manifest regen (pack-ops/ is NOT v11-surface under current strict RC9 base case).

---

## §2 File changed

| Path | Action | Line delta |
|---|---|---|
| `pack-ops/MERGE-STRATEGY.md` | MODIFIED (single-hunk REPLACE in Cross-references list) | +1 / -1 |

Total: 1 file modified. No new files. No deletions. No manifest regen.

---

## §3 D8.6 edit (exact BEFORE / AFTER quote)

The PLAN-BD-175-PHASE-5.md §2.9b spec named L465 as the target line (the abstract spec line). The actual current line in the file at HEAD `4e240ec` is **L472** (line numbers drifted between the spec authoring and the post-Commit-2/3 relocation + Commit-9a audience-header amendment; the targeted text content is identical to the spec and unique in the file, so the Edit matched cleanly without ambiguity).

**BEFORE (L472, pre-edit):**

```
- `OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
```

**AFTER (L472, post-edit):**

```
- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
```

Architect-doc cross-reference: `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §3.5 D8.6 amendment ("REPLACE bare `OPTIONAL-FEATURES.md` with `docs/pack/OPTIONAL-FEATURES.md` per Override 8 S2 SPLIT").

Plan cross-reference: `PLAN-BD-175-PHASE-5.md` §2.9b.2 exact-edit block (which quotes BEFORE / AFTER identically to the actual edit applied; the only delta is the line-number `L465` vs actual `L472` drift noted above).

---

## §4 Pre-edit context (lines 460-475 quote)

```
2. Run `scripts/migrate-v10-to-v11.sh`.
3. Read `.pack-migrate-v10-to-v11/report.md`.
4. For each `customization-detected-needs-reconciliation` row, open
   the named sidecar, merge project content into the destination,
   remove the sidecar, `git add`.
5. Commit.
6. Remove `.pack-migrate-v10-to-v11-backup/` after sufficient
   confidence in the migration result.

---

## Cross-references

- `scripts/lib/customization-preserve.sh` — the BD-088 implementation
- `scripts/lib/customization-report.sh` — the report renderer
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests
- `MIGRATION-v10-to-v11.md` — the user-facing migration narrative
- `OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
- `QUICKSTART.md` — where to start
- `validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
```

The targeted bare reference is L472. Surrounding prose (the Cross-references list itself, its heading, the prior steps `1`-`6`, and the trailing lines) are unchanged.

---

## §5 Post-edit verification (all 5 verification command outputs)

### 5.1 Confirm Commit 10 landed (project-side file exists)

```bash
$ ls -la project-template/docs/pack/OPTIONAL-FEATURES.md
-rw-r--r--@ 1 david  staff  7872 May 19 14:40 project-template/docs/pack/OPTIONAL-FEATURES.md
```

PASS — file exists at HEAD `4e240ec` (Commit 10 landed pre-spawn).

### 5.2 Post-edit L472 verification

```bash
$ sed -n '472p' pack-ops/MERGE-STRATEGY.md
- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
```

PASS — L472 now reads `docs/pack/OPTIONAL-FEATURES.md` (no longer bare).

### 5.3 Resolvable-path hit count

```bash
$ grep -n "docs/pack/OPTIONAL-FEATURES" pack-ops/MERGE-STRATEGY.md
472:- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
```

PASS — exactly 1 hit at L472 (the new resolvable-path reference).

### 5.4 Bare-reference hit count

```bash
$ grep -n "\`OPTIONAL-FEATURES\.md\`" pack-ops/MERGE-STRATEGY.md
(no output)
```

PASS — ZERO remaining bare `` `OPTIONAL-FEATURES.md` `` hits in the file.

### 5.5 Working-tree scope

```bash
$ git status --short
 M pack-ops/MERGE-STRATEGY.md
$ git diff --stat
 pack-ops/MERGE-STRATEGY.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

PASS — only `pack-ops/MERGE-STRATEGY.md` modified; single-hunk REPLACE (1 insertion, 1 deletion); no manifest, no other files. (Note: `maintenance-docs/v11-research/*.md` were untracked at session start — those are pre-existing and untouched by this commit. The new IMPL-REPORT file at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md` is written AFTER PREFLIGHT per the prompt's flow; Pack Chat will see it as an additional untracked file at commit time.)

### 5.6 Full diff (for completeness)

```diff
$ git diff pack-ops/MERGE-STRATEGY.md
diff --git a/pack-ops/MERGE-STRATEGY.md b/pack-ops/MERGE-STRATEGY.md
index fe72f13..f3af573 100644
--- a/pack-ops/MERGE-STRATEGY.md
+++ b/pack-ops/MERGE-STRATEGY.md
@@ -469,7 +469,7 @@ default behavior):
 - `scripts/lib/customization-report.sh` — the report renderer
 - `scripts/tests/test-customization-preserve.sh` — class-coverage tests
 - `MIGRATION-v10-to-v11.md` — the user-facing migration narrative
-- `OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
+- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
 - `QUICKSTART.md` — where to start
 - `validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
```

PASS — minimal single-hunk diff exactly per spec.

### 5.7 HEAD SHA

```bash
$ git rev-parse HEAD
4e240eca46e33940e52e3ab5953b406f72e4e832
```

PASS — HEAD unchanged (no state-changing git verbs run by coder).

---

## §6 Out-of-scope observations

The single-hunk constraint scoped this commit to ONLY the D8.6 bare reference at L472. During the inspection of the Cross-references list (L468-L474), I observed **three sibling bare references** in the same list. They are documented here per the prompt's §6 directive for Pack Chat triage; **I did NOT touch them** (scope discipline).

### 6.1 Sibling bare references in the same list

L468-L474 currently reads:

```
- `scripts/lib/customization-preserve.sh` — the BD-088 implementation       [L468 — resolvable repo-relative path, OK]
- `scripts/lib/customization-report.sh` — the report renderer                [L469 — resolvable repo-relative path, OK]
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests      [L470 — resolvable repo-relative path, OK]
- `MIGRATION-v10-to-v11.md` — the user-facing migration narrative            [L471 — BARE reference — see §6.1.a]
- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough              [L472 — JUST FIXED per D8.6]
- `QUICKSTART.md` — where to start                                           [L473 — BARE reference — see §6.1.b]
- `validate-pack.py` Check 25 — CI regression guard for the truthful-report contract  [L474 — BARE reference — see §6.1.c]
```

**§6.1.a — L471 `MIGRATION-v10-to-v11.md`.** Currently a bare reference. Per `pack-ops/PACK-AGENTS.md` § "Agent permission rules" and the Commit 10 sequence (which moved boundary-relevant files to `pack-ops/`), this file's canonical location is likely `pack-ops/MIGRATION-v10-to-v11.md` (pack-side migration narrative). Recommend Pack Chat verify file location and triage as a Commit 12 (Architect C prevention mechanisms / M4 boundary-investigation skill) candidate, or as a separate BD-178-adjacent finding under the "bare-reference contamination" umbrella.

**§6.1.b — L473 `QUICKSTART.md`.** Currently a bare reference. Per the pack/project boundary remediation in BD-175, QUICKSTART.md's audience and install state need verification. If pack-side: `pack-ops/QUICKSTART.md`. If project-side: `docs/pack/QUICKSTART.md` (parallel to the OPTIONAL-FEATURES.md SPLIT pattern just established by Commit 10). If both audiences (SPLIT pattern): mirror the OPTIONAL-FEATURES SPLIT design. Recommend Pack Chat triage as a Commit 12 candidate or a new BD parallel to D8.6/D8.7.

**§6.1.c — L474 `validate-pack.py` Check 25.** This is a bare reference to a script + check number. The script lives at `scripts/validate-pack.py` per pack convention. Recommend updating to `` `scripts/validate-pack.py` Check 25 — ...`` for path-resolvability symmetry with the L468-L470 entries (which already use `scripts/lib/` and `scripts/tests/` prefixes). Lower-priority observation; arguably a stylistic/consistency finding rather than a contamination finding.

### 6.2 Recommended disposition

These three observations are **NOT contamination per the BD-175 §D §C re-litigation framework** (they don't necessarily represent project-side audience contamination in a pack-only file under V5 PRIMARY); they are **bare-reference hygiene observations** that surfaced incidentally during the D8.6 inspection. Recommended dispositions:

- **§6.1.a (L471 MIGRATION-v10-to-v11.md):** verify file location at HEAD; if pack-side moved to `pack-ops/`, the bare ref is broken — surface as a Commit 12 cleanup or new sub-BD.
- **§6.1.b (L473 QUICKSTART.md):** similar location-audit needed; potentially a parallel SPLIT candidate if it has dual-audience content.
- **§6.1.c (L474 validate-pack.py):** stylistic-consistency finding; can be a NIT-class fix bundled into Commit 12 broad-fix scope or deferred to a v11-cleanup BD.

**Per the "Deferral IS scope creep" rule**, these should NOT be silently deferred to "v11.1+" — they need explicit Pack Chat triage with user-discussion-and-approval per OQ-1 EXECUTION-PLAN §B. The pack-coder agent has NOT touched any of these; surfacing them here is the in-scope action (out-of-scope observation per §6 of this report's structure).

### 6.3 Prevention-mechanism candidate for Commit 12

The pattern observed in §6.1 (multiple sibling bare references in a single cross-reference list, where only one was caught by the §D contamination audit because it was the only one being newly resolved to a SPLIT file) suggests a candidate prevention mechanism for Commit 12 (Architect C prevention mechanisms scope):

- **Proposed check (additive, not in this commit):** a `validate-pack.py` check that scans MERGE-STRATEGY.md (and similar pack docs) for cross-reference list items where the entry is a bare filename (no path prefix) and the named file does NOT exist at the same directory as the doc. This would catch all three §6.1 observations as well as future similar drift.

This is a **suggestion**, not a commitment — Architect C's existing M1-M8 prevention-mechanism scope already covers boundary-investigation (M4), trinity doc amendment (M8), and deny-list checks (M5b Check 37 etc.). The §6.3 candidate may or may not fit within those existing mechanism scopes; Pack Chat / Architect C triage required.

---

## §7 PREFLIGHT line (paste exactly)

```
PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD 4e240eca46e33940e52e3ab5953b406f72e4e832; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md
```

PREFLIGHT was emitted in the parent chat stream BEFORE this IMPL-REPORT was written, per the STOP-MEANS-STOP / PREFLIGHT pattern in CLAUDE.md.

---

## §8 Definition-of-Done checklist

| Item | Status | Note |
|---|---|---|
| L472 (PLAN-spec L465; actual L472) reads `docs/pack/OPTIONAL-FEATURES.md` | PASS | See §5.2 |
| Project-side file exists at HEAD | PASS | See §5.1 (Commit 10 landed) |
| `grep "docs/pack/OPTIONAL-FEATURES"` ≥ 1 hit | PASS | See §5.3 (exactly 1 hit) |
| Zero bare `` `OPTIONAL-FEATURES.md` `` hits remain | PASS | See §5.4 (zero hits) |
| No edits outside `pack-ops/MERGE-STRATEGY.md` | PASS | See §5.5 |
| No state-changing git verbs run | PASS | HEAD unchanged at `4e240ec` (see §5.7); only read-only `status`/`diff`/`rev-parse` used |
| No manifest regen needed | PASS | `pack-ops/` is NOT v11-surface under current strict RC9; diff shows only `pack-ops/MERGE-STRATEGY.md` |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS | See §7 |
| Single-hunk diff (1 insertion, 1 deletion) | PASS | See §5.5 / §5.6 |
| File reads cleanly end-to-end post-edit | PASS | 482 lines total; tail shows clean trailing-`>`-quoted block (no truncation, no syntax break) |
| Trinity rule N/A | PASS | MERGE-STRATEGY.md is single-file pack-side doc (no AGENTS.md/GEMINI.md parallel) |
| No prior PACK-REVIEW or IMPL-REPORT reads | PASS | Prompt forbade reading prior reports for this BD; not read |

All 12 DoD items PASS.

---

## §9 Plan deviations

**Zero plan deviations.** The implementation exactly matches PLAN §2.9b.

One **non-deviation clarification**: the spec named L465 as the target line; the actual current line at HEAD `4e240ec` is L472. Line-number drift between PLAN authoring and HEAD execution is normal (post-Commit-2/3 relocation + Commit-9a audience-header amendment moved content within the file). The Edit matched on **content uniqueness**, not line number — the target string `` - `OPTIONAL-FEATURES.md` — tracker opt-in walkthrough `` was unique in the file, so the Edit was unambiguous and correct. The PLAN's exact-edit BEFORE/AFTER quote is byte-identical to the applied edit. Per the pack-memory rule "Architect-doc-vs-reality reconciliation" and the "never use line numbers" guidance in code-comment style, this kind of line-number drift is expected and is reconciled by content matching, not by treating the line number as authoritative.

---

## §10 New POQs introduced

**None.** The three observations in §6 are documented for Pack Chat triage but are NOT new POQs (Pack Open Questions) in the architectural sense — they are bare-reference hygiene findings that may inform Commit 12 (Architect C prevention mechanisms) scope or new sub-BDs but do not represent unresolved architectural questions.

---

## §11 Files changed inventory

| Path | Change type |
|---|---|
| `pack-ops/MERGE-STRATEGY.md` | MODIFIED (+1 / -1; D8.6 ref-update) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md` | NEW (this report — written AFTER PREFLIGHT per the prompt's flow; will appear as untracked at commit time) |

No deletions. No other modifications. No manifest regen.

---

## §12 Commit handoff notes for Pack Chat

- **Suggested commit message** (per CLAUDE.md `feat: vN — BD-NNN ...` form):
  ```
  feat: v11 — BD-175 TASK-T5 MERGE-STRATEGY D8.6 ref-update (Override 8 cascade)
  ```
- **Files to stage:** `pack-ops/MERGE-STRATEGY.md` (and this IMPL-REPORT, per pack convention — Pack Chat decides whether to stage IMPL-REPORTs inline or via the standard Phase-end sweep).
- **No manifest stage needed** (pack-ops/ not v11-surface per RC9 base case; PLAN §2.9b.2 explicitly confirms "NO manifest").
- **Sequential commit:** this is the second-to-last commit of the Path A sequential tail (10 → 9b → 12). After this commit lands, Commit 12 (Architect C prevention mechanisms) is the next and final commit of BD-175 Phase 5.
- **No trinity edit needed** (MERGE-STRATEGY.md is single pack-side migration doc; no AGENTS.md/GEMINI.md mirrors).
- **CI expectations:** no CI signal changes specific to this commit (no scripts touched, no fixtures touched, no project-template touched, no manifest touched). The full pack-validation suite should run identically to pre-edit state, with the resolvable `docs/pack/OPTIONAL-FEATURES.md` path now matching the project-side file Commit 10 added.

---

End of IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.
