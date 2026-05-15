# IMPLEMENTATION-REPORT-SIDECAR-LIFECYCLE-FIX

**Author:** pack-coder (implementation pass)
**Date:** 2026-05-15
**Worktree branch:** v11-dev
**Pre-edit HEAD:** `8ba18b21876e2bd0cbb03195d4416d9c4acea6ae`
**Post-edit HEAD (working tree only):** `8ba18b21876e2bd0cbb03195d4416d9c4acea6ae` — no commits made (per pack rule: agents never commit)
**Architecture input:** `maintenance-docs/v11-implementation/ARCHITECTURE-SIDECAR-LIFECYCLE.md` (838 lines, all 8 sections)
**Implementation strategy:** Option (e) full extraction (per Pack Chat override; subsumes option (d) modified)

---

## 1. Summary

Resolved the BD-095 / BD-101 collision that turned CI red on commit
`8ba18b2` by extracting the per-sidecar resolution-classification predicate
into a single shared helper (`checkpoint_classify_sidecar`) and routing
both Gate 2's `checkpoint_check_no_orphan_sidecars` (C3, BD-101 territory)
AND `_v10_v11_resume_classify_sidecars` (C2, BD-095 territory) through it.
This is the option (e) extraction recommended in
`ARCHITECTURE-SIDECAR-LIFECYCLE.md` §6.5 and now authorized as a single
coherent fix per Pack Chat's override.

