#!/usr/bin/env bash
# scripts/dry-run-migration.sh — BD-114 parameterized read-only migration
# dry-run harness.
#
# Public-friendly entry point that previews a one-major migration against
# any v10 (or future-vN) client repo without ever modifying the original.
# The original target is opened only via clone (URL) or read-only copy
# (local path); all migration work happens in /tmp on a disposable copy
# that is removed on every exit path (success, failure, Ctrl-C).
#
# Three usage modes — all the same script:
#
#   1. Synthetic fixture (CI / smoke):
#        scripts/dry-run-migration.sh test-fixtures/v10-realistic-ot
#
#   2. Public user, their own v10 client (URL or local path):
#        scripts/dry-run-migration.sh /path/to/their/v10/clone
#        scripts/dry-run-migration.sh https://github.com/their-org/their-v10-repo
#        scripts/dry-run-migration.sh git@github.com:their-org/their-v10-repo.git
#
#   3. Optiquity release gate (URL via internal CI secret):
#        scripts/dry-run-migration.sh "$OT_URL"
#      The URL is supplied at invocation; nothing is hardcoded in the pack.
#
# Input contract (also documented in BD-125):
#   - Target must be a clean v10 install (no uncommitted changes).
#   - No in-flight prior migration state-dir on the target.
#   - Accessible via `git clone` (URL) or readable as a local directory.
#
# Read-only enforcement (mechanical, not honor-system):
#   - Target is cloned (URL) or copied (local) into a fresh mktemp dir
#     under /tmp (or $TMPDIR when set).
#   - Refuses to operate on any working dir that does not resolve under
#     /tmp / $TMPDIR.
#   - On the working clone, `git remote set-url --push origin /dev/null`
#     makes any accidental `git push` a hard error.
#   - An EXIT trap removes the working dir on every path out (success,
#     failure, signal). The original URL/path is never touched.
#
# Output:
#   - stdout / stderr / exit code from the migrator captured into
#     `<work-dir>/results/{stdout.log,stderr.log,exit-code}`.
#   - Pre/post diff captured into `<work-dir>/results/diff.patch`
#     (file-list + content delta of the working clone vs. its initial
#     commit).
#   - Summary report written to `<work-dir>/results/dry-run-report.md`
#     (or to `--report-out <path>` to persist past cleanup).
#
# Exit codes (BD-114-local; do NOT collide with the BD-119 framework's
# 10..16, 20..30, 99 ranges by reusing 2 + 4..7 for our own conditions):
#   0  — dry-run completed successfully (migration would succeed)
#   2  — usage error (bad/missing args, --help is its own path → 0)
#   4  — target acquisition failed (clone or copy)
#   5  — read-only enforcement refused (work dir outside /tmp/$TMPDIR)
#   6  — version detection / adapter selection failed
#   7  — adapter (the actual migrator) returned non-zero
#
# Hard rules:
#   - No git state changes on the original target — ever.
#   - No URL or path defaulted/hardcoded; first arg required.
#   - macOS bash 3.2 + BSD utils compatible (mktemp -d -t, cp -R, trap).
#
# Architecture: maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md §5.2
# Backlog:      BACKLOG.md BD-114

set -uo pipefail

# ── Local exit codes ───────────────────────────────────────────────────────

readonly DRY_EXIT_OK=0
readonly DRY_EXIT_USAGE=2
readonly DRY_EXIT_ACQUIRE=4
readonly DRY_EXIT_READONLY_REFUSED=5
readonly DRY_EXIT_DETECT_OR_DISPATCH=6
readonly DRY_EXIT_ADAPTER=7

# ── Globals (set by parse_args / main) ─────────────────────────────────────

DRY_TARGET_INPUT=""        # raw first arg as the user supplied it
DRY_REPORT_OUT=""          # --report-out <path> (optional persistent copy)
DRY_TMP_BASE=""            # --tmp-dir <path> (override; must be under /tmp/$TMPDIR)
DRY_WORK_DIR=""            # the actual mktemp -d we created (cleaned on EXIT)
DRY_PACK=""                # absolute path to the pack repo
DRY_CLONE_DIR=""           # $DRY_WORK_DIR/clone — where the migration is staged
DRY_RESULTS_DIR=""         # $DRY_WORK_DIR/results

# ── Logging helpers ────────────────────────────────────────────────────────

dry_say()  { printf '%s\n' "$*"; }
dry_info() { printf '  %s\n' "$*"; }
dry_warn() { printf 'warning: %s\n' "$*" >&2; }
dry_err()  { printf 'error: %s\n' "$*" >&2; }

