# IMPL-REPORT — BD-197 C0: Check 36 manifest carve-out

**Agent:** pack-coder
**Task:** BD-197 commit C0 — the Check 36 scope-neutral generated-artifact
carve-out (`pack-only` change).
**Branch:** `v11-dev`
**Base HEAD SHA (pre-work + post-work; agent never commits):**
`3250887cdd08587443f33d06bcb3613404e393f5`
**Date:** 2026-06-13
**Spec followed:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md`
§17 (§17.1–§17.8).

---

## 0. Read attestation (authority docs read IN FULL — no skim, no derivation)

I read each of the following directly and in full before coding. No content
was derived from secondary sources.

| Doc | What I extracted |
|---|---|
| `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` §17.1–§17.8 (lines 617–877) | The exact carve-out spec: the conflict (EB-1), MEASURE 1/2 (the forced-co-variant set is EXACTLY `{test-fixtures/manifest.txt}`, EB-2/3/4), the constant `_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({"test-fixtures/manifest.txt"})`, the predicate `_is_scope_neutral_generated`, the two offender-branch edits (`and not _is_scope_neutral_generated(p)` on `pack_only` + `project_only`, `pack_chat_only` UNCHANGED), the not-weakened proof (EB-5), the test-case spec NC-1..NC-6, the runtime note (O(1) set-membership), the "set-membership not a `test-fixtures/` prefix" rationale. |
| Current Check 36 + helpers in `scripts/validate-pack.py` | `check_commit_scope_honesty()` (was ~4264–4349; the two offender branches `is_pack_only`/`is_project_only`); `_is_project_side_path` (was ~4250–4253); `_is_pack_only_path`/`_is_pack_chat_only_permitted`; constants block ~4072–4126 incl. `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`. |
| Current test `scripts/tests/test-validate-pack-checks-36-37-38.sh` (full, all 7 groups) | Group-0 `required` symbol list; Group-1 unquoted `<<EOF` heredoc (note: NO backticks in body — shell-expanded); the `assert_match`/`assert_pm`/`assert_pside` patterns; Groups 2–7. |
| `CLAUDE.md` `## Pack memory` (full, via session context) | All workflow / agent-invocation / repo-convention rules; the specific rules in force for this spawn. |
| `feedback_ci_guard_design_measure_then_bound.md` | measure-then-bound 5-step contract; size allowlist to KEEP only. |
| `feedback_ci_check_runtime_compounding.md` | cost = per-run × battery-invocation-count; O(1), no subprocess-per-entry. |
| `feedback_verify_full_ci_suite.md` | run EVERY script wired in validate-pack.yml (both jobs), quote each exit; no sampling. |
| `feedback_manifest_regen_on_v11_surface.md` | v11-surface commits regenerate manifest; stage only if non-empty. |
| `feedback_edit_in_place_not_full_rewrite.md` | targeted in-place edits; re-read after; no wholesale rewrite. |

---

## 1. Files changed (inventory)

| Path | Change type | Line delta |
|---|---|---|
| `scripts/validate-pack.py` | modified | +35 / −2 |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | modified | +89 / −0 |

`git diff --stat`:
```
 .../tests/test-validate-pack-checks-36-37-38.sh    | 89 ++++++++++++++++++++++
 scripts/validate-pack.py                           | 35 ++++++++-
 2 files changed, 122 insertions(+), 2 deletions(-)
```

No other file is modified. `test-fixtures/manifest.txt` was rebuilt (build
exit 0) and is **byte-identical** to HEAD (empty diff) — left unstaged and
clean. No new files. No deletions. No git state changes (agent never commits).

---

## 2. The conflict was verified real BEFORE the edit (EB-1 reproduced)

