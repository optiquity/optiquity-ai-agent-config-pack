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
#     1.2 --dry-run emits the corrected post-report advisory paragraph
#         (M1 wording — BLOCK + exit code 31 + recovery instruction)
#
#   Group 2 — --apply happy path against a transient v10-shape fixture
#             with seeded docs/project/{BACKLOG,IMPLEMENTATION-PLAN,
#             CHANGELOG}.md monolithic files
#     2.1 --apply produces per-entry trees under
#         docs/project/{backlog,implementation-plan,changelog}/
#     2.2 --apply produces / preserves regenerated mirrors at
#         docs/project/{BACKLOG.md,IMPLEMENTATION-PLAN.md,CHANGELOG.md}
#     2.3 --apply emits the corrected post-report advisory paragraph
#         (same M1 assertions as 1.2)
#     2.4 --apply Gate 2 PASSES
#     2.5 --apply HEAD unchanged before/after (migrator does NOT commit)
#
#   Group 3 — Mode-aware divergence routing
#             (per_entry_regenerate_mirror invoked directly with
#             _MIGRATOR_MODE values)
#     3.1 _MIGRATOR_MODE=dry-run: rc=0, stdout names "divergence
#         detected", on-disk mirror UNCHANGED
#     3.2 _MIGRATOR_MODE=apply: rc=31, stderr names "force-overwrite-
#         mirror" + "ERROR", on-disk mirror UNCHANGED
#     3.3 _MIGRATOR_MODE=resume: rc=31 (block path identical to apply),
#         on-disk mirror UNCHANGED
#     3.4 _MIGRATOR_MODE=apply + PE_FORCE_OVERWRITE_MIRROR=1: rc=0,
#         stderr names "WARNING: PE_FORCE_OVERWRITE_MIRROR=1" audit-
#         trail, on-disk mirror OVERWRITTEN
#
#   Group 4 — Dispatcher --force-overwrite-mirror intercept on resume
#             path (resume.sh never calls _migrator_parse_args; the
#             dispatcher intercept in migrate-v10-to-v11.sh is the
#             only seam that wires the flag into resume mode)
#     4.1 --resume --force-overwrite-mirror against a fixture with a
#         pre-seeded divergence: rc=0, mirror overwritten, audit-trail
#         warning emitted
#     4.2 --resume WITHOUT --force-overwrite-mirror against the same
#         pre-seeded divergence: rc=31 (blocked). Confirms the
#         dispatcher intercept is the difference.
#
#   Group 5 — Backward compatibility
#     5.1 per_entry_regenerate_mirror invoked WITHOUT _MIGRATOR_MODE
#         set preserves pre-BD-165 behavior (rc=2 + stderr warning
#         naming "force-overwrite-mirror"). Same contract that
#         test-per-entry.sh Group 8 relies on.
#
# Build-your-own fixture: the in-tree test-fixtures/v10-realistic-ot/
# does not have docs/project/*.md files (per IMPL-REPORT-BD-165 §7.2);
# this runner synthesizes the minimum v10-shape fixture with the
# requisite docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md
# content directly under /tmp.
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

# Snapshot mirror-file SHA — used to detect divergence-block protected
# the on-disk file from mutation.
mirror_sha() {
    shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
}

# ─────────────────────────────────────────────────────────────────────────
# Group 1: 6th sub-op presence + sequencing (dry-run surface)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 1: 6th sub-op presence + sequencing ===\n"

T=$(make_v10_target_with_project_docs)
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" 2>&1) ; rc=$?
assert_eq "1.0 setup --dry-run rc=0" "0" "$rc"
assert_contains "1.1 --dry-run banner names BD-165 per-entry decompose" \
    "$out" "BD-165 per-entry decompose"

# 1.2 — post-report advisory paragraph has the corrected M1 wording
# (BLOCK + EXIT_GATE_FAILED=31 + force-overwrite-mirror). This is the
# regression-guard for the M1 fix; the pre-fix wording was "silently
# overwritten ... unless --force-overwrite-mirror is acknowledged",
# which inverted the safety contract.
assert_contains "1.2a --dry-run advisory says 'will BLOCK'" \
    "$out" "will BLOCK"
