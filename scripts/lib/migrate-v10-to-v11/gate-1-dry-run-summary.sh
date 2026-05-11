# scripts/lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh — BD-101 Gate 1
# (pre-migration, read-only).
#
# Sourced by `dry-run.sh`. Adapters never source this directly.
#
# Purpose:
#   Verify the dry-run-produced migration plan is reasonable BEFORE the
#   user approves --apply. Read-only — does not mutate any project file.
#   Surfaces what --apply would do, in clear pass/fail terms.
#
# PASS criteria:
#   - dispositions.tsv exists, is non-empty, has zero unknown-classification
#     rows (checkpoint_check_dispositions_consistency PASS)
#   - report.md was rendered to the state dir
#
# FAIL criteria:
#   - dispositions.tsv missing / empty / contains unknown-classification
#   - report.md missing
#
# Exit codes (process not exited; the function returns these as $?):
#   0   PASS — the dry-run plan is internally consistent
#   31  EXIT_GATE_FAILED — at least one check failed
#
# Public API:
#   migrate_v10_to_v11_gate1_run <state-dir>
#       Emit the gate banner + per-check lines + summary line. Return 0
#       on PASS, 31 on FAIL. Pure stdout — the caller decides whether
#       to exit the process.
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source checkpoint helpers if not already loaded. The path is relative
# to this file.
if ! declare -F checkpoint_check_dispositions_consistency >/dev/null 2>&1; then
    _gate1_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=checkpoint.sh disable=SC1091
    . "$_gate1_dir/checkpoint.sh"
fi

migrate_v10_to_v11_gate1_run() {
    local state_dir="${1:-}"

    say ""
    say "── Gate 1 — pre-migration dry-run summary (read-only) ──"
    say ""

    local fails=0

    # Check A: dispositions.tsv consistency.
    if ! checkpoint_check_dispositions_consistency "$state_dir"; then
        fails=$((fails + 1))
    fi

    # Check B: report.md rendered.
    if [[ -f "$state_dir/report.md" ]]; then
        say "  [OK]   report: report.md rendered at $state_dir/report.md"
    else
        say "  [FAIL] report: report.md not rendered  → Run: re-run --dry-run"
        fails=$((fails + 1))
    fi

    # Check C: count needs-reconciliation rows for the user. This is
    # informational — non-zero conflicts are NOT a Gate 1 fail (the
    # whole point of the two-phase workflow is that conflicts get
    # paused-and-resolved during --apply). The user just needs to see
    # how many sidecars to expect.
    local n_conflict=0
    if [[ -f "$state_dir/dispositions.tsv" ]]; then
        n_conflict=$(awk -F'\t' '$1 == "customization-detected-needs-reconciliation"' \
            "$state_dir/dispositions.tsv" 2>/dev/null | wc -l | tr -d ' ')
    fi
    if (( n_conflict > 0 )); then
        say "  [INFO] conflicts: $n_conflict file(s) will need reconciliation during --apply"
    else
        say "  [INFO] conflicts: 0 — --apply will run end-to-end without pausing"
    fi

    say ""
    if (( fails == 0 )); then
        say "── Gate 1 PASS — dry-run plan is internally consistent ──"
        return 0
    else
        say "── Gate 1 FAIL — $fails check(s) failed; do NOT proceed to --apply ──"
        return "${EXIT_GATE_FAILED:-31}"
    fi
}
