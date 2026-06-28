#!/usr/bin/env bash
# scripts/tests/test-migrate-v10-to-v11-decompose.sh — BD-165 retroactive
# fix regression-guard test runner.
#
# Covers BD-165's net-new functional surface, which the pre-existing
# test runners (test-migrate-v10-to-v11.sh, *-dry-run.sh, *-gates.sh,
# test-per-entry.sh) do not exercise:
#
#   Group 1 — 6th sub-op presence + sequencing
#     1.1 --dry-run dry-run banner names the new BD-165 decompose step
#     1.2 --dry-run emits the BD-206 no-mirror post-report advisory
#         paragraph (per-entry tree + _toc.md is the sole source of
#         truth; no monolithic mirror is regenerated)
#
#   Group 2 — --apply happy path against a transient v10-shape fixture
#             with seeded docs/project/{BACKLOG,IMPLEMENTATION-PLAN,
#             CHANGELOG}.md monolithic INPUT files
#     2.1 --apply produces per-entry trees under
#         docs/project/{backlog,implementation-plan,changelog}/
#     2.2 --apply produces NO regenerated monolithic mirror at
#         docs/project/{BACKLOG.md,IMPLEMENTATION-PLAN.md,CHANGELOG.md}
#         (BD-206 no-mirror model — the v10 monolith was read as INPUT
#         and is NOT re-emitted; only the per-entry tree + _toc.md remain)
#     2.3 --apply emits the BD-206 no-mirror post-report advisory
#         paragraph (same assertions as 1.2)
#     2.4 --apply Gate 2 PASSES
#     2.5 --apply HEAD unchanged before/after (migrator does NOT commit)
#
# Build-your-own fixture: the in-tree v10-realistic-ot build artifact
# (under test-fixtures/) does not have docs/project/*.md files (per
# IMPL-REPORT-BD-165 §7.2); this runner synthesizes the minimum v10-shape
# fixture with the requisite
# docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md content directly
# under /tmp. It is NOT fixture-dependent — it builds its own under /tmp.
#
# Bash 3.2 + macOS BSD utility compatible. NO associative arrays, NO
# `&>`, NO GNU-only flags.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATE_SH="$REPO_ROOT/scripts/migrate-v10-to-v11.sh"
PE_LIB_DIR="$REPO_ROOT/scripts/lib/per-entry"