assert_contains "1.2b --dry-run advisory names exit code 31 (EXIT_GATE_FAILED)" \
    "$out" "EXIT_GATE_FAILED"
assert_contains "1.2c --dry-run advisory names --force-overwrite-mirror" \
    "$out" "force-overwrite-mirror"
# Negative: the pre-M1 inverted wording must NOT be present.
assert_not_contains "1.2d --dry-run advisory does NOT have pre-M1 inverted 'silently overwritten' wording" \
    "$out" "silently overwritten"

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

# --apply: pass --force-overwrite-mirror because first-migration users
# with pre-existing docs/project/*.md (the fixture seeds them) will
# correctly see divergence on first regenerate; the safety contract
# requires explicit acknowledgement to overwrite the v10-format mirror
# with the v11 regenerated mirror (per IMPL-REPORT-BD-165 §7.3 + Pack
# Chat's S3 test specification).
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --force-overwrite-mirror "$T" 2>&1) ; rc=$?
assert_eq "2.0b --apply rc=0 (with --force-overwrite-mirror)" "0" "$rc"

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

# 2.2 — regenerated mirrors present at docs/project/{BACKLOG,IMPL-PLAN,CHANGELOG}.md
[[ -f "$T/docs/project/BACKLOG.md" ]] \
    && t_pass "2.2a regenerated mirror BACKLOG.md present" \
    || t_fail "2.2a regenerated mirror BACKLOG.md missing"
[[ -f "$T/docs/project/IMPLEMENTATION-PLAN.md" ]] \
    && t_pass "2.2b regenerated mirror IMPLEMENTATION-PLAN.md present" \
    || t_fail "2.2b regenerated mirror IMPLEMENTATION-PLAN.md missing"
[[ -f "$T/docs/project/CHANGELOG.md" ]] \
    && t_pass "2.2c regenerated mirror CHANGELOG.md present" \
    || t_fail "2.2c regenerated mirror CHANGELOG.md missing"

# 2.3 — post-report advisory paragraph has corrected M1 wording.
assert_contains "2.3a --apply advisory says 'will BLOCK'" \
    "$out" "will BLOCK"
assert_contains "2.3b --apply advisory names exit code 31 (EXIT_GATE_FAILED)" \
    "$out" "EXIT_GATE_FAILED"
assert_contains "2.3c --apply advisory names --force-overwrite-mirror" \
    "$out" "force-overwrite-mirror"
assert_not_contains "2.3d --apply advisory does NOT have pre-M1 inverted wording" \
    "$out" "silently overwritten"

# 2.4 — Gate 2 PASS appears in the run output.
assert_contains "2.4 --apply Gate 2 PASS in output" "$out" "Gate 2 PASS"

# 2.5 — HEAD unchanged (migrator does NOT commit).
HEAD_AFTER=$(git -C "$T" rev-parse HEAD)
assert_eq "2.5 HEAD unchanged after --apply (migrator never commits)" \
    "$HEAD_BEFORE" "$HEAD_AFTER"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 3: Mode-aware divergence routing (per_entry_regenerate_mirror)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 3: mode-aware divergence routing ===\n"

# Setup: build a clean per-entry tree + regenerated mirror first, then
# hand-edit the mirror to create divergence, then probe the routing.
DV_ROOT=$(mktemp -d -t bd165-dv.XXXXXX)
DV_DIR="$DV_ROOT/docs/project/backlog"
mkdir -p "$DV_DIR"

# Minimal _rules.md + _intro.md so the mirror generator has supporting
# files admitted.
cat > "$DV_DIR/_rules.md" <<'EOF'
# Per-stream contract — project-backlog

Stream identity: project-backlog
Filename convention: ^TD-\d+\.md$

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
EOF
cat > "$DV_DIR/_intro.md" <<'EOF'
# Project backlog

Synthetic intro for divergence routing test.

---

## Active
EOF

# A single per-entry file so the mirror generator emits something.
cat > "$DV_DIR/TD-001.md" <<'EOF'
<!-- per-entry source: docs/project/backlog/TD-001.md; contract: docs/project/backlog/_rules.md -->
**TD-001 — Divergence routing test entry**
Type: TODO(version)
Status: Open
Description: Single entry for divergence routing tests.
EOF

