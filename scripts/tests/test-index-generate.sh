#!/usr/bin/env bash
# scripts/tests/test-index-generate.sh — test suite for the BD-206 O11
# impl-plan `_index.md` generator + MANDATORY validator
# (scripts/lib/per-entry/index-generate.sh).
#
# The module derives a topological SEED for the impl-plan `_index.md`
# ordering from each phase file's `Blockers` / `Unblocks` / `Dependencies`
# / `Prerequisite` SSOT (the deps stay SSOT in the entry files; `_index.md` is not a
# competing source — G-3 (A) derive-seed-then-hand-maintain), and the
# MANDATORY validator enforces the TWO hard properties:
#   (1) hard-dependency-order consistency (the serial order is a valid
#       topological order of the rule-based deps);
#   (2) per-entry↔`_index.md` membership sync (exact, no missing/extra —
#       analogous to the `_toc.md`-sync Check 33).
#
# Coverage:
#   Group 1: generation — deterministic topological seed; idempotency;
#            title extraction; empty tree; backlog stream rejected.
#   Group 2: validation PASS — generated index conforms; multi-edge deps;
#            judgment-free ordering accepted where no hard dep constrains.
#   Group 3: validation FAIL (the teeth) — order violation; membership
#            missing/extra/duplicate; missing _index.md with phases; ghost
#            in an empty tree; dependency cycle.
#   Group 4: lenient SKIP — non-impl-plan stream + absent directory.
#   Group 5: bash 3.2 sourcing smoke.
#
# Test infra is self-provisioned (every tree built under a /tmp dir; no
# real stream mutated; cleanup on every exit).
#
# Usage: bash scripts/tests/test-index-generate.sh
# Exit:  0 if all PASS; 1 on any FAIL.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB="$REPO_ROOT/scripts/lib/per-entry/index-generate.sh"
STREAM="project-implementation-plan"

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

# shellcheck disable=SC1090
. "$LIB"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-index-generate.XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# Build a fresh stream dir with the given phase files. Each arg is
# "NUM:title:blockers:unblocks" (blockers/unblocks are phase-N lists or none).
new_stream() {
    local d
    d="$(mktemp -d "$WORK/stream.XXXXXX")"
    echo "$d"
}
write_phase() {
    # $1 dir  $2 num  $3 title  $4 blockers  $5 unblocks
    local d="$1" num="$2" title="$3" blockers="$4" unblocks="$5"
    cat > "$d/phase-$num.md" <<EOF
<!-- per-entry source: x; contract: y -->
## Phase $num — $title

- **Entry-Type**: phase-epic
- **ID**: phase-$num
- **Status**: not-started
- **Blockers**: $blockers
- **Unblocks**: $unblocks
- **Goal**: g$num
- **Prerequisite**: none
EOF
}

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: generation (topological seed / idempotency / empty) ===\n"
# ─────────────────────────────────────────────────────────────────

D="$(new_stream)"
write_phase "$D" 0 "Bootstrap" "none" "phase-1, phase-2"
write_phase "$D" 1 "Middle" "phase-0" "phase-2"
write_phase "$D" 2 "Final" "phase-1" "none"
per_entry_regenerate_index "$STREAM" "$D"

GEN="$(cat "$D/_index.md")"
assert_contains "1.1 generated _index.md carries the DO-NOT-EDIT marker" \
    "$GEN" "DO NOT EDIT BY HAND"
assert_contains "1.2 generated _index.md has a Serial order section" \
    "$GEN" "## Serial order"
# Topological order: 0 before 1 before 2.
# Extract just the bullet phase ids in order:
ORDER="$(grep -oE '^- \[phase-[0-9]+\]' "$D/_index.md" | sed -E 's/^- \[(phase-[0-9]+)\]/\1/' | tr '\n' ' ' | sed 's/ $//')"
assert_eq "1.3 topological seed orders 0 -> 1 -> 2" \
    "phase-0 phase-1 phase-2" "$ORDER"
