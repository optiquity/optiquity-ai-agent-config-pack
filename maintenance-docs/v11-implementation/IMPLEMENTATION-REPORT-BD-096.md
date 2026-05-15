---
title: IMPLEMENTATION-REPORT-BD-096
author: pack-coder (v11-dev, Batch 16)
status: implementation complete; ready for Pack Chat stage + commit
date: 2026-05-14
---

# Implementation report — BD-096 Synthetic-fixture set (Batch 16)

**Branch / HEAD:** `v11-dev` @ `91e7563c172afed77d79f390c2452a1e6fd01342` (unchanged — agent did not commit, per pack rules).

## Files changed (inventory)

**Modified (1):**
- `scripts/tests/test-customization-preserve.sh` (+162 lines: new Group 8 driver for directory-based fixtures; existing Groups 1-7 byte-identical).

**New (78 fixture files + 1 README + 5 manifests + 5 assertions = 89 files):**

Top-level fixture README:
- `scripts/tests/fixtures/customization-preserve/README.md`

Per-fixture (`scripts/tests/fixtures/customization-preserve/<name>/`):

| Fixture | manifest.tsv rows | base/ files | ours/ files | theirs/ files | assertions.tsv rows |
|---|---|---|---|---|---|
| `lightly-customized-minimal/` | 5 | 4 | 5 | 4 | 1 |
| `heavily-customized/` | 11 | 6 | 11 | 6 | 9 |
| `language-heterogeneous/` | 6 | 4 | 6 | 5 | 5 |
| `custom-agents-heavy/` | 9 | 3 | 9 | 3 | 1 |
| `v10-with-customization/` | 5 | 3 | 5 | 3 | 7 |

Total fixture artifacts on disk: 91 (`find … -type f`).

## Per-fixture customization shape decisions

1. **`lightly-customized-minimal/`** — happy path. Trinity untouched (`unchanged-pack` x3), one project-only `x-` agent (`project-only-file`), one structured-config merge where both sides added separate allow-list entries (`merged-with-customization` via `merge-json.py`). Smallest fixture; proves the algorithm doesn't over-react when the project barely customizes.
2. **`heavily-customized/`** — worst-case. Trinity all 3 with project + pack edits → 3x `customization-detected-needs-reconciliation` with sidecars. Custom agents in all 3 CLI dirs + 1 `x-` script. Pack script `bootstrap.sh` with both edits → sidecar. JSON + TOML structured configs with merges. PM-CHAT.md with both edits → sidecar. Stresses every strategy code path.
3. **`language-heterogeneous/`** — multi-language project. `.gemini/.env` exercises the `_cp_strategy_gemini_env` key-union merge (project AGENT_CAPABILITIES with three languages wins; pack-new key adopted). Pack scripts: 2 `pack-update-applied`, 1 `merged-with-customization`, 1 `customization-detected-needs-reconciliation`. Plus 1 `x-grpc-coder` custom agent.
4. **`custom-agents-heavy/`** — focuses on the agent surface. 6 `x-` custom agents (2 per CLI), plus 3 pack agents driven through the 3 distinct dispositions: pack-edited+project-edited (sidecar), pack-edited only (copy), project-edited only (preserve). Validates that `custom-agent` vs `pack-agent` classification + their separate strategies work for all three CLIs.
5. **`v10-with-customization/`** — OT-modeled. Mirrors the inline Group 3 (XCODE_SCHEME + permissions JSON merge), Group 4 (ollama removal + lmstudio addition TOML merge), Group 5 (gemini-env key-union), trinity sidecar, and `x-ot-reviewer` custom agent — but as a directory-based fixture to give the OT shape parity with the other four.

**BD-088 OT preservation decision:** kept the inline TSV cases in Groups 1-7 byte-identical AND added the directory-based equivalent under `v10-with-customization/`. This is supplemental (not converted), so no coverage regression risk and the algorithmic unit-test surface in Groups 1-7 is preserved.

## Test runner extension approach

Extended the existing `scripts/tests/test-customization-preserve.sh` rather than creating a new runner. Rationale:
- The runner already sources the SUT libraries, defines `assert_eq` / `assert_contains` / `tsv_col` helpers, and integrates with CI (`.github/workflows/validate.yml` line 127-129).
- A second runner would duplicate setup boilerplate and require a parallel CI registration.
- Extension is a self-contained Group 8 that walks `FIXTURES_DIR` data-driven; new fixtures can be added without touching code.

