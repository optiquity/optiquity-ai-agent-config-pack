#!/usr/bin/env bash
# scripts/tests/test-validate-pack-checks-32-33-34.sh — synthetic-fixture
# test runner for the BD-168 per-entry split validators (Check 32 mirror-
# in-sync, Check 33 TOC-in-sync, Check 34 cross-reference integrity).
#
# Fixture strategy (per planner §18.2 #6 — coder picks placement):
#   - Inline mktemp scratch trees (no separate fixtures dir under
#     `scripts/tests/fixtures/per-entry/`). Fixtures are tiny (3 entries
#     each), and the green/red contrast is best read in-line. Same shape
#     as `test-per-entry.sh` Group 1–11 fixtures.
#   - Each test exercises a SINGLE check function from `validate-pack.py`
#     against a synthetic per-entry tree built under a scratch
#     `REPO_ROOT`. The validator's STREAMS constant is hard-coded for
#     the real pack repo, so we INVOKE the new check functions
#     directly via a small Python wrapper that monkey-patches
#     `REPO_ROOT` + `STREAMS` before calling each `check_*`.
#
# Test groups:
#   Group A: Check 32 (mirror-in-sync) — green + red fixtures.
#     A1: green tree + in-sync mirror → check passes.
#     A2: green tree + hand-edited mirror → check FAILs with the
#         expected "out of sync" message.
#     A3: green tree + missing _rules.md → check FAILs with the
#         expected "_rules.md missing" pre-check message.
#     A4: green tree + non-conforming filename → check FAILs with the
#         expected "non-conforming filenames" pre-check message.
#   Group B: Check 33 (TOC-in-sync) — green + red.
#     B1: green tree + in-sync _toc.md → check passes.
#     B2: green tree + hand-edited _toc.md → check FAILs.
#     B3: green tree + missing _toc.md → check FAILs.
#   Group C: Check 34 (cross-reference integrity) — green + red.
#     C1: green tree + all refs resolve → check passes.
#     C2: green tree + dangling BD-NNN ref → check FAILs with offending
#         file:line + ref name.
#     C3: green tree + ref inside _v8-resolved-archive.md → check
#         passes (archive SKIPed per integration parent §11.3).
#     C4: green tree + self-reference → check passes.
#
# Plus structural smoke:
#   D1: STREAMS constant has the expected pack-side tuples (sanity).
#
# Usage: bash scripts/tests/test-validate-pack-checks-32-33-34.sh
# Exit:  0 if all PASS; 1 on any FAIL.
#
# Architecture:
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md
#     §10.1 (Check 32 contract); §10.2 (Check 33); §10.3 (Check 34);
#     §10.4 (pre-check folding); §10.5 (SKIP behavior); §10.6 (pack-side
#     scope); §11.3 (v8-archive SKIP for cross-refs).
#   maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md
#     §5.6 (BD-168 contract).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE_PY="$REPO_ROOT/scripts/validate-pack.py"
PER_ENTRY_LIB="$REPO_ROOT/scripts/lib/per-entry"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' actual='$3'"; fi
}

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' missing from output: ${2:0:400}"; fi
}

