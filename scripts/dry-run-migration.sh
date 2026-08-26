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
# `--apply-sandbox` extends any of the three modes: after the dry-run
# preview, the REAL migration is applied to the same disposable copy
# (reconciliation sidecars auto-accepted as-is), then a verification
# battery runs on the migrated copy — per-stream line accounting against
# pre-migration monolith snapshots (reduced by the MIGRATION-TRIAGE
# synthesized-field record), _toc.md/_index.md presence, and SET EQUALITY
# between the installed validate-docs.sh conformance failures and the
# MIGRATION-TRIAGE declared manual-fill set. The original target is
# still never modified; all apply work stays in the /tmp copy.
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
# 10..16, 20..30, 31, 99 ranges by reusing 2 + 4..8 for our own conditions):
#   0  — dry-run completed successfully (migration would succeed)
#   2  — usage error (bad/missing args, --help is its own path → 0)
#   4  — target acquisition failed (clone or copy)
#   5  — read-only enforcement refused (work dir outside /tmp/$TMPDIR)
#   6  — version detection / adapter selection failed
#   7  — adapter (the actual migrator) returned non-zero
#   8  — --apply-sandbox verification battery failed (the adapter itself
#        returned 0; accounting / presence / set-equality found a defect)
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
# Collision-free against the measured framework set: framework 10..16,
# fail_stage 20+N (20..30), EXIT_GATE_FAILED=31, EXIT_INTERNAL=99;
# local 0/2/4..7 above.
readonly DRY_EXIT_SANDBOX_VERIFY=8

# ── Globals (set by parse_args / main) ─────────────────────────────────────

DRY_TARGET_INPUT=""        # raw first arg as the user supplied it
DRY_APPLY_SANDBOX=0        # --apply-sandbox (full apply + verification battery)
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
  --apply-sandbox           After the dry-run preview, apply the REAL
                            migration to the disposable copy
                            (reconciliation sidecars auto-accepted
                            as-is) and run the verification battery on
                            the migrated copy: per-stream line
                            accounting against pre-migration monolith
                            snapshots (reduced by the MIGRATION-TRIAGE
                            synthesized-field record), _toc.md/_index.md
                            presence, and set equality between the
                            installed validate-docs.sh conformance
                            failures and the MIGRATION-TRIAGE declared
                            manual-fill set. The original target is
                            still never modified. Battery failure exits 8.
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
  8  --apply-sandbox verification battery failed (adapter returned 0)
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
            --apply-sandbox)
                DRY_APPLY_SANDBOX=1
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

# ── --apply-sandbox: snapshot + apply + verification battery ──────────────
#
# All sandbox work happens on the disposable $DRY_CLONE_DIR copy; the
# original target is never touched. Harness-internal git verbs stay
# inside the self-provisioned $TMPDIR clone.

# Copy the v10 monolith set from the working copy into the results dir
# BEFORE any migration mutates it. Both plan spellings are snapshotted
# (whichever exist); absent files are skipped (a partial v10 monolith
# set is a valid pre-state).
dry_sandbox_snapshot() {
    local snapdir="$DRY_RESULTS_DIR/monolith-snapshots"
    mkdir -p "$snapdir"
    local rel
    for rel in docs/project/BACKLOG.md \
               docs/project/IMPLEMENTATION-PLAN.md \
               docs/project/IMPLEMENTATION_PLAN.md \
               docs/project/CHANGELOG.md; do
        if [[ -f "$DRY_CLONE_DIR/$rel" ]]; then
            cp "$DRY_CLONE_DIR/$rel" "$snapdir/${rel##*/}"
        fi
    done
    return 0
}

# Echo the migrator state dir on the clone (`.pack-migrate-<from>-to-<to>`,
# never the `-backup` sibling); return 1 when absent.
dry_sandbox_state_dir() {
    local d
    for d in "$DRY_CLONE_DIR"/.pack-migrate-*-to-*; do
        [[ -d "$d" ]] || continue
        case "$d" in *-backup) continue ;; esac
        printf '%s\n' "$d"
        return 0
    done
    return 1
}

