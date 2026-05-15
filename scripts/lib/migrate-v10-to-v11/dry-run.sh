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

    # F1 (BD-095 retro fix): the surface is built dynamically from two
    # framework-owned sources so the fingerprint can never silently
    # under-cover the manifest. ARCHITECTURE-BD-119.md §9.2 is the contract
    # ("avoid duplicating surface knowledge"); the helper +
    # `migrator_manifest` are the two framework-owned tables BD-095
    # consumes. Adding a future v11→v12 transform row to the manifest
    # (or extending `migrator_target_surface_for_version v10`) will
    # automatically expand drift detection without a parallel edit here.
    #
    # Surface composition:
    #   1. `migrator_target_surface_for_version "$MIGRATOR_FROM_VERSION"`
    #      contributes both files (trinity, .codex/config.toml,
    #      BACKLOG.md) and directories (per-CLI agents/) — directories
    #      are swept recursively, files are hashed individually.
    #   2. `migrator_manifest` contributes every row whose action column
    #      is `transform` (project-relative path in column 2). Rows with
    #      action `add` / `remove` / `relocate-from` are excluded — only
    #      `transform`-class rows describe files that an `--apply` will
    #      mutate based on user-side state.
    #   3. Duplicates between (1) and (2) are folded — the trinity files
    #      and `.codex/config.toml` appear in both sources; we union the
    #      sets (sort -u) so each path is hashed once.
    local listing
    listing=$(mktemp)

    # ── (1) Surface from `migrator_target_surface_for_version` ─────────
    # Helper output is one entry per line. Each entry is either a
    # project-relative file or a project-relative directory; we test
    # `[[ -d ]]` to decide which sweep path to take. `unknown` is the
    # one-line sentinel value the helper emits for unsupported versions
    # (returns rc=1) — we treat it as an empty surface and rely on (2)
    # alone, plus warn so the regression test surfaces the framework gap.
    local surface_lines surface_rc
    surface_lines=$(migrator_target_surface_for_version \
        "$MIGRATOR_FROM_VERSION" 2>/dev/null) || surface_rc=$?
    if [[ "${surface_lines:-}" == "unknown" ]] \
       || [[ -z "${surface_lines:-}" ]]; then
        warn "migrator_target_surface_for_version $MIGRATOR_FROM_VERSION returned no surface (rc=${surface_rc:-0}); fingerprint will rely on the manifest alone"
        surface_lines=""
    fi

    # Files set + directories set, gathered into temp listings so the
    # final hash is over a single sorted union (composition over
    # special-cases — V3 §design 4).
    local files_listing dirs_listing
    files_listing=$(mktemp)
    dirs_listing=$(mktemp)

    local entry
    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        if [[ -d "$target/$entry" ]]; then
            printf '%s\n' "$entry" >> "$dirs_listing"
        else
            # Treat as a regular file even when it does not yet exist on
            # disk — the listing is later filtered on `[[ -f ]]` so a
            # missing file is silently skipped (deterministic with the
            # pre-fix behavior).
            printf '%s\n' "$entry" >> "$files_listing"
        fi
    done <<< "$surface_lines"

    # ── (2) Manifest transform-class rows ──────────────────────────────
    # Manifest format (one TSV row): pack-relpath\tproject-relpath\tclass\taction
    # We want column 2 (project-relpath) where column 4 == `transform`.
    # Comment lines (`#`-prefixed after optional leading whitespace) and
    # blank rows are ignored — same lenience as the framework's
    # `_manifest_parse`.
    if declare -F migrator_manifest >/dev/null 2>&1; then
        migrator_manifest 2>/dev/null \
            | awk -F'\t' '
                /^[[:space:]]*$/ { next }
                /^[[:space:]]*#/ { next }
                NF >= 4 && $4 == "transform" { print $2 }
            ' >> "$files_listing"
    fi

    # ── Union files + sweep dirs into a single sorted listing ──────────
    # Files: dedupe with sort -u so trinity / .codex/config.toml entries
    # that appear in both (1) and (2) are hashed once. Skip rows whose
    # target path doesn't exist (a manifest row may name a file the
    # client doesn't have — that's not drift).
    local rel f abs sha
    if [[ -s "$files_listing" ]]; then
        while IFS= read -r rel; do
            [[ -z "$rel" ]] && continue
            abs="$target/$rel"
            if [[ -f "$abs" ]]; then
                sha=$(_v10_v11_dryrun_sha256_cmd < "$abs" | awk '{print $1}')
                printf '%s\t%s\n' "$rel" "$sha" >> "$listing"
            fi
        done < <(sort -u "$files_listing")
    fi

    # Directories: dedupe similarly, then `find -type f` per dir. The
    # per-dir output is sorted so the final pre-hash sort is stable.
    if [[ -s "$dirs_listing" ]]; then
        local sweep
        while IFS= read -r sweep; do
            [[ -z "$sweep" ]] && continue
            [[ -d "$target/$sweep" ]] || continue
            # `find … -type f` is BSD/GNU portable.
            while IFS= read -r f; do
                [[ -z "$f" ]] && continue
                sha=$(_v10_v11_dryrun_sha256_cmd < "$f" | awk '{print $1}')
                rel="${f#"$target/"}"
                printf '%s\t%s\n' "$rel" "$sha" >> "$listing"
            done < <(find "$target/$sweep" -type f -print 2>/dev/null | sort)
        done < <(sort -u "$dirs_listing")
    fi

    rm -f "$files_listing" "$dirs_listing"

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
    #
    # F6 (BD-095 retro fix): capture stderr and surface it on failure
    # rather than `>/dev/null 2>&1 || true` swallowing the renderer's
    # diagnostic. Gate 1 will still emit `[FAIL] report.md not rendered`
    # downstream, but operators now see WHY the renderer failed.
    if [[ -f "$state_dir/dispositions.tsv" ]] \
       && declare -F customization_report >/dev/null 2>&1; then
        local _render_err
        _render_err="$state_dir/customization_report.stderr"
        if ! customization_report \
                "$state_dir/dispositions.tsv" \
                "$state_dir/report.md" \
                "${MIGRATOR_FROM_VERSION} → ${MIGRATOR_TO_VERSION} migration customization report (--dry-run preview)" \
                2>"$_render_err"; then
            warn "customization_report failed: $(head -5 "$_render_err" 2>/dev/null)"
            warn "see $_render_err for full output"
            # Leave the stderr file in place — Gate 1 FAIL will reference it.
        else
            rm -f "$_render_err"
        fi
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

    # BD-101 Gate 1 — pre-migration dry-run summary (read-only).
    # Surface the gate result inline with the dry-run report so the user
    # reviewing the report sees PASS/FAIL before deciding to --apply.
    # On Gate 1 failure, return EXIT_GATE_FAILED so the caller (the
    # adapter's bare-invocation auto-flow OR the explicit --dry-run
    # exit) propagates a non-zero rc.
    local gate1_rc=0
    if declare -F migrate_v10_to_v11_gate1_run >/dev/null 2>&1; then
        migrate_v10_to_v11_gate1_run "$state_dir" || gate1_rc=$?
    fi

    say ""
    say "Review the report at $state_dir/report.md, then run --apply"
    say "to write the changes. The fingerprint guards against working-tree"
    say "drift between dry-run review and apply."

    if (( gate1_rc != 0 )); then
        return "$gate1_rc"
    fi
    return 0
}
