# scripts/lib/migrator-manifest.sh — declarative manifest parser + dispatch
# engine for the BD-119 N→N+1 migrator framework.
#
# Sourced by `scripts/lib/migrator-core.sh` only. Adapters do NOT source
# this file directly — the engine is reached via the public API in
# migrator-core.sh. Every function here is internal and prefixed with
# `_manifest_` (framework convention for non-public surface).
#
# Responsibilities (architecture §3, §4.2; ARCHITECTURE-BD-119.md):
#   - Parse the TSV manifest the adapter emits via `migrator_manifest()`:
#       <pack-relpath>\t<project-relpath>\t<class>\t<action>
#     Actions: transform | add | remove | relocate-from <old-path>
#   - Validate trinity-parity (I5): if any of CLAUDE/AGENTS/GEMINI is
#     present, all three must be with matching class + action.
#   - Iterate entries and call `customization_preserve` per `transform`
#     row, additive write per `add`, no-op-with-report per `remove`,
#     git-mv-with-fallback per `relocate-from`.
#   - Drive the directory-sweep hook (`migrator_directory_sweeps`).
#
# Bodies filled in C-4 (PLAN T-9). bash 3.2 portable — no associative
# arrays, no `&>`, no `${var,,}`. Parallel indexed arrays mirror the
# parser's logical 4-tuple per row.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Parsed-manifest storage (parallel indexed arrays) ─────────────────────
#
# `_manifest_parse` populates these. Other `_manifest_*` functions read
# them. They are reset on every parse so a re-run inside the same shell
# (e.g. unit tests calling _manifest_parse twice) does not accumulate.

_MIGRATOR_MANIFEST_PACK_RELS=()
_MIGRATOR_MANIFEST_PROJ_RELS=()
_MIGRATOR_MANIFEST_CLASSES=()
_MIGRATOR_MANIFEST_ACTIONS=()
# `_MIGRATOR_MANIFEST_ACTION_ARGS[i]` is the post-verb argument. Currently
# only `relocate-from <old-path>` uses it; other verbs leave the entry as
# the empty string. Always indexed in parallel with the four arrays above.
_MIGRATOR_MANIFEST_ACTION_ARGS=()
_MIGRATOR_MANIFEST_COUNT=0

_manifest_reset_storage() {
    _MIGRATOR_MANIFEST_PACK_RELS=()
    _MIGRATOR_MANIFEST_PROJ_RELS=()
    _MIGRATOR_MANIFEST_CLASSES=()
    _MIGRATOR_MANIFEST_ACTIONS=()
    _MIGRATOR_MANIFEST_ACTION_ARGS=()
    _MIGRATOR_MANIFEST_COUNT=0
}

# ── Manifest parser ───────────────────────────────────────────────────────
#
# Reads `migrator_manifest` stdout into the parallel-array storage above.
# Each non-blank, non-comment row must have exactly four tab-separated
# fields: `<pack-relpath>\t<project-relpath>\t<class>\t<action>`. The
# `action` field may itself be space-separated when it carries an
# argument (`relocate-from <old-path>`); the parser splits on the first
# space and stores the remainder in `_MIGRATOR_MANIFEST_ACTION_ARGS`.
#
# Blank lines and `#`-commented lines are skipped. Malformed rows abort
# with EXIT_INTERNAL — adapters cannot ship a manifest the engine
# silently misreads.

