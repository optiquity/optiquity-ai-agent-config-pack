# scripts/lib/migrator-core.sh — orchestrator for the BD-119 N→N+1 migrator
# framework.
#
# Sourced by per-version adapters (e.g. `scripts/migrate-v10-to-v11.sh`) and by
# external harnesses (BD-114 `dry-run-real-ot.sh`). Adapters declare a small
# version-specific contract via `MIGRATOR_*` environment variables and a set
# of hook functions, then call `migrator_run "$@"`. Every shared safety
# concern (preflight, backup, three-way dispatch, report rendering, exit
# codes, dry-run, idempotency) lives here so per-version adapters can never
# regress the N→N+1 safety contract.
#
# Architecture: maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md
# Plan:         maintenance-docs/v11-implementation/PLAN-BD-119.md §3
#
# State at C-3 (this file):
#   - Public-API surface FROZEN per PLAN §3 (seven function names + nine
#     exit-code constants + EXIT_NOT_V10 synonym). The ninth constant —
#     EXIT_GATE_FAILED=31 — was added by BD-101 (verification gates) as
#     an additive extension to the frozen surface; existing constants
#     10..16, 99 retain their semantics. The seventh function —
#     migrator_pause() — was likewise added by BD-282 as an additive
#     extension: adapters call it instead of `exit 0` to signal a
#     deliberate, --resume-able pause so the EXIT trap renders a PAUSED
#     (not FAILED) report. Adapters should still reference constants by
#     name, never by literal value.
#   - Stage sequencer + arg parser + EXIT trap + adapter-contract reader
#     are LIVE (this is T-7 from PLAN §4).
#   - Public-API helpers `migrator_detect_target_version`,
#     `migrator_select_adapter`, `migrator_baseline_to_tmp`,
#     `migrator_target_surface_for_version` are LIVE (T-11).
#   - `_stage_*` bodies in `migrator-stages.sh` and `_manifest_*` bodies in
#     `migrator-manifest.sh` remain stubs that return 1 — bodies land in
#     C-4 (PLAN T-8, T-9, T-10). An end-to-end `migrator_run` call will
#     therefore reach `_stage_preflight` and fail there; this is expected
#     and lets the framework be wired up before stage bodies are written.
#
# Internal env-var conventions:
#   MIGRATOR_*   adapter-declared (read by core; FROZEN public surface)
#   _MIGRATOR_*  core-internal (reset between runs; not part of public surface)
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Source sibling libraries ───────────────────────────────────────────────
#
# Resolve the directory containing this file independent of $PWD, so the
# sibling libs load whether the adapter sources by absolute or relative
# path. macOS bash 3.2 compatible — no `${BASH_SOURCE[0]:A}` zsh-isms.

_migrator_core_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=migrator-stages.sh disable=SC1091
. "$_migrator_core_dir/migrator-stages.sh"
# shellcheck source=migrator-manifest.sh disable=SC1091
. "$_migrator_core_dir/migrator-manifest.sh"
# shellcheck source=migrator-skills.sh disable=SC1091
# BD-147 — skill-rename / skill-split adapter (sibling lib per
# ARCHITECTURE-BD-119.md §3.1). Adapters call
# `migrator_skill_rename` (and forward-declared `migrator_skill_split`)
# from inside their post-dispatch hooks; the BD-035 v10→v11 split is the
# first consumer.
. "$_migrator_core_dir/migrator-skills.sh"

# ── Exit-code constants (PLAN §3.5; FROZEN) ────────────────────────────────
#
# Adapters reference these by name, never by literal value. Stage failures
# use the `20+N` formula computed by `fail_stage` (see helpers below).

readonly EXIT_PACK_INVALID=10
readonly EXIT_NOT_GIT=11
readonly EXIT_DIRTY=12
readonly EXIT_NOT_BASELINE=13
readonly EXIT_BASELINE_MISSING=14
readonly EXIT_LIB_MISSING=15
readonly EXIT_ALREADY_MIGRATED=16
# BD-101 — gate failure (verification gate detected a defect post-stage).
# Distinct from stage failure (codes 20..30) so `--resume` can detect a
# gate-fix-and-retry workflow vs a stage-internal failure.
readonly EXIT_GATE_FAILED=31
readonly EXIT_INTERNAL=99