# Source the per-entry helpers into a subshell-able function so each
# Group 3 case can probe a different routing path.
probe_mirror_routing() {
    # $1 = label; $2 = _MIGRATOR_MODE value (may be ""); $3 = force flag
    #   ("1" or "0"); $4 = expected rc; $5 = expected stream
    #   ("stdout" / "stderr") for the divergence message; $6 = needle
    #   to find in the captured stream; $7 = "unchanged" / "overwritten"
    #   for the on-disk mirror assertion.
    local label="$1" mode="$2" force="$3" exp_rc="$4" stream="$5" needle="$6" disk="$7"
    local mirror_path="$DV_ROOT/docs/project/BACKLOG.md"
    # Regenerate the mirror cleanly first (no divergence). Subshell
    # so _MIGRATOR_MODE / PE_FORCE_OVERWRITE_MIRROR don't leak.
    (
        unset _MIGRATOR_MODE
        unset PE_FORCE_OVERWRITE_MIRROR
        # shellcheck disable=SC1091
        . "$PE_LIB_DIR/_lib.sh"
        # shellcheck disable=SC1091
        . "$PE_LIB_DIR/mirror-generate.sh"
        per_entry_regenerate_mirror project-backlog "$DV_DIR" "$mirror_path" </dev/null
    ) >/dev/null 2>&1
    # Introduce divergence by appending a hand-edit to the mirror.
    {
        cat "$mirror_path"
        echo "<!-- divergence-routing test hand-edit ($label) -->"
    } > "$mirror_path.edited"
    mv "$mirror_path.edited" "$mirror_path"
    local sha_before
    sha_before=$(mirror_sha "$mirror_path")

    # Probe with the requested mode + force.
    local out err rc=0
    local tmp_stdout tmp_stderr
    tmp_stdout=$(mktemp -t bd165-stdout.XXXXXX)
    tmp_stderr=$(mktemp -t bd165-stderr.XXXXXX)
    (
        if [[ -n "$mode" ]]; then
            export _MIGRATOR_MODE="$mode"
        else
            unset _MIGRATOR_MODE
        fi
        if [[ "$force" == "1" ]]; then
            export PE_FORCE_OVERWRITE_MIRROR=1
        else
            unset PE_FORCE_OVERWRITE_MIRROR
        fi
        # EXIT_GATE_FAILED must be in env for the block-path return code
        # to land at 31 (matches the migrator-core.sh:74 constant).
        export EXIT_GATE_FAILED=31
        # shellcheck disable=SC1091
        . "$PE_LIB_DIR/_lib.sh"
        # shellcheck disable=SC1091
        . "$PE_LIB_DIR/mirror-generate.sh"
        per_entry_regenerate_mirror project-backlog "$DV_DIR" "$mirror_path" </dev/null
    ) >"$tmp_stdout" 2>"$tmp_stderr" || rc=$?
    out=$(cat "$tmp_stdout")
    err=$(cat "$tmp_stderr")
    rm -f "$tmp_stdout" "$tmp_stderr"

    assert_eq "${label}-rc" "$exp_rc" "$rc"
    if [[ "$stream" == "stdout" ]]; then
        assert_contains "${label}-stdout" "$out" "$needle"
    elif [[ "$stream" == "stderr" ]]; then
        assert_contains "${label}-stderr" "$err" "$needle"
    fi
    local sha_after
    sha_after=$(mirror_sha "$mirror_path")
    if [[ "$disk" == "unchanged" ]]; then
        if [[ "$sha_before" == "$sha_after" ]]; then
            t_pass "${label}-disk on-disk mirror UNCHANGED"
        else
            t_fail "${label}-disk expected unchanged; SHA differs ($sha_before → $sha_after)"
        fi
    elif [[ "$disk" == "overwritten" ]]; then
        if [[ "$sha_before" != "$sha_after" ]]; then
            t_pass "${label}-disk on-disk mirror OVERWRITTEN"
        else
            t_fail "${label}-disk expected overwritten; SHA unchanged"
        fi
    fi
}

