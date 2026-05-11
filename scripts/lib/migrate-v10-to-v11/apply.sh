# scripts/lib/migrate-v10-to-v11/apply.sh — BD-095 `--apply` mode for the
# v10 → v11 migrator.
#
# Sourced by `scripts/migrate-v10-to-v11.sh`. Adapters never source this
# directly. Public API is `migrate_v10_to_v11_apply_run "$@"`.
#
# Responsibilities:
#   - Verify the freshness preconditions before mutation:
#       1. A dry-run fingerprint file exists at the expected state-dir path.
#       2. The fingerprint epoch is within 24 hours of `date +%s` (§6.G).
#       3. The current working-tree fingerprint matches the recorded one
#          (target_sha256 equality) — the working tree has not drifted
#          since the dry-run was computed.
#     Each precondition failure exits with a clear, actionable message
#     telling the user exactly what to re-run.
#   - Drive the framework via `migrator_run --apply` once preconditions
#     pass. Stage sentinels are written by the apply.sh wrapper so the
#     `--resume` mode can determine which stages already ran.
#   - When dispatch produces unresolved `customization-detected-needs-
#     reconciliation` rows, write a sentinel that captures the list of
#     unresolved sidecars and pause cleanly BEFORE S4 so the user can
#     reconcile by hand and resume. This is the "two-phase" half of the
#     spec — single-shot only when no conflicts arise.
#
# Public API:
#   migrate_v10_to_v11_apply_run "$@"
#       Full --apply run with freshness guard. Bare-invocation paths in
#       the adapter call this after auto-running --dry-run when needed.
#
#   migrate_v10_to_v11_apply_check_freshness <target>
#       Read-only freshness verification. Exits the process on failure
#       (preserving the framework's "no half-applied state" invariant).
#       Echoes "OK epoch=<e> sha=<s>" on success for log clarity.
#
# Stage-sentinel layout (architecture §6 — adapter extension):
#   $STATE_DIR/sentinels/stage-S0.done
#   $STATE_DIR/sentinels/stage-S1.done
#   $STATE_DIR/sentinels/stage-S2.done
#   $STATE_DIR/sentinels/stage-S3.done
#   $STATE_DIR/sentinels/stage-S3.paused      ← present iff paused
#                                               for sidecar reconciliation
#   $STATE_DIR/sentinels/stage-S4.done
#   $STATE_DIR/sentinels/stage-S5.done
#   $STATE_DIR/sentinels/stage-S6.done
#
# `*.done` is touched immediately after the stage completes successfully.
# `S3.paused` lists one path-per-line of *.merge-conflict (a.k.a.
# *.${MIGRATOR_OWN_SIDECAR_SUFFIX}) sidecars the user must reconcile
# before --resume will proceed.
#
# Do NOT add a shebang — this file is sourced, not executed.

# 24-hour freshness window in seconds. Architecture §6.G recommendation
# (a) — 24 h friendly to "review overnight, apply tomorrow" workflow.
# Internal constant; override via env var only for unit tests (BD-095
# spec does not promise a public knob).
: "${V10_V11_DRYRUN_MAX_AGE_SECS:=86400}"

# ── Public: freshness check ────────────────────────────────────────────────

