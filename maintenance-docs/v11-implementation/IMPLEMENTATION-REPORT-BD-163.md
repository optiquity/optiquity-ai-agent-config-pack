# IMPLEMENTATION-REPORT-BD-163

**BD:** BD-163 — CI repair: declare fixture dependencies in test runners +
reorder workflow + audit + document invariant (retroactive BD-147 CI fix)
**Branch:** `v11-dev`
**Pre-flight HEAD:** `4b93ef0595e97317f5bb57188860429e65fc31ee`
**Final HEAD:** `4b93ef0595e97317f5bb57188860429e65fc31ee` (no agent commits;
working-tree edits only — Pack Chat will commit)
**Date:** 2026-05-12

---

## Summary

Three changes applied to address the BD-147 CI failure (4+ consecutive red
runs since commit `0622c82`) by fixing the **root cause** (silent,
undeclared, unchecked fixture dependency in `scripts/test-migrator-skills.sh`
G1) — not just the symptom (workflow step ordering).

- **Change A:** added `require_fixture <name>` helper to
  `scripts/test-migrator-skills.sh`; called at the top of G1; documented
  preconditions in the runner header. Fail-fast now produces a clear,
  actionable error naming the missing fixture and the exact build
  command, exit code 3.
- **Change B:** reordered `.github/workflows/validate-pack.yml` so the
  `migrator-skills tests (BD-147)` step runs AFTER `build test fixtures`
  + `fixture manifest verify`; added a header invariant comment block
  documenting the rule and the defense-in-depth reasoning.
- **Change C:** audited 9 sibling test runners; only persona-contracts
  and migrator-skills depend on built fixtures, and persona-contracts is
  already protected by `_materialize_for_contract`'s built-fixture
  die-check. All other runners synthesize their own `mktemp`-based
  fixtures and need no change.

---

## Pre-flight state

```
git rev-parse HEAD       → 4b93ef0595e97317f5bb57188860429e65fc31ee
git status (relevant)    → BACKLOG.md modified (BD-163 entry); other
                            untracked maintenance-docs unrelated
ls test-fixtures/        → v10-realistic-ot/ present (built locally)
test-fixtures/v10-realistic-ot/.git/HEAD → present (built marker confirmed)
```

`test-fixtures/.gitignore` confirms the fixture directories are
gitignored (`*` with explicit allow-list for `.gitignore`, `README.md`,
`build.sh`, `manifest.txt`, and the static-snapshot
`v11-trinity-marker-prepped/`).

---

## Change A — `require_fixture` in `scripts/test-migrator-skills.sh`

### Header documentation block (added)

Inserted under existing header comment, immediately above `set -uo pipefail`:

```
# ## Preconditions (BD-163)
#
# G1 depends on the built `test-fixtures/v10-realistic-ot/` fixture
# (a gitignored build artifact, not source — only present after running
# `bash test-fixtures/build.sh --name v10-realistic-ot`). G2 / G3 are
# self-contained (synthesize their own fixtures under `$TMPDIR`).
#
# `require_fixture` (below) validates fixture preconditions explicitly
# and fails fast with a clear, actionable error if a required fixture is
# missing — converting the prior silent `cp: cannot stat ...` failure
# into a self-documenting precondition. Add a `require_fixture <name>`
# call at the top of any future G-section that touches `test-fixtures/`.
```

### `require_fixture` helper (added)

Inserted between `PACK_ROOT=...` and `FIXTURE_BASE=...`:

```bash
# ── BD-163 — fixture-precondition helper ───────────────────────────────
# Verifies that `test-fixtures/<name>/` exists AND has been built (per
# `test-fixtures/build.sh`, every fixture is initialized as a git repo,
# so `.git/HEAD` is the canonical built-fixture marker). On failure,
# prints the exact build command and exits non-zero. Portable bash 3.2
# / BSD-utils — no GNU-only constructs.
require_fixture() {
    local name="${1:?require_fixture: missing <name>}"
    local fx="$PACK_ROOT/test-fixtures/$name"
    if [[ ! -d "$fx" || ! -f "$fx/.git/HEAD" ]]; then
        printf 'ERROR: %s requires test-fixtures/%s/ but it does not exist or is not a built fixture.\n' \
            "$(basename "${BASH_SOURCE[1]:-$0}")" "$name" >&2
        printf '       Build it with: bash test-fixtures/build.sh --name %s\n' "$name" >&2
        printf '       (or build all fixtures: bash test-fixtures/build.sh --all --clean)\n' >&2
        exit 3
    fi
}
```

