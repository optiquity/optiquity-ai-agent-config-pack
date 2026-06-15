# IMPL-REPORT — BD-219 C4 (project-only)

**Coder:** pack-coder (fresh instance, C4 only)
**Date:** 2026-06-15
**Branch:** v11-dev
**HEAD SHA:** 26a0179ecc8e00761c53c80e0f60bf0752a58b48
**Regime:** IN-PLACE (no worktree isolation for C4 — disjoint files; consistent with the plan §4 safe-parallel note)

---

## 1. Task summary

C4 adds ONE new `##` section ("CI test parallelization (GitHub Actions matrix)") to
`project-template/docs/pack/OPTIONAL-FEATURES.md`. The section is written in
PROJECT-NATIVE vocabulary with ZERO pack-self tokens — it is generic GitHub Actions
advice for a CLIENT project whose CI runs a multi-suite test battery sequentially.

---

## 2. Added section (verbatim)

```
## CI test parallelization (GitHub Actions matrix)

**Status:** Standard GitHub Actions — available on all plan tiers (Free,
Team, Enterprise), all account types (personal and organization), and all
runner types (`ubuntu-latest` and self-hosted alike). Platform-agnostic —
works with any test framework and any language.

**What it is.** When your project's CI runs many independent test suites
sequentially in a single job, wall-clock time accumulates linearly with
the number of suites. GitHub Actions `strategy: matrix` distributes a set
of test scripts (or other tasks) across parallel runners, so total
wall-clock time drops from Σ(all suites) to max(slowest suite) — without
dropping any test or weakening any assertion. Combined with `fail-fast:
false`, every suite runs in every push even when an earlier one fails,
preserving full failure visibility. An aggregation job (`if: always()` +
an explicit success assertion on the matrix result) serves as the single
stable required status check regardless of shard count.

**When this matters for your project.** This is worth doing when: (a) your
CI has multiple independent test suites running in one job, (b) total
wall-clock time is causing friction (slow feedback, queue pile-ups), and
(c) the test suites can each run independently on a clean runner (no
hard inter-suite ordering dependency). A single-suite project or a project
whose CI already completes quickly does not benefit.

**How to enable.** No external service or paid feature is required — this
is a standard GitHub Actions workflow pattern. Add three jobs to your
workflow:

1. **`plan` job** — an upstream job that computes the test partition and
   writes it to `$GITHUB_OUTPUT` as JSON:
   ```yaml
   plan:
     runs-on: ubuntu-latest
     outputs:
       matrix: ${{ steps.plan.outputs.matrix }}
     steps:
       - uses: actions/checkout@v4
       - id: plan
         run: echo "matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}" >> "$GITHUB_OUTPUT"
   ```
   Replace the static `include` list with a dynamic generator script if
   your suite list grows or changes.

2. **`tests` job** — a matrix job that consumes the partition:
   ```yaml
   tests:
     needs: [plan]
     runs-on: ubuntu-latest
     strategy:
       fail-fast: false   # surface ALL failures, not just the first
       matrix: ${{ fromJSON(needs.plan.outputs.matrix) }}
     steps:
       - uses: actions/checkout@v4
       - name: run suite ${{ matrix.suite }}
         run: bash scripts/test-${{ matrix.suite }}.sh
   ```

3. **`tests-result` aggregation job** — the single required status check:
   ```yaml
   tests-result:
     needs: [plan, tests]
     if: always()
     runs-on: ubuntu-latest
     steps:
       - name: assert all suites passed
         run: |
           echo "tests result = ${{ needs.tests.result }}"
           test "${{ needs.tests.result }}" = "success"
   ```

**Required-status-check rename consideration.** If your branch protection
requires a check named `tests`, converting `tests` to a matrix renames
the check to `tests (suite-name)` per combination — the old `tests` check
disappears. Before merging the matrix change, update your branch
protection rule to require `tests-result` (the aggregation job) instead of
`tests`. This is a one-time admin step; `tests-result` then remains stable
regardless of how many suites you add or remove.

**No pack-specific setup needed.** Your project's existing test scripts
(`scripts/test.sh`, `scripts/test-swift.sh`, `scripts/test-python.sh`,
etc.) run inside the matrix exactly as they would in any shell step — no
changes to the scripts themselves. The matrix controls orchestration; the
scripts remain standalone and human-runnable locally without change.

**Caveats.**
- **Suite independence is required.** Each matrix combination runs on a
  fresh runner with a clean checkout. Suites that depend on shared mutable
  state (a running database, a network service, a shared file) need that
  state to be self-provisioned per runner (Docker service containers, or
  a setup step that creates the fixture from scratch).
- **Fixture build cost is paid per shard.** If a suite requires a
  build artifact (compiled binaries, generated files, test fixtures),
  each runner that needs it builds it independently unless you use GitHub
  Actions artifact upload/download between jobs. For short builds the
  overhead is acceptable; for long builds consider caching or a
  pre-build job.
- **Slow single test within a suite sets the floor.** Parallelizing
  suites helps only at the suite level. If one suite contains a single
  test that takes 90 s, that suite cannot finish faster than 90 s
  regardless of how many shards you add. Split long-running individual
  tests into separate suites to lower the floor.
- **`fail-fast: false` is required.** The default (`fail-fast: true`)
  cancels sibling matrix combinations when one fails — you lose failure
  visibility across suites. Always set `fail-fast: false` for test
  matrices.

**When to skip.** CI already fast or single-suite; test suites have
hard inter-suite ordering dependencies; project does not use GitHub
Actions.
```