_manifest_parse() {
    _manifest_reset_storage

    if ! declare -F migrator_manifest >/dev/null 2>&1; then
        die "_manifest_parse: adapter did not declare migrator_manifest()" \
            "$EXIT_INTERNAL"
    fi

    local raw
    raw=$(migrator_manifest 2>/dev/null || true)

    # Empty manifest is allowed — some transitions may declare zero
    # transform rows and rely entirely on directory sweeps + artifact
    # installs. Don't error here; the iterator will emit "no entries".
    if [[ -z "$raw" ]]; then
        return 0
    fi

    local row pack_rel proj_rel cls action_field action action_arg
    local lineno=0
    while IFS= read -r row; do
        lineno=$((lineno + 1))
        # Skip blank lines.
        [[ -z "$row" ]] && continue
        # Skip comment lines (leading `#`, optionally indented).
        case "${row#"${row%%[![:space:]]*}"}" in
            '#'*) continue ;;
        esac

        # Tab-split into four logical fields. bash 3.2 IFS read on a
        # captured line: we re-read via process substitution-safe form
        # by splitting manually with `awk` — but plain IFS split works
        # provided we copy the row through `IFS=$'\t' read`.
        IFS=$'\t' read -r pack_rel proj_rel cls action_field <<< "$row"

        if [[ -z "${pack_rel:-}" || -z "${proj_rel:-}" \
           || -z "${cls:-}" || -z "${action_field:-}" ]]; then
            die "_manifest_parse: malformed manifest row $lineno (need 4 tab-separated fields): $row" \
                "$EXIT_INTERNAL"
        fi

        # Split the action field on the first space — the verb is
        # always a single token; everything after is its argument
        # (currently only `relocate-from <old>`).
        action="${action_field%% *}"
        if [[ "$action" == "$action_field" ]]; then
            action_arg=""
        else
            action_arg="${action_field#* }"
        fi

        case "$action" in
            transform|add|remove|relocate-from) ;;
            *)
                die "_manifest_parse: unknown manifest action '$action' on row $lineno (expected transform|add|remove|relocate-from)" \
                    "$EXIT_INTERNAL"
                ;;
        esac

        if [[ "$action" == "relocate-from" && -z "$action_arg" ]]; then
            die "_manifest_parse: relocate-from on row $lineno missing <old-path> argument: $row" \
                "$EXIT_INTERNAL"
        fi

        _MIGRATOR_MANIFEST_PACK_RELS+=("$pack_rel")
        _MIGRATOR_MANIFEST_PROJ_RELS+=("$proj_rel")
        _MIGRATOR_MANIFEST_CLASSES+=("$cls")
        _MIGRATOR_MANIFEST_ACTIONS+=("$action")
        _MIGRATOR_MANIFEST_ACTION_ARGS+=("$action_arg")
        _MIGRATOR_MANIFEST_COUNT=$((_MIGRATOR_MANIFEST_COUNT + 1))
    done <<< "$raw"
}

# ── Trinity-parity validator (I5) ─────────────────────────────────────────
#
# Architecture §6 I5: when any of CLAUDE.md / AGENTS.md / GEMINI.md
# appears as a manifest row (pack-relpath = `project-template/CLAUDE.md`
# *or* the bare project-relpath = `CLAUDE.md`), the other two must also
# appear with the same class + action. Errors before any mutation if
# violated. Implementation runs against the parsed-manifest storage so
# both the heredoc-emitted manifests and any future loaded-from-file
# manifests share the same validator.

