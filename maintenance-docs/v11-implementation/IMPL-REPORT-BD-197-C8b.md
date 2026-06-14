# IMPL-REPORT — BD-197 C8b — Guard-A′ (Check 54) OPTIONAL-FEATURES presence-check

**Commit:** C8b (the LAST implementation commit of BD-197) — `pack-only`
**Branch:** `v11-dev`
**Base HEAD (session start + final, no commit made):** `286b4b1e43c00536d3dcf847d521654d2401eefd`
**Regime:** in-place (no `/tmp` handoff dir named in the prompt → edits left in the working tree; `git diff` patch emitted to `/tmp/c8b-changes.patch` for auditability; this report written to the named parent-tree path)
**Date:** 2026-06-14

---

## Read attestation (no skim, no summary, no crop, no derivation)

I READ EACH NAMED AUTHORITATIVE DOC DIRECTLY AND IN FULL before any edit:

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — §13.1a (Guard-A′ presence-check; the MANDATED 3-token form — `baseRef` + `bgIsolation` + the `permissions.deny` recipe token; "sized to EXACTLY those three"; the prose `isolation` param explicitly NOT folded), §11.5 gate (b) (the separate POSITIVE presence-check, baseline 0/0 pre-P3), §13.1/§13.2/§13.3 (sibling guards), §14/§15/§16 Block-C row 5.
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` — §B C8b (lines 157–161: "Check 54 — ships ONCE, here; decision 7"; asserts BOTH surfaces mention all three tokens; measure-then-bound; green on arrival), §B C5/C8a (the token authors), §C run-before-wire mandate (line 198), §C the complete wired battery (line 205), §C green-per-commit (lines 190–192), §G manifest "expected EMPTY — S-2".
- `backlog/BD-197.md` — all notes; **Note 14** in full (the user-mandated Guard-A′ extension — `permissions.deny` recipe token in BOTH files, in addition to `baseRef`+`bgIsolation`; "SUPERSEDES the design's earlier 'optional (P3-architect call)' framing; it is now a mandated C8b deliverable").
- `pack-ops/OPTIONAL-FEATURES.md` (C5) and `project-template/docs/pack/OPTIONAL-FEATURES.md` (C8a) — both read in full to measure the exact tokens present.
- `scripts/validate-pack.py` — the existing guard/check conventions (Check 53/55/56/57 structure: module-level constants + `check_*` function + `print` banner + `ok`/`fail` + dispatch via `run_check`), the `REPO_ROOT`/`failures`/`ok`/`fail`/`run_check` helpers, the reserved-54 comments (lines 9431, 9446–9447), the Check-51/Check-53 self-skip + synthetic-tree precedents.
- `.github/workflows/validate-pack.yml` — the tests-job step shape and the BD-197 guard-test block (Checks 52/53/56/55/57).
- `CLAUDE.md` § "## Pack memory" (full) + curated memory files: `feedback_ci_guard_design_measure_then_bound.md`, `feedback_ci_check_runtime_compounding.md`, `feedback_verify_full_ci_suite.md`, `feedback_manifest_regen_on_v11_surface.md`.
- `CLAUDE.md`, `pack-ops/PACK-AGENTS.md`, `/backlog/_rules.md`, `/changelog/_rules.md` standing rules.

---

## Guard-A′ (Check 54) specification — as implemented

**What it asserts (the POSITIVE inverse of Guard-A/Check 53):** BOTH OPTIONAL-FEATURES surfaces each mention the MANDATED THREE tokens — so the un-prohibited worktree-isolation feature + its in-session backstop recipe stay DOCUMENTED on both surfaces.

- **Surfaces (2):** `pack-ops/OPTIONAL-FEATURES.md` (authored C5) + `project-template/docs/pack/OPTIONAL-FEATURES.md` (authored C8a).
- **Tokens (3, literal substrings):** `baseRef`, `bgIsolation`, `permissions.deny`.
  - `baseRef` — the REQUIRED base setting key.
  - `bgIsolation` — the background-SESSION gate / BD-218 pointer (documented in its correct role; the check does NOT assert it is a subagent trigger — only that the key is documented).
  - `permissions.deny` — the documented-optional in-session mechanical-backstop recipe token (§18.2(ii)); MANDATED per BD-197 Note 14 (supersedes the design's earlier "optional" framing).
- **NOT asserted (measure-then-bound, no broader):** the prose per-spawn `isolation` parameter — it is prose, not a settings key (design §13.1a). Test case G proves a file with the 3 tokens but no `isolation` param still PASSes.

**Symbols added to `scripts/validate-pack.py`:**
- `_CHECK_54_OPTIONAL_FEATURES_SURFACES = ("pack-ops/OPTIONAL-FEATURES.md", "project-template/docs/pack/OPTIONAL-FEATURES.md")`
- `_CHECK_54_REQUIRED_TOKENS = ("baseRef", "bgIsolation", "permissions.deny")`
- `def check_optional_features_presence() -> None` — banner `── Check 54: BD-197 OPTIONAL-FEATURES presence-check (Guard-A′) ──`; two single-file reads; per surface, `missing = [tok for tok in _CHECK_54_REQUIRED_TOKENS if tok not in text]`; `fail(...)` naming the surface + missing token(s) on any miss; one consolidated `ok(...)` when clean.
- Dispatch: `run_check("check_optional_features_presence", check_optional_features_presence)` registered immediately after Check 53 in the BD-197 cluster.

**Why literal substring (not regex):** the three tokens are unique literal identifiers (`baseRef`, `bgIsolation`) and a literal recipe heading (`permissions.deny`, whose `.` is a real dot in the docs — e.g. the prose `` `permissions.deny` recipe `` and the JSON `"permissions": { "deny": [ ... ] }` block). A plain `in` test matches the authored token exactly, sized no broader.

---

## Measure-then-bound — the 3 tokens × 2 files (live at HEAD 286b4b1, 2026-06-14)

```
grep -c 'baseRef'           pack-ops/OPTIONAL-FEATURES.md                        => 10
grep -c 'bgIsolation'       pack-ops/OPTIONAL-FEATURES.md                        =>  6
grep -c 'permissions\.deny' pack-ops/OPTIONAL-FEATURES.md                        =>  4
grep -c 'baseRef'           project-template/docs/pack/OPTIONAL-FEATURES.md      => 10
grep -c 'bgIsolation'       project-template/docs/pack/OPTIONAL-FEATURES.md      =>  6
grep -c 'permissions\.deny' project-template/docs/pack/OPTIONAL-FEATURES.md      =>  4
```

**Interpretation:** all three tokens are present in BOTH files (each ≥ 1) → the guard is **GREEN ON ARRIVAL** (C5 authored the pack tokens, C8a the project tokens). The assertion is sized to EXACTLY these 3 tokens × 2 files — no broader. **Conclusion: SUPPORTED.**

**Exact `permissions.deny` carrier strings measured:** pack — the prose `` `permissions.deny` recipe `` heading (lines 186, 193, 228, 253) + the JSON `"permissions": { "deny": [...] }` block (line 202); project — the parallel heading (lines 173, 181, 215, 258) + JSON block (line 190). The asserted token is the exact literal `permissions.deny` both files carry.

---

## Missing-token-catch proof (explicit; /tmp only — NO real-tree mutation, NO `git checkout`)

Pointed `mod.REPO_ROOT` at a synthetic `/tmp` tree (the Check-53 precedent) and removed one token at a time from one file; verbatim result:

```
baseline (both files all 3 tokens):           failures = 0 (expect 0)
PACK    minus baseRef:                         failures = 1 (expect >=1)
PACK    minus bgIsolation:                     failures = 1 (expect >=1)
PACK    minus permissions.deny:                failures = 1 (expect >=1)
PROJECT minus baseRef:                         failures = 1 (expect >=1)
PROJECT minus bgIsolation:                     failures = 1 (expect >=1)
PROJECT minus permissions.deny:                failures = 1 (expect >=1)
```

**Guard-A′ FAILS if ANY of the 3 tokens is removed from EITHER file — proven for all 6 cells.** Real-tree token counts unchanged after the proof (`pack baseRef=10 bgIsolation=6 permissions.deny=4`; `proj baseRef=10 bgIsolation=6 permissions.deny=4`) — confirming the /tmp-only methodology touched nothing in the repo.

---

## Runtime (ci-check-runtime-compounding)

- **Isolated Check-54 wall-time:** `0.113 ms` (`0.000113 s`), measured by timing `check_optional_features_presence()` directly.
- **Shape:** exactly TWO single-file reads (one per OPTIONAL-FEATURES surface) + three bounded `in` substring tests each. NO whole-tree walk, NO subprocess, NO subprocess-per-entry.
- Well under the 2.0 s per-check WARN budget; `run_check` times it. The validate-pack total-budget guard (general + deep) remained green (exit 0 on both invocations).

---

## Check-number confirmation (54; checks 52–57 now contiguous as a set)

- `grep` for `Check 54`/`_CHECK_54`/`check_optional_features` in `scripts/validate-pack.py` returned exit 1 (zero hits) BEFORE my edit — **54 was genuinely unused/reserved.** No `scripts/tests/test-validate-pack-check-54.sh` existed.
- After C8b, the numeric SET {52, 53, 54, 55, 56, 57} is complete — **no missing number** (54 was the last reserved gap, now filled). The prior "non-contiguous gap at 54" comments (lines ~9431/9446) describe the pre-C8b state; they remain accurate as historical context and were not edited (out of C8b scope — they are descriptive, not assertions of current state, and editing them is not a C8b deliverable).
- Banner order in a live run is commit-order (52, 53, 54, 56, 55, 57), per the dispatch registration sequence — the NUMBERS are all present; banner order ≠ numeric order by design (numbers ≠ commit order, per the §13.2/§13.3 design notes). Verbatim banners from the run:
  ```
  ── Check 52: BD-197 pack RW/RO two-class consistency (Guard-B) ──
  ── Check 53: BD-197 worktree-isolation prohibition flip-block (Guard-A) ──
  ── Check 54: BD-197 OPTIONAL-FEATURES presence-check (Guard-A′) ──
  ── Check 56: BD-197 destructive-git-verb enumeration parity (Guard-C) ──
  ── Check 55: BD-197 project RW/RO two-class consistency (Guard-B project) ──
  ── Check 57: BD-197 PROJECT destructive-git-verb enumeration parity (Guard-C project) ──
  ```

**Green-on-arrival evidence (verbatim from `python3 scripts/validate-pack.py`):**
```
── Check 54: BD-197 OPTIONAL-FEATURES presence-check (Guard-A′) ──
  OK: Check 54 (Guard-A′) — OPTIONAL-FEATURES presence holds across 2 surface(s) (pack + project): all 3 mandated tokens (`baseRef`, `bgIsolation`, `permissions.deny` recipe) documented in each. The un-prohibited worktree-isolation feature + its in-session backstop recipe stay documented (BD-197 Note 14).