assert_not_contains() {
    if [[ "$2" != *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' should NOT appear in output: ${2:0:400}"; fi
}

# Track per-test scratch dirs for cleanup.
SCRATCH_ROOT=$(mktemp -d -t validate-checks-tests.XXXXXX)
trap 'rm -rf "$SCRATCH_ROOT"' EXIT INT TERM

# Smoke: validate-pack.py exists and is executable Python.
[[ -f "$VALIDATE_PY" ]] || { printf "FATAL: %s not found\n" "$VALIDATE_PY" >&2; exit 1; }
[[ -d "$PER_ENTRY_LIB" ]] || { printf "FATAL: %s not found\n" "$PER_ENTRY_LIB" >&2; exit 1; }

# ─────────────────────────────────────────────────────────────────
# Python wrapper: monkey-patch REPO_ROOT + STREAMS, invoke a single
# check_* function, return its stdout (containing OK / FAIL lines)
# plus the FAIL count.
# ─────────────────────────────────────────────────────────────────
#
# Args: $1 = check function name, $2 = scratch REPO_ROOT, [$3..] = optional
#       extra streams to add to STREAMS (default: pack-backlog only).
# Stdout: validator output (OK / FAIL lines).
# Exit: 0 if zero fails, 1 if any fail (matches the validator's
#       failures-collected semantic).
run_check() {
    local check_name="$1"
    local scratch_repo="$2"
    shift 2
    # Default STREAMS: just pack-backlog (the canonical test stream).
    # Caller may override by passing additional stream tuples after $2
    # in the form "key|dir|mirror|regex" pipe-delimited.
    local extra_streams=("$@")
    PE_TEST_REPO="$scratch_repo" \
    PE_TEST_CHECK="$check_name" \
    PE_TEST_EXTRA_STREAMS="${extra_streams[*]:-}" \
    PE_TEST_VALIDATE_PY="$VALIDATE_PY" \
        python3 - <<'PYEOF'
import importlib.util
import os
import sys
from pathlib import Path

scratch_repo = Path(os.environ["PE_TEST_REPO"]).resolve()
check_name = os.environ["PE_TEST_CHECK"]
extra_str = os.environ.get("PE_TEST_EXTRA_STREAMS", "").strip()
validate_py = os.environ["PE_TEST_VALIDATE_PY"]

# Load validate-pack.py as a module.
spec = importlib.util.spec_from_file_location("validate_pack", validate_py)
vp = importlib.util.module_from_spec(spec)
sys.modules["validate_pack"] = vp
spec.loader.exec_module(vp)

# Monkey-patch: REPO_ROOT → scratch_repo; STREAMS → pack-backlog only
# (or with extras parsed from the env var).
vp.REPO_ROOT = scratch_repo
streams = [
    ("pack-backlog", "backlog", "BACKLOG.md", r"^BD-\d+\.md$"),
]
if extra_str:
    for tup in extra_str.split():
        parts = tup.split("|")
        if len(parts) == 4:
            streams.append((parts[0], parts[1], parts[2], parts[3]))
vp.STREAMS = streams
vp.failures = []

check_fn = getattr(vp, check_name)
check_fn()

# Match the validator's exit semantic: 0 if zero fails, 1 if any.
sys.exit(1 if vp.failures else 0)
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Fixture builder helpers
# ─────────────────────────────────────────────────────────────────

# Materialize a green pack-backlog per-entry tree under <scratch_repo>:
#   <scratch_repo>/backlog/_rules.md
#   <scratch_repo>/backlog/_intro.md
#   <scratch_repo>/backlog/_v8-resolved-archive.md
#   <scratch_repo>/backlog/BD-100.md, BD-101.md, BD-102.md
#   <scratch_repo>/BACKLOG.md  (regenerated mirror)
#   <scratch_repo>/backlog/_toc.md  (regenerated TOC)
# All files use the BD-164 helpers so the on-disk shape is what the
# helpers emit (byte-identical round-trip from the start).
# $1 = scratch_repo path
build_green_pack_backlog() {
    local scratch_repo="$1"
    local backlog_dir="$scratch_repo/backlog"
    mkdir -p "$backlog_dir"

    # _rules.md (declares supporting files).
    cat >"$backlog_dir/_rules.md" <<'EOF'
# Per-stream contract — pack-backlog (test fixture)

Stream identity: pack-backlog
Filename convention: ^BD-\d+\.md$
Lifecycle states: Open, Resolved

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
- `_v8-resolved-archive.md`
EOF

    # _intro.md (preamble).
    cat >"$backlog_dir/_intro.md" <<'EOF'
# Backlog (test fixture)

Test-fixture preamble.

---

## Active — v11 Scope
EOF

    # _v8-resolved-archive.md (frozen-historical block; contains a
    # historical reference to BD-999 which does NOT exist in the
    # current tree — exercises Check 34 §11.3 SKIP path).
    cat >"$backlog_dir/_v8-resolved-archive.md" <<'EOF'
## Resolved — v8 (March 2026)

- v8.0 — Initial release. See BD-999 (historical, not in current tree).
EOF

    # Three entry files. BD-100 references BD-101 (defined); BD-101
    # has a self-reference; BD-102 references the v11.0 changelog
    # entry which is OUT OF SCOPE here (single-stream test) so it
    # would be flagged unless we exercise multi-stream fixture (C1
    # uses single-stream so we omit cross-stream refs from BD-102).
    cat >"$backlog_dir/BD-100.md" <<'EOF'
<!-- per-entry source: /backlog/BD-100.md; contract: /backlog/_rules.md -->
**BD-100 — Sample first entry**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: BD-101
File/Symbol: `scripts/example.sh`
Description: First sample entry. References BD-101 in body.
EOF
    cat >"$backlog_dir/BD-101.md" <<'EOF'
<!-- per-entry source: /backlog/BD-101.md; contract: /backlog/_rules.md -->
**BD-101 — Sample second entry**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: `scripts/another.sh`
Description: Second entry. Self-reference to BD-101 in body.
Resolved: 2026-05-13 — see BD-100 for context.
EOF
    cat >"$backlog_dir/BD-102.md" <<'EOF'
<!-- per-entry source: /backlog/BD-102.md; contract: /backlog/_rules.md -->
**BD-102 — Sample third entry**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: n/a
Description: Third entry; references BD-100 in body.
EOF

    # Generate the canonical BACKLOG.md mirror via the BD-164 helper.
    bash -c "
        . '$PER_ENTRY_LIB/_lib.sh'
        . '$PER_ENTRY_LIB/mirror-generate.sh'
        per_entry_regenerate_mirror pack-backlog '$backlog_dir' '$scratch_repo/BACKLOG.md'
    " >/dev/null 2>&1

    # Generate the canonical _toc.md via the BD-164 helper.
    bash -c "
        . '$PER_ENTRY_LIB/_lib.sh'
        . '$PER_ENTRY_LIB/toc-regenerate.sh'
        per_entry_regenerate_toc pack-backlog '$backlog_dir'
    " >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────
# Group D: structural smoke (STREAMS constant binding)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group D: structural smoke (STREAMS constant) ===\n"

D1_OUT=$(PE_TEST_VALIDATE_PY="$VALIDATE_PY" python3 - <<'PYEOF'
import importlib.util
import os
import sys

spec = importlib.util.spec_from_file_location("validate_pack", os.environ["PE_TEST_VALIDATE_PY"])
vp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vp)

# Verify shape: list of 4-tuples; pack-backlog and pack-changelog
# present per integration parent §10.6 pack-side scope.
keys = [s[0] for s in vp.STREAMS]
print(f"keys={keys}")
print(f"len={len(vp.STREAMS)}")
print(f"tuple_lens={[len(s) for s in vp.STREAMS]}")
PYEOF
)
assert_contains "D1.1 STREAMS includes pack-backlog" "$D1_OUT" "pack-backlog"
assert_contains "D1.2 STREAMS includes pack-changelog" "$D1_OUT" "pack-changelog"
assert_contains "D1.3 STREAMS tuples are 4-tuples" "$D1_OUT" "tuple_lens=[4, 4]"

# ─────────────────────────────────────────────────────────────────
# Group A: Check 32 (mirror-in-sync) — green + red
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group A: Check 32 (mirror-in-sync) ===\n"

# A1: green tree + in-sync mirror → check passes.
A1_REPO="$SCRATCH_ROOT/A1"
mkdir -p "$A1_REPO"
build_green_pack_backlog "$A1_REPO"
A1_OUT=$(run_check check_mirror_in_sync "$A1_REPO" 2>&1)
A1_RC=$?
assert_eq "A1.1 in-sync mirror → check rc=0" "0" "$A1_RC"
assert_contains "A1.2 in-sync mirror → OK byte-identical" "$A1_OUT" "byte-identical"
assert_not_contains "A1.3 in-sync mirror → no FAIL" "$A1_OUT" "FAIL:"

# A2: green tree + hand-edited mirror → check FAILs.
A2_REPO="$SCRATCH_ROOT/A2"
mkdir -p "$A2_REPO"
build_green_pack_backlog "$A2_REPO"
# Hand-edit the mirror by appending a stray line.
printf '\nROGUE LINE — hand-edited\n' >>"$A2_REPO/BACKLOG.md"
A2_PRE_SHA=$(shasum "$A2_REPO/BACKLOG.md" | awk '{print $1}')
A2_OUT=$(run_check check_mirror_in_sync "$A2_REPO" 2>&1)
A2_RC=$?
A2_POST_SHA=$(shasum "$A2_REPO/BACKLOG.md" | awk '{print $1}')
assert_eq "A2.1 hand-edited mirror → check rc=1" "1" "$A2_RC"
assert_contains "A2.2 hand-edited mirror → FAIL out-of-sync" "$A2_OUT" "out of sync"
assert_contains "A2.3 hand-edited mirror → FAIL names regenerator" "$A2_OUT" "per_entry_regenerate_mirror"
assert_eq "A2.4 hand-edited mirror → working-tree restored to pre-check state" "$A2_PRE_SHA" "$A2_POST_SHA"

# A3: green tree + missing _rules.md → check FAILs (pre-check a).
A3_REPO="$SCRATCH_ROOT/A3"
mkdir -p "$A3_REPO"
build_green_pack_backlog "$A3_REPO"
rm "$A3_REPO/backlog/_rules.md"
A3_OUT=$(run_check check_mirror_in_sync "$A3_REPO" 2>&1)
A3_RC=$?
assert_eq "A3.1 missing _rules.md → check rc=1" "1" "$A3_RC"
assert_contains "A3.2 missing _rules.md → FAIL names _rules.md" "$A3_OUT" "_rules.md missing"

# A4: green tree + non-conforming filename → check FAILs (pre-check b).
A4_REPO="$SCRATCH_ROOT/A4"
mkdir -p "$A4_REPO"
build_green_pack_backlog "$A4_REPO"
# Add a stray non-conforming file (neither matches BD-NNN.md nor a known
# supporting basename).
printf 'rogue\n' >"$A4_REPO/backlog/ROGUE-FILE.md"
A4_OUT=$(run_check check_mirror_in_sync "$A4_REPO" 2>&1)
A4_RC=$?
assert_eq "A4.1 non-conforming filename → check rc=1" "1" "$A4_RC"
assert_contains "A4.2 non-conforming filename → FAIL names the file" "$A4_OUT" "ROGUE-FILE.md"
assert_contains "A4.3 non-conforming filename → FAIL says non-conforming" "$A4_OUT" "non-conforming filenames"

# A5 (folded pre-check c): hand-edit the v8 archive content → mirror
# divergence catches it (per integration parent §10.4 — c folds into
# the main divergence check).
A5_REPO="$SCRATCH_ROOT/A5"
mkdir -p "$A5_REPO"
build_green_pack_backlog "$A5_REPO"
# Edit the v8 archive (frozen-historical block); mirror regenerator
# would re-emit the new content; on-disk mirror is unchanged → divergence.
printf '\nv8-archive hand-edit\n' >>"$A5_REPO/backlog/_v8-resolved-archive.md"
A5_OUT=$(run_check check_mirror_in_sync "$A5_REPO" 2>&1)
A5_RC=$?
assert_eq "A5.1 v8-archive edit → mirror divergence rc=1" "1" "$A5_RC"
assert_contains "A5.2 v8-archive edit → FAIL out-of-sync" "$A5_OUT" "out of sync"

# ─────────────────────────────────────────────────────────────────
# Group B: Check 33 (TOC-in-sync) — green + red
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group B: Check 33 (TOC-in-sync) ===\n"

# B1: green tree + in-sync _toc.md → check passes.
B1_REPO="$SCRATCH_ROOT/B1"
mkdir -p "$B1_REPO"
build_green_pack_backlog "$B1_REPO"
B1_OUT=$(run_check check_toc_in_sync "$B1_REPO" 2>&1)
B1_RC=$?
assert_eq "B1.1 in-sync _toc.md → check rc=0" "0" "$B1_RC"
assert_contains "B1.2 in-sync _toc.md → OK byte-identical" "$B1_OUT" "byte-identical"
assert_not_contains "B1.3 in-sync _toc.md → no FAIL" "$B1_OUT" "FAIL:"

# B2: green tree + hand-edited _toc.md → check FAILs.
B2_REPO="$SCRATCH_ROOT/B2"
mkdir -p "$B2_REPO"
build_green_pack_backlog "$B2_REPO"
printf '\nROGUE TOC LINE\n' >>"$B2_REPO/backlog/_toc.md"
B2_PRE_SHA=$(shasum "$B2_REPO/backlog/_toc.md" | awk '{print $1}')
B2_OUT=$(run_check check_toc_in_sync "$B2_REPO" 2>&1)
B2_RC=$?
B2_POST_SHA=$(shasum "$B2_REPO/backlog/_toc.md" | awk '{print $1}')
assert_eq "B2.1 hand-edited _toc.md → check rc=1" "1" "$B2_RC"
assert_contains "B2.2 hand-edited _toc.md → FAIL out-of-sync" "$B2_OUT" "out of sync"
assert_contains "B2.3 hand-edited _toc.md → FAIL names regenerator" "$B2_OUT" "per_entry_regenerate_toc"
assert_eq "B2.4 hand-edited _toc.md → working-tree restored" "$B2_PRE_SHA" "$B2_POST_SHA"

# B3: green tree + missing _toc.md → check FAILs.
B3_REPO="$SCRATCH_ROOT/B3"
mkdir -p "$B3_REPO"
build_green_pack_backlog "$B3_REPO"
rm "$B3_REPO/backlog/_toc.md"
B3_OUT=$(run_check check_toc_in_sync "$B3_REPO" 2>&1)
B3_RC=$?
assert_eq "B3.1 missing _toc.md → check rc=1" "1" "$B3_RC"
assert_contains "B3.2 missing _toc.md → FAIL says absent" "$B3_OUT" "_toc.md absent"
# Confirm the test runner restored the tree (no _toc.md left behind).
[[ -f "$B3_REPO/backlog/_toc.md" ]] && t_fail "B3.3 _toc.md not restored" "leftover file exists" \
    || t_pass "B3.3 missing _toc.md → tree restored to pre-check state"

# ─────────────────────────────────────────────────────────────────
# Group C: Check 34 (cross-reference integrity) — green + red
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group C: Check 34 (cross-reference integrity) ===\n"

# C1: green tree + all refs resolve → check passes. Self-ref + cross-
# entry refs to BD-100 / BD-101 / BD-102 all defined.
C1_REPO="$SCRATCH_ROOT/C1"
mkdir -p "$C1_REPO"
build_green_pack_backlog "$C1_REPO"
C1_OUT=$(run_check check_cross_reference_integrity "$C1_REPO" 2>&1)
C1_RC=$?
assert_eq "C1.1 all refs resolve → check rc=0" "0" "$C1_RC"
assert_contains "C1.2 all refs resolve → OK summary" "$C1_OUT" "all resolved"
assert_not_contains "C1.3 all refs resolve → no FAIL" "$C1_OUT" "FAIL:"

# C2: green tree + dangling BD-NNN ref → check FAILs.
C2_REPO="$SCRATCH_ROOT/C2"
mkdir -p "$C2_REPO"
build_green_pack_backlog "$C2_REPO"
# Append a dangling reference to a non-existent BD-555.
printf '\nDescription continued: see BD-555 for related context.\n' \
    >>"$C2_REPO/backlog/BD-100.md"
C2_OUT=$(run_check check_cross_reference_integrity "$C2_REPO" 2>&1)
C2_RC=$?
assert_eq "C2.1 dangling BD-555 → check rc=1" "1" "$C2_RC"
assert_contains "C2.2 dangling BD-555 → FAIL names BD-555" "$C2_OUT" "BD-555"
assert_contains "C2.3 dangling BD-555 → FAIL names BD-100.md" "$C2_OUT" "BD-100.md"
assert_contains "C2.4 dangling BD-555 → FAIL says no matching entry file" "$C2_OUT" "no matching entry file found"

# C3: ref inside _v8-resolved-archive.md → check passes (archive
# SKIPed per integration parent §11.3). The fixture's v8 archive
# already contains "BD-999" (which is NOT defined). Confirm no FAIL
# for BD-999 in the green run (already covered by C1 — re-assert here
# explicitly).
C3_REPO="$SCRATCH_ROOT/C3"
mkdir -p "$C3_REPO"
build_green_pack_backlog "$C3_REPO"
C3_OUT=$(run_check check_cross_reference_integrity "$C3_REPO" 2>&1)
C3_RC=$?
assert_eq "C3.1 BD-999 inside v8 archive → check rc=0 (SKIPed)" "0" "$C3_RC"
assert_not_contains "C3.2 BD-999 inside v8 archive → no FAIL for BD-999" "$C3_OUT" "BD-999"

# C4: self-reference → check passes (BD-101 references itself in body;
# already in the green fixture). Re-assert explicitly.
C4_REPO="$SCRATCH_ROOT/C4"
mkdir -p "$C4_REPO"
build_green_pack_backlog "$C4_REPO"
# BD-101.md already says "Self-reference to BD-101 in body" → both
# the regex match AND the self-id are BD-101 → no FAIL expected.
C4_OUT=$(run_check check_cross_reference_integrity "$C4_REPO" 2>&1)
C4_RC=$?
assert_eq "C4.1 BD-101 self-ref → check rc=0" "0" "$C4_RC"
assert_not_contains "C4.2 BD-101 self-ref → no FAIL for self-ref" "$C4_OUT" "references BD-101 — no matching"

# C5: dangling phase-N reference (cross-stream form). phase-N IDs
# belong to project-implementation-plan, which is NOT loaded in the
# pack-side STREAMS (per integration parent §10.6). Append a
# `phase-3` reference inside BD-100.md → since the pack-side STREAMS
# does NOT define `phase-3`, Check 34 reports it as dangling.
# This exercises the §10.6 scope rule from the failure side.
C5_REPO="$SCRATCH_ROOT/C5"
mkdir -p "$C5_REPO"
build_green_pack_backlog "$C5_REPO"
printf '\nDescription continued: aligns with phase-3 milestone.\n' \
    >>"$C5_REPO/backlog/BD-100.md"
C5_OUT=$(run_check check_cross_reference_integrity "$C5_REPO" 2>&1)
C5_RC=$?
assert_eq "C5.1 dangling phase-3 → check rc=1" "1" "$C5_RC"
assert_contains "C5.2 dangling phase-3 → FAIL names phase-3" "$C5_OUT" "phase-3"

# ─────────────────────────────────────────────────────────────────
# Group E: SKIP behavior (per integration parent §10.5)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group E: SKIP behavior (no per-entry tree present) ===\n"

# E1: scratch_repo with NO backlog/ directory → all three checks SKIP
# gracefully (rc=0, "not present" message).
E1_REPO="$SCRATCH_ROOT/E1"
mkdir -p "$E1_REPO"
E1_C32=$(run_check check_mirror_in_sync "$E1_REPO" 2>&1)
E1_C32_RC=$?
assert_eq "E1.1 no tree → Check 32 rc=0 (SKIP)" "0" "$E1_C32_RC"
assert_contains "E1.2 no tree → Check 32 says 'not present'" "$E1_C32" "not present"

E1_C33=$(run_check check_toc_in_sync "$E1_REPO" 2>&1)
E1_C33_RC=$?
assert_eq "E1.3 no tree → Check 33 rc=0 (SKIP)" "0" "$E1_C33_RC"
assert_contains "E1.4 no tree → Check 33 says 'not present'" "$E1_C33" "not present"

E1_C34=$(run_check check_cross_reference_integrity "$E1_REPO" 2>&1)
E1_C34_RC=$?
assert_eq "E1.5 no tree → Check 34 rc=0 (SKIP)" "0" "$E1_C34_RC"
assert_contains "E1.6 no tree → Check 34 says 'no per-entry trees present'" "$E1_C34" "no per-entry trees present"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "PASS: %d\n" "$PASS"
printf "FAIL: %d\n" "$FAIL"

if [[ $FAIL -eq 0 ]]; then
    printf "\nAll BD-168 validate-pack Check 32/33/34 tests PASSED (%d/%d).\n" \
        "$PASS" "$((PASS + FAIL))"
    exit 0
else
    printf "\nFAILED — %d test(s) failed.\n" "$FAIL"
    exit 1
fi