# 3.1 — dry-run: rc=0, stdout has "divergence detected", mirror UNCHANGED.
probe_mirror_routing "3.1 dry-run" "dry-run" "0" "0" "stdout" \
    "divergence detected" "unchanged"

# 3.2 — apply: rc=31, stderr has "force-overwrite-mirror" + "ERROR", mirror UNCHANGED.
probe_mirror_routing "3.2 apply (block)" "apply" "0" "31" "stderr" \
    "force-overwrite-mirror" "unchanged"
# Additional 3.2 check: stderr also includes "ERROR" (the block-path
# capitalization signaling failure).
(
    unset _MIGRATOR_MODE PE_FORCE_OVERWRITE_MIRROR
    # shellcheck disable=SC1091
    . "$PE_LIB_DIR/_lib.sh"
    # shellcheck disable=SC1091
    . "$PE_LIB_DIR/mirror-generate.sh"
    per_entry_regenerate_mirror project-backlog "$DV_DIR" "$DV_ROOT/docs/project/BACKLOG.md" </dev/null
) >/dev/null 2>&1
# Reintroduce divergence for the secondary ERROR-string check.
{
    cat "$DV_ROOT/docs/project/BACKLOG.md"
    echo "<!-- 3.2 secondary ERROR-string check -->"
} > "$DV_ROOT/docs/project/BACKLOG.md.edited"
mv "$DV_ROOT/docs/project/BACKLOG.md.edited" "$DV_ROOT/docs/project/BACKLOG.md"
err_apply=$(
    export _MIGRATOR_MODE=apply
    unset PE_FORCE_OVERWRITE_MIRROR
    export EXIT_GATE_FAILED=31
    # shellcheck disable=SC1091
    . "$PE_LIB_DIR/_lib.sh"
    # shellcheck disable=SC1091
    . "$PE_LIB_DIR/mirror-generate.sh"
    per_entry_regenerate_mirror project-backlog "$DV_DIR" "$DV_ROOT/docs/project/BACKLOG.md" </dev/null 2>&1 1>/dev/null
) || true
assert_contains "3.2x apply stderr contains 'ERROR'" "$err_apply" "ERROR"

# 3.3 — resume: rc=31, mirror UNCHANGED (block path identical to apply).
probe_mirror_routing "3.3 resume (block)" "resume" "0" "31" "stderr" \
    "force-overwrite-mirror" "unchanged"

# 3.4 — apply + PE_FORCE_OVERWRITE_MIRROR=1: rc=0, stderr has the
# audit-trail "WARNING: PE_FORCE_OVERWRITE_MIRROR=1" line, mirror
# OVERWRITTEN.
probe_mirror_routing "3.4 apply force" "apply" "1" "0" "stderr" \
    "PE_FORCE_OVERWRITE_MIRROR=1" "overwritten"

rm -rf "$DV_ROOT"

# ─────────────────────────────────────────────────────────────────────────
# Group 4: Dispatcher --force-overwrite-mirror intercept on resume path
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 4: dispatcher --force-overwrite-mirror intercept (resume path) ===\n"

# The resume path in scripts/lib/migrate-v10-to-v11/resume.sh sets
# _MIGRATOR_MODE="resume" DIRECTLY and never invokes
# _migrator_parse_args. Without the dispatcher intercept in
# scripts/migrate-v10-to-v11.sh (lines 804-810), --resume
# --force-overwrite-mirror would silently ignore the flag.
#
# Strategy: prepare a paused migration (so --resume has something to
# resume), then BEFORE running --resume hand-edit one of the
# regenerated mirrors that the BD-165 sub-op will subsequently
# regenerate. Without the dispatcher intercept the flag is dropped
# and the BD-165 mirror-regen step blocks with rc=31. With the
# dispatcher intercept the flag is honored and the regen overwrites
# the hand-edit (rc=0).

prepare_paused() {
    # Build target with docs/project/*.md AND a project-customization
    # line that forces sidecar creation at S3 dispatch (so --apply
    # pauses cleanly before S4).
    local d
    d=$(make_v10_target_with_project_docs)
    printf '\n## Project customization line\n' >> "$d/CLAUDE.md"
    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "project customization" 2>/dev/null
    PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$d" >/dev/null 2>&1
    # First --apply: pauses at S3 with sidecars to resolve. Exit code 0
    # (clean pause).
    PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$d" >/dev/null 2>&1
    printf '%s\n' "$d"
}

