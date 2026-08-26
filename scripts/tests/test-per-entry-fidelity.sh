#!/usr/bin/env bash
# scripts/tests/test-per-entry-fidelity.sh — test suite for the BD-291
# per-entry line-accounting gate (scripts/lib/per-entry/accounting.sh).
#
# Permanently encodes the no-loss property: every non-structural
# monolith line routes to an entry file or the dropped-content capture
# (M == T ⊎ R, line multisets). Groups:
#
#   Unit PASS  clean decompose (+capture) of an inline 3-entry monolith
#              → per_entry_accounting_check returns 0.
#   m1         delete one line from one entry file → non-zero rc +
#              UNACCOUNTED + the line text.
#   m2         append one fabricated line to an entry file → non-zero
#              rc + FABRICATED + the file name.
#   m3         truncate the capture file → non-zero rc + UNACCOUNTED.
#   r0–r2      reduced mode (5th arg, synthesis record): r0 PASS with a
#              correct record after hand-inserting the recorded lines;
#              r1 mutate one recorded line in the tree → FAIL
#              (RECORDED-BUT-ABSENT); r2 add one tree line outside the
#              record → FAIL (FABRICATED).
#
# Self-contained: inline fixtures under mktemp -d; NOT fixture-dependent.
#
# Usage: bash scripts/tests/test-per-entry-fidelity.sh
# Exit:  0 if all PASS; 1 on any FAIL.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib/per-entry"

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
    else t_fail "$1" "needle='$3' missing from: ${2:0:200}"; fi
}

assert_nonzero_rc() {
    if [[ "$2" -ne 0 ]]; then t_pass "$1"
    else t_fail "$1" "expected non-zero rc, got 0"; fi
}

# Source the helpers (same load order as a consumer would use).
# shellcheck disable=SC1091
. "$LIB_DIR/_lib.sh"
# shellcheck disable=SC1091
. "$LIB_DIR/decompose.sh"
# shellcheck disable=SC1091
. "$LIB_DIR/accounting.sh"

SCRATCH_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/per-entry-fidelity.XXXXXX")
trap 'rm -rf "$SCRATCH_ROOT"' EXIT INT TERM

# ─────────────────────────────────────────────────────────────────
# Fixture: 3-entry pack-backlog monolith with preamble, a fenced
# block inside one entry, an H1 divider, and a trailing non-entry
# section (the capture is non-empty by construction).
# ─────────────────────────────────────────────────────────────────

FX_ROOT="$SCRATCH_ROOT/fixture"
FX_DIR="$FX_ROOT/backlog"
mkdir -p "$FX_DIR"
cat >"$FX_ROOT/BACKLOG.md" <<'EOF'
# Backlog

Preamble line one.

**BD-100 — First entry**
Type: TODO(version)
Status: Open
File/Symbol: `scripts/example.sh`
Description: first entry with a fence.
```
## fenced heading stays in-span
```

**BD-101 — Second entry**
Type: TODO(version)
Status: Open
Description: second entry.

# Milestone divider
Milestone context line.

**BD-102 — Third entry**
Type: TODO(version)
Status: Resolved
Description: third entry.

## Trailing section
Trailing section context line.
EOF

FX_CAP="$FX_ROOT/dropped.md"
PE_DECOMPOSE_DROPPED="$FX_CAP" per_entry_decompose pack-backlog "$FX_ROOT/BACKLOG.md" "$FX_DIR" 2>/dev/null

# ─────────────────────────────────────────────────────────────────
# Group 1: unit PASS on the clean decompose
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: accounting unit PASS ===\n"

U_RC=0
U_OUT=$(per_entry_accounting_check pack-backlog "$FX_ROOT/BACKLOG.md" "$FX_DIR" "$FX_CAP" 2>&1) || U_RC=$?
assert_eq "1.1 clean decompose+capture passes the gate (rc 0)" "0" "$U_RC"
assert_contains "1.2 verdict line reports PASS" "$U_OUT" "per-entry accounting: PASS (pack-backlog)"

# ─────────────────────────────────────────────────────────────────
# Group 2: bite mutations m1–m3 (each must discriminate)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: bite mutations m1–m3 ===\n"

# m1: delete one line from one entry file → UNACCOUNTED + line text.
M1_DIR="$SCRATCH_ROOT/tree-m1"
cp -R "$FX_DIR" "$M1_DIR"
grep -v '^File/Symbol:' "$M1_DIR/BD-100.md" >"$M1_DIR/BD-100.md.tmp"
mv "$M1_DIR/BD-100.md.tmp" "$M1_DIR/BD-100.md"
M1_RC=0
M1_OUT=$(per_entry_accounting_check pack-backlog "$FX_ROOT/BACKLOG.md" "$M1_DIR" "$FX_CAP" 2>&1) || M1_RC=$?
assert_nonzero_rc "2.1a m1 deleted entry line fails the gate" "$M1_RC"
assert_contains "2.1b m1 names the loss class" "$M1_OUT" "UNACCOUNTED"
assert_contains "2.1c m1 names the deleted line text" "$M1_OUT" 'File/Symbol: `scripts/example.sh`'

