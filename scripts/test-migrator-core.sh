#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-migrator-core.sh — unit tests for the BD-119 migrator
# framework's CORE public-API surface (PLAN-BD-119.md §3.1, T-12).
#
# Companion to `scripts/test-migrator-manifest.sh` (engine-side coverage).
# This file exercises the *frozen public surface* in `migrator-core.sh`:
#
#   - migrator_detect_target_version <target-dir>
#       v10-shape target  → echoes "v10"
#       v11-shape target  → echoes "v11"
#       unknown target    → echoes "unknown"
#       (delegates to detect_target_pack_version; no git-repo requirement,
#       see ARCHITECTURE-BD-119 §5.1 / detect.sh)
#
#   - migrator_select_adapter <from-version>
#       from=v10 → echoes path to migrate-v10-to-v11.sh
#       from=v9  → echoes path to migrate-v9-to-v10.sh
#       from=v99 → die EXIT_INTERNAL=99 ("no adapter found")
#       missing PACK → die EXIT_PACK_INVALID=10
#       invalid from arg → die EXIT_INTERNAL=99
#
#   - migrator_baseline_to_tmp <pack-relpath> <tmpfile>
#       success path (existing pack file at $MIGRATOR_BASELINE_TAG):
#         rc=0; tmpfile non-empty
#       baseline-missing-file (file absent at tag):
#         rc=1; tmpfile empty (NOT a fatal exit; documented behaviour)
#       missing args → die EXIT_INTERNAL=99
#
#   - migrator_target_surface_for_version <vN>
#       v10 → list contains expected v10 surface entries
#       v11 → list contains expected v11 additions
#       v99 → "unknown" + rc=1
#
#   - migrator_run / migrator_dispatch
#       happy-path dry-run smoke: minimal stub adapter + git-clean target
#         exits 0 in --dry-run mode
#       dirty target → exits EXIT_DIRTY=12
#
#   - Exit-code constants are present after sourcing the core
#     (PLAN §3.5: 8 constants + EXIT_NOT_V10 synonym).
#
# Each test case runs in a subshell with isolated fixtures so failures
# never bleed across cases. Read-only with respect to the pack repo;
# everything happens under a per-test temp directory.
#
# Usage:    bash scripts/test-migrator-core.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FIXTURE_BASE="$(mktemp -d -t test-migrator-core.XXXXXX)"
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

