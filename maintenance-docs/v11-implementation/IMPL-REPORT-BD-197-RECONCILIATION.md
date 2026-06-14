# IMPL-REPORT — BD-197 MANDATORY final design-reconciliation pass (Note-15 pre-Resolved gate)

**Role:** pack-coder (reconciliation pass). **Regime:** IN-PLACE (working tree; no `/tmp` handoff dir named by the prompt; report written to the named parent-tree path). **Scope:** `pack-only` (edits two `maintenance-docs/` design + plan docs).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD (start = end, unchanged):** `7da3380fc61e2b8cd094163f5ecb0d75ffe275be`.
**Date:** 2026-06-14. **Realized consumer of:** `backlog/BD-197.md` Note 15.

This pass reconciles the BD-197 design + plan DOCS to the AS-BUILT reality of the landed C0–C8b implementation, per the `architect-doc-reality-reconciliation` rule, before BD-197 is flipped Resolved. No code/tests/project surfaces were touched.

---

## 1. Read attestation

I read each NAMED authoritative input DIRECTLY and IN FULL (no skim, no summary, no crop, no derivation):

- `backlog/BD-197.md` — full (58 lines), Note 15 (the spec) read line-by-line + Notes 1–14 for context.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — the doc reconciled: §13 / §13.1 / §13.1a / §13.2 / §13.3 (guard sections), §11.2 (operational-mention `implementation-report` refs), §12.2 (project-side mechanism homes), §14 (architect-doc-vs-reality reconciliation), §5.4 (verb-parity CI guard), the top "Correction pass (2026-06-14)" note, §15/§16 — all read in full before editing.
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` — §A (commit sequence), §B (C2 line 89 pack skill; C7a line 138 project skill), §J3 (Guard-C fold-vs-standalone), §F (re-measurement EE blocks), §I (coder spawn map) — read in full for the stale references.
- `scripts/validate-pack.py` — the AS-BUILT SSOT; grepped + read the Check 52–57 def headers, docstrings, and constant blocks BEFORE writing any check number/guard name into the docs (evidence §2).
- `CLAUDE.md` § "## Pack memory" — `architect-doc-reality-reconciliation`, `edit-in-place-not-full-rewrite`, `empirical-evidence-blocks`, `enumerate-encoding-surfaces`, `verify-full-ci-suite`, `scope-deliverables-to-the-ask`, `agents-never-commit`, `rules-applied-verification-block` — read in full.
- `.github/workflows/validate-pack.yml` — read in full to enumerate every wired script for the full-CI-suite verification.
- Supporting confirmation (read, not edited): `IMPL-REPORT-BD-197-C7a.md` §2.6/§8/D-1 (the project skill-name correction), `IMPL-REPORT-BD-197-C5.md` (Guard-C standalone Check 56), `IMPL-REPORT-BD-197-C7b.md` §2 (standalone Check 57), `PACK-REVIEW-BD-197-C7b.md` NIT-1/NIT-2 (the disposition language).

---

## 2. AS-BUILT grep evidence (Empirical-Evidence Block — measured BEFORE writing)

**Empirical-Evidence Block EB-1 — realized check numbers + the two Guard-C checks.**
- **Command:** `grep -oE 'Check [0-9]+' scripts/validate-pack.py | sort -u` (range tail) + `grep -nE 'def check_...' scripts/validate-pack.py` (function names) + per-check header comment reads.
- **Output (HEAD `7da3380`, 2026-06-14):** highest realized check = **Check 57**; the BD-197 guard map confirmed:

| Guard (design) | AS-BUILT Check | Function name (verified exact) | Commit |
|---|---|---|---|
| Guard-B pack (§13.2) | **Check 52** | `check_pack_rw_ro_two_class` | C3 |
| Guard-A flip-block (§13.1) | **Check 53** | `check_worktree_isolation_prohibition_flip_block` | C5 |
| Guard-A′ OPTIONAL-FEATURES presence (§13.1a) | **Check 54** | `check_optional_features_presence` | C8b |
| Guard-B project (§13.2) | **Check 55** | `check_project_rw_ro_two_class` | C6b |
| Guard-C pack verb-parity (§13.3) | **Check 56** | `check_destructive_git_verb_parity` | C5 |
| Guard-C project verb-parity (§13.3) | **Check 57** | `check_project_destructive_git_verb_parity` | C7b |

- **The two Guard-C checks (56+57), verbatim from the source:**
  - `scripts/validate-pack.py:8694`: `# ── Check 56: BD-197 destructive-git-verb enumeration parity (Guard-C) ─────`
  - `scripts/validate-pack.py:9096`: `# ── Check 57: BD-197 PROJECT destructive-git-verb enumeration parity ───────` / `:9097 #              (Guard-C project)`
  - `:8790 def check_destructive_git_verb_parity()` (Check 56, pack) ; `:9246 def check_project_destructive_git_verb_parity()` (Check 57, project).