```

---

## New per-check test + run-before-wire evidence

**File:** `scripts/tests/test-validate-pack-check-54.sh` (new, 251 lines, `chmod +x`).

**Coverage:**
- Group 0 — module import + Check 54 symbol registration + **sizing assertion** (`_CHECK_54_REQUIRED_TOKENS == ('baseRef','bgIsolation','permissions.deny')`, `_CHECK_54_OPTIONAL_FEATURES_SURFACES == (pack, project)`).
- Group 1 — synthetic `/tmp` tree (never the real tree):
  - **A PASS** — all 3 tokens in BOTH files.
  - **B FAIL** — `permissions.deny` missing from PACK (asserts the failure names the pack path + the token).
  - **C FAIL** — `permissions.deny` missing from PROJECT.
  - **D FAIL** — `baseRef` missing from PACK.
  - **E FAIL** — `bgIsolation` missing from PROJECT.
  - **F FAIL** — a surface file absent entirely (not-found path).
  - **G PASS** — measure-then-bound: 3 tokens present but NO prose `isolation` param → still PASS (the param is deliberately not folded into the bounded check).
- Group 2 — end-to-end `validate-pack.py` exit 0 on HEAD + Check-54 clean banner present.

**Run-before-wire sequence (per plan §C decision 2 / M-3):**
1. **Authored** the test → 2. **RAN it locally BEFORE wiring** → Groups 0 + 1 PASS; Group 2 reported the *expected* `validate-pack exits non-zero` because the BD-184 wiring guard correctly FAILS when a `test-validate-pack-check*.sh` file exists on disk but is not yet wired in the yml (verbatim: `FAIL: scripts/tests/test-validate-pack-check-54.sh — per-check test file exists on disk but has NO corresponding ... invocation in .github/workflows/validate-pack.yml ... Per BD-184 ...`). This is the run-before-wire gate working as designed — the guard's behavior (Groups 0/1) was proven before wiring.
3. **Wired** the new step into `.github/workflows/validate-pack.yml` tests job (after the Check-57 step, in the BD-197 guard-test block) → 4. **Re-ran the FULL battery** (below). Post-wire, the test exits 0 with `PASS: 3, FAIL: 0` and Group 2 now reports `validate-pack.py exits 0; Check 54 runs and reports presence-holds clean at HEAD`.

yml step added:
```yaml
      - name: validate-pack Check 54 tests (BD-197 C8b, OPTIONAL-FEATURES presence-check Guard-A′)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-54.sh