assert_contains "1.4 title extracted from the H2 heading" \
    "$GEN" "[phase-1](./phase-1.md) — Middle"

# Idempotency.
cp "$D/_index.md" "$D/_index.before"
per_entry_regenerate_index "$STREAM" "$D"
if cmp -s "$D/_index.before" "$D/_index.md"; then
    t_pass "1.5 regeneration is idempotent (byte-identical)"
else
    t_fail "1.5 regeneration is NOT idempotent"
fi

# Empty stream → empty index.
DE="$(new_stream)"
per_entry_regenerate_index "$STREAM" "$DE"
assert_contains "1.6 empty stream yields the empty-index marker" \
    "$(cat "$DE/_index.md")" "(empty — no phase entries)"

# Backlog stream rejected (only impl-plan carries _index.md).
DB="$(new_stream)"
if ( per_entry_regenerate_index project-backlog "$DB" ) 2>/dev/null; then
    t_fail "1.7 backlog stream regenerate-index rejected" "expected non-zero"
else
    t_pass "1.7 backlog stream regenerate-index rejected (only impl-plan)"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: validation PASS ===\n"
# ─────────────────────────────────────────────────────────────────

# The Group-1 generated index validates clean.
if per_entry_validate_index "$STREAM" "$D" >/dev/null 2>&1; then
    t_pass "2.1 generated index validates clean (both hard properties)"
else
    t_fail "2.1 generated index FAILED validation"
fi

# Judgment-free ordering: two phases with NO hard dep between them —
# either order is accepted (the validator only enforces hard deps).
DF="$(new_stream)"
write_phase "$DF" 3 "Indep-A" "none" "none"
write_phase "$DF" 4 "Indep-B" "none" "none"
# Hand-author an index with 4 before 3 (no hard dep → free choice).
cat > "$DF/_index.md" <<'EOF'
# Index — ordering — project-implementation-plan

## Serial order

- [phase-4](./phase-4.md) — Indep-B
- [phase-3](./phase-3.md) — Indep-A
EOF
if per_entry_validate_index "$STREAM" "$DF" >/dev/null 2>&1; then
    t_pass "2.2 judgment-free order accepted where no hard dep constrains"
else
    t_fail "2.2 judgment-free order WRONGLY rejected"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 3: validation FAIL (the teeth) ===\n"
# ─────────────────────────────────────────────────────────────────

# 3.1 ORDER violation — reverse the dependency order.
DO="$(new_stream)"
write_phase "$DO" 0 "A" "none" "phase-1"
write_phase "$DO" 1 "B" "phase-0" "none"
cat > "$DO/_index.md" <<'EOF'
## Serial order

- [phase-1](./phase-1.md) — B
- [phase-0](./phase-0.md) — A
EOF
OUT="$(per_entry_validate_index "$STREAM" "$DO" 2>&1)"; RC=$?
[[ $RC -ne 0 ]] && t_pass "3.1 ORDER violation FAILs" || t_fail "3.1 ORDER violation NOT caught"
assert_contains "3.1b ORDER message names the precede constraint" "$OUT" "must precede"

# 3.2 MEMBERSHIP missing — phase-1 not in the index.
DM="$(new_stream)"
write_phase "$DM" 0 "A" "none" "none"
write_phase "$DM" 1 "B" "none" "none"
cat > "$DM/_index.md" <<'EOF'
## Serial order

- [phase-0](./phase-0.md) — A
EOF
OUT="$(per_entry_validate_index "$STREAM" "$DM" 2>&1)"; RC=$?
[[ $RC -ne 0 ]] && t_pass "3.2 MEMBERSHIP missing FAILs" || t_fail "3.2 MEMBERSHIP missing NOT caught"
assert_contains "3.2b membership message names phase-1" "$OUT" "phase-1"

