# scripts/lib/migrator-stages.sh — per-stage implementations for the BD-119
# N→N+1 migrator framework.
#
# Sourced by `scripts/lib/migrator-core.sh` only. Adapters do NOT source
# this file directly — they go through the public API in migrator-core.sh.
# Every function here is an internal stage runner prefixed with `_stage_`
# (an underscore prefix is the framework's convention for "not part of
# the public surface").
#
# Stage order (architecture §6, ARCHITECTURE-BD-119.md):
#   _stage_preflight        — I1, I4, I8 (preflight + idempotency)
#   _stage_backup           — I2 (full-tree tar backup)
#   _stage_libs             — source three-way + customization-preserve
#   _stage_dispatch         — manifest-driven three-way per-file dispatch
#   _stage_relocations      — git-mv-with-fallback for `relocate-from`
#   _stage_artifact_installs— additive-only writes for `add` entries
#   _stage_report           — render report.md + post-report hook
#
# Bodies filled in C-4 (PLAN T-8 + T-10). The dispatch engine bodies live
# in migrator-manifest.sh and are reached via `_stage_dispatch` here.
#
# Banner text + log lines mirror the v10→v11 monolith (lines 63–404 of
# `scripts/migrate-v10-to-v11.sh` at d7b3f07) so the C-5 / C-6 behavior-
# preservation harness diffs come up clean. Where the monolith hard-codes
# "v10"/"v11" / "v10-customized", the framework substitutes
# `MIGRATOR_FROM_VERSION` / `MIGRATOR_TO_VERSION` /
# `MIGRATOR_OWN_SIDECAR_SUFFIX` so any future adapter inherits the same
# wording without copy-paste drift (architecture M5).
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Internal helpers ──────────────────────────────────────────────────────
#
# `_migrator_dryrun_log <verb> <message>` emits the "[dry-run] would …"
# line that PLAN POQ-2 promises. Stages call it instead of mutating when
# `_MIGRATOR_DRY_RUN=1`. Read-only checks (preflight, baseline-tag exists,
# etc.) still run; only writes short-circuit. Centralized so future stages
# stay consistent.
_migrator_dryrun_log() {
    local verb="$1" msg="$2"
    info "[dry-run] would $verb $msg"
}

# Returns 0 when dry-run mode is active. Stage write-paths gate on this.
_migrator_is_dryrun() {
    [[ "${_MIGRATOR_DRY_RUN:-0}" == "1" ]]
}

# ── S0 — Preflight (I1, I4, I8) ───────────────────────────────────────────
#
# Verifies the target is a clean git repo, the pack-side libraries exist,
# the baseline tag resolves, the target's installed pack version matches
# `MIGRATOR_FROM_VERSION`, and no prior-version `--update` sidecars
# remain. Architecture §6 invariants I1, I4, I8 are enforced here.
#
# Idempotency (I8): if a prior successful migration left
# `<state-dir>/dispositions.tsv` behind, exit `EXIT_ALREADY_MIGRATED` (16)
# unless `--resume` is set. The current C-4 scope errors out on `--resume`
# in the arg parser (BD-095 surface), so re-running an already-migrated
# tree always tells the user to recover from the backup first. Read-only.

