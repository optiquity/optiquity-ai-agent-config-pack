# IMPL-REPORT — BD-197 C6b — Guard-B-project (Check 55) RW/RO consistency

**Role:** pack-coder (fresh, C6b). **Commit half:** C6b — P3 Guard-B(project) RW/RO consistency check (GUARD; `pack-only`).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** `v11-dev` (in-place regime).
**HEAD at start AND end (no commit — agents never commit):** `4226dc84bf99fdb20cc6599076655a09698b39f4` (C6a, committed).
**Date:** 2026-06-14.
**Regime:** IN-PLACE (cwd = main v11-dev checkout, branch `v11-dev`; NOT a `worktree-agent-*` worktree). The prompt named NO `/tmp` handoff dir → edits land in the working tree; this report is written to the parent-tree path the prompt specified.

---

## 1. Read attestation (no skim / no derivation)

I read each NAMED authoritative input directly and in full before editing:

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — §13.2 (Guard-B design: PROJECT = set-equality across the three legs; **bind to the PROSE mandate header, NEVER `tools:`**), plus §4.3 project (the triple-reinforcement RW/RO declaration), §13 measure-then-bound contract preamble, §13.1/§13.1a/§13.3 (the sibling guards, to size the number + tolerate the gap), and §14/§15 readiness. Read via Read (lines 1–285) + targeted Grep/Read of §13.2 (lines 526–615).
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` — §B C6a (the DATA half I depend on) + §B C6b (my spec) + §B C7a/C7b/C8a/C8b (the boundary — I do NOT do them). Plus §E Guard-B (measure-then-bound steps), §F EE-1/EE-5/EE-6 (battery/agent-count/check-number measurements), §H (enumerate-encoding-surfaces row for Check 55), §I C6b (rules-in-force), §J (decision ledger — decisions 2/4/6/7 and J-resolved-13 the expected-empty manifest).
- `maintenance-docs/v11-implementation/RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md` — §1.2 (project = 16 agents per CLI; 2 RW `coder`/`repo-ops` + 14 RO; READONLY_AGENTS = 14; Gemini files carry NO `tools:`) + §2.2 + the reconciliation table.
- `scripts/validate-pack.py` — the EXISTING Guard-B(pack) **Check 52** implementation (lines 8232–8388, mirrored for the project version), the **Check 51 self-skip/allowlist precedent** (`entry.name == "validate-pack.py"` at `:2169`), the **Check 56** project-style multi-surface guard, the `run_check()` runtime-guard wrapper (`:463`, per-check WARN budget 2.0s) + the highest existing check number, the `ok`/`fail` helpers (`:406`/`:411`).
- The three legs Guard-B-project asserts: `project-template/docs/pack/PM-CHAT.md` `## Permission profiles` table (lines 397–468, the SSOT); `project-template/agent-run.sh` `READONLY_AGENTS` (lines 38–53, 14 entries); the per-agent prose mandate headers in `project-template/.{claude,codex,gemini}/agents/*` (48 files).
- `CLAUDE.md` `## Pack memory` — `ci-guard-design-measure-then-bound`, `ci-check-runtime-compounding`, `enumerate-encoding-surfaces`, `verify-full-ci-suite`, `edit-in-place`, `regenerate-manifest-v11-surface`, `empirical-evidence-blocks`, `preflight-stop-means-stop`, `agents-never-commit`, `scope-deliverables-to-the-ask`, `rules-applied-verification-block`.
- Curated memory files: `feedback_ci_guard_design_measure_then_bound.md`, `feedback_ci_check_runtime_compounding.md`, `feedback_verify_full_ci_suite.md`, `feedback_manifest_regen_on_v11_surface.md`.

---

## 2. The Guard-B-project spec (what Check 55 asserts)

**Check 55 — BD-197 project RW/RO two-class consistency (Guard-B project).** The PROJECT analog of Guard-B(pack) (Check 52). It asserts SET-EQUALITY across the THREE project legs:

```
{PM-CHAT.md `## Permission profiles` Read-only rows}
  ↔ {project-template/agent-run.sh READONLY_AGENTS array}
  ↔ {per-agent-file PROSE mandate headers (RO)}
