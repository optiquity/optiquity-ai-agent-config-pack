# PLAN-BD-119 — Implementation plan for the General N→N+1 Migrator Framework

**Author:** pack-planner
**Date:** 2026-05-08
**Status:** Proposed (read-only planning pass)
**Architecture input:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`
**Architecture commit SHA:** `4a6aa6b` (head at planning time; doc landed in
`docs: v11 — BD-114..BD-120 pre-Phase-A persona-coverage batch (Open)`)
**Scope:** BD-119 only. Cross-references BD-114, BD-115, BD-116, BD-117,
BD-118, BD-120 strictly as integration cues.

---

## Table of contents

1. [Goal and BD items addressed](#1-goal-and-bd-items-addressed)
2. [Affected files (complete list)](#2-affected-files-complete-list)
3. [Public surface lock-down (function + env-var contracts)](#3-public-surface-lock-down-function--env-var-contracts)
4. [Task breakdown (T-1..T-15)](#4-task-breakdown-t-1t-15)
5. [File-level dependency graph](#5-file-level-dependency-graph)
6. [Commit sequence (C-1..C-7)](#6-commit-sequence-c-1c-7)
7. [Replacement strategy: gradual vs atomic — and why](#7-replacement-strategy-gradual-vs-atomic--and-why)
8. [Behavior-preservation verification recipe](#8-behavior-preservation-verification-recipe)
9. [Trinity + cross-doc updates](#9-trinity--cross-doc-updates)
10. [Open-question disposition](#10-open-question-disposition)
11. [Risk register + verification mapping](#11-risk-register--verification-mapping)
12. [Downstream integration cues (BD-114, BD-115, BD-120)](#12-downstream-integration-cues-bd-114-bd-115-bd-120)
13. [Failure-mode triage (when behavior-preservation diff fails)](#13-failure-mode-triage-when-behavior-preservation-diff-fails)
14. [Definition of Done for BD-119](#14-definition-of-done-for-bd-119)
15. [Newly identified open questions (planner-side)](#15-newly-identified-open-questions-planner-side)

---

## 1. Goal and BD items addressed

**Goal.** Land the migrator framework described in
ARCHITECTURE-BD-119.md without behavior change to v10→v11, such that:

- Three new shared libraries exist under `scripts/lib/` (`migrator-core.sh`,
  `migrator-stages.sh`, `migrator-manifest.sh`).
- `scripts/lib/detect.sh` gains `detect_target_pack_version` per §5.1.
- `scripts/migrate-v10-to-v11.sh` is refactored into a thin adapter
  (~120 lines) that sources `migrator-core.sh` and supplies hooks.
- A behavior-preservation harness proves the refactored adapter
  produces output equivalent to the pre-refactor monolith on every
  fixture in `test-fixtures/`.
- CI (`.github/workflows/validate-pack.yml`) is green at every commit
  on the branch.
- Trinity rule honored on pack-repo `CLAUDE.md / AGENTS.md / GEMINI.md`.
- Public surface (function names, env-var names, exit-code symbols)
  is locked so BD-114 / BD-115 / BD-120 can build against it without
  amending BD-119 retroactively.

**BD addressed:** BD-119.
**BD enabled (not landed here):** BD-114, BD-120.
**BD touched as integration cues only (no implementation):** BD-115,
BD-116, BD-117, BD-118.

---

## 2. Affected files (complete list)

### 2.1 New files

| Path | Why |
|---|---|
| `scripts/lib/migrator-core.sh` | Public API + arg parsing + stage sequencer + exit-code constants. Adapters source this. (Architecture §3.1, §3.2.) |
| `scripts/lib/migrator-stages.sh` | Per-stage implementations (`_stage_preflight`, `_stage_backup`, `_stage_libs`, `_stage_dispatch`, `_stage_relocations`, `_stage_artifact_installs`, `_stage_report`). Sourced only by core. (Architecture §3.1.) |
| `scripts/lib/migrator-manifest.sh` | TSV manifest parser + `customization_preserve` dispatch engine + trinity-parity validator. Sourced only by core. (Architecture §3.1, §4.2, §6 I3 / I5.) |
| `scripts/lib/migrator-skills.sh` (added in BD-147) | Reusable skill-rename helper extracted from inline S5b. Sibling library to `migrator-core.sh`. Exposes `migrator_skill_rename` and forward-declared `migrator_skill_split`. (See `ARCHITECTURE-BD-119.md` §3.1 sibling-lib paragraph and `ARCHITECTURE-SKILL-DIMENSIONS.md` §6.5.) |
| `scripts/tests/test-migrator-core.sh` | Unit tests for the core's public API (`migrator_select_adapter`, `migrator_detect_target_version`, manifest parser, trinity-parity validator). Wired into `validate-pack.yml`. |
| `scripts/tests/test-migrator-behavior-preservation.sh` | The §8 recipe driver: builds fixtures, runs both pre-refactor and post-refactor migrators, diffs outputs, fails CI on unexpected diff. (Hooked into `validate-pack.yml` only after C-6.) |
| `maintenance-docs/v11-implementation/PLAN-BD-119.md` | This file. |

### 2.2 Files modified

| Path | Change | Trinity impact |
|---|---|---|
| `scripts/migrate-v10-to-v11.sh` | Refactor: 437 → ~120 lines. Becomes adapter against the framework. | None (single file). |
| `scripts/lib/detect.sh` | Add `detect_target_pack_version <target-dir>` per architecture §5.1. Read-only function; no signature changes to existing functions. | None. |
| `.github/workflows/validate-pack.yml` | Add two test steps: `test-migrator-core` and `test-migrator-behavior-preservation`. Both `if: always()`. | None. |
| `scripts/validate-pack.py` | Add a structural check (Check 26) that asserts `scripts/lib/migrator-core.sh` exists, is shell-syntax-valid, and exposes the documented public API names. Inventory check only — no behavior assertion. | None. |
| `README.md` | Repository Layout: add three new lib files under `scripts/lib/` block (lines ~188–198). No version-table edit (BD-119 is not a version cut). | None. |
| `CLAUDE.md` (pack repo root) | Add a one-line entry under "Repo structure" pointing maintainers at the migrator framework when authoring a new `migrate-vN-to-vM.sh`. | **TRINITY** — see §9. |
| `AGENTS.md` (pack repo root) | Same as CLAUDE.md (parity). | **TRINITY** — see §9. |
| `GEMINI.md` (pack repo root) | Same as CLAUDE.md (parity). | **TRINITY** — see §9. |
| `PACK-AGENTS.md` | Update only if the framework introduces a routing change; per §9, default is **N/A** because no new pack-agent verb is introduced. Documented as N/A here so the implementer does not invent a touch. | None. |

### 2.3 Files explicitly NOT modified

| Path | Why |
|---|---|
| `BACKLOG.md` | PM-chat-only per CLAUDE.md. Status flip happens at end of batch via implicit-flip rule. Implementer must NOT edit BACKLOG.md. |
| `CHANGELOG.md` | Changes only at version boundaries with explicit instruction. BD-119 is mid-version refactor; no changelog entry. |
| `scripts/init-project.sh` | OQ4 in architecture §11.2 explicitly defers `--update` framework integration to a follow-up BD. Untouched. |
| `scripts/lib/customization-preserve.sh` | Architecture §3.1 marks unchanged. R5 (§11.1) says signature freeze is the structural payoff. |
| `scripts/lib/customization-report.sh` | Same — unchanged. |
| `scripts/lib/three-way.sh` | Same — unchanged. |
| `scripts/migrate-v9-to-v10.sh` | Frozen per README.md line 180. The framework is forward-only. |
| `test-fixtures/build.sh` | BD-120's surface, not BD-119's. See §12. |
| `test-fixtures/manifest.txt` | Fixture manifest is verified, not edited, by BD-119. |
| `supporting-docs/MIGRATION-v10-to-v11.md` | User-facing migration guide — behavior is preserved, so doc is unchanged. |
| `supporting-docs/MERGE-STRATEGY.md` | Per-file customization rules; BD-119 does not change them. |

---

## 3. Public surface lock-down (function + env-var contracts)

This is the contract BD-114 / BD-120 / future v11→v12 adapter consume.
Once C-3 (see §6) lands, these names are frozen for the duration of
v11.x. Renames require a new BD that explicitly amends BD-119.

### 3.1 Functions exported by `migrator-core.sh`

| Name | Arity | Returns | Frozen? |
|---|---|---|---|
| `migrator_run` | `"$@"` (positional target dir + flags) | exit code 0 / 10..30 / 99 | yes |
| `migrator_dispatch <target-dir>` | 1 | exit code | yes |
| `migrator_detect_target_version <target-dir>` | 1 | echoes `vN` or `unknown` | yes |
| `migrator_select_adapter <from-version>` | 1 | echoes adapter path or errors | yes |
| `migrator_baseline_to_tmp <pack-relpath> <tmpfile>` | 2 | side effect: writes BASE | yes |
| `migrator_target_surface_for_version <vN>` | 1 | echoes newline-list of relpaths | yes (BD-120 consumer) |

### 3.2 Functions exported by `detect.sh` (additive)

| Name | Arity | Returns | Frozen? |
|---|---|---|---|
| `detect_target_pack_version <target-dir>` | 1 | echoes `vN` or `unknown` | yes |

### 3.3 Adapter-declared variables (`MIGRATOR_*`)

Per architecture §3.2 — frozen verbatim:

- `MIGRATOR_FROM_VERSION` — string, e.g. `"v10"`.
- `MIGRATOR_TO_VERSION` — string, e.g. `"v11"`.
- `MIGRATOR_BASELINE_TAG` — string, e.g. `"v10"`.
- `MIGRATOR_OWN_SIDECAR_SUFFIX` — string, e.g. `"v10-customized"`.
- `MIGRATOR_PRIOR_SIDECAR_SUFFIXES` — bash array.

### 3.4 Adapter-declared hooks

Required: `migrator_manifest`, `migrator_directory_sweeps`,
`migrator_relocations`, `migrator_artifact_installs`,
`migrator_post_report_hook`.

Optional: `migrator_pre_dispatch_hook`, `migrator_post_dispatch_hook`,
`migrator_target_version_marker` (see §5.1 of architecture).

### 3.5 Exit-code constants

Frozen. Adapters reference by name, never by literal:

```
EXIT_PACK_INVALID=10
EXIT_NOT_GIT=11
EXIT_DIRTY=12
EXIT_NOT_BASELINE=13   # was EXIT_NOT_V10 in monolith; renamed (architecture §C1)
EXIT_BASELINE_MISSING=14
EXIT_LIB_MISSING=15
EXIT_ALREADY_MIGRATED=16   # NEW per architecture I8
EXIT_INTERNAL=99
```

Stage failures use the existing `20+N` formula; that formula is also
frozen. **Renaming `EXIT_NOT_V10` to `EXIT_NOT_BASELINE` is the only
behavior-visible exit-code change.** Old name retained as a synonym
constant (`readonly EXIT_NOT_V10="$EXIT_NOT_BASELINE"`) so any external
caller that grepped the constant name does not break. Documented in
the adapter header comment.

### 3.6 Internal env vars (`_MIGRATOR_*`)

Reserved for the core; not part of the public surface. Implementer may
add/rename freely. Examples: `_MIGRATOR_DRY_RUN`, `_MIGRATOR_STATE_DIR`,
`_MIGRATOR_BACKUP_DIR`. Adapters MUST NOT read or write these.

---

## 4. Task breakdown (T-1..T-15)

Each task has scope, files, expected size, dependencies, parallel-eligible flag.

| ID | Scope | Files | Size (LOC ±) | Depends on | Parallel? |
|---|---|---|---|---|---|
| **T-1** | Snapshot pre-refactor monolith for behavior-preservation diffs. Tag the current `migrate-v10-to-v11.sh` as branch-local reference (`git stash` of a copy to `scripts/migrate-v10-to-v11.sh.preBD119` ignored by git, plus a worktree-snapshot). Used by §8 recipe. | working-tree only (no commit) | 0 | — | no (must precede everything) |
| **T-2** | Add `detect_target_pack_version` to `scripts/lib/detect.sh` per architecture §5.1. Implement signal cascade (tracker.toml `[pack].version` → trinity addenda fingerprint → surface markers → negative markers → `unknown`). Pure additive. | `scripts/lib/detect.sh` | +60 | — | yes (independent of core lib) |
| **T-3** | Add Check 26 to `validate-pack.py` asserting `migrator-core.sh` presence + shell-syntax-valid + exposes documented public-API names. Skipped (returns OK) if file does not yet exist on the working tree to keep early commits green. | `scripts/validate-pack.py` | +50 | — | yes |
| **T-4** | Land `scripts/lib/migrator-core.sh` skeleton: header comment, exit-code constants (per §3.5), `say/info/warn/die/fail_stage` helpers, public-API stubs that error `not yet implemented` (so the file is sourceable + `bash -n` clean before T-7 fills bodies). | `scripts/lib/migrator-core.sh` | +120 | T-3 (Check 26 must be lenient) | no |
| **T-5** | Land `scripts/lib/migrator-stages.sh` skeleton: empty `_stage_*` functions that return non-zero with `not implemented`. File is sourceable, syntax-valid. | `scripts/lib/migrator-stages.sh` | +80 | T-4 (sourced by core) | yes (alongside T-6) |
| **T-6** | Land `scripts/lib/migrator-manifest.sh` skeleton: empty TSV parser + dispatch engine. Sourceable, syntax-valid. | `scripts/lib/migrator-manifest.sh` | +80 | T-4 | yes (alongside T-5) |
| **T-7** | Implement core's stage sequencer + arg parsing + trap/EXIT report-render guarantee. Adapter contract reading (`MIGRATOR_*` env vars + hook detection via `declare -F`). All exit codes wired. | `scripts/lib/migrator-core.sh` | +180 | T-4, T-5, T-6 | no |
| **T-8** | Implement `_stage_preflight`, `_stage_backup`, `_stage_libs` per architecture §6 I1, I2, I4, I8. Idempotency check (I8) issues `EXIT_ALREADY_MIGRATED` when prior `<state-dir>/dispositions.tsv` is present without `--resume`. | `scripts/lib/migrator-stages.sh` | +180 | T-7 | no |
| **T-9** | Implement `_stage_dispatch` engine: parses `migrator_manifest` TSV, validates trinity-parity (I5), iterates entries, calls `customization_preserve` per `transform`, additive-write per `add`, no-op-with-report per `remove`, git-mv-with-fallback per `relocate-from`. Plus `migrator_directory_sweeps` iteration. | `scripts/lib/migrator-manifest.sh` | +220 | T-7 | yes (alongside T-10) |
| **T-10** | Implement `_stage_relocations`, `_stage_artifact_installs`, `_stage_report` (renders via `customization_report`, then calls `migrator_post_report_hook`). Templated revert-instructions string against `MIGRATOR_FROM_VERSION` / `MIGRATOR_TO_VERSION` (architecture M5). | `scripts/lib/migrator-stages.sh` | +120 | T-7 | yes (alongside T-9) |
| **T-11** | Implement `migrator_detect_target_version` (delegates to `detect_target_pack_version`), `migrator_select_adapter` (glob `scripts/migrate-v*-to-v*.sh`, OQ3 resolved → glob), `migrator_baseline_to_tmp`, `migrator_target_surface_for_version`. | `scripts/lib/migrator-core.sh` | +90 | T-2, T-7 | no |
| **T-12** | Author `scripts/tests/test-migrator-core.sh`: unit tests for the core's pure functions — manifest TSV parse, trinity-parity validator (positive + negative), `migrator_select_adapter` glob (positive: v10→v11 found; negative: v99 missing), exit-code constants present, `migrator_target_surface_for_version v10` returns expected list. Hooked into `validate-pack.yml` as a new step. | `scripts/tests/test-migrator-core.sh`, `.github/workflows/validate-pack.yml` | +200 (test) +6 (yml) | T-11 | yes (alongside T-13) |
| **T-13** | Refactor `scripts/migrate-v10-to-v11.sh` from 437-line monolith to ~120-line adapter per architecture §10 mapping table. Sets all `MIGRATOR_*` vars, defines five required hooks (`migrator_manifest`, `migrator_directory_sweeps`, `migrator_relocations`, `migrator_artifact_installs`, `migrator_post_report_hook`), sources `migrator-core.sh`, calls `migrator_run "$@"`. | `scripts/migrate-v10-to-v11.sh` | -317 | T-7..T-11 | no |
| **T-14** | Author `scripts/tests/test-migrator-behavior-preservation.sh`: implements §8 recipe driver. Reads `scripts/migrate-v10-to-v11.sh.preBD119` snapshot (kept on filesystem during the branch lifetime, gitignored — see T-1) and runs both old + new against four fixtures, diffs, exits non-zero on unexpected diff. **Initially `if: always()` in CI but tolerated to fail until C-6 (gate flip).** | `scripts/tests/test-migrator-behavior-preservation.sh`, `.github/workflows/validate-pack.yml`, `.gitignore` | +250 (test) +4 (yml) +1 (gitignore) | T-13 | no |
| **T-15** | Update README.md Repository Layout (three new lib lines), pack-repo trinity (CLAUDE/AGENTS/GEMINI — one-line entry under "Repo structure" pointing at the framework). Verify by grep that no other doc names the monolith filename in a way that became stale (existing migration-guide language is user-facing and behavior-preserved, so untouched — see §9 audit). | `README.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | +6 (README) +3×2 (trinity) | T-13 (so the doc reflects landed structure) | yes |