migrate_v10_to_v11_apply_check_freshness() {
    local target="${1:-}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        die "migrate_v10_to_v11_apply_check_freshness: target dir required" \
            "$EXIT_INTERNAL"
    fi
    local state_dir="$target/.pack-migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}"
    local fp="$state_dir/dry-run.fingerprint"

    if [[ ! -f "$fp" ]]; then
        {
            printf 'error: --apply requires a fresh --dry-run report\n'
            printf '  expected fingerprint: %s\n' "$fp"
            printf '  no dry-run output found for this target\n'
            printf '\n'
            printf '→ Run: PACK=%s %s --dry-run %s\n' \
                "${PACK:-/path/to/pack}" \
                "scripts/migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}.sh" \
                "$target"
            printf '  Review %s, then re-run --apply.\n' \
                "$state_dir/report.md"
        } >&2
        exit "$EXIT_NOT_BASELINE"
    fi

    # Parse the fingerprint file (key=value records, schema=1).
    local schema to_version recorded_epoch recorded_sha recorded_count
    schema=$(grep '^schema=' "$fp" | head -1 | cut -d= -f2-)
    to_version=$(grep '^to_version=' "$fp" | head -1 | cut -d= -f2-)
    recorded_epoch=$(grep '^epoch=' "$fp" | head -1 | cut -d= -f2-)
    recorded_sha=$(grep '^target_sha256=' "$fp" | head -1 | cut -d= -f2-)
    recorded_count=$(grep '^target_files=' "$fp" | head -1 | cut -d= -f2-)

    if [[ "$schema" != "1" ]]; then
        die "dry-run fingerprint schema unsupported: '$schema' (expected 1) at $fp; re-run --dry-run" \
            "$EXIT_INTERNAL"
    fi
    if [[ "$to_version" != "$MIGRATOR_TO_VERSION" ]]; then
        die "dry-run fingerprint targets $to_version but adapter is $MIGRATOR_TO_VERSION; re-run --dry-run" \
            "$EXIT_INTERNAL"
    fi
    if [[ -z "$recorded_epoch" || -z "$recorded_sha" ]]; then
        die "dry-run fingerprint at $fp is corrupt (missing epoch or sha); re-run --dry-run" \
            "$EXIT_INTERNAL"
    fi

    # Freshness window (§6.G). `date -u +%s` is portable.
    local now age max="$V10_V11_DRYRUN_MAX_AGE_SECS"
    now=$(date +%s)
    age=$(( now - recorded_epoch ))
    if (( age < 0 )); then
        # Clock-went-backwards safety: treat as stale rather than fresh.
        age=$(( max + 1 ))
    fi
    if (( age > max )); then
        {
            printf 'error: --apply refused; dry-run report is older than %ss (24h freshness window §6.G)\n' "$max"
            printf '  fingerprint: %s\n' "$fp"
            printf '  age:         %ss (max %ss)\n' "$age" "$max"
            printf '\n'
            printf '→ Run: PACK=%s %s --dry-run %s\n' \
                "${PACK:-/path/to/pack}" \
                "scripts/migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}.sh" \
                "$target"
            printf '  Re-review the report, then re-run --apply within 24h.\n'
        } >&2
        exit "$EXIT_NOT_BASELINE"
    fi

    # Working-tree fingerprint must match recorded fingerprint.
    local current_line current_sha current_count
    current_line=$(migrate_v10_to_v11_dry_run_compute_fingerprint "$target")
    current_sha=$(printf '%s' "$current_line" | awk '{print $1}')
    current_count=$(printf '%s' "$current_line" | awk '{print $2}')

    if [[ "$current_sha" != "$recorded_sha" ]]; then
        {
            printf 'error: --apply refused; working-tree fingerprint changed since --dry-run\n'
            printf '  recorded sha:  %s (files=%s)\n' "$recorded_sha" "$recorded_count"
            printf '  current sha:   %s (files=%s)\n' "$current_sha" "$current_count"
            printf '\n'
            printf 'The customization surface (CLAUDE.md / AGENTS.md / GEMINI.md /\n'
            printf '.codex/config.toml / BACKLOG.md / per-CLI agents/) has been\n'
            printf 'modified after the dry-run report was generated. The report at\n'
            printf '%s no longer reflects what --apply would do.\n' "$state_dir/report.md"
            printf '\n'
            printf '→ Run: PACK=%s %s --dry-run %s\n' \
                "${PACK:-/path/to/pack}" \
                "scripts/migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}.sh" \
                "$target"
            printf '  Re-review the report against the current working tree.\n'
        } >&2
        exit "$EXIT_DIRTY"
    fi

    say "Dry-run freshness OK: epoch=$recorded_epoch (age=${age}s) sha=${recorded_sha}"
}

# ── Internal: stage-sentinel utilities ────────────────────────────────────

# Lay down `<state-dir>/sentinels/stage-<id>.done` as an atomic touch.
_v10_v11_apply_sentinel_mark() {
    local state_dir="$1" stage="$2"
    mkdir -p "$state_dir/sentinels"
    touch "$state_dir/sentinels/stage-$stage.done"
}

# Determine whether the post-S3 dispatch produced any unresolved
# `customization-detected-needs-reconciliation` rows. If so, populate
# `<state-dir>/sentinels/stage-S3.paused` with one sidecar path per
# line and return 0 (paused). Returns 1 if no conflicts (proceed to S4).
_v10_v11_apply_collect_conflicts() {
    local state_dir="$1"
    local tsv="$state_dir/dispositions.tsv"
    [[ -f "$tsv" ]] || return 1

    local paused="$state_dir/sentinels/stage-S3.paused"
    mkdir -p "$state_dir/sentinels"

    # Each row of dispositions.tsv:
    #   <disposition>\t<class>\t<path>\t<action>\t<sidecar>\t...\t<note>
    # Pull rows whose disposition column is `customization-detected-needs-
    # reconciliation` AND whose sidecar column is non-`-`.
    awk -F'\t' \
        -v want="customization-detected-needs-reconciliation" \
        '$1 == want && $5 != "-" && $5 != "" { print $5 }' \
        "$tsv" > "$paused"

    if [[ ! -s "$paused" ]]; then
        rm -f "$paused"
        return 1
    fi
    return 0
}

