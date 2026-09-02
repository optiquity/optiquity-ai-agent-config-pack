# scripts/lib/migrate-v10-to-v11/resume.sh — BD-095 `--resume` mode for the
# v10 → v11 migrator.
#
# Sourced by `scripts/migrate-v10-to-v11.sh`. Adapters never source this
# directly. Public API is `migrate_v10_to_v11_resume_run "$@"`.
#
# Resume contract (architecture §6.H):
#   - Forward-only. The state-dir sentinels record which stages already
#     completed; resume continues from the next pending stage. A user
#     who wants to "rewind" must restore from the backup directory and
#     start over.
#   - Accepts BOTH conflict-resolution signals interchangeably:
#       (a) companion `.resolved` flag-file alongside the sidecar
#           (e.g. `foo.v10-customized.resolved`)
#       (b) extension removal (e.g. `foo.v10-customized` deleted because
#           the user merged content and renamed back to `foo`)
#   - Refuses to proceed if any sidecar listed in
#     `<state-dir>/sentinels/stage-S3.paused` is still unresolved (neither
#     signal observed). Lists each unresolved file with the two ways to
#     mark it resolved.
#   - On success runs the remaining stages (S4, S5, S6) using the SAME
#     framework helpers the apply path uses (we do not re-implement
#     dispatch — those stages are pure post-dispatch actions).
#
# Public API:
#   migrate_v10_to_v11_resume_run "$@"
#       Verify each paused sidecar is resolved, then run S4..S6 against
#       the existing state-dir + already-mutated working tree. Returns 0
#       on success; non-zero with an actionable error on each failure
#       mode (no in-progress migration, unresolved sidecars, etc.).
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Internal: resume-conflict scanner ─────────────────────────────────────
#
# For each sidecar path recorded in `stage-S3.paused`, return one of:
#   resolved-flag      — `<sidecar>.resolved` file exists alongside
#   resolved-removed   — sidecar file is gone (extension removed / deleted)
#   unresolved         — sidecar present and no `.resolved` flag
#
# Echoes `<status>\t<sidecar>` rows to stdout, one per input row. Pure
# read-only.
#
# Per ARCHITECTURE-SIDECAR-LIFECYCLE.md §6.5 (option (e) extraction), the
# per-sidecar classification logic lives in `checkpoint_classify_sidecar`
# (scripts/lib/migrate-v10-to-v11/checkpoint.sh). This helper is a thin
# loop wrapper that forwards each input row to the shared classifier so
# Gate 2's C3 (orphan-sidecar) and the resume.sh C2 precondition can never
# diverge on the BD-095 two-signal `.resolved` / removed contract. The
# emitted status tokens (`resolved-flag` / `resolved-removed` /
# `unresolved`) are unchanged; downstream consumers at line ~143 below
# depend on those exact strings.
_v10_v11_resume_classify_sidecars() {
    local paused="$1"
    # Defense-in-depth: under the v10→v11 adapter, checkpoint.sh is
    # always sourced before this function is called (see
    # scripts/migrate-v10-to-v11.sh:629 + 634); but if a future test
    # harness or direct-source scenario invokes resume.sh in isolation,
    # source the classifier on demand. Mirrors the gate-2-phase-a-verify.sh
    # idiom.
    if ! declare -F checkpoint_classify_sidecar >/dev/null 2>&1; then
        local _resume_dir
        _resume_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # shellcheck source=checkpoint.sh disable=SC1091
        . "$_resume_dir/checkpoint.sh"
    fi
    local s status
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        status=$(checkpoint_classify_sidecar "$s")
        printf '%s\t%s\n' "$status" "$s"
    done < "$paused"
}

# ── Public: resume dispatcher ─────────────────────────────────────────────