The architectural payoff: the two views of the same predicate ("is sidecar
X resolved?") now share one source of truth. Future BD-095/BD-101
contract changes only need to touch the classifier; both call sites
inherit the change.

The CI-red artifacts (`scripts/tests/test-migrate-v10-to-v11-dry-run.sh`
test 4.1 + `scripts/persona-contracts/contract-migration.sh`) now PASS
unchanged. The status tokens emitted by `_v10_v11_resume_classify_sidecars`
(`resolved-flag` / `resolved-removed` / `unresolved`) are byte-identical
pre/post-extraction; downstream awk consumers at resume.sh:143-153 are
unaffected.

---

## 2. Per-edit detail

### 2.1 Edit 1 — `scripts/lib/migrate-v10-to-v11/checkpoint.sh`

**Change type:** Modified (added one new public helper + rewrote one existing helper body).

**Symbols affected:**
- NEW: `checkpoint_classify_sidecar` (public; pure read-only; one of `resolved-flag` / `resolved-removed` / `unresolved` / `unknown`).
- MODIFIED: `checkpoint_check_no_orphan_sidecars` (header comment + body; delegates per-candidate classification to `checkpoint_classify_sidecar`).

**Before (the relevant pre-fix function — lines 275-312, header + body):**

```bash
# ── checkpoint_check_no_orphan_sidecars ──────────────────────────────────
#
# MINOR-3 (BD-101 retro fix): Gate 2 should observe zero own-suffix
# sidecar files at the project root. The migrator's --resume precondition
# already gates this for sidecars listed in stage-S3.paused; this check
# catches the residual class (sidecars left behind after manual resolve,
# sidecars from a different stage, etc.) so the truth-oracle banner
# accurately reflects "this client install is consistent post-Phase-A".

checkpoint_check_no_orphan_sidecars() {
    local target="${1:-}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        printf '  [FAIL] sidecars: target dir missing (%s)\n' "$target"
        return 1
    fi
    local suffix="${MIGRATOR_OWN_SIDECAR_SUFFIX:-}"
    if [[ -z "$suffix" ]]; then
        printf '  [INFO] sidecars: MIGRATOR_OWN_SIDECAR_SUFFIX unset; skipping orphan-sidecar check\n'
        return 0
    fi
    local orphans
    orphans=$(find "$target" -type f -name "*.${suffix}" \
        -not -path '*/.pack-migrate-*' \
        -not -path '*/.git/*' \
        2>/dev/null | head -10)
    if [[ -n "$orphans" ]]; then
        printf '  [FAIL] sidecars: orphan *.%s file(s) at target  → Run: resolve and rm each listed sidecar\n' "$suffix"
        printf '%s\n' "$orphans" | sed 's|^|         |'
        return 1
    fi
    printf '  [OK]   sidecars: no orphan *.%s files at target\n' "$suffix"
    return 0
}
```

**After (relevant post-fix region — adds `checkpoint_classify_sidecar` ABOVE the orphan-sidecar check, then rewrites the orphan check body):**

```bash
# ── checkpoint_classify_sidecar ──────────────────────────────────────────
#
# Single source of truth for "is this sidecar resolved?" semantics per
# the BD-095 contract (see resume.sh:38-57 + ARCHITECTURE-SIDECAR-LIFECYCLE.md
# §3). Both Gate 2's orphan-sidecar check (C3) and resume.sh's precondition
# scanner (C2) classify sidecars through this helper so they can never
# diverge on the BD-095 two-signal `.resolved` / removed contract.
#
# Returns one of (echoed to stdout, single token + newline):
#   resolved-flag    — sidecar present AND companion `<sidecar>.resolved` exists
#   resolved-removed — sidecar absent (user merged + rm'd, OR accepted pack
#                      default + rm'd) — state (d)/(e)
#   unresolved       — sidecar present, no `.resolved` companion — state (b)
#   unknown          — empty / missing arg; returns 1 (caller error)
#
# Pure read-only. Caller decides what counts as orphan / FAIL.
checkpoint_classify_sidecar() {
    local sidecar="${1:-}"
    if [[ -z "$sidecar" ]]; then
        printf 'unknown\n'
        return 1
    fi
    if [[ -f "${sidecar}.resolved" ]]; then
        printf 'resolved-flag\n'
    elif [[ ! -f "$sidecar" ]]; then
        printf 'resolved-removed\n'
    else
        printf 'unresolved\n'
    fi
    return 0
}

# ── checkpoint_check_no_orphan_sidecars ──────────────────────────────────
#
# MINOR-3 (BD-101 retro fix), updated per
# maintenance-docs/v11-implementation/ARCHITECTURE-SIDECAR-LIFECYCLE.md
# §6: Gate 2 should observe zero UNRESOLVED own-suffix sidecar files at
# the project root. The BD-095 contract (resume.sh:38-57) accepts TWO
# resolution signals: (a) companion `<sidecar>.resolved` flag-file, and
# (b) sidecar absence (user merged + `rm`'d). A sidecar in state (c)
# "flagged-resolved" — present on disk WITH a `.resolved` companion —
# is legitimate audit-trail residue and MUST NOT be counted as orphan.
#
# Classification is delegated to `checkpoint_classify_sidecar` so this
# helper and resume.sh's `_v10_v11_resume_classify_sidecars` (C2) share
# one source of truth (option (e) in ARCHITECTURE-SIDECAR-LIFECYCLE.md
# §6.5).
#
# What this catches that other Gate 2 checks don't:
#   - M3-α (cross-execution forgot-to-remove): sidecar present, no
#     `.resolved` companion, no `stage-S3.paused` guard active because
#     a later run wiped state-dir or completed.
#   - M3-β (unknown-lineage stragglers): sidecar matching this
#     migrator's suffix at any path under target.
#
# Lifecycle states (§1):
#   (b) created     → sidecar present, no .resolved → UNRESOLVED → FAIL
#   (c) flagged     → sidecar present + .resolved   → RESOLVED   → OK
#   (d)/(e) absent  → sidecar gone                  → RESOLVED   → not seen by find

checkpoint_check_no_orphan_sidecars() {
    local target="${1:-}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        printf '  [FAIL] sidecars: target dir missing (%s)\n' "$target"
        return 1
    fi
    local suffix="${MIGRATOR_OWN_SIDECAR_SUFFIX:-}"
    if [[ -z "$suffix" ]]; then
        printf '  [INFO] sidecars: MIGRATOR_OWN_SIDECAR_SUFFIX unset; skipping orphan-sidecar check\n'
        return 0
    fi
    local candidates
    candidates=$(find "$target" -type f -name "*.${suffix}" \
        -not -path '*/.pack-migrate-*' \
        -not -path '*/.git/*' \
        2>/dev/null)
    if [[ -z "$candidates" ]]; then
        printf '  [OK]   sidecars: no *.%s files at target\n' "$suffix"
        return 0
    fi
    local s status orphans=()
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        status=$(checkpoint_classify_sidecar "$s")
        if [[ "$status" == "unresolved" ]]; then
            orphans+=("$s")
        fi
    done <<< "$candidates"
    if (( ${#orphans[@]} > 0 )); then
        printf '  [FAIL] sidecars: %d unresolved *.%s file(s) at target  → Run: resolve and rm each listed sidecar (or touch <sidecar>.resolved if accepting pack default)\n' \
            "${#orphans[@]}" "$suffix"
        printf '         %s\n' "${orphans[@]:0:10}"
        return 1
    fi
    printf '  [OK]   sidecars: no unresolved *.%s files at target (resolved-via-flag sidecars present are OK)\n' "$suffix"
    return 0
}
```

**Behavior table (architect §7.3, holds for the new code):**

| Tree state | candidates result | orphans array | Outcome |
|---|---|---|---|
| No `*.v10-customized` files | empty | `[]` | `[OK] no *.v10-customized files at target` |
| 3 files, all with `.resolved` companions (state (c)) | 3 paths | `[]` | `[OK] no unresolved *.v10-customized files at target (resolved-via-flag sidecars present are OK)` |
| 3 files, none with companions (state (b)) | 3 paths | 3 paths | `[FAIL] 3 unresolved *.v10-customized file(s)` |
| 3 files, 2 flagged + 1 not | 3 paths | 1 path | `[FAIL] 1 unresolved *.v10-customized file(s)` |

All four rows verified by tests 2.6 / 2.5e / 2.5c / 2.5d (in that order)
in §4 below.

**Line delta:** +71 lines (32 new for `checkpoint_classify_sidecar`, 39
net for the rewritten `checkpoint_check_no_orphan_sidecars` header +
body) / -38 lines (the original `checkpoint_check_no_orphan_sidecars`
and its 8-line header were replaced).

### 2.2 Edit 2 — `scripts/lib/migrate-v10-to-v11/resume.sh`

**Change type:** Modified (rewrote `_v10_v11_resume_classify_sidecars`
body to delegate; added defense-in-depth source guard for
`checkpoint.sh`).

**Symbol affected:** `_v10_v11_resume_classify_sidecars` (private;
signature + caller-contract unchanged; body shrunk to a thin loop wrapper).

**Before (lines 38-57):**

```bash
_v10_v11_resume_classify_sidecars() {
    local paused="$1"
    local s status
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        if [[ -f "${s}.resolved" ]]; then
            status="resolved-flag"
        elif [[ ! -f "$s" ]]; then
            status="resolved-removed"
        else
            status="unresolved"
        fi
        printf '%s\t%s\n' "$status" "$s"
    done < "$paused"
}
```

**After:**

```bash
# Per ARCHITECTURE-SIDECAR-LIFECYCLE.md §6.5 (option (e) extraction), the
# per-sidecar classification logic lives in `checkpoint_classify_sidecar`
# (scripts/lib/migrate-v10-to-v11/checkpoint.sh). This helper is a thin
# loop wrapper that forwards each input row to the shared classifier so
# Gate 2's C3 (orphan-sidecar) and the resume.sh C2 precondition can never
# diverge on the BD-095 two-signal `.resolved` / removed contract. The
# emitted status tokens (`resolved-flag` / `resolved-removed` /
# `unresolved`) are unchanged; downstream consumers at line ~143 below
# depend on those exact strings.
_v10_v11_resume_classify_sidecars() {
    local paused="$1"
    # Defense-in-depth: under the v10→v11 adapter, checkpoint.sh is
    # always sourced before this function is called (see
    # scripts/migrate-v10-to-v11.sh:629 + 634); but if a future test
    # harness or direct-source scenario invokes resume.sh in isolation,
    # source the classifier on demand. Mirrors the gate-2-phase-a-verify.sh
    # idiom.
    if ! declare -F checkpoint_classify_sidecar >/dev/null 2>&1; then
        local _resume_dir
        _resume_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # shellcheck source=checkpoint.sh disable=SC1091
        . "$_resume_dir/checkpoint.sh"
    fi
    local s status
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        status=$(checkpoint_classify_sidecar "$s")
        printf '%s\t%s\n' "$status" "$s"
    done < "$paused"
}
```

**Caller / contract preservation:** the single caller at resume.sh:138
(`classification=$(_v10_v11_resume_classify_sidecars "$paused")`) and the
downstream awk-matchers at resume.sh:143-153 (which match `unresolved` /
`!= "unresolved" && != ""`) are byte-identical pre/post-edit. The
emitted format `<status>\t<sidecar>` per row is preserved exactly.

**Source-chain verification (per the prompt requirement):**
`scripts/migrate-v10-to-v11.sh:629` sources `resume.sh`, then line 634
sources `checkpoint.sh` — both at script-load time, before any function
is CALLED. By the time `migrate_v10_to_v11_resume_run` invokes
`_v10_v11_resume_classify_sidecars`, `checkpoint_classify_sidecar` is
already defined. The defense-in-depth source guard added inside the
function is for future direct-source / test-harness scenarios; under
normal `migrate-v10-to-v11.sh` invocation the guard's predicate is
always false (function exists) and the source is skipped.

**Line delta:** +18 lines (10 of comment context + 8 of source guard) /
-7 lines (removed inline if/elif/else block).

### 2.3 Edit 3 — `scripts/tests/test-migrate-v10-to-v11-gates.sh`

**Change type:** Modified (added 21 new assertions; tightened 1 existing
assertion).

**Edits:**

1. **Tightened existing case 2.6 assertion** (line 295 old wording vs new
wording per architect §8.2 final paragraph). The pre-fix assertion
matched the substring `[OK]   sidecars: no orphan` which DOES NOT appear
in the new [OK] line wording. Updated to match
`[OK]   sidecars: no *.v10-customized files at target` (the
no-candidates branch — applicable here because the post-apply tree has
no sidecars). This is consistent with the architect's note that the OK
line wording shifted.

2. **Added cases 2.5b / 2.5c / 2.5d / 2.5e** per architect §8.2 (Gate 2
integration tests against synthetic sidecar fixtures):
   - 2.5b: sidecar present + `.resolved` companion → `[OK]` line, rc=0,
     no `[FAIL] sidecars` substring
   - 2.5c: sidecar present + NO `.resolved` companion → `[FAIL] sidecars: 1 unresolved *.v10-customized file(s)`, rc=31
   - 2.5d: two sidecars, one flagged + one not → `[FAIL] sidecars: 1 unresolved`, rc=31, names only the unresolved one
   - 2.5e: three sidecars, all flagged → `[OK]` line (resolved-via-flag), rc=0

3. **Added cases 2.6b / 2.6c / 2.6d / 2.6e** — direct unit tests for
`checkpoint_classify_sidecar`:
   - 2.6b: sidecar + `.resolved` → echoes `resolved-flag`, rc=0
   - 2.6c: sidecar absent → echoes `resolved-removed`, rc=0
   - 2.6d: sidecar present, no `.resolved` → echoes `unresolved`, rc=0
   - 2.6e: empty arg → echoes `unknown`, rc=1

**Test count delta:**
- Pre-edit: 66 PASS in this file.
- Post-edit: 87 PASS, 0 FAIL — 21 new assertions added (4 new cases × ≈3
  assertions each + the classifier's 4 cases × ≈2 assertions each = 20+,
  matching the actual count).

---

## 3. Files modified inventory

| Path | Change type | Line delta (approx) |
|---|---|---|
| `scripts/lib/migrate-v10-to-v11/checkpoint.sh` | Modified | +71 / -38 |
| `scripts/lib/migrate-v10-to-v11/resume.sh` | Modified | +18 / -7 |
| `scripts/tests/test-migrate-v10-to-v11-gates.sh` | Modified | +94 / -1 (tightened 1 assertion + added 21 assertions across 8 new cases) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-SIDECAR-LIFECYCLE-FIX.md` | NEW | (this report) |

No other files modified. No git state changes.

The architect's deliverable
`maintenance-docs/v11-implementation/ARCHITECTURE-SIDECAR-LIFECYCLE.md`
is untracked (not modified — it was already present pre-task as a
session deliverable; coder did not edit it).

---

## 4. Verification

All commands run from the v11-dev worktree at HEAD `8ba18b2`.

### 4.1 `bash -n` syntax checks

```text
$ bash -n scripts/lib/migrate-v10-to-v11/checkpoint.sh && echo OK
OK
$ bash -n scripts/lib/migrate-v10-to-v11/resume.sh && echo OK
OK
$ bash -n scripts/tests/test-migrate-v10-to-v11-gates.sh && echo OK
OK
```

All three files: clean.

### 4.2 `scripts/tests/test-migrate-v10-to-v11-gates.sh`

```text
=== Summary ===
Passed: 87
Failed: 0
All BD-101 gate tests passed.
```

Selected per-case lines (full output captured during run; abridged
here for the new cases):

```text
PASS 2.5 Gate 2 FAIL orphan-sidecar rc=31              ← existing, holds
PASS 2.5 Gate 2 names sidecars FAIL                    ← existing, holds
PASS 2.5 Gate 2 names the orphan file                  ← existing, holds
PASS 2.6 Gate 2 PASS no-orphan-sidecars rc=0           ← existing, holds
PASS 2.6 Gate 2 OK sidecars (no candidates)            ← updated wording
PASS 2.5b Gate 2 PASS rc=0 (flagged-resolved sidecar present)
PASS 2.5b Gate 2 OK sidecars (resolved-via-flag OK)
PASS 2.5b Gate 2 does NOT flag the .resolved-companion sidecar
PASS 2.5c Gate 2 FAIL rc=31 (1 unresolved sidecar)
PASS 2.5c Gate 2 names sidecars FAIL
PASS 2.5c Gate 2 names the unresolved file
PASS 2.5d Gate 2 FAIL rc=31 (mix; 1 unresolved)
PASS 2.5d Gate 2 reports precise count = 1
PASS 2.5d Gate 2 names the unresolved one
PASS 2.5d Gate 2 does NOT name the flagged one in the orphan listing
PASS 2.5e Gate 2 PASS rc=0 (3 sidecars all flagged)
PASS 2.5e Gate 2 OK sidecars (resolved-via-flag OK)
PASS 2.5e Gate 2 does NOT FAIL on all-flagged tree

=== Group 2.6 — checkpoint_classify_sidecar (BD-095 contract) ===
PASS 2.6b classifier rc=0 (resolved-flag)
PASS 2.6b classifier echoes 'resolved-flag'
PASS 2.6c classifier rc=0 (resolved-removed)
PASS 2.6c classifier echoes 'resolved-removed'
PASS 2.6d classifier rc=0 (unresolved)
PASS 2.6d classifier echoes 'unresolved'
PASS 2.6e classifier empty-arg rc=1
PASS 2.6e classifier empty-arg echoes 'unknown'
```

Pre-fix baseline: 66 PASS. Post-fix: **87 PASS, 0 FAIL**. The
≥74-PASS target is met (+21 new cases — 13 new Gate 2 wiring assertions
across 2.5b/c/d/e and 8 new classifier-direct assertions across 2.6b/c/d/e).

### 4.3 `scripts/tests/test-migrate-v10-to-v11-dry-run.sh`

```text
PASS 4.1 --resume rc=0 (.resolved signal)              ← was FAIL pre-fix; now PASS
PASS 4.1 --resume completed S6
PASS 4.1 stage-S6.done after --resume

=== Summary ===
Passed: 61
Failed: 0
All BD-095 tests passed.
```

Pre-fix: 60 PASS + 1 FAIL (test 4.1 `--resume rc=0 (.resolved signal)`
returned rc=31 instead of 0 because Gate 2 misclassified the
`.resolved`-flagged sidecars as orphans). Post-fix: **61 PASS, 0 FAIL**.

### 4.4 `scripts/test-persona-contracts.sh` (aggregator)

```text
PASS apply paused at reconciliation gate (3 sidecar(s) — expected)
PASS migrator --resume exit 0 after sidecar reconciliation     ← pre-fix FAIL
... (28 more PASS lines for assertions 2/3/4)
=== migration contract: 30 passed, 0 failed ===

============================================================
Persona contract summary: 3/3 passed
  PASS:
    - contract-greenfield.sh
    - contract-mid-dev.sh
    - contract-migration.sh

All persona contracts PASS.
```

Pre-fix: `contract-migration.sh` failed at the
`migrator --resume exit 0 after sidecar reconciliation` assertion
(rc=31 returned by Gate 2). Post-fix: **3/3 contracts PASS** with the
internal 30/30 PASS for `contract-migration.sh`.

### 4.5 `python3 scripts/validate-pack.py`

```text
... (32 OK check banners)

============================================================
PASSED — all checks clean
```

**32/32 PASS.** No regressions introduced by the source edits.

### 4.6 Status-string preservation (per success criterion)

A focused script sources `checkpoint.sh` + `resume.sh`, builds a
synthetic paused-list with one sidecar in each lifecycle state
(unresolved / flagged / removed), invokes
`_v10_v11_resume_classify_sidecars`, and asserts the emitted tokens.

Output:

```text
── classifier output ──
unresolved	/tmp/.../sidecar-unresolved.v10-customized
resolved-flag	/tmp/.../sidecar-flagged.v10-customized
resolved-removed	/tmp/.../sidecar-removed.v10-customized
────
PASS: status-string preservation — all three tokens
(resolved-flag / resolved-removed / unresolved) emitted byte-identical
to pre-fix.
```

The downstream awk consumer at resume.sh:143-153 (which matches `$1 ==
"unresolved"` and `$1 != "unresolved" && $1 != ""`) sees the same input
shape and the same per-row values pre/post-extraction. C2 contract
preserved.

---

## 5. Out-of-scope items / deviations / POQs

**Deviations from the implementation plan:** zero. All three edits
landed exactly per the prompt's specification, with the option (e)
extraction subsuming option (d) modified per Pack Chat's override.

**Files touched outside the allowed list:** zero.

**Forbidden-file edits attempted:** zero. `BACKLOG.md`, `CHANGELOG.md`,
`apply.sh`, `dry-run.sh`, `gate-2-phase-a-verify.sh`,
`gate-3-phase-b-verify.sh`, `gate-1-dry-run-summary.sh`,
`migrator-core.sh`, `migrate-v10-to-v11.sh`,
`test-migrate-v10-to-v11-dry-run.sh`,
`scripts/persona-contracts/contract-migration.sh`,
`supporting-docs/MIGRATION-v10-to-v11.md`,
`supporting-docs/MERGE-STRATEGY.md`, and the architect's
`ARCHITECTURE-SIDECAR-LIFECYCLE.md` are all unchanged.

**New POQs:** none. The architecture doc had already enumerated the
options exhaustively and option (e) closes the only outstanding question
(the BD-095 / BD-101 territory boundary, which Pack Chat resolved by
authorizing the cross-territory edit).

**No git state changes.** No `git add`, no `git commit`, no `git push`,
no tag operations. Working tree shows three modified files plus one new
file (this report) plus the untracked architect deliverable
`ARCHITECTURE-SIDECAR-LIFECYCLE.md` (which was already present at
session start; coder did not create or modify it).

**Optional architect-§8.3 enhancement deferred:** the architect §8.3
suggested OPTIONALLY adding a back-reference paragraph to
`maintenance-docs/v11-implementation/CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md`
naming the lifecycle states (a)..(e). This was explicitly listed as
"not required for the CI red fix; suggested for documentation
completeness if the doc is touched in a future BD." Coder did not touch
it (out of scope for this fix; the Pack Chat-authorized scope is the
three source edits + report).

---

## 6. Definition-of-Done checklist

| Item | Status |
|---|---|
| Edit 1: `checkpoint_classify_sidecar` added with the documented contract | PASS |
| Edit 1: `checkpoint_check_no_orphan_sidecars` rewritten to call the classifier | PASS |
| Edit 2: `_v10_v11_resume_classify_sidecars` body delegates to `checkpoint_classify_sidecar` | PASS |
| Edit 2: emitted status tokens byte-identical to pre-fix | PASS (verification §4.6) |
| Edit 2: caller at resume.sh:138 + downstream awk consumers untouched and still pass | PASS (test 4.1 + contract-migration.sh both PASS) |
| Edit 3: 2.5b/c/d/e Gate 2 wiring cases added | PASS (4 cases, 13 assertions) |
| Edit 3: 2.6b/c/d/e classifier-direct unit cases added | PASS (4 cases, 8 assertions) |
| Edit 3: existing case 2.6 wording assertion updated | PASS (now matches `[OK]   sidecars: no *.v10-customized files at target`) |
| `bash -n` clean on checkpoint.sh / resume.sh / test-migrate-v10-to-v11-gates.sh | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` ≥ 74 PASS | PASS (87/0) |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` ≥ 61 PASS, test 4.1 PASS | PASS (61/0) |
| `bash scripts/test-persona-contracts.sh` 3/3 PASS, contract-migration PASS | PASS |
| `python3 scripts/validate-pack.py` 32/32 PASS | PASS |
| Status-string preservation evidence in report | PASS (§4.6) |
| Behavior table (architect §7.3, 4 rows) holds | PASS (verified by 2.6 / 2.5e / 2.5c / 2.5d) |
| CI-red artifacts (test 4.1 + contract-migration.sh) PASS unchanged (no edits) | PASS |
| No edits to forbidden files | PASS |
| No git state changes | PASS |
| Implementation report exists at `IMPLEMENTATION-REPORT-SIDECAR-LIFECYCLE-FIX.md` | PASS (this file) |
| Macos bash 3.2 + BSD utils compatibility | PASS (no GNU-only flags; `find ... -not -path` is BSD-portable; `head -10`, `printf`, `[[ -f ... ]]` all bash-3.2-safe; the array `orphans+=(...)` is bash-3.2-safe; `${orphans[@]:0:10}` slice is bash-3.2-safe) |
| Trinity rule (CLAUDE/AGENTS/GEMINI) — N/A; no trinity files touched | N/A |

All DoD items PASS. The fix is complete, verified, and ready for Pack
Chat review + commit.

---

## 7. File paths (absolute, for Pack Chat to apply)

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/checkpoint.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/resume.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-migrate-v10-to-v11-gates.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-SIDECAR-LIFECYCLE-FIX.md`