- **The measure-then-bound split reason, verbatim (`:9112`–`:9128`):** Check 56 is "sized to the FULL §5.1 28-verb set across 10 PACK surfaces"; "The PROJECT surfaces are heterogeneous … the project-consistent verb set is a measured INTERSECTION of 8 verbs … NOT the 28-verb pack set, and the catch-all principle phrase is TRINITY-ONLY"; "A separate, single-responsibility Check 57 is cleaner (decision 8 escape hatch)."
- **The 8-verb project intersection (`:9215`–`:9218`):** `checkout, clean, merge, rebase, reset, restore, stash, worktree`.
- **CI wiring confirmation (`validate-pack.yml`):** Check 52 (line 215), 53 (218), **56 (221)**, 55 (224), **57 (227)**, 54 (230) — each wired to its own `test-validate-pack-check-NN.sh`.
- **Interpretation:** the design's earlier "single conceptual Guard-C (optional, P3 architect call)" framing + any reserved/placeholder numbering is SUPERSEDED by this measured map. Guard-C realized as TWO standalone checks; C7b was PRESENT (not dropped) → 12 commits, not 11.
- **Conclusion:** **SUPPORTED** — the as-built numbers + the 56+57 split are confirmed against the live source before being written into the docs.

**Empirical-Evidence Block EB-2 — the project skill SSOT (Note 15(c) / C7a D-1).**
- **Command:** `ls -la project-template/skills/implementation/SKILL.md` + `ls project-template/skills/implementation-report/`.
- **Output (HEAD `7da3380`):** `project-template/skills/implementation/SKILL.md` EXISTS (3699 bytes); `project-template/skills/implementation-report/` → "No such file or directory". The pack-side `.claude/.codex/.gemini/skills/implementation-report/` DO exist (the legitimate pack skill).
- **Interpretation:** the project-side `implementation-report` skill the design/plan referenced does NOT exist; the real project report-step SSOT is `project-template/skills/implementation/SKILL.md` (P-missed-7 — a pack-style name was reached for a project surface). C7a D-1 landed the regime-aware step there.
- **Conclusion:** **SUPPORTED** — the project skill-name reference must be corrected to `project-template/skills/implementation/SKILL.md`.

---

## 3. Per-delta reconciliations (Note 15, 1–4) — before/after

### Delta 1 — Guard-C realized as TWO checks (Note 15(a)) — DESIGN §13.3

