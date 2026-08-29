#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-migrator-manifest.sh — unit tests for the BD-119 migrator
# framework's manifest engine + a thin slice of the stage runner.
#
# Per PLAN-BD-119.md §6 row C-4 (T-9 + T-10 unit tests). Covers:
#   - _manifest_parse happy path (4 tab-separated fields, comments,
#     blank lines, relocate-from with action argument).
#   - _manifest_parse malformed-row error (3 fields → EXIT_INTERNAL).
#   - _manifest_parse unknown-action error.
#   - _manifest_validate_trinity success (all three trinity files
#     present with matching class+action).
#   - _manifest_validate_trinity failure (only 2 of 3 trinity files in
#     manifest → abort BEFORE any mutation).
#   - _manifest_validate_trinity failure (class drift across trinity).
#   - _manifest_iterate dispatching to customization_preserve for
#     `transform`, additive write for `add`, sidecar+remove for `remove`,
#     git-mv-with-fallback for `relocate-from`.
#   - _stage_preflight idempotency: re-run on already-migrated target
#     exits EXIT_ALREADY_MIGRATED (16).
#
# Each test case runs in a subshell with its own fixtures so failures
# never bleed across tests. Read-only with respect to the pack repo
# itself; everything happens under a per-test temp directory.
#
# Usage:    bash scripts/test-migrator-manifest.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-migrator-manifest.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0

pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}

# Helper: run a bash subshell with the migrator core sourced under a
# minimal valid adapter contract. The subshell's body is provided as a
# single argument; stdout / stderr / rc are captured by the caller.
#
# Variant 1: _migrator_subshell <body-string>
#   Returns rc; stdout + stderr go to caller's terminal unless captured
#   via $(...) and 2>&1.
_migrator_subshell() {
    local body="$1"
    bash -c '
        set -uo pipefail
        PACK="'"$PACK_ROOT"'"
        export PACK
        MIGRATOR_FROM_VERSION="v10"
        MIGRATOR_TO_VERSION="v11"
        MIGRATOR_BASELINE_TAG="v10"
        MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
        MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update")
        migrator_manifest()             { :; }
        migrator_directory_sweeps()     { :; }
        migrator_relocations()          { :; }
        migrator_artifact_installs()    { :; }
        migrator_post_report_hook()     { :; }
        . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"
        '"$body"'
    '
}

# ── 1. _manifest_parse happy path ─────────────────────────────────────────
echo "== _manifest_parse happy path =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/AGENTS.md" "AGENTS.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/GEMINI.md" "GEMINI.md" "trinity" "transform"
        printf "# a comment that should be skipped\n"
        printf "\n"
        printf "%s\t%s\t%s\t%s\n" "project-template/foo.md" "foo.md" "generic" "relocate-from docs/old-foo.md"
        printf "%s\t%s\t%s\t%s\n" "project-template/bar.md" "bar.md" "generic" "add"
    }
    _manifest_parse
    printf "count=%s\n" "$_MIGRATOR_MANIFEST_COUNT"
    printf "actions=%s\n" "${_MIGRATOR_MANIFEST_ACTIONS[*]}"
    printf "relocate-arg=%s\n" "${_MIGRATOR_MANIFEST_ACTION_ARGS[3]}"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"count=5"* \
   && "$out" == *"actions=transform transform transform relocate-from add"* \
   && "$out" == *"relocate-arg=docs/old-foo.md"* ]]; then
    pass "happy-path: 5 entries parsed, comments/blanks skipped, relocate-from arg captured"
else
    fail "happy-path parse" "count=5 + actions=... + relocate-arg=..." "rc=$rc out=$out"
fi

# ── 2. _manifest_parse malformed row → EXIT_INTERNAL ─────────────────────
echo "== _manifest_parse malformed row =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\n" "only-three-fields" "is-not" "enough"
    }
    _manifest_parse 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"malformed manifest row"* ]]; then
    pass "malformed-row: 3 fields → EXIT_INTERNAL (99) with malformed message"
else
    fail "malformed-row parse" "rc=99 + 'malformed manifest row' in stderr" "rc=$rc out=$out"
fi

# ── 3. _manifest_parse unknown action → EXIT_INTERNAL ────────────────────
echo "== _manifest_parse unknown action =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "p/x.md" "x.md" "generic" "delete-please"
    }
    _manifest_parse 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"unknown manifest action"* ]]; then
    pass "unknown-action: errors with EXIT_INTERNAL"
else
    fail "unknown-action parse" "rc=99 + 'unknown manifest action'" "rc=$rc out=$out"
fi