_stage_preflight() {
    say "── S0 — pre-flight ──"

    # Validate $PACK and pack-side libraries.
    [[ -n "${PACK:-}" ]] \
        || die "PACK environment variable not set" "$EXIT_PACK_INVALID"
    [[ -d "$PACK/project-template" ]] \
        || die "PACK ($PACK) missing project-template/" "$EXIT_PACK_INVALID"
    [[ -f "$PACK/scripts/lib/three-way.sh" ]] \
        || die "PACK missing three-way.sh" "$EXIT_PACK_INVALID"
    [[ -f "$PACK/scripts/lib/customization-preserve.sh" ]] \
        || die "PACK missing customization-preserve library" \
               "$EXIT_LIB_MISSING"
    [[ -f "$PACK/scripts/lib/customization-report.sh" ]] \
        || die "PACK missing customization-report library" \
               "$EXIT_LIB_MISSING"

    # Target must be a git repo with a clean working tree.
    git -C "$_MIGRATOR_TARGET" rev-parse --git-dir >/dev/null 2>&1 \
        || die "target is not a git repo: $_MIGRATOR_TARGET" "$EXIT_NOT_GIT"

    if [[ -n "$(git -C "$_MIGRATOR_TARGET" status --porcelain)" ]]; then
        die "target working tree is dirty; commit or stash first" "$EXIT_DIRTY"
    fi

    # Sanity: target must look like the declared FROM version. The
    # monolith checked CLAUDE.md + .claude/ directly; we keep that as a
    # generic ai-config-marker check (any pack-configured project has
    # both). Version-detection fingerprinting is downstream of this and
    # is run via `migrator_detect_target_version` for the "wrong major
    # version" guard. Architecture §5.4 + monolith lines 82–85.
    if [[ ! -f "$_MIGRATOR_TARGET/CLAUDE.md" \
       || ! -d "$_MIGRATOR_TARGET/.claude" ]]; then
        die "target does not appear to be a pack-configured project (CLAUDE.md or .claude/ missing); $0 is for ${MIGRATOR_FROM_VERSION} → ${MIGRATOR_TO_VERSION} migration only" \
            "$EXIT_NOT_BASELINE"
    fi

    # Baseline tag must exist in pack repo.
    if ! git -C "$PACK" rev-parse "$MIGRATOR_BASELINE_TAG" >/dev/null 2>&1; then
        die "${MIGRATOR_FROM_VERSION} baseline tag '$MIGRATOR_BASELINE_TAG' not present in pack repo at $PACK" \
            "$EXIT_BASELINE_MISSING"
    fi
    info "${MIGRATOR_FROM_VERSION} baseline tag resolved: $MIGRATOR_BASELINE_TAG"

    # Stale-sidecar refusal (architecture §6 I4 / monolith lines 94–108).
    # Iterate the adapter-declared prior-suffix list (e.g. ("pre-update")
    # for v10→v11). Each suffix is expanded into a `*.<suffix>` find pattern.
    local suffix stale_sidecars
    if (( ${#MIGRATOR_PRIOR_SIDECAR_SUFFIXES[@]} > 0 )); then
        for suffix in "${MIGRATOR_PRIOR_SIDECAR_SUFFIXES[@]}"; do
            [[ -z "$suffix" ]] && continue
            stale_sidecars=$(find "$_MIGRATOR_TARGET" -type f \
                -name "*.${suffix}" \
                -not -path "*/.git/*" \
                -not -path "*/.pack-update/*" \
                -not -path "*${_MIGRATOR_BACKUP_DIR##*/}/*" \
                2>/dev/null | head -20)
            if [[ -n "$stale_sidecars" ]]; then
                say "refusing to proceed: prior \`--update\` sidecars present:"
                printf '  %s\n' $stale_sidecars >&2
                die "reconcile or remove the .${suffix} sidecars above before running ${MIGRATOR_FROM_VERSION}→${MIGRATOR_TO_VERSION} migration" \
                    "$EXIT_DIRTY"
            fi
        done
    fi

    # Idempotency (I8): if a prior successful migration left a
    # dispositions.tsv behind, exit EXIT_ALREADY_MIGRATED with a clearer
    # signal than the monolith's "backup directory already exists" error.
    if [[ -f "$_MIGRATOR_STATE_DIR/dispositions.tsv" ]]; then
        say "target already migrated: $_MIGRATOR_STATE_DIR/dispositions.tsv exists"
        die "to re-run the migration, restore from the backup at $_MIGRATOR_BACKUP_DIR first; --resume is the forward-only continuation after a paused dispatch (see --help)" \
            "$EXIT_ALREADY_MIGRATED"
    fi
}

# ── S1 — Backup (I2) ──────────────────────────────────────────────────────
#
# Full working-tree backup before any mutation. Excludes only `.git/`,
# the framework's own state + backup dirs, and the legacy `.pack-update/`
# dir from `init-project.sh --update`. The monolith's exclude list
# (lines 122–135) is reproduced verbatim with version-derived dir names
# so a v11→v12 adapter inherits the same exclude shape (architecture M3).

_stage_backup() {
    say "── S1 — backup ──"

    if [[ -d "$_MIGRATOR_BACKUP_DIR" ]]; then
        fail_stage S1 "backup directory already exists: $_MIGRATOR_BACKUP_DIR — rename it (mv $_MIGRATOR_BACKUP_DIR $_MIGRATOR_BACKUP_DIR.prev) or remove it before re-running"
    fi

    if _migrator_is_dryrun; then
        _migrator_dryrun_log "create backup directory" "$_MIGRATOR_BACKUP_DIR"
        _migrator_dryrun_log "tar full working tree to" "$_MIGRATOR_BACKUP_DIR (excluding .git/ + state dirs)"
        return 0
    fi

    mkdir -p "$_MIGRATOR_BACKUP_DIR"

    # Build exclude list with version-derived state-dir + backup-dir
    # names. `tar --exclude-from=` is portable across BSD and GNU tar
    # (architecture R3). Use only the *basename* of the state/backup dirs
    # because tar reads exclude entries as paths relative to the archive
    # root (`-C "$_MIGRATOR_TARGET"`). Including absolute paths or
    # leading-`./` would break BSD-tar matching.
    local exclude_list state_basename backup_basename
    state_basename="${_MIGRATOR_STATE_DIR##*/}"
    backup_basename="${_MIGRATOR_BACKUP_DIR##*/}"
    exclude_list=$(mktemp)
    cat > "$exclude_list" <<EOF
.git
$state_basename
$backup_basename
.pack-update
EOF
    tar -cf - -C "$_MIGRATOR_TARGET" --exclude-from="$exclude_list" . \
        | tar -x -C "$_MIGRATOR_BACKUP_DIR"
    rm -f "$exclude_list"

    [[ -f "$_MIGRATOR_BACKUP_DIR/CLAUDE.md" ]] \
        || fail_stage S1 "backup verification failed (CLAUDE.md missing in backup)"

    info "backup written: $_MIGRATOR_BACKUP_DIR (full working tree, excludes .git/ + state dirs)"
}

# ── S2 — Library setup ────────────────────────────────────────────────────
#
# Sources three-way + customization-preserve + customization-report and
# initializes the BD-088 customization-preserve state dir. The state dir
# is derived from `MIGRATOR_FROM_VERSION` / `MIGRATOR_TO_VERSION` so
# every adapter inherits the same naming. Sidecar suffix is
# adapter-declared (`MIGRATOR_OWN_SIDECAR_SUFFIX`).

_stage_libs() {
    say "── S2 — initialize customization-preserve state ──"

    export _CP_PACK_ROOT="$PACK"
    # shellcheck source=three-way.sh disable=SC1091
    . "$PACK/scripts/lib/three-way.sh"
    # shellcheck source=customization-preserve.sh disable=SC1091
    . "$PACK/scripts/lib/customization-preserve.sh"
    # shellcheck source=customization-report.sh disable=SC1091
    . "$PACK/scripts/lib/customization-report.sh"

    if _migrator_is_dryrun; then
        _migrator_dryrun_log "reset state directory" "$_MIGRATOR_STATE_DIR"
        # In dry-run we still want the state dir for the dispositions.tsv
        # because the engine records "would write" findings. The mkdir is
        # therefore not gated on dry-run.
    fi

    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init \
        "$_MIGRATOR_STATE_DIR" \
        ".${MIGRATOR_OWN_SIDECAR_SUFFIX}"
    info "state dir: $_MIGRATOR_STATE_DIR"
}

# ── S3 — Manifest dispatch ────────────────────────────────────────────────
#
# Calls into the manifest engine in `migrator-manifest.sh`. The engine
# reads the adapter's `migrator_manifest` + `migrator_directory_sweeps`
# stdout, validates trinity-parity (I5) before any mutation, and
# iterates entries through `customization_preserve` for the always-
# dispatch contract (architecture §6 M4 / I3).

_stage_dispatch() {
    say "── S3 — dispatch ${MIGRATOR_FROM_VERSION} → ${MIGRATOR_TO_VERSION} file changes ──"

    # Parse adapter-declared manifest into the parallel-array storage
    # owned by `migrator-manifest.sh`. Errors before any mutation if the
    # manifest is malformed or trinity-parity is violated (I5).
    _manifest_parse
    _manifest_validate_trinity

    # Iterate parsed manifest. Always dispatches every entry through
    # customization_preserve for `transform`, additive write for `add`,
    # no-op (with disposition record) for `remove`, git-mv-with-fallback
    # for `relocate-from`. Records a disposition in the BD-088 TSV for
    # each so the BD-088 truthful-report contract holds.
    _manifest_iterate

    # Directory sweeps (architecture §3, monolith S3 lines 226–253). The
    # adapter declares `<pack-dir> <class>` rows; the engine iterates
    # every regular file under each pack-dir and dispatches via
    # customization_preserve, *unless* the file already appeared in the
    # manifest above (manifest-row precedence per architecture §4.2).
    _manifest_sweep_directories
}

# ── S4 — Relocations (BD-042 legacy-doc relocation in v10→v11) ────────────
#
# Reads adapter-declared `migrator_relocations` (`<old-path> <new-path>`
# rows) and performs git-mv with a `mv` fallback for untracked files,
# plus the "both root and target present → sidecar the root copy" branch
# from monolith lines 269–273. Most version transitions emit zero rows;
# v10→v11 emits five (METHODOLOGY.md / PROMPT-TEMPLATES.md / etc.).

_stage_relocations() {
    local rows row old new moved=0
    rows=$(migrator_relocations 2>/dev/null || true)

    # Silent when the adapter declares no relocations — adapters that
    # handle their own S4 banner via migrator_post_dispatch_hook (e.g. the
    # v10→v11 adapter, which uses the BD-042-specific wording) rely on
    # this stage being a no-op when rows are empty so the framework does
    # not double-print a generic banner. Adapters that DO declare rows
    # get the generic banner + per-row info lines below.
    if [[ -z "$rows" ]]; then
        return 0
    fi

    say "── S4 — relocations ──"

    while IFS= read -r row; do
        [[ -z "$row" ]] && continue
        # Comment lines (start with `#`) — allow heredoc-style annotations.
        [[ "${row# }" == \#* ]] && continue
        # Two whitespace-separated fields: <old-path> <new-path>.
        old=$(printf '%s' "$row" | awk '{print $1}')
        new=$(printf '%s' "$row" | awk '{print $2}')
        if [[ -z "$old" || -z "$new" ]]; then
            warn "skipping malformed relocation row: $row"
            continue
        fi

        if [[ ! -f "$_MIGRATOR_TARGET/$old" ]]; then
            # Old path does not exist in target — nothing to relocate.
            continue
        fi

        if _migrator_is_dryrun; then
            _migrator_dryrun_log "relocate" "$old → $new"
            moved=$((moved + 1))
            continue
        fi

        # Ensure destination directory exists.
        mkdir -p "$_MIGRATOR_TARGET/$(dirname "$new")"

        if [[ -f "$_MIGRATOR_TARGET/$new" ]]; then
            # Both source and destination exist — preserve the canonical
            # destination, sidecar the root copy with a clear suffix.
            mv "$_MIGRATOR_TARGET/$old" "$_MIGRATOR_TARGET/$old.relocated-from-root"
            info "relocated: $old → $old.relocated-from-root ($new already present)"
            moved=$((moved + 1))
            continue
        fi

        # git-mv first; fall back to plain mv if the source is untracked.
        # Any other git-mv failure is a defect (fail_stage so the user
        # can investigate before more relocations run).
        local mv_stderr untracked=0
        mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "$old" "$new" 2>&1) || {
            if [[ "$mv_stderr" == *"not under version control"* \
               || "$mv_stderr" == *"did not match"* ]]; then
                mv "$_MIGRATOR_TARGET/$old" "$_MIGRATOR_TARGET/$new"
                untracked=1
            else
                fail_stage S4 "git mv $old → $new failed: $mv_stderr"
            fi
        }
        [[ -f "$_MIGRATOR_TARGET/$new" ]] \
            || fail_stage S4 "post-relocation verification failed: $new missing"
        if (( untracked == 1 )); then
            info "relocated (untracked): $old → $new"
        else
            info "relocated: $old → $new"
        fi
        moved=$((moved + 1))
    done <<< "$rows"

    info "relocations: $moved file(s) moved"
}

# ── S5 — Additive artifact installs ───────────────────────────────────────
#
# Reads adapter-declared `migrator_artifact_installs` TSV
# (`<pack-relpath>\t<project-relpath>\t<class>\tadd` rows) and writes
# each only if the target does not already have the file. Records a
# disposition via the BD-088 contract (`pack-update-applied` for newly
# written, `project-only-file` for already-present, `removed-everywhere`
# for absent-on-pack-side). Directories are created on demand.
#
# Implementation note: this stage handles `add`-action rows from the
# adapter's `migrator_artifact_installs` hook. The dispatch engine in
# `_manifest_iterate` *also* understands `add`, but the architecture
# splits them so the dispatch engine deals only with the v10→v11-style
# customization manifest while artifact installs stay version-additive.

_stage_artifact_installs() {
    local rows row pack_rel proj_rel cls action installed=0
    rows=$(migrator_artifact_installs 2>/dev/null || true)

    # Silent when the adapter declares no artifact installs — same
    # rationale as `_stage_relocations`: adapters wanting a custom S5
    # banner (or that ship artifacts via migrator_post_dispatch_hook for
    # behavior-preservation reasons, e.g. v10→v11) rely on this stage
    # being a no-op when rows are empty.
    if [[ -z "$rows" ]]; then
        return 0
    fi

    say "── S5 — install ${MIGRATOR_TO_VERSION} client artifacts ──"

    while IFS=$'\t' read -r pack_rel proj_rel cls action; do
        # Skip blank or comment rows.
        [[ -z "${pack_rel:-}" ]] && continue
        case "$pack_rel" in '#'*) continue ;; esac
        if [[ -z "${proj_rel:-}" || -z "${cls:-}" || -z "${action:-}" ]]; then
            warn "skipping malformed artifact-install row: $pack_rel | $proj_rel | $cls | $action"
            continue
        fi
        if [[ "$action" != "add" ]]; then
            warn "artifact-install row uses non-'add' action ($action) — skipping; use migrator_manifest for transform/remove/relocate"
            continue
        fi

        local src="$PACK/$pack_rel"
        local dst="$_MIGRATOR_TARGET/$proj_rel"

        if [[ ! -f "$src" ]]; then
            _cp_record "removed-everywhere" "$cls" "$proj_rel" "none" "-" "-" \
                "additive artifact absent at pack baseline"
            continue
        fi

        if [[ -f "$dst" ]]; then
            # Target already has the file — never clobber. Record so the
            # BD-088 truthful-report contract holds.
            _cp_record "project-only-file" "$cls" "$proj_rel" "preserved" "-" "-" \
                "additive artifact already present in target"
            continue
        fi

        if _migrator_is_dryrun; then
            _migrator_dryrun_log "install artifact" "$proj_rel"
            _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
                "[dry-run] would copy $pack_rel"
            installed=$((installed + 1))
            continue
        fi

        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        # Preserve executable bit for shipped scripts (the monolith does
        # this explicitly for `scripts/pack-help.sh` at lines 363–364).
        if [[ -x "$src" ]]; then
            chmod +x "$dst"
        fi
        _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
            "additive install"
        installed=$((installed + 1))
    done <<< "$rows"

    info "artifact installs: $installed file(s) added"
}

# ── S6 — Render report + post-report hook ─────────────────────────────────
#
# Renders `<state-dir>/report.md` via `customization_report`, prints the
# templated revert-instructions string (architecture M5: templated
# against MIGRATOR_FROM_VERSION / MIGRATOR_TO_VERSION so wording does not
# drift across adapters), records the destination pack version into
# `tracker.toml` if the file already exists in the target (POQ-3), and
# calls the adapter-supplied `migrator_post_report_hook`.

_stage_report() {
    say "── S6 — render truthful migration report ──"

    local report="$_MIGRATOR_STATE_DIR/report.md"
    local title="${MIGRATOR_FROM_VERSION} → ${MIGRATOR_TO_VERSION} migration customization report"

    if _migrator_is_dryrun; then
        _migrator_dryrun_log "render report" "$report"
    else
        customization_report \
            "$_MIGRATOR_STATE_DIR/dispositions.tsv" \
            "$report" \
            "$title"
    fi

    local count
    count=$(customization_findings_count 2>/dev/null || printf '0')

    say ""
    say "Migration complete. $count files processed by the dispatch engine."
    say "Backup: $_MIGRATOR_BACKUP_DIR (faithful working-tree snapshot)"
    say "Report: $report"
    say ""
    say "To revert this migration:"
    say "  1. From a clean shell:"
    say "       cd $_MIGRATOR_TARGET"
    say "       rm -rf ${_MIGRATOR_STATE_DIR##*/}"
    say "       (rsync -a --delete --exclude=.git/ \\"
    say "          --exclude=${_MIGRATOR_BACKUP_DIR##*/}/ \\"
    say "          ${_MIGRATOR_BACKUP_DIR##*/}/ ./)"
    say "  2. Inspect with \`git diff\`."
    say "  3. When satisfied, remove ${_MIGRATOR_BACKUP_DIR##*/}/."
    if [[ -f "$_MIGRATOR_STATE_DIR/dispositions.tsv" ]] \
       && grep -q "needs-reconciliation" "$_MIGRATOR_STATE_DIR/dispositions.tsv" 2>/dev/null; then
        say ""
        say "NOTE: one or more files need manual reconciliation. Review the"
        say "report's \"Files needing manual reconciliation\" section and"
        say "inspect the named .${MIGRATOR_OWN_SIDECAR_SUFFIX} sidecars."
    fi

    # POQ-3: stamp tracker.toml `[pack].version = "<TO_VERSION>"` if the
    # file already exists in the target. Never creates the file. Idempotent
    # (replaces the line in-place when present, appends a `[pack]` section
    # otherwise). Wrapped in dry-run gate.
    _stage_report_stamp_tracker_version

    return 0
}

# Internal: stamp the destination pack version into tracker.toml when
# the file already exists. Architecture §7 last paragraph + PLAN POQ-3.
# Bash-3.2 + BSD-sed compatible: uses awk for the in-place update so we
# do not have to deal with `sed -i ''` vs `sed -i` portability.
_stage_report_stamp_tracker_version() {
    local tracker="$_MIGRATOR_TARGET/tracker.toml"
    [[ -f "$tracker" ]] || return 0

    local version="$MIGRATOR_TO_VERSION"

    if _migrator_is_dryrun; then
        _migrator_dryrun_log "stamp" "$tracker [pack] version = \"$version\""
        return 0
    fi

    if grep -q '^\[pack\]' "$tracker" 2>/dev/null; then
        # `[pack]` section exists — replace or insert `version = "..."`
        # within it. Awk is the safest cross-platform tool here.
        local tmp
        tmp=$(mktemp)
        awk -v ver="$version" '
            BEGIN { in_pack = 0; wrote_version = 0 }
            /^\[pack\]/ {
                print
                in_pack = 1
                next
            }
            /^\[/ && in_pack && !wrote_version {
                print "version = \"" ver "\""
                wrote_version = 1
                in_pack = 0
                print
                next
            }
            in_pack && /^[[:space:]]*version[[:space:]]*=/ {
                print "version = \"" ver "\""
                wrote_version = 1
                next
            }
            { print }
            END {
                if (in_pack && !wrote_version) {
                    print "version = \"" ver "\""
                }
            }
        ' "$tracker" > "$tmp"
        mv "$tmp" "$tracker"
    else
        # Append a `[pack]` section with the version line.
        printf '\n[pack]\nversion = "%s"\n' "$version" >> "$tracker"
    fi
}