# Back-compat synonym — the monolithic v10→v11 migrator exposed
# `EXIT_NOT_V10`. Architecture §C1 / PLAN §3.5 require the rename to
# `EXIT_NOT_BASELINE` plus a synonym so any external caller that grepped the
# old name still resolves. Adapters SHOULD use `EXIT_NOT_BASELINE` directly.
readonly EXIT_NOT_V10="$EXIT_NOT_BASELINE"

# ── Logging helpers (replaces the monolith's say/info/warn/die/fail_stage) ─
#
# These names match the monolith's helpers verbatim so behavior-preservation
# diffs against the pre-refactor stdout do not regress on banner text.
# Defined unconditionally — adapters SHOULD NOT redefine them. (Bash has no
# private-namespace mechanism; convention is the only enforcement.)

say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$1" >&2; exit "${2:-$EXIT_INTERNAL}"; }

# fail_stage <stage-id> <message>
#   stage-id is "S0".."S6" (or any "S<N>" pattern). Numeric exit code is
#   `20 + N`, capped at 30 (PLAN §3.5 + monolith parity at lines 52–59).
fail_stage() {
    local stage="$1" msg="$2"
    local n="${stage#S}"
    local code=$(( 20 + n ))
    (( code > 30 )) && code=30
    printf 'error: stage %s failed: %s\n' "$stage" "$msg" >&2
    exit "$code"
}

# ── Internal state (reset on every migrator_run / migrator_dispatch call) ──
#
# Adapters MUST NOT read or write these. They are documented here so the
# core's contract is explicit — naming convention is `_MIGRATOR_*`.
#
#   _MIGRATOR_TARGET                  absolute path to the target project
#   _MIGRATOR_DRY_RUN                 "1" if --dry-run, else "0"
#   _MIGRATOR_MODE                    one of: apply | dry-run | resume
#   _MIGRATOR_STATE_DIR               "$_MIGRATOR_TARGET/.pack-migrate-<from>-to-<to>"
#   _MIGRATOR_BACKUP_DIR              "$_MIGRATOR_STATE_DIR-backup"
#   _MIGRATOR_REPORT_DONE             "1" once `_stage_report` has run; gates
#                                     the EXIT trap's truthful-report-on-
#                                     failure guarantee so a failed run still
#                                     attempts to render the report exactly
#                                     once.
#   _MIGRATOR_PAUSED                  "1" once `migrator_pause` has run; tells
#                                     the EXIT trap to render a PAUSED (not
#                                     FAILED) report for a deliberate,
#                                     --resume-able pause. Only `migrator_pause`
#                                     sets it; genuine errors leave it "0".

_migrator_reset_state() {
    _MIGRATOR_TARGET=""
    _MIGRATOR_DRY_RUN="0"
    _MIGRATOR_MODE="apply"
    _MIGRATOR_STATE_DIR=""
    _MIGRATOR_BACKUP_DIR=""
    _MIGRATOR_REPORT_DONE="0"
    _MIGRATOR_PAUSED="0"
}
_migrator_reset_state

# ── Adapter-contract reader ────────────────────────────────────────────────
#
# Validates the adapter declared the required MIGRATOR_* variables and
# defined the required hook functions before `migrator_run` was called.
# Errors with EXIT_INTERNAL when the adapter is malformed — this is a
# coding bug in the adapter, not a user-facing failure.

_migrator_required_vars=(
    MIGRATOR_FROM_VERSION
    MIGRATOR_TO_VERSION
    MIGRATOR_BASELINE_TAG
    MIGRATOR_OWN_SIDECAR_SUFFIX
)

# MIGRATOR_PRIOR_SIDECAR_SUFFIXES is a bash array — checked separately
# because `[[ -z "${VAR[@]}" ]]` is awkward for empty arrays. The check
# is "declared" (even if empty), not "non-empty" (some transitions may
# have no prior sidecars).

_migrator_required_hooks=(
    migrator_manifest
    migrator_directory_sweeps
    migrator_relocations
    migrator_artifact_installs
    migrator_post_report_hook
)

