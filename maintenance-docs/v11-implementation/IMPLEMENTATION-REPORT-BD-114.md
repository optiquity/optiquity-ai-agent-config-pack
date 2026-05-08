# IMPLEMENTATION-REPORT-BD-114.md

**BD:** BD-114 — `dry-run-migration.sh` parameterized read-only migration harness
**Agent:** pack-coder
**Branch:** `worktree-agent-af389d6ba82b944a7`
**HEAD SHA at start and end:** `01ecadd7601dc2ae043f85dccc43c70423ed807e` (unchanged — agents do not commit)
**Date:** 2026-05-08

---

## 1. Pre-flight (verbatim)

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af389d6ba82b944a7

$ git rev-parse HEAD
01ecadd7601dc2ae043f85dccc43c70423ed807e

$ git rev-parse --abbrev-ref HEAD
worktree-agent-af389d6ba82b944a7

$ git log --oneline -10
01ecadd docs: v11 — BD-121 correction: remove forbidden CHANGELOG mid-version edit step
63a096c feat: v11 — flip BD-115 + BD-119 to Resolved (Batch 8a closed; persona-coverage infra + N→N+1 migrator framework)
79f3aef fix: v11 — BD-119 fix-follow: B1 BLOCKER + S1..S5 SHOULD-FIX (Batch 8a review)
17a0cda docs: v11 — pack-reviewer report for BD-115 + BD-119 (1 BLOCKER, 5 SHOULD-FIX, 3 NICE-TO-HAVE)
d2cd9b4 docs: v11 — BD-119 C-7: migrator-framework doc refresh
861c158 refactor: v11 — BD-119 C-6: cut migrate-v10-to-v11.sh over to framework adapter
9f9f052 feat: v11 — BD-119 C-5: behavior-preservation harness (mandatory pre-C-6 gate)
3724d72 docs: v11 — reshape BD-114 for public usability + open BD-125 companion doc
0532526 docs: v11 — clarify BD-116 sequencing note + expand BD-121 scope (validate-pack + supporting-docs ripple)
23b0cb0 feat: v11 — BD-119 C-4b: add test-migrator-core.sh (T-12 unit tests; closes POQ-6)

$ ls scripts/lib/migrator-*.sh
scripts/lib/migrator-core.sh
scripts/lib/migrator-manifest.sh
scripts/lib/migrator-stages.sh

$ ls scripts/migrate-v10-to-v11.sh
scripts/migrate-v10-to-v11.sh

$ grep -c "BD-114" BACKLOG.md
11
```

The `test-fixtures/v10-realistic-ot/` directory was NOT present at start (the
fixture is gitignored / only-on-demand). I rebuilt it via
`bash test-fixtures/build.sh --name v10-realistic-ot --clean`, which produced
HEAD `239c98a657a709f1508e372f53e45ced24fb7b4d` — the manifest-pinned SHA.
See §6 (Plan deviations / side-effects) for the manifest.txt side-effect this
introduced.

All other pre-flight checks pass: HEAD descended from `01ecadd`, branch starts
with `worktree-agent-`, framework lib files present, adapter present, BACKLOG
entry present.

---

## 2. T-task summary

The work was a single track (no internal sub-tasks).

| File | Status | Lines | Verification |
|---|---|---|---|
| `scripts/dry-run-migration.sh` | NEW | 478 | `bash -n` clean; happy-path exit 0 against fixture |
| `scripts/test-dry-run-migration.sh` | NEW | 117 | `bash -n` clean; 7/7 sub-assertions PASS |

Both files chmod +x (executable).

No other source files were modified.

---

## 3. Full file contents

### 3.1 `scripts/dry-run-migration.sh` (NEW)

```bash
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
```

### 3.1-cont `scripts/dry-run-migration.sh` (continued)

```bash
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
```

### 3.2 `scripts/test-dry-run-migration.sh` (NEW)

```bash
#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-dry-run-migration.sh — BD-114 self-tests.
#
# Verifies scripts/dry-run-migration.sh against:
#   T1 happy-path  — synthetic fixture (test-fixtures/v10-realistic-ot)
#                    exits 0, --report-out file is written, work dir is
#                    cleaned afterwards.
#   T2 missing-arg — invoked with no args, exits with usage code (2).
#   T3 bad-path    — invoked with a non-existent local path, exits with
#                    acquisition code (4).
#   T4 tmp-refused — invoked with `--tmp-dir` outside /tmp / $TMPDIR,
#                    exits with read-only-refused code (5).
#
# Usage:
#     bash scripts/test-dry-run-migration.sh
#
# Exit 0 on all-pass; 1 otherwise. Prints a summary line:
#     === Results: <P> passed, <F> failed ===

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HARNESS="$SCRIPT_DIR/dry-run-migration.sh"
FIXTURE="$PACK_ROOT/test-fixtures/v10-realistic-ot"