resolve_sidecars() {
    # Resolve every paused-sidecar by touching its .resolved flag.
    local d="$1"
    local paused="$d/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
    [[ -s "$paused" ]] || return 0
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        touch "${s}.resolved"
    done <"$paused"
}

# 4.2 first (negative case — without --force-overwrite-mirror).
# Building from scratch each case ensures a clean pause state.
T=$(prepare_paused)
paused="$T/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
if [[ ! -s "$paused" ]]; then
    t_fail "4.0 prepare_paused did not produce sidecars (cannot run Group 4)"
else
    t_pass "4.0 prepare_paused produced sidecars to reconcile"
    resolve_sidecars "$T"
    # Pre-seed divergence on docs/project/BACKLOG.md — the resume run
    # will reach the BD-165 sub-op which calls per_entry_regenerate_mirror,
    # which will detect the divergence and block in apply|resume mode.
    if [[ -f "$T/docs/project/BACKLOG.md" ]]; then
        printf '\n<!-- divergence to test resume + --force-overwrite-mirror intercept -->\n' \
            >> "$T/docs/project/BACKLOG.md"
        sha_pre=$(mirror_sha "$T/docs/project/BACKLOG.md")

        # 4.2 — --resume WITHOUT --force-overwrite-mirror: expect rc=25
        # (blocked at S5d). The mirror generator's apply|resume block
        # path returns EXIT_GATE_FAILED=31, but the BD-165 decompose
        # helper wraps that failure in `fail_stage S5` which exits with
        # the framework's stage-failure formula (20 + stage number) =
        # 25 for S5. Both indicate "the regenerator blocked on
        # divergence"; the migrator-level rc is the wrapped fail_stage
        # code (25), not the raw EXIT_GATE_FAILED code (31).
        out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume "$T" 2>&1) ; rc=$?
        if [[ "$rc" -eq 25 ]]; then
            t_pass "4.2a --resume WITHOUT --force-overwrite-mirror: rc=25 (blocked at S5d via fail_stage)"
        else
            t_fail "4.2a --resume WITHOUT --force-overwrite-mirror: rc=$rc; expected 25"
        fi
        sha_post=$(mirror_sha "$T/docs/project/BACKLOG.md")
        assert_eq "4.2b --resume WITHOUT --force-overwrite-mirror: on-disk mirror UNCHANGED" \
            "$sha_pre" "$sha_post"
    else
        t_fail "4.2 docs/project/BACKLOG.md missing after paused --apply (test fixture broken)"
    fi
fi
rm -rf "$T"

# 4.1 — --resume --force-overwrite-mirror: expect rc=0 and mirror
# OVERWRITTEN; the dispatcher intercept sets _MIGRATOR_FORCE_OVERWRITE_MIRROR=1
# before dispatching to the resume handler so the BD-165 mirror-regen
# step overwrites instead of blocking.
T=$(prepare_paused)
paused="$T/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
if [[ ! -s "$paused" ]]; then
    t_fail "4.1a (skip) prepare_paused did not produce sidecars"
else
    resolve_sidecars "$T"
    if [[ -f "$T/docs/project/BACKLOG.md" ]]; then
        printf '\n<!-- divergence to test resume + --force-overwrite-mirror intercept (4.1) -->\n' \
            >> "$T/docs/project/BACKLOG.md"
        sha_pre=$(mirror_sha "$T/docs/project/BACKLOG.md")

        out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume --force-overwrite-mirror "$T" 2>&1) ; rc=$?
        if [[ "$rc" -eq 0 ]]; then
            t_pass "4.1a --resume --force-overwrite-mirror: rc=0"
        else
            t_fail "4.1a --resume --force-overwrite-mirror: rc=$rc; expected 0"
        fi
        sha_post=$(mirror_sha "$T/docs/project/BACKLOG.md")
        if [[ "$sha_pre" != "$sha_post" ]]; then
            t_pass "4.1b --resume --force-overwrite-mirror: on-disk mirror OVERWRITTEN"
        else
            t_fail "4.1b --resume --force-overwrite-mirror: mirror SHA unchanged"
        fi
        # The audit-trail warning is emitted to stderr (captured in $out
        # via 2>&1) when force-overwrite is applied.
        assert_contains "4.1c --resume --force-overwrite-mirror emits audit-trail warning" \
            "$out" "PE_FORCE_OVERWRITE_MIRROR=1"
    else
        t_fail "4.1 docs/project/BACKLOG.md missing after paused --apply"
    fi