_migrator_check_adapter_contract() {
    local var hook
    for var in "${_migrator_required_vars[@]}"; do
        # Indirect expansion bash 3.2 compatible — no nameref.
        if [[ -z "${!var:-}" ]]; then
            die "adapter contract violation: $var must be set before sourcing migrator-core.sh / calling migrator_run" \
                "$EXIT_INTERNAL"
        fi
    done
    # MIGRATOR_PRIOR_SIDECAR_SUFFIXES must be declared (declare -p succeeds)
    # but may be empty.
    if ! declare -p MIGRATOR_PRIOR_SIDECAR_SUFFIXES >/dev/null 2>&1; then
        die "adapter contract violation: MIGRATOR_PRIOR_SIDECAR_SUFFIXES array must be declared (use empty array if no priors)" \
            "$EXIT_INTERNAL"
    fi
    for hook in "${_migrator_required_hooks[@]}"; do
        if ! declare -F "$hook" >/dev/null 2>&1; then
            die "adapter contract violation: required hook function $hook is not defined" \
                "$EXIT_INTERNAL"
        fi
    done
}

# ── Stage sequencer + EXIT trap ────────────────────────────────────────────
#
# Architecture §6 I9: report rendering is mandatory — even on partial
# failure the core attempts a final report render so the user has a
# truthful artifact. The trap fires on any path out of `migrator_run`
# (including `die`, `fail_stage`, and `set -e` propagation).

_migrator_exit_trap() {
    local rc=$?
    # Only attempt a report render once. If `_stage_report` already ran
    # (rc=0 path), do nothing. If we are bailing before the report stage
    # and the state dir exists, attempt a best-effort render so the user
    # sees what classifications happened up to the failure point.
    if [[ "$_MIGRATOR_REPORT_DONE" == "0" \
       && -n "$_MIGRATOR_STATE_DIR" \
       && -d "$_MIGRATOR_STATE_DIR" ]]; then
        # Only attempt if customization_report is actually defined (the
        # libs were loaded by `_stage_libs`). Pre-libs failures (e.g.
        # `_stage_preflight` or `_stage_backup`) have no report to render.
        if declare -F customization_report >/dev/null 2>&1 \
           && [[ -f "$_MIGRATOR_STATE_DIR/dispositions.tsv" ]]; then
            if [[ "${_MIGRATOR_PAUSED:-0}" == "1" ]]; then
                # Deliberate pause: an adapter called `migrator_pause`
                # (exit 0) to let the user reconcile customizations.
                # Render a PAUSED (not FAILED) report and emit a calm
                # pointer — NOT `warn` (which prepends "warning:").
                customization_report \
                    "$_MIGRATOR_STATE_DIR/dispositions.tsv" \
                    "$_MIGRATOR_STATE_DIR/report.md" \
                    "${MIGRATOR_FROM_VERSION:-vN} → ${MIGRATOR_TO_VERSION:-vM} migration — PAUSED for customization reconciliation" \
                    2>/dev/null || true
                printf 'note: migration paused — requires attention; partial report written to %s\n' \
                    "$_MIGRATOR_STATE_DIR/report.md" >&2
            else
                # Genuine failure before the report stage: render a partial
                # report and warn loudly (unchanged pre-BD-282 behavior).
                customization_report \
                    "$_MIGRATOR_STATE_DIR/dispositions.tsv" \
                    "$_MIGRATOR_STATE_DIR/report.md" \
                    "${MIGRATOR_FROM_VERSION:-vN} → ${MIGRATOR_TO_VERSION:-vM} migration customization report (partial — run failed at exit code $rc)" \
                    2>/dev/null || true
                warn "migration failed (exit $rc); partial report rendered to $_MIGRATOR_STATE_DIR/report.md"
            fi
        fi
    fi
    return "$rc"
}