```

---

## FULL CI SUITE results (no sampling — EVERY wired script + the new test)

Every script wired in `.github/workflows/validate-pack.yml` was run and its EXIT status quoted. Both validate-job invocations (general + `PACK_VALIDATE_DEEP=1`) and EVERY tests-job script, incl. the new check-54 test. **All EXIT 0.**

**Validate job (2):**
```
validate-pack.py (general)                EXIT 0
validate-pack.py (DEEP / PACK_VALIDATE_DEEP=1)  EXIT 0   (PASSED — all checks clean, both)
```

**Tests job — tracker/per-entry (15):** test-detect.sh, tracker-provider-test.sh, tracker-config-test.sh, tracker-init-test.sh, tracker-agent-read-test.sh, tracker-migrate-forward-test.sh, tracker-migrate-reverse-test.sh, tracker-migrate-roundtrip-test.sh, test-tracker-phase-task.sh, test-tracker-links.sh, test-tracker-cycle-check.sh, tracker-errors-test.sh, tracker-config-schema-test.sh, recommendation-state-schema-test.sh, test-per-entry.sh — **all EXIT 0.**

**Tests job — validate-pack per-check tests (23):** checks-32-33-34, checks-36-37-38, check-39, check-40, check-41, check-18, check-16, check-19, check-42, check-43, check-44, check-45, check-46, removed-doc-advisory, check-49-field-faithfulness, check-50-codec, check-51-flip-block, check-52, check-53, check-56, check-55, check-57, **check-54 (NEW)** — **all EXIT 0.**

**Tests job — tracker-BD + migrate + init (17):** tracker-deferral-gate-test.sh, tracker-bd129-gh-repo-test.sh, tracker-bd130-doctor-wired-test.sh, tracker-bd132-race-test.sh, tracker-bd133-header-preservation-test.sh, tracker-bd134-close-retry-test.sh, recommendation-test.sh, pack-help-test.sh, test-customization-preserve.sh, test-init-project.sh, test-migrate-v10-to-v11.sh, test-migrate-v10-to-v11-dry-run.sh, test-migrate-v10-to-v11-gates.sh, test-migrate-v10-to-v11-decompose.sh, test-migrator-core.sh, test-migrator-manifest.sh, test-migrator-capability-translation.sh — **all EXIT 0.**

**Tests job — manifest + integration + persona + template (8 + the restore step):**
```
build.sh --all --clean        EXIT 0
restore manifest              (cp-restore, NOT git checkout — see note)
build.sh --verify             EXIT 0
test-v11-realistic-ot.sh      EXIT 0
test-migrator-skills.sh       EXIT 0
test-persona-contracts.sh     EXIT 0
template-translations-test.sh EXIT 0
template-version-test.sh      EXIT 0
test-issue-forms.sh           EXIT 0
```

**Manifest-restore substitution note:** the CI yml step at line 298 is `git checkout HEAD -- test-fixtures/manifest.txt`. `git checkout` is a DENIED verb for this agent class (agents-never-commit), so I substituted a `cp`-restore from a `/tmp` backup taken before the build. The substitution is faithful: the manifest was independently proven UNCHANGED by C8b (see below), so the restore is a no-op either way; the CI runner itself will run the real `git checkout` step.

**TOTAL: every wired script EXIT 0. No sampling.**

---

## Manifest determination (cp-based regen, NOT git checkout)

- C8b touches `scripts/` (and `.github/`) → v11-surface → manifest regen required.
- **Backup taken via `cp`** (not git): `cp test-fixtures/manifest.txt /tmp/manifest-backup-c8b.txt` (10 lines).
- **Regenerated:** `bash test-fixtures/build.sh --all --clean` → EXIT 0.
- **Diff vs git-tracked:** `git diff --quiet test-fixtures/manifest.txt` → **exit 0 (EMPTY — unchanged).** `diff -q` of the regenerated manifest vs the `/tmp` backup → IDENTICAL.
- **`build.sh --verify`** → EXIT 0 (all three fixture trees OK).
- **`git status --short test-fixtures/manifest.txt`** → empty (unmodified).
- **Determination: manifest diff is EMPTY → nothing to stage** (matches the plan's "expected EMPTY — S-2, same as C6b"). **Confirmed `cp` used for backup/restore; no `git checkout` run.**

---

## Plan deviations

**ZERO.** C8b implemented exactly per design §13.1a + §11.5 gate (b) + plan §B C8b + BD-197 Note 14: Check 54 = 3-token (`baseRef`+`bgIsolation`+`permissions.deny`) presence-check × 2 surfaces, measure-then-bound, runtime-guarded, with the new per-check test authored+run+wired in the same commit, full battery re-run, manifest empty.

## New POQs introduced

**None.**

---

## Files changed (inventory)

| Path | Change type | Delta |
|---|---|---|
| `scripts/validate-pack.py` | modified | +141 lines (Check 54 constants + `check_optional_features_presence` + dispatch `run_check` + comment block) |
| `.github/workflows/validate-pack.yml` | modified | +3 lines (the Check-54 tests-job step) |
| `scripts/tests/test-validate-pack-check-54.sh` | new | 251 lines (Groups 0/1/2) |

`git diff --stat` (tracked edits): `2 files changed, 144 insertions(+)`. The patch for the two tracked-file edits is at `/tmp/c8b-changes.patch` (173 lines); the new test file's full contents are below (so Pack Chat can re-apply without re-deriving). **No other files modified.** The two untracked `IMPL-REPORT-BD-197-C8a.md` / `PACK-REVIEW-BD-197-C8a.md` were present at session start (C8a artifacts) and are NOT my work — the orchestrator bundles them. `test-fixtures/manifest.txt` is UNMODIFIED.

---

## Definition-of-Done checklist

| Item | PASS/FAIL | Evidence |
|---|---|---|
| Check 54 = 3-token presence-check (`baseRef`+`bgIsolation`+`permissions.deny`) × 2 surfaces | PASS | `_CHECK_54_REQUIRED_TOKENS`/`_CHECK_54_OPTIONAL_FEATURES_SURFACES`; banner + OK output |
| Check number = 54 (re-confirmed unused; 52–57 now a contiguous set) | PASS | pre-edit grep exit 1; SET {52..57} complete post-C8b |
| Measure-then-bound (sized to exactly the 3 measured tokens × 2 files) | PASS | counts 10/6/4 both files; assertion = exactly the 3 tokens; `isolation` param NOT folded (test G) |
| Green on arrival (C5+C8a authored tokens) | PASS | validate-pack Check-54 OK; exit 0 |
| Missing-token-catch proven in EITHER file (no real-tree mutation, no git checkout) | PASS | 6/6 /tmp cells fail; baseline 0; real tree counts unchanged |
| Runtime: two-file read, no subprocess, recorded wall-time | PASS | 0.113 ms; 2 reads + 6 `in` tests |
| New per-check test authored + RUN locally (quote exit 0) | PASS | `PASS: 3, FAIL: 0`, exit 0 (post-wire) |
| Run-before-wire (ran before wiring; BD-184 gate confirmed it) | PASS | pre-wire BD-184 FAIL reproduced; post-wire clean |
| Test wired into validate-pack.yml tests job | PASS | step added after Check-57 |
| FULL CI battery re-run, every wired script EXIT 0 (no sampling) | PASS | 2 validate (incl. DEEP) + all tests-job scripts + new test = all EXIT 0 |
| Manifest regen via cp (not git checkout); stage only if non-empty | PASS | diff EMPTY → nothing to stage; `--verify` exit 0 |
| Scope = pack-only (validate-pack.py + test + yml only) | PASS | `git diff --name-only` = the 2 tracked files; new test only untracked addition I made |
| Trinity rule | N/A | no trinity file touched |
| edit-in-place (no wholesale rewrite of validate-pack.py) | PASS | two targeted Edits (one insert block + one dispatch insert) |
| No state-changing git verb | PASS | only `git rev-parse`/`status`/`diff` (incl. `git diff > file`) run |

---

## Full contents — new file `scripts/tests/test-validate-pack-check-54.sh`

```bash
#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-54.sh — dedicated test for
# BD-197 Check 54 (OPTIONAL-FEATURES presence-check, Guard-A′).
#
# Check 54 is the POSITIVE inverse of Guard-A (Check 53): it asserts BOTH
# OPTIONAL-FEATURES surfaces (`pack-ops/OPTIONAL-FEATURES.md` from C5 +
# `project-template/docs/pack/OPTIONAL-FEATURES.md` from C8a) each mention the
# MANDATED three tokens — `baseRef`, `bgIsolation`, and the `permissions.deny`
# recipe token (user-approved 2026-06-14; BD-197 Note 14; design §13.1a /
# §11.5 gate (b)). This keeps the un-prohibited worktree-isolation feature +
# its in-session backstop recipe DOCUMENTED on both surfaces.
#
# This test proves the guard PASSes when all three tokens are present in BOTH
# files, and FAILs when ANY token is missing from EITHER file — exercised in a
# synthetic /tmp tree (it NEVER mutates the real tree). It also confirms the
# measure-then-bound sizing (exactly 3 tokens × 2 files; the prose `isolation`
# param is NOT folded in).
#
# Coverage:
#   Group 0: module import + Check 54 symbol registration
#   Group 1: synthetic-tree end-to-end (mod.REPO_ROOT pointed at /tmp):
#            A  PASS — all 3 tokens present in BOTH files
#            B  FAIL — `permissions.deny` missing from the PACK file
#            C  FAIL — `permissions.deny` missing from the PROJECT file
#            D  FAIL — `baseRef` missing from the PACK file
#            E  FAIL — `bgIsolation` missing from the PROJECT file
#            F  FAIL — a surface file is absent entirely
#            G  PASS — token set is sized to exactly the 3 keys (a file with
#                      the 3 tokens but WITHOUT the prose `isolation` param
#                      still PASSes — the param is deliberately NOT asserted)
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 54 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-54.sh

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
printf "\n=== Group 0: Module import + Check 54 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_optional_features_presence',
    '_CHECK_54_OPTIONAL_FEATURES_SURFACES',
    '_CHECK_54_REQUIRED_TOKENS',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