- **Before:** `### 13.3 Guard C (optional, P3 architect call) — verb-enumeration parity` — a single conceptual guard, "MAY fold into existing trinity-parity + bijection checks rather than a new check."
- **After:** `### 13.3 Guard C — verb-enumeration parity — REALIZED AS TWO CHECKS (Check 56 pack + Check 57 project)`. Documents: (i) the design intent (single conceptual guard, coder's-call fold decision 8); (ii) AS-BUILT **Check 56** (Guard-C pack, `check_destructive_git_verb_parity`, C5 — 28-verb set / 10 pack surfaces) + **Check 57** (Guard-C project, `check_project_destructive_git_verb_parity`, C7b — 8-verb intersection / trinity-only catch-all / 52 project surfaces); (iii) the measure-then-bound WHY (pack closed 28-verb absolute ban vs heterogeneous project surfaces → folding over-complicates → standalone per decision-8 escape hatch); (iv) the realized-count consequence (C7b PRESENT, not dropped → 12 commits). Source attributed to the C7b reviewer NIT-2.

### Delta 2 — Realized CI check numbers (Note 15(b)) — DESIGN §13.1 / §13.1a / §13.2 / §13.3 + the Reconciliation note

- **Before:** §13.1 / §13.1a / §13.2 named the guards (A / A′ / B) but carried NO check numbers (they predate realization); §13.3 had no number.
- **After:** each guard heading now carries an "AS-BUILT: realized as `Check NN` (`function_name`), shipped in CN" line, confirmed by grep:
  - §13.1 Guard-A → **Check 53** (`check_worktree_isolation_prohibition_flip_block`, C5).
  - §13.1a Guard-A′ → **Check 54** (`check_optional_features_presence`, C8b) + the note that number order ≠ commit order (54 lands last).
  - §13.2 Guard-B → **Check 52** pack (`check_pack_rw_ro_two_class`, C3) + **Check 55** project (`check_project_rw_ro_two_class`, C6b).
  - §13.3 Guard-C → **Check 56** pack + **Check 57** project (above).
  - The new "## Reconciliation pass" note (item 2) carries the full as-built map in one table for quick reference.

### Delta 3 — C7a D-1 project skill-name correction (Note 15(c), P-missed-7) — DESIGN §12.2 + PLAN §B C7a

- **Before (design §12.2 project bullet):** `… + project-template/skills/implementation-report/SKILL.md (+ mirrors) + …`.
- **After (design §12.2):** `… + project-template/skills/implementation/SKILL.md (the regime-aware report step) + …`, plus an explicit AS-BUILT correction sentence (Note 15(c) / C7a D-1 / P-missed-7) stating there is NO project-side `implementation-report` skill and the earlier reference was a pack-style name reached for a project surface, corrected to the project's own SSOT.
- **Before (plan line 138):** `- project-template/skills/implementation-report/SKILL.md (+ mirrors) — regime-aware report step.`
- **After (plan line 138):** points to `project-template/skills/implementation/SKILL.md` + the same AS-BUILT correction note.
- **Preserved (intentionally unchanged):** all PACK-side `implementation-report` references — design §11.2 (`.claude/.codex/.gemini/skills/implementation-report/SKILL.md` ×3), design §12.2 pack bullet, design §14 (`implementation-report`/`pack-coder` operational mentions), plan line 89 — these name the legitimate pack skill, which EXISTS.

### Delta 4 — C7b NIT-1 disposition (Note 15(d)) — DESIGN §13.3

- **Before:** unaddressed (NIT-1 lived only in `PACK-REVIEW-BD-197-C7b.md`).
- **After:** §13.3 records the **WON'T-FIX, accepted-as-harmless** disposition for Check 57's `_check_57_verb_present` ≥4-member slash-run branch: it can theoretically false-positive on a benign 4-segment lowercase path (e.g. `docs/pack/changelog/reset`), but (i) a false-positive can only make a surface look MORE compliant, never spurious-fail; (ii) no real surface relies on it (the entire slash contribution comes from the 6 legitimate Codex `Forbidden:` lists); tightening it would be gold-plating, not a defect fix.

### Dated reconciliation note — DESIGN (new "## Reconciliation pass (2026-06-14, BD-197 Note-15 gate)")

Added a top-level pass note (a sibling of the existing "## Correction pass (2026-06-14)" — the established convention for pass notes above §0 in this doc), summarizing deltas 1–4, carrying the full as-built check-number table, and laying out the reconciliation chain (a) in-code docstrings, (b) this addendum + §13 updates, (c) this IMPL-REPORT — cross-referencing `backlog/BD-197.md` Note 15.

### Dated reconciliation note — PLAN (new AS-BUILT block under §J3)

Added a blockquote AS-BUILT RECONCILIATION note under §J3 (the canonical Guard-C home in the plan) that SUPERSEDES the contingent plan-time "Guard-C fold / Check 56 ext / may-drop-to-11 / C7b may be dropped" framing throughout §A–§J. It states the realized 56+57 standalone outcome, the 12-commit count, and the full check-number map, and instructs the reader to read the as-built outcome wherever the plan's plan-time contingent phrases appear. (The plan-time contingent phrases themselves are LEFT IN PLACE as auditable planning history per `edit-in-place-not-full-rewrite`; the J3 note is the single authoritative supersession anchor.)

---

## 4. No-stale-reference confirmation

| Check | Command | Result |
|---|---|---|
| No project-side `implementation-report` skill referenced as a real deliverable | `grep 'project-template/skills/implementation-report'` on both docs | Only inside the new AS-BUILT correction notes (explicitly labelling it the WRONG/non-existent name). All deliverable references now point to `project-template/skills/implementation/SKILL.md`. ✅ |
| No "Guard C (optional, P3 architect call)" single-guard framing in §13.3 | `grep -nE 'Guard C \(optional\|optional, P3 architect call'` on design | exit 1 (none). ✅ |
| No "reserved"/placeholder check numbering left as current | `grep -niE 'reserved.*(check\|number)\|Check NN'` on design | Only the new note line 43 ("earlier reserved … is SUPERSEDED"), which is the reconciliation statement, not a live placeholder. ✅ |
| All 6 guard check numbers (52–57) present + correct in §13 | `grep -nE 'Check 5[2-7]'` on design §13 | §13.1=53, §13.1a=54, §13.2=52+55, §13.3=56+57 — all present. ✅ |
| Plan contingent Guard-C framing superseded (not silently deleted) | §J3 AS-BUILT note present; plan-time phrases retained as history | The single supersession anchor states the realized outcome; the 14 plan-time contingent phrases are auditable history pointed at the J3 note. ✅ |
| Pack-side `implementation-report` refs preserved (legit skill) | `grep '.claude/.codex/.gemini/skills/implementation-report'` | Design §11.2 + plan line 89 unchanged. ✅ |

---

## 5. Full-CI-suite results (verify-full-ci-suite — NO sampling)

Ran EVERY script wired in `.github/workflows/validate-pack.yml`. The fixture-build step ran `test-fixtures/build.sh --all --clean`; the workflow's `git checkout HEAD -- test-fixtures/manifest.txt` restore step was reproduced with the **read-only** equivalent `git show HEAD:test-fixtures/manifest.txt > test-fixtures/manifest.txt` (no denied git verb run — see §7).

**validate job (both invocations):**

| Step | Command | EXIT |
|---|---|---|
| Run pack validation | `python3 scripts/validate-pack.py` | **0** (`PASSED — all checks clean`) |
| Run pack validation DEEP | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** (`PASSED — all checks clean`) |

**tests job (every step, in workflow order) — ALL EXIT 0:**

`scripts/test-detect.sh` 0 · `tracker-provider-test.sh` 0 · `tracker-config-test.sh` 0 · `tracker-init-test.sh` 0 · `tracker-agent-read-test.sh` 0 · `tracker-migrate-forward-test.sh` 0 · `tracker-migrate-reverse-test.sh` 0 · `tracker-migrate-roundtrip-test.sh` 0 · `test-tracker-phase-task.sh` 0 · `test-tracker-links.sh` 0 · `test-tracker-cycle-check.sh` 0 · `tracker-errors-test.sh` 0 · `tracker-config-schema-test.sh` 0 · `recommendation-state-schema-test.sh` 0 · `test-per-entry.sh` 0 · `test-validate-pack-checks-32-33-34.sh` 0 · `test-validate-pack-checks-36-37-38.sh` 0 · `test-validate-pack-check-39.sh` 0 · `test-validate-pack-check-40.sh` 0 · `test-validate-pack-check-41.sh` 0 · `test-validate-pack-check-18.sh` 0 · `test-validate-pack-check-16.sh` 0 · `test-validate-pack-check-19.sh` 0 · `test-validate-pack-check-42.sh` 0 · `test-validate-pack-check-43.sh` 0 · `test-validate-pack-check-44.sh` 0 · `test-validate-pack-check-45.sh` 0 · `test-validate-pack-check-46.sh` 0 · `test-validate-pack-check-removed-doc-advisory.sh` 0 · `test-validate-pack-check-49-field-faithfulness.sh` 0 · `test-validate-pack-check-50-codec-single-source.sh` 0 · `test-validate-pack-check-51-flip-block.sh` 0 · **`test-validate-pack-check-52.sh` 0** · **`test-validate-pack-check-53.sh` 0** · **`test-validate-pack-check-56.sh` 0** · **`test-validate-pack-check-55.sh` 0** · **`test-validate-pack-check-57.sh` 0** · **`test-validate-pack-check-54.sh` 0** · `tracker-deferral-gate-test.sh` 0 · `tracker-bd129-gh-repo-test.sh` 0 · `tracker-bd130-doctor-wired-test.sh` 0 · `tracker-bd132-race-test.sh` 0 · `tracker-bd133-header-preservation-test.sh` 0 · `tracker-bd134-close-retry-test.sh` 0 · `recommendation-test.sh` 0 · `pack-help-test.sh` 0 · `test-customization-preserve.sh` 0 · `test-init-project.sh` 0 · `test-migrate-v10-to-v11.sh` 0 · `test-migrate-v10-to-v11-dry-run.sh` 0 · `test-migrate-v10-to-v11-gates.sh` 0 · `test-migrate-v10-to-v11-decompose.sh` 0 · `test-migrator-core.sh` 0 · `test-migrator-manifest.sh` 0 · `test-migrator-capability-translation.sh` 0 · `test-fixtures/build.sh --all --clean` 0 · manifest restore (`git show` redirect) 0 · `test-fixtures/build.sh --verify` 0 · `test-v11-realistic-ot.sh` 0 · `test-migrator-skills.sh` 0 · `test-persona-contracts.sh` 0 · `template-translations-test.sh` 0 · `template-version-test.sh` 0 · `test-issue-forms.sh` 0

**Total:** 2 validate-job invocations + 61 tests-job scripts/steps = **ALL EXIT 0. Full CI suite GREEN.** Check 34 (cross-ref) is inside `validate-pack.py` → covered by the green validate-job; both doc edits stay green.

---

## 6. Manifest-unchanged confirmation

`maintenance-docs/` is NOT one of the four v11-surface dirs (`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`), so no manifest change is expected. Confirmed: `git diff --stat test-fixtures/manifest.txt` → EMPTY (manifest unchanged). `git status --short` shows ONLY the two edited docs. The `build.sh --all --clean` rebuild touched only gitignored fixture artifacts; the read-only `git show` redirect restored the committed manifest content exactly.

---

## 7. Git-state safety note (agents-never-commit)

The CI workflow's manifest-restore step uses `git checkout HEAD -- test-fixtures/manifest.txt` — a DENIED git verb for agents. I did NOT run it. I reproduced its intent with the read-only `git show HEAD:test-fixtures/manifest.txt > test-fixtures/manifest.txt` (writes file content via shell redirect; runs no state-changing git verb). Only read-only git verbs were run this pass: `git rev-parse`, `git status`, `git diff`, `git show`. No `add/commit/push/stash/reset/restore/checkout/mv/rm/apply/merge/rebase` etc. The orchestrator stages + commits.

---

## 8. Files changed inventory

| Path | Change type | Delta |
|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` | modified | +~38 / −3 (new "## Reconciliation pass" note + §13.1/§13.1a/§13.2/§13.3 as-built lines + §13.3 rewrite + §12.2 skill-name correction) |
| `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` | modified | +3 / −1 (line 138 skill-name correction + §J3 AS-BUILT note) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-RECONCILIATION.md` | new | this report |

Read-only patch emitted for auditability: `/tmp/bd197-reconciliation.patch` (101 lines, the two-doc diff). No new source files (this report is the only new file). No deletions. No project surfaces, code, or tests touched.

---

## 9. Plan deviations

ZERO functional deviations from the prompt's deltas 1–4. One implementation choice worth flagging (not a deviation): for the PLAN doc, the plan-time contingent Guard-C framing ("may drop to 11 commits / Check 56 ext / C7b may be dropped") was LEFT IN PLACE as auditable planning history and superseded via a single AS-BUILT anchor note under §J3, rather than hand-editing all 14 contingent phrases (which would risk a wholesale rewrite that drops the historical decision narrative — forbidden by `edit-in-place-not-full-rewrite`). The design doc (the authoritative as-built record) carries the fully-corrected §13.3 + numbers.

## 10. New POQs introduced

None.

## 11. Out-of-scope items noticed (surfaced, not fixed — scope-deliverables-to-the-ask)

- `scripts/validate-pack.py` contains **three** stale comments asserting Check 54 (Guard-A′) is "reserved" — forward-reference notes written by the C5 coder before Check 54 landed in C8b. One (in the Check 54 dispatch block) phrases the staleness as `Check number 54 — reserved for Guard-A′`; two others (in the Check 55 and Check 57 run-check dispatch blocks) phrase it as `54 is reserved for the C8b Guard-A′`. All three are purely cosmetic — Check 54 is fully implemented + CI-wired; the "reserved" wording is the only stale artifact. Editing `scripts/` is out of this pass's `pack-only` maintenance-docs scope. Deferred to **BD-219** (which runs directly after BD-197 resolves and adds `--only-check` to that file).
- BD-197 Note 12 already tracks a separate cosmetic stderr-noise nit in `test-validate-pack-checks-36-37-38.sh` (accept-for-now). Confirmed that test still EXIT 0 this pass; no action taken (out of scope).

---

## 12. Definition-of-Done checklist

| Item | PASS/FAIL | Evidence |
|---|---|---|
| Delta 1 — §13.3 documents the 56+57 split + why | PASS | §3 Delta 1; design §13.3 rewritten |
| Delta 2 — design check numbers match as-built (52–57) | PASS | §2 EB-1; §13.1/§13.1a/§13.2/§13.3 + Reconciliation note |
| Delta 3 — project skill name corrected to `implementation` (design + plan) | PASS | §2 EB-2; §3 Delta 3; design §12.2 + plan line 138 |
| Delta 4 — C7b NIT-1 won't-fix disposition recorded | PASS | §3 Delta 4; design §13.3 |
| Dated "## Reconciliation pass (2026-06-14, BD-197 Note-15 gate)" note added (design) | PASS | design top, sibling of "## Correction pass" |
| As-built confirmed by grep of validate-pack.py BEFORE writing | PASS | §2 EB-1/EB-2 |
| No stale single-Guard-C / stale-number / project `implementation-report` ref remains | PASS | §4 table (all checks pass) |
| Both design AND plan reconciled in lockstep (enumerate-encoding-surfaces) | PASS | both docs edited; §3/§4 |
| Full CI suite run, every script, exits quoted, no sampling | PASS | §5 (2 + 61 steps, all EXIT 0) |
| Manifest unchanged (maintenance-docs not v11-surface) | PASS | §6 (empty diff) |
| No git-state change; only read-only git | PASS | §7 |
| Edits in place, no wholesale rewrite; section maps intact | PASS | design §0–§18 + plan §A–§K maps verified unchanged |
| Report written to the exact named path | PASS | this file |

---

## 13. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | architect-doc-reality-reconciliation [coder] | Shipped the reconciliation chain: (a) in-code docstrings in `validate-pack.py` Checks 52–57 already name the realized consumers + cross-ref the design (verified by grep §2); (b) design §13.1/§13.1a/§13.2/§13.3 + the new "## Reconciliation pass" note name the realized consumers (Check 52–57, the project `implementation` skill) + cross-reference `backlog/BD-197.md` Note 15; (c) THIS IMPL-REPORT cross-references both. No line numbers cited (files+symbols only). | COMPLIANT |
| 2 | edit-in-place-not-full-rewrite [universal] | All 7 edits were targeted `old→new` replacements (each Edit asserted a unique match). Section maps re-verified after editing: design `grep '^## '` = §0–§18 + the two pass-notes, unchanged order; design §13.1–§13.3 sub-headings intact; plan `grep '^## '` = attestation + §A–§K + Rules-Applied, unchanged order. NO wholesale rewrite; plan-time contingent phrases retained as history (§9). | COMPLIANT |
| 3 | empirical-evidence-blocks [coder] | §2 EB-1 (check numbers + 56+57 split + 8-verb intersection, with command + verbatim source lines + HEAD `7da3380` + date 2026-06-14 + SUPPORTED) and EB-2 (project skill SSOT exists / `implementation-report` absent, SUPPORTED) measured BEFORE writing any number/name into the docs. | COMPLIANT |
| 4 | enumerate-encoding-surfaces [coder] | Reconciled BOTH encoding surfaces in lockstep: the DESIGN (§13.1/§13.1a/§13.2/§13.3/§12.2 + new note) AND the PLAN (line 138 + §J3 note). §4 no-stale-reference table confirms neither doc leaves a stale single-Guard-C / stale-number / project-`implementation-report` reference. | COMPLIANT |
| 5 | verify-full-ci-suite [universal] | Ran EVERY wired script: 2 validate-job invocations (incl. `PACK_VALIDATE_DEEP=1`) + 61 tests-job scripts/steps; every EXIT quoted in §5; ALL EXIT 0. No sampling. The 6 BD-197 guard tests (52/53/54/55/56/57) explicitly run + green. | COMPLIANT |
| 6 | scope-deliverables-to-the-ask [universal] | Edited ONLY the design + plan docs for deltas 1–4 + the reconciliation notes. NO code/tests changed, NO redesign, NO project surfaces touched. Two out-of-scope items (stale "54 reserved" in-code comment; the Note-12 stderr nit) SURFACED in §11, not fixed. | COMPLIANT |
| 7 | agents-never-commit [universal] | Only read-only git verbs run: `git rev-parse HEAD` → `7da3380fc61e2b8cd094163f5ecb0d75ffe275be`, `git status`, `git diff`, `git show`. The CI manifest-restore `git checkout HEAD -- ...` was NOT run — reproduced read-only via `git show … > file` (§7). No `add/commit/push/stash/reset/restore/checkout/mv/rm/apply`. HEAD unchanged. | COMPLIANT |
| 8 | rules-applied-verification-block [universal] | This block; every row carries quoted/measured evidence; no empty cell. | COMPLIANT |

---

*End of IMPL-REPORT-BD-197-RECONCILIATION.md — IN-PLACE regime; 2 docs modified + this report; nothing staged; HEAD `7da3380fc61e2b8cd094163f5ecb0d75ffe275be` unchanged; full CI suite green; read-only patch at `/tmp/bd197-reconciliation.patch`.*