# Run the real adapter with --apply on the disposable copy, auto-resolving
# the reconciliation pause when it fires, then dispatch the verification
# battery. Returns 0, DRY_EXIT_ADAPTER, or DRY_EXIT_SANDBOX_VERIFY.
dry_apply_sandbox() {
    local adapter
    adapter="$(cat "$DRY_RESULTS_DIR/selected-adapter" 2>/dev/null)"
    if [[ -z "$adapter" || ! -f "$adapter" ]]; then
        dry_err "apply-sandbox: no selected adapter recorded"
        return "$DRY_EXIT_DETECT_OR_DISPATCH"
    fi

    # The dry-run phase staged the clone for its diff capture; unstage so
    # the adapter's clean-tree preflight sees the same state a real
    # operator's --apply would. Working tree untouched.
    git -C "$DRY_CLONE_DIR" reset -q >/dev/null 2>&1 || true

    # Explicit --apply rides the dry-run fingerprint the preview phase
    # just wrote (the adapter's freshness gate requires it).
    # --no-interactive forces the deterministic pause path on a TTY.
    dry_info "running adapter --apply (sandbox) against the clone"
    local apply_rc=0
    PACK="$DRY_PACK" bash "$adapter" --apply --no-interactive "$DRY_CLONE_DIR" \
        > "$DRY_RESULTS_DIR/apply-stdout.log" \
        2> "$DRY_RESULTS_DIR/apply-stderr.log" \
        || apply_rc=$?
    printf '%s\n' "$apply_rc" > "$DRY_RESULTS_DIR/apply-exit-code"
    if (( apply_rc != 0 )); then
        dry_err "adapter --apply exited non-zero: $apply_rc (see $DRY_RESULTS_DIR/apply-stderr.log)"
        return "$DRY_EXIT_ADAPTER"
    fi

    # A customization-divergent target pauses at the reconciliation gate
    # (exit 0 + stage-S3.paused + sidecars). The sandbox accepts the
    # current destination content as-is (the documented default-accept
    # path: a `.resolved` companion per sidecar listed in the paused
    # sentinel) and resumes — the battery verifies decompose fidelity,
    # not the operator's per-file reconciliation choices.
    local state_dir paused
    state_dir="$(dry_sandbox_state_dir || true)"
    paused="$state_dir/sentinels/stage-S3.paused"
    if [[ -n "$state_dir" && -f "$paused" ]]; then
        dry_info "apply paused at the reconciliation gate — auto-accepting sidecars, resuming"
        local s
        while IFS= read -r s; do
            [[ -n "$s" && -f "$s" ]] && touch "${s}.resolved"
        done < "$paused"
        local resume_rc=0
        PACK="$DRY_PACK" bash "$adapter" --resume "$DRY_CLONE_DIR" \
            > "$DRY_RESULTS_DIR/resume-stdout.log" \
            2> "$DRY_RESULTS_DIR/resume-stderr.log" \
            || resume_rc=$?
        printf '%s\n' "$resume_rc" > "$DRY_RESULTS_DIR/resume-exit-code"
        if (( resume_rc != 0 )); then
            dry_err "adapter --resume exited non-zero: $resume_rc (see $DRY_RESULTS_DIR/resume-stderr.log)"
            return "$DRY_EXIT_ADAPTER"
        fi
    fi

    # Re-capture the diff so the report reflects the APPLIED migration
    # (replaces the dry-run capture).
    git -C "$DRY_CLONE_DIR" add -A >/dev/null 2>&1 || true
    git -C "$DRY_CLONE_DIR" diff --cached --stat \
        > "$DRY_RESULTS_DIR/diff.stat" 2>/dev/null || true
    git -C "$DRY_CLONE_DIR" diff --cached \
        > "$DRY_RESULTS_DIR/diff.patch" 2>/dev/null || true

    # Internal test seam (not a user surface): iff the env names an
    # executable file, run it with the clone dir as $1 AFTER the adapter
    # and BEFORE the verification battery.
    if [[ -n "${DRY_APPLY_SANDBOX_POST_HOOK:-}" && -x "${DRY_APPLY_SANDBOX_POST_HOOK:-}" ]]; then
        "$DRY_APPLY_SANDBOX_POST_HOOK" "$DRY_CLONE_DIR" \
            || dry_warn "apply-sandbox post hook returned non-zero"
    fi

    dry_sandbox_verify
}