_manifest_validate_trinity() {
    local trinity=("CLAUDE.md" "AGENTS.md" "GEMINI.md")
    local i name
    local found_any=0
    # Slot indices keyed by trinity name (parallel to `trinity`).
    local idx_claude=-1 idx_agents=-1 idx_gemini=-1

    for (( i = 0; i < _MIGRATOR_MANIFEST_COUNT; i++ )); do
        name="${_MIGRATOR_MANIFEST_PROJ_RELS[$i]}"
        case "$name" in
            CLAUDE.md) idx_claude=$i; found_any=1 ;;
            AGENTS.md) idx_agents=$i; found_any=1 ;;
            GEMINI.md) idx_gemini=$i; found_any=1 ;;
        esac
    done

    # If none of the three appear, the rule is vacuously satisfied.
    if (( found_any == 0 )); then
        return 0
    fi

    # All three must be present.
    local missing=()
    (( idx_claude < 0 )) && missing+=("CLAUDE.md")
    (( idx_agents < 0 )) && missing+=("AGENTS.md")
    (( idx_gemini < 0 )) && missing+=("GEMINI.md")
    if (( ${#missing[@]} > 0 )); then
        die "trinity parity violation (architecture §6 I5): manifest declares some of CLAUDE.md/AGENTS.md/GEMINI.md but is missing: ${missing[*]} — when one trinity file ships in a manifest, all three must" \
            "$EXIT_INTERNAL"
    fi

    # All three must share the same class and the same action.
    local cls_claude="${_MIGRATOR_MANIFEST_CLASSES[$idx_claude]}"
    local cls_agents="${_MIGRATOR_MANIFEST_CLASSES[$idx_agents]}"
    local cls_gemini="${_MIGRATOR_MANIFEST_CLASSES[$idx_gemini]}"
    local act_claude="${_MIGRATOR_MANIFEST_ACTIONS[$idx_claude]}"
    local act_agents="${_MIGRATOR_MANIFEST_ACTIONS[$idx_agents]}"
    local act_gemini="${_MIGRATOR_MANIFEST_ACTIONS[$idx_gemini]}"

    if [[ "$cls_claude" != "$cls_agents" || "$cls_claude" != "$cls_gemini" ]]; then
        die "trinity parity violation: CLAUDE.md class=$cls_claude / AGENTS.md class=$cls_agents / GEMINI.md class=$cls_gemini — all three must use the same class" \
            "$EXIT_INTERNAL"
    fi
    if [[ "$act_claude" != "$act_agents" || "$act_claude" != "$act_gemini" ]]; then
        die "trinity parity violation: CLAUDE.md action=$act_claude / AGENTS.md action=$act_agents / GEMINI.md action=$act_gemini — all three must use the same action" \
            "$EXIT_INTERNAL"
    fi
}

# ── Iterator / dispatch engine ────────────────────────────────────────────
#
# Walks the parsed manifest entries and dispatches each to the action
# handler. Architecture §6 M4 always-dispatch: every `transform` entry
# goes through `customization_preserve` — even when both sides absent —
# so the BD-088 truthful-report invariant holds.
#
# Action verb behavior:
#   transform        — three-way dispatch via customization_preserve
#                      (matches the monolith's S3 behavior verbatim).
#   add              — additive-only install: copy pack→target only if
#                      target is missing; record disposition either way.
#   remove           — file existed at baseline but no longer ships at
#                      target version. If target still has it, sidecar
#                      and remove; otherwise record removed-everywhere.
#   relocate-from    — git-mv-with-fallback from the action argument
#                      (`<old-path>`) to the row's project-relpath
#                      (`<new-path>`). Same fallback semantics as the
#                      monolith's S4 BD-042 relocation.

_manifest_iterate() {
    if (( _MIGRATOR_MANIFEST_COUNT == 0 )); then
        info "dispatch: 0 file(s) — manifest empty"
        return 0
    fi

    local i pack_rel proj_rel cls action action_arg
    local processed=0
    for (( i = 0; i < _MIGRATOR_MANIFEST_COUNT; i++ )); do
        pack_rel="${_MIGRATOR_MANIFEST_PACK_RELS[$i]}"
        proj_rel="${_MIGRATOR_MANIFEST_PROJ_RELS[$i]}"
        cls="${_MIGRATOR_MANIFEST_CLASSES[$i]}"
        action="${_MIGRATOR_MANIFEST_ACTIONS[$i]}"
        action_arg="${_MIGRATOR_MANIFEST_ACTION_ARGS[$i]}"

        case "$action" in
            transform)
                _manifest_dispatch_transform \
                    "$pack_rel" "$proj_rel" "$cls"
                ;;
            add)
                _manifest_dispatch_add \
                    "$pack_rel" "$proj_rel" "$cls"
                ;;
            remove)
                _manifest_dispatch_remove \
                    "$pack_rel" "$proj_rel" "$cls"
                ;;
            relocate-from)
                _manifest_dispatch_relocate \
                    "$pack_rel" "$proj_rel" "$cls" "$action_arg"
                ;;
        esac
        processed=$((processed + 1))
    done

    info "dispatch: $processed file(s) processed"
}

# ── Action handlers ──────────────────────────────────────────────────────
#
# Each handler:
#  - resolves the BASE blob (pack baseline tag) via migrator_baseline_to_tmp
#  - resolves OURS / THEIRS / DEST paths under TARGET / PACK
#  - calls customization_preserve to record a truthful disposition
#  - cleans up the BASE tmp file
#
# Architecture I3 (BD-088 contract) is upheld for `transform` and `add`
# rows by always invoking customization_preserve / _cp_record. `remove`
# and `relocate-from` cannot use customization_preserve directly because
# the action is structural, not text-merge — they call `_cp_record` to
# stamp a disposition and keep the report truthful.

_manifest_dispatch_transform() {
    local pack_rel="$1" proj_rel="$2" cls="$3"
    local theirs="$PACK/$pack_rel"
    local ours="$_MIGRATOR_TARGET/$proj_rel"
    local dest="$_MIGRATOR_TARGET/$proj_rel"
    local base
    base=$(mktemp)
    if migrator_baseline_to_tmp "$pack_rel" "$base"; then
        : # base populated
    else
        # Empty base file is what migrator_baseline_to_tmp leaves on
        # not-found; clear the path so customization_preserve sees
        # "absent" (empty string), matching the monolith's behavior.
        rm -f "$base"
        base=""
    fi
    [[ -f "$theirs" ]] || theirs=""
    [[ -f "$ours" ]]   || ours=""

    if _migrator_is_dryrun; then
        _migrator_dryrun_log "transform" "$proj_rel (class=$cls)"
        # Still record a finding so the dry-run report is truthful.
        _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
            "[dry-run] would dispatch via customization_preserve"
    else
        # Always dispatch — even when both sides absent (architecture M4).
        customization_preserve \
            "$base" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" >/dev/null
    fi

    # Best-effort cleanup; explicit `return 0` so an empty $base (baseline
    # absent) does not propagate a non-zero exit under set -e in the
    # caller's iterator loop.
    if [[ -n "$base" ]]; then
        rm -f "$base"
    fi
    return 0
}