```

and that the RW set = exactly `{coder, repo-ops}`, for the 16 project agents × 3 CLIs.

- **Binds to the PROSE mandate header, NEVER `tools:`** (design §13.2). Discriminators: `**Read-only.**` = RO; `**Write-capable (scoped).**` / `**Write-capable (script).**` = RW. The `tools:` line is irrelevant to the class.
- **Measure-then-bound:** sized to the measured 16-agent set (2 RW + 14 RO) — `_CHECK_55_PROJECT_AGENTS` (16), `_CHECK_55_RW_AGENTS = ("coder","repo-ops")`, `_CHECK_55_AGENT_DIRS` (3 CLIs). A new agent / CLI requires extending these tuples in lock-step (commented in-code).
- **Three failure modes per leg:** PM-CHAT RO set ≠ expected; READONLY_AGENTS RO set ≠ expected (or a stray unknown token); per-file header class ≠ expected (or no recognized header → unclassified).
- **GREEN on arrival** because C6a (`4226dc8`) already made the three legs set-consistent.

Implementation: `scripts/validate-pack.py`, function `check_project_rw_ro_two_class()` + helpers `_check_55_pm_chat_ro_rows()`, `_check_55_readonly_agents()`, `_check_55_header_class()`; registered in `main()` via `run_check("check_project_rw_ro_two_class", check_project_rw_ro_two_class)` after Check 56. (Architect-doc-reality-reconciliation: the realized consumer of design §13.2 / §4.3-project is `scripts/validate-pack.py` `check_project_rw_ro_two_class` + `_CHECK_55_*`; this report is the IMPL cross-reference.)

---

## 3. Check number — re-measure, NOT assume (decision recorded)

The plan reserved **Check 55** for Guard-B-project, but that predates later commits. I RE-MEASURED live (do NOT assume):

```
$ grep -oE 'Check [0-9]+' scripts/validate-pack.py | grep -oE '[0-9]+' | sort -n | uniq | tail
...51 52 53 56
```
- HEAD `4226dc84bf99fdb20cc6599076655a09698b39f4`, 2026-06-14.
- **Highest existing check = 56** (Guard-C, landed in C5 `8e62a2e`). Present BD-197 checks: 52 (Guard-B pack, C3), 53 (Guard-A, C5), 56 (Guard-C, C5).
- **Check 54 and Check 55 are BOTH unused** (`grep 'Check 54\|Check 55' scripts/ .github/` → no hits; no `test-validate-pack-check-54/55` files).
- **Check 54 is reserved** for the not-yet-landed C8b Guard-A′ (per the plan §I C8b / §J2). **Check 55 is reserved for me** (Guard-B-project, per the plan §B C6b).

**Chosen number: Check 55.** Rationale: it is the next available number consistent with the plan's intent — it does NOT collide with anything landed, and it preserves Check 54 for C8b's Guard-A′ (numbers are assigned at authoring, not by commit order). After C6b lands and BEFORE C8b lands, the sequence reads `...52 53 55 56` — a non-contiguous gap (54 unfilled) which is **expected and tolerated**: C8b fills 54 later. I verified NO validator/test requires contiguous check numbers (`grep -rn 'contiguous\|range(.*Check'` → only an unrelated prose hit at `:6952` about verbatim-char counts). Uniqueness verified above (54/55 both unused).

---

## 4. Measure-then-bound evidence (the 3 legs measured; set-equality holds)

All measured live at HEAD `4226dc8`, 2026-06-14, on the REAL tree (read-only):

**Leg 1 — PM-CHAT `## Permission profiles` table:**
```
$ grep -E '^\| `[a-z-]+` \| Read-only \|' project-template/docs/pack/PM-CHAT.md | wc -l
14
$ grep -E '^\| `[a-z-]+` \| Write-capable' project-template/docs/pack/PM-CHAT.md
| `coder` | Write-capable (scoped) |
| `repo-ops` | Write-capable (script) |
```
→ 14 RO + 2 RW. SUPPORTED.

**Leg 2 — agent-run.sh READONLY_AGENTS array:**
```
$ awk '/^READONLY_AGENTS=\(/{f=1;next}/^\)/{f=0}f{print}' project-template/agent-run.sh | grep -cE '^[[:space:]]*[a-z-]+'
14
```
→ exactly 14 RO entries; `coder`+`repo-ops` absent (= RW). SUPPORTED.

**Leg 3 — per-agent prose mandate headers (48 files = 16 × 3 CLIs):**
Measured across all 48 files: 14× `**Read-only.**` per CLI; `coder` = `**Write-capable (scoped).**`; `repo-ops` = `**Write-capable (script).**` per CLI (claude/codex/gemini all consistent — verified by per-file grep loop).
→ 14 RO + 2 RW per CLI. SUPPORTED.

**Set-equality holds (green on arrival):**
```
$ python3 scripts/validate-pack.py 2>&1 | grep 'Check 55'
── Check 55: BD-197 project RW/RO two-class consistency (Guard-B project) ──
  OK: Check 55 — project RW/RO two-class set-equality holds: 16 agents × 3 CLIs;
  PM-CHAT `## Permission profiles` Read-only rows (14) ↔ agent-run.sh READONLY_AGENTS (14)
  ↔ per-agent prose mandate headers; RW set = {`coder`, `repo-ops`} (bound to the prose
  header, never `tools:`).