# The §5.1(a)–(e) verification battery on the migrated copy. Runs EVERY
# leg (no short-circuit — all failures are diagnosis payload), records
# per-stream accounting verdicts + the validate-docs set-equality delta
# for the report, and returns DRY_EXIT_SANDBOX_VERIFY when any leg
# failed. Leg (a) — adapter rc==0 — was already enforced by the caller.
dry_sandbox_verify() {
    local state_dir snapdir failures
    state_dir="$(dry_sandbox_state_dir || true)"
    snapdir="$DRY_RESULTS_DIR/monolith-snapshots"
    failures="$DRY_RESULTS_DIR/sandbox-failures.txt"
    : > "$failures"
    : > "$DRY_RESULTS_DIR/sandbox-accounting.txt"

    dry_info "sandbox verification battery on the migrated copy"

    # ── Parse the SHIPPED MIGRATION-TRIAGE machine blocks ──
    # The migrated copy's TRIAGE is the load-bearing input: the
    # `## Synthesized fields` fenced block feeds the reduced-mode
    # accounting; the `## Manual fill required` fenced block is the
    # declared set for the validate-docs comparison. Absent TRIAGE
    # parses to empty records.
    DRY_SB_TRIAGE="$DRY_CLONE_DIR/docs/project/MIGRATION-TRIAGE.md" \
    DRY_SB_OUT="$DRY_RESULTS_DIR" \
        python3 - <<'PYEOF'
import os

triage = os.environ["DRY_SB_TRIAGE"]
out = os.environ["DRY_SB_OUT"]

synth, manual = [], []
if os.path.isfile(triage):
    with open(triage, "r", encoding="utf-8", newline="") as f:
        section, in_fence = None, False
        for raw in f.read().splitlines():
            if raw.startswith("## ") and not in_fence:
                section = raw[3:].strip()
                continue
            if raw.startswith("```"):
                in_fence = not in_fence
                continue
            if in_fence and section == "Synthesized fields" and raw.strip():
                synth.append(raw)
            elif in_fence and section == "Manual fill required" and raw.strip():
                manual.append(raw)

def write(name, rows):
    with open(os.path.join(out, name), "w", encoding="utf-8",
              newline="") as f:
        for r in rows:
            f.write(r + "\n")

write("triage-synth-project-backlog.tsv",
      [r for r in synth if r.startswith("backlog/")])
write("triage-synth-project-implementation-plan.tsv",
      [r for r in synth if r.startswith("implementation-plan/")])
write("triage-declared.tsv", manual)
PYEOF

    # ── (b) per-stream accounting in reduced mode ──
    # Pre-migration snapshots vs the migrated tree + the migrator's
    # capture files, with the tree-side multiset reduced by EXACTLY the
    # TRIAGE-shipped synthesized-line record. A stream with no snapshot
    # had no monolith input at clone time — SKIP (valid pre-state).
    local spec key candidates sub snap cand synth_arg dropped acct_out acct_rc
    for spec in \
        "project-backlog|BACKLOG.md|backlog" \
        "project-implementation-plan|IMPLEMENTATION-PLAN.md IMPLEMENTATION_PLAN.md|implementation-plan" \
        "project-changelog|CHANGELOG.md|changelog"; do
        key="${spec%%|*}"
        local rest="${spec#*|}"
        candidates="${rest%%|*}"
        sub="${rest##*|}"

        snap=""
        for cand in $candidates; do
            if [[ -f "$snapdir/$cand" ]]; then
                snap="$snapdir/$cand"
                break
            fi
        done
        if [[ -z "$snap" ]]; then
            printf '%s\tSKIP\tno monolith input at clone time\n' "$key" \
                >> "$DRY_RESULTS_DIR/sandbox-accounting.txt"
            continue
        fi

        dropped=""
        [[ -n "$state_dir" ]] && dropped="$state_dir/dropped-$key.md"
        synth_arg=""
        case "$key" in
            project-backlog|project-implementation-plan)
                synth_arg="$DRY_RESULTS_DIR/triage-synth-$key.tsv"
                ;;
        esac

        # Subshell: the accounting lib's pe_die exits; contain it.
        acct_rc=0
        if [[ -n "$synth_arg" ]]; then
            acct_out=$( {
                . "$DRY_PACK/scripts/lib/per-entry/accounting.sh"
                per_entry_accounting_check "$key" "$snap" \
                    "$DRY_CLONE_DIR/docs/project/$sub" "$dropped" "$synth_arg"
            } 2>&1 ) || acct_rc=$?
        else
            acct_out=$( {
                . "$DRY_PACK/scripts/lib/per-entry/accounting.sh"
                per_entry_accounting_check "$key" "$snap" \
                    "$DRY_CLONE_DIR/docs/project/$sub" "$dropped"
            } 2>&1 ) || acct_rc=$?
        fi
        if (( acct_rc == 0 )); then
            printf '%s\tPASS\t%s\n' "$key" "$acct_out" \
                >> "$DRY_RESULTS_DIR/sandbox-accounting.txt"
        else
            {
                printf '%s\tFAIL\n' "$key"
                printf '%s\n' "$acct_out"
            } >> "$DRY_RESULTS_DIR/sandbox-accounting.txt"
            printf '%s\n' "$acct_out" >&2
            printf '(b) accounting FAIL: %s\n' "$key" >> "$failures"
        fi

        # ── (c) generated-surface presence for decomposed streams ──
        if [[ ! -f "$DRY_CLONE_DIR/docs/project/$sub/_toc.md" ]]; then
            printf '(c) missing _toc.md: docs/project/%s/\n' "$sub" >> "$failures"
        fi
        if [[ "$key" == "project-implementation-plan" \
              && ! -f "$DRY_CLONE_DIR/docs/project/$sub/_index.md" ]]; then
            printf '(c) missing _index.md: docs/project/%s/\n' "$sub" >> "$failures"
        fi
    done

    # ── (d) installed-validator conformance vs the declared set ──
    # Run the SHIPPED validate-docs.sh FROM the migrated copy, normalize
    # its [conformance] failure lines to (relpath, class) pairs, and
    # assert SET EQUALITY with the TRIAGE manual-fill machine block.
    # Non-conformance axes (history/deferred/bloat/dangling/session-state)
    # are outside the instrument; their count is recorded as context.
    local vd_rc=0
    if [[ -f "$DRY_CLONE_DIR/scripts/validate-docs.sh" ]]; then
        bash "$DRY_CLONE_DIR/scripts/validate-docs.sh" \
            > "$DRY_RESULTS_DIR/validate-docs.out" 2>&1 || vd_rc=$?
        local delta_rc=0
        DRY_SB_VDOUT="$DRY_RESULTS_DIR/validate-docs.out" \
        DRY_SB_VDRC="$vd_rc" \
        DRY_SB_DECLARED="$DRY_RESULTS_DIR/triage-declared.tsv" \
        DRY_SB_DELTA="$DRY_RESULTS_DIR/sandbox-validate-delta.txt" \
            python3 - <<'PYEOF' || delta_rc=$?