# Stage order is fixed (architecture §6, PLAN §3.4). The seven stages are
# the I1..I9 invariants in execution order. Adapters cannot reorder.
_migrator_run_stages() {
    _stage_preflight
    _stage_backup
    _stage_libs
    # Optional pre-dispatch hook (architecture §3.2; default no-op).
    if declare -F migrator_pre_dispatch_hook >/dev/null 2>&1; then
        migrator_pre_dispatch_hook
    fi
    _stage_dispatch
    # Optional post-dispatch hook.
    if declare -F migrator_post_dispatch_hook >/dev/null 2>&1; then
        migrator_post_dispatch_hook
    fi
    _stage_relocations
    _stage_artifact_installs
    _stage_report
    _MIGRATOR_REPORT_DONE="1"
    # Adapter-supplied post-report guidance (e.g. "pack tracker init"
    # pointer at v10→v11). Required hook per PLAN §3.4.
    migrator_post_report_hook
}

# ── Argument parsing + usage ───────────────────────────────────────────────

_migrator_usage() {
    local from="${MIGRATOR_FROM_VERSION:-vN}"
    local to="${MIGRATOR_TO_VERSION:-vM}"
    say "Usage: PACK=/path/to/pack migrate-${from}-to-${to}.sh [target-dir] [flags]"
    say ""
    say "Flags:"
    say "  --help, -h    Show this message and exit"
    say "  --dry-run     Run preflight + manifest validation; log writes but do not perform them"
    say "  --apply       Default. Refuses to run unless a fresh dry-run fingerprint exists;"
    say "                pauses cleanly before S4 if conflicts are produced."
    say "  --resume      Continue a paused migration after sidecar reconciliation."
    say "                Forward-only; per-adapter (the v10→v11 adapter implements it;"
    say "                future adapters may opt out)."
    say ""
    # bash 3.2 has no `${var^^}` upper-casing — use `tr` for portability.
    local from_upper
    from_upper=$(printf '%s' "$from" | tr '[:lower:]' '[:upper:]')
    say "Environment:"
    say "  PACK                          Absolute path to the pack repo (required)"
    say "  ${from_upper}_TAG / MIGRATOR_BASELINE_TAG"
    say "                                Override baseline tag (default: ${MIGRATOR_BASELINE_TAG:-$from})"
}

_migrator_parse_args() {
    local positional=()
    while (( $# > 0 )); do
        case "$1" in
            --help|-h)
                _migrator_usage
                exit 0
                ;;
            --dry-run)
                _MIGRATOR_DRY_RUN="1"
                _MIGRATOR_MODE="dry-run"
                ;;
            --apply)
                _MIGRATOR_MODE="apply"
                ;;
            --resume)
                # `--resume` is per-adapter. The v10→v11 adapter handles it
                # in `scripts/lib/migrate-v10-to-v11/resume.sh` and intercepts
                # the flag BEFORE forwarding to `migrator_run`, so this
                # framework-level branch is unreachable in normal use.
                # Adapters that need resume must wire similar pre-`migrator_run`
                # mode dispatch in their own entry script (see migrate-v10-to-v11.sh
                # _mode parsing as the reference implementation). The framework
                # does not provide a generic state-machine resume — the
                # sentinels and recovery semantics are version-specific.
                die "--resume is per-adapter; this framework call path was not intercepted by the adapter (see scripts/lib/migrate-v10-to-v11/resume.sh for the v10→v11 reference implementation)" \
                    "$EXIT_INTERNAL"
                ;;
            --)
                shift
                while (( $# > 0 )); do
                    positional+=("$1")
                    shift
                done
                break
                ;;
            --*)
                die "unknown option: $1 (try --help)" "$EXIT_INTERNAL"
                ;;
            *)
                positional+=("$1")
                ;;
        esac
        shift || true
    done

    local target="${positional[0]:-.}"
    # Resolve to absolute path; preserve original on `cd` failure so the
    # downstream preflight error message still names what the user typed.
    _MIGRATOR_TARGET="$(cd "$target" 2>/dev/null && pwd || printf '%s' "$target")"

    # Derive state + backup directory names from the version pair (architecture
    # §3.3). Adapter declares versions; core derives names so a sidecar/
    # state-dir naming defect fixed once is fixed for every adapter.
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"

    # Export for the stage functions in migrator-stages.sh and for
    # backwards-compatibility with any monolith-era helpers that read
    # `$TARGET` directly.
    TARGET="$_MIGRATOR_TARGET"
    STATE_DIR="$_MIGRATOR_STATE_DIR"
    BACKUP_DIR="$_MIGRATOR_BACKUP_DIR"
}