Marker rationale: `test-fixtures/build.sh` `_fixture_git_init` always
runs `git init` as the first build step for every fixture (line 93),
so `.git/HEAD` is universal across all fixtures and is created
strictly post-build. Cheaper than checking `manifest.txt` alignment
and works for the BD-116 `--for-contract greenfield` sandbox shape too.

### Call site (added at top of G1)

```bash
echo "=== G1: golden-snapshot regression for v10→v11 S5b helper ==="

# BD-163: declare G1's fixture precondition explicitly. Fails fast with
# an actionable error if the gitignored build artifact is missing
# (instead of the prior silent `cp: cannot stat ...` failure).
require_fixture "v10-realistic-ot"

G1_DIR="$FIXTURE_BASE/g1"
...
```

### Verification — happy path

```
$ bash scripts/test-migrator-skills.sh
=== G1: golden-snapshot regression for v10→v11 S5b helper ===
  pass: G1 golden sha256 CLAUDE.md
  pass: G1 golden sha256 AGENTS.md
  pass: G1 golden sha256 GEMINI.md
  pass: G1 golden sha256 docs/pack/PLATFORM-SKILLS.md
  pass: G1 golden sha256 .pack-migrate-v10-to-v11/python-architecture-rename.advisory

=== G2: migrator_skill_rename SIMPLE mode ===
  pass: G2.a … pass: G2.f                       (6 sub-tests)

=== G3: migrator_skill_rename SPLIT mode + migrator_skill_split ===
  pass: G3.a … pass: G3.g                       (8 sub-tests)

=== Results: 19 passed, 0 failed ===
```

### Verification — fail-fast path (CI shape simulation)

Temporarily moved the local `.git` aside to simulate CI's
unbuilt-fixture state, re-ran the test, then restored:

```
$ mv test-fixtures/v10-realistic-ot/.git /tmp/bd163-stash-git
$ bash scripts/test-migrator-skills.sh
=== G1: golden-snapshot regression for v10→v11 S5b helper ===
ERROR: test-migrator-skills.sh requires test-fixtures/v10-realistic-ot/ but it does not exist or is not a built fixture.
       Build it with: bash test-fixtures/build.sh --name v10-realistic-ot
       (or build all fixtures: bash test-fixtures/build.sh --all --clean)
$ echo $?
3
$ mv /tmp/bd163-stash-git test-fixtures/v10-realistic-ot/.git
$ bash scripts/test-migrator-skills.sh | tail -1
=== Results: 19 passed, 0 failed ===
```

Exit-3 contract is met. Error message names both the fixture AND the
build command. No more silent `cp: cannot stat ...`.

---

## Change B — `.github/workflows/validate-pack.yml` reorder + invariant

### Header invariant block (added)

Appended to the existing `# Step ordering for the BD-115/116/117 surface`
comment block at the top of the file:

