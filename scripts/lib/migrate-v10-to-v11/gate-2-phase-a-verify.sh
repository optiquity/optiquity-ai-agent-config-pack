# scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh — BD-101 Gate 2
# (post-Phase-A verification).
#
# Sourced by `apply.sh`. Adapters never source this directly.
#
# Purpose:
#   After Phase-A stages complete in --apply (S0..S5), verify the
#   migrated tree is internally consistent before the user proceeds to
#   any Phase-B work (tracker init, etc.).
#
# Phase-A surface checked (per BD-101 BACKLOG entry; orphan-sidecar
# check added as BD-101 retro fix MINOR-3):
#   - Trinity addenda landed (CLAUDE / AGENTS / GEMINI carry the v11
#     addenda H2 markers)
#   - HELP-FRAGMENT files match pack-side mirrors byte-for-byte
#   - Source-column entries in dispositions.tsv are consistent (no
#     unknown-classification rows; SKIPPED in resume mode — see
#     checkpoint_check_dispositions_consistency MINOR-2 fix)
#   - Relocated docs (BD-042 / BD-091) are in their new positions
#   - validate-pack.py passes against the pack source
#   - No orphan *.${MIGRATOR_OWN_SIDECAR_SUFFIX} files left at target
#
# PASS / FAIL routing:
#   FAIL routes through A1 UX. The orchestrating apply.sh calls
#   `migrate_v10_to_v11_gate2_run`; on non-zero return apply.sh exits
#   with EXIT_GATE_FAILED so `--resume` can detect "gate fix needed"
#   vs "stage internal failure".
#
# Public API:
#   migrate_v10_to_v11_gate2_run <target> <state-dir> <pack>
#       Emit gate banner + per-check lines + summary; return 0 on PASS,
#       31 (EXIT_GATE_FAILED) on FAIL.
#
# Do NOT add a shebang — this file is sourced, not executed.

if ! declare -F checkpoint_check_trinity_addenda >/dev/null 2>&1; then
    _gate2_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=checkpoint.sh disable=SC1091
    . "$_gate2_dir/checkpoint.sh"
fi

migrate_v10_to_v11_gate2_run() {
    local target="${1:-}"
    local state_dir="${2:-}"
    local pack="${3:-${PACK:-}}"

    say ""
    say "── Gate 2 — post-Phase-A verification (read-only) ──"
    say ""

    local fails=0

    if ! checkpoint_check_trinity_addenda "$target"; then
        fails=$((fails + 1))
    fi
    if ! checkpoint_check_help_fragments "$target" "$pack"; then
        fails=$((fails + 1))
    fi
    if ! checkpoint_check_dispositions_consistency "$state_dir"; then
        fails=$((fails + 1))
    fi
    if ! checkpoint_check_relocated_docs "$target"; then
        fails=$((fails + 1))
    fi
    if ! checkpoint_check_validate_pack "$pack"; then
        fails=$((fails + 1))
    fi
    # MINOR-3 (BD-101 retro fix): catch orphan *.${MIGRATOR_OWN_SIDECAR_SUFFIX}
    # sidecars that escaped the resume.sh precondition list.
    if ! checkpoint_check_no_orphan_sidecars "$target"; then
        fails=$((fails + 1))
    fi

    say ""
    if (( fails == 0 )); then
        say "── Gate 2 PASS — Phase-A verified ──"
        return 0
    else
        local _from="${MIGRATOR_FROM_VERSION:-v10}"
        local _to="${MIGRATOR_TO_VERSION:-v11}"
        local _target="${target:-<target>}"
        local _state="${state_dir:-<state-dir>}"
        say "── Gate 2 FAIL — $fails check(s) failed; route through A1 UX ──"
        say ""
        say "Recovery — fix-and-continue is NOT supported for Phase-A gate failures."
        say "The migrator's S4/S5/S6 sentinels are already marked .done, so --resume"
        say "would skip past the failed stages without re-firing the gate. The only"
        say "supported recovery is to restore the working tree from the migrator's"
        say "backup mirror and re-run --dry-run + --apply."
        say ""
        say "Note: \$PACK/scripts/restore-from-backup.sh is the LEGACY v9.3→v10 helper;"
        say "it inverts a flattened-path backup layout that does NOT apply to v10→v11."
        say "The v10→v11 migrator writes a faithful working-tree mirror at"
        say "${_state}-backup/ — restore it with rsync per the recipe below."
        say ""
        say "  1. (Optional) Inspect each [FAIL] line above to understand the defect."
        say "  2. Discard in-progress migration state + restore from backup:"
        say "       cd ${_target}"
        say "       rm -rf .pack-migrate-${_from}-to-${_to}/"
        say "       rsync -a --delete \\"
        say "           --exclude=.git/ \\"
        say "           --exclude=.pack-migrate-${_from}-to-${_to}-backup/ \\"
        say "           .pack-migrate-${_from}-to-${_to}-backup/ ./"
        say "       git diff   # inspect; should be empty if backup is faithful"
        say "       rm -rf .pack-migrate-${_from}-to-${_to}-backup/"
        say "  3. Re-run --dry-run + --apply against the restored tree:"
        say "       bash \$PACK/scripts/migrate-${_from}-to-${_to}.sh --dry-run ${_target}"
        say "       bash \$PACK/scripts/migrate-${_from}-to-${_to}.sh --apply   ${_target}"
        say ""
        say "If the underlying defect is in the pack itself, file an issue with the"
        say "[FAIL] lines above before re-running. See supporting-docs/MIGRATION-${_from}-to-${_to}.md"
        say "§Rollback for the canonical recovery recipe."
        return "${EXIT_GATE_FAILED:-31}"
    fi
}