Command (against the pristine module at HEAD `3250887c`):
```
python3 -c "...import vp...; print(vp._is_project_side_path('test-fixtures/manifest.txt'));
            print([p for p in ['project-template/docs/pack/PM-CHAT.md','test-fixtures/manifest.txt']
                   if not vp._is_project_side_path(p)])"
```
Verbatim output:
```
_PROJECT_SIDE_PATH_PREFIXES = ('project-template/', 'supporting-docs/')
_is_project_side_path(test-fixtures/manifest.txt) = False
PRE-PATCH project_only offenders for [project content + manifest] = ['test-fixtures/manifest.txt']
has _is_scope_neutral_generated already? False
has _SCOPE_NEUTRAL_GENERATED_PATHS already? False
```
Interpretation: pre-patch, a `project-only` commit staging the
forced-co-variant manifest flags it as an offender → Check 36 FAILS. The
constant/predicate did not exist. **SUPPORTED** — conflict real.

---

## 3. The edits (before/after snippets)

### 3.1 `scripts/validate-pack.py` — new constant (beside `_PROJECT_SIDE_PATH_PREFIXES`)

Inserted immediately after `_PROJECT_SIDE_PATH_PREFIXES`:
```python
# Scope-neutral generated artifact(s): auto-generated files that the
# `regenerate-manifest-v11-surface` rule FORCES to co-vary with a v11-surface
# edit on EITHER surface. They carry no surface-specific semantic content, so
# they are permitted in BOTH `project-only` and `pack-only` commits without
# counting as an offender. Sized EXACTLY to the measured forced-co-variant set
# (ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §17.3): manifest only.
# A hand-edited manifest is independently caught by `build.sh --verify`, so
# admitting it here does NOT let content smuggle past the boundary.
_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({
    "test-fixtures/manifest.txt",
})
```

### 3.2 `scripts/validate-pack.py` — new predicate (beside `_is_project_side_path`)

Inserted immediately after `_is_project_side_path`:
```python
def _is_scope_neutral_generated(path: str) -> bool:
    """True if `path` is an auto-generated, scope-neutral artifact that the
    regenerate-manifest rule forces to co-vary with v11-surface edits on
    EITHER surface (ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §17).
    Such paths are not offenders in either `project-only` or `pack-only`
    commits. Exact-string set-membership — NOT a `test-fixtures/` prefix, so
    the static `v11-trinity-marker-prepped/` snapshot + the `build.sh`/README
    recipe (real pack-side content) still count toward scope."""
    return path in _SCOPE_NEUTRAL_GENERATED_PATHS
```

### 3.3 `scripts/validate-pack.py` — the two offender branches (in `check_commit_scope_honesty`)

**`is_pack_only` branch — before:**
```python
        if is_pack_only:
            offenders = [p for p in paths if _is_project_side_path(p)]
            if offenders:
```
**after:**
```python
        if is_pack_only:
            offenders = [
                p for p in paths
                if _is_project_side_path(p)
                and not _is_scope_neutral_generated(p)
            ]
            if offenders:
```

**`is_project_only` branch — before:**
```python
        if is_project_only:
            offenders = [p for p in paths if not _is_project_side_path(p)]
            if offenders:
```
**after:**
```python
        if is_project_only:
            offenders = [
                p for p in paths
                if not _is_project_side_path(p)
                and not _is_scope_neutral_generated(p)
            ]
            if offenders:
```

**`is_pack_chat_only` branch — UNCHANGED** (verified by re-read; still
`offenders = [p for p in paths if not _is_pack_chat_only_permitted(p)]`).
Out of scope per §17.4 + scope-deliverables-to-the-ask.

### 3.4 `scripts/tests/test-validate-pack-checks-36-37-38.sh` — Group-0 registration

**before:**
```
    '_is_project_side_path',
    '_is_pack_chat_only_permitted',
```
**after:**
```
    '_is_project_side_path',
    '_is_scope_neutral_generated',
    '_is_pack_chat_only_permitted',
```

### 3.5 `scripts/tests/test-validate-pack-checks-36-37-38.sh` — Group-1 NC cases

Inserted after the `assert_pside(...)` block (after `T11d`), before the
`if failures:` close of the Group-1 Python heredoc. The cases: NC-1..NC-3
(predicate exactness), NC-4 (`project-only` project+manifest PASSES), NC-5
(`pack-only` pack+manifest PASSES), NC-6 (real cross-surface offender STILL
FAILS), plus NC-7 (offender-level not-weakened control: the static
`v11-trinity-marker-prepped/` snapshot is NOT carved). NC-7 surfaces §17.5(a)'s
symmetric not-weakened claim at the offender level (NC-3 covers it only at the
predicate level) — see "Plan deviations" §9 for the disposition.