```
# Step ordering invariant for the tests: job (BD-163)
# ===================================================
# Tests that depend on built fixtures (in test-fixtures/<name>/) MUST
# come AFTER the "build test fixtures" step. The fixtures are
# gitignored build artifacts; CI runners do not have them until built.
# Affected tests today:
#   - migrator-skills tests (BD-147) — depends on v10-realistic-ot
#                                     (G1 golden-snapshot regression)
#   - persona contracts (BD-116)     — depends on existing-project-mid-dev
#                                     and v10-realistic-ot via
#                                     `test-fixtures/build.sh
#                                     --for-contract <persona>`
#   - fixture manifest verify (BD-115) — depends on all built fixtures
# Each fixture-dependent test runner ALSO declares its precondition
# inline via the `require_fixture` helper (test-migrator-skills.sh)
# or via `_materialize_for_contract`'s built-fixture die-check
# (test-fixtures/build.sh, used by persona-contracts). CI step ordering
# is a defense-in-depth complement to those preconditions: the in-script
# checks give a clear local-dev error; the ordering keeps CI green even
# if a future runner forgets to call `require_fixture`.
```

### Step reorder

Moved the `migrator-skills tests (BD-147)` step from its prior position
(immediately after `migrator-capability-translation tests`, which was
BEFORE the fixture build) to AFTER `fixture manifest verify` and BEFORE
`persona contracts`. Added an inline comment at the new position
explaining the ordering rationale.

Before (relevant portion):

```yaml
- name: migrator-capability-translation tests (BD-144)
  run: bash scripts/test-migrator-capability-translation.sh
- name: migrator-skills tests (BD-147)               # ← BROKEN: ran before build
  run: bash scripts/test-migrator-skills.sh
- name: build test fixtures (BD-115/116/117)
  run: bash test-fixtures/build.sh --all --clean
- name: fixture manifest verify (BD-115, RELEASE-GATE item 5)
  run: bash test-fixtures/build.sh --verify
- name: persona contracts (BD-116, RELEASE-GATE item 3)
  run: bash scripts/test-persona-contracts.sh
```

After:

```yaml
- name: migrator-capability-translation tests (BD-144)
  run: bash scripts/test-migrator-capability-translation.sh
- name: build test fixtures (BD-115/116/117)
  run: bash test-fixtures/build.sh --all --clean
- name: fixture manifest verify (BD-115, RELEASE-GATE item 5)
  run: bash test-fixtures/build.sh --verify
# BD-163: migrator-skills tests MUST run AFTER "build test fixtures"
# because G1 (golden-snapshot regression) depends on the built
# `test-fixtures/v10-realistic-ot/` fixture (gitignored build
# artifact). The runner also calls `require_fixture` defensively.
- name: migrator-skills tests (BD-147)
  run: bash scripts/test-migrator-skills.sh
- name: persona contracts (BD-116, RELEASE-GATE item 3)
  run: bash scripts/test-persona-contracts.sh
```

### Verification

YAML syntax sanity (script ordering only, no in-flight CI fetch):

```
$ python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/validate-pack.yml"))'
(no output = parsed cleanly)
```

(See validate-pack run below for whole-pack structural sanity.)

---

## Change C — audit other fixture-dependent test runners

Searched every test runner named in the BD-163 spec for references to
`test-fixtures/` or `--for-contract`:

```
$ grep -nE "test-fixtures|for-contract" \
    scripts/test-migrator-core.sh \
    scripts/test-migrator-manifest.sh \
    scripts/test-migrator-capability-translation.sh \
    scripts/tests/test-migrate-v10-to-v11.sh \
    scripts/tests/test-migrate-v10-to-v11-dry-run.sh \
    scripts/tests/test-migrate-v10-to-v11-gates.sh \
    scripts/tests/test-init-project.sh \
    scripts/test-persona-contracts.sh \
    scripts/tests/test-customization-preserve.sh