migrate_v10_to_v11_resume_run() {
    # Resolve target.
    local target="."
    local arg
    for arg in "$@"; do
        case "$arg" in
            -*|--*) ;;
            *) target="$arg"; break ;;
        esac
    done
    target="$(cd "$target" 2>/dev/null && pwd || printf '%s' "$target")"
    local state_dir="$target/.pack-migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}"
    local paused="$state_dir/sentinels/stage-S3.paused"
    local s3_done="$state_dir/sentinels/stage-S3.done"

    # Precondition: a paused migration must exist. The state-dir alone is
    # not enough — `--apply` writes the dispositions.tsv even on success.
    # `stage-S3.done` plus `stage-S3.paused` is the unambiguous signal of
    # a paused-for-reconciliation run.
    if [[ ! -d "$state_dir" ]]; then
        {
            printf 'error: --resume requires an in-progress migration\n'
            printf '  expected state dir: %s\n' "$state_dir"
            printf '  no migration state found for this target\n'
            printf '\n'
            printf '→ Run --dry-run + --apply first; --resume only follows a\n'
            printf '  paused dispatch (sidecars present).\n'
        } >&2
        exit "$EXIT_INTERNAL"
    fi
    if [[ ! -f "$s3_done" ]]; then
        {
            printf 'error: --resume requires S3 dispatch to have completed\n'
            printf '  missing sentinel: %s\n' "$s3_done"
            printf '\n'
            printf '→ Run --dry-run + --apply first; --resume only follows a\n'
            printf '  paused dispatch.\n'
        } >&2
        exit "$EXIT_INTERNAL"
    fi
    if [[ ! -f "$paused" ]]; then
        {
            printf 'error: --resume found no paused conflicts to resolve\n'
            printf '  no sentinel: %s\n' "$paused"
            printf '\n'
            printf 'The previous --apply completed without sidecars. Nothing\n'
            printf 'to resume. If S4/S5/S6 did not run for some reason, restore\n'
            printf 'from the backup at %s-backup and re-run --apply.\n' "$state_dir"
        } >&2
        exit "$EXIT_INTERNAL"
    fi

    # Forward-only check: if any *.done sentinel for S4/S5/S6 already
    # exists, the run already completed past the pause point — refuse to
    # rewind.
    local later_stage
    for later_stage in S4 S5 S6; do
        if [[ -f "$state_dir/sentinels/stage-$later_stage.done" ]]; then
            {
                printf 'error: --resume is forward-only; stage %s already complete\n' "$later_stage"
                printf '  sentinel: %s\n' "$state_dir/sentinels/stage-$later_stage.done"
                printf '\n'
                printf 'The migration has already progressed past the pause point.\n'
                printf 'To re-run from the beginning, restore from\n'
                printf '%s-backup and start over with --dry-run + --apply.\n' "$state_dir"
            } >&2
            exit "$EXIT_INTERNAL"
        fi
    done

    # Classify sidecars. List unresolved ones with actionable instructions.
    #
    # F11 (BD-095 retro fix): build the unresolved listing in a single awk
    # pass over the classification output (was: re-awk inside the error
    # block). `unresolved_list` carries the rendered "  $sidecar" lines;
    # `unresolved` is the count of those lines.
    local classification unresolved=0 resolved=0 unresolved_list=""
    classification=$(_v10_v11_resume_classify_sidecars "$paused")
    if [[ -z "$classification" ]]; then
        # paused file is empty / blank-only — treat as no conflicts.
        warn "stage-S3.paused exists but lists no sidecars; proceeding to S4"
    else
        unresolved_list=$(printf '%s\n' "$classification" \
            | awk -F'\t' '$1 == "unresolved" {print "  " $2}')
        if [[ -n "$unresolved_list" ]]; then
            # `wc -l` counts trailing-newline-terminated lines; the
            # pipeline above always emits a trailing newline per match
            # so this matches the row count exactly.
            unresolved=$(printf '%s\n' "$unresolved_list" \
                | grep -c '^  ' || true)
        fi
        resolved=$(printf '%s\n' "$classification" \
            | awk -F'\t' '$1 != "unresolved" && $1 != "" {c++} END {print c+0}')
    fi

    if (( unresolved > 0 )); then
        {
            printf 'error: --resume refused; %s sidecar(s) still unresolved\n' "$unresolved"
            printf '\n'
            # BD-287 (§2.1): mirror the apply-menu / report prose split — HOW to
            # resolve depends on the file type. Accept-pack for an auto-merged
            # prose file (live copy still marked) means re-installing the pack
            # template; a trinity/script/agent sidecar already holds the pack
            # version. The resolve-merge-conflicts skill folds a trinity sidecar
            # section-aware; scripts/agents are re-applied by hand.
            printf 'Resolve each by ONE of (how depends on the file type; see the\n'
            printf 'report section "Files needing manual reconciliation"):\n'
            printf '  (a) accept the pack version — for an auto-merged prose file whose\n'
            printf '      live copy still has conflict markers, re-install the pack\n'
            printf '      template over the live file; for a trinity/script/agent\n'
            printf '      sidecar the live file already holds the pack version. Then\n'
            printf '      remove (rename) the sidecar.\n'
            printf '  (b) keep your version — restore the sidecar over the live file,\n'
            printf '      then remove (rename) the sidecar.\n'
            printf '  (c) merge both — resolve conflict markers by hand, or run the\n'
            printf '      resolve-merge-conflicts skill (it folds a trinity sidecar\n'
            printf '      section-aware; scripts/agents are re-applied by hand), then\n'
            printf '      `touch <sidecar>.resolved`. The skill is not installed in\n'
            printf '      this project until the migration finishes — read it from\n'
            printf '      the pack you are migrating from:\n'
            printf '        %s/project-template/skills/resolve-merge-conflicts/SKILL.md\n' \
                "$PACK"
            printf '\n'
            printf 'Unresolved sidecars:\n'
            printf '%s\n' "$unresolved_list"
            printf '\n'
            printf 'Then re-run:\n'
            # F12 (BD-095 retro fix): drop `:-/path/to/pack` fallback;
            # by the time --resume is invoked, the prior --apply has
            # validated PACK upstream.
            printf '  PACK=%s scripts/migrate-%s-to-%s.sh --resume %s\n' \
                "$PACK" \
                "$MIGRATOR_FROM_VERSION" "$MIGRATOR_TO_VERSION" \
                "$target"
        } >&2
        exit "$EXIT_DIRTY"
    fi

    say "── --resume — sidecar reconciliation verified ──"
    say "  resolved sidecars: $resolved"
    say ""
    say "Continuing from S4 (relocations + artifact installs + report)..."
    say ""

    # Run S4..S6 directly. We do NOT call `migrator_run` here because
    # the framework would re-run S0..S3 (and the S0 idempotency check
    # would fire because dispositions.tsv already exists). Instead, we
    # source the framework + libs and invoke the post-S3 stages by hand,
    # mirroring `_migrator_run_stages`'s tail.
    #
    # The adapter has already sourced migrator-core.sh; helpers are
    # therefore in scope. We need to re-load three-way + customization-
    # preserve + customization-report because `_stage_libs` is what
    # normally sources them.
    export _CP_PACK_ROOT="$PACK"
    if ! declare -F customization_preserve_init >/dev/null 2>&1; then
        # shellcheck source=/dev/null
        . "$PACK/scripts/lib/three-way.sh"
        # shellcheck source=/dev/null
        . "$PACK/scripts/lib/customization-preserve.sh"
        # shellcheck source=/dev/null
        . "$PACK/scripts/lib/customization-report.sh"
    fi

    # Set internal state the stage helpers read so they target the
    # correct dirs (they normally inherit these from `_migrator_parse_args`).
    _MIGRATOR_TARGET="$target"
    _MIGRATOR_STATE_DIR="$state_dir"
    _MIGRATOR_BACKUP_DIR="$state_dir-backup"
    _MIGRATOR_DRY_RUN="0"
    _MIGRATOR_MODE="resume"
    _MIGRATOR_REPORT_DONE="0"
    TARGET="$target"
    STATE_DIR="$state_dir"
    BACKUP_DIR="$state_dir-backup"

    # Re-init customization-preserve so `_cp_record` writes to the
    # existing dispositions.tsv (`customization_preserve_init` truncates
    # — we DO want a fresh disposition file for the post-S3 stages so
    # the resume report reflects what happened during resume; the pre-
    # resume report.md remains in place under the same name and will
    # be overwritten by `_stage_report` below).
    customization_preserve_init "$state_dir" ".${MIGRATOR_OWN_SIDECAR_SUFFIX}"

    # Run the post-S3 stages.
    if declare -F migrator_post_dispatch_hook >/dev/null 2>&1; then
        # In resume mode the conflict pause shouldn't fire (we just
        # verified everything is resolved); the after-dispatch hook
        # checks `S3.paused` though, so remove it so the wrapper does
        # not loop. Sentinels are touched by the wrapper as it goes.
        rm -f "$state_dir/sentinels/stage-S3.paused"
        # Skip the apply-mode wrapper if it is installed; call the
        # original v10→v11 hook directly so we don't re-invoke the
        # paused/conflict check.
        if declare -F _v10_to_v11_orig_post_dispatch >/dev/null 2>&1; then
            _v10_to_v11_orig_post_dispatch
        else
            migrator_post_dispatch_hook
        fi
    fi
    _v10_v11_apply_sentinel_mark "$state_dir" S4
    _v10_v11_apply_sentinel_mark "$state_dir" S5

    # F10 (BD-095 retro fix): `_stage_relocations` and
    # `_stage_artifact_installs` are no-ops in the v10→v11 adapter
    # because `migrator_relocations` / `migrator_artifact_installs`
    # are declared empty (see migrate-v10-to-v11.sh lines ~120-128).
    # The post-dispatch hook above performs the equivalent BD-104 +
    # BD-042 + v11 artifact install work. We keep the stage calls so
    # the resume sequence is byte-equivalent to `_migrator_run_stages`'s
    # tail and the framework's no-op-when-empty contract is exercised.
    # Future per-version `resume.sh` files where the adapter declares
    # non-empty `migrator_relocations` / `migrator_artifact_installs`
    # rows MUST audit this sequence — re-running relocations after S3
    # paused-for-reconciliation could double-rename. The forward-only
    # contract assumes "S4..S6 haven't run"; copy this verbatim only
    # after verifying the adapter's relocations + artifact-installs
    # are also empty.
    _stage_relocations
    _stage_artifact_installs
    _stage_report
    _MIGRATOR_REPORT_DONE="1"
    _v10_v11_apply_sentinel_mark "$state_dir" S6

    if declare -F migrator_post_report_hook >/dev/null 2>&1; then
        if declare -F _v10_to_v11_orig_post_report >/dev/null 2>&1; then
            _v10_to_v11_orig_post_report
        else
            migrator_post_report_hook
        fi
    fi

    # BD-101 Gate 2 + Gate 3 — fire after the resumed Phase-A completes.
    # The apply.sh `migrator_post_report_hook` wrapper handles gates when
    # the run is non-paused; resume.sh runs S4..S6 directly (bypassing
    # the wrapper), so we invoke the gates explicitly here.
    if declare -F migrate_v10_to_v11_gate2_run >/dev/null 2>&1; then
        if ! migrate_v10_to_v11_gate2_run \
                "$target" \
                "$state_dir" \
                "${PACK:-}"; then
            exit "${EXIT_GATE_FAILED:-31}"
        fi
    fi
    if declare -F migrate_v10_to_v11_gate3_run >/dev/null 2>&1; then
        if ! migrate_v10_to_v11_gate3_run \
                "$target" \
                "${PACK:-}"; then
            exit "${EXIT_GATE_FAILED:-31}"
        fi
    fi

    say ""
    say "── --resume complete ──"
    return 0
}
