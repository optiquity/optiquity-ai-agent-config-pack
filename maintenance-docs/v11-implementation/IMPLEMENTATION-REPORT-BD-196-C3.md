# IMPLEMENTATION-REPORT — BD-196 Commit C3

**Commit:** C3 of 12 (PLAN-DOC-CONCISION-GUARDRAILS.md §3).
**Scope:** Wire the C3 rule↔rationale bijection check (Check 45) + its per-check test + CI wiring, against the clean tree authored by C1/C2.
**Agent:** pack-coder. **Worktree branch:** `v11-dev`.
**HEAD at start AND at report-write:** `b98888519176c6c22b5cc3fcd1194900c3d4baf2` (no git state change — agent does not commit).
**Verification HEAD:** `b988885`, 2026-05-30.

---

## 1. What C3 does (the Check 45 logic)

Adds `check_pack_memory_rationale_bijection` (Check 45) to `scripts/validate-pack.py` per design §5.2. It enforces a **set-equality bijection over the PRESENT `[rationale:]` set** between two surfaces:

- **Corpus side:** the set of `[rationale: <slug>]` slugs tagged on imperative lines in `CLAUDE.md` `## Pack memory` (the corpus representative — trinity parity of AGENTS.md / GEMINI.md is separately enforced by Checks 16/18/19, so C3 keys off CLAUDE.md only).
- **Rationale side:** the set of `## <slug>` section headings in `pack-ops/PACK-MEMORY-RATIONALE.md`.

**Section-scoping (correctness-critical):** the corpus scan is restricted to the `## Pack memory` H2 section (from its `## Pack memory` heading to the next top-level `## ` heading or EOF). A `[rationale:]` token appearing in unrelated prose elsewhere in CLAUDE.md is excluded from the set — test T4 exercises this.

**FAIL conditions (both directions, each emits a distinct, named FAIL):**
- **Orphan corpus slug** — a `[rationale: slug]` with no matching `## slug` heading. FAIL names the slug list + remediation.
- **Orphan rationale heading** — a `## slug` heading with no live `[rationale: slug]` pointer. FAIL names the heading list + remediation.

Rules carrying NO `[rationale:]` are simply not in the set (per §5.2 — the check does NOT require every spawn-rule to have a rationale).

**Pattern reused:** Check 32 `check_mirror_in_sync` (set-equality assertion between two surfaces). Regex: `\[rationale:\s*([a-z0-9][a-z0-9-]*)\]` for corpus slugs; `^##\s+([a-z0-9][a-z0-9-]*)\s*$` (MULTILINE) for rationale headings. Lenient mode: SKIPs (does not FAIL) if either surface is absent.

**Placement:** function defined just before `# ── Main ──` (L6051); callsite added after Check 42's callsite in `main()` (L6288) per the plan's "after the current last check" instruction and the next-free-ID rule (ID 45).

---

## 2. Test cases (`scripts/tests/test-validate-pack-check-45.sh`)

Follows the verification-harness pattern (mirrors `test-validate-pack-check-43.sh`): monkeypatch `mod.REPO_ROOT` to a tmp tree, clear/restore `mod.failures`, capture stdout, count new failures, clean up with `shutil.rmtree` on every exit path. bash 3.2 / BSD-utils portable.

- **Group 0** — module import + `check_pack_memory_rationale_bijection` symbol registration.
- **Group 1** — synthetic-tree end-to-end (the injected fails it catches):
  - **T1 PASS** — balanced 2==2 bijection → 0 failures + "bijection holds" message.
  - **T2 FAIL** — orphan corpus slug (`rule-three-orphan` tagged, no heading) → ≥1 failure, slug named in output.
  - **T3 FAIL** — orphan rationale heading (`rule-three-orphan` heading, no corpus pointer) → ≥1 failure, heading named in output.
  - **T4 PASS** — section-scoping: stray `[rationale:]` tags OUTSIDE `## Pack memory` (in the synthetic header/tail sections) are excluded → in-section 1==1 stays balanced, 0 failures.
  - **T5 FAIL** — both directions orphaned simultaneously (`corpus-only` slug + `rationale-only` heading) → ≥2 distinct failures.
- **Group 2** — end-to-end `validate-pack.py` exit-status on real HEAD: exits 0 and Check 45 reports the bijection holds (the 18==18 live tree).

---

## 3. CI wiring (Check 42 stays green)

Added to `.github/workflows/validate-pack.yml` after the Check 43 test step:

```yaml
      - name: validate-pack Check 45 tests (BD-196, pack-memory rule↔rationale bijection)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-45.sh
```

Check 42 (CI-wiring guard) now sees **11 per-check test files on disk; 11 workflow invocations; zero unwired** (was 10/10 before C3) — green.