scripts/test-persona-contracts.sh:9:#   - materializes a sandbox via test-fixtures/build.sh --for-contract,
```

Then surveyed each runner's fixture-construction style:

| Test runner | Fixture style | Built-fixture dep? | Disposition |
|---|---|---|---|
| `scripts/test-migrator-skills.sh` | G1: copy of `test-fixtures/v10-realistic-ot/`; G2/G3: `mktemp` | YES (G1) | **Change A applied** — `require_fixture v10-realistic-ot` |
| `scripts/test-migrator-core.sh` | `mktemp -d -t test-migrator-core.XXXXXX`; per-case subdirs | NO | No change — synthesizes own fixtures |
| `scripts/test-migrator-manifest.sh` | `mktemp -d -t test-migrator-manifest.XXXXXX`; per-case subdirs | NO | No change — synthesizes own fixtures |
| `scripts/test-migrator-capability-translation.sh` | `mktemp -d -t test-bd144-translate.XXXXXX`; comment explicitly states "doesn't depend on a fully-prepared v10-realistic-ot fixture" | NO | No change — synthesizes own fixtures (intentional design) |
| `scripts/tests/test-migrate-v10-to-v11.sh` | `mktemp -d -t migrate10-tgt.XXXXXX` etc. | NO | No change — synthesizes own fixtures |
| `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | `mktemp -d -t migrate10-bd095.XXXXXX` (shared-fixture builder writes synthetic v10-shape into tmp) | NO | No change — synthesizes own fixtures |
| `scripts/tests/test-migrate-v10-to-v11-gates.sh` | `mktemp -d -t migrate10-bd101.XXXXXX` etc. | NO | No change — synthesizes own fixtures |
| `scripts/tests/test-init-project.sh` | `mktemp -d -t init-tgt.XXXXXX` | NO | No change — synthesizes own fixtures |
| `scripts/test-persona-contracts.sh` | Delegates to per-contract scripts under `scripts/persona-contracts/` which call `test-fixtures/build.sh --for-contract <persona>` | YES (mid-dev, migration personas) | **Already protected** — `_materialize_for_contract` (in `test-fixtures/build.sh` lines 793-794, 807-808) calls `die "...source fixture not built; run build.sh --name X first"` if the source fixture's `.git` is missing. Greenfield builds a fresh repo (no built-fixture dep). |
| `scripts/tests/test-customization-preserve.sh` | `mktemp -d -t cp-*` (multiple per-test subdirs) | NO | No change — synthesizes own fixtures |