PASSED=0
FAILED=0
t_pass() { echo -e "  \033[32mPASS\033[0m $1"; PASSED=$((PASSED + 1)); }
t_fail() { echo -e "  \033[31mFAIL\033[0m $1${2:+ — $2}"; FAILED=$((FAILED + 1)); }
assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' got='$3'"; fi
}
assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "expected to contain '$3'"; fi
}
assert_not_contains() {
    if [[ "$2" != *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "expected NOT to contain '$3'"; fi
}

# ─────────────────────────────────────────────────────────────────────────
# Fixture builder
# ─────────────────────────────────────────────────────────────────────────
#
# Synthesizes a v10-shape target directory under /tmp with:
#   - Trinity files (CLAUDE.md, AGENTS.md, GEMINI.md) sourced from v10 tag
#     so the BD-088 customization-preserve dispatch lands a clean unchanged-
#     pack path (no spurious sidecars).
#   - Minimal docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md
#     monolithic files with hand-authored entries so the BD-165 6th
#     sub-op (_v10_to_v11_decompose_streams) actually has content to
#     decompose.
#   - git init + initial commit so EXIT_DIRTY=12 preflight passes.
#
# Echoes the target absolute path on stdout.
make_v10_target_with_project_docs() {
    local d
    d=$(mktemp -d -t migrate10-bd165.XXXXXX)
    git init -q "$d" >/dev/null
    git -C "$d" config user.email "test@example.com"
    git -C "$d" config user.name  "Test"

    mkdir -p "$d/.claude" "$d/docs/pack" "$d/docs/project" "$d/.codex" "$d/.gemini"
    git -C "$REPO_ROOT" show v10:project-template/CLAUDE.md > "$d/CLAUDE.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/AGENTS.md > "$d/AGENTS.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/GEMINI.md > "$d/GEMINI.md" 2>/dev/null

    # docs/project/BACKLOG.md — minimal hand-authored project backlog
    # with 3 TD-NNN entries. Shape matches the per-entry mirror grammar
    # (intro + ## section + **TD-NNN — title** bold-headers + `---`
    # inter-entry separators) so the decompose helper recognizes entries.
    cat > "$d/docs/project/BACKLOG.md" <<'EOF'
# Project backlog

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/backlog/`.

---

## Active

**TD-001 — Sample first project entry**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: `app/Sources/Example.swift`
Description: Sample first project entry.

---

**TD-002 — Sample second project entry**
Type: TODO(version)
Status: Open
Blockers: TD-001
Unblocks: None
File/Symbol: `app/Sources/Other.swift`
Description: Sample second project entry depending on the first.

---

**TD-003 — Sample third project entry**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: TD-001
File/Symbol: `app/Sources/Third.swift`
Description: Sample third project entry resolved early.
Resolved: 2026-05-10 — sample resolution.
EOF

    # docs/project/IMPLEMENTATION-PLAN.md — minimal hand-authored
    # implementation plan with 2 phase-N.md entries. The decompose
    # parser anchors on `## Phase N — Title` H2 lines (per
    # scripts/lib/per-entry/decompose.sh:133-134) and produces
    # phase-N.md per-entry files.
    cat > "$d/docs/project/IMPLEMENTATION-PLAN.md" <<'EOF'
# Project implementation plan

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/implementation-plan/`.

---

## Phase 1 — Sample first phase

Phase 1 is the initial scaffolding phase.

- Phase 1.1 — Initial repo setup
- Phase 1.2 — First feature scaffold

---

## Phase 2 — Sample second phase

Phase 2 is the feature-implementation phase.

- Phase 2.1 — Implement feature A
- Phase 2.2 — Implement feature B
EOF

    # docs/project/CHANGELOG.md — minimal hand-authored project
    # changelog with 2 dated entries.
    cat > "$d/docs/project/CHANGELOG.md" <<'EOF'
# Project changelog

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/changelog/`.

---

### 2026-04-15 — Phase 1 milestone

Initial scaffolding phase complete:
- Repo setup
- First feature scaffold

---

### 2026-04-22 — Phase 2 milestone

Feature implementation phase complete:
- Feature A
- Feature B
EOF

    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "v10 initial state + minimal docs/project/*.md" 2>/dev/null
    printf '%s\n' "$d"
}

# ─────────────────────────────────────────────────────────────────────────
# Group 1: 6th sub-op presence + sequencing (dry-run surface)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 1: 6th sub-op presence + sequencing ===\n"

T=$(make_v10_target_with_project_docs)
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" 2>&1) ; rc=$?
assert_eq "1.0 setup --dry-run rc=0" "0" "$rc"
assert_contains "1.1 --dry-run banner names per-entry decompose" \
    "$out" "per-entry decompose"

# 1.2 — post-report advisory paragraph has the BD-206 no-mirror wording
# (per-entry tree + _toc.md is the sole source of truth; the v10 monolith
# is read as decomposition INPUT and is NOT regenerated as a mirror).
# The pre-BD-206 advisory described a regenerated mirror with a
# divergence-block (BLOCK + a non-zero gate exit + a flag-based override
# recovery); under the no-mirror model that entire narrative is gone, so
# the negative needles below assert the dead flag/wording are absent.
assert_contains "1.2a --dry-run advisory says 'sole source of truth'" \
    "$out" "sole source of truth"
assert_contains "1.2b --dry-run advisory states no monolithic mirror" \
    "$out" "no monolithic mirror under the v11 model"
# Negative: the removed mirror divergence-gate narrative must NOT be present.
assert_not_contains "1.2c --dry-run advisory does NOT name --force-overwrite-mirror (removed, BD-206)" \
    "$out" "force-overwrite-mirror"
assert_not_contains "1.2d --dry-run advisory does NOT have mirror divergence-block 'will BLOCK' wording (removed, BD-206)" \
    "$out" "will BLOCK"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 2: --apply happy path against fixture with docs/project/*.md
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2: --apply happy path with project docs ===\n"

T=$(make_v10_target_with_project_docs)
HEAD_BEFORE=$(git -C "$T" rev-parse HEAD)

# Run --dry-run first (--apply requires fresh fingerprint).
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1 ; rc=$?
assert_eq "2.0a setup --dry-run rc=0" "0" "$rc"

# --apply: plain (no divergence-override flag — removed in BD-206).
# Under the no-mirror model the decompose sub-op reads the v10 monolith
# as INPUT and regenerates only the per-entry tree + _toc.md; it never
# regenerates a mirror, so there is no divergence to block and no flag
# to acknowledge.
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" 2>&1) ; rc=$?
assert_eq "2.0b --apply rc=0 (no-mirror model; no flag)" "0" "$rc"

# 2.1 — per-entry trees produced under docs/project/<stream>/.
[[ -f "$T/docs/project/backlog/TD-001.md" ]] \
    && t_pass "2.1a per-entry backlog TD-001.md exists" \
    || t_fail "2.1a per-entry backlog TD-001.md missing"
[[ -f "$T/docs/project/backlog/TD-002.md" ]] \
    && t_pass "2.1b per-entry backlog TD-002.md exists" \
    || t_fail "2.1b per-entry backlog TD-002.md missing"
[[ -f "$T/docs/project/backlog/TD-003.md" ]] \
    && t_pass "2.1c per-entry backlog TD-003.md exists" \
    || t_fail "2.1c per-entry backlog TD-003.md missing"
[[ -f "$T/docs/project/implementation-plan/phase-1.md" ]] \
    && t_pass "2.1d per-entry implementation-plan phase-1.md exists" \
    || t_fail "2.1d per-entry implementation-plan phase-1.md missing"
[[ -f "$T/docs/project/implementation-plan/phase-2.md" ]] \
    && t_pass "2.1e per-entry implementation-plan phase-2.md exists" \
    || t_fail "2.1e per-entry implementation-plan phase-2.md missing"
[[ -f "$T/docs/project/changelog/2026-04-15-phase-1-milestone.md" ]] \
    && t_pass "2.1f per-entry changelog 2026-04-15-phase-1-milestone.md exists" \
    || t_fail "2.1f per-entry changelog 2026-04-15-phase-1-milestone.md missing"

# 2.2 — NO regenerated monolithic mirror (BD-206 no-mirror model). The
# per-entry tree + generated _toc.md is the sole source of truth +
# readable form; the decompose sub-op regenerates only the _toc.md index
# and never re-emits a mirror. The v10 monolith INPUT files persist on
# disk untouched (the migrator reads them as decompose input and does not
# remove them) — but they are NOT regenerated, so they still carry the
# raw v10 input content rather than a tool-regenerated mirror.
[[ -f "$T/docs/project/backlog/_toc.md" ]] \
    && t_pass "2.2a backlog/_toc.md regenerated (no-mirror readable form)" \
    || t_fail "2.2a backlog/_toc.md missing"
[[ -f "$T/docs/project/implementation-plan/_toc.md" ]] \
    && t_pass "2.2b implementation-plan/_toc.md regenerated (no-mirror readable form)" \
    || t_fail "2.2b implementation-plan/_toc.md missing"
[[ -f "$T/docs/project/changelog/_toc.md" ]] \
    && t_pass "2.2c changelog/_toc.md regenerated (no-mirror readable form)" \
    || t_fail "2.2c changelog/_toc.md missing"
# 2.2d — the v10 monolith INPUT was NOT regenerated as a mirror: it still
# carries the raw fixture-authored v10 content (proving the decompose
# sub-op did not re-emit a regenerated mirror over it).
if [[ -f "$T/docs/project/BACKLOG.md" ]] \
    && grep -q "Sample first project entry" "$T/docs/project/BACKLOG.md"; then
    t_pass "2.2d v10 BACKLOG.md input UNTOUCHED (no regenerated mirror written over it)"
else
    t_fail "2.2d v10 BACKLOG.md input not in expected untouched state"
fi

# 2.3 — post-report advisory paragraph has the BD-206 no-mirror wording.
assert_contains "2.3a --apply advisory says 'sole source of truth'" \
    "$out" "sole source of truth"
assert_contains "2.3b --apply advisory states no monolithic mirror" \
    "$out" "no monolithic mirror under the v11 model"
assert_not_contains "2.3c --apply advisory does NOT name --force-overwrite-mirror (removed, BD-206)" \
    "$out" "force-overwrite-mirror"
assert_not_contains "2.3d --apply advisory does NOT have mirror divergence-block 'will BLOCK' wording (removed, BD-206)" \
    "$out" "will BLOCK"

# 2.4 — Gate 2 PASS appears in the run output.
assert_contains "2.4 --apply Gate 2 PASS in output" "$out" "Gate 2 PASS"

# 2.5 — HEAD unchanged (migrator does NOT commit).
HEAD_AFTER=$(git -C "$T" rev-parse HEAD)
assert_eq "2.5 HEAD unchanged after --apply (migrator never commits)" \
    "$HEAD_BEFORE" "$HEAD_AFTER"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASSED"
printf "Failed: %d\n" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
    echo "All BD-165 decompose tests passed."
    exit 0
fi
exit 1