# Hook injected into the adapter via `migrator_pre_dispatch_hook` so
# stage sentinels are written for stages 0..2 even before dispatch runs.
# The adapter's existing `migrator_post_dispatch_hook` calls our
# `migrate_v10_to_v11_apply_after_dispatch` to mark S3 + decide pause.
migrate_v10_to_v11_apply_pre_dispatch_hook() {
    # `_MIGRATOR_STATE_DIR` is set by the framework's parse step.
    [[ -n "${_MIGRATOR_STATE_DIR:-}" ]] || return 0
    _v10_v11_apply_sentinel_mark "$_MIGRATOR_STATE_DIR" S0
    _v10_v11_apply_sentinel_mark "$_MIGRATOR_STATE_DIR" S1
    _v10_v11_apply_sentinel_mark "$_MIGRATOR_STATE_DIR" S2
}

# Called from the adapter's `migrator_post_dispatch_hook` (immediately
# inside it, before BD-042 relocations). When conflicts are present,
# the function emits the user-facing pause message and exits 0 — the
# user will re-invoke with --resume after reconciling. When no
# conflicts, it returns and the adapter's hook continues to S4/S5.
migrate_v10_to_v11_apply_after_dispatch() {
    [[ -n "${_MIGRATOR_STATE_DIR:-}" ]] || return 0
    _v10_v11_apply_sentinel_mark "$_MIGRATOR_STATE_DIR" S3

    # Skip the conflict-pause path in --dry-run mode (we're not actually
    # going to install anything either way).
    if _migrator_is_dryrun; then
        return 0
    fi

    if _v10_v11_apply_collect_conflicts "$_MIGRATOR_STATE_DIR"; then
        say ""
        say "── PAUSED — customization-detected-needs-reconciliation ──"
        say ""
        say "Dispatch produced one or more sidecar files that need manual"
        say "reconciliation before the migration can complete. The remaining"
        say "stages (S4 relocations, S5 artifact installs, S6 report) will"
        say "run when you invoke --resume after resolving each sidecar."
        say ""
        say "Sidecars to reconcile:"
        local s
        while IFS= read -r s; do
            [[ -z "$s" ]] && continue
            say "  $s"
        done < "$_MIGRATOR_STATE_DIR/sentinels/stage-S3.paused"
        say ""
        say "For each sidecar, choose ONE of:"
        say "  (a) merge content into the destination file by hand, then"
        say "      mark resolved by either:"
        say "        - removing the .${MIGRATOR_OWN_SIDECAR_SUFFIX}"
        say "          extension (rename foo.${MIGRATOR_OWN_SIDECAR_SUFFIX}"
        say "          to foo), OR"
        say "        - touching a companion .resolved flag-file"
        say "          (touch foo.${MIGRATOR_OWN_SIDECAR_SUFFIX}.resolved)"
        say "  (b) accept the pack's destination as-is and remove the sidecar."
        say ""
        say "Then run:"
        say "  PACK=${PACK:-/path/to/pack} \\"
        say "    scripts/migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}.sh \\"
        say "    --resume $_MIGRATOR_TARGET"
        say ""
        # Use a clean exit so the framework's EXIT trap renders the
        # partial report. The trap in migrator-core.sh checks
        # `_MIGRATOR_REPORT_DONE`; we leave it 0 so the trap fires the
        # report. Exit code 0 because pausing for user input is not a
        # failure — `--resume` will complete the run.
        exit 0
    fi
}

# ── Public: apply dispatcher ───────────────────────────────────────────────