New-check wiring discipline (Check 42 enforces) — all four present in this commit: (a) function `check_pack_memory_rationale_bijection`; (b) `main()` callsite; (c) per-check test `test-validate-pack-check-45.sh`; (d) CI-workflow wiring line.

---

## 4. Verification evidence (all PASS at HEAD `b988885`)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **exit 0 — PASSED, all checks clean** |
| Check 45 line | `OK: Check 45 — 18 corpus [rationale: slug] pointer(s); 18 rationale ## <slug> section(s); sets are equal (bijection holds, no orphans in either direction).` |
| Check 42 line | `OK: Check 42 — 11 per-check test file(s) on disk; 11 workflow invocation(s) found; zero unwired tests.` |
| `bash scripts/tests/test-validate-pack-check-45.sh` | **3 PASS / 0 FAIL — All tests passed** |
| `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` (shared set-compare pattern) | **65 PASS / 0 FAIL** |
| `bash scripts/tests/test-validate-pack-check-42.sh` (CI-wiring guard) | **4 PASS / 0 FAIL** |
| `bash scripts/tests/test-validate-pack-check-43.sh` (Check 43 leak-sweep; scripts/ touched) | **7 PASS / 0 FAIL** |

**Working-state confirmation:** Check 45 PASSES at HEAD (18==18) — wired against the clean tree from C2, per the load-bearing working-state rule. No force needed.

**Check 43 (V11 leak-sweep / pack-project boundary):** PASS — confirmed because the commit touches `scripts/`.

---

## 5. Files changed (inventory)

| Path | Change | Delta |
|---|---|---|
| `scripts/validate-pack.py` | modified (added Check 45 function + `main()` callsite via targeted Edits; no rewrite) | +126 |
| `.github/workflows/validate-pack.yml` | modified (1 per-check-test step added) | +3 |
| `scripts/tests/test-validate-pack-check-45.sh` | **new** (full contents in §7) | +269 |

`git diff --stat` confirms exactly these three files; `git status --short` shows `M validate-pack.py`, `M validate-pack.yml`, `?? test-validate-pack-check-45.sh`. No other files touched. Re-read of the diff confirms only the Check 45 function + callsite landed in `validate-pack.py` (no incidental edits).

---

## 6. Notes / deviations / manifest

- **Manifest regen is Pack Chat's at commit.** This commit touches `scripts/` (a v11-surface trigger dir). Per the standing rule, the coder does NOT run `test-fixtures/build.sh` or stage `manifest.txt` — that is Pack Chat's at commit time. (Per plan §5, `pack-ops/`/`scripts/` non-installed test+validator edits typically yield an empty manifest diff, but the rebuild+stage-if-diff discipline is Pack Chat's.)
- **Plan deviations:** ZERO. C3 implemented exactly as specified (Check 45, function + callsite + test + CI wiring; ID 45; Check 32 pattern; §5.2 bijection over the present `[rationale:]` set).
- **New POQs:** none.
- **Boundary discipline:** no project-side files touched (all edits are pack-side: `scripts/`, `.github/workflows/`). No pack-only reference added to any project-shipped surface. N/A — no project-side edit in scope.
- **Trinity:** N/A (validator / test / CI only — plan §3 C3 row: "Trinity: no").

---

## 7. Full contents of new file `scripts/tests/test-validate-pack-check-45.sh`

```bash
#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-45.sh — synthetic fixture
# tests for BD-196 (C3) Check 45 (pack-memory rule↔rationale
# bijection; ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §5.2).
#
# These tests exercise the set-equality bijection between the corpus
# `## Pack memory` `[rationale: slug]` set (CLAUDE.md representative)
# and the `## <slug>` heading set in pack-ops/PACK-MEMORY-RATIONALE.md,
# without mutating any real CLAUDE.md / pack-ops file. Each end-to-end
# test stages a synthetic CLAUDE.md + PACK-MEMORY-RATIONALE.md inside a
# tmp REPO_ROOT, invokes Check 45 against the tmp tree, and asserts
# PASS / FAIL as expected. Cleanup runs on every exit path.
#
# Coverage:
#   Group 0: Module import + Check 45 symbol registration
#   Group 1: Synthetic-tree end-to-end (PASS + injected-FAIL cases)
#   Group 2: End-to-end validate-pack.py exit-status on HEAD (18==18)
#
# Usage: bash scripts/tests/test-validate-pack-check-45.sh

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

# Group 0: Module import + new symbol reachable
printf "\n=== Group 0: Module import + Check 45 symbol registration ===\n"
python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_pack_memory_rationale_bijection']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check45-import.out 2>&1
if grep -q "^OK$" /tmp/vp-check45-import.out; then
    t_pass "validate-pack.py imports + Check 45 symbol registered"
else
    t_fail "validate-pack.py import or Check 45 symbol registration failed" \
        "$(cat /tmp/vp-check45-import.out)"
fi

# Group 1: Synthetic-tree end-to-end (PASS + injected-FAIL cases)
# [T1 balanced PASS; T2 orphan corpus slug FAIL; T3 orphan rationale
#  heading FAIL; T4 section-scoping PASS (out-of-section tags ignored);
#  T5 both-direction orphans FAIL >=2]. Harness monkeypatches
#  mod.REPO_ROOT to a tmp tree, clears/restores mod.failures, captures
#  stdout, rmtree on every exit. (Full Python heredoc body shipped in
#  the working-tree file.)

# Group 2: End-to-end validate-pack.py exit-status on HEAD (18==18)
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"
if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check45-e2e.out 2>&1; then
    if grep -q "Check 45: pack-memory rule↔rationale bijection" /tmp/vp-check45-e2e.out \
       && grep -q "Check 45 — .* corpus .* pointer(s); .* rationale .* section(s); sets are equal" /tmp/vp-check45-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 45 runs and reports the bijection holds at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 45 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check45-e2e.out)"
    fi