# ── Cleanup trap ───────────────────────────────────────────────────────────
# Removes $DRY_WORK_DIR unconditionally. Runs on success, error, and any
# signal that exits via the shell (INT, TERM, HUP). bash 3.2 portable.

dry_cleanup() {
    local rc=$?
    if [[ -n "$DRY_WORK_DIR" && -d "$DRY_WORK_DIR" ]]; then
        # Defensive: refuse to rm anything that doesn't look like a tmp path.
        case "$DRY_WORK_DIR" in
            /tmp/*|/private/tmp/*|/var/folders/*)
                rm -rf "$DRY_WORK_DIR"
                ;;
            *)
                # If $TMPDIR was used, the path may not match the static
                # prefixes above — still remove iff it lives under $TMPDIR.
                if [[ -n "${TMPDIR:-}" && "$DRY_WORK_DIR" == "${TMPDIR%/}/"* ]]; then
                    rm -rf "$DRY_WORK_DIR"
                else
                    dry_warn "refusing to clean unexpected work dir: $DRY_WORK_DIR"
                fi
                ;;
        esac
    fi
    return "$rc"
}

# ── Usage ──────────────────────────────────────────────────────────────────

dry_usage() {
    cat <<'EOF'
Usage: scripts/dry-run-migration.sh <git-url-or-local-path> [flags]

Read-only migration dry-run harness. Clones (URL) or copies (local path)
the target into /tmp, runs the appropriate migrator against the copy, and
captures the result into a report. The original target is never modified.

Arguments:
  <git-url-or-local-path>   REQUIRED. Either:
                              - https://... or git@... git URL
                              - absolute or relative local filesystem path

Flags:
  --report-out <path>       Persist the dry-run-report.md to <path> after
                            cleanup (default: report is removed with the
                            working dir).
  --tmp-dir <path>          Override the work-dir parent. Must resolve
                            under /tmp or $TMPDIR (refused otherwise).
  --pack <path>             Override the pack repo path (default: parent
                            of the script's directory).
  --help, -h                Show this message and exit.

Examples:

  # Mode 1 — synthetic fixture (CI / smoke):
  scripts/dry-run-migration.sh test-fixtures/v10-realistic-ot

  # Mode 2 — public user, their own v10 client:
  scripts/dry-run-migration.sh /path/to/their/v10/clone
  scripts/dry-run-migration.sh https://github.com/their-org/their-v10-repo

  # Mode 3 — Optiquity release gate (URL via internal CI secret):
  scripts/dry-run-migration.sh "$OT_URL"

Exit codes:
  0  dry-run completed successfully (migration would succeed)
  2  usage error
  4  target acquisition failed (clone or copy)
  5  read-only enforcement refused (work dir not under /tmp/$TMPDIR)
  6  version detection / adapter selection failed
  7  adapter (migrator) returned non-zero — preview shows a real failure
EOF
}

# ── Arg parsing ────────────────────────────────────────────────────────────

dry_parse_args() {
    local positional=()
    while (( $# > 0 )); do
        case "$1" in
            --help|-h)
                dry_usage
                exit "$DRY_EXIT_OK"
                ;;
            --report-out)
                shift || { dry_err "--report-out requires a path"; exit "$DRY_EXIT_USAGE"; }
                DRY_REPORT_OUT="$1"
                ;;
            --tmp-dir)
                shift || { dry_err "--tmp-dir requires a path"; exit "$DRY_EXIT_USAGE"; }
                DRY_TMP_BASE="$1"
                ;;
            --pack)
                shift || { dry_err "--pack requires a path"; exit "$DRY_EXIT_USAGE"; }
                DRY_PACK="$1"
                ;;
            --)
                shift
                while (( $# > 0 )); do
                    positional+=("$1"); shift
                done
                break
                ;;
            --*)
                dry_err "unknown flag: $1 (try --help)"
                exit "$DRY_EXIT_USAGE"
                ;;
            *)
                positional+=("$1")
                ;;
        esac
        shift || true
    done

    if (( ${#positional[@]} != 1 )); then
        dry_err "exactly one positional argument required (git URL or local path)"
        dry_say ""
        dry_usage >&2
        exit "$DRY_EXIT_USAGE"
    fi
    DRY_TARGET_INPUT="${positional[0]}"
}

# ── Pre-flight ─────────────────────────────────────────────────────────────

dry_preflight() {
    # Resolve the script's pack location (default: parent of script dir).
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -z "$DRY_PACK" ]]; then
        DRY_PACK="$(cd "$script_dir/.." && pwd)"
    else
        # Resolve to absolute. A relative --pack arg is a footgun.
        DRY_PACK="$(cd "$DRY_PACK" 2>/dev/null && pwd || printf '%s' "$DRY_PACK")"
    fi
    if [[ ! -d "$DRY_PACK/scripts/lib" || ! -f "$DRY_PACK/scripts/lib/migrator-core.sh" ]]; then
        dry_err "pack repo not valid at: $DRY_PACK (missing scripts/lib/migrator-core.sh)"
        exit "$DRY_EXIT_USAGE"
    fi

    # Determine the work-dir parent. Default order: $TMPDIR, then /tmp.
    local tmp_parent
    if [[ -n "$DRY_TMP_BASE" ]]; then
        tmp_parent="$DRY_TMP_BASE"
    elif [[ -n "${TMPDIR:-}" ]]; then
        tmp_parent="${TMPDIR%/}"
    else
        tmp_parent="/tmp"
    fi
    if [[ ! -d "$tmp_parent" || ! -w "$tmp_parent" ]]; then
        dry_err "tmp parent not a writable directory: $tmp_parent"
        exit "$DRY_EXIT_READONLY_REFUSED"
    fi

    # Resolve to absolute (canonical) so the under-/tmp check below is
    # comparing canonical paths, not user-typed relatives.
    local tmp_parent_abs
    tmp_parent_abs="$(cd "$tmp_parent" 2>/dev/null && pwd)" \
        || { dry_err "cannot resolve tmp parent: $tmp_parent"; exit "$DRY_EXIT_READONLY_REFUSED"; }

    # Read-only enforcement: refuse anything that does not resolve under
    # /tmp, /private/tmp (macOS canonical of /tmp), /var/folders (macOS
    # default $TMPDIR), or whatever $TMPDIR currently points at.
    local ok=0
    case "$tmp_parent_abs" in
        /tmp|/tmp/*|/private/tmp|/private/tmp/*|/var/folders|/var/folders/*) ok=1 ;;
    esac
    if (( ok == 0 )) && [[ -n "${TMPDIR:-}" ]]; then
        local tmpdir_abs
        tmpdir_abs="$(cd "${TMPDIR}" 2>/dev/null && pwd)"
        if [[ -n "$tmpdir_abs" \
            && ( "$tmp_parent_abs" == "$tmpdir_abs" \
              || "$tmp_parent_abs" == "$tmpdir_abs"/* ) ]]; then
            ok=1
        fi
    fi
    if (( ok == 0 )); then
        dry_err "refusing to use tmp parent outside /tmp or \$TMPDIR: $tmp_parent_abs"
        exit "$DRY_EXIT_READONLY_REFUSED"
    fi

    # mktemp -d in BSD form (macOS bash 3.2 compatible — no `-p` GNU flag).
    DRY_WORK_DIR="$(mktemp -d "$tmp_parent_abs/dry-run-migration.XXXXXX")" \
        || { dry_err "mktemp -d failed under: $tmp_parent_abs"; exit "$DRY_EXIT_READONLY_REFUSED"; }

    DRY_CLONE_DIR="$DRY_WORK_DIR/clone"
    DRY_RESULTS_DIR="$DRY_WORK_DIR/results"
    mkdir -p "$DRY_RESULTS_DIR"
}

# ── Acquire target into $DRY_CLONE_DIR ─────────────────────────────────────

dry_acquire_target() {
    local input="$DRY_TARGET_INPUT"

    # Heuristic: a URL has a scheme or "git@host:" syntax. Everything else
    # is treated as a local path.
    if [[ "$input" == http://* \
       || "$input" == https://* \
       || "$input" == git://* \
       || "$input" == ssh://* \
       || "$input" =~ ^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+: ]]; then
        dry_info "cloning URL into work dir: $input"
        if ! git clone --quiet "$input" "$DRY_CLONE_DIR" 2>"$DRY_RESULTS_DIR/clone.err"; then
            dry_err "git clone failed; see $DRY_RESULTS_DIR/clone.err"
            return "$DRY_EXIT_ACQUIRE"
        fi
    else
        # Local path: must exist and be a directory.
        if [[ ! -d "$input" ]]; then
            dry_err "local path is not a directory: $input"
            return "$DRY_EXIT_ACQUIRE"
        fi
        # Resolve to absolute so subsequent checks aren't $PWD-dependent.
        local input_abs
        input_abs="$(cd "$input" 2>/dev/null && pwd)" \
            || { dry_err "cannot resolve local path: $input"; return "$DRY_EXIT_ACQUIRE"; }

        # If the local path is itself a git repo, prefer `git clone` so the
        # working clone has a clean commit base for diff'ing post-migration.
        if git -C "$input_abs" rev-parse --git-dir >/dev/null 2>&1; then
            dry_info "cloning local git repo into work dir: $input_abs"
            if ! git clone --quiet "$input_abs" "$DRY_CLONE_DIR" 2>"$DRY_RESULTS_DIR/clone.err"; then
                dry_err "git clone (local) failed; see $DRY_RESULTS_DIR/clone.err"
                return "$DRY_EXIT_ACQUIRE"
            fi
        else
            # Not a git repo — copy then init. cp -R is BSD-portable.
            dry_info "copying local directory into work dir (not a git repo): $input_abs"
            mkdir -p "$DRY_CLONE_DIR"
            if ! cp -R "$input_abs"/. "$DRY_CLONE_DIR"/ 2>"$DRY_RESULTS_DIR/clone.err"; then
                dry_err "cp -R failed; see $DRY_RESULTS_DIR/clone.err"
                return "$DRY_EXIT_ACQUIRE"
            fi
            git -C "$DRY_CLONE_DIR" init -q || {
                dry_err "git init in work dir failed"
                return "$DRY_EXIT_ACQUIRE"
            }
            # Establish a baseline commit so the post-migration diff is meaningful.
            git -C "$DRY_CLONE_DIR" config user.name  "dry-run-harness" >/dev/null 2>&1 || true
            git -C "$DRY_CLONE_DIR" config user.email "dry-run-harness@local" >/dev/null 2>&1 || true
            git -C "$DRY_CLONE_DIR" add -A >/dev/null 2>&1 || true
            git -C "$DRY_CLONE_DIR" commit -q --allow-empty \
                -m "dry-run baseline" >/dev/null 2>&1 || true
        fi
    fi

    # Disable push from the working clone — `git push` becomes a hard
    # failure (no such device). Cosmetic safety on top of the clone-isolation;
    # the original is also never named as a remote here.
    git -C "$DRY_CLONE_DIR" remote set-url --push origin /dev/null 2>/dev/null || true

    # Capture initial HEAD SHA for diff.
    git -C "$DRY_CLONE_DIR" rev-parse HEAD > "$DRY_RESULTS_DIR/baseline-sha" 2>/dev/null \
        || : > "$DRY_RESULTS_DIR/baseline-sha"

    return 0
}

# ── Run the migrator against the clone ─────────────────────────────────────

dry_run_migrator() {
    # Invoke the framework's public API in subshells so that any internal
    # `die` (which calls `exit`) cannot kill the harness. Each subshell
    # sources migrator-core.sh fresh with PACK exported.
    local detected adapter
    detected="$(
        export PACK="$DRY_PACK"
        # shellcheck disable=SC1091
        . "$DRY_PACK/scripts/lib/migrator-core.sh"
        migrator_detect_target_version "$DRY_CLONE_DIR"
    )" 2>"$DRY_RESULTS_DIR/detect.err" || {
        dry_err "migrator_detect_target_version failed; see $DRY_RESULTS_DIR/detect.err"
        return "$DRY_EXIT_DETECT_OR_DISPATCH"
    }
    printf '%s\n' "$detected" > "$DRY_RESULTS_DIR/detected-version"
    dry_info "detected target pack version: $detected"

    if [[ -z "$detected" || "$detected" == "unknown" ]]; then
        dry_err "could not detect a known pack version on the target"
        return "$DRY_EXIT_DETECT_OR_DISPATCH"
    fi

    adapter="$(
        export PACK="$DRY_PACK"
        # shellcheck disable=SC1091
        . "$DRY_PACK/scripts/lib/migrator-core.sh"
        migrator_select_adapter "$detected"
    )" 2>"$DRY_RESULTS_DIR/adapter.err" || {
        dry_err "migrator_select_adapter failed; see $DRY_RESULTS_DIR/adapter.err"
        return "$DRY_EXIT_DETECT_OR_DISPATCH"
    }
    if [[ -z "$adapter" || ! -f "$adapter" ]]; then
        dry_err "migrator_select_adapter returned empty / non-existent path: $adapter"
        return "$DRY_EXIT_DETECT_OR_DISPATCH"
    fi
    printf '%s\n' "$adapter" > "$DRY_RESULTS_DIR/selected-adapter"
    dry_info "selected adapter: $adapter"

    # Invoke the adapter as a child process so its `set -euo pipefail`
    # cannot poison our shell. Pass --dry-run so the framework's I6
    # invariant ("never modifies target") engages.
    dry_info "running adapter --dry-run against the clone"
    local adapter_rc=0
    PACK="$DRY_PACK" bash "$adapter" --dry-run "$DRY_CLONE_DIR" \
        > "$DRY_RESULTS_DIR/stdout.log" \
        2> "$DRY_RESULTS_DIR/stderr.log" \
        || adapter_rc=$?
    printf '%s\n' "$adapter_rc" > "$DRY_RESULTS_DIR/exit-code"

    # Capture the post-migration diff against the baseline commit.
    git -C "$DRY_CLONE_DIR" add -A >/dev/null 2>&1 || true
    git -C "$DRY_CLONE_DIR" diff --cached --stat \
        > "$DRY_RESULTS_DIR/diff.stat" 2>/dev/null || true
    git -C "$DRY_CLONE_DIR" diff --cached \
        > "$DRY_RESULTS_DIR/diff.patch" 2>/dev/null || true

    if (( adapter_rc != 0 )); then
        dry_err "adapter exited non-zero: $adapter_rc (see $DRY_RESULTS_DIR/{stdout.log,stderr.log})"
        return "$DRY_EXIT_ADAPTER"
    fi
    return 0
}

# ── Render dry-run-report.md ───────────────────────────────────────────────

dry_render_report() {
    local report="$DRY_RESULTS_DIR/dry-run-report.md"
    local detected adapter rc
    detected="$(cat "$DRY_RESULTS_DIR/detected-version" 2>/dev/null || printf 'unknown')"
    adapter="$(cat  "$DRY_RESULTS_DIR/selected-adapter"  2>/dev/null || printf '(none)')"
    rc="$(cat       "$DRY_RESULTS_DIR/exit-code"        2>/dev/null || printf '(n/a)')"

    {
        printf '%s\n\n' '# Dry-run migration report'
        # bash printf builtin treats a leading literal '-' as an option flag.
        # Pass `--` end-of-options once, then use `%s` placeholders for any
        # text that begins with '-' (e.g. our bullet rows).
        printf -- '%s `%s`\n' '- Target input:       ' "$DRY_TARGET_INPUT"
        printf -- '%s `%s`\n' '- Detected version:  ' "$detected"
        printf -- '%s `%s`\n' '- Selected adapter:  ' "$adapter"
        printf -- '%s `%s`\n' '- Adapter exit code: ' "$rc"
        printf -- '%s `%s`\n' '- Pack repo:         ' "$DRY_PACK"
        printf -- '%s `%s`\n' '- Work dir (cleaned):' "$DRY_WORK_DIR"
        printf '\n%s\n\n```\n' '## Diff (file list)'
        cat "$DRY_RESULTS_DIR/diff.stat" 2>/dev/null || printf '%s\n' '(no diff captured)'
        printf '```\n\n%s\n\n```\n' '## Adapter stdout (tail)'
        tail -n 40 "$DRY_RESULTS_DIR/stdout.log" 2>/dev/null \
            || printf '%s\n' '(no stdout captured)'
        printf '```\n\n%s\n\n```\n' '## Adapter stderr (tail)'
        tail -n 40 "$DRY_RESULTS_DIR/stderr.log" 2>/dev/null \
            || printf '%s\n' '(no stderr captured)'
        printf '```\n'
    } > "$report"

    if [[ -n "$DRY_REPORT_OUT" ]]; then
        # Best-effort persistent copy. Failure to copy does NOT change the
        # overall exit status — the in-tmp report still rendered.
        cp "$report" "$DRY_REPORT_OUT" 2>/dev/null \
            || dry_warn "could not copy report to $DRY_REPORT_OUT"
    fi
    dry_say "report: $report"
}

# ── Main ───────────────────────────────────────────────────────────────────

dry_main() {
    dry_parse_args "$@"
    dry_preflight
    trap dry_cleanup EXIT INT TERM HUP

    local rc=0
    dry_acquire_target || rc=$?
    if (( rc != 0 )); then
        return "$rc"
    fi

    dry_run_migrator || rc=$?
    # Render the report regardless of adapter success; users want to see
    # "what would have happened" even when the migrator says no.
    dry_render_report || true
    return "$rc"
}

dry_main "$@"