```python
# Predicate-level controls (NC-1..NC-3): exact-string membership only.
def assert_neutral(path, expected, label):
    actual = mod._is_scope_neutral_generated(path)
    if actual != expected:
        failures.append(f"{label}: path={path!r} expected_neutral={expected} actual={actual}")

# NC-1: predicate admits the manifest.
assert_neutral("test-fixtures/manifest.txt", True, "NC-1")
# NC-2: predicate rejects a non-carved pack path.
assert_neutral("scripts/validate-pack.py", False, "NC-2")
# NC-3: predicate rejects sibling test-fixtures paths (no prefix widening) --
#   proves the carve-out is exact-string, NOT a test-fixtures/ prefix that
#   would wrongly exempt the static snapshot + the build.sh/README recipe.
assert_neutral("test-fixtures/v11-trinity-marker-prepped/CLAUDE.md", False, "NC-3a")
assert_neutral("test-fixtures/build.sh", False, "NC-3b")

# Offender-level controls (NC-4..NC-7): reproduce the two patched offender
# comprehensions exactly as they appear in check_commit_scope_honesty().
def project_only_offenders(paths):
    return [
        p for p in paths
        if not mod._is_project_side_path(p)
        and not mod._is_scope_neutral_generated(p)
    ]

def pack_only_offenders(paths):
    return [
        p for p in paths
        if mod._is_project_side_path(p)
        and not mod._is_scope_neutral_generated(p)
    ]

# NC-4: a project-only commit = project content + manifest PASSES (empty).
nc4 = project_only_offenders(
    ["project-template/docs/pack/PM-CHAT.md", "test-fixtures/manifest.txt"]
)
if nc4 != []:
    failures.append(f"NC-4: project-only [project content + manifest] expected [] got {nc4}")

# NC-5: a pack-only commit = pack content + manifest PASSES (empty).
nc5 = pack_only_offenders(
    ["pack-ops/PACK-CHAT.md", "test-fixtures/manifest.txt"]
)
if nc5 != []:
    failures.append(f"NC-5: pack-only [pack content + manifest] expected [] got {nc5}")

# NC-6: a REAL cross-surface offender STILL FAILS -- the guard is NOT
#   weakened. ... only the manifest is carved.
nc6 = project_only_offenders(
    ["project-template/docs/pack/PM-CHAT.md", "scripts/validate-pack.py",
     "test-fixtures/manifest.txt"]
)
if nc6 != ["scripts/validate-pack.py"]:
    failures.append(...)

# NC-7 (not-weakened, exactness): the static snapshot is NOT carved -- a
#   project-only commit touching it STILL FAILS ...
nc7 = project_only_offenders(
    ["project-template/docs/pack/PM-CHAT.md",
     "test-fixtures/v11-trinity-marker-prepped/CLAUDE.md",
     "test-fixtures/manifest.txt"]
)
if nc7 != ["test-fixtures/v11-trinity-marker-prepped/CLAUDE.md"]:
    failures.append(...)
```

**Note on backticks:** the Group-1 heredoc is unquoted (`<<EOF`), so the shell
expands the body. My first draft used backticks in the comment lines; the shell
parsed them as command substitution (failed run). I removed ALL backticks from
my inserted block (matching the pre-existing convention in this heredoc, which
uses no backticks) and the test then passed. This is a fix to my own
in-progress edit, not a deviation from the spec.

---

## 4. Not-weakened proof — projected logic against the PATCHED module

Command (against the patched module at HEAD `3250887c`, 2026-06-13): import
`vp`, evaluate the predicate + reproduce both patched offender comprehensions.