else
    if grep -q "Check 45: pack-memory rule↔rationale bijection" /tmp/vp-check45-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 45 ran but found a bijection orphan)" \
            "Tail: $(tail -40 /tmp/vp-check45-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 45 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check45-e2e.out)"
    fi
fi

# Summary
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

> NOTE: §7 above is an ABRIDGED transcription (the Group 1 Python heredoc body — the `run_check_with_synthetic` helper + the T1–T5 synthetic-tree fixtures — is collapsed to a comment for report concision). The COMPLETE file (269 lines, all five T-cases fully expanded) is on disk at `scripts/tests/test-validate-pack-check-45.sh` and is what was verified (3 PASS / 0 FAIL). For exact re-apply, read the on-disk file.

---

## 8. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit | Ran only read-only git (`rev-parse`, `status --short`, `diff --stat`, `diff`); no add/commit/push. Deliverable = working-tree edits + this IMPL-REPORT. | COMPLIANT |
| Edit in place — targeted Edits, not rewrite | `validate-pack.py` modified via two targeted Edits (function before `# ── Main ──`; callsite after Check 42). `git diff --stat` = `+126` insertions, 0 deletions; re-read confirms only the additions landed. | COMPLIANT |
| New-check wiring discipline (Check 42) | All four present: function (L6051), `main()` callsite (L6288), test `test-validate-pack-check-45.sh`, CI line in `validate-pack.yml`. Check 42 reports 11/11 wired, zero unwired. | COMPLIANT |
| Working-state (Check 45 passes at HEAD) | `python3 scripts/validate-pack.py` exit 0; Check 45 line: `18 corpus pointer(s); 18 rationale section(s); sets are equal (bijection holds)`. Wired against clean tree; not forced. | COMPLIANT |
| Verification before PREFLIGHT | Full suite PASS (exit 0); test-45 3/0; 32-33-34 65/0; Check 42 test 4/0; Check 43 test 7/0. All run before PREFLIGHT line. | COMPLIANT |
| PREFLIGHT before IMPL-REPORT | Emitted `PREFLIGHT: 3/3 ... verification PASS; HEAD b988885; about to Write IMPL-REPORT ...` immediately before this Write. | COMPLIANT |
| Manifest regen is Pack Chat's | Did NOT run `build.sh` or stage `manifest.txt`; documented as Pack Chat's at-commit obligation (§6). | COMPLIANT |
| verification-harness skill (test-script shape) | test-45 mirrors test-43: header, fixtures via tmp REPO_ROOT, per-case PASS/FAIL lines, summary, exit code; bash 3.2 / BSD-utils portable (`(( FAIL == 0 ))`, `printf`, `grep`, no GNU-only flags). | COMPLIANT |
| STOP-MEANS-STOP | No parent stop/halt/revert message received; work proceeded to completion. | N/A: no stop signal |
| Prison rule | Did not read/cite/trust `maintenance-docs/prison/`. | COMPLIANT |
| Trinity rule | No trinity file (CLAUDE/AGENTS/GEMINI at either location) touched — validator/test/CI only (plan §3 C3 "Trinity: no"). | N/A: no trinity edit |
| Boundary discipline (P-missed-7) | No project-side (`project-template/`/`supporting-docs/`) file touched; no pack-only reference added to a project surface. | N/A: pack-side only |
| No destructive ops | No `rm -rf`, `git rm`, overwrite of trusted files. New file created; two existing files Edited (Read first). | COMPLIANT |
| Output ends with Rules-Applied Verification Block | This block. | COMPLIANT |

---

**End of IMPLEMENTATION-REPORT-BD-196-C3.md.**
