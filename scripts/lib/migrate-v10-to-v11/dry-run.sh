# scripts/lib/migrate-v10-to-v11/dry-run.sh — BD-095 `--dry-run` mode for the
# v10 → v11 migrator.
#
# Sourced by `scripts/migrate-v10-to-v11.sh` only. Adapters do NOT source
# this directly — the entry point is the v10→v11 adapter's mode dispatcher.
#
# Responsibilities:
#   - Produce a deterministic fingerprint over the *target customization
#     surface* (the project-relative paths returned by
#     `migrator_target_surface_for_version v10`) so a later `--apply` can
#     verify the working tree has not drifted since the dry-run report
#     was reviewed (architecture §6.G — 24-hour freshness window).
#   - Drive `migrator_run --dry-run` through the framework so S0..S6 are
#     exercised without mutating the working tree (framework I6).
#   - Persist the fingerprint + an epoch timestamp + the resolved
#     `MIGRATOR_TO_VERSION` so the apply.sh comparator can detect both
#     working-tree drift and stale dry-run output (architecture §6.G).
#
# Public API (sourced into the adapter's shell):
#   migrate_v10_to_v11_dry_run_run "$@"
#       Runs the framework in --dry-run mode then stamps the fingerprint
#       file. Forwards stdout/stderr from the framework verbatim. Exits
#       with the framework's exit code on framework failure; exits 0 on
#       fingerprint write success.
#
#   migrate_v10_to_v11_dry_run_compute_fingerprint <target>
#       Echoes a single line: "<sha256>  <file-count>" computed from the
#       customization surface of <target>. Used both by dry-run.sh (to
#       stamp) and by apply.sh (to verify-against). Pure read-only.
#
# Internal helpers prefixed with `_v10_v11_dryrun_`.
#
# Do NOT add a shebang — this file is sourced, not executed.

# Path layout used by all three BD-095 mode libs. `$_MIGRATOR_STATE_DIR`
# is set by the framework's `_migrator_parse_args`; on a cold dry-run
# invocation the framework has not run yet, so we derive the same path
# from the target argument before invoking the framework.
#
# Fingerprint file format (newline-separated key=value records):
#   schema=1
#   to_version=v11
#   epoch=<unix epoch seconds>
#   target_sha256=<sha256 of normalized surface listing>
#   target_files=<integer count of files folded into the sha>
#
# `schema=1` lets future BDs evolve the format without silently mis-
# reading old fingerprints.

# ── Internal: fingerprint computation ──────────────────────────────────────
#
# Walk the project-relative paths in the v10 customization surface, plus
# every regular file under the per-CLI agents directories (so a project
# that added custom agent files is detected as drifted). For each file
# that exists, emit `<relpath>\t<sha256>` to a sorted listing, then sha256
# the listing itself for a single deterministic fingerprint.
#
# bash 3.2 + macOS shasum compatible. Uses `shasum -a 256` (preferred over
# `sha256sum` because BSD systems ship the former; falls back to
# `sha256sum` if `shasum` is missing).
_v10_v11_dryrun_sha256_cmd() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum
    else
        die "no sha256 tool available (need shasum or sha256sum)" \
            "$EXIT_INTERNAL"
    fi
}