_manifest_dispatch_add() {
    local pack_rel="$1" proj_rel="$2" cls="$3"
    local src="$PACK/$pack_rel"
    local dst="$_MIGRATOR_TARGET/$proj_rel"

    if [[ ! -f "$src" ]]; then
        _cp_record "removed-everywhere" "$cls" "$proj_rel" "none" "-" "-" \
            "additive entry absent at pack baseline"
        return 0
    fi

    if [[ -f "$dst" ]]; then
        _cp_record "project-only-file" "$cls" "$proj_rel" "preserved" "-" "-" \
            "additive entry already present in target"
        return 0
    fi

    if _migrator_is_dryrun; then
        _migrator_dryrun_log "add" "$proj_rel (class=$cls)"
        _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
            "[dry-run] would copy $pack_rel"
        return 0
    fi

    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    if [[ -x "$src" ]]; then
        chmod +x "$dst"
    fi
    _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
        "additive add"
}

_manifest_dispatch_remove() {
    local pack_rel="$1" proj_rel="$2" cls="$3"
    local target="$_MIGRATOR_TARGET/$proj_rel"
    # `pack_rel` is unused here but kept in the parameter list so the
    # five action handlers share a uniform shape.
    : "$pack_rel"

    if [[ ! -f "$target" ]]; then
        _cp_record "removed-everywhere" "$cls" "$proj_rel" "none" "-" "-" \
            "remove-action: file absent in target"
        return 0
    fi

    if _migrator_is_dryrun; then
        _migrator_dryrun_log "remove" "$proj_rel"
        _cp_record "removed-by-design" "$cls" "$proj_rel" "removed" "-" "-" \
            "[dry-run] would remove"
        return 0
    fi

    # Sidecar the file before removal so the user can recover any
    # customization (mirrors monolith's removed-by-pack-customized branch
    # in customization-preserve).
    local sidecar="${target}.${MIGRATOR_OWN_SIDECAR_SUFFIX}"
    cp "$target" "$sidecar"
    rm "$target"
    _cp_record "removed-by-design" "$cls" "$proj_rel" "removed" "$sidecar" "-" \
        "remove-action: file retired in ${MIGRATOR_TO_VERSION}; previous content sidecared"
}

_manifest_dispatch_relocate() {
    local pack_rel="$1" proj_rel="$2" cls="$3" old="$4"
    : "$pack_rel"
    local new="$proj_rel"

    if [[ ! -f "$_MIGRATOR_TARGET/$old" ]]; then
        _cp_record "removed-everywhere" "$cls" "$new" "none" "-" "-" \
            "relocate-from: source $old absent — nothing to relocate"
        return 0
    fi

    if _migrator_is_dryrun; then
        _migrator_dryrun_log "relocate" "$old → $new"
        _cp_record "pack-update-applied" "$cls" "$new" "copied" "-" "-" \
            "[dry-run] would relocate from $old"
        return 0
    fi

    mkdir -p "$_MIGRATOR_TARGET/$(dirname "$new")"

    if [[ -f "$_MIGRATOR_TARGET/$new" ]]; then
        # Both source and destination present — keep destination canonical.
        mv "$_MIGRATOR_TARGET/$old" \
           "$_MIGRATOR_TARGET/$old.relocated-from-root"
        _cp_record "project-only-file" "$cls" "$new" "preserved" \
            "$_MIGRATOR_TARGET/$old.relocated-from-root" "-" \
            "relocate-from: $new already present; sidecared $old"
        return 0
    fi

    local mv_stderr untracked=0
    mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "$old" "$new" 2>&1) || {
        if [[ "$mv_stderr" == *"not under version control"* \
           || "$mv_stderr" == *"did not match"* ]]; then
            mv "$_MIGRATOR_TARGET/$old" "$_MIGRATOR_TARGET/$new"
            untracked=1
        else
            die "_manifest_dispatch_relocate: git mv $old → $new failed: $mv_stderr" \
                "$EXIT_INTERNAL"
        fi
    }
    [[ -f "$_MIGRATOR_TARGET/$new" ]] \
        || die "_manifest_dispatch_relocate: post-relocation verification failed: $new missing" \
               "$EXIT_INTERNAL"
    if (( untracked == 1 )); then
        _cp_record "pack-update-applied" "$cls" "$new" "copied" "-" "-" \
            "relocate-from $old (untracked plain mv)"
    else
        _cp_record "pack-update-applied" "$cls" "$new" "copied" "-" "-" \
            "relocate-from $old (git mv)"
    fi
}