**Total task count: 15.**

**Estimated net LOC delta:**
- New lib code: ~770 (core + stages + manifest)
- Detect addition: +60
- Tests: ~450
- Validate-pack: +50
- CI yml: +10
- Adapter refactor: -317 (delete) +120 (new) = -197
- Docs: +12

Net: roughly +1130 lines added, ~317 deleted. Architecture §10 expects
the 317 deleted lines to live somewhere; they live in the new libs
(~770), so the delta is consistent with the "amortize across future
versions" thesis.

---

## 5. File-level dependency graph

Edges read "must exist on the working tree before."

```
T-1 (snapshot)
  └─► T-13 (refactor adapter — needs snapshot for diff)
  └─► T-14 (behavior-preservation — diffs against snapshot)

T-2 (detect_target_pack_version) ─► T-11 (core delegates to it)
T-3 (validate-pack Check 26)     ─► T-4 (core file lands; check now meaningful)
T-4 (core skeleton)              ─► T-5, T-6, T-7
T-5 (stages skeleton)            ─► T-7 (core sources it), T-8, T-10
T-6 (manifest skeleton)          ─► T-7 (core sources it), T-9
T-7 (core sequencer + arg parse) ─► T-8, T-9, T-10, T-11
T-8 (preflight/backup/libs)      ─► T-13
T-9 (dispatch engine)            ─► T-13
T-10 (relocations/installs/report)─► T-13
T-11 (detect/select/baseline_to_tmp/target_surface) ─► T-12, T-13
T-12 (core unit tests)           ─► (no downstream — gates CI)
T-13 (adapter refactor)          ─► T-14, T-15
T-14 (behavior-preservation test)─► (no downstream — gates closure)
T-15 (docs)                      ─► (no downstream)
```