**Result:** only `test-migrator-skills.sh` had the silent-undeclared-dep
anti-pattern. `test-persona-contracts.sh`'s deps are already declared
(through `_materialize_for_contract`'s die-check on the source fixture).
No new shared `scripts/lib/test-helpers.sh` was needed — the helper is
inline in the single runner that needs it. If a second runner later
needs the same helper, extracting it into a shared lib at that point is
the right time to add the lib (YAGNI).

---

## Verification commands + results

### `bash scripts/test-migrator-skills.sh`

```
=== Results: 19 passed, 0 failed ===
```

PASS (19/19). Includes G1 (5 golden-snapshot assertions), G2 (6),
G3 (8).

### `python3 scripts/validate-pack.py`

Tail:

```
── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 13 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 19 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 34 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 34 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts

============================================================
PASSED — all checks clean
```

PASS (31/31 Checks).

### Fail-fast smoke (require_fixture missing-fixture path)

```
ERROR: test-migrator-skills.sh requires test-fixtures/v10-realistic-ot/ but it does not exist or is not a built fixture.
       Build it with: bash test-fixtures/build.sh --name v10-realistic-ot
       (or build all fixtures: bash test-fixtures/build.sh --all --clean)
EXIT: 3
```

Exact contract met. Local fixture restored post-test; final happy-path
re-run confirmed `19 passed, 0 failed`.

### Permission preservation

```
-rwxr-xr-x@ 1 david  staff  19406 May 12 22:42 scripts/test-migrator-skills.sh
-rw-r--r--@ 1 david  staff   7750 May 12 22:43 .github/workflows/validate-pack.yml
```

Executable bit preserved on `scripts/test-migrator-skills.sh`. Workflow
YAML mode unchanged (workflows are not executable).

---

## Files-touched inventory

| Path | Change type | Lines added | Lines removed |
|---|---|---|---|
| `scripts/test-migrator-skills.sh` | modified | +33 | 0 |
| `.github/workflows/validate-pack.yml` | modified | +33 | -3 (step reorder) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-163.md` | new | (this report) | — |

**File-count:** 3 (well within the BD-163 ≤10 / BD-159 §3.1 mechanical-edit cap).

No other files touched. Did not modify:
- `BACKLOG.md` (BD-163 status flip is Pack Chat's job post-review).
- `CHANGELOG.md`, `README.md` (no version-table change).
- Trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — pack-repo or
  project-template — no rule changes).
- `maintenance-docs/v11-research/` (BD-163 spec excluded).
- `deployment-python/SKILL.md` (BD-162 architect track).
- `ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (BD-162 architect output).
- Any other test runners (Change C audit found none needed).

---

## Plan deviations

None. The fix follows the BD-163 spec exactly:
- Change A: `require_fixture` helper inline in
  `scripts/test-migrator-skills.sh`, called at top of G1, header docs.
- Change B: workflow step reorder + invariant header.
- Change C: audit completed; no other runners needed the helper
  (persona-contracts already protected via `_materialize_for_contract`'s
  die-check).

The spec mentioned the option to "extract the helper into a shared lib
like `scripts/lib/test-helpers.sh` if 2+ test runners need it, or
inline if only one does" — only one runner needs it, so it stays inline.

---

## New POQs introduced

None.

## BD-159 §3.1 mechanical-edit sanity check

| Dimension | Threshold | This BD | PASS? |
|---|---|---|---|
| New top-level docs (pack-product) | 0 expected | 0 | PASS |
| New top-level docs (pack-ops) | 0 expected | 0 (workflow artifacts in `maintenance-docs/v11-implementation/` are exempted per BD-159) | PASS |
| New scripts | 0 expected | 0 | PASS |
| New validate-pack Checks | 0 expected | 0 | PASS |
| New SKILL.md / agent files | 0 expected | 0 | PASS |
| Trinity-file rule changes | 0 expected | 0 | PASS |
| File count | ≤10 | 3 | PASS |
| Reviewer required? | mechanical → reviewer pass sufficient | n/a (BD-163 is a CI-repair fix BD; no architect needed per the user's "fix has to be real, not a band-aid" framing — the realness is in addressing the silent-dependency anti-pattern, which is mechanical) | PASS |

Sanity check PASSES on every dimension.

---

## Definition of Done

| Item | PASS / FAIL |
|---|---|
| `scripts/test-migrator-skills.sh` G1 fails fast with actionable error if fixture missing | PASS (smoke-tested; exit 3) |
| Test runner header documents fixture preconditions | PASS (`## Preconditions (BD-163)` block added) |
| `.github/workflows/validate-pack.yml` puts fixture-dependent tests after `build test fixtures` | PASS (migrator-skills moved to after fixture manifest verify; persona contracts already after) |
| Workflow header comment documents the invariant | PASS (`# Step ordering invariant for the tests: job (BD-163)` block added) |
| `bash scripts/test-migrator-skills.sh` PASSES locally | PASS (19/19) |
| `python3 scripts/validate-pack.py` returns PASS for all 31 Checks | PASS (31/31) |
| All other test runners audited | PASS (9 runners surveyed; table above) |
| Permission bits preserved | PASS (`-rwxr-xr-x` on `.sh`) |
| `maintenance-docs/v11-research/` untouched | PASS |
| `deployment-python/SKILL.md` untouched | PASS |
| `ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` untouched | PASS |
| BD-159 §3.1 mechanical-edit sanity check | PASS (table above) |
| No state-changing git verbs run | PASS (only `git rev-parse`, `git status`) |

All Definition-of-Done items: **PASS**.

---

## Notes for Pack Chat

- Recommended commit message:
  `fix: v11 — BD-163 declare fixture preconditions in test-migrator-skills + reorder validate-pack workflow`
  (BD-163 is a fix/repair BD, not a feature BD; `fix:` prefix per
  pack-repo commit convention.)
- After commit, push and verify the next CI run is green via
  `gh run list --workflow=validate-pack.yml --branch v11-dev --limit 1`.
- BD-163 status flip to Resolved is the implicit-flip step (per the
  Pack memory rule "Implicit BD status flip on batch completion") —
  no separate user approval needed.
- Optional: if a reviewer pass is desired, run `claude --agent
  pack-reviewer` once with this report path; otherwise the green CI run
  is itself the verification.