# Helper: source migrator-core.sh inside a subshell that has a minimal
# valid adapter contract pre-declared. The caller passes a body string
# of bash to execute after sourcing. Returns the body's rc; stdout +
# stderr captured by `$(... 2>&1)` at the call site.
_core_subshell() {
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

# ── 1. Exit-code constants present (PLAN §3.5) ─────────────────────────
echo "== exit-code constants present after sourcing =="

out=$(_core_subshell '
    for c in EXIT_PACK_INVALID EXIT_NOT_GIT EXIT_DIRTY EXIT_NOT_BASELINE \
             EXIT_BASELINE_MISSING EXIT_LIB_MISSING EXIT_ALREADY_MIGRATED \
             EXIT_INTERNAL EXIT_NOT_V10; do
        if [[ -z "${!c:-}" ]]; then
            printf "missing:%s\n" "$c"
        fi
    done
    printf "EXIT_PACK_INVALID=%s EXIT_NOT_GIT=%s EXIT_DIRTY=%s\n" \
        "$EXIT_PACK_INVALID" "$EXIT_NOT_GIT" "$EXIT_DIRTY"
    printf "EXIT_NOT_BASELINE=%s EXIT_BASELINE_MISSING=%s EXIT_LIB_MISSING=%s\n" \
        "$EXIT_NOT_BASELINE" "$EXIT_BASELINE_MISSING" "$EXIT_LIB_MISSING"
    printf "EXIT_ALREADY_MIGRATED=%s EXIT_INTERNAL=%s EXIT_NOT_V10=%s\n" \
        "$EXIT_ALREADY_MIGRATED" "$EXIT_INTERNAL" "$EXIT_NOT_V10"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" != *"missing:"* \
   && "$out" == *"EXIT_PACK_INVALID=10"* \
   && "$out" == *"EXIT_NOT_GIT=11"* \
   && "$out" == *"EXIT_DIRTY=12"* \
   && "$out" == *"EXIT_NOT_BASELINE=13"* \
   && "$out" == *"EXIT_BASELINE_MISSING=14"* \
   && "$out" == *"EXIT_LIB_MISSING=15"* \
   && "$out" == *"EXIT_ALREADY_MIGRATED=16"* \
   && "$out" == *"EXIT_INTERNAL=99"* \
   && "$out" == *"EXIT_NOT_V10=13"* ]]; then
    pass "all 8 exit-code constants + EXIT_NOT_V10 synonym present with frozen values"
else
    fail "exit-code constants" "all defined with PLAN §3.5 values" "rc=$rc out=$out"
fi

# ── 2. Public-API names defined ────────────────────────────────────────
echo "== public API names defined (PLAN §3.1) =="

out=$(_core_subshell '
    for fn in migrator_run migrator_dispatch migrator_detect_target_version \
              migrator_select_adapter migrator_baseline_to_tmp \
              migrator_target_surface_for_version; do
        if ! declare -F "$fn" >/dev/null 2>&1; then
            printf "missing-fn:%s\n" "$fn"
        fi
    done
    printf "all-fn-checked\n"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" != *"missing-fn:"* && "$out" == *"all-fn-checked"* ]]; then
    pass "six public-API function names declared after sourcing core"
else
    fail "public-API names" "all 6 declared" "rc=$rc out=$out"
fi

# ── 3. migrator_detect_target_version: v10 shape ───────────────────────
echo "== migrator_detect_target_version: v10 shape =="

fx="$FIXTURE_BASE/detect-v10"
mkdir -p "$fx/.claude" "$fx/docs/pack"
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
v10 shape.
EOF
echo "# PROMPT-TEMPLATES.md" > "$fx/docs/pack/PROMPT-TEMPLATES.md"

out=$(_core_subshell '
    migrator_detect_target_version "'"$fx"'"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"v10"* ]]; then
    pass "v10-shape target → echoes v10"
else
    fail "detect-v10" "v10" "rc=$rc out=$out"
fi

# ── 4. migrator_detect_target_version: v11 shape ───────────────────────
echo "== migrator_detect_target_version: v11 shape =="

fx="$FIXTURE_BASE/detect-v11"
mkdir -p "$fx/.claude/skills/pack-help"
echo "# SKILL.md" > "$fx/.claude/skills/pack-help/SKILL.md"
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
- run `pack help` for the full verb list, or `/pack-help` in your CLI.
EOF

out=$(_core_subshell '
    migrator_detect_target_version "'"$fx"'"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"v11"* ]]; then
    pass "v11-shape target (trinity addenda fingerprint) → echoes v11"
else
    fail "detect-v11" "v11" "rc=$rc out=$out"
fi

# ── 5. migrator_detect_target_version: unknown ─────────────────────────
echo "== migrator_detect_target_version: unknown =="

fx="$FIXTURE_BASE/detect-unknown"
mkdir -p "$fx"

out=$(_core_subshell '
    migrator_detect_target_version "'"$fx"'"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"unknown"* ]]; then
    pass "empty / un-recognized target → echoes unknown"
else
    fail "detect-unknown" "unknown" "rc=$rc out=$out"
fi

# ── 6. migrator_select_adapter: positive (v10 → migrate-v10-to-v11.sh) ─
echo "== migrator_select_adapter: from=v10 finds migrate-v10-to-v11.sh =="

out=$(_core_subshell '
    migrator_select_adapter v10
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"migrate-v10-to-v11.sh"* ]]; then
    pass "from=v10 → finds scripts/migrate-v10-to-v11.sh"
else
    fail "select-adapter-v10" "path ending in migrate-v10-to-v11.sh" \
        "rc=$rc out=$out"
fi

# ── 7. migrator_select_adapter: bare-numeric form accepted ─────────────
echo "== migrator_select_adapter: from=10 (bare number) accepted =="

out=$(_core_subshell '
    migrator_select_adapter 10
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"migrate-v10-to-v11.sh"* ]]; then
    pass "from=10 (no leading v) also resolves to migrate-v10-to-v11.sh"
else
    fail "select-adapter-bare-10" "path ending in migrate-v10-to-v11.sh" \
        "rc=$rc out=$out"
fi

# ── 8. migrator_select_adapter: negative (v99 missing) ─────────────────
echo "== migrator_select_adapter: from=v99 → no adapter (EXIT_INTERNAL=99) =="

out=$(_core_subshell '
    migrator_select_adapter v99 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"no adapter found"* ]]; then
    pass "from=v99 → die EXIT_INTERNAL with 'no adapter found'"
else
    fail "select-adapter-v99" "rc=99 + 'no adapter found'" "rc=$rc out=$out"
fi

# ── 9. migrator_select_adapter: PACK unset → EXIT_PACK_INVALID ─────────
echo "== migrator_select_adapter: PACK unset → EXIT_PACK_INVALID=10 =="

# Build a body that explicitly unsets PACK before calling the helper. The
# core's check fires on `[[ -z "${PACK:-}" || ! -d ... ]]`.
out=$(bash -c '
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
    unset PACK
    migrator_select_adapter v10 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 10 && "$out" == *"PACK environment variable not set"* ]]; then
    pass "PACK unset → die EXIT_PACK_INVALID (10)"