# ── 4. _manifest_validate_trinity — all three present, matching ─────────
echo "== trinity validator: all-three-present, matching =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/AGENTS.md" "AGENTS.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/GEMINI.md" "GEMINI.md" "trinity" "transform"
    }
    _manifest_parse
    _manifest_validate_trinity
    printf "trinity-ok\n"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"trinity-ok"* ]]; then
    pass "trinity-success: all 3 with same class+action passes"
else
    fail "trinity-success" "rc=0 + trinity-ok" "rc=$rc out=$out"
fi

# ── 5. _manifest_validate_trinity — only 2 of 3 → abort ─────────────────
echo "== trinity validator: only 2 of 3 present =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/AGENTS.md" "AGENTS.md" "trinity" "transform"
    }
    _manifest_parse
    _manifest_validate_trinity 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 \
   && "$out" == *"trinity parity violation"* \
   && "$out" == *"GEMINI.md"* ]]; then
    pass "trinity-only-two: errors with EXIT_INTERNAL naming missing GEMINI.md"
else
    fail "trinity-only-two" "rc=99 + 'trinity parity violation' + GEMINI.md" "rc=$rc out=$out"
fi

# ── 6. _manifest_validate_trinity — class drift across trinity → abort ──
echo "== trinity validator: class drift =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/AGENTS.md" "AGENTS.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/GEMINI.md" "GEMINI.md" "generic" "transform"
    }
    _manifest_parse
    _manifest_validate_trinity 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"trinity parity violation"* ]]; then
    pass "trinity-class-drift: errors with EXIT_INTERNAL"
else
    fail "trinity-class-drift" "rc=99 + 'trinity parity violation'" "rc=$rc out=$out"
fi

# ── 7. _manifest_iterate dispatches `transform` via customization_preserve
echo "== _manifest_iterate transform → customization_preserve =="

# Build a minimal target tree + state-dir so the dispatch runs end-to-end
# through customization_preserve and records a disposition. We can't
# easily reach `git show v10:...` in tests, so we stub
# `migrator_baseline_to_tmp` to always return rc=1 (file missing at
# baseline) — which is the new-file-in-pack code path in three-way.sh.
fx="$FIXTURE_BASE/iterate-transform"
mkdir -p "$fx" "$fx/.claude"
cat > "$fx/CLAUDE.md" <<'EOF'
# project CLAUDE.md
EOF

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    # Wire state-dir manually (mimics what _stage_libs does).
    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    # Stub baseline_to_tmp to always return "not found at baseline" so
    # we exercise the new-file-in-pack three-way branch.
    migrator_baseline_to_tmp() { : > "$2"; return 1; }

    _manifest_parse
    _manifest_iterate

    # The TSV must contain exactly one entry for CLAUDE.md.
    awk "NR > 1 && \$3 == \"CLAUDE.md\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
# Any valid disposition token proves customization_preserve was called.
# The exact token depends on three-way's classification of the
# absent-base / present-ours / present-theirs case: `project-shadows-new-pack`
# (mapping to needs-reconciliation) when the two sides differ, which is what
# this fixture produces, and `unchanged-pack` when they are byte-identical.
# `unchanged-pack` is deliberately NOT in the allowed set below: if this
# fixture ever converged on the pack's content, that is a change of test
# meaning and should fail loudly here rather than pass silently.
known_disp_re='(merged-with-customization|pack-update-applied|project-only-file|customization-detected-needs-reconciliation|project-shadows-new-pack)'
if [[ $rc -eq 0 && "$out" =~ $known_disp_re ]]; then
    pass "transform: customization_preserve invoked, disposition recorded"
else
    fail "iterate-transform" "rc=0 + a known disposition token" "rc=$rc out=$out"
fi

# ── 8. `add` action: additive write only when target missing ────────────
echo "== add: additive write only when target missing =="

fx="$FIXTURE_BASE/iterate-add"
mkdir -p "$fx"

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        # Use a real pack file so cp succeeds.
        # tracker.toml.project-example is present in the v11 pack template
        # (renamed from tracker.toml.example per BD-135). Destination
        # basename remains tracker.toml.example client-side.
        printf "%s\t%s\t%s\t%s\n" "project-template/tracker.toml.project-example" "tracker.toml.example" "generic" "add"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    _manifest_parse
    _manifest_iterate

    # Target should now have the file
    [[ -f "'"$fx"'/tracker.toml.example" ]] && printf "wrote-add\n"
    awk "NR > 1 && \$3 == \"tracker.toml.example\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"wrote-add"* \
   && "$out" == *"pack-update-applied"* ]]; then
    pass "add: copies pack→target when target missing, records pack-update-applied"
else
    fail "iterate-add" "rc=0 + wrote-add + pack-update-applied" "rc=$rc out=$out"