$ echo $?   # full validate-pack
0
```
Conclusion: **SUPPORTED** — sized to exactly 14 RO + 2 RW; green on arrival per C6a.

---

## 5. Mismatch-catch proof (Check 55 FAILS on an injected mismatch; real tree untouched)

Per `ci-guard-design-measure-then-bound`, a guard that never catches a mismatch is worthless. Proven two ways:

**(a) /tmp mutation of the REAL tree (real tree NOT mutated).** Copied the real PM-CHAT + agent-run.sh + 48 agent files to a `/tmp` dir, then flipped `coder.md`'s prose header RW→RO and ran Check 55 against the `/tmp` copy:
```
mutated coder.md header RW->RO
── Check 55: BD-197 project RW/RO two-class consistency (Guard-B project) ──
FAIL: Check 55 — class MISMATCH for `coder`: expected `RW` (PM-CHAT table + READONLY_AGENTS)
≠ prose header `RO` (in project-template/.claude/agents/coder.md). ...
FAILURES: 1
=== confirm REAL tree untouched ===
1        # grep -c 'Write-capable (scoped)' project-template/.claude/agents/coder.md
```
→ FAILS (1 failure) on the injected mismatch; the real `coder.md` still carries `Write-capable (scoped)`. The `/tmp` dir was `rm -rf`'d after.

**(b) The per-check test's synthetic-tree cases (T2–T5, T8)** inject a mismatch in EACH leg and assert a failure (see §7). All pass (the guard catches each).

Conclusion: **SUPPORTED** — the guard catches per-leg mismatches; the real tree was never mutated.

---

## 6. Binds-to-PROSE-header-NOT-`tools:` proof

Design §13.2 mandates binding to the prose header because RO agents carry write tools and Gemini files carry no `tools:`. Proven on the REAL tree:

```
$ grep 'tools:' project-template/.claude/agents/reviewer.md
tools: Read, Grep, Glob, Bash, Write, Edit          # carries Write + Edit
$ grep -o '**Read-only.**' project-template/.claude/agents/reviewer.md | head -1
**Read-only.**                                       # yet prose header = RO

