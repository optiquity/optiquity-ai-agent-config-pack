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
# Phase-A surface checked (per BD-101 BACKLOG entry):
#   - Trinity addenda landed (CLAUDE / AGENTS / GEMINI carry the v11
#     addenda H2 markers)
#   - HELP-FRAGMENT files match pack-side mirrors byte-for-byte
#   - Source-column entries in dispositions.tsv are consistent (no
#     unknown-classification rows)
#   - Relocated docs (BD-042 / BD-091) are in their new positions
#   - validate-pack.py passes against the pack source
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
    say "── Gate 2 — post-Phase-A verification ──"
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

    say ""
    if (( fails == 0 )); then
        say "── Gate 2 PASS — Phase-A verified ──"
        return 0
    else
        say "── Gate 2 FAIL — $fails check(s) failed; route through A1 UX ──"
        say ""
        say "Recovery — fix-and-continue is NOT supported for Phase-A gate failures."
        say "The migrator's S4/S5/S6 sentinels are already marked .done, so --resume"
        say "would skip past the failed stages without re-firing the gate. The only"
        say "supported recovery is restore-from-backup + re-run:"
        say ""
        say "  1. (Optional) Inspect each [FAIL] line above to understand the defect."
        say "  2. Restore from backup:"
        say "       bash \$PACK/scripts/restore-from-backup.sh ${state_dir}-backup"
        say "  3. Re-run --dry-run + --apply against the restored tree:"
        say "       bash \$PACK/scripts/migrate-${MIGRATOR_FROM_VERSION:-v10}-to-${MIGRATOR_TO_VERSION:-v11}.sh --dry-run ${target}"
        say "       bash \$PACK/scripts/migrate-${MIGRATOR_FROM_VERSION:-v10}-to-${MIGRATOR_TO_VERSION:-v11}.sh --apply   ${target}"
        say ""
        say "If the underlying defect is in the pack itself, file an issue with the"
        say "[FAIL] lines above before re-running."
        return "${EXIT_GATE_FAILED:-31}"
    fi
}