else
    fail "select-adapter-no-pack" "rc=10 + 'PACK environment variable not set'" \
        "rc=$rc out=$out"
fi

# ── 10. migrator_select_adapter: invalid from arg → EXIT_INTERNAL ──────
echo "== migrator_select_adapter: invalid arg → EXIT_INTERNAL =="

out=$(_core_subshell '
    migrator_select_adapter "vBADARG" 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"invalid from-version"* ]]; then
    pass "from='vBADARG' (non-numeric) → die EXIT_INTERNAL with 'invalid from-version'"
else
    fail "select-adapter-bad-arg" "rc=99 + 'invalid from-version'" "rc=$rc out=$out"
fi

# ── 11. migrator_baseline_to_tmp: success path ─────────────────────────
echo "== migrator_baseline_to_tmp: pack file at v10 baseline → rc=0, tmpfile non-empty =="

tmpf="$FIXTURE_BASE/baseline-out.txt"
out=$(_core_subshell '
    rm -f "'"$tmpf"'"
    migrator_baseline_to_tmp "README.md" "'"$tmpf"'"
    rc=$?
    printf "rc=%s\n" "$rc"
    if [[ -s "'"$tmpf"'" ]]; then
        printf "tmpfile-non-empty\n"
    fi
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"rc=0"* \
   && "$out" == *"tmpfile-non-empty"* ]]; then
    pass "baseline_to_tmp success: README.md@v10 → rc=0 + non-empty tmpfile"
else
    fail "baseline_to_tmp success" "rc=0 + tmpfile-non-empty" "rc=$rc out=$out"
fi

# ── 12. migrator_baseline_to_tmp: file missing at baseline → rc=1, empty tmpfile
echo "== migrator_baseline_to_tmp: nonexistent pack-relpath at v10 → rc=1, empty tmpfile =="

tmpf="$FIXTURE_BASE/baseline-out-missing.txt"
out=$(_core_subshell '
    rm -f "'"$tmpf"'"
    migrator_baseline_to_tmp "no-such-file-at-baseline-tag.md" "'"$tmpf"'"
    rc=$?
    printf "rc=%s\n" "$rc"
    if [[ ! -s "'"$tmpf"'" ]]; then
        printf "tmpfile-empty\n"
    fi
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"rc=1"* \
   && "$out" == *"tmpfile-empty"* ]]; then
    pass "baseline_to_tmp missing-at-baseline: rc=1 + empty tmpfile (non-fatal)"
else
    fail "baseline_to_tmp missing" "rc=1 + tmpfile-empty" "rc=$rc out=$out"
fi

# ── 13. migrator_baseline_to_tmp: missing args → EXIT_INTERNAL ─────────
echo "== migrator_baseline_to_tmp: missing args → EXIT_INTERNAL =="

out=$(_core_subshell '
    migrator_baseline_to_tmp "" "" 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"usage"* ]]; then
    pass "baseline_to_tmp empty-args → die EXIT_INTERNAL with usage hint"
else
    fail "baseline_to_tmp no-args" "rc=99 + 'usage'" "rc=$rc out=$out"
fi

# ── 14. migrator_target_surface_for_version v10 ────────────────────────
echo "== migrator_target_surface_for_version v10 =="