import os
import re

vd_out = os.environ["DRY_SB_VDOUT"]
vd_rc = os.environ["DRY_SB_VDRC"]
declared_path = os.environ["DRY_SB_DECLARED"]
delta_path = os.environ["DRY_SB_DELTA"]

declared = set()
with open(declared_path, "r", encoding="utf-8", newline="") as f:
    for row in f.read().splitlines():
        if row.strip():
            declared.add(row.rstrip("\n"))

CONF_RE = re.compile(r"^  - (\S+) \[conformance\] (.*)$")
CLASS_RES = (
    (re.compile(r"missing field 'Status'"), lambda m: "missing-status"),
    (re.compile(r"missing field 'Goal'"), lambda m: "missing-goal"),
    (re.compile(r"Scope '([^']*)' not in"),
     lambda m: "payload-out-of-enum:Scope=" + m.group(1)),
    (re.compile(r"Severity '([^']*)' not in"),
     lambda m: "payload-out-of-enum:Severity=" + m.group(1)),
)

measured = set()
other_axis = 0
with open(vd_out, "r", encoding="utf-8", newline="") as f:
    for line in f.read().splitlines():
        if not line.startswith("  - "):
            continue
        m = CONF_RE.match(line)
        if not m:
            other_axis += 1
            continue
        rel, msg = m.group(1), m.group(2)
        if rel.startswith("docs/project/"):
            rel = rel[len("docs/project/"):]
        cls = None
        for rx, mk in CLASS_RES:
            hit = rx.search(msg)
            if hit:
                cls = mk(hit)
                break
        if cls is None:
            cls = "other:" + msg[:80]
        measured.add(rel + "\t" + cls)

undeclared = sorted(measured - declared)
undelivered = sorted(declared - measured)
green = not undeclared and not undelivered