migrate_v10_to_v11_apply_run() {
    # Resolve target like the framework does, for the freshness check.
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

    # Freshness gate (§6.G). Exits the process on failure with a
    # documented exit code + actionable message.
    migrate_v10_to_v11_apply_check_freshness "$target"

    # The dry-run that produced our fingerprint also wrote the
    # `.pack-migrate-v10-to-v11/` state dir. Subsequent `git status` would
    # report those files as untracked → preflight (`_stage_preflight`)
    # fires `EXIT_DIRTY`. Add the state dir + backup dir to the
    # repo-local exclude so this orchestration artifact does not look
    # like project dirt. Idempotent — adding the same line twice is
    # harmless.
    local exclude_file gitdir
    gitdir="$(git -C "$target" rev-parse --git-dir 2>/dev/null || true)"
    if [[ -n "$gitdir" ]]; then
        # `git rev-parse --git-dir` returns a path relative to the target
        # (or absolute for git-worktree links). Normalize to absolute
        # since the test cwd is rarely the target.
        case "$gitdir" in
            /*) ;;
            *) gitdir="$target/$gitdir" ;;
        esac
        exclude_file="$gitdir/info/exclude"
        local sd_base="${state_dir##*/}"
        local bd_base="${state_dir##*/}-backup"
        mkdir -p "$gitdir/info"
        if touch "$exclude_file" 2>/dev/null; then
            grep -qxF "/$sd_base/" "$exclude_file" 2>/dev/null \
                || printf '/%s/\n' "$sd_base" >> "$exclude_file"
            grep -qxF "/$bd_base/" "$exclude_file" 2>/dev/null \
                || printf '/%s/\n' "$bd_base" >> "$exclude_file"
        fi
    fi

    # Wire stage-sentinel hooks into the adapter. The pre-dispatch hook
    # is set here (it does not exist in the adapter); the adapter's
    # existing post-dispatch hook calls our after-dispatch hook through
    # the wrapper installed below.
    migrator_pre_dispatch_hook() {
        migrate_v10_to_v11_apply_pre_dispatch_hook
    }

    # Wrap the adapter's existing post-dispatch hook so the conflict
    # check runs FIRST and the rest of the hook (BD-042 rename + legacy
    # relocation + v11 artifact install) only runs when no conflicts.
    # `_v10_to_v11_orig_post_dispatch` snapshots the original; we only
    # do this once (idempotent on re-source).
    if ! declare -F _v10_to_v11_orig_post_dispatch >/dev/null 2>&1; then
        eval "$(declare -f migrator_post_dispatch_hook \
            | sed '1s/migrator_post_dispatch_hook/_v10_to_v11_orig_post_dispatch/')"
        migrator_post_dispatch_hook() {
            migrate_v10_to_v11_apply_after_dispatch
            _v10_to_v11_orig_post_dispatch
            _v10_v11_apply_sentinel_mark "$_MIGRATOR_STATE_DIR" S4
            _v10_v11_apply_sentinel_mark "$_MIGRATOR_STATE_DIR" S5
        }
    fi

    # IMPORTANT: the framework's `_stage_libs` does `rm -rf
    # $_MIGRATOR_STATE_DIR` before re-initializing, which would obliterate
    # our just-verified `dry-run.fingerprint`. Stash it and restore it
    # after the framework's stage run begins. Also wipe the state-dir's
    # dispositions.tsv right now so the preflight idempotency check
    # (which fires on dispositions.tsv presence) does not refuse the
    # apply on the dry-run's leftover findings.
    local fp_src="$state_dir/dry-run.fingerprint"
    local fp_stash
    fp_stash=$(mktemp)
    cp "$fp_src" "$fp_stash"
    # Remove just the leftover dispositions.tsv + report.md (the artifacts
    # that trip preflight). dry-run.fingerprint stays put; _stage_libs
    # will rm -rf the state dir and we restore the fingerprint after.
    rm -f "$state_dir/dispositions.tsv" "$state_dir/report.md"

    # Hook into S6 to also mark the sentinel + restore the fingerprint
    # after _stage_libs has wiped the state dir.
    if ! declare -F _v10_to_v11_orig_post_report >/dev/null 2>&1; then
        if declare -F migrator_post_report_hook >/dev/null 2>&1; then
            eval "$(declare -f migrator_post_report_hook \
                | sed '1s/migrator_post_report_hook/_v10_to_v11_orig_post_report/')"
        else
            _v10_to_v11_orig_post_report() { :; }
        fi
        migrator_post_report_hook() {
            _v10_v11_apply_sentinel_mark "$_MIGRATOR_STATE_DIR" S6
            _v10_to_v11_orig_post_report
        }
    fi

    # Wrap _stage_libs to restore the fingerprint after it wipes the
    # state dir. (Pure additive: the original behavior is preserved;
    # we just re-stash the file the user already validated.)
    if ! declare -F _v10_to_v11_orig_stage_libs >/dev/null 2>&1; then
        eval "$(declare -f _stage_libs \
            | sed '1s/_stage_libs/_v10_to_v11_orig_stage_libs/')"
        _stage_libs() {
            _v10_to_v11_orig_stage_libs
            # Restore the dry-run fingerprint after the framework's
            # `rm -rf $_MIGRATOR_STATE_DIR`. Resume mode reads it.
            cp "$fp_stash" "$_MIGRATOR_STATE_DIR/dry-run.fingerprint"
        }
    fi

    migrator_run --apply "$@"
    local rc=$?
    rm -f "$fp_stash"
    return "$rc"
}