**Public-API freeze gate.** After T-7 + T-11 land (i.e. the function
*signatures* exist even if some bodies are minimal stubs), the public
surface in §3 is locked. T-12's unit tests assert each name is defined.
BD-114's BD-120's implementer agents may begin reading against the
locked surface from that point on, even before T-13 ships.

---

## 6. Commit sequence (C-1..C-7)

Seven commits, each individually green under `validate-pack.yml`, each
reverting cleanly. The sequence is **gradual** until C-6 (the cutover);
C-7 is doc-only cleanup. Every commit's message follows the
`feat: vN — BD-119 …` / `docs: …` / `fix: …` convention from
`CLAUDE.md`.

| Commit | Title | Tasks bundled | What it must verify before staging |
|---|---|---|---|
| **C-1** | `feat: v11 — BD-119 add detect_target_pack_version + validate-pack Check 26 (lenient)` | T-2, T-3 | `bash -n scripts/lib/detect.sh`; `python3 scripts/validate-pack.py` green (Check 26 lenient — no-op when migrator-core absent); `bash scripts/test-detect.sh` green (covers existing detect functions, regression check). |
| **C-2** | `feat: v11 — BD-119 land migrator-core/stages/manifest skeletons` | T-4, T-5, T-6 | `bash -n` on all three new files; sourcing each in a subshell exits 0; `python3 scripts/validate-pack.py` green (Check 26 now active, asserts public-API names declared as stubs); existing tests unchanged. |
| **C-3** | `feat: v11 — BD-119 implement core sequencer + public API (surface lock)` | T-7, T-11 | `bash -n` clean; new `test-migrator-core.sh` (added in C-4) is not yet wired — but a smoke `bash -c 'source scripts/lib/migrator-core.sh; type migrator_run migrator_dispatch migrator_detect_target_version migrator_select_adapter migrator_baseline_to_tmp migrator_target_surface_for_version'` returns 0 for all six names. **Public surface locked at this commit.** |
| **C-4** | `feat: v11 — BD-119 implement stages + manifest engine + core unit tests` | T-8, T-9, T-10, T-12 | All existing CI jobs green; new `test-migrator-core.sh` step green; manifest-parser positive + negative cases green; trinity-parity validator green. |
| **C-5** | `test: v11 — BD-119 add behavior-preservation harness (advisory; runs against monolith only as smoke check)` | T-14 partial — harness exists; runs old monolith only against fixtures and writes a "baseline" output set under `/tmp/bd119-baseline-*` — tolerates the new framework being absent because T-13 has not landed | Harness script exists; CI step exists with `if: always()` and accepts a no-op exit when `BD119_REFACTOR_LANDED=0`; existing CI green. |
| **C-6** | `refactor: v11 — BD-119 refactor migrate-v10-to-v11.sh to adapter; flip behavior-preservation gate` | T-13, finalize T-14 | **The cutover commit.** Refactored adapter lands. Behavior-preservation harness now runs both pre-snapshot + post-refactor, diffs, fails CI on unexpected diff. All existing CI suites green. The pre-refactor monolith on disk is no longer needed at HEAD (snapshot lives off-tree per T-1); harness reads it from the C-1 parent commit's `git show HEAD~5:scripts/migrate-v10-to-v11.sh` (path: parent of C-1, i.e. branch base). See §8 for the exact recipe. |
| **C-7** | `docs: v11 — BD-119 README layout + pack-repo trinity update` | T-15 | `python3 scripts/validate-pack.py` green; `grep -RIn 'migrate-v10-to-v11' README.md supporting-docs/ maintenance-docs/` audited for stale claims (see §9 audit table); pack-repo trinity has the same one-line entry in all three files (verified by `diff <(grep -A1 'migrator framework' CLAUDE.md) <(grep -A1 'migrator framework' AGENTS.md)` etc.). |

**Each commit is independently revertable.** If C-6 fails behavior
preservation in a way that cannot be fixed in-branch within a day, C-1
through C-5 can ship as a partial framework (libs exist, public API
exists, no consumer yet) and BD-119's adapter refactor portion can be
re-attempted in a follow-up. This is explicitly desirable: the
framework's correctness is provable independently of whether the v10
adapter has cut over yet.

---

## 7. Replacement strategy: gradual vs atomic — and why

**Decision: gradual landing of the framework (C-1..C-5), atomic cutover
of the adapter (C-6), doc cleanup (C-7).**

The architecture leaves this decision open ("If at refactor time the
line counts argue for fewer files, collapsing manifest into stages is
acceptable"). Two strategies were considered:

**A) Atomic single-commit cutover.** Land all libs + refactored
adapter + tests + docs in one commit. Pros: no transitional state.
Cons: enormous diff (~1100 LOC); reviewer sees framework + adapter
intertwined; impossible to bisect a regression to library vs adapter;
if behavior-preservation diff fails, the entire commit reverts and we
lose the library work too.

**B) Gradual — chosen.** Land framework first, then cut over. Pros:
each commit reviewable on its own; bisection isolates regressions to
the right surface; if cutover fails, libraries persist as
ready-to-consume infrastructure for a follow-up attempt; BD-114 / BD-120
implementers can begin work after C-3 lands without waiting for the
v10 adapter cutover.

**Why no "migrator-core alongside monolith with a dispatch flag."**
The architecture explicitly mandates behavior preservation against
fixtures. A flag-based dispatch (e.g. `MIGRATOR_USE_FRAMEWORK=1`) would
require maintaining two code paths through C-6 and proving both
green — doubling the test surface. The behavior-preservation harness
already proves equivalence; an in-script flag is redundant. Rejected.