# ── Directory-sweep iterator ──────────────────────────────────────────────
#
# Reads `migrator_directory_sweeps` output (`<pack-dir> <class>` rows)
# and dispatches each contained file with the declared class. Manifest-
# row precedence over sweep results when paths collide — the manifest's
# `transform`-action proj-relpath set is consulted before each sweep
# dispatch so an adapter can override a sweep result for a specific file.

_manifest_sweep_directories() {
    if ! declare -F migrator_directory_sweeps >/dev/null 2>&1; then
        # Adapter declared no sweeps — that's fine; not all transitions
        # need them. (Required-hook validation in the core ensures the
        # function is at least defined; an empty heredoc returns no rows.)
        return 0
    fi

    local rows row pack_dir cls
    rows=$(migrator_directory_sweeps 2>/dev/null || true)
    [[ -z "$rows" ]] && return 0

    # Pre-build the manifest proj-relpath set into a single newline-joined
    # blob; for each candidate file we grep the blob to avoid re-scanning
    # the parallel arrays per-file. macOS bash 3.2 has no associative
    # arrays.
    local manifest_set
    manifest_set=$(printf '%s\n' "${_MIGRATOR_MANIFEST_PROJ_RELS[@]:-}")

    while IFS= read -r row; do
        [[ -z "$row" ]] && continue
        case "${row#"${row%%[![:space:]]*}"}" in
            '#'*) continue ;;
        esac
        # Two whitespace-separated fields: <pack-dir> <class>.
        pack_dir=$(printf '%s' "$row" | awk '{print $1}')
        cls=$(printf '%s' "$row" | awk '{print $2}')
        if [[ -z "$pack_dir" || -z "$cls" ]]; then
            warn "skipping malformed directory-sweep row: $row"
            continue
        fi
        _manifest_sweep_one_dir "$pack_dir" "$cls" "$manifest_set"
    done <<< "$rows"
}

# Internal: iterate every regular file under `$PACK/$pack_dir`, derive
# the parallel project-relative path, and dispatch via
# customization_preserve unless the file already appears in the parsed
# manifest's proj-relpath set.
_manifest_sweep_one_dir() {
    local pack_dir="$1" cls="$2" manifest_set="$3"
    [[ -d "$PACK/$pack_dir" ]] || return 0

    # The pack-side iteration root mirrors the project-side root. The
    # monolith assumed pack_dir == proj_dir (e.g. `project-template/scripts`
    # → `scripts/`); the directory-sweep TSV row carries one path that
    # plays both roles relative to its respective root.
    local proj_dir="$pack_dir"
    case "$proj_dir" in
        project-template/*) proj_dir="${proj_dir#project-template/}" ;;
    esac

    local f rel pack_rel proj_rel theirs ours dest base
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        rel="${f#"$PACK/$pack_dir/"}"
        pack_rel="$pack_dir/$rel"
        proj_rel="$proj_dir/$rel"

        # Manifest-row precedence: skip if this proj-relpath is already
        # in the parsed manifest. Use line-anchored grep -F -x for an
        # exact-match check that does not interpret regex metachars in
        # the path.
        if [[ -n "$manifest_set" ]] \
           && printf '%s\n' "$manifest_set" \
              | grep -F -x -q -- "$proj_rel"; then
            continue
        fi

        theirs="$f"
        ours="$_MIGRATOR_TARGET/$proj_rel"
        dest="$_MIGRATOR_TARGET/$proj_rel"
        base=$(mktemp)
        if ! migrator_baseline_to_tmp "$pack_rel" "$base"; then
            rm -f "$base"
            base=""
        fi
        [[ -f "$ours" ]] || ours=""

        if _migrator_is_dryrun; then
            _migrator_dryrun_log "sweep-dispatch" "$proj_rel (class=$cls)"
            _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
                "[dry-run] would dispatch via sweep"
        else
            customization_preserve \
                "$base" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" \
                >/dev/null
        fi

        # Same set -e guard as in _manifest_dispatch_transform — an empty
        # `$base` means baseline absence, not a failure; the loop must
        # continue.
        if [[ -n "$base" ]]; then
            rm -f "$base"
        fi
    done < <(find "$PACK/$pack_dir" -type f -print 2>/dev/null)
}