# Assert the measure-then-bound sizing: exactly 3 tokens × 2 surfaces.
toks = tuple(mod._CHECK_54_REQUIRED_TOKENS)
surfs = tuple(mod._CHECK_54_OPTIONAL_FEATURES_SURFACES)
if toks != ('baseRef', 'bgIsolation', 'permissions.deny'):
    print('FAIL_TOKENS ' + repr(toks))
    sys.exit(1)
if surfs != ('pack-ops/OPTIONAL-FEATURES.md',
             'project-template/docs/pack/OPTIONAL-FEATURES.md'):
    print('FAIL_SURFACES ' + repr(surfs))
    sys.exit(1)
print('OK')
" > /tmp/vp-check54-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check54-import.out; then
    t_pass "validate-pack.py imports + Check 54 symbols registered + sized to 3 tokens × 2 surfaces"
else
    t_fail "validate-pack.py import / Check 54 symbol registration / sizing failed" \
        "$(cat /tmp/vp-check54-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (PASS + missing-token-FAIL cases)
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

PACK = "pack-ops/OPTIONAL-FEATURES.md"
PROJ = "project-template/docs/pack/OPTIONAL-FEATURES.md"

# Content carrying all 3 tokens (baseRef, bgIsolation, permissions.deny) plus
# the prose isolation param (which is deliberately NOT asserted by the guard).
ALL3 = (
    "Set worktree.baseRef to head. worktree.bgIsolation gates background "
    "sessions. The permissions.deny recipe is the in-session backstop. "
    'Pass isolation:"worktree" per spawn.\n'
)