# _check_55_header_class on the REAL files:
reviewer:  tools-has-Write=True,  header_class=RO     # tools: IGNORED → RO
architect: tools-has-Write=True,  header_class=RO
auditor:   tools-has-Write=True,  header_class=RO
```
A `tools:`-keyed guard would misclassify `reviewer`/`architect`/`auditor` as RW (they carry `Write`/`Edit`). Check 55 binds to the prose header and correctly classifies them RO — mirroring the Check 52 `pack-reviewer` precedent.

**No-`tools:`-field case (Gemini):** `grep -lc 'tools:' project-template/.gemini/agents/*.md | wc -l` → `0` (no Gemini file has a `tools:` field). The test's **T7** builds a synthetic tree with NO `tools:` field at all and asserts the guard still classifies from the prose header (PASS). A `tools:`-keyed guard would be impossible on the Gemini surface; the prose-header binding works uniformly.

Conclusion: **SUPPORTED** — binds to the prose header; `tools:` ignored; works with or without a `tools:` field.

---

## 7. The new per-check test + run-before-wire evidence

**File:** `scripts/tests/test-validate-pack-check-55.sh` (new; 13.6 KB; `bash`, macOS bash 3.2 + BSD-utils compatible — `set -u`, no bash-4 features, no GNU-only flags).

**Coverage (mirrors the Check-52 test shape, extended for 3 legs):**
- **Group 0** — module import + `check_project_rw_ro_two_class` symbol registration.
- **Group 1** — synthetic-tree end-to-end (T1–T8):
  - **T1 PASS** — all three legs consistent (14 RO + 2 RW; 48 headers).
  - **T2 FAIL** — PM-CHAT leg: an RO row flipped to Write-capable → PM-CHAT RO set ≠ expected.
  - **T3 FAIL** — READONLY_AGENTS leg: an RO agent dropped from the array → array RO set ≠ expected.
  - **T4 FAIL** — header leg: `coder` (RW) header flipped to RO → header ≠ expected class.
  - **T5 FAIL** — an RO agent's prose header stripped → unclassified.
  - **T6 PASS** — binds to PROSE not `tools:`: an RO agent given write-capable `tools:` but RO header stays RO.
  - **T7 PASS** — the Gemini case: agent files with NO `tools:` field at all → RO header alone classifies RO.
  - **T8 FAIL** — READONLY_AGENTS lists a stray unknown agent token.
- **Group 2** — end-to-end `validate-pack.py` exit-status on HEAD (Check 55 clean).

**Run-before-wire sequence (decision 2):** author → run → wire → re-run battery, all in the SAME commit half.

1. **First local run (before wiring + before a test-bug fix):** Groups 0 PASS; Group 1 had a synthetic-tree backtick-escaping bug (`\\\`` in the heredoc produced a literal `\`` so the name cell did not strip to the agent name) AND Group 2 reported the BD-184 run-before-wire validator failure (`test file exists on disk but has NO corresponding invocation in validate-pack.yml`) — both EXPECTED at that point.
2. **Fix 1 (test bug, in the test only):** replaced the heredoc-escaped backtick with `BT = chr(96)` and string concatenation — no SyntaxWarning, real backticks emitted.
3. **Fix 2 (wire the test):** added the sister-step to `.github/workflows/validate-pack.yml` `tests:` job after the Check-56 step.
4. **Re-run the test (quoted):**
```
$ bash scripts/tests/test-validate-pack-check-55.sh; echo "EXIT: $?"
  PASS validate-pack.py imports + Check 55 symbol registered
  PASS End-to-end synthetic-tree tests T1-T8 (...binds-to-prose-header-not-tools + no-tools-field case)
  PASS validate-pack.py exits 0; Check 55 runs and reports set-equality clean at HEAD
  PASS: 3   FAIL: 0   All tests passed.
EXIT: 0
$ grep -c SyntaxWarning <test-output>   # 0
```
Conclusion: **EXIT 0** after wiring; no SyntaxWarning; all 3 groups (8 synthetic cases) pass.

---

## 8. FULL CI suite results (no sampling — every wired script)

Run on the REAL tree at HEAD `4226dc8`, 2026-06-14. Fixtures pre-built (`build.sh --all --clean` then **cp**-restore of the manifest, then `build.sh --verify`) to mirror the CI tests-job preconditions WITHOUT `git checkout` (denied verb).

**validate job (both invocations):**
| Step | EXIT |
|---|---|
| `python3 scripts/validate-pack.py` | **0** |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** |

**tests job (every wired script — all EXIT 0):**

Fixture/build steps: `test-fixtures/build.sh --all --clean` = 0; manifest restored via **cp** (not git checkout); `test-fixtures/build.sh --verify` = 0.

| Script | EXIT | | Script | EXIT |
|---|---|---|---|---|
| test-detect.sh | 0 | | test-validate-pack-check-46.sh | 0 |
| tracker-provider-test.sh | 0 | | test-validate-pack-check-removed-doc-advisory.sh | 0 |
| tracker-config-test.sh | 0 | | test-validate-pack-check-49-field-faithfulness.sh | 0 |
| tracker-init-test.sh | 0 | | test-validate-pack-check-50-codec-single-source.sh | 0 |
| tracker-agent-read-test.sh | 0 | | test-validate-pack-check-51-flip-block.sh | 0 |
| tracker-migrate-forward-test.sh | 0 | | test-validate-pack-check-52.sh | 0 |
| tracker-migrate-reverse-test.sh | 0 | | test-validate-pack-check-53.sh | 0 |
| tracker-migrate-roundtrip-test.sh | 0 | | test-validate-pack-check-56.sh | 0 |
| test-tracker-phase-task.sh | 0 | | **test-validate-pack-check-55.sh (NEW)** | **0** |
| test-tracker-links.sh | 0 | | tracker-deferral-gate-test.sh | 0 |
| test-tracker-cycle-check.sh | 0 | | tracker-bd129-gh-repo-test.sh | 0 |
| tracker-errors-test.sh | 0 | | tracker-bd130-doctor-wired-test.sh | 0 |
| tracker-config-schema-test.sh | 0 | | tracker-bd132-race-test.sh | 0 |
| recommendation-state-schema-test.sh | 0 | | tracker-bd133-header-preservation-test.sh | 0 |
| test-per-entry.sh | 0 | | tracker-bd134-close-retry-test.sh | 0 |
| test-validate-pack-checks-32-33-34.sh | 0 | | recommendation-test.sh | 0 |
| test-validate-pack-checks-36-37-38.sh | 0 | | pack-help-test.sh | 0 |
| test-validate-pack-check-39.sh | 0 | | test-customization-preserve.sh | 0 |
| test-validate-pack-check-40.sh | 0 | | test-init-project.sh | 0 |
| test-validate-pack-check-41.sh | 0 | | test-migrate-v10-to-v11.sh | 0 |
| test-validate-pack-check-18.sh | 0 | | test-migrate-v10-to-v11-dry-run.sh | 0 |
| test-validate-pack-check-16.sh | 0 | | test-migrate-v10-to-v11-gates.sh | 0 |
| test-validate-pack-check-19.sh | 0 | | test-migrate-v10-to-v11-decompose.sh | 0 |
| test-validate-pack-check-42.sh | 0 | | test-migrator-core.sh | 0 |
| test-validate-pack-check-43.sh | 0 | | test-migrator-manifest.sh | 0 |
| test-validate-pack-check-44.sh | 0 | | test-migrator-capability-translation.sh | 0 |
| test-validate-pack-check-45.sh | 0 | | test-v11-realistic-ot.sh | 0 |
| | | | test-migrator-skills.sh | 0 |
| | | | test-persona-contracts.sh | 0 |
| | | | template-translations-test.sh | 0 |
| | | | template-version-test.sh | 0 |
| | | | test-issue-forms.sh | 0 |

**Total: 2 validate-job invocations + 59 tests-job scripts (incl. fixture build/verify + the new test) = ALL EXIT 0. No sampling.**

---

## 9. Runtime (ci-check-runtime-compounding)

- **Check 55 wall-time:** `1.46 ms` (0.0015 s) measured isolated via `time.monotonic()` around `check_project_rw_ro_two_class()`.
- **Per-check WARN budget:** `RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0 s` → 1.46 ms is ~0.07% of budget. No `RUNTIME-BUDGET` warning emitted by `run_check()`. The total-run budget guard (general 10 s / deep 35 s) is unaffected (validate-pack still exits 0 with no runtime-budget FAIL).
- **Shape:** SINGLE bounded pass — 48 agent-file reads + 1 PM-CHAT read + 1 agent-run.sh read = 50 reads; **NO subprocess-per-entry, NO whole-tree scan, NO regex backtracking** (bounded string `.split('|')` + set ops). Negligible across the battery's ~200+ validate-pack invocations.

---

## 10. Manifest determination (cp-based, NOT git checkout)

C6b touches `scripts/` (v11-surface) → the `regenerate-manifest-v11-surface` RUN obligation fires. Result: **EMPTY diff → no stage needed** (matches plan §G / decision J-resolved-13: validate-pack.py + a test do NOT project into client fixtures, so no fixture SHA drifts).

Procedure (NO `git checkout` — denied verb):
```
$ cp test-fixtures/manifest.txt /tmp/manifest-backup-c6b.txt        # cp backup
$ bash test-fixtures/build.sh --all --clean    # build exit 0
$ git diff --stat test-fixtures/manifest.txt   # EMPTY (regenerated byte-identical)
MANIFEST DIFF: EMPTY (no stage needed)
$ cp /tmp/manifest-backup-c6b.txt test-fixtures/manifest.txt        # cp restore
$ git status --short test-fixtures/manifest.txt                     # clean (empty)
$ bash test-fixtures/build.sh --verify         # verify exit 0
```
Confirmed: **cp** backup/restore used, NOT `git checkout`. Manifest is clean (unstaged, unmodified) post-restore; `build.sh --verify` exit 0.

---

## 11. Files changed inventory

| Path | Change type | Detail |
|---|---|---|
| `scripts/validate-pack.py` | modified | +257 lines: `check_project_rw_ro_two_class()` + 3 helpers + `_CHECK_55_*` constants (after Check 56); `run_check(...)` registration in `main()`. Targeted additions (edit-in-place); no wholesale rewrite. |
| `.github/workflows/validate-pack.yml` | modified | +3 lines: a `tests:`-job sister-step running `test-validate-pack-check-55.sh`, after the Check-56 step. |
| `scripts/tests/test-validate-pack-check-55.sh` | new | The Check-55 per-check test (Groups 0/1/2; T1–T8). Full contents in §13. |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C6b.md` | new | This report. |

`git diff --stat` (tracked, in-scope only): `.github/workflows/validate-pack.yml 3 +`, `scripts/validate-pack.py 257 +`. The new test + report are untracked (new files). Patch emitted read-only to `/tmp/c6b-tracked.patch` (289 lines, tracked-file diff) for orchestrator auditability.

---

## 12. Plan deviations + out-of-scope items surfaced

**Plan deviations: ZERO.** C6b implemented exactly per plan §B C6b + design §13.2 (Check number 55 re-measured-and-confirmed; bind-to-prose; measure-then-bound to 16 agents; run-before-wire; single-surface `pack-only`; green on arrival).

**New POQs: none.**

**Out-of-scope items SURFACED (not silently fixed — `scope-deliverables-to-the-ask`):**

1. **Pre-existing un-related working-tree changes I did NOT make and did NOT touch:** `backlog/_toc.md` (modified) + `backlog/BD-219.md` (new, untracked). These are a **new BD entry opened by the orchestrator (Pack Chat) during this session** — `BD-219 — CI runtime optimization: tests-job matrix-sharding + validate-pack --only-check`, scheduled to run directly after BD-197 is Resolved. They are user-governance authoring, completely unrelated to C6b, and OUTSIDE my scope. I left them untouched. **My `git diff` patch is scoped to ONLY my 3 in-scope files** (`scripts/validate-pack.py`, `.github/workflows/validate-pack.yml`, and the new test) — the orchestrator must NOT bundle `backlog/_toc.md` / `backlog/BD-219.md` into the C6b commit (they belong to the separate BD-219 open).
2. **Pre-existing untracked C6a reports:** `IMPL-REPORT-BD-197-C6a.md` + `PACK-REVIEW-BD-197-C6a.md` were already present at session start (the orchestrator bundles them; per the prompt I did NOT edit them).

**Boundary discipline check:** C6b is `pack-only` — every edit is on pack-side surfaces (`scripts/validate-pack.py`, `.github/workflows/validate-pack.yml`, `scripts/tests/`). No project-side (`project-template/`, `supporting-docs/`) file was edited; the project legs were READ-only to size the guard. No pack-only reference was added to a client surface. No project-side SSOT investigation was required (no project-side edit). **No boundary-discipline stop.**

---

## 13. New file — full contents: `scripts/tests/test-validate-pack-check-55.sh`

```bash
#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-55.sh — dedicated test for
# BD-197 Check 55 (project RW/RO two-class consistency, Guard-B project).
#
# Check 55 asserts SET-EQUALITY across the THREE project legs:
#   {PM-CHAT `## Permission profiles` Read-only rows}
#     ↔ {project-template/agent-run.sh READONLY_AGENTS array}
#     ↔ {per-agent-file PROSE mandate headers}
# and that the RW set = exactly {`coder`, `repo-ops`}, for the 16 project
# agents × 3 CLIs. It BINDS TO THE PROSE HEADER, NEVER `tools:` (project RO
# agents like `reviewer`/`architect`/`auditor` carry `Write, Edit` yet are
# RO; the Gemini files carry NO `tools:` field at all). This test proves the
# guard PASSes on the well-formed tree and FAILs on injected mismatches in
# each of the three legs, in a synthetic tree (the real tree is never
# mutated).
#
# Coverage:
#   Group 0: module import + Check 55 symbol registration
#   Group 1: synthetic-tree end-to-end:
#            T1 PASS — PM-CHAT (14 RO + 2 RW) + READONLY_AGENTS (14) +
#                      48 headers all consistent
#            T2 FAIL — PM-CHAT leg: an RO row flipped to Write-capable
#                      (PM-CHAT RO set ≠ expected)
#            T3 FAIL — READONLY_AGENTS leg: an RO agent dropped from the
#                      array (array RO set ≠ expected)
#            T4 FAIL — header leg: a `coder` (RW) header flipped to RO
#                      (header ≠ expected class)
#            T5 FAIL — an RO agent's prose header stripped (unclassified)
#            T6 PASS — proves the guard binds to the PROSE header, NOT
#                      `tools:`: an RO agent given a write-capable
#                      `tools:` line but keeping its RO header stays RO
#            T7 PASS — proves the guard works when the agent file has NO
#                      `tools:` field at all (the Gemini case): RO header
#                      alone classifies it RO
#            T8 FAIL — READONLY_AGENTS lists a stray unknown agent token
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 55 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-55.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

PASS=0
FAIL=0
t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: module import + symbol registration
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: Module import + Check 55 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_project_rw_ro_two_class']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check55-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check55-import.out; then
    t_pass "validate-pack.py imports + Check 55 symbol registered"
else
    t_fail "validate-pack.py import or Check 55 symbol registration failed" \
        "$(cat /tmp/vp-check55-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (PASS + injected-FAIL cases)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

BT = chr(96)  # literal backtick (avoids heredoc escaping pitfalls)
RO_HDR = mod._CHECK_55_RO_HEADER             # **Read-only.**
RW_SCOPED = mod._CHECK_55_RW_HEADERS[0]      # **Write-capable (scoped).**
RW_SCRIPT = mod._CHECK_55_RW_HEADERS[1]      # **Write-capable (script).**
AGENTS = list(mod._CHECK_55_PROJECT_AGENTS)
RW = set(mod._CHECK_55_RW_AGENTS)            # {coder, repo-ops}
RO_AGENTS = [a for a in AGENTS if a not in RW]

# Default header class per agent (the well-formed tree).
def default_headers():
    d = {a: RO_HDR for a in RO_AGENTS}
    d["coder"] = RW_SCOPED
    d["repo-ops"] = RW_SCRIPT
    return d

# A well-formed PM-CHAT profile table: 14 RO + coder (scoped) + repo-ops (script).
def pm_chat_text(ro_override=None):
    ro_set = set(RO_AGENTS)
    if ro_override is not None:
        ro_set = ro_override
    rows = ["# PM-CHAT.md\n", "## Permission profiles\n",
            "### Profile assignment\n",
            "| Agent | Profile |", "|---|---|"]
    for a in AGENTS:
        if a == "coder":
            prof = "Write-capable (scoped)"
        elif a == "repo-ops":
            prof = "Write-capable (script)"
        elif a in ro_set:
            prof = "Read-only"
        else:
            prof = "Write-capable (scoped)"
        rows.append("| " + BT + a + BT + " | " + prof + " |")
    return "\n".join(rows) + "\n"

# A well-formed agent-run.sh READONLY_AGENTS array (the 14 RO agents).
def agent_run_text(ro_list=None, extra_token=None):
    items = ro_list if ro_list is not None else list(RO_AGENTS)
    body = "READONLY_AGENTS=(\n"
    for a in items:
        body += f"    {a}\n"
    if extra_token:
        body += f"    {extra_token}\n"
    body += ")\n"
    return "#!/usr/bin/env bash\n" + body

# Per-agent body. tools_line optional (the Gemini files have none).
def agent_body(header, tools_line=None):
    out = ""
    if tools_line is not None:
        out += "tools: " + tools_line + "\n"
    out += "You are a project agent.\n\n" + header + " mandate prose.\n"
    return out

def build_tree(root, *, pm_text=None, run_text=None, headers=None,
               drop_header_for=None, extra_tools_for=None, no_tools=False):
    root = pathlib.Path(root)
    (root / "project-template" / "docs" / "pack").mkdir(parents=True, exist_ok=True)
    (root / "project-template" / "docs" / "pack" / "PM-CHAT.md").write_text(
        pm_text if pm_text is not None else pm_chat_text())
    (root / "project-template").mkdir(parents=True, exist_ok=True)
    (root / "project-template" / "agent-run.sh").write_text(
        run_text if run_text is not None else agent_run_text())
    hdrs = default_headers()
    if headers:
        hdrs.update(headers)
    for d, ext in mod._CHECK_55_AGENT_DIRS:
        (root / d).mkdir(parents=True, exist_ok=True)
        for a in AGENTS:
            hdr = hdrs[a]
            # Default: a benign read-only tools line (mirrors real claude/codex).
            tools = None if no_tools else "Read, Grep, Glob, Bash"
            if extra_tools_for and a == extra_tools_for:
                tools = "Read, Grep, Glob, Bash, Write, Edit, MultiEdit"
            if drop_header_for and a == drop_header_for:
                # Strip the recognized header -> unclassified.
                body = agent_body("(no recognized header)", tools)
                body = body.replace("(no recognized header) mandate prose.",
                                    "no recognized mandate header here")
            else:
                body = agent_body(hdr, tools)
            (root / d / f"{a}.{ext}").write_text(body)

def run(build_kwargs):
    tmpdir = tempfile.mkdtemp(prefix="vp-check55-")
    root = pathlib.Path(tmpdir)
    build_tree(root, **build_kwargs)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_project_rw_ro_two_class()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return len(new_failures), captured

# T1: PASS — all three legs consistent (14 RO + 2 RW; 48 headers).
fc, cap = run(dict())
if fc != 0:
    failures.append(f"T1 (all consistent PASS) expected 0 failures, got {fc}: {cap}")

# T2: FAIL — PM-CHAT leg: drop an RO agent from the RO set (its row becomes
# Write-capable) -> PM-CHAT RO set != expected.
bad_ro = set(RO_AGENTS) - {"reviewer"}
fc, cap = run(dict(pm_text=pm_chat_text(ro_override=bad_ro)))
if fc < 1 or "PM-CHAT" not in cap or "Read-only rows" not in cap:
    failures.append(f"T2 (PM-CHAT RO row flipped) expected PM-CHAT-leg failure, got {fc}: {cap}")

# T3: FAIL — READONLY_AGENTS leg: drop an RO agent from the array.
short_run = [a for a in RO_AGENTS if a != "planner"]
fc, cap = run(dict(run_text=agent_run_text(ro_list=short_run)))
if fc < 1 or "READONLY_AGENTS" not in cap:
    failures.append(f"T3 (READONLY_AGENTS dropped) expected array-leg failure, got {fc}: {cap}")

# T4: FAIL — header leg: flip coder (RW) header to RO.
fc, cap = run(dict(headers={"coder": RO_HDR}))
if fc < 1 or "MISMATCH" not in cap or "coder" not in cap:
    failures.append(f"T4 (coder header RW->RO mismatch) expected mismatch, got {fc}: {cap}")

# T5: FAIL — strip an RO agent's prose header (unclassified).
fc, cap = run(dict(drop_header_for="auditor"))
if fc < 1 or "no single recognized prose mandate header" not in cap:
    failures.append(f"T5 (stripped header) expected unclassified failure, got {fc}: {cap}")

# T6: PASS — binds to PROSE header NOT tools:. Give the RO reviewer a
# write-capable tools line; with its RO header intact it stays RO -> 0 fails.
fc, cap = run(dict(extra_tools_for="reviewer"))
if fc != 0:
    failures.append(f"T6 (RO-despite-write-tools binds to prose header) expected 0 failures, got {fc}: {cap}")

# T7: PASS — the Gemini case: agent files with NO tools: field at all. The RO
# header alone classifies them RO; the guard never needs tools:.
fc, cap = run(dict(no_tools=True))
if fc != 0:
    failures.append(f"T7 (no tools: field at all, Gemini case) expected 0 failures, got {fc}: {cap}")

# T8: FAIL — READONLY_AGENTS lists a stray unknown agent token.
fc, cap = run(dict(run_text=agent_run_text(extra_token="x-bogus")))
if fc < 1 or "unknown agent" not in cap:
    failures.append(f"T8 (stray array token) expected stray-token failure, got {fc}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T8 (three-leg consistency PASS + injected per-leg mismatches + binds-to-prose-header-not-tools + no-tools-field case)" ;;
    *) t_fail "End-to-end check_project_rw_ro_two_class tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check55-e2e.out 2>&1; then
    if grep -q "Check 55: BD-197 project RW/RO two-class consistency" /tmp/vp-check55-e2e.out \
       && grep -q "Check 55 — project RW/RO two-class set-equality holds" /tmp/vp-check55-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 55 runs and reports set-equality clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 55 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check55-e2e.out)"
    fi
else
    if grep -q "Check 55: BD-197 project RW/RO two-class consistency" /tmp/vp-check55-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 55 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check55-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 55 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check55-e2e.out)"
    fi
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"
    exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"
    exit 1
fi
```

---

## 14. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| Guard-B-project (a NEW check) added to `validate-pack.py` | PASS | `check_project_rw_ro_two_class()` + helpers + `_CHECK_55_*`; registered in `main()` |
| Asserts set-equality across the 3 legs | PASS | §4 — PM-CHAT RO ↔ READONLY_AGENTS ↔ prose headers; §2 |
| RW set = `{coder, repo-ops}` | PASS | `_CHECK_55_RW_AGENTS = ("coder","repo-ops")`; §4 |
| Binds to PROSE header, NEVER `tools:` | PASS | §6 — reviewer/architect/auditor carry Write but classify RO; T7 no-tools case |
| Measure-then-bound (14 RO + 2 RW; sized exactly) | PASS | §4 measurements; constants sized to 16 agents × 3 CLIs |
| Catches a mismatch (proven; real tree untouched) | PASS | §5 — /tmp mutation FAILS; T2–T5/T8 |
| Check number re-measured (NOT assumed); unique; gap tolerated | PASS | §3 — highest=56; chose 55; 54 reserved for C8b; no contiguity requirement |
| Per-check runtime guard; single-pass; no subprocess-per-entry | PASS | §9 — 1.46 ms; `run_check()` WARN budget; 50 reads, no subprocess |
| New per-check test authored + RUN locally (exit 0) | PASS | §7 — `EXIT: 0`; 3 groups / 8 cases |
| Test wired into `validate-pack.yml` `tests` job (run-before-wire) | PASS | §7 — sister-step added after Check-56 step |
| FULL CI battery re-run (no sampling); every script exit quoted | PASS | §8 — 2 validate-job + 59 tests-job scripts ALL EXIT 0 |
| Manifest: regen RUN; stage only if non-empty (cp, not git checkout) | PASS | §10 — EMPTY diff; cp backup/restore; verify exit 0 |
| enumerate-encoding-surfaces (check + test + yml in lockstep) | PASS | §11 — all three in this one commit half |
| edit-in-place (no wholesale rewrite) | PASS | targeted additions to validate-pack.py + yml |
| Scope: only the 3 files + report; project surfaces untouched | PASS | §11/§12 — `git diff --name-only` = the 2 tracked + new test; backlog changes surfaced as NOT mine |
| No state-changing git verb run | PASS | §15 — read-only git only; cp not git checkout |

---

## 15. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | ci-guard-design-measure-then-bound [coder] | Measured 3 legs (§4): PM-CHAT 14 RO + 2 RW, READONLY_AGENTS 14, prose headers 14 RO + 2 RW. Sized `_CHECK_55_PROJECT_AGENTS` (16), `_CHECK_55_RW_AGENTS` (coder,repo-ops), `_CHECK_55_AGENT_DIRS` (3) to exactly that. Binds to prose header (§6: reviewer/architect/auditor carry Write yet RO; T7 no-tools). Mismatch caught (§5: /tmp mutation → `FAILURES: 1`, real tree untouched). | COMPLIANT |
| 2 | ci-check-runtime-compounding [universal] | Wall-time `1.46 ms` (§9) via `time.monotonic()`; under `RUN_CHECK_PER_CHECK_WARN_BUDGET_S=2.0s`; no RUNTIME-BUDGET warning. Single pass = 50 file reads; NO subprocess-per-entry, NO whole-tree scan. Battery ~200+ validate-pack invocations → negligible. | COMPLIANT |
| 3 | enumerate-encoding-surfaces [coder] | Check source (`scripts/validate-pack.py`) + new test (`scripts/tests/test-validate-pack-check-55.sh`) + yml wiring (`.github/workflows/validate-pack.yml`) all changed in lockstep, this one commit half (§11 inventory). | COMPLIANT |
| 4 | verify-full-ci-suite [universal] | Ran EVERY wired script (§8): 2 validate-job invocations (general + `PACK_VALIDATE_DEEP=1`, both EXIT 0) + 59 tests-job scripts (incl. fixture build/verify + the NEW test), ALL EXIT 0, each quoted. Test wired BEFORE the battery re-run (run-before-wire, §7). No sampling. | COMPLIANT |
| 5 | edit-in-place-not-full-rewrite [universal] | `scripts/validate-pack.py` +257 lines as a targeted block after Check 56 + a registration line in `main()` (Edit calls on unique anchors); `.github/workflows/validate-pack.yml` +3-line sister-step. No wholesale rewrite. | COMPLIANT |
| 6 | regenerate-manifest-v11-surface [coder] | scripts/ is v11-surface → regen RUN (§10): `build.sh --all --clean` exit 0; `git diff` manifest = EMPTY → no stage. cp backup/restore (NOT git checkout); `build.sh --verify` exit 0. | COMPLIANT |
| 7 | empirical-evidence-blocks [coder] | Every state-claim backed by command + verbatim output + HEAD `4226dc8` + date 2026-06-14: §3 (check number), §4 (3 legs), §5 (mismatch), §6 (binds-to-prose), §7 (test run), §8 (battery), §9 (wall-time), §10 (manifest). | COMPLIANT |
| 8 | preflight-stop-means-stop [universal] | PREFLIGHT line emitted in chat immediately before this Write (`PREFLIGHT: Guard-B-project (Check 55) ... FULL CI battery PASS; manifest empty; HEAD 4226dc8...`), only after ALL edits + the FULL battery + the new test PASSed. No parent stop/halt received during the edit pass. | COMPLIANT |
| 9 | agents-never-commit [universal] | Read-only git only: `git rev-parse HEAD` → `4226dc8...`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`, `git status`, `git diff`, `git diff > /tmp/c6b-tracked.patch` (read-only patch-emit), `git log`. NO `git checkout` (used `cp` for manifest backup/restore). NO add/commit/push/stage/apply/reset/restore/etc. The orchestrator commits. | COMPLIANT |
| 10 | scope-deliverables-to-the-ask [universal] | Touched ONLY `scripts/validate-pack.py` + the new test + `.github/workflows/validate-pack.yml` + this report (`git diff --name-only` = 2 tracked + new test). Did NOT touch project surfaces, did NOT do C7/C8, did NOT edit C6a audit docs. Surfaced the unrelated orchestrator-authored `backlog/_toc.md`/`backlog/BD-219.md` as NOT mine (§12) — patch scoped to exclude them. | COMPLIANT |
| 11 | rules-applied-verification-block [universal] | This block. Every row carries quoted/measured evidence; no empty cell. | COMPLIANT |

---

**End of IMPL-REPORT-BD-197-C6b.**