fi
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 5: Backward compatibility (fall-through path; _MIGRATOR_MODE unset)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 5: backward compatibility (fall-through) ===\n"

# Setup a fresh per-entry tree + regenerated mirror, then hand-edit
# the mirror and invoke per_entry_regenerate_mirror WITHOUT setting
# _MIGRATOR_MODE. Expected behavior is the pre-BD-165 contract:
# rc=2 + stderr warning naming "force-overwrite-mirror". This is the
# same contract test-per-entry.sh Group 8 relies on.

BC_ROOT=$(mktemp -d -t bd165-bc.XXXXXX)
BC_DIR="$BC_ROOT/docs/project/backlog"
mkdir -p "$BC_DIR"
cat > "$BC_DIR/_rules.md" <<'EOF'
# Per-stream contract — project-backlog

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
EOF
cat > "$BC_DIR/_intro.md" <<'EOF'
# Project backlog

Synthetic intro for backward-compat test.

---

## Active
EOF
cat > "$BC_DIR/TD-001.md" <<'EOF'
<!-- per-entry source: docs/project/backlog/TD-001.md; contract: docs/project/backlog/_rules.md -->
**TD-001 — Backward-compat test entry**
Type: TODO(version)
Status: Open
Description: Single entry for backward-compat test.
EOF

(
    unset _MIGRATOR_MODE
    unset PE_FORCE_OVERWRITE_MIRROR
    # shellcheck disable=SC1091
    . "$PE_LIB_DIR/_lib.sh"
    # shellcheck disable=SC1091
    . "$PE_LIB_DIR/mirror-generate.sh"
    per_entry_regenerate_mirror project-backlog "$BC_DIR" "$BC_ROOT/docs/project/BACKLOG.md" </dev/null
) >/dev/null 2>&1
{
    cat "$BC_ROOT/docs/project/BACKLOG.md"
    echo "<!-- backward-compat divergence test hand-edit -->"
} > "$BC_ROOT/docs/project/BACKLOG.md.edited"
mv "$BC_ROOT/docs/project/BACKLOG.md.edited" "$BC_ROOT/docs/project/BACKLOG.md"

sha_pre=$(mirror_sha "$BC_ROOT/docs/project/BACKLOG.md")
tmp_bc_stderr=$(mktemp -t bd165-bc-stderr.XXXXXX)
rc_bc=0
(
    unset _MIGRATOR_MODE
    unset PE_FORCE_OVERWRITE_MIRROR
    # shellcheck disable=SC1091
    . "$PE_LIB_DIR/_lib.sh"
    # shellcheck disable=SC1091
    . "$PE_LIB_DIR/mirror-generate.sh"
    per_entry_regenerate_mirror project-backlog "$BC_DIR" "$BC_ROOT/docs/project/BACKLOG.md" </dev/null
) >/dev/null 2>"$tmp_bc_stderr" || rc_bc=$?
err_bc=$(cat "$tmp_bc_stderr")
rm -f "$tmp_bc_stderr"
sha_post=$(mirror_sha "$BC_ROOT/docs/project/BACKLOG.md")

assert_eq "5.1a fall-through (no _MIGRATOR_MODE) returns rc=2 (pre-BD-165)" "2" "$rc_bc"
assert_contains "5.1b fall-through stderr names 'force-overwrite-mirror'" \
    "$err_bc" "force-overwrite-mirror"
assert_eq "5.1c fall-through does NOT modify on-disk mirror" "$sha_pre" "$sha_post"

rm -rf "$BC_ROOT"

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