Verbatim output:
```
=== constant + predicate present ===
_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({'test-fixtures/manifest.txt'})
has _is_scope_neutral_generated = True

=== NC-1..3 predicate exactness ===
NC-1 admits manifest        = True (expect True)
NC-2 rejects validate-pack  = False (expect False)
NC-3 rejects snapshot       = False (expect False)
NC-3 rejects build.sh       = False (expect False)

=== NC-4 project-only: project content + manifest PASSES ===
offenders = [] (expect [])

=== NC-5 pack-only: pack content + manifest PASSES ===
offenders = [] (expect [])

=== NC-6 real cross-surface offender STILL FAILS (project-only) ===
offenders = ['scripts/validate-pack.py'] (expect [scripts/validate-pack.py])

=== not-weakened: snapshot NOT carved (project-only commit touching snapshot still FAILS) ===
offenders = ['test-fixtures/v11-trinity-marker-prepped/CLAUDE.md'] (expect [...])

=== not-weakened: pack-only commit touching a real project file still FAILS ===
offenders = ['project-template/CLAUDE.md'] (expect [project-template/CLAUDE.md])
```
Interpretation: the carve-out admits EXACTLY `test-fixtures/manifest.txt`
(NC-1/4/5); every other cross-surface path is still an offender — real pack
source `scripts/validate-pack.py` (NC-6), the static snapshot
`v11-trinity-marker-prepped/CLAUDE.md`, the recipe `build.sh`, and a real
`project-template/` file in a `pack-only` commit. **SUPPORTED** — guard NOT
weakened; sized to the one measured generated path (measure-then-bound).

These same six controls are also asserted in the wired test
`scripts/tests/test-validate-pack-checks-36-37-38.sh` (NC-1..NC-7), which
passes (§6).

---

## 5. Manifest confirmation (regenerate-manifest-v11-surface; expected EMPTY)

C0 touches `scripts/` (v11-surface) → ran the manifest build per the rule.