The Group 8 driver:
1. Stages each fixture's `ours/` tree under a temp project root (mirrors how a real migration sees pre-update state).
2. Walks `manifest.tsv`, calling `customization_preserve` for each row with the manifest-pinned class.
3. Asserts the recorded disposition + class match expected (per-row).
4. Walks optional `assertions.tsv`, checking `dest`/`sidecar` file content for required substrings.
5. Renders the truthful report and asserts every manifest rel appears in it (BD-059 truthfulness contract).

Driver uses BSD `cp -R src/. dest/` (verified to copy hidden directories on Darwin) and bash 3.2-only constructs.

## Verification gate evidence

```
$ bash scripts/tests/test-customization-preserve.sh
=== Group 1: customization_classify ===
=== Group 2: text-strategy 4-case ===
=== Group 3: structured config (JSON) ===
=== Group 4: structured config (TOML) ===
=== Group 5: gemini-env preservation ===
=== Group 6: custom-agent / custom-script preservation ===
=== Group 6b: init guard for _CP_PACK_ROOT (B1) ===
=== Group 6c: BD-112 collision-safe flat naming ===
=== Group 7: truthful report ===
=== Group 8: BD-096 directory-based fixtures ===
=== Summary ===
Passed: 210
Failed: 0
All tests passed.
```

Baseline before changes: `Passed: 79 / Failed: 0`. New: `Passed: 210 / Failed: 0` (+131 tests; all green; all 5 fixtures fully exercised).

```
$ python3 scripts/validate-pack.py
… (Checks 1-31 plus 4 informational) …
PASSED — all checks clean
```

Same status as baseline (`91e7563` HEAD). No new checks added; no existing check regressed.

```
$ bash --version
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)
```

Confirmed compatibility with macOS bash 3.2 + BSD utils target.

## Plan deviations

None. BD-096 spec called for 5 fixtures + README + runner exercising all 5 end-to-end; that is what shipped.

## New POQs introduced

None.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| 5 fixture directories under `scripts/tests/fixtures/customization-preserve/` | PASS |
| Each fixture has realistic content (not empty placeholders) | PASS |
| `bash scripts/tests/test-customization-preserve.sh` PASSES end-to-end with all 5 fixtures exercised | PASS (210/210) |
| `python3 scripts/validate-pack.py` PASSES (all checks clean; no new checks) | PASS |
| Each fixture's customization shape documented (in fixture README) | PASS (`scripts/tests/fixtures/customization-preserve/README.md`) |
| Trinity rule N/A (no trinity files modified) | PASS (only test runner + fixtures touched) |
| Fixtures deterministic (no timestamps, no machine paths) | PASS |
| BD-088 OT-modeled fixture preserved (inline + directory equivalent) | PASS (Groups 1-7 byte-identical; `v10-with-customization/` added supplementally) |
| Phase-task fixtures NOT included (deferred to BD-106 in Batch 17) | PASS (none added) |
| No PM-only files modified (BACKLOG/CHANGELOG/README/PACK-CHAT/PACK-AGENTS/CLAUDE/AGENTS/GEMINI/EXECUTION-PLAN/RELEASE-GATE) | PASS |
| Agent did not commit (no `git add`/`commit`/`push`/`tag`) | PASS (HEAD unchanged at `91e7563`) |
| BD-096 status flip in BACKLOG.md left for Pack Chat | PASS (BACKLOG.md untouched per agent constraints) |

## Notes for Pack Chat

- BD-096 is ready for status flip (`Status: Open` → `Status: Resolved`, `Resolved: 2026-05-14, v11.0 — …`). Agents-never-commit rule + don't-touch-PM-only-files rule both prevent the agent from doing this.
- Files to stage: `scripts/tests/test-customization-preserve.sh` (modified) + `scripts/tests/fixtures/customization-preserve/` (89 new files). Confirmed via `git status`.
- CI will pick this up automatically: workflow already runs `bash scripts/tests/test-customization-preserve.sh`.