migrate_v10_to_v11_dry_run_compute_fingerprint() {
    local target="${1:-}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        die "migrate_v10_to_v11_dry_run_compute_fingerprint: target dir required" \
            "$EXIT_INTERNAL"
    fi

    # Surface = explicit v10 list (trinity, .codex/config.toml, BACKLOG.md)
    # PLUS recursive contents of per-CLI agents directories. Manifest-row
    # files are covered by the explicit list; sweep-row files (agents) are
    # covered by the recursion. Limited to the v10 surface so the apply
    # comparator stays insensitive to v11-only files the dry-run might
    # have proposed adding (e.g. tracker.toml.example).
    local explicit=(
        "CLAUDE.md"
        "AGENTS.md"
        "GEMINI.md"
        ".codex/config.toml"
        "BACKLOG.md"
    )
    local sweep_dirs=(
        ".claude/agents"
        ".codex/agents"
        ".gemini/agents"
    )

    local listing
    listing=$(mktemp)

    local rel f abs sha
    for rel in "${explicit[@]}"; do
        abs="$target/$rel"
        if [[ -f "$abs" ]]; then
            sha=$(_v10_v11_dryrun_sha256_cmd < "$abs" | awk '{print $1}')
            printf '%s\t%s\n' "$rel" "$sha" >> "$listing"
        fi
    done

    local sweep
    for sweep in "${sweep_dirs[@]}"; do
        [[ -d "$target/$sweep" ]] || continue
        # `find … -type f` is BSD/GNU portable. Sort for determinism.
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            sha=$(_v10_v11_dryrun_sha256_cmd < "$f" | awk '{print $1}')
            rel="${f#"$target/"}"
            printf '%s\t%s\n' "$rel" "$sha" >> "$listing"
        done < <(find "$target/$sweep" -type f -print 2>/dev/null | sort)
    done

    local count combined
    if [[ -s "$listing" ]]; then
        # Ensure the listing itself is sorted before hashing — `find`
        # output above is sorted per-sweep; pre-sort the combined file so
        # interleaving order does not affect the fingerprint.
        sort -o "$listing" "$listing"
        count=$(wc -l < "$listing" | tr -d ' ')
        combined=$(_v10_v11_dryrun_sha256_cmd < "$listing" | awk '{print $1}')
    else
        # Empty surface — uncommon but stamp deterministically.
        count=0
        combined=$(printf '' | _v10_v11_dryrun_sha256_cmd | awk '{print $1}')
    fi

    rm -f "$listing"
    printf '%s  %s\n' "$combined" "$count"
}

# ── Public: dry-run dispatcher ─────────────────────────────────────────────

migrate_v10_to_v11_dry_run_run() {
    # Resolve the target directory the same way the framework will. The
    # framework parses positional args inside `migrator_run`; we mirror
    # the parse here only enough to know where to put the fingerprint
    # AFTER the framework has finished. Anything trickier (-h / --help)
    # is deferred to the framework's parser.
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

    # Defer to the framework. `migrator_run` calls `_migrator_parse_args`
    # which sets `_MIGRATOR_DRY_RUN=1` when it sees `--dry-run`, so all
    # _stage_* functions short-circuit their writes. Returns 0 on a
    # clean dry-run.
    migrator_run --dry-run "$@"
    local rc=$?
    if (( rc != 0 )); then
        return "$rc"
    fi

    # Stamp the fingerprint file. The state dir was created by
    # _stage_libs even in dry-run mode (the dispositions.tsv lives there),
    # so this write does not need to mkdir.
    if [[ ! -d "$state_dir" ]]; then
        warn "dry-run: state dir $state_dir not present after run; skipping fingerprint stamp"
        return 0
    fi

    # Render report.md from the dispositions.tsv that the framework's
    # dry-run plumbing recorded. The framework's `_stage_report` skips
    # the actual render in --dry-run mode (it only logs "would render"),
    # so we materialize the report here. State is read-only — the
    # render is a write to the state dir, not the project tree, and is
    # the deliverable BD-095 promises ("--dry-run produces report").
    if [[ -f "$state_dir/dispositions.tsv" ]] \
       && declare -F customization_report >/dev/null 2>&1; then
        customization_report \
            "$state_dir/dispositions.tsv" \
            "$state_dir/report.md" \
            "${MIGRATOR_FROM_VERSION} → ${MIGRATOR_TO_VERSION} migration customization report (--dry-run preview)" \
            >/dev/null 2>&1 || true
    fi

    local fp_line fp_sha fp_count epoch
    fp_line=$(migrate_v10_to_v11_dry_run_compute_fingerprint "$target")
    fp_sha=$(printf '%s' "$fp_line" | awk '{print $1}')
    fp_count=$(printf '%s' "$fp_line" | awk '{print $2}')
    epoch=$(date +%s)

    {
        printf 'schema=1\n'
        printf 'to_version=%s\n' "$MIGRATOR_TO_VERSION"
        printf 'epoch=%s\n' "$epoch"
        printf 'target_sha256=%s\n' "$fp_sha"
        printf 'target_files=%s\n' "$fp_count"
    } > "$state_dir/dry-run.fingerprint"

    say ""
    say "Dry-run fingerprint stamped: $state_dir/dry-run.fingerprint"
    say "  target_sha256: $fp_sha"
    say "  target_files:  $fp_count"
    say "  epoch:         $epoch (24h freshness window)"
    say ""
    say "Review the report at $state_dir/report.md, then run --apply"
    say "to write the changes. The fingerprint guards against working-tree"
    say "drift between dry-run review and apply."
    return 0
}