---

## 3. Boundary-compliance attestation (no pack-self tokens)

Grep command and result:

```
$ grep -n "BD-\|validate-pack\|pack-ops\|maintenance-docs\|pack-coder\|pack-architect\|pack-reviewer\|pack-planner\|Pack Chat\|PACK-AGENTS\|PACK-CHAT\|ci-shard-plan\|pack-only\|pack-chat-only" project-template/docs/pack/OPTIONAL-FEATURES.md
(no output)
```

Exit: 0 hits. ZERO pack-self tokens in the entire file (including the new section).

The new section speaks exclusively in client vocabulary:
- "your project's CI", "your workflow", "your branch protection"
- "GitHub Actions `strategy: matrix`", `fail-fast: false`, `$GITHUB_OUTPUT`
- References to the project's own scripts: `scripts/test.sh`, `scripts/test-swift.sh`, `scripts/test-python.sh`

No BD-NNN, no `validate-pack.py`, no `pack-ops/`, no `maintenance-docs/`, no `pack-*` agent names, no reference to the pack's own `tests` job or internal sharding work.

---

## 4. Manifest result

`project-template/` is a v11-surface directory. `bash test-fixtures/build.sh --all --clean` was run.

```
$ git status --short test-fixtures/manifest.txt
 M test-fixtures/manifest.txt
```