# ── Public API (PLAN §3.1; FROZEN) ─────────────────────────────────────────
#
# Seven functions form the public surface. Six are callable from adapters and
# from external harnesses; the seventh, migrator_pause, is an adapter-only
# pause signal (it exits, so external harnesses do not call it). Names +
# arities are frozen for the duration of v11.x; renames require a new BD that
# explicitly amends BD-119.

# migrator_run "$@"
#   Full end-to-end migration with the calling adapter's declared contract.
#   Drives the stage sequencer; returns 0 on success or a documented exit
#   code on failure.
migrator_run() {
    set -euo pipefail
    _migrator_reset_state
    trap _migrator_exit_trap EXIT
    _migrator_check_adapter_contract
    _migrator_parse_args "$@"
    _migrator_run_stages
}

# migrator_dispatch <target-dir>
#   Programmatic entry point — same effect as `migrator_run "$target-dir"`
#   but skips usage printing (no `--help` recognition) and accepts only the
#   positional target. Used by external harnesses (BD-114) where flags are
#   irrelevant.
migrator_dispatch() {
    if (( $# != 1 )); then
        die "migrator_dispatch: expected exactly one argument (target-dir), got $#" \
            "$EXIT_INTERNAL"
    fi
    migrator_run "$1"
}

# migrator_pause
#   Adapters call this INSTEAD of `exit 0` when they deliberately pause
#   (e.g. to let the user reconcile customizations) and expect `--resume`
#   to complete the run. Sets the flag the EXIT trap reads to render a
#   PAUSED (not FAILED) report. Genuine errors MUST NOT call this — use
#   die / fail_stage (non-zero) so the trap's FAILURE branch fires.
migrator_pause() { _MIGRATOR_PAUSED=1; exit 0; }

# migrator_detect_target_version <target-dir>
#   Echo the major pack version installed in the target (e.g. `v10`,
#   `v11`, `unknown`). Delegates to `detect_target_pack_version` from
#   `lib/detect.sh`; sources detect.sh on demand if not already loaded.
migrator_detect_target_version() {
    local target="${1:-.}"
    if ! declare -F detect_target_pack_version >/dev/null 2>&1; then
        local detect_lib="$_migrator_core_dir/detect.sh"
        if [[ -f "$detect_lib" ]]; then
            # shellcheck source=detect.sh disable=SC1091
            . "$detect_lib"
        else
            die "migrator_detect_target_version: detect.sh not found at $detect_lib" \
                "$EXIT_LIB_MISSING"
        fi
    fi
    detect_target_pack_version "$target"
}

# migrator_select_adapter <from-version>
#   Echo the absolute path to `migrate-v<from>-to-v<from+1>.sh`. Errors if
#   no adapter is found, or if multiple adapters claim the same from-version
#   (PLAN OQ3 → glob with collision-detection).
#
# Discovery: glob `$PACK/scripts/migrate-v*-to-v*.sh`, parse `vN` from each
# filename via the regex `migrate-v([0-9]+)-to-v([0-9]+)\.sh`, return the
# match for `<from-version>`.
migrator_select_adapter() {
    local from="${1:-}"
    if [[ -z "$from" ]]; then
        die "migrator_select_adapter: <from-version> argument required (e.g. v10)" \
            "$EXIT_INTERNAL"
    fi
    if [[ -z "${PACK:-}" || ! -d "${PACK:-/dev/null}" ]]; then
        die "migrator_select_adapter: PACK environment variable not set or invalid" \
            "$EXIT_PACK_INVALID"
    fi

    # Strip leading `v` if present so callers may pass either `v10` or `10`.
    local from_num="${from#v}"
    if ! [[ "$from_num" =~ ^[0-9]+$ ]]; then
        die "migrator_select_adapter: invalid from-version: $from (expected vN or N)" \
            "$EXIT_INTERNAL"
    fi

    local matches=()
    local f base from_match to_match
    # Glob may not match — `nullglob` is bash 4 only, so guard with a
    # file-exists check inside the loop (bash 3.2 compatible).
    for f in "$PACK/scripts"/migrate-v*-to-v*.sh; do
        [[ -e "$f" ]] || continue
        base=$(basename "$f")
        if [[ "$base" =~ ^migrate-v([0-9]+)-to-v([0-9]+)\.sh$ ]]; then
            from_match="${BASH_REMATCH[1]}"
            to_match="${BASH_REMATCH[2]}"
            if [[ "$from_match" == "$from_num" ]]; then
                matches+=("$f")
            fi
            # Touch to_match so set -u does not complain in callers that
            # later read it; primary use is from_match equality above.
            : "$to_match"
        fi
    done

    if (( ${#matches[@]} == 0 )); then
        die "migrator_select_adapter: no adapter found for from-version v$from_num (looked under $PACK/scripts/)" \
            "$EXIT_INTERNAL"
    fi
    if (( ${#matches[@]} > 1 )); then
        die "migrator_select_adapter: multiple adapters claim from-version v$from_num: ${matches[*]}" \
            "$EXIT_INTERNAL"
    fi
    printf '%s\n' "${matches[0]}"
}

# migrator_baseline_to_tmp <pack-relpath> <tmpfile>
#   Side-effect helper: write the BASE blob (pack repo file at
#   `MIGRATOR_BASELINE_TAG`) into `<tmpfile>` for three-way dispatch.
#   Returns 0 on success (file existed at baseline) and writes the blob
#   to `<tmpfile>`. Returns non-zero (and leaves `<tmpfile>` empty) when
#   the file did not exist at the baseline tag — that is a normal case
#   for files newly added in the destination version. Replaces the
#   monolith's `v10_baseline_to_tmp`.
migrator_baseline_to_tmp() {
    local pack_relpath="${1:-}"
    local tmpfile="${2:-}"
    if [[ -z "$pack_relpath" || -z "$tmpfile" ]]; then
        die "migrator_baseline_to_tmp: usage: <pack-relpath> <tmpfile>" \
            "$EXIT_INTERNAL"
    fi
    if [[ -z "${PACK:-}" ]]; then
        die "migrator_baseline_to_tmp: PACK not set" "$EXIT_PACK_INVALID"
    fi
    if [[ -z "${MIGRATOR_BASELINE_TAG:-}" ]]; then
        die "migrator_baseline_to_tmp: MIGRATOR_BASELINE_TAG not set" \
            "$EXIT_INTERNAL"
    fi
    if git -C "$PACK" show "$MIGRATOR_BASELINE_TAG:$pack_relpath" \
        > "$tmpfile" 2>/dev/null; then
        return 0
    else
        : > "$tmpfile"
        return 1
    fi
}

# migrator_baseline_for_row <pack-relpath> <proj-relpath> <tmpfile>
#   DESTINATION-aware BASE resolution for one install row. It changes ONE
#   reading of `migrator_baseline_to_tmp`: a client file ABSENT at a
#   destination the FROM version never created is not a deletion. The
#   engine reads "base present, ours absent, theirs present" as
#   `project-deleted-pack-kept` and copies nothing — correct only when the
#   FROM version could have put a file there. For a destination it never
#   created (the TO version renamed it), the client never had the file, so
#   such a row gets NO base and the pack source installs as a clean add.
#
#   The rule applies only when the client has NO file at the destination.
#   A file the client DOES have there is three-wayed against the baseline
#   SOURCE blob exactly as before, whatever put it there: a client who
#   created the file from the pack's example has that example as the
#   plausible common ancestor, and dropping it would turn their edits
#   (a removed key, say) into a two-way union that re-adds what they
#   removed.
#
#   An adapter whose FROM version delivered a source elsewhere declares
#   the optional hook
#       migrator_from_version_delivered <pack-relpath> <proj-relpath>
#   — rc 0 when the FROM version installed the source at that destination,
#   rc 1 otherwise. With the hook undefined every row counts as delivered
#   at its destination and this reduces to `migrator_baseline_to_tmp`.
#   Same return contract as `migrator_baseline_to_tmp`: 0 with the blob
#   written, or 1 with <tmpfile> left empty. Reads `_MIGRATOR_TARGET` for
#   the client-file presence test (unset ⇒ treated as absent). Consumers:
#   the manifest engine (`_manifest_dispatch_transform`,
#   `_manifest_sweep_directories`) and the v10→v11 adapter's
#   `_v10_to_v11_map_derived_install`.
migrator_baseline_for_row() {
    local pack_relpath="${1:-}"
    local proj_relpath="${2:-}"
    local tmpfile="${3:-}"
    if [[ -z "$pack_relpath" || -z "$proj_relpath" || -z "$tmpfile" ]]; then
        die "migrator_baseline_for_row: usage: <pack-relpath> <proj-relpath> <tmpfile>" \
            "$EXIT_INTERNAL"
    fi
    # `_MIGRATOR_TARGET` unset ⇒ no client tree to consult ⇒ the client file
    # counts as ABSENT (never test "/<proj-relpath>" against the root fs).
    if { [[ -z "${_MIGRATOR_TARGET:-}" ]] || [[ ! -e "${_MIGRATOR_TARGET}/$proj_relpath" ]]; } \
       && declare -F migrator_from_version_delivered >/dev/null 2>&1 \
       && ! migrator_from_version_delivered "$pack_relpath" "$proj_relpath"; then
        : > "$tmpfile"
        return 1
    fi
    migrator_baseline_to_tmp "$pack_relpath" "$tmpfile"
}

# migrator_target_surface_for_version <vN>
#   Echo a newline-delimited list of project-relative paths that a vN
#   install creates and that real-client customization can target. Used
#   by BD-160 fixture parameterization (v11-realistic-ot dispatcher in
#   test-fixtures/build.sh — see `_build_realistic_for_version`'s C2/C3
#   re-verification against the v11 surface; architecture §9.2). The
#   prior "BD-120 fixture parameterization" wording was retracted in
#   the BD-120 retro F1 fix because BD-120 dropped the helper-consumer
#   claim (helper was not actually sourced or called from build.sh at
#   that time); BD-160 is the helper's first real fixture-builder
#   consumer.
#
#   The returned list is *paths to files or directories*, not a transformation
#   map. The fixture builder applies its patterns; this helper only declares
#   "where the targets live in this version." This avoids duplicating
#   surface knowledge across init-project.sh, migrate-vN-to-vM.sh, and
#   test-fixtures/build.sh.
#
#   Currently knows about v10 and v11. `unknown` for any other version.
migrator_target_surface_for_version() {
    local ver="${1:-}"
    case "$ver" in
        v10)
            cat <<'EOF'
CLAUDE.md
AGENTS.md
GEMINI.md
.claude/agents
.codex/agents
.gemini/agents
.codex/config.toml
BACKLOG.md
EOF
            ;;
        v11)
            # v11 inherits the v10 customization surface (trinity,
            # .codex/config.toml, BACKLOG.md) and adds the v11-specific
            # Antigravity surfaces. Agents are a plugin bundle
            # (.agents-plugin/optiquity-agents/agents), skills are loose
            # under .agents/skills/, and pm-help is a pool skill
            # distributed loose to all three CLIs (renamed from pack-help
            # per BD-257; the pack-side pack-help.sh + lib/detect.sh no
            # longer ship — no dual-use). The legacy `.gemini/` agent dir +
            # `.gemini/commands/pack-help.toml` command are gone (BD-221).
            # Only customization-relevant surfaces are
            # listed. tracker.toml.example is NOT listed: a v11 install no
            # longer creates it (tracker integration is deferred;
            # flat-file is the sole supported mode). The groupings stream
            # templates (BD-262 fourth per-entry stream; installed on
            # every v11.0+ path per BD-263) are customization-relevant:
            # a client may hand-edit the shipped sidecars.
            cat <<'EOF'
CLAUDE.md
AGENTS.md
GEMINI.md
.claude/agents
.codex/agents
.agents-plugin/optiquity-agents/agents
.codex/config.toml
BACKLOG.md
docs/pack/HELP-FRAGMENT.md
.github/ISSUE_TEMPLATE/work-item.yml
.claude/skills/pm-help/SKILL.md
.codex/skills/pm-help/SKILL.md
.agents/skills/pm-help/SKILL.md
docs/project/groupings/_rules.md
docs/project/groupings/_intro.md
EOF
            ;;
        *)
            printf 'unknown\n'
            return 1
            ;;
    esac
}