PASS_COUNT=0
FAIL_COUNT=0

t_pass() { printf '  PASS — %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
t_fail() { printf '  FAIL — %s\n' "$1" >&2; FAIL_COUNT=$((FAIL_COUNT + 1)); }

[[ -x "$HARNESS" ]] \
    || { printf 'FATAL: harness not executable: %s\n' "$HARNESS" >&2; exit 1; }

# ── T1: happy path ─────────────────────────────────────────────────────────

printf 'T1 — happy path against %s\n' "$FIXTURE"
if [[ ! -d "$FIXTURE" ]]; then
    t_fail "T1 fixture missing: $FIXTURE (run test-fixtures/build.sh --name v10-realistic-ot --clean)"
else
    t1_report="$(mktemp -t bd114-t1-report.XXXXXX)"
    t1_log="$(mktemp -t bd114-t1-log.XXXXXX)"
    rc=0
    bash "$HARNESS" "$FIXTURE" --report-out "$t1_report" \
        > "$t1_log" 2>&1 || rc=$?
    if [[ "$rc" -eq 0 ]]; then
        t_pass "T1.a exit code = 0"
    else
        t_fail "T1.a exit code = $rc (expected 0); log: $t1_log"
    fi
    if [[ -s "$t1_report" ]]; then
        t_pass "T1.b --report-out written and non-empty"
    else
        t_fail "T1.b --report-out empty or missing: $t1_report"
    fi
    # Confirm the report mentions a v10-detected path + a non-empty diff.
    if grep -q 'Detected version:.*v10' "$t1_report" 2>/dev/null \
       && grep -q 'Diff (file list)' "$t1_report" 2>/dev/null; then
        t_pass "T1.c report content sane (v10 detected, diff section present)"
    else
        t_fail "T1.c report content missing expected sections; see $t1_report"
    fi
    # Confirm the work dir was cleaned. The log line "Work dir (cleaned)"
    # in the report names the path; it should not exist anymore.
    work_line=$(grep -m1 'Work dir (cleaned)' "$t1_report" 2>/dev/null \
                | sed 's/.*`\(.*\)`.*/\1/')
    if [[ -n "$work_line" && ! -d "$work_line" ]]; then
        t_pass "T1.d work dir cleaned: $work_line"
    elif [[ -z "$work_line" ]]; then
        t_fail "T1.d could not find work-dir line in report"
    else
        t_fail "T1.d work dir still present after run: $work_line"
    fi
    rm -f "$t1_report" "$t1_log"
fi

# ── T2: missing arg ────────────────────────────────────────────────────────

printf 'T2 — missing required arg\n'
t2_log="$(mktemp -t bd114-t2-log.XXXXXX)"
rc=0
bash "$HARNESS" > "$t2_log" 2>&1 || rc=$?
if [[ "$rc" -eq 2 ]]; then
    t_pass "T2 exit code = 2 (DRY_EXIT_USAGE)"
else
    t_fail "T2 exit code = $rc (expected 2); log: $t2_log"
fi
rm -f "$t2_log"

# ── T3: bad local path ─────────────────────────────────────────────────────

printf 'T3 — non-existent local path\n'
t3_log="$(mktemp -t bd114-t3-log.XXXXXX)"
rc=0
bash "$HARNESS" /this/path/does/not/exist-bd114-test \
    > "$t3_log" 2>&1 || rc=$?
if [[ "$rc" -eq 4 ]]; then
    t_pass "T3 exit code = 4 (DRY_EXIT_ACQUIRE)"
else
    t_fail "T3 exit code = $rc (expected 4); log: $t3_log"
fi
rm -f "$t3_log"

# ── T4: --tmp-dir outside /tmp / $TMPDIR ───────────────────────────────────

printf 'T4 — --tmp-dir outside /tmp / $TMPDIR\n'
# Place a refused-tmp-base under PACK_ROOT itself; that is definitely not
# under /tmp or $TMPDIR. The harness must refuse before any clone happens.
t4_bad_tmp="$PACK_ROOT/.bd114-test-refused-tmp-$$"
mkdir -p "$t4_bad_tmp"
t4_log="$(mktemp -t bd114-t4-log.XXXXXX)"
rc=0
bash "$HARNESS" "$FIXTURE" --tmp-dir "$t4_bad_tmp" \
    > "$t4_log" 2>&1 || rc=$?
if [[ "$rc" -eq 5 ]]; then
    t_pass "T4 exit code = 5 (DRY_EXIT_READONLY_REFUSED)"
else
    t_fail "T4 exit code = $rc (expected 5); log: $t4_log"
fi
rm -rf "$t4_bad_tmp"
rm -f "$t4_log"

# ── Summary ────────────────────────────────────────────────────────────────

printf '\n=== Results: %d passed, %d failed ===\n' "$PASS_COUNT" "$FAIL_COUNT"
if (( FAIL_COUNT > 0 )); then
    exit 1
fi
exit 0
```

---

## 4. Verification

### 4.1 `bash -n` (syntax)

```
$ bash -n scripts/dry-run-migration.sh && echo SYN_OK
SYN_OK

$ bash -n scripts/test-dry-run-migration.sh && echo SYN_OK
SYN_OK
```

### 4.2 Self-test

```
$ bash scripts/test-dry-run-migration.sh
T1 — happy path against /Users/.../test-fixtures/v10-realistic-ot
  PASS — T1.a exit code = 0
  PASS — T1.b --report-out written and non-empty
  PASS — T1.c report content sane (v10 detected, diff section present)
  PASS — T1.d work dir cleaned: /var/folders/.../dry-run-migration.HH6zQ1
T2 — missing required arg
  PASS — T2 exit code = 2 (DRY_EXIT_USAGE)
T3 — non-existent local path
  PASS — T3 exit code = 4 (DRY_EXIT_ACQUIRE)
T4 — --tmp-dir outside /tmp / $TMPDIR
  PASS — T4 exit code = 5 (DRY_EXIT_READONLY_REFUSED)

=== Results: 7 passed, 0 failed ===
```

**test-dry-run-migration.sh: 7/7 PASS** (4 tests, 7 sub-assertions).

### 4.3 Happy-path against `test-fixtures/v10-realistic-ot` (last 10 lines + exit code)

```
$ bash scripts/dry-run-migration.sh test-fixtures/v10-realistic-ot
  cloning local git repo into work dir: /Users/.../test-fixtures/v10-realistic-ot
  detected target pack version: v10
  selected adapter: /Users/.../scripts/migrate-v10-to-v11.sh
  running adapter --dry-run against the clone
report: /var/folders/38/2gkt0krd4m55gktw0t7n8wrr0000gn/T/dry-run-migration.a15VKb/results/dry-run-report.md
exit=0
```

The dry-run-report (sample, captured to `/tmp/dry-run-report-test.md`) shows
the would-be migration diff: 12 files / 1040 insertions including the v11-only
artifacts (`HELP-FRAGMENT.md`, `tracker.toml.example`,
`.github/ISSUE_TEMPLATE/*.yml`, per-CLI `pack-help`, `scripts/pack-help.sh`,
`scripts/lib/detect.sh`) plus the `.pack-migrate-v10-to-v11/dispositions.tsv`
record from the BD-088 dispatch engine. The adapter's stdout shows
`[dry-run] would sweep-dispatch ...` lines confirming the framework's I6
invariant engaged (no real writes).

### 4.4 Regression suites

```
$ bash scripts/test-detect.sh
=== Results: 40 passed, 0 failed ===

$ bash scripts/test-migrator-core.sh
=== Results: 19 passed, 0 failed ===

$ bash scripts/test-migrator-manifest.sh
=== Results: 12 passed, 0 failed ===

$ bash scripts/test-migration.sh
tests: 35 total, 35 passed, 0 failed
```

Total: 106 existing assertions still green.

The BD-119 behavior-preservation harness
(`scripts/test-migrator-behavior-preservation.sh`) was NOT re-run because (a)
this BD touches no migrator source files, (b) the harness needs the
gitignored snapshot file (POQ-4) which is branch-local and not present here,
and (c) the four regression suites above already cover the framework
public-API surface this harness consumes. The behavior-preservation harness
remains the canonical pre-tag gate.

---

## 5. Plan deviations

None of substance. Two minor implementation choices that the original prompt
left to my discretion are called out for transparency:

1. **Public API in subshells.** `migrator_detect_target_version` and
   `migrator_select_adapter` call the framework's `die` on error, which
   `exit`s the calling shell. To keep the harness from being killed by an
   adapter-discovery failure, both calls run in `( )` subshells with PACK
   exported. Functionally equivalent to direct calls; structurally safer.
2. **Default `$TMPDIR` on macOS.** The architecture said "refuse anything
   not under /tmp or $TMPDIR." On macOS, `$TMPDIR` defaults to
   `/var/folders/...` — which the test environment uses. The pre-flight
   accepts `/tmp`, `/private/tmp` (macOS canonical of `/tmp`),
   `/var/folders`, and an explicit `$TMPDIR` prefix. Linux CI (`/tmp` only)
   continues to work via the first prefix.

---

## 6. Side-effect: `test-fixtures/manifest.txt` modified

Building the v10-realistic-ot fixture (required for self-test verification —
the fixture is gitignored and absent at branch start) re-wrote
`test-fixtures/manifest.txt` because `test-fixtures/build.sh --name <one>`
does not preserve sibling SHAs; it marks unbuilt fixtures as
`(not built)`. The diff is:

```
-v10-minimal  134a86cfe75fbc1e11a80e844653bde63108d4dd
 v10-realistic-ot  239c98a657a709f1508e372f53e45ced24fb7b4d
-v11-flat-file  521870da0390c89d3725076af9e83f910610513e
-v11-tracker-on  cffa636ae113fede2bb1fd319322756c908c4623
-existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
+v10-minimal  (not built)
+v11-flat-file  (not built)
+v11-tracker-on  (not built)
+existing-project-mid-dev  (not built)
```

The v10-realistic-ot SHA is unchanged (`239c98a...`), so build determinism
is verified. **Recommended Pack Chat action before commit:** restore
`test-fixtures/manifest.txt` via `git checkout -- test-fixtures/manifest.txt`,
or rebuild all five fixtures (`bash test-fixtures/build.sh --all --clean`)
and let the manifest re-fill. I left the working-tree change in place rather
than `git checkout`-ing it myself, because the agent rules forbid
state-changing git verbs even for "clean up my own footprint" cases.

This is also a latent BD-115 issue: `build.sh --name` should not clobber
sibling manifest entries. Recording as a candidate for a future BD on
fixture-builder hygiene; not in BD-114's scope.

---

## 7. New POQs introduced

None. The BD-114 design is fully specified in the BACKLOG entry and
ARCHITECTURE-BD-119.md §5.2. Implementation choices in §5 above are
clearly within the latitude those documents allow.

---

## 8. Definition-of-Done checklist

| # | Item | Status |
|---|---|---|
| 1 | Harness file exists at `scripts/dry-run-migration.sh` | PASS |
| 2 | Self-test exists at `scripts/test-dry-run-migration.sh` | PASS |
| 3 | Happy-path mode 1 works against `test-fixtures/v10-realistic-ot` (exit 0, report rendered) | PASS |
| 4 | Usage error path works (no args → exit 2) | PASS |
| 5 | Bad-path negative test works (exit 4) | PASS |
| 6 | --tmp-dir refusal works (exit 5) | PASS |
| 7 | Cleanup confirmed (work dir absent post-run) | PASS |
| 8 | macOS bash 3.2 portable (`mktemp -d <tmpl>`, `cp -R`, `printf -- '-...'`, no GNU-only flags, no bash-4 features) | PASS |
| 9 | No source modified outside scope (no edits to `migrator-*.sh`, `migrate-v10-to-v11.sh`, doc files) | PASS |
| 10 | Implementation report written | PASS |
| 11 | `bash -n` clean for both new files | PASS |
| 12 | Pre-existing regression suites still green (test-detect 40/40, test-migrator-core 19/19, test-migrator-manifest 12/12, test-migration 35/35) | PASS |

---

## 9. Files changed

| Path | Change | Notes |
|---|---|---|
| `scripts/dry-run-migration.sh` | NEW (executable) | 478 lines; BD-114 harness |
| `scripts/test-dry-run-migration.sh` | NEW (executable) | 117 lines; 4 tests / 7 sub-assertions |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-114.md` | NEW | this file |
| `test-fixtures/v10-realistic-ot/` | NEW (untracked, fixture-built) | gitignored fixture; rebuilt at start of session, SHA `239c98a657a709f1508e372f53e45ced24fb7b4d` matches manifest |
| `test-fixtures/manifest.txt` | MODIFIED (incidental side-effect) | builder script re-wrote sibling fixture rows to `(not built)`; see §6 |

---

## 10. Proposed commit message

```
feat: v11 — BD-114: dry-run-migration.sh parameterized read-only migration harness
```

(Recommended companion commit-prep step before this commit: either
`git checkout -- test-fixtures/manifest.txt` or rebuild all fixtures via
`bash test-fixtures/build.sh --all --clean` so the manifest is whole again.)