# 3.3 MEMBERSHIP extra — index lists a phase with no file.
DX="$(new_stream)"
write_phase "$DX" 0 "A" "none" "none"
cat > "$DX/_index.md" <<'EOF'
## Serial order

- [phase-0](./phase-0.md) — A
- [phase-9](./phase-9.md) — Ghost
EOF
OUT="$(per_entry_validate_index "$STREAM" "$DX" 2>&1)"; RC=$?
[[ $RC -ne 0 ]] && t_pass "3.3 MEMBERSHIP extra FAILs" || t_fail "3.3 MEMBERSHIP extra NOT caught"

# 3.4 duplicate listing.
DD="$(new_stream)"
write_phase "$DD" 0 "A" "none" "none"
cat > "$DD/_index.md" <<'EOF'
## Serial order

- [phase-0](./phase-0.md) — A
- [phase-0](./phase-0.md) — A
EOF
OUT="$(per_entry_validate_index "$STREAM" "$DD" 2>&1)"; RC=$?
[[ $RC -ne 0 ]] && t_pass "3.4 duplicate listing FAILs" || t_fail "3.4 duplicate NOT caught"

# 3.5 missing _index.md with phases present.
DN="$(new_stream)"
write_phase "$DN" 0 "A" "none" "none"
OUT="$(per_entry_validate_index "$STREAM" "$DN" 2>&1)"; RC=$?
[[ $RC -ne 0 ]] && t_pass "3.5 missing _index.md (phases present) FAILs" || t_fail "3.5 missing index NOT caught"

# 3.6 ghost in an empty tree (no phases but index lists one).
DG="$(new_stream)"
cat > "$DG/_index.md" <<'EOF'
## Serial order

- [phase-7](./phase-7.md) — Ghost
EOF
OUT="$(per_entry_validate_index "$STREAM" "$DG" 2>&1)"; RC=$?
[[ $RC -ne 0 ]] && t_pass "3.6 ghost in empty tree FAILs" || t_fail "3.6 ghost NOT caught"

# 3.7 dependency cycle.
DC="$(new_stream)"
write_phase "$DC" 0 "A" "phase-1" "none"
write_phase "$DC" 1 "B" "phase-0" "none"
per_entry_regenerate_index "$STREAM" "$DC"
OUT="$(per_entry_validate_index "$STREAM" "$DC" 2>&1)"; RC=$?
[[ $RC -ne 0 ]] && t_pass "3.7 dependency cycle FAILs" || t_fail "3.7 cycle NOT caught"
assert_contains "3.7b cycle message names the cycle" "$OUT" "cycle"

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 4: lenient SKIP ===\n"
# ─────────────────────────────────────────────────────────────────

# Non-impl-plan stream → SKIP (rc 0).
if per_entry_validate_index project-backlog "$D" >/dev/null 2>&1; then
    t_pass "4.1 non-impl-plan stream validation SKIPs lenient"
else
    t_fail "4.1 non-impl-plan stream NOT lenient"
fi
# Absent directory → SKIP (rc 0).
if per_entry_validate_index "$STREAM" "$WORK/does-not-exist" >/dev/null 2>&1; then
    t_pass "4.2 absent stream dir validation SKIPs lenient"
else
    t_fail "4.2 absent stream dir NOT lenient"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 5: bash 3.2 sourcing smoke ===\n"
# ─────────────────────────────────────────────────────────────────

if bash --norc -c ". '$LIB'; type per_entry_regenerate_index >/dev/null && type per_entry_validate_index >/dev/null" 2>/dev/null; then
    t_pass "5.1 module sources cleanly + exposes both public functions"
else
    t_fail "5.1 module failed to source / expose functions"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

if (( FAIL == 0 )); then
    printf "\n\033[32mAll index-generate tests passed.\033[0m\n"
    exit 0
fi
printf "\n\033[31mSome index-generate tests failed.\033[0m\n"
exit 1