Command + verbatim output:
```
cp test-fixtures/manifest.txt /tmp/manifest-before-c0.txt
bash test-fixtures/build.sh --all --clean        # BUILD_EXIT=0
diff /tmp/manifest-before-c0.txt test-fixtures/manifest.txt && echo MANIFEST_DIFF_EMPTY=yes
  → MANIFEST_DIFF_EMPTY=yes
git status --porcelain test-fixtures/manifest.txt
  → (empty)
git status --porcelain test-fixtures/ project-template/ pack-ops/ supporting-docs/
  → (empty)
```
Interpretation: editing `validate-pack.py` does not feed any client fixture, so
no v11 fixture's installed-HEAD SHA changed → the rebuilt manifest is
byte-identical. Per the rule, stage the manifest ONLY if the diff is non-empty;
the diff is EMPTY, so the manifest is NOT staged and C0 stays cleanly
`pack-only`. **SUPPORTED** (matches design EB-2's prediction). Final
`git diff --quiet test-fixtures/manifest.txt` → manifest clean vs HEAD.

---

## 6. Per-check test result (the wired Check 36/37/38 test)

`bash scripts/tests/test-validate-pack-checks-36-37-38.sh` → **EXIT=0**.
Summary line: `PASS: 8  FAIL: 0  — All tests passed.` Group 0 (now asserts
`_is_scope_neutral_generated` present) PASS; Group 1 (now includes NC-1..NC-7)
PASS; Groups 2–7 PASS.

Note: pre-existing cosmetic shell-noise lines (`pack-ops/BACKLOG.md: No such
file or directory`, `backlog/: is a directory`, etc.) appear during Group 1.
These pre-date my change — confirmed by running the pristine committed test
(`git show HEAD:...`) which emits the same noise at its line 74. They originate
from the long-standing unquoted-heredoc expansion of the pre-existing
`assert_pm("pack-ops/BACKLOG.md",...)` / `assert_pm("backlog/...",...)` path
strings. My change adds NO new noise (I used no backticks/expansions). The test
exits 0 in both states.

---

## 7. Runtime (ci-check-runtime-compounding)

The carve-out adds ONE `frozenset` membership test per offender candidate
inside the already-materialized comprehension — O(1) per path, no new
subprocess, no per-entry storm, no whole-tree scan. Check 36 still walks only
the commits in its range (default = HEAD).

Measured Check-36 wall-time (isolated, against the patched module):
```
Check 36 wall-time: 0.0178 s
Check 36 output:   OK: Check 36 — 1 scope-claiming commit(s) verified clean; 0 implicit-scope commit(s) skipped
```
Against the 186-invocation battery (the design's figure; the workflow wires
2 validate-job invocations + the per-check/integration suite's repeated
`validate-pack.py` calls), the added per-path cost is negligible and does NOT
compound. **SUPPORTED** — O(1), no subprocess.

---

## 8. FULL CI SUITE — every wired script, exit status (no sampling)

I enumerated every `run:` command in `.github/workflows/validate-pack.yml`
(60 commands total: 2 validate-job + 58 tests-job) and ran each. Every one
returned EXIT=0.

### validate job (×2)
| # | Command | Exit |
|---|---|---|
| 1 | `python3 scripts/validate-pack.py` | **0** (`PASSED — all checks clean`) |
| 2 | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** (`PASSED — all checks clean`) |

### tests job — part 1 (detect + tracker + schema + per-entry)
| Script | Exit |
|---|---|
| `scripts/test-detect.sh` | 0 |
| `scripts/tests/tracker-provider-test.sh` | 0 |
| `scripts/tests/tracker-config-test.sh` | 0 |
| `scripts/tests/tracker-init-test.sh` | 0 |
| `scripts/tests/tracker-agent-read-test.sh` | 0 |
| `scripts/tests/tracker-migrate-forward-test.sh` | 0 |
| `scripts/tests/tracker-migrate-reverse-test.sh` | 0 |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | 0 |
| `scripts/tests/test-tracker-phase-task.sh` | 0 |
| `scripts/tests/test-tracker-links.sh` | 0 |
| `scripts/tests/test-tracker-cycle-check.sh` | 0 |
| `scripts/tests/tracker-errors-test.sh` | 0 |
| `scripts/tests/tracker-config-schema-test.sh` | 0 |
| `scripts/tests/recommendation-state-schema-test.sh` | 0 |
| `scripts/tests/test-per-entry.sh` | 0 |

### tests job — part 2 (validate-pack per-check tests)
| Script | Exit |
|---|---|
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | 0 |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | 0 (the changed test) |
| `scripts/tests/test-validate-pack-check-39.sh` | 0 |
| `scripts/tests/test-validate-pack-check-40.sh` | 0 |
| `scripts/tests/test-validate-pack-check-41.sh` | 0 |
| `scripts/tests/test-validate-pack-check-18.sh` | 0 |
| `scripts/tests/test-validate-pack-check-16.sh` | 0 |
| `scripts/tests/test-validate-pack-check-19.sh` | 0 |
| `scripts/tests/test-validate-pack-check-42.sh` | 0 |
| `scripts/tests/test-validate-pack-check-43.sh` | 0 |
| `scripts/tests/test-validate-pack-check-44.sh` | 0 |
| `scripts/tests/test-validate-pack-check-45.sh` | 0 |
| `scripts/tests/test-validate-pack-check-46.sh` | 0 |
| `scripts/tests/test-validate-pack-check-removed-doc-advisory.sh` | 0 |
| `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` | 0 |
| `scripts/tests/test-validate-pack-check-50-codec-single-source.sh` | 0 |
| `scripts/tests/test-validate-pack-check-51-flip-block.sh` | 0 |

### tests job — part 3 (deferral-gate + BD-12x/13x + recommendation/help/init/migrate/migrator)
| Script | Exit |
|---|---|
| `scripts/tests/tracker-deferral-gate-test.sh` | 0 |
| `scripts/tests/tracker-bd129-gh-repo-test.sh` | 0 |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | 0 |
| `scripts/tests/tracker-bd132-race-test.sh` | 0 |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | 0 |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | 0 |
| `scripts/tests/recommendation-test.sh` | 0 |
| `scripts/tests/pack-help-test.sh` | 0 |
| `scripts/tests/test-customization-preserve.sh` | 0 |
| `scripts/tests/test-init-project.sh` | 0 |
| `scripts/tests/test-migrate-v10-to-v11.sh` | 0 |
| `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 0 |
| `scripts/tests/test-migrate-v10-to-v11-gates.sh` | 0 (re-confirmed standalone, also 0) |
| `scripts/tests/test-migrate-v10-to-v11-decompose.sh` | 0 (re-confirmed standalone, also 0) |
| `scripts/test-migrator-core.sh` | 0 (re-confirmed standalone, also 0) |
| `scripts/test-migrator-manifest.sh` | 0 (re-confirmed standalone, also 0) |
| `scripts/test-migrator-capability-translation.sh` | 0 (re-confirmed standalone, also 0) |

### tests job — part 4 (fixtures + manifest verify + integration + persona + template + issue-forms)
| Step | Exit |
|---|---|
| `bash test-fixtures/build.sh --all --clean` | 0 |
| `git checkout HEAD -- test-fixtures/manifest.txt` (CI restore; read-only path-restore) | 0 |
| `bash test-fixtures/build.sh --verify` | 0 |
| `scripts/tests/test-v11-realistic-ot.sh` | 0 |
| `scripts/test-migrator-skills.sh` | 0 |
| `scripts/test-persona-contracts.sh` | 0 |
| `scripts/tests/template-translations-test.sh` | 0 |
| `scripts/tests/template-version-test.sh` | 0 |
| `scripts/tests/test-issue-forms.sh` | 0 |

**Result: 60/60 wired commands EXIT=0. Full CI battery GREEN — no sampling.**

Note on the `git checkout HEAD -- test-fixtures/manifest.txt` step: this is the
CI workflow's own step #53 (restore committed manifest before verify), a
read-only `git checkout -- <path>` form (no branch state mutated) that I ran to
faithfully reproduce the CI `tests` job ordering. It restored the manifest to
its committed bytes (which were already byte-identical post-build per §5), so
the working tree remains: only my two source edits modified, manifest clean.

---

## 9. Plan deviations

| # | Deviation | Disposition |
|---|---|---|
| D1 | Added an extra offender-level test case **NC-7** (static snapshot in a `project-only` commit still FAILS) beyond the spec's NC-1..NC-6. | ADDITIVE only. §17.5(a) makes the symmetric not-weakened claim ("a genuinely cross-surface commit still FAILS" / "the static snapshot is REAL content that SHOULD count toward scope"); the spec's NC-3 proves this at the PREDICATE level only. NC-7 asserts it at the OFFENDER level (the level the guard actually runs at), strengthening enumerate-encoding-surfaces coverage without altering any spec'd case. No spec'd case removed/weakened. Not a re-design; surfaced here per scope-deliverables-to-the-ask. |

No other deviations. The constant, predicate, both offender-branch edits, the
unchanged `pack_chat_only` branch, the Group-0 registration, and NC-1..NC-6 are
implemented exactly as §17.4/§17.6 specify.

---

## 10. New POQs introduced

None. (Observation, not a POQ: the pre-existing cosmetic shell-noise in the
Group-1 unquoted heredoc — §6 — is a long-standing latent style issue in the
test; out of scope for C0 and not fixed, per scope-deliverables-to-the-ask. It
does not affect correctness or exit status.)

---

## 11. Definition-of-Done checklist

| Item | Status |
|---|---|
| `_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({"test-fixtures/manifest.txt"})` added beside `_PROJECT_SIDE_PATH_PREFIXES` | PASS |
| `_is_scope_neutral_generated(path)` predicate added beside `_is_project_side_path` (exact-string set-membership) | PASS |
| `and not _is_scope_neutral_generated(p)` added to BOTH `pack_only` + `project_only` offender comprehensions | PASS |
| `pack_chat_only` branch UNCHANGED | PASS |
| Carve-out is EXACT-PATH, not a `test-fixtures/` prefix (snapshot + build.sh NOT exempt) | PASS (NC-3/NC-7) |
| Test: Group-0 `required` registers `_is_scope_neutral_generated` | PASS |
| Test: NC-1..NC-6 added per §17.6 (+ NC-7 additive) | PASS |
| Test run locally, exit 0 quoted | PASS (EXIT=0) |
| measure-then-bound: sized to exactly `{test-fixtures/manifest.txt}`; real offender still fails (proof quoted) | PASS (§4) |
| runtime: O(1) set-membership, no subprocess; Check-36 wall-time recorded | PASS (0.0178 s) |
| FULL CI suite run (validate ×2 + every tests-job script), each exit quoted, no sampling | PASS (60/60 EXIT=0) |
| manifest: build run; staged only if non-empty (EMPTY confirmed; left unstaged) | PASS |
| edit-in-place, no full rewrite; re-read after edits | PASS |
| No git state changes (agent never commits) | PASS |
| Only `validate-pack.py`, the test, and this IMPL-REPORT touched | PASS |
| PREFLIGHT line emitted before report | PASS |

---

## 12. Rules-Applied Verification Block

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| **ci-guard-design-measure-then-bound** | Carve-out = `frozenset({'test-fixtures/manifest.txt'})` (sized to design §17.3's measured forced-co-variant set). Real-offender-still-caught proof: `NC-6 ... offenders = ['scripts/validate-pack.py']`; snapshot-not-exempt: `offenders = ['test-fixtures/v11-trinity-marker-prepped/CLAUDE.md']`; recipe-not-exempt: `NC-3 rejects build.sh = False`. | COMPLIANT |
| **ci-check-runtime-compounding** | `Check 36 wall-time: 0.0178 s`; carve-out is one `frozenset` membership per path on the already-materialized list; no new subprocess / no per-entry storm / no whole-tree scan. | COMPLIANT |
| **enumerate-encoding-surfaces** | Both encoding surfaces changed in ONE edit set: `scripts/validate-pack.py` (check) + `scripts/tests/test-validate-pack-checks-36-37-38.sh` (test); new symbol `_is_scope_neutral_generated` registered in the test's Group-0 `required` list; `git diff --stat` shows exactly these two files. | COMPLIANT |
| **verify-full-ci-suite** | Enumerated all 60 `run:` commands from `validate-pack.yml`; ran each; `Result: 60/60 wired commands EXIT=0` (§8). Both `validate-pack.py` (general + `PACK_VALIDATE_DEEP=1`) AND the full tests job. No sampling. | COMPLIANT |
| **regenerate-manifest-v11-surface** | `bash test-fixtures/build.sh --all --clean` → `BUILD_EXIT=0`; `MANIFEST_DIFF_EMPTY=yes`; `git status --porcelain test-fixtures/manifest.txt` → empty. Staged ONLY if non-empty → diff EMPTY → not staged. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Five targeted `Edit` calls (2 constant/predicate inserts + 2 offender-branch edits + 1 test-required-list + 1 test NC-block); no Write to either source file. Re-read the offender region (lines 4322–4373) and the inserted test block after editing to confirm. | COMPLIANT |
| **empirical-evidence-blocks** | Every claim backed by command + verbatim output + HEAD `3250887c` + date 2026-06-13: conflict (§2), not-weakened (§4), manifest-empty (§5), test exit (§6), wall-time (§7), full-suite 60/60 (§8). | COMPLIANT |
| **preflight-stop-means-stop** | Emitted exactly one PREFLIGHT line AFTER all edits + full battery (60/60) + new test cases passed: `PREFLIGHT: carve-out + test complete; full CI battery PASS; manifest diff empty; HEAD 3250887cdd08587443f33d06bcb3613404e393f5; about to Write IMPL-REPORT to ...`. No partial report. No parent stop message received. | COMPLIANT |
| **agents-never-commit** | Ran only read-only git verbs (`rev-parse`, `status`, `diff`, `show`, `ls-files`, `checkout HEAD -- <path>` path-restore). No `add`/`commit`/`push`/`stash`/`tag`/branch-mutating verb. Working tree left with only the two edits unstaged; manifest unstaged. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Only the carve-out + its test implemented. `pack_chat_only` branch untouched; no design/plan doc edited; no other check touched; `git status --short` shows exactly 2 modified files. Out-of-scope observation (heredoc noise) surfaced (§10), not silently fixed. | COMPLIANT |
| **rules-applied-verification-block** | This block. | COMPLIANT |

---

*End of IMPL-REPORT-BD-197-C0-CARVEOUT.md*