with open(delta_path, "w", encoding="utf-8", newline="") as f:
    f.write("validate-docs exit code: %s\n" % vd_rc)
    f.write("declared manual-fill rows: %d\n" % len(declared))
    f.write("measured conformance rows: %d\n" % len(measured))
    f.write("non-conformance failure lines (outside the instrument): %d\n"
            % other_axis)
    f.write("set-equality: %s\n" % ("GREEN" if green else "RED"))
    for row in undeclared:
        f.write("UNDECLARED: %s\n" % row)
    for row in undelivered:
        f.write("UNDELIVERED: %s\n" % row)

raise SystemExit(0 if green else 1)
PYEOF
        if (( delta_rc != 0 )); then
            grep -E '^(UNDECLARED|UNDELIVERED):' \
                "$DRY_RESULTS_DIR/sandbox-validate-delta.txt" >&2 || true
            printf '(d) validate-docs set-equality RED (see sandbox-validate-delta.txt)\n' \
                >> "$failures"
        fi
    else
        printf '(d) installed validator missing: scripts/validate-docs.sh\n' \
            >> "$failures"
        printf 'validate-docs exit code: (not run — validator missing)\nset-equality: RED\n' \
            > "$DRY_RESULTS_DIR/sandbox-validate-delta.txt"
    fi

    # ── (e) TRIAGE existence rule ──
    # MIGRATION-TRIAGE.md exists iff (captures ∪ synthesis ∪ manual-fill)
    # is nonempty. Captures + synthesis are read from the migrator state
    # dir; manual-fill evidence is the measured conformance set from (d).
    local has_need=0 f
    if [[ -n "$state_dir" ]]; then
        for f in "$state_dir"/dropped-*.md "$state_dir"/synthesized-*.tsv; do
            [[ -f "$f" ]] || continue
            if grep -q '[^[:space:]]' "$f" 2>/dev/null; then
                has_need=1
                break
            fi
        done
    fi
    if (( has_need == 0 )) \
        && grep -q '^measured conformance rows: [1-9]' \
            "$DRY_RESULTS_DIR/sandbox-validate-delta.txt" 2>/dev/null; then
        has_need=1
    fi
    if [[ -f "$DRY_CLONE_DIR/docs/project/MIGRATION-TRIAGE.md" ]]; then
        if (( has_need == 0 )); then
            printf '(e) MIGRATION-TRIAGE.md present but captures, synthesis, and manual-fill are all empty\n' \
                >> "$failures"
        fi
    else
        if (( has_need == 1 )); then
            printf '(e) MIGRATION-TRIAGE.md absent but captures/synthesis/manual-fill nonempty\n' \
                >> "$failures"
        fi
    fi

    if [[ -s "$failures" ]]; then
        dry_err "sandbox verification battery FAILED:"
        while IFS= read -r f; do
            dry_err "  $f"
        done < "$failures"
        return "$DRY_EXIT_SANDBOX_VERIFY"
    fi
    dry_info "sandbox verification battery PASS (accounting + presence + set-equality)"
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
        if (( DRY_APPLY_SANDBOX )); then
            printf -- '%s `%s`\n' '- Mode:              ' 'apply-sandbox'
        fi
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
        if (( DRY_APPLY_SANDBOX )); then
            printf '\n%s\n\n```\n' '## Accounting verdicts'
            cat "$DRY_RESULTS_DIR/sandbox-accounting.txt" 2>/dev/null \
                || printf '%s\n' '(no accounting verdicts captured)'
            printf '```\n\n%s\n\n```\n' '## validate-docs delta'
            cat "$DRY_RESULTS_DIR/sandbox-validate-delta.txt" 2>/dev/null \
                || printf '%s\n' '(no validate-docs delta captured)'
            printf '```\n'
        fi
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

    # Sandbox mode: snapshot the monolith set BEFORE any migration work —
    # the accounting battery compares the migrated tree against these.
    if (( DRY_APPLY_SANDBOX )); then
        dry_sandbox_snapshot
    fi

    dry_run_migrator || rc=$?

    # Sandbox mode: apply the real migration to the disposable copy and
    # run the verification battery (only when the preview succeeded).
    if (( rc == 0 && DRY_APPLY_SANDBOX )); then
        dry_apply_sandbox || rc=$?
    fi

    # Render the report regardless of adapter success; users want to see
    # "what would have happened" even when the migrator says no.
    dry_render_report || true
    return "$rc"
}

dry_main "$@"
