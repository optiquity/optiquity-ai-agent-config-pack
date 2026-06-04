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
# BD-168 retro fix adds:
#   Group F: pack-changelog stream coverage (S2 — review §2.2 #2).
#     F1: green pack-changelog → Check 32 PASS.
#     F2: green pack-changelog → Check 33 PASS.
#     F3: green pack-changelog → Check 34 PASS (no dangling).
#     F4: hand-edited pack-changelog mirror → Check 32 FAIL.
#     F5: cross-stream union — pack-backlog refs v11.0 in pack-changelog
#         → Check 34 PASS (exercises defined_all union path).
#   Group G: M2 snap-leftover regression (M2 — review §2.1 #2).
#     G1: Check 33 PASS path → no `.per-entry-toc-snap.*` left in stream_dir.
#     G2: Check 33 FAIL path → no `.per-entry-toc-snap.*` left in stream_dir.
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
# (or with extras parsed from the env var). BD-203 A4: the pack-backlog
# entry regex admits the suffix form (`BD-167b.md`).
vp.REPO_ROOT = scratch_repo
streams = [
    ("pack-backlog", "backlog", "BACKLOG.md", r"^BD-\d+[a-z]*\.md$"),
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
Description: Third entry; references BD-100 and the suffix entry BD-167b in body.
EOF
    # BD-203 A4/A15-T2: a suffix-form entry file (`BD-167b.md`) exercising
    # the widened entry regex (`^BD-\d+[a-z]*\.md$`) + the widened Check 34
    # cross-ref token (`BD-\d+[a-z]*`). BD-102 references BD-167b above.
    cat >"$backlog_dir/BD-167b.md" <<'EOF'
<!-- per-entry source: /backlog/BD-167b.md; contract: /backlog/_rules.md -->
**BD-167b — Suffix-form entry**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: n/a
Description: Suffix entry; self-reference BD-167b in body resolves.
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

# Materialize a green pack-changelog per-entry tree under <scratch_repo>:
#   <scratch_repo>/changelog/_rules.md
#   <scratch_repo>/changelog/_intro.md
#   <scratch_repo>/changelog/v11.md, v10.md
#   <scratch_repo>/changelog/_toc.md  (regenerated TOC)
# BD-203 CHANGE 2: per-release granularity — entries match the
# pack-changelog regex `^v\d+\.md$` (one `vN.md` per major release).
# No monolith mirror is emitted (no-mirror SSOT). Two releases exercise
# grouping by major version (BD-164 toc-regenerate axis).
# $1 = scratch_repo path
build_green_pack_changelog() {
    local scratch_repo="$1"
    local changelog_dir="$scratch_repo/changelog"
    mkdir -p "$changelog_dir"

    # _rules.md (declares supporting files; no-mirror statement).
    cat >"$changelog_dir/_rules.md" <<'EOF'
# Per-stream contract — pack-changelog (test fixture)

Stream identity: pack-changelog
Filename convention: ^v\d+\.md$
Lifecycle states: none (versions are immutable post-ship)

The per-entry tree (+ `_toc.md`) is the SOLE source of truth and
readable form. There is no monolithic mirror.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
EOF

    # _intro.md (preamble).
    cat >"$changelog_dir/_intro.md" <<'EOF'
# Changelog (test fixture)

Test-fixture preamble.

---
EOF

    # Two release entries (per-release granularity). v11 carries a nested
    # `### v11.0` subsection inside the release file; v10 is H2-only. The
    # toc-regenerate.sh axis is "version" grouping by major.
    # NB: the nested subsection header deliberately carries NO `vN.M`
    # token (it would be tokenized by Check 34's CROSS_REF_RE as a
    # cross-reference and flagged dangling, since per-release granularity
    # defines `v11`, not `v11.0`). This fixture exercises Check 32′/33/34;
    # nested-subsection-preservation is covered by test-per-entry.sh
    # Group 10.
    cat >"$changelog_dir/v11.md" <<'EOF'
<!-- per-entry source: /changelog/v11.md; contract: /changelog/_rules.md -->
## v11 — May 2026

### Initial release

- Initial v11 release. References BD-100 for context.
EOF
    cat >"$changelog_dir/v10.md" <<'EOF'
<!-- per-entry source: /changelog/v10.md; contract: /changelog/_rules.md -->
## v10 — March 2026

- v10 release (H2-only).
EOF

    # Generate the canonical _toc.md via the BD-164 helper (no mirror —
    # under the no-mirror model `_toc.md` is the readable index).
    bash -c "
        . '$PER_ENTRY_LIB/_lib.sh'
        . '$PER_ENTRY_LIB/toc-regenerate.sh'
        per_entry_regenerate_toc pack-changelog '$changelog_dir'
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
# Group A: Check 32′ (no pack monolith exists — BD-203 inverted)
# ─────────────────────────────────────────────────────────────────
#
# BD-203 retires the old "mirror-in-sync" Check 32 and replaces it with
# an inverted guard (still named `check_mirror_in_sync`): for each pack
# stream whose per-entry tree is present, assert the monolith is ABSENT
# and `_rules.md` + `_toc.md` are present + filenames conform. Green =
# tree present + NO monolith; red = monolith present (or missing
# supporting file / non-conforming filename). `build_green_pack_backlog`
# emits the BACKLOG.md monolith as conversion input, so each green case
# DELETES it first.

printf "\n=== Group A: Check 32′ (no pack monolith exists — BD-203) ===\n"

# A1: green tree + NO monolith → check passes.
A1_REPO="$SCRATCH_ROOT/A1"
mkdir -p "$A1_REPO"
build_green_pack_backlog "$A1_REPO"
rm -f "$A1_REPO/BACKLOG.md"   # no-mirror SSOT: monolith deleted
A1_OUT=$(run_check check_mirror_in_sync "$A1_REPO" 2>&1)
A1_RC=$?
assert_eq "A1.1 tree + no monolith → check rc=0" "0" "$A1_RC"
assert_contains "A1.2 tree + no monolith → OK no monolith present" "$A1_OUT" "no monolith present"
assert_not_contains "A1.3 tree + no monolith → no FAIL" "$A1_OUT" "FAIL:"

# A2: tree present + monolith STILL present → check FAILs (wrong-model).
A2_REPO="$SCRATCH_ROOT/A2"
mkdir -p "$A2_REPO"
build_green_pack_backlog "$A2_REPO"   # leaves BACKLOG.md monolith in place
A2_OUT=$(run_check check_mirror_in_sync "$A2_REPO" 2>&1)
A2_RC=$?
assert_eq "A2.1 monolith present + tree → check rc=1" "1" "$A2_RC"
assert_contains "A2.2 monolith present → FAIL says still present" "$A2_OUT" "still present"
assert_contains "A2.3 monolith present → FAIL says delete the monolith" "$A2_OUT" "delete the monolith"

# A3: green tree + missing _rules.md → check FAILs.
A3_REPO="$SCRATCH_ROOT/A3"
mkdir -p "$A3_REPO"
build_green_pack_backlog "$A3_REPO"
rm -f "$A3_REPO/BACKLOG.md"
rm "$A3_REPO/backlog/_rules.md"
A3_OUT=$(run_check check_mirror_in_sync "$A3_REPO" 2>&1)
A3_RC=$?
assert_eq "A3.1 missing _rules.md → check rc=1" "1" "$A3_RC"
assert_contains "A3.2 missing _rules.md → FAIL names _rules.md" "$A3_OUT" "_rules.md missing"

# A4: green tree + missing _toc.md → check FAILs (no-mirror readable index).
A4_REPO="$SCRATCH_ROOT/A4"
mkdir -p "$A4_REPO"
build_green_pack_backlog "$A4_REPO"
rm -f "$A4_REPO/BACKLOG.md"
rm "$A4_REPO/backlog/_toc.md"
A4_OUT=$(run_check check_mirror_in_sync "$A4_REPO" 2>&1)
A4_RC=$?
assert_eq "A4.1 missing _toc.md → check rc=1" "1" "$A4_RC"
assert_contains "A4.2 missing _toc.md → FAIL names _toc.md" "$A4_OUT" "_toc.md missing"

# A5: green tree + non-conforming filename → check FAILs. The suffix
# entry BD-167b.md in the green fixture CONFORMS (widened regex), so the
# stray ROGUE-FILE.md is the only non-conforming offender.
A5_REPO="$SCRATCH_ROOT/A5"
mkdir -p "$A5_REPO"
build_green_pack_backlog "$A5_REPO"
rm -f "$A5_REPO/BACKLOG.md"
printf 'rogue\n' >"$A5_REPO/backlog/ROGUE-FILE.md"
A5_OUT=$(run_check check_mirror_in_sync "$A5_REPO" 2>&1)
A5_RC=$?
assert_eq "A5.1 non-conforming filename → check rc=1" "1" "$A5_RC"
assert_contains "A5.2 non-conforming filename → FAIL names the file" "$A5_OUT" "ROGUE-FILE.md"
assert_contains "A5.3 non-conforming filename → FAIL says non-conforming" "$A5_OUT" "non-conforming filenames"

# A6: the suffix entry BD-167b.md CONFORMS under the widened regex — a
# green tree carrying it (no monolith) passes Check 32′.
A6_REPO="$SCRATCH_ROOT/A6"
mkdir -p "$A6_REPO"
build_green_pack_backlog "$A6_REPO"
rm -f "$A6_REPO/BACKLOG.md"
[[ -f "$A6_REPO/backlog/BD-167b.md" ]] && t_pass "A6.0 suffix entry BD-167b.md present in fixture" \
    || t_fail "A6.0 suffix entry BD-167b.md present in fixture"
A6_OUT=$(run_check check_mirror_in_sync "$A6_REPO" 2>&1)
A6_RC=$?
assert_eq "A6.1 suffix entry conforms → check rc=0" "0" "$A6_RC"
assert_not_contains "A6.2 suffix entry conforms → BD-167b.md NOT flagged non-conforming" "$A6_OUT" "BD-167b.md"

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

# C6 (BD-203 A5/A15-T2): a body reference to the suffix entry `BD-167b`
# RESOLVES — the widened CROSS_REF_RE token (`BD-\d+[a-z]*`) tokenizes
# `BD-167b`, and the widened entry regex defines `BD-167b` (the fixture's
# BD-167b.md). Before BD-203 the token yielded NOTHING on `BD-167b`
# (a `\b` cannot sit between `7` and `b`), so the ref was invisible.
C6_REPO="$SCRATCH_ROOT/C6"
mkdir -p "$C6_REPO"
build_green_pack_backlog "$C6_REPO"
# BD-100 references the suffix entry BD-167b (defined in the fixture).
printf '\nDescription continued: superseded by BD-167b.\n' \
    >>"$C6_REPO/backlog/BD-100.md"
C6_OUT=$(run_check check_cross_reference_integrity "$C6_REPO" 2>&1)
C6_RC=$?
assert_eq "C6.1 suffix ref BD-167b resolves → check rc=0" "0" "$C6_RC"
assert_not_contains "C6.2 suffix ref BD-167b → no dangling FAIL" "$C6_OUT" "BD-167b — no matching"

# C7 (BD-203 A5): a DANGLING suffix reference (`BD-999z`, not defined) is
# now VISIBLE to Check 34 (the token admits the suffix) and FAILs — the
# widening admits the suffix in BOTH directions (resolve + dangling).
C7_REPO="$SCRATCH_ROOT/C7"
mkdir -p "$C7_REPO"
build_green_pack_backlog "$C7_REPO"
printf '\nDescription continued: see BD-999z for related context.\n' \
    >>"$C7_REPO/backlog/BD-100.md"
C7_OUT=$(run_check check_cross_reference_integrity "$C7_REPO" 2>&1)
C7_RC=$?
assert_eq "C7.1 dangling suffix ref BD-999z → check rc=1" "1" "$C7_RC"
assert_contains "C7.2 dangling suffix ref → FAIL names BD-999z" "$C7_OUT" "BD-999z"

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
# Group F: pack-changelog stream coverage (BD-168 retro fix S2)
# ─────────────────────────────────────────────────────────────────
#
# The original BD-168 test runner exercised only the pack-backlog
# stream. Per BD-168 retro fix S2 (review §2.2 SHOULD finding #2), add
# explicit coverage for the second pack-side stream (pack-changelog),
# including a cross-stream `defined_all` union test exercising
# validate-pack.py:3280-3282 (the union of defined IDs across loaded
# streams used by Check 34).
#
# The extra_streams seam in run_check accepts pipe-delimited tuples; the
# pack-changelog tuple uses the BD-203 per-release regex `^v\d+\.md$`.

printf "\n=== Group F: pack-changelog stream coverage (BD-203 per-release) ===\n"

# Tuple constant for the pack-changelog stream (4-part pipe-delimited).
# BD-203: per-release granularity → entry regex `^v\d+\.md$`.
PACKCL_TUPLE='pack-changelog|changelog|CHANGELOG.md|^v\d+\.md$'

# F1: green pack-changelog tree + NO monolith → Check 32′ PASS.
# pack-backlog SKIPs (no /backlog/ in scratch); pack-changelog passes
# (tree present, no monolith) → overall PASS.
F1_REPO="$SCRATCH_ROOT/F1"
mkdir -p "$F1_REPO"
build_green_pack_changelog "$F1_REPO"
F1_OUT=$(run_check check_mirror_in_sync "$F1_REPO" "$PACKCL_TUPLE" 2>&1)
F1_RC=$?
assert_eq "F1.1 green pack-changelog → Check 32′ rc=0" "0" "$F1_RC"
assert_contains "F1.2 green pack-changelog → no monolith present" "$F1_OUT" "changelog/ — no monolith present"
assert_contains "F1.3 green pack-changelog → pack-backlog SKIPs" "$F1_OUT" "backlog/ — not present"
assert_not_contains "F1.4 green pack-changelog → no FAIL" "$F1_OUT" "FAIL:"

# F2: green pack-changelog tree + Check 33 → PASS.
F2_REPO="$SCRATCH_ROOT/F2"
mkdir -p "$F2_REPO"
build_green_pack_changelog "$F2_REPO"
F2_OUT=$(run_check check_toc_in_sync "$F2_REPO" "$PACKCL_TUPLE" 2>&1)
F2_RC=$?
assert_eq "F2.1 green pack-changelog → Check 33 rc=0" "0" "$F2_RC"
assert_contains "F2.2 green pack-changelog → _toc.md byte-identical" "$F2_OUT" "changelog/_toc.md byte-identical"
assert_not_contains "F2.3 green pack-changelog → no FAIL" "$F2_OUT" "FAIL:"

# F3: green pack-changelog tree + Check 34 → PASS (no dangling refs).
F3_REPO="$SCRATCH_ROOT/F3"
mkdir -p "$F3_REPO"
build_green_pack_changelog "$F3_REPO"
# The v11.md body references BD-100 which is NOT defined in this scratch
# (no /backlog/). Check 34 would correctly FAIL with dangling BD-100. To
# exercise the all-pass path, strip the body reference before the check.
sed -i.bak 's/References BD-100 for context.//' "$F3_REPO/changelog/v11.md"
rm -f "$F3_REPO/changelog/v11.md.bak"
F3_OUT=$(run_check check_cross_reference_integrity "$F3_REPO" "$PACKCL_TUPLE" 2>&1)
F3_RC=$?
assert_eq "F3.1 green pack-changelog → Check 34 rc=0" "0" "$F3_RC"
assert_not_contains "F3.2 green pack-changelog → no dangling FAIL" "$F3_OUT" "FAIL:"

# F4: pack-changelog tree present + monolith STILL present → Check 32′
# FAIL (wrong-model; the monolith must be deleted under no-mirror).
F4_REPO="$SCRATCH_ROOT/F4"
mkdir -p "$F4_REPO"
build_green_pack_changelog "$F4_REPO"
printf '# stale monolith\n' >"$F4_REPO/CHANGELOG.md"
F4_OUT=$(run_check check_mirror_in_sync "$F4_REPO" "$PACKCL_TUPLE" 2>&1)
F4_RC=$?
assert_eq "F4.1 monolith present + changelog tree → Check 32′ rc=1" "1" "$F4_RC"
assert_contains "F4.2 monolith present → FAIL says CHANGELOG.md still present" "$F4_OUT" "CHANGELOG.md still present"
assert_contains "F4.3 monolith present → FAIL says delete the monolith" "$F4_OUT" "delete the monolith"

# F5: cross-stream union — pack-backlog entry references a pack-changelog
# release. Exercises the defined_all union. A pack-backlog entry
# referencing v10.0 should resolve via the pack-changelog stream's
# defined IDs (NB: the per-release changelog defines `v10` / `v11` as
# entry IDs; the CROSS_REF_RE `vN.M` token requires a minor — so the
# union here is exercised via the pack-changelog body referencing a
# pack-backlog BD that IS defined).
F5_REPO="$SCRATCH_ROOT/F5"
mkdir -p "$F5_REPO"
build_green_pack_backlog "$F5_REPO"
rm -f "$F5_REPO/BACKLOG.md"
build_green_pack_changelog "$F5_REPO"
# The pack-changelog v11.md references BD-100, which IS defined in the
# pack-backlog stream → resolves only via the defined_all union across
# both loaded streams. Without the union this would FAIL as dangling.
F5_OUT=$(run_check check_cross_reference_integrity "$F5_REPO" "$PACKCL_TUPLE" 2>&1)
F5_RC=$?
assert_eq "F5.1 cross-stream union → Check 34 rc=0 (BD-100 resolves via pack-backlog)" "0" "$F5_RC"
assert_not_contains "F5.2 cross-stream union → no dangling FAIL" "$F5_OUT" "FAIL:"

# ─────────────────────────────────────────────────────────────────
# Group G: M2 snap-leftover regression (BD-168 retro fix M2)
# ─────────────────────────────────────────────────────────────────
#
# Per BD-168 retro fix M2 (review §2.1 MUST finding #2), Check 33
# previously created its snapshot file inside stream_dir/ via
# tempfile.mkstemp(dir=str(stream_dir)). A SIGKILL between mkstemp
# and the finally-block cleanup would leave a leftover
# `.per-entry-toc-snap.XXXXXX.md` inside stream_dir/ that would FAIL
# Check 32 pre-check (b) on the NEXT validator run.
#
# Fix M2 moves the snap to the system tempdir (dir=None). Regression
# test: assert that after Check 33 runs successfully, no
# `.per-entry-toc-snap.*` files remain inside stream_dir/.

printf "\n=== Group G: M2 snap-leftover regression (no snap files in stream_dir) ===\n"

G1_REPO="$SCRATCH_ROOT/G1"
mkdir -p "$G1_REPO"
build_green_pack_backlog "$G1_REPO"
# Run Check 33 against the green tree (PASS path).
G1_OUT=$(run_check check_toc_in_sync "$G1_REPO" 2>&1)
G1_RC=$?
assert_eq "G1.1 Check 33 PASS path → rc=0" "0" "$G1_RC"
# Assert no snap files left behind in stream_dir/.
G1_LEFTOVERS=$(find "$G1_REPO/backlog" -name '.per-entry-toc-snap.*' -print 2>/dev/null)
if [[ -z "$G1_LEFTOVERS" ]]; then
    t_pass "G1.2 Check 33 PASS path → no .per-entry-toc-snap.* leftover in stream_dir"
else
    t_fail "G1.2 Check 33 PASS path → snap leftover in stream_dir" "$G1_LEFTOVERS"
fi

# Same assertion against the FAIL path (hand-edited _toc.md → Check 33
# FAILs but should still not leave a snap behind).
G2_REPO="$SCRATCH_ROOT/G2"
mkdir -p "$G2_REPO"
build_green_pack_backlog "$G2_REPO"
printf '\nROGUE TOC\n' >>"$G2_REPO/backlog/_toc.md"
G2_OUT=$(run_check check_toc_in_sync "$G2_REPO" 2>&1)
G2_RC=$?
assert_eq "G2.1 Check 33 FAIL path → rc=1" "1" "$G2_RC"
G2_LEFTOVERS=$(find "$G2_REPO/backlog" -name '.per-entry-toc-snap.*' -print 2>/dev/null)
if [[ -z "$G2_LEFTOVERS" ]]; then
    t_pass "G2.2 Check 33 FAIL path → no .per-entry-toc-snap.* leftover in stream_dir"
else
    t_fail "G2.2 Check 33 FAIL path → snap leftover in stream_dir" "$G2_LEFTOVERS"
fi

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