# m2: append one fabricated line to an entry file → FABRICATED + file.
M2_DIR="$SCRATCH_ROOT/tree-m2"
cp -R "$FX_DIR" "$M2_DIR"
printf 'Fabricated line xyz.\n' >>"$M2_DIR/BD-102.md"
M2_RC=0
M2_OUT=$(per_entry_accounting_check pack-backlog "$FX_ROOT/BACKLOG.md" "$M2_DIR" "$FX_CAP" 2>&1) || M2_RC=$?
assert_nonzero_rc "2.2a m2 fabricated entry line fails the gate" "$M2_RC"
assert_contains "2.2b m2 names the fabrication class" "$M2_OUT" "FABRICATED"
assert_contains "2.2c m2 names the carrying file" "$M2_OUT" "BD-102.md"

# m3: truncate the capture file → UNACCOUNTED (the captured content
# no longer accounts for its monolith lines).
M3_CAP="$SCRATCH_ROOT/dropped-m3.md"
cp "$FX_CAP" "$M3_CAP"
: >"$M3_CAP"
M3_RC=0
M3_OUT=$(per_entry_accounting_check pack-backlog "$FX_ROOT/BACKLOG.md" "$FX_DIR" "$M3_CAP" 2>&1) || M3_RC=$?
assert_nonzero_rc "2.3a m3 truncated capture fails the gate" "$M3_RC"
assert_contains "2.3b m3 names the loss class" "$M3_OUT" "UNACCOUNTED"
assert_contains "2.3c m3 names a captured line" "$M3_OUT" "Trailing section context line."

# ─────────────────────────────────────────────────────────────────
# Group 3: reduced mode (synthesis record; both directions bite)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: reduced mode r0–r2 ===\n"

# r0: hand-insert the recorded lines, supply the matching record → PASS.
R_DIR="$SCRATCH_ROOT/tree-r"
cp -R "$FX_DIR" "$R_DIR"
awk 'NR==3{print "Entry-Type: td"} {print}' "$R_DIR/BD-100.md" >"$R_DIR/BD-100.md.tmp"
mv "$R_DIR/BD-100.md.tmp" "$R_DIR/BD-100.md"
awk 'NR==3{print "Marker: TODO"} {print}' "$R_DIR/BD-101.md" >"$R_DIR/BD-101.md.tmp"
mv "$R_DIR/BD-101.md.tmp" "$R_DIR/BD-101.md"
R_TSV="$SCRATCH_ROOT/synth.tsv"
printf 'BD-100.md\tEntry-Type: td\nBD-101.md\tMarker: TODO\n' >"$R_TSV"
R0_RC=0
R0_OUT=$(per_entry_accounting_check pack-backlog "$FX_ROOT/BACKLOG.md" "$R_DIR" "$FX_CAP" "$R_TSV" 2>&1) || R0_RC=$?
assert_eq "3.1a r0 correct record + inserted lines passes (rc 0)" "0" "$R0_RC"
assert_contains "3.1b r0 verdict line reports PASS" "$R0_OUT" "per-entry accounting: PASS (pack-backlog)"

# r1: mutate one recorded line in the tree → RECORDED-BUT-ABSENT.
R1_DIR="$SCRATCH_ROOT/tree-r1"
cp -R "$R_DIR" "$R1_DIR"
sed 's/^Marker: TODO$/Marker: EDITED/' "$R1_DIR/BD-101.md" >"$R1_DIR/BD-101.md.tmp"
mv "$R1_DIR/BD-101.md.tmp" "$R1_DIR/BD-101.md"
R1_RC=0
R1_OUT=$(per_entry_accounting_check pack-backlog "$FX_ROOT/BACKLOG.md" "$R1_DIR" "$FX_CAP" "$R_TSV" 2>&1) || R1_RC=$?
assert_nonzero_rc "3.2a r1 mutated recorded line fails the gate" "$R1_RC"
assert_contains "3.2b r1 names the missing record" "$R1_OUT" "RECORDED-BUT-ABSENT: BD-101.md: Marker: TODO"

# r2: add one tree line OUTSIDE the record → FABRICATED.
R2_DIR="$SCRATCH_ROOT/tree-r2"
cp -R "$R_DIR" "$R2_DIR"
printf 'Extra undeclared line.\n' >>"$R2_DIR/BD-102.md"
R2_RC=0
R2_OUT=$(per_entry_accounting_check pack-backlog "$FX_ROOT/BACKLOG.md" "$R2_DIR" "$FX_CAP" "$R_TSV" 2>&1) || R2_RC=$?
assert_nonzero_rc "3.3a r2 unrecorded tree addition fails the gate" "$R2_RC"
assert_contains "3.3b r2 names the fabrication + file" "$R2_OUT" "FABRICATED: BD-102.md: Extra undeclared line."

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "PASS: %d\n" "$PASS"
printf "FAIL: %d\n" "$FAIL"

if [[ "$FAIL" -eq 0 ]]; then
    printf "\nAll per-entry fidelity tests PASSED (%d/%d).\n" "$PASS" "$((PASS+FAIL))"
    exit 0
else
    printf "\n%d/%d per-entry fidelity tests FAILED.\n" "$FAIL" "$((PASS+FAIL))"
    exit 1
fi
