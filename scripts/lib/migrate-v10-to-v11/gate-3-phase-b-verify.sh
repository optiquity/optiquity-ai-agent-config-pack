# scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh — BD-101 Gate 3
# (post-Phase-B verification, conditional on tracker mode).
#
# Sourced by `apply.sh`. Adapters never source this directly.
#
# Purpose:
#   Phase-B is the optional tracker-integration phase. The v10→v11
#   migrator itself does not opt the user into tracker mode — it lays
#   down the artifacts (tracker.toml.example, ISSUE_TEMPLATE forms,
#   per-CLI pack-help) and points the user at `pack tracker init` in
#   the post-report hook. Gate 3 fires only when the user *has*
#   already opted into tracker mode at the time the migrator's --apply
#   completes (e.g. they ran `pack tracker init` between runs, or this
#   is a re-application against a tracker-mode project).
#
# SKIP criteria:
#   - tracker.toml absent at target root
#   - tracker.toml present but mode.state != "tracker" or
#     migration.forward_complete != true (`flat-file` mode)
#   In SKIP mode this gate exits 0 with a single `[INFO] skipped` line.
#
# PASS criteria (when tracker mode active):
#   - .pack-tracker/id-map.json parseable; every entry has positive int
#   - BACKLOG.md mirror present + freshness check passes
#   - `pack tracker doctor` exits 0
#
# Public API:
#   migrate_v10_to_v11_gate3_run <target> <pack>
#       Emit banner + per-check lines (or single skip line) + summary.
#       Return 0 on PASS or SKIP, 31 on FAIL.
#
# Do NOT add a shebang — this file is sourced, not executed.

if ! declare -F checkpoint_check_mapping_integrity >/dev/null 2>&1; then
    _gate3_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=checkpoint.sh disable=SC1091
    . "$_gate3_dir/checkpoint.sh"
fi

migrate_v10_to_v11_gate3_run() {
    local target="${1:-}"
    local pack="${2:-${PACK:-}}"

    say ""
    say "── Gate 3 — post-Phase-B verification (read-only; conditional on tracker mode) ──"
    say ""

    # Try to source tracker-config.sh so checkpoint_tracker_mode_active
    # uses the canonical V1 §3.2 algorithm rather than the text-grep
    # fallback. Best-effort — the helper handles the absence.
    if ! declare -F tracker_mode >/dev/null 2>&1; then
        if [[ -f "$pack/scripts/lib/tracker-config.sh" ]]; then
            # shellcheck source=/dev/null
            . "$pack/scripts/lib/tracker-config.sh" 2>/dev/null || true
        fi
    fi

    if ! checkpoint_tracker_mode_active "$target"; then
        say "  [INFO] tracker: skipped — flat-file mode (tracker.toml absent or mode.state != tracker)"
        say ""
        say "── Gate 3 SKIP — flat-file mode; Phase-B not applicable ──"
        return 0
    fi

    local fails=0
    if ! checkpoint_check_mapping_integrity "$target"; then
        fails=$((fails + 1))
    fi
    if ! checkpoint_check_mirror_freshness "$target"; then
        fails=$((fails + 1))
    fi
    if ! checkpoint_check_tracker_doctor "$target" "$pack"; then
        fails=$((fails + 1))
    fi

    say ""
    if (( fails == 0 )); then
        say "── Gate 3 PASS — Phase-B verified (tracker mode) ──"
        return 0
    else
        say "── Gate 3 FAIL — $fails check(s) failed; route through A1 UX ──"
        say ""
        say "Recovery — Phase-B (tracker mode) is recoverable WITHOUT restore-from-backup;"
        say "Phase-A is already complete. Diagnose and re-run the failed tracker step:"
        say ""
        say "  1. Inspect each [FAIL] line above."
        say "  2. Run \`pack tracker doctor\` for a per-check diagnosis and the"
        say "     specific recovery verbs to run."
        say "  3. If tracker setup is unrecoverable (mapping / mirror state corrupt),"
        say "     run \`pack tracker reset\` and re-run \`pack tracker init\`."
        say ""
        say "Note: the Phase-A working tree is intact (Gate 2 already passed). Do NOT"
        say "restore-from-backup for a Gate 3 failure — it would discard Phase-A work."
        return "${EXIT_GATE_FAILED:-31}"
    fi
}