**Constraint on C-1..C-5: no live use of new libs.** Until C-6 lands,
nothing in the production code path sources `migrator-core.sh` outside
of unit tests. The libraries are dormant infrastructure. This makes
each pre-cutover commit verifiably non-behavior-affecting against
existing fixtures (the test-migrate-v10-to-v11 suite passes byte-for-byte).

---

## 8. Behavior-preservation verification recipe

Architecture §10 says "diff the resulting working trees" but does not
specify what counts as "equivalent." This section makes that concrete.

### 8.1 Inputs (fixtures)

From `test-fixtures/manifest.txt`:
- `v10-minimal` (SHA `134a86c…`) — minimal v10 shape; trivial migration.
- `v10-realistic-ot` (SHA `239c98a…`) — OT-shape customization patterns;
  the realistic test.
- `v11-flat-file` and `v11-tracker-on` — these are *post-migration*
  fixtures and the migrator MUST refuse to run against them (already
  at v11). They are inputs to the *negative* leg of the recipe (assert
  `EXIT_NOT_BASELINE`).

The harness re-builds fixtures via `test-fixtures/build.sh` and verifies
their SHAs against `manifest.txt` before running the diff (catches
fixture drift independently of migrator drift).

### 8.2 What "equivalent" means precisely

Equivalence is checked along five axes; each axis has a precise rule.

| Axis | Rule | Allowed difference |
|---|---|---|
| **A1 — Working tree file list** | `find <target> -type f \! -path '*/.git/*' \! -path '*/.pack-migrate-*' \| sort` must be byte-identical between old and new. | None. |
| **A2 — Working tree file contents** | For every file in the union of the two trees, `cmp` must return 0. | None — including whitespace and line endings. |
| **A3 — `report.md` content** | After redacting timestamps (regex `s/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z?/<TS>/g`), `cmp` must return 0. | Timestamps only. |
| **A4 — Stdout** | After redacting timestamps, target paths under `/tmp` (regex `s|/tmp/[^ ]*|<TMP>|g`), and any tmpfile names from `mktemp`, the two stdouts must `cmp` identical. | Timestamps, tmp-paths, mktemp names. |
| **A5 — Exit codes** | Across all triggerable failure paths (`EXIT_PACK_INVALID`, `EXIT_NOT_GIT`, `EXIT_DIRTY`, `EXIT_NOT_BASELINE`/`EXIT_NOT_V10`, `EXIT_BASELINE_MISSING`), both versions return identical numeric code. | None. The renamed `EXIT_NOT_BASELINE` constant equals 13, same as old `EXIT_NOT_V10`. |

**Rationale for the A4 redaction list.** These are the only sources of
nondeterminism in the existing migrator's stdout (verified by reading
`migrate-v10-to-v11.sh` lines 47–59 + every `printf '%s\n'` call).
Anything else differing is a regression.

**Single concession allowed.** The architecture renames `EXIT_NOT_V10`
to `EXIT_NOT_BASELINE`. Per §3.5, the old name is retained as a
synonym constant pointing at the same numeric value. **No exit code
visible to a caller changes.** This must be asserted by a dedicated
test case in `test-migrator-behavior-preservation.sh`.

### 8.3 Concrete shell recipe

The harness does the following (pseudocode-level, but commands are
literal so the implementer does not invent variants):

```bash
# Setup: snapshot of the pre-refactor monolith (taken in T-1).
OLD_MIGRATOR="$(git show <branch-base-sha>:scripts/migrate-v10-to-v11.sh)"
OLD_MIGRATOR_FILE="$(mktemp)"; printf '%s' "$OLD_MIGRATOR" > "$OLD_MIGRATOR_FILE"
chmod +x "$OLD_MIGRATOR_FILE"
NEW_MIGRATOR="$REPO_ROOT/scripts/migrate-v10-to-v11.sh"

# For each fixture:
for fx in v10-minimal v10-realistic-ot; do
  for impl in old new; do
    workdir=$(mktemp -d)
    cp -R "$REPO_ROOT/test-fixtures/$fx/." "$workdir/"
    git -C "$workdir" init -q && git -C "$workdir" add -A && \
      git -C "$workdir" -c user.email=t@t -c user.name=T commit -q -m init
    PACK="$REPO_ROOT" \
      bash "$([[ $impl = old ]] && printf '%s' "$OLD_MIGRATOR_FILE" \
              || printf '%s' "$NEW_MIGRATOR")" \
      "$workdir" > "$RESULTS/$fx.$impl.stdout" 2> "$RESULTS/$fx.$impl.stderr"
    echo $? > "$RESULTS/$fx.$impl.exit"
    # Capture working tree.
    (cd "$workdir" && find . -type f \! -path './.git/*' \! -path './.pack-migrate-*' \
       | sort > "$RESULTS/$fx.$impl.filelist")
    tar -C "$workdir" --exclude='./.git' --exclude='./.pack-migrate-*' \
       -cf "$RESULTS/$fx.$impl.tar" .
  done
  # Compare.
  diff "$RESULTS/$fx.old.filelist" "$RESULTS/$fx.new.filelist" || fail A1
  # Per-file cmp via a manifest walk:
  while IFS= read -r f; do
    cmp <(tar -xOf "$RESULTS/$fx.old.tar" "$f") \
        <(tar -xOf "$RESULTS/$fx.new.tar" "$f") || fail "A2 $f"
  done < "$RESULTS/$fx.old.filelist"
  # Stdout: redact + cmp.
  redact() { sed -E "s/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z?/<TS>/g; s|/tmp/[^ ]*|<TMP>|g"; }
  cmp <(redact < "$RESULTS/$fx.old.stdout") \
      <(redact < "$RESULTS/$fx.new.stdout") || fail A4
  # Exit codes.
  cmp "$RESULTS/$fx.old.exit" "$RESULTS/$fx.new.exit" || fail A5
done

# Negative cases (A5): EXIT_PACK_INVALID, EXIT_NOT_GIT, EXIT_DIRTY,
# EXIT_NOT_BASELINE, EXIT_BASELINE_MISSING. Five subtests each running
# both old and new against a deliberately-broken target and asserting
# numeric exit code equality.
```

**Portability constraints honored.** All commands are bash 3.2 + BSD
or GNU compatible: `find -print` (not `-print0`), `tar` with both
`--exclude` (BSD + GNU), `sed -E` (both), `cmp` (POSIX), `mktemp` no
template (both). No `find -regex`, no `tar --exclude-from=` (avoids GNU
vs BSD path-rooting differences), no `diff --color`. Architecture R3
mitigated.

### 8.4 What success looks like

- All five axes pass on both `v10-minimal` and `v10-realistic-ot`.
- All five negative-path exit-code tests pass.
- Total: **2 fixtures × 5 axes + 5 negative tests = 15 assertions, all green.**
- No allow-list. The architecture says behavior preservation; the
  harness enforces it absolutely. **Any non-trivial diff blocks
  closure** per architecture §10 last paragraph.

### 8.5 CI hookup

- `scripts/tests/test-migrator-behavior-preservation.sh` runs as a
  `validate-pack.yml` step under the `tests` job, `if: always()`.
- Until C-6 lands (i.e. on C-5), the script reads `BD119_REFACTOR_LANDED`
  env (default `0`); if `0`, it runs the old migrator only and exits
  green after producing baseline outputs (sanity check that the
  fixtures + monolith are reproducible — catches fixture drift early).
- At C-6, `BD119_REFACTOR_LANDED=1` is set and the full diff runs.
- The behavior-preservation test is **NOT** in the BD-117 manual gate
  (architecture R1 lists BD-114 as the manual gate). It runs on every
  push, fully automated. This makes it CI per BD-118's intent and
  matches the BD-118 description "synthetic migration contract through
  v10-realistic-ot."

### 8.6 What semantic-but-not-byte-identical differences are acceptable