out=$(_core_subshell '
    migrator_target_surface_for_version v10
' 2>&1)
rc=$?
# v10 surface (per migrator-core.sh §3 / architecture) includes CLAUDE.md,
# AGENTS.md, GEMINI.md, the three .claude/.codex/.gemini agent dirs, and
# .codex/config.toml + BACKLOG.md. v10 must NOT advertise the v11-only
# additions (HELP-FRAGMENT.md, tracker.toml.example, ISSUE_TEMPLATE).
if [[ $rc -eq 0 \
   && "$out" == *"CLAUDE.md"* \
   && "$out" == *"AGENTS.md"* \
   && "$out" == *"GEMINI.md"* \
   && "$out" == *".claude/agents"* \
   && "$out" == *".codex/agents"* \
   && "$out" == *".gemini/agents"* \
   && "$out" == *".codex/config.toml"* \
   && "$out" == *"BACKLOG.md"* \
   && "$out" != *"HELP-FRAGMENT.md"* \
   && "$out" != *"tracker.toml.example"* \
   && "$out" != *"ISSUE_TEMPLATE"* ]]; then
    pass "v10 surface lists 8 expected v10 entries; excludes v11-only additions"
else
    fail "target_surface_v10" "v10 entries present + v11 entries absent" \
        "rc=$rc out=$out"
fi

# ── 15. migrator_target_surface_for_version v11 ────────────────────────
echo "== migrator_target_surface_for_version v11 =="

out=$(_core_subshell '
    migrator_target_surface_for_version v11
' 2>&1)
rc=$?
# v11 inherits v10's surface and adds the v11-only additions.
if [[ $rc -eq 0 \
   && "$out" == *"CLAUDE.md"* \
   && "$out" == *"AGENTS.md"* \
   && "$out" == *"GEMINI.md"* \
   && "$out" == *"docs/pack/HELP-FRAGMENT.md"* \
   && "$out" == *"tracker.toml.example"* \
   && "$out" == *".github/ISSUE_TEMPLATE/work-item.yml"* \
   && "$out" == *".claude/skills/pack-help/SKILL.md"* \
   && "$out" == *".codex/skills/pack-help/SKILL.md"* \
   && "$out" == *".gemini/commands/pack-help.toml"* ]]; then
    pass "v11 surface inherits v10 + adds HELP-FRAGMENT/tracker.toml.example/ISSUE_TEMPLATE/per-CLI pack-help"
else
    fail "target_surface_v11" "v10 entries + v11 additions" "rc=$rc out=$out"
fi

# ── 16. migrator_target_surface_for_version v99 → unknown / rc=1 ──────
echo "== migrator_target_surface_for_version v99 → unknown =="

out=$(_core_subshell '
    migrator_target_surface_for_version v99
    printf "post-rc=%s\n" "$?"
' 2>&1)
rc=$?
if [[ "$out" == *"unknown"* && "$out" == *"post-rc=1"* ]]; then
    pass "target_surface_for_version v99 → echoes 'unknown' + rc=1"
else
    fail "target_surface_v99" "'unknown' + rc=1" "rc=$rc out=$out"
fi

# ── 17. migrator_run dry-run smoke happy path ──────────────────────────
echo "== migrator_run --dry-run smoke happy path =="

# Build a minimal target: git repo, clean, with CLAUDE.md + .claude/.
# Adapter declares an empty manifest + minimal hooks. Dry-run must not
# mutate the target; it should exit 0 after preflight + libs init +
# manifest validation (empty manifest, empty sweeps).
fx="$FIXTURE_BASE/run-dryrun-happy"
mkdir -p "$fx/.claude"
printf '# CLAUDE.md\n' > "$fx/CLAUDE.md"
git -C "$fx" init -q -b main
git -C "$fx" config user.email t@t
git -C "$fx" config user.name t
git -C "$fx" add -A
git -C "$fx" commit -q -m "init"

out=$(_core_subshell '
    migrator_run --dry-run "'"$fx"'" 2>&1
' 2>&1)
rc=$?
# Tolerate prior_sidecars list of ("pre-update") because no .pre-update
# files exist in the fresh fixture. State dir + dispositions.tsv may be
# created by _stage_libs (init); that is dry-run-tolerant per stages.
if [[ $rc -eq 0 ]]; then
    # Sanity: target's CLAUDE.md must still be the original placeholder
    # (no body rewrite) — dry-run must not have mutated it.
    body=$(cat "$fx/CLAUDE.md" 2>/dev/null)
    if [[ "$body" == "# CLAUDE.md" ]]; then
        pass "migrator_run --dry-run: rc=0 on minimal happy path; CLAUDE.md untouched"
    else
        fail "migrator_run dry-run mutated CLAUDE.md" "# CLAUDE.md" "$body"
    fi
else
    fail "migrator_run dry-run happy path" "rc=0" "rc=$rc out=$out"
fi

# ── 18. migrator_run on dirty target → EXIT_DIRTY (12) ────────────────
echo "== migrator_run on dirty target → EXIT_DIRTY (12) =="

fx="$FIXTURE_BASE/run-dirty"
mkdir -p "$fx/.claude"
printf '# CLAUDE.md\n' > "$fx/CLAUDE.md"
git -C "$fx" init -q -b main
git -C "$fx" config user.email t@t
git -C "$fx" config user.name t
git -C "$fx" add -A
git -C "$fx" commit -q -m "init"
# Now make the working tree dirty: add an untracked file.
printf 'untracked\n' > "$fx/dirty-marker.txt"

out=$(_core_subshell '
    migrator_run "'"$fx"'" 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 12 && "$out" == *"working tree is dirty"* ]]; then
    pass "migrator_run on dirty target → EXIT_DIRTY (12) with 'working tree is dirty'"
else
    fail "migrator_run dirty" "rc=12 + 'working tree is dirty'" "rc=$rc out=$out"
fi

# ── 19. migrator_dispatch arity guard ─────────────────────────────────
echo "== migrator_dispatch: zero-args → EXIT_INTERNAL =="

out=$(_core_subshell '
    migrator_dispatch 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"expected exactly one argument"* ]]; then
    pass "migrator_dispatch with no args → die EXIT_INTERNAL (arity guard)"
else
    fail "migrator_dispatch no-args" "rc=99 + 'expected exactly one argument'" \
        "rc=$rc out=$out"
fi

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