The manifest diff is NON-EMPTY. The v11 fixtures (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`) incorporate the current HEAD tree (which includes `project-template/` content), so the fixture SHAs changed when OPTIONAL-FEATURES.md changed. This is expected behavior per `build.sh`'s fixture-from-HEAD construction.

Per plan §C4: "the C0 Check-36 carve-out `_SCOPE_NEUTRAL_GENERATED_PATHS` permits the pack-side `test-fixtures/manifest.txt` in a `project-only` commit." Confirmed in `scripts/validate-pack.py`:

```python
_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({
    "test-fixtures/manifest.txt",
})
```

The manifest MUST be staged in the same commit. It is NOT a boundary violation — `_SCOPE_NEUTRAL_GENERATED_PATHS` is specifically designed to permit it in a `project-only` commit.

---

## 5. Verification results

### 5.1 General validate-pack.py

```
$ python3 scripts/validate-pack.py
...
PASSED — all checks clean
```

Exit code: 0. All 60 checks passed including:
- Check 43 (project-side leak scanner) — no pack-self leak in OPTIONAL-FEATURES.md
- Check 54 (OPTIONAL-FEATURES presence-check) — all 3 mandated tokens still present
- Check 58 (validate job no `--only-check`) — pass
- Check 59 (CHECK_REGISTRY completeness 60 entries) — pass
- Check 60 (shard partition coverage) — pass

### 5.2 Deep validate-pack.py

```
$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py
...
PASSED — all checks clean
```

Exit code: 0.

### 5.3 OPTIONAL-FEATURES-specific tests

**test-validate-pack-check-54.sh** (Check 54 — OPTIONAL-FEATURES presence-check):
```
PASS: 3, FAIL: 0 — All tests passed.
```

**test-validate-pack-check-40.sh** (Check 40 — pack-ops bare cross-reference scanner):
```
PASS: 8, FAIL: 0 — All tests passed.
```

**test-validate-pack-check-39.sh** (Check 39 — cmd_update mapping symmetry):
```
PASS: 6, FAIL: 0 — All tests passed.
```

**test-validate-pack-check-43.sh** (Check 43 — project-side leak scanner):
```
PASS: 9, FAIL: 0 — All tests passed.
```

### 5.4 Final git status

```
$ git status --short
 M project-template/docs/pack/OPTIONAL-FEATURES.md
 M test-fixtures/manifest.txt
```

Only the two expected files modified. No other working-tree changes.

---

## 6. Files changed

| Path | Change type | Notes |
|---|---|---|
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | modified | Added `## CI test parallelization (GitHub Actions matrix)` section before `## Adding new entries`; +113 lines |
| `test-fixtures/manifest.txt` | modified | Fixture SHAs updated (v11 fixtures incorporate project-template/ — expected; staging required per `regenerate-manifest-v11-surface` + Check-36 carve-out) |

---

## 7. Placement decision

Section inserted after `## Tracker integration (deferred)` and immediately before `## Adding new entries`. Rationale: CI test parallelization is a general, platform-agnostic feature (not CLI-specific like the Claude Code / Codex / Gemini sections), so placing it near the end alongside the other general entry (Tracker) is the natural slot. It avoids cluttering the CLI-specific sections early in the file.

---

## 8. Plan deviations

None. The plan §C4 specified exactly:
- One new `##` section in `project-template/docs/pack/OPTIONAL-FEATURES.md`
- Project-native vocabulary, zero pack-self tokens
- Title: "CI test parallelization (GitHub Actions matrix)" — matched
- Run manifest regen, check the diff — done (non-empty, correctly staged with carve-out note)
- Run general + deep validate-pack — done, both exit 0
- Boundary-leak grep → zero hits — done

The only detail requiring judgment was the non-empty manifest: the plan said "almost certainly empty" but prepared for the non-empty case (with a STOP condition only if it would violate project-only keyword). Per the carve-out, staging it is CORRECT. No STOP issued.

---

## 9. New POQs

None introduced.

---

## 10. Definition-of-Done checklist

| Item | Status |
|---|---|
| One new `##` section added to `project-template/docs/pack/OPTIONAL-FEATURES.md` | PASS |
| Section follows file's existing convention (Status / What it is / When it matters / How to enable / [pack-pieces adapted] / Caveats / When to skip) | PASS |
| ZERO pack-self tokens (BD-, validate-pack, pack-ops, maintenance-docs, pack-* agent names, ci-shard-plan, etc.) | PASS — grep exits 0 |
| General validate-pack exit 0 | PASS |
| Deep validate-pack exit 0 | PASS |
| Check 54 test passes (OPTIONAL-FEATURES presence-check) | PASS (3/3) |
| Check 43 test passes (project-side leak scanner) | PASS (9/9) |
| Check 40 test passes | PASS (8/8) |
| Check 39 test passes | PASS (6/6) |
| Manifest regen run + result reported | PASS — non-empty, carve-out applies |
| `git status --short` shows ONLY OPTIONAL-FEATURES.md + manifest.txt | PASS |
| Trinity rule: OPTIONAL-FEATURES.md is NOT a trinity file; no parallel edit needed | PASS (confirmed) |
| Boundary discipline check: project-side SSOT investigated before writing | PASS — read file's existing entries + "Adding new entries" convention in full |
| No state-changing git verb run | PASS |

---

## 11. Boundary discipline check

Per the P-missed-7 pre-flight requirement:

**File edited:** `project-template/docs/pack/OPTIONAL-FEATURES.md`

**Project-side SSOT investigated:** The file itself is the project-side SSOT for optional feature documentation. I read it IN FULL before editing. I also investigated:
- `project-template/CLAUDE.md` — confirms OPTIONAL-FEATURES.md is a project-side docs/pack/ file
- Architecture §7 — confirmed the project-side convention (what vocab to use, what to exclude)
- The file's "Adding new entries" section (line 308) — the explicit convention for new entries

**Concept being changed:** Adding documentation about GitHub Actions `strategy: matrix` for client CI parallelization.

**Pack-self references investigated and EXCLUDED:** No `BD-NNN`, `validate-pack.py`, `pack-ops/`, `maintenance-docs/`, `pack-*` agent names, `ci-shard-plan.py`, `pack-only`, references to the pack's own `tests` job. All excluded by construction (the section was authored from scratch in client vocabulary).

**Conclusion:** No SSOT violation. The entry is genuinely project-native with no pack-self leakage.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **boundary-investigation / P-missed-7** | Read OPTIONAL-FEATURES.md IN FULL before editing. Section 11 (Boundary discipline check) above. Grep proof: `grep -n "BD-\|validate-pack\|pack-ops\|maintenance-docs\|pack-coder..." project-template/docs/pack/OPTIONAL-FEATURES.md` → 0 hits. Content uses exclusively client vocabulary ("your project's CI", "your workflow", "your branch protection"). | COMPLIANT |
| **pack-project-separation-of-concerns** | The new section is a project-side client deliverable written for client developers. No pack-side vocabulary. The section was authored independently for the client audience — it does not copy from any pack-side artifact. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Used a targeted `Edit` call inserting exactly one new `##` section before `## Adding new entries`. The existing 316-line file was not rewritten; only the new block was added. Post-edit the file is 430 lines (new section = +114 lines from the `---` separator to the closing `---`). | COMPLIANT |
| **regenerate-manifest-v11-surface** | `bash test-fixtures/build.sh --all --clean` run; `git status --short test-fixtures/manifest.txt` → ` M` (non-empty). Manifest must be staged in same commit. Check-36 carve-out `_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({"test-fixtures/manifest.txt"})` confirmed in scripts/validate-pack.py line 4149–4151 — project-only commit with manifest is CI-legal. | COMPLIANT |
| **commit-subject-keyword-token-trap** | For Pack Chat's commit: the subject will carry `project-only` and must NOT contain `pack-only` or `pack-chat-only` tokens. My edits touch ONLY `project-template/docs/pack/OPTIONAL-FEATURES.md` + `test-fixtures/manifest.txt` (carve-out path) — both compatible with the `project-only` keyword claim. | COMPLIANT (scope correct; Pack Chat applies the subject) |
| **verify-full-ci-suite** | General validate-pack: exit 0, all 60 checks pass. Deep validate-pack: exit 0. OPTIONAL-FEATURES-asserting tests: check-54 (3/3 PASS), check-43 (9/9 PASS), check-40 (8/8 PASS), check-39 (6/6 PASS). git status confirmed only expected files modified. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Exactly one `##` section added; nothing else changed. No invented new files, no unrelated edits, no other OPTIONAL-FEATURES content touched. | COMPLIANT |
| **agents-never-commit** | No state-changing git verb run. Commands used: `git rev-parse HEAD` (read-only), `git status --short` (read-only), `git diff` (read-only). Build.sh was run to generate the manifest (it is a build script, not a git verb). | COMPLIANT |
| **preflight-stop-means-stop** | PREFLIGHT line emitted above after all edits + verification passed. No stop/halt message received. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT conclusion; no empty evidence; no AMBIGUOUS terminal state. | COMPLIANT |