**None.** Architecture §1 is explicit ("same exit codes, same
artifacts, same report shape, same console output"). The redactions in
A3/A4 are for nondeterministic *sources* (timestamps, mktemp names)
that already vary between two runs of the *same* migrator — not
between old and new. Redacting them does not relax the equivalence
contract; it normalizes the comparison input.

If during implementation the implementer discovers a deterministic but
unavoidable difference (e.g., the framework adds a leading blank line
to a stage banner), that is **not** acceptable as an allow-list entry —
it is a bug to fix in the framework. The implementer files a §13
diagnosis and the architecture is amended (a new BD), not the harness
softened.

---

## 9. Trinity + cross-doc updates

### 9.1 Touch matrix

| Doc | Touched? | What | Why |
|---|---|---|---|
| `CLAUDE.md` (pack repo root) | **Required** | Add a one-line bullet under "Repo structure" or "Rules for agents" naming the migrator framework as the place to extend when authoring `migrate-vN-to-vM.sh`. | Trinity rule (CLAUDE.md text changed) — fires the same edit in AGENTS.md and GEMINI.md. |
| `AGENTS.md` (pack repo root) | **Required** | Same one-line entry, identical wording. | Trinity. |
| `GEMINI.md` (pack repo root) | **Required** | Same one-line entry, identical wording. | Trinity. |
| `README.md` Repository Layout | **Required** | Three new lines under the `scripts/lib/` block (between current `three-way.sh` and `customization-preserve.sh` lines, alphabetical-ish to match style): `migrator-core.sh`, `migrator-stages.sh`, `migrator-manifest.sh`. | Architecture §3.1 introduces the files; CLAUDE.md says README is authoritative for layout. |
| `README.md` version history table | **N/A** | BD-119 is a refactor without a version cut; no row added. | Per CLAUDE.md, version-table edits are PM-chat only. |
| `PACK-AGENTS.md` | **N/A** | No new pack agent or routing introduced. | The framework is a shared library, not an agent. |
| `PACK-CHAT.md` | **N/A** | No PM-chat operating change. | Behavior-preserving refactor. |
| `CHANGELOG.md` | **N/A** | Mid-version refactor, no changelog entry. | Per CLAUDE.md, CHANGELOG is touched at version boundaries with explicit instruction. |
| `supporting-docs/MIGRATION-v10-to-v11.md` | **N/A** | Behavior is preserved; user-facing migration guide is unchanged. | Architecture §1 mandates behavior preservation. |
| `supporting-docs/MERGE-STRATEGY.md` | **N/A** | Per-file customization rules unchanged. | Architecture §3.1 marks the libs unchanged. |
| `supporting-docs/INSTALL-PROCEDURES.md` | **N/A** | No install-procedure change. | — |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` | **N/A** | Authoritative input; only edited if implementer finds an architectural gap (in which case file an OQ in §15 of this plan, not silent revision). | — |
| `project-template/CLAUDE.md / AGENTS.md / GEMINI.md` | **N/A** | Project-template trinity is for shipped projects, not pack-repo development. The migrator framework is pack-internal. | — |
| `.github/ISSUE_TEMPLATE/work-item.yml` | **N/A** | No issue-template change. | — |
| `HELP-FRAGMENT*.md` | **N/A** | No new pack verb introduced. | — |

### 9.2 Stale-reference grep audit (run before C-7)

The implementer runs these greps and confirms results match expectations:

```bash
# 1. Find all docs that name the v10→v11 migrator file path.
grep -RIn 'migrate-v10-to-v11' README.md supporting-docs/ maintenance-docs/

# Expectation: every hit must still be accurate after refactor.
#   - README.md line 181 ("v10.0 → v11.0 migration script (v11)") — still true.
#   - supporting-docs/MIGRATION-v10-to-v11.md user-facing usage — still true.
#   - DOG-FOOD-MIGRATION-REPORT.md — historical artifact, references frozen.
# If any hit names line numbers or function names from the old monolith
# (e.g. "stage_s3_dispatch", "v10_baseline_to_tmp"), update or remove
# that hit.

# 2. Find all references to renamed exit code.
grep -RIn 'EXIT_NOT_V10' .

# Expectation: only `scripts/migrate-v10-to-v11.sh` (now adapter) and
# `scripts/lib/migrator-core.sh` (the synonym `readonly EXIT_NOT_V10=$EXIT_NOT_BASELINE`).
# Any other hit is stale and must be updated to EXIT_NOT_BASELINE.

# 3. Find references to the old monolith's stage names.
grep -RIn 'stage_s[0-9]_\|v10_baseline_to_tmp' .

# Expectation: only inside scripts/migrate-v9-to-v10.sh (frozen v10 migrator,
# not refactored), the architecture doc itself (frozen reference), and
# DOG-FOOD-MIGRATION-REPORT.md (historical). Any *active* doc hit is
# stale.

# 4. Trinity parity check on pack-repo trinity files.
diff <(awk '/^## Repo structure/,/^## /' CLAUDE.md | head -20) \
     <(awk '/^## Repo structure/,/^## /' AGENTS.md | head -20)
diff <(awk '/^## Repo structure/,/^## /' CLAUDE.md | head -20) \
     <(awk '/^## Repo structure/,/^## /' GEMINI.md | head -20)

# Expectation: identical, modulo each file's existing tool-specific
# preamble. The new framework bullet is identical wording in all three.
```

### 9.3 Trinity bullet wording (suggested)

The implementer is free to re-word but the bullet must convey:

> When authoring a new `migrate-vN-to-vM.sh`, source
> `scripts/lib/migrator-core.sh` and supply the adapter contract
> (`MIGRATOR_*` vars + five hook functions). See architecture
> `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` for the
> contract. Do NOT copy `migrate-v10-to-v11.sh` and rewrite — that
> regresses the framework.

This wording is the same across all three trinity files. No tool-
specific carve-out is justified.

---

## 10. Open-question disposition

Architecture §11.2 names five OQs. Each is resolved or deferred below
with explicit rationale + the trigger that would force re-asking.

### OQ1 — BD-095 dry-run/apply/resume integration

**Architecture says:** "pack-planner needs to confirm BD-095's design
has not already constrained where the modes live."

**Status of BD-095:** Open per BACKLOG.md line 672; "Blockers: BD-085,
BD-088, BD-094." BD-095 has not started. No design constraint exists
yet that the framework would conflict with.

**Disposition: RESOLVED — modes live in the core (per architecture I6,
I8), and BD-095 implementer inherits the placement.** BD-119
implements `--dry-run` plumbing (the `_MIGRATOR_DRY_RUN` flag wired
through `_stage_*` functions) but the rich two-phase / `--resume`
state-file logic stays for BD-095. Concretely: BD-119 adds the
`--dry-run` flag to `migrator_run` arg parsing, the flag short-circuits
mutations in each stage with a "[dry-run] would <verb> <file>" log,
and exit code is 0 if dry-run completed without errors. `--apply` and
`--resume` are stubs that error "not yet implemented; see BD-095."

**Trigger to re-ask:** if BD-095 design later mandates the modes live
in a separate orchestrator outside `migrator-core.sh`, OQ1 reopens.

### OQ2 — Manifest validation tooling location

**Architecture says:** separate script vs check in `validate-pack.py`.

**Disposition: RESOLVED — Check 26 in `validate-pack.py`.** Reasoning:
existing CI shape adds checks to `validate-pack.py` (currently 25
checks); a separate script duplicates the runner pattern. Manifest
linting is structural — exactly what `validate-pack.py` is for.
Implementer adds Check 26 per T-3, extends it during T-13 to actually
parse the v10→v11 adapter's manifest and validate it.

**Trigger to re-ask:** if Check 26 needs to call `customization_preserve`
to validate, it would belong outside `validate-pack.py` (which is
Python-only). Trigger: if Check 26 needs more than text/regex parsing.

### OQ3 — Adapter discovery: glob vs registry

**Architecture says:** "Glob is simpler and matches existing pack
conventions; a registry is more explicit."

**Disposition: RESOLVED — glob.** `migrator_select_adapter` globs
`$PACK/scripts/migrate-v*-to-v*.sh`, parses the version pair from the
filename (regex `migrate-v([0-9]+)-to-v([0-9]+)\.sh`), and returns the
match for the requested from-version. Errors loudly on ambiguity (two
adapters claim the same from-version) or missing file. No registry
file. Matches the convention of `init-project.sh` and other pack
scripts that derive metadata from filenames.

**Trigger to re-ask:** if multiple adapters per from-version become a
real case (e.g., a hotfix adapter `migrate-v10-to-v11-hotfix.sh`),
trigger re-ask. Until then, glob is sufficient.

### OQ4 — `init-project.sh --update` integration

**Architecture says:** "Architect's leaning: yes, but explicitly *out
of scope* for BD-119."

**Disposition: DEFERRED — out of scope, no work in BD-119.** A new BD
in v11 scope ("BD-NNN — express init-project.sh --update as a vN→vN
self-migration against the framework") will be filed by PM chat after
BD-119 ships. BD-119 implementer touches `init-project.sh` for
**zero** lines.

**Trigger to re-ask:** never within BD-119. Only after C-7 lands and
PM chat opens the follow-up BD.

### OQ5 — Trinity-rule check coverage (which surfaces validate?)

**Architecture says:** the check covers CLAUDE.md / AGENTS.md /
GEMINI.md (always); architect's recommendation extends to seven
surfaces (`.claude/agents`, `.codex/agents`, `.gemini/agents`,
`.claude/skills`, `.codex/skills`, `.gemini/skills`,
`docs/pack/prompts`).

**Disposition: PARTIALLY RESOLVED — implementer enforces the three
context files; the seven-surface generalization is recommended but not
required for BD-119.**

Reasoning: the trinity *rule* in pack convention is specifically about
the three context files (CLAUDE/AGENTS/GEMINI). The seven-surface
extension is a generalization of M9 ("per-CLI artifact installs
duplicated three times with subtle drift") — valuable, but it expands
the manifest validator's scope and risks false positives if (e.g.) a
v12 transition deliberately ships only `.codex/agents/foo.md` because
a Claude/Gemini equivalent doesn't exist yet. That is a real case
(Codex skill-pack has shipped Codex-only items historically per the
pack convention).

Implementer behavior: validator hard-errors on trinity (CLAUDE/AGENTS/
GEMINI) parity violations. Validator emits a `warning:` on per-CLI
agent-or-skill parity violations but does not block. The warning text
names the missing surface and points at architecture §6 I5 / §8 M9.

**Trigger to re-ask:** if the M9 defect class re-surfaces in a future
review (a per-CLI artifact ships for one CLI but not the other two
without explicit justification), upgrade the warning to an error in a
follow-up BD.

### Summary

- **Resolved (3):** OQ1 (modes in core, BD-095 inherits), OQ2 (Check
  26 in validate-pack.py), OQ3 (glob adapter discovery).
- **Deferred (1):** OQ4 (init-project --update integration — separate
  BD).
- **Partially resolved (1):** OQ5 (trinity hard, seven-surface soft).

---

## 11. Risk register + verification mapping

### 11.1 Architecture risks

| Risk | Architecture | Mitigation in this plan | Verified by |
|---|---|---|---|
| **R1** Shared-bug blast radius (a defect in core hits every adapter) | §11.1 | Behavior-preservation harness (§8) is mandatory at C-6 and runs every push thereafter. `validate-pack.yml` Check 26 inventory + unit tests in T-12. BD-118 CI (separate BD) extends coverage. | T-12, T-14; CI green at C-4 onward; behavior-preservation green at C-6. |
| **R2** Wrong abstraction (four manifest verbs insufficient) | §11.1 | Hooks (`migrator_pre_dispatch_hook` / `migrator_post_dispatch_hook`) are the documented escape valve. Plan does NOT pre-emptively add new verbs. The v10→v11 refactor uses only the four documented verbs (proves sufficiency for at least one transition). | T-13 — if implementer needs a fifth verb to refactor the v10→v11 adapter cleanly, file an OQ in §15 and stop; do not silently add a verb. |
| **R3** Bash portability (macOS bash 3.2 vs Linux bash 5+) | §11.1 | §8 recipe explicitly uses portable command forms (no `find -print0`, no GNU-only `tar` flags, `mktemp` no template, `sed -E`). CI runs on `ubuntu-latest`; implementer additionally runs the harness locally on macOS before C-6. | Manual macOS run is in the C-6 pre-stage checklist. CI Linux run on every push from C-4 onward. |
| **R4** Trinity-parse-time errors surprise adopters | §11.1 | The validator's error message (per OQ5 disposition) names all three trinity files and which is missing, plus a pointer to the architecture's I5 invariant. Documentation will follow when the first non-v10 adapter is authored. | T-12 negative-case unit test asserts the error message contains all three filenames. |
| **R5** Coupling to `customization-preserve.sh` API | §11.1 | The framework engine in `migrator-manifest.sh` is the single caller; today there are two callers in pack (`migrate-v10-to-v11.sh` and `init-project.sh --update`). After C-6, that drops to two still (since OQ4 is deferred), but the migrator-side caller is now centralized. Future API change ripples through one file in scripts/lib/. | Static — provable by `grep -RIn 'customization_preserve' scripts/` after C-6 returning two surfaces only (`migrator-manifest.sh` + `init-project.sh`). |

### 11.2 Planner-identified risks

| Risk | Description | Mitigation | Verified by |
|---|---|---|---|
| **PR-6** Snapshot-diff drift if branch base moves | If the implementer rebases the BD-119 branch mid-flight, the "branch base" SHA the harness reads against shifts. The pre-refactor monolith embedded in `git show <branch-base>:scripts/migrate-v10-to-v11.sh` could already differ from what was on-disk at T-1. | T-1 also writes the monolith bytes to `scripts/.bd119-pre-refactor-monolith.sh.snapshot` (filename in `.gitignore`, never committed). The harness reads the on-disk snapshot, not git. Branch rebases do not affect the on-disk file. | T-14 reads the snapshot file, not a git ref. Test asserts file exists with `[[ -f $SNAPSHOT ]]` else it fails fast. |
| **PR-7** Public-API freeze leaks downstream BD work into BD-119 | BD-114 / BD-120 implementer agents start consuming the surface after C-3. If they discover a missing helper, the temptation is to amend BD-119 in-flight. | §3 lists the **complete** public surface frozen at C-3. Any addition required by BD-114 / BD-120 implementer is filed as a new BD or as an OQ in §15 here, not silently merged. | Code review gate: any commit on the BD-119 branch after C-3 that adds a name to `migrator-core.sh`'s public surface (i.e., a function whose name does not match `^_migrator_` or `^_stage_`) is flagged. |
| **PR-8** Behavior-preservation false-green on under-tested fixture path | If `v10-realistic-ot` does not exercise a code path the framework changed, the harness greens but production breaks. | `v10-realistic-ot` was specifically built to exercise OT-shape patterns (architecture §9.1). `v10-minimal` covers the trivial path. Together they exercise all `transform` / `add` / `remove` / `relocate-from` actions present in the v10→v11 manifest (verified during T-13). | T-13 author runs `bash -x` once per fixture before C-6 and confirms each action verb is hit at least once (logged to a one-time analysis under `/tmp/bd119-coverage.log`, not committed). |
| **PR-9** `detect_target_pack_version` heuristic ambiguity for v10-with-tracker fixtures | A v10 project that opted into the tracker between v10 install and v10→v11 migration carries `tracker.toml`. The architecture §5.1 signal ladder names tracker.toml `[pack].version` as signal 1 — but v10 tracker.toml does not have that field (the field is added at v11). Detection could over-rely on signal 1 and misclassify. | T-2 implements signal 1 as **opt-in** ("if `[pack].version` is present, trust it") — *absence* of the field is not a v10 signal, the cascade continues. T-2 unit test covers a v10 fixture with tracker.toml-without-pack-version. | T-12 test case `detect_v10_with_tracker_no_pack_version_returns_v10`. |

---

## 12. Downstream integration cues (BD-114, BD-115, BD-120)

### 12.1 BD-114 — Real-OT read-only dry-run harness

**Consumer surface from BD-119:** `migrator_detect_target_version`,
`migrator_select_adapter`, `migrator_run` (or `migrator_dispatch`).
Architecture §5.2 shows the exact shape:

```bash
detected=$(migrator_detect_target_version "$tmp_clone")
adapter=$(migrator_select_adapter "$detected")
PACK="$PACK" bash "$adapter" "$tmp_clone"
```

**Cue for the BD-119 implementer:** these three function names are
**part of the BD-119 public surface freeze** at C-3. Do NOT rename
during refactor. Do NOT collapse `migrator_dispatch` into `migrator_run`
even if they look redundant; BD-114 may want the no-usage-printing
variant.

**Cue for the BD-114 implementer (read by them, not by us):** safe to
begin work after C-3 lands. The behavior-preservation refactor at C-6
does not change any public-API name.

### 12.2 BD-115 — `existing-project-mid-dev` fixture

**No direct dependency.** BD-115 is a fixture, not a migrator
consumer. BD-115 is unblocked already (BACKLOG.md line 1055
"Blockers: None").

**Cue for the BD-115 implementer:** the new fixture must build
deterministically (architecture §9 implies the SHA is recorded in
`test-fixtures/manifest.txt`) and must NOT rely on any pre-existing
pack file in the working tree (this is the "user has a real project
mid-development" persona — pure non-pack content). It does NOT need
to be migrator-runnable; BD-116 contracts use `init-project.sh
--update`, not `migrate-v10-to-v11.sh`.

**Cue for the BD-119 implementer:** if BD-115 lands during BD-119's
window (likely — both are Open, no shared blocker), BD-115's
modifications to `test-fixtures/build.sh` are concurrent with the
behavior-preservation harness. To avoid a merge collision: the
behavior-preservation harness reads fixtures directly from
`test-fixtures/v10-minimal/` and `test-fixtures/v10-realistic-ot/` —
both are pre-existing in `manifest.txt` (SHAs already pinned). BD-119
**does not** need to add a new fixture, and should not. BD-119
implementer must NOT touch `test-fixtures/build.sh`.

### 12.3 BD-120 — Parameterize realistic-OT fixture

**Consumer surface from BD-119:** `migrator_target_surface_for_version <vN>`
(architecture §9.2). The function is on the public-surface freeze list
(§3.1).

**Cue for the BD-119 implementer:** ship the helper in T-11. Even
though BD-120 is BD-119's downstream (BACKLOG.md line 1153 "Blockers:
BD-119"), the helper is a single short function and is on the locked
surface; deferring it costs another version's surface change.

**Cue for the BD-120 implementer (downstream):** safe to read
`migrator_target_surface_for_version` as the canonical source of "what
relpaths does a vN install create?" The implementation may glob
`project-template/` at the time of the call; the *return* shape is
what's contracted, not the internals.

### 12.4 BD-116 / BD-117 / BD-118 — no direct cues

- **BD-116** (persona contracts) blocks on BD-115, not BD-119. The
  migration contract subtest of BD-116 will read the v10→v11 manifest
  from inside the refactored adapter (architecture §4.2 point 3) — but
  that surface is the manifest format, not a function name.
- **BD-117** (RELEASE-GATE.md) consumes BD-114's harness as a manual
  gate. Indirect dependency through BD-114.
- **BD-118** (CI wiring) consumes BD-116 contracts. The
  behavior-preservation harness from §8 here is **not** a BD-118
  surface (architecture R1 + the harness is fixture-vs-fixture, not
  contract-vs-template). BD-118 implementer should NOT pull the
  behavior-preservation step into BD-118 — it ships under BD-119 and
  is already wired into `validate-pack.yml` at C-5/C-6.

### 12.5 Public-surface no-rename pact

The function names introduced in §3 are **part of BD-119's public
surface for the duration of v11.x**. No follow-on BD (BD-114, BD-115,
BD-120, BD-117, BD-118, or any other) may rename them without
amending BD-119 in writing (a new BD or a follow-up commit explicitly
in BD-119's number). If during BD-114's review the architecture team
decides a name should change, the change ships as a BD-NNN+1 amendment
to BD-119, not silently. The plan flags this so a downstream
implementer agent does not accidentally rename and break the contract.

---

## 13. Failure-mode triage (when behavior-preservation diff fails)

If the harness from §8 reports a non-trivial diff at C-6, the
implementer follows this protocol — do NOT loosen the harness, do NOT
add allow-list entries.

### 13.1 Diagnostic protocol

1. **Capture both outputs.** Run the harness with `BD119_KEEP_RESULTS=1`
   so `/tmp/bd119-results-*` is preserved (the harness deletes by
   default). Write a short report to
   `maintenance-docs/v11-implementation/DIAGNOSIS-BD-119-<date>.md`
   (a temporary file the implementer creates ad-hoc; not committed,
   only used to communicate with reviewer).

2. **Classify the diff axis.** Which of A1..A5 fails?
   - **A1 (file list)**: a file is being created or omitted that was
     not before. Locate via `diff filelist.old filelist.new`. Most
     likely culprit: an `add` or `relocate-from` action emitting an
     extra path.
   - **A2 (file contents)**: identify the diverging file via the cmp
     loop. Most likely culprit: ordering of `customization_preserve`
     calls, or a `git show` extraction race, or path normalization
     differences.
   - **A3 (report.md)**: the disposition table differs. Likely culprit:
     manifest ordering, since `customization-report.sh` writes
     dispositions in dispatch order.
   - **A4 (stdout)**: a banner string changed, or a warn/info line
     order changed. Likely culprit: stage banner wording or printf
     ordering.
   - **A5 (exit codes)**: a failure path returns a different code.
     Likely culprit: `EXIT_NOT_BASELINE` rename not propagating, or
     `fail_stage` numeric formula mismatch.

3. **Locate the framework code path.** For A1/A2/A3: read
   `migrator-manifest.sh` for the dispatch action that produced the
   diverging artifact. For A4: read `migrator-stages.sh` for the
   banner. For A5: read `migrator-core.sh` exit-code constants.

4. **Compare against the snapshot.** `diff -u
   scripts/.bd119-pre-refactor-monolith.sh.snapshot
   scripts/migrate-v10-to-v11.sh` — the relevant logic is somewhere
   in the deleted lines. Find where the framework should but does
   not match.

5. **Decide: framework bug or adapter bug.**
   - **Framework bug**: fix in `scripts/lib/migrator-*.sh`. The fix
     improves all future adapters too. Re-run harness.
   - **Adapter bug**: the v10→v11 adapter's manifest or hooks are not
     declaring something the framework expects. Fix in
     `scripts/migrate-v10-to-v11.sh` (the adapter). Re-run harness.
   - **Architecture gap**: framework cannot express what the monolith
     did without a new manifest verb or hook. STOP. File OQ in §15
     and escalate — do not silently extend the framework.

6. **Re-run the full harness.** After the fix, re-run all 15
   assertions (2 fixtures × 5 axes + 5 negative). Partial green is
   not green.

### 13.2 Where logs go

- Harness output: `/tmp/bd119-results-*/<fixture>.<impl>.{stdout,stderr,exit,filelist,tar}`
- Diff report (ad-hoc): `maintenance-docs/v11-implementation/DIAGNOSIS-BD-119-<date>.md` (gitignored or simply not committed)
- CI artifact (if upload-artifact is added in T-14, optional):
  `actions-runner-bd119-results.tar.gz`. Only added if implementer
  finds CI logs alone insufficient; default is no artifact.

### 13.3 What is NEVER an acceptable resolution

- Adding the diverging file to an A1 allow-list. There is no allow-list.
- Adding a regex redaction to A4 beyond timestamps + tmp paths.
- Marking the harness `continue-on-error: true` in CI.
- Changing the architecture's "behavior preservation is mandatory"
  position. Architecture amendment requires a new BD with explicit
  PM-chat approval.
- Tagging v11.0 with the behavior-preservation harness red.

### 13.4 Distinguishing "expected" from "regression"

There is no "expected diff" in BD-119. **Every diff is a regression
unless it is the documented `EXIT_NOT_V10` → `EXIT_NOT_BASELINE`
constant rename, which is invisible at the numeric exit-code level
because the synonym constant retains the old name.** If A5 fails on
exit code 13 specifically, the synonym retention is broken — fix the
core, do not amend the harness.

---

## 14. Definition of Done for BD-119

BD-119 flips to Resolved (per implicit-flip rule) when **every** item
below is true. Implementer treats this as a checklist, ticks each in a
final commit message body or PR description.

### 14.1 Code

- [ ] `scripts/lib/migrator-core.sh` exists, sources cleanly, exposes the six public-API functions per §3.1.
- [ ] `scripts/lib/migrator-stages.sh` exists, sourced by core, implements I1, I2, I3, I4, I6, I8 per architecture §6.
- [ ] `scripts/lib/migrator-manifest.sh` exists, sourced by core, validates trinity-parity (I5) and dispatches all four manifest verbs.
- [ ] `scripts/lib/detect.sh` has `detect_target_pack_version` per architecture §5.1.
- [ ] `scripts/migrate-v10-to-v11.sh` is ~120 lines, sources `migrator-core.sh`, declares `MIGRATOR_*` vars, defines five required hooks, calls `migrator_run "$@"`.
- [ ] No public-API name in §3 was renamed after C-3.

### 14.2 Tests

- [ ] `scripts/tests/test-migrator-core.sh` green (unit tests).
- [ ] `scripts/tests/test-migrator-behavior-preservation.sh` green: 2 fixtures × 5 axes + 5 negative-exit-code = 15 assertions all pass.
- [ ] `scripts/tests/test-migrate-v10-to-v11.sh` (existing BD-085 suite) green — proves the refactor did not regress the existing fixture suite.
- [ ] All other `scripts/tests/*-test.sh` still green.

### 14.3 CI

- [ ] `validate-pack.yml`: both jobs (validate, tests) green on the final commit.
- [ ] Check 26 in `validate-pack.py` passes.
- [ ] `python3 scripts/validate-pack.py` exits 0 locally on macOS.

### 14.4 Docs

- [ ] `README.md` Repository Layout names the three new lib files.
- [ ] Pack-repo `CLAUDE.md / AGENTS.md / GEMINI.md` each contain the framework bullet, identical wording.
- [ ] No stale references in the §9.2 grep audit (`migrate-v10-to-v11`, `EXIT_NOT_V10`, old stage names).
- [ ] `ARCHITECTURE-BD-119.md` cross-references all valid (no broken paths). Implementer runs `grep -oE '\b[a-z][a-z_-]+/[a-z_./-]+' maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md | sort -u | while read p; do [[ -e $p ]] || echo "MISSING: $p"; done` and confirms zero MISSING lines.
- [ ] `PLAN-BD-119.md` (this file) cross-references valid (same grep).

### 14.5 Open questions

- [ ] OQ1, OQ2, OQ3, OQ5 resolved in §10 of this plan; resolutions reflected in code.
- [ ] OQ4 deferred in writing in §10 of this plan; no `init-project.sh` edits in any commit.
- [ ] No new architectural OQs introduced in §15 are unaddressed; each is either resolved by the implementer with rationale logged in the commit, or explicitly deferred to a future BD.

### 14.6 Cross-doc + repo hygiene

- [ ] No PM-chat-only file modified (`BACKLOG.md`, `README.md` version-history table, `PACK-CHAT.md`, `PACK-AGENTS.md`).
- [ ] No `CHANGELOG.md` edit (mid-version refactor).
- [ ] No `init-project.sh` edit (OQ4 deferred).
- [ ] No `customization-preserve.sh` / `customization-report.sh` / `three-way.sh` edit.
- [ ] No `migrate-v9-to-v10.sh` edit (frozen).
- [ ] No `test-fixtures/build.sh` edit (BD-115 / BD-120 surface).
- [ ] All commits follow `feat: v11 — BD-119 …` / `fix:` / `docs:` / `refactor:` / `test:` convention.
- [ ] `git add -A && git status` is shown before each commit per CLAUDE.md.

### 14.7 Reviewer + maintainer sign-off

- [ ] One pack-reviewer pass after C-7 (per the one-review/fix-cycle-per-batch rule). Review prompt cites ARCHITECTURE-BD-119.md and this PLAN, never any prior review.
- [ ] If reviewer finds issues: fix in-session (in BD-119's commits or a Pack-Chat-approved follow-up commit), then move on.
- [ ] PM chat flips BD-119 to Resolved with the date in BACKLOG.md after batch completion (implicit-flip rule).

---

## 15. Newly identified open questions (planner-side)

Open questions that surfaced *during planning*, not present in the
architecture. Each has a recommended default the implementer may
follow without re-asking; the trigger column says when the implementer
must stop and escalate.

### POQ-1 — Manifest TSV: in-script heredoc or external file?

**Question:** Architecture §4.2 shows the manifest as TSV. Should the
adapter emit it from a function (heredoc) or maintain it as a separate
file (e.g., `scripts/migrate-v10-to-v11.manifest.tsv` next to the
adapter)?

**Recommended default:** in-script heredoc inside `migrator_manifest()`.
Reasoning: keeps the adapter self-contained (one file per version,
matches architecture §4.1's "thin adapter" pattern); diffability is
preserved (heredoc body is a clean TSV block); separate-file
introduces a path-discovery problem (where does
`migrator_manifest_path` look?).

**Trigger to escalate:** if the v10→v11 manifest exceeds ~50 entries
during T-13 (current monolith has ~14), heredoc readability degrades.
Currently safe.

### POQ-2 — `--dry-run` plumbing depth in BD-119 vs BD-095

**Question:** Architecture I6 implies dry-run lives in core. OQ1
deferred most of the modes to BD-095. What level of dry-run does
BD-119 ship?

**Recommended default:** BD-119 ships `--dry-run` flag plumbing only:
the core's arg parser recognizes the flag, sets `_MIGRATOR_DRY_RUN=1`,
and each `_stage_*` function checks the flag and short-circuits its
mutating path with a `[dry-run] would <verb>` log line. The two-phase
`--apply` and `--resume` BD-095 will add are stub branches that error
"not yet implemented; see BD-095." Behavior-preservation harness does
NOT exercise dry-run (out of scope of equivalence; the old monolith
has no dry-run).

**Trigger to escalate:** if T-13 reveals a stage where the dry-run
short-circuit would skip a check the user needs (e.g., baseline-tag
existence), implementer must NOT silently skip; instead, the check
runs read-only, only the *write* short-circuits.

### POQ-3 — `[pack] version` field in tracker.toml — write or not?

**Question:** Architecture §7 last paragraph says "the migrator
framework should write that field at the end of a successful run *if
`tracker.toml` already exists in the target*." Is this in BD-119 scope
or deferred?

**Recommended default:** **In BD-119 scope.** It is a one-line write,
version-derived (`MIGRATOR_TO_VERSION`), and lives in `_stage_report`
of the core. Implementer adds it to T-10. The new field is added with
an idempotent write (`if grep -q '^\[pack\]' tracker.toml; then
update; else append`). Only fires if `tracker.toml` exists; never
creates the file.

**Trigger to escalate:** if writing the field triggers a TOML-parse
failure in `pack-tracker.sh status` (the tracker subsystem's existing
TOML reader). Implementer runs `pack tracker status` against the
post-migrated v10-realistic-ot fixture as a sanity check before C-6.

### POQ-4 — Where to physically store the pre-refactor monolith snapshot

**Question:** PR-6 (§11.2) names a `.bd119-pre-refactor-monolith.sh.snapshot`
file. Repo policy on snapshots?

**Recommended default:** `scripts/.bd119-pre-refactor-monolith.sh.snapshot`,
added to `.gitignore` in T-1 commit (or in C-5 — gitignore lives at
repo root). The file exists only on the implementer's working tree
during the BD-119 branch lifetime. After C-7 ships, the file is
deleted from the working tree — the harness no longer needs it
because behavior preservation is proven. The harness includes a
fallback: if `BD119_KEEP_SNAPSHOT=0` (default after C-7), and the
snapshot file is missing, the harness extracts the monolith from
`git show <pre-refactor-tag-or-sha>:scripts/migrate-v10-to-v11.sh` —
where `<pre-refactor-tag-or-sha>` is recorded in a comment at the top
of the harness script. **This is the only durable record of the
pre-refactor SHA.**

**Trigger to escalate:** if the implementer wants to delete the
behavior-preservation harness entirely after C-7 (because the proof is
done). RECOMMENDATION: keep the harness in CI permanently — it
catches future regressions in `customization-preserve.sh` or in any
other lib that the framework depends on. Do not delete.

### POQ-5 — Trinity-parity validator: hard-error or pre-flight warning?

**Question:** Architecture I5 says "errors before any mutation."
Should the error be at adapter source-time (parse-time of the
manifest) or at dispatch start?

**Recommended default:** at dispatch start (i.e., inside `_stage_dispatch`,
before the engine's per-entry loop). Reasoning: source-time validation
would require the core to parse the manifest at adapter source, which
means `migrator_manifest` must be callable before `migrator_run` — a
contract change. Dispatch-start validation matches the existing
preflight pattern (errors come from `_stage_*` functions, not from
sourcing).

**Trigger to escalate:** if an implementer reviewing this prefers
parse-time enforcement, the contract change (callable-before-`migrator_run`)
must be discussed; do not silently switch.

---

## End of plan

Implementer: read top to bottom, execute T-1 through T-15 in order,
commit per the §6 sequence, run §8 harness on every push, and tick
§14 Definition of Done before requesting review.