fi

# ── 9. `add` action: skip when target already has file ──────────────────
echo "== add: skip when target already present =="

fx="$FIXTURE_BASE/iterate-add-existing"
mkdir -p "$fx"
printf 'pre-existing content\n' > "$fx/tracker.toml.example"

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/tracker.toml.project-example" "tracker.toml.example" "generic" "add"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    _manifest_parse
    _manifest_iterate

    # Target file should still have the original content (not clobbered)
    cat "'"$fx"'/tracker.toml.example"
    awk "NR > 1 && \$3 == \"tracker.toml.example\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"pre-existing content"* \
   && "$out" == *"project-only-file"* ]]; then
    pass "add: target already-present preserved, recorded project-only-file"
else
    fail "iterate-add-existing" "rc=0 + pre-existing-content + project-only-file" "rc=$rc out=$out"
fi

# ── 10. `remove` action: sidecar + rm when target had the file ─────────
echo "== remove: sidecar + rm when target has file =="

fx="$FIXTURE_BASE/iterate-remove"
mkdir -p "$fx"
printf 'old retired file\n' > "$fx/old-retired.md"

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/old-retired.md" "old-retired.md" "generic" "remove"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    _manifest_parse
    _manifest_iterate

    [[ ! -f "'"$fx"'/old-retired.md" ]] && printf "removed\n"
    [[ -f "'"$fx"'/old-retired.md.v10-customized" ]] && printf "sidecared\n"
    awk "NR > 1 && \$3 == \"old-retired.md\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"removed"* \
   && "$out" == *"sidecared"* \
   && "$out" == *"removed-by-design"* ]]; then
    pass "remove: file removed + sidecared + removed-by-design recorded"
else
    fail "iterate-remove" "rc=0 + removed + sidecared + removed-by-design" "rc=$rc out=$out"
fi

# ── 11. `relocate-from` action: git mv old → new (untracked fallback) ──
echo "== relocate-from: untracked plain mv fallback =="

fx="$FIXTURE_BASE/iterate-relocate"
mkdir -p "$fx"
git -C "$fx" init -q -b main
git -C "$fx" config user.email t@t
git -C "$fx" config user.name t
printf 'legacy doc\n' > "$fx/METHODOLOGY.md"
git -C "$fx" add METHODOLOGY.md
git -C "$fx" commit -q -m "init"

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" \
            "project-template/docs/pack/METHODOLOGY.md" \
            "docs/pack/METHODOLOGY.md" \
            "generic" \
            "relocate-from METHODOLOGY.md"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    _manifest_parse
    _manifest_iterate

    [[ ! -f "'"$fx"'/METHODOLOGY.md" ]] && printf "old-gone\n"
    [[ -f "'"$fx"'/docs/pack/METHODOLOGY.md" ]] && printf "new-present\n"
    awk "NR > 1 && \$3 == \"docs/pack/METHODOLOGY.md\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"old-gone"* \
   && "$out" == *"new-present"* \
   && "$out" == *"pack-update-applied"* ]]; then
    pass "relocate-from: git-mv succeeds, pack-update-applied recorded"
else
    fail "iterate-relocate" "rc=0 + old-gone + new-present + pack-update-applied" "rc=$rc out=$out"
fi

# ── 12. _stage_preflight idempotency: re-run on already-migrated tree ──
echo "== preflight: idempotency re-run → EXIT_ALREADY_MIGRATED =="

fx="$FIXTURE_BASE/preflight-idempotent"
mkdir -p "$fx" "$fx/.claude" "$fx/.pack-migrate-v10-to-v11"
printf '# CLAUDE.md\n' > "$fx/CLAUDE.md"
printf '# disposition\tclass\trel_path\taction\n' > "$fx/.pack-migrate-v10-to-v11/dispositions.tsv"
printf 'pack-update-applied\ttrinity\tCLAUDE.md\tcopied\n' >> "$fx/.pack-migrate-v10-to-v11/dispositions.tsv"
git -C "$fx" init -q -b main 2>/dev/null
git -C "$fx" config user.email t@t
git -C "$fx" config user.name t
git -C "$fx" add -A 2>/dev/null
git -C "$fx" commit -q -m "init" 2>/dev/null

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest()             { :; }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    # Set up the state without going through migrator_run (which sets
    # the EXIT trap and re-invokes parse).
    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"

    _stage_preflight 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 16 && "$out" == *"target already migrated"* ]]; then
    pass "preflight: idempotency re-run exits EXIT_ALREADY_MIGRATED (16)"
else
    fail "preflight-idempotency" "rc=16 + 'target already migrated'" "rc=$rc out=$out"
fi

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