def run(build):
    """build(root) populates a synthetic tree; return (n_failures, output)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check54-")
    root = pathlib.Path(tmpdir)
    build(root)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_optional_features_presence()
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return n, cap

def w(root, rel, text):
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)

# A: all 3 tokens present in BOTH files -> PASS
def bA(root):
    w(root, PACK, ALL3)
    w(root, PROJ, ALL3)
n, cap = run(bA)
if n != 0:
    failures.append(f"A (all 3 tokens both files) expected PASS, got {n}: {cap}")

# B: permissions.deny missing from the PACK file -> FAIL (names the pack path + token)
def bB(root):
    w(root, PACK, "worktree.baseRef:head and worktree.bgIsolation only.\n")
    w(root, PROJ, ALL3)
n, cap = run(bB)
if n < 1 or PACK not in cap or "permissions.deny" not in cap:
    failures.append(f"B (permissions.deny missing from PACK) expected FAIL naming {PACK}+token, got {n}: {cap}")

# C: permissions.deny missing from the PROJECT file -> FAIL (names the project path)
def bC(root):
    w(root, PACK, ALL3)
    w(root, PROJ, "worktree.baseRef:head and worktree.bgIsolation only.\n")
n, cap = run(bC)
if n < 1 or PROJ not in cap or "permissions.deny" not in cap:
    failures.append(f"C (permissions.deny missing from PROJECT) expected FAIL naming {PROJ}+token, got {n}: {cap}")

# D: baseRef missing from the PACK file -> FAIL
def bD(root):
    w(root, PACK, "worktree.bgIsolation gate; the permissions.deny recipe.\n")
    w(root, PROJ, ALL3)
n, cap = run(bD)
if n < 1 or PACK not in cap or "baseRef" not in cap:
    failures.append(f"D (baseRef missing from PACK) expected FAIL naming {PACK}+baseRef, got {n}: {cap}")

# E: bgIsolation missing from the PROJECT file -> FAIL
def bE(root):
    w(root, PACK, ALL3)
    w(root, PROJ, "worktree.baseRef:head; the permissions.deny recipe.\n")
n, cap = run(bE)
if n < 1 or PROJ not in cap or "bgIsolation" not in cap:
    failures.append(f"E (bgIsolation missing from PROJECT) expected FAIL naming {PROJ}+bgIsolation, got {n}: {cap}")

# F: a surface file is absent entirely -> FAIL (not found)
def bF(root):
    w(root, PACK, ALL3)
    # PROJ deliberately not written
n, cap = run(bF)
if n < 1 or PROJ not in cap or "not" not in cap:
    failures.append(f"F (PROJECT surface absent) expected FAIL naming {PROJ}, got {n}: {cap}")

# G: measure-then-bound — a file with all 3 tokens but WITHOUT the prose
# isolation param still PASSes (the param is NOT folded into the bounded check).
def bG(root):
    no_param = (
        "worktree.baseRef head; worktree.bgIsolation background gate; "
        "the permissions.deny recipe is the backstop.\n"
    )
    w(root, PACK, no_param)
    w(root, PROJ, no_param)
n, cap = run(bG)
if n != 0:
    failures.append(f"G (3 tokens, no isolation param -> still PASS) expected PASS, got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests A/B/C/D/E/F/G (presence PASS + missing-token catch in EITHER file + absent-surface FAIL + measure-then-bound sizing)" ;;
    *) t_fail "End-to-end check_optional_features_presence tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check54-e2e.out 2>&1; then
    if grep -q "Check 54: BD-197 OPTIONAL-FEATURES presence-check" /tmp/vp-check54-e2e.out \
       && grep -q "Check 54 (Guard-A′) — OPTIONAL-FEATURES presence holds" /tmp/vp-check54-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 54 runs and reports presence-holds clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 54 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check54-e2e.out)"
    fi
else
    if grep -q "Check 54: BD-197 OPTIONAL-FEATURES presence-check" /tmp/vp-check54-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 54 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check54-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 54 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check54-e2e.out)"
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

## Boundary discipline check

C8b is `pack-only` and touched ZERO project-side surfaces. The edited files are all pack-only (`scripts/validate-pack.py`, `scripts/tests/test-validate-pack-check-54.sh`, `.github/workflows/validate-pack.yml`). The guard READS the project-side `project-template/docs/pack/OPTIONAL-FEATURES.md` as an asserted surface but did not EDIT it (C8a authored it). No reference to a pack-only file was added to any project-side surface. No boundary-discipline stop required.

---

## Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| ci-guard-design-measure-then-bound [coder] | Measured the 3 tokens in BOTH files at HEAD 286b4b1 (`baseRef` 10/10, `bgIsolation` 6/6, `permissions.deny` 4/4); `_CHECK_54_REQUIRED_TOKENS` sized to EXACTLY those 3 (prose `isolation` param NOT folded — test G PASS); missing-token-catch proven 6/6 in /tmp (each token removed from either file → 1 failure; baseline 0). | COMPLIANT |
| ci-check-runtime-compounding [universal] | Isolated wall-time 0.113 ms; exactly 2 single-file reads + 6 `in` tests; no whole-tree walk, no subprocess, no subprocess-per-entry; `run_check` times it under the 2.0 s WARN budget; total-budget guard green (general + deep). | COMPLIANT |
| enumerate-encoding-surfaces [coder] | Check + new test + yml edited in LOCKSTEP in this one commit: `scripts/validate-pack.py` (constants+fn+dispatch), `scripts/tests/test-validate-pack-check-54.sh` (new), `.github/workflows/validate-pack.yml` (wired step). No asymmetric coverage. | COMPLIANT |
| verify-full-ci-suite [universal] | Ran EVERY script wired in validate-pack.yml — both validate invocations (general + `PACK_VALIDATE_DEEP=1`) + every tests-job script + the new check-54 test; quoted each EXIT status; ALL EXIT 0; no sampling. Run-before-wire honored (test run before yml wiring; BD-184 gate reproduced then cleared). | COMPLIANT |
| edit-in-place-not-full-rewrite [universal] | Two targeted Edits to `scripts/validate-pack.py` (one insert block after Check-53 `ok(...)`, one dispatch insert after the Check-53 `run_check`); one targeted Edit to the yml. No wholesale rewrite. | COMPLIANT |
| regenerate-manifest-v11-surface [coder] | `cp` backup → `build.sh --all --clean` → `git diff --quiet test-fixtures/manifest.txt` exit 0 (EMPTY) → `build.sh --verify` exit 0; nothing staged (empty diff). `cp`-restore used, NOT `git checkout`. | COMPLIANT |
| empirical-evidence-blocks [coder] | Every state-claim backed by command + verbatim output + HEAD 286b4b1 + date 2026-06-14 (token counts, missing-token-catch table, wall-time, contiguity grep, manifest diff, full-battery exit codes). | COMPLIANT |
| preflight-stop-means-stop [universal] | Emitted the single PREFLIGHT line (`Guard-A′ (Check 54) 3-token presence + test wired complete; green on arrival both surfaces; missing-token-catch proven; FULL CI battery PASS; manifest empty; HEAD 286b4b1...; about to Write IMPL-REPORT`) only after ALL edits + the FULL battery + the new test PASSED. No parent stop received. | COMPLIANT |
| agents-never-commit [universal] | Only read-only git verbs run: `git rev-parse HEAD`/`--abbrev-ref`, `git status`, `git diff` (incl. `git diff > /tmp/c8b-changes.patch`). NO `add/commit/push/checkout/stash/reset/restore/...`. Manifest restore via `cp`. Edits left UNSTAGED in the working tree for the orchestrator. | COMPLIANT |
| scope-deliverables-to-the-ask [universal] | Edited ONLY `scripts/validate-pack.py` + the new test + the yml. Did NOT touch either OPTIONAL-FEATURES file, any project surface, or the C8a audit docs. `git diff --name-only` = the 2 tracked files. | COMPLIANT |
| rules-applied-verification-block [universal] | This block. | COMPLIANT |
