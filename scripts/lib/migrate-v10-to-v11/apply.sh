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
# `S3.paused` lists one path-per-line of *.${MIGRATOR_OWN_SIDECAR_SUFFIX}
# sidecars (currently *.v10-customized for the v10→v11 adapter) the user
# must reconcile before --resume will proceed.
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
            # F12 (BD-095 retro fix): drop the `:-/path/to/pack` fallback;
            # by the time the freshness gate fires, PACK has been validated
            # upstream (the dispatcher requires it; the framework's S0
            # preflight enforces it). The fallback was a real-path-looking
            # footgun for users who copy-paste the recovery line.
            printf '→ Run: PACK=%s %s --dry-run %s\n' \
                "$PACK" \
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
            # F12 (BD-095 retro fix): drop `:-/path/to/pack` fallback.
            printf '→ Run: PACK=%s %s --dry-run %s\n' \
                "$PACK" \
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
            printf 'The customization surface (trinity files, .codex/config.toml,\n'
            printf 'BACKLOG.md, per-CLI agents/, plus every transform-class manifest\n'
            printf 'row — see migrator_target_surface_for_version + migrator_manifest)\n'
            printf 'has been modified after the dry-run report was generated. The\n'
            printf 'report at %s no longer reflects what --apply would do.\n' "$state_dir/report.md"
            printf '\n'
            # F12 (BD-095 retro fix): drop `:-/path/to/pack` fallback.
            printf '→ Run: PACK=%s %s --dry-run %s\n' \
                "$PACK" \
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
    #
    # BD-287 (VERIFY, no change): the prose auto-merge arm records a
    # markers-present result as `needs-reconciliation` with action `merged`
    # and a KEPT sidecar (`$5` non-dash), so this collector still pauses those
    # rows exactly like the trinity/pack-script/pack-agent `sidecar` rows. A
    # CLEAN prose merge drops the sidecar (`$5` == `-`) and is correctly NOT
    # collected (it is fully resolved at dispatch — F2).
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

# BD-287 — look up the (class, action, rel) triple for a needs-reconciliation
# row by its sidecar path (column $5, the value the collector wrote to
# stage-S3.paused). Echoes "<class>\t<action>\t<rel>" for the FIRST matching
# row (empty if none). This is what makes the interactive accept-pack choice
# (and the copy-paste menu prose) ROW-TYPE-AWARE per §2.1: a merged-with-markers
# prose row (action `merged`) holds the marked 3-way merge in the live file, so
# accept-pack must RE-INSTALL the pack template; a plain `sidecar` row's live
# file already IS the pack version. Pure read-only.
_v10_v11_apply_lookup_row() {
    local tsv="$1" sidecar="$2"
    [[ -f "$tsv" ]] || return 0
    awk -F'\t' \
        -v want="customization-detected-needs-reconciliation" \
        -v sc="$sidecar" \
        '$1 == want && $5 == sc { printf "%s\t%s\t%s\n", $2, $4, $3; exit }' \
        "$tsv"
}

# BD-287 — remove the `<live>.v10-base` stash a trinity conflict left at
# dispatch (§2.2). Called when a trinity row is resolved wholesale (accept /
# keep) so no `.v10-base` clutter survives. No-op for non-trinity rows (they
# have no stash) and harmless if the stash is already absent.
_v10_v11_apply_clear_base() {
    local class="$1" live="$2"
    [[ "$class" == "trinity" ]] && rm -f "${live}.v10-base"
    return 0
}

# BD-287 — row-type-aware `[1] accept pack` (F3 / OI-F3). For a
# merged-with-markers prose row (action `merged`) the LIVE file currently holds
# the marked 3-way merge, so accept-pack RE-INSTALLS THEIRS: it copies the pack
# v11 template `$PACK/project-template/<rel>` (the path derived exactly as the
# dispatch manifest maps it) over the live file BEFORE dropping the sidecar. For
# a plain `sidecar` row the live file already IS the pack v11 version, so it only
# drops the sidecar (today's behaviour). Either way, a trinity row also clears
# its `.v10-base` stash. Returns 0 when the row is resolved, non-zero to DEFER
# (the caller then leaves the sidecar for --resume). The migrator NEVER invokes
# the skill/agent from bash (Model B) — this is a pure-bash wholesale one-side
# selection, not a merge.
_v10_v11_apply_accept_pack() {
    local s="$1" live="$2" class="$3" action="$4" rel="$5"
    if [[ "$action" == "merged" ]]; then
        local tmpl="$PACK/project-template/$rel"
        if [[ ! -f "$tmpl" ]]; then
            warn "could not accept pack for $live: template $tmpl not found; deferring"
            return 1
        fi
        if ! cp "$tmpl" "$live"; then
            warn "could not re-install pack template over $live; deferring"
            return 1
        fi
    fi
    if ! rm -f "$s"; then
        warn "could not remove $s; deferring"
        return 1
    fi
    _v10_v11_apply_clear_base "$class" "$live"
    return 0
}

# Prints today's per-file copy-paste reconciliation menu over the sidecars
# currently listed in `<state-dir>/sentinels/stage-S3.paused`. Extracted
# VERBATIM from the pre-BD-283 conflict block so the non-interactive path
# stays byte-for-byte. Called by BOTH the non-interactive branch (full list)
# and the interactive deferred sub-path (trimmed list). No prompt is read
# here, so the fd-0 redirect on its internal `done < ...paused` loop is
# harmless. References the same globals the caller does
# (_MIGRATOR_STATE_DIR / MIGRATOR_OWN_SIDECAR_SUFFIX / PACK /
# MIGRATOR_FROM_VERSION / MIGRATOR_TO_VERSION / _MIGRATOR_TARGET).
_v10_v11_apply_print_copypaste_menu() {
    say ""
    say "── Migration paused — requires attention ──"
    say ""
    say "Dispatch found files that BOTH you and the pack changed. Your"
    say "prior copy of each was saved next to the live file as a"
    say ".${MIGRATOR_OWN_SIDECAR_SUFFIX} sidecar. Depending on the file, the"
    say "live file now holds either the new pack template or a 3-way merge"
    say "WITH conflict markers (stated per file below). The migration is"
    say "paused (not failed): the remaining stages (S4 relocations, S5"
    say "artifact installs, S6 report) run when you invoke --resume after"
    say "you resolve each file below."
    say ""
    say "For each file, choose ONE option and run its command:"
    say ""
    # BD-287 (§2.1): split the per-file prose by row type (class + action),
    # looked up from dispositions.tsv. A merged-with-markers prose row (action
    # `merged`, class generic/pm-chat) holds the MARKED merge (NOT the clean
    # pack version), so accept-pack must re-install the pack template and the
    # prose points at the conflict markers / skill; a STRUCTURED `merged` row
    # (JSON/TOML config, action `merged`, other class) holds a key-merge with
    # reconciliation warnings (no markers) — accept-pack still re-installs the
    # template but the prose points at the warnings, NOT the skill (which does
    # not apply to structured configs); a trinity sidecar points at the
    # resolve-merge-conflicts skill (section-aware fold) or the pre-reconcile
    # guide; a script/agent sidecar is re-applied by hand (the skill does not
    # merge executables/agents — F1). The migrator NEVER runs the skill itself
    # (Model B) — these are copy-paste commands the user runs.
    local s live tsv class action rel
    tsv="$_MIGRATOR_STATE_DIR/dispositions.tsv"
    local rm_all="" cp_all=""
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        # Sidecar paths are absolute (apply-mode); the live file is the
        # sidecar with the .${MIGRATOR_OWN_SIDECAR_SUFFIX} suffix stripped.
        live="${s%.${MIGRATOR_OWN_SIDECAR_SUFFIX}}"
        class=""; action=""; rel=""
        IFS=$'\t' read -r class action rel \
            <<< "$(_v10_v11_apply_lookup_row "$tsv" "$s")" || true
        say "  $live"
        if [[ "$action" == "merged" ]]; then
            if [[ "$class" == "generic" || "$class" == "pm-chat" ]]; then
                say "    1. Accept the pack's new version — discards YOUR"
                say "       customization. The live file holds the merge WITH"
                say "       conflict markers, so re-install the clean pack v11"
                say "       template over it, then remove the saved copy:"
                say "         cp '$PACK/project-template/$rel' '$live'"
                say "         rm '$s'"
                say "    2. Keep your customization — discards the pack v11 update;"
                say "       restores your prior copy over the merged file:"
                say "         mv '$s' '$live'"
                say "    3. Resolve the conflict markers — keeps both. Resolve the"
                say "       markers in '$live' by hand, or run the"
                say "       resolve-merge-conflicts skill; then mark it resolved:"
                say "         touch '$s.resolved'        # keep the sidecar as a record"
                say "         # ...or, once resolved:  rm '$s'"
            else
                say "    1. Accept the pack's new version — discards YOUR"
                say "       customization. The live file holds a key-merged"
                say "       config (with reconciliation warnings, no conflict"
                say "       markers), so re-install the clean pack v11 template"
                say "       over it, then remove the saved copy:"
                say "         cp '$PACK/project-template/$rel' '$live'"
                say "         rm '$s'"
                say "    2. Keep your customization — discards the pack v11 update;"
                say "       restores your prior copy over the merged file:"
                say "         mv '$s' '$live'"
                say "    3. Review the merged config — keeps both. The migrator"
                say "       key-merged your config with the pack; the"
                say "       resolve-merge-conflicts skill does NOT apply to"
                say "       structured configs — review the reconciliation"
                say "       warnings and adjust '$live' by hand, then mark it"
                say "       resolved:"
                say "         touch '$s.resolved'        # keep the sidecar as a record"
                say "         # ...or, once resolved:  rm '$s'"
            fi
            cp_all="${cp_all}cp '$PACK/project-template/$rel' '$live' && "
            rm_all="$rm_all '$s'"
        elif [[ "$class" == "trinity" ]]; then
            say "    1. Accept the pack's new version — discards YOUR"
            say "       customization. The live file already IS the pack v11"
            say "       template, so just remove the saved copies:"
            say "         rm '$s' '$live.v10-base'"
            say "    2. Keep your customization — discards the pack v11 update;"
            say "       restores your prior copy over the template:"
            say "         mv '$s' '$live' && rm -f '$live.v10-base'"
            say "    3. Merge both, section-aware — run the"
            say "       resolve-merge-conflicts skill (it folds your prior copy"
            say "       into the new pack trinity), or fold by hand per the"
            say "       pre-reconcile guide. The skill is not installed in this"
            say "       project until the migration finishes, so read it from"
            say "       the pack you are migrating from:"
            say "         $PACK/project-template/skills/resolve-merge-conflicts/SKILL.md"
            say "       Edit '$live' (your prior copy is"
            say "       in '$s'), then mark it resolved:"
            say "         touch '$s.resolved'        # keep the sidecar as a record"
            say "         # ...or, once merged:  rm '$s'"
            rm_all="$rm_all '$s' '$live.v10-base'"
        else
            say "    1. Accept the pack's new version — discards YOUR"
            say "       customization. The live file already IS the pack v11"
            say "       version, so just remove the saved copy:"
            say "         rm '$s'"
            say "    2. Keep your customization — discards the pack v11 update;"
            say "       restores your prior copy over the pack file:"
            say "         mv '$s' '$live'"
            say "    3. Re-apply your edit by hand — the"
            say "       resolve-merge-conflicts skill does NOT merge scripts or"
            say "       agents. The live file is the valid pack v11 version;"
            say "       re-apply your change over it (your prior copy is in"
            say "       '$s'), then mark it resolved:"
            say "         touch '$s.resolved'        # keep the sidecar as a record"
            say "         # ...or, once merged:  rm '$s'"
            rm_all="$rm_all '$s'"
        fi
        say ""
    done < "$_MIGRATOR_STATE_DIR/sentinels/stage-S3.paused"
    # OI-1 (BD-282): honest accept-pack-for-ALL one-shot. BD-287: a merged row
    # needs its clean pack template re-installed first (its live file holds
    # markers), so the shortcut chains a `cp` per merged row before the single
    # `rm`; a trinity row's `.v10-base` stash is cleared alongside its sidecar.
    # Explicitly labelled that it discards every customization to the files
    # above — reversible from the pre-migration backup dir.
    say "Shortcut — accept the pack's new version for ALL files above in"
    say "one step. This DISCARDS ALL your customizations to those files"
    say "(each remains recoverable from the ${_MIGRATOR_STATE_DIR##*/}-backup dir):"
    say "  ${cp_all}rm$rm_all"
    say ""
    say "When every file above is resolved, finish the migration:"
    # F12 (BD-095 retro fix): drop `:-/path/to/pack` fallback. This
    # block fires only AFTER S3 dispatch completed (post-mutation),
    # so PACK is definitely set.
    say "  PACK=$PACK \\"
    say "    scripts/migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}.sh \\"
    say "    --resume $_MIGRATOR_TARGET"
    say ""
}

# BD-283 — interactive reconciliation loop. Sets the GLOBAL
# `_V10V11_DEFERRED_COUNT` to the number of sidecars left unresolved. MUST be
# called as a PLAIN statement, NEVER $( ... ): the per-file summary uses
# say/info which write to STDOUT (migrator-core.sh), so a command
# substitution would swallow the menu UX AND corrupt the count on the
# auto-continue-vs-pause branch (MUST-1). bash-3.2-safe: no namerefs, no
# mapfile; the deferred count is a plain global, not a nameref return.
_v10_v11_apply_interactive_reconcile() {
    local state_dir="$1"
    local paused="$state_dir/sentinels/stage-S3.paused"
    local tsv="$state_dir/dispositions.tsv"

    # Slurp the paused list into an array FIRST so fd 0 is the real process
    # stdin when prompt_choice reads (do NOT nest prompt_choice inside a
    # `while … done < file` loop — fd 0 would be the file, not stdin).
    local -a _conflicts=()
    local line
    while IFS= read -r line; do
        [[ -n "$line" ]] && _conflicts+=("$line")
    done < "$paused"

    local -a _resolved=() _deferred=()
    local s live choice i class action rel
    for (( i=0; i<${#_conflicts[@]}; i++ )); do
        s="${_conflicts[i]}"
        # NIT-1: derive the live path via the suffix var, never a literal.
        live="${s%.${MIGRATOR_OWN_SIDECAR_SUFFIX}}"
        # BD-287 (§2.1): row-type context — a merged prose row (class
        # generic/pm-chat) holds a marked 3-way merge and a STRUCTURED merged
        # row (JSON/TOML) holds a key-merge with warnings; either way accept-pack
        # RE-INSTALLS the pack template (F3). A plain sidecar row's live file
        # already IS the pack version. Also drives the per-file pointer prose
        # (markers/skill for prose vs warnings for structured vs hand for
        # scripts/agents).
        class=""; action=""; rel=""
        IFS=$'\t' read -r class action rel \
            <<< "$(_v10_v11_apply_lookup_row "$tsv" "$s")" || true
        say ""
        say "  $live"
        info "your prior copy is saved at: $s"
        if [[ "$action" == "merged" ]]; then
            if [[ "$class" == "generic" || "$class" == "pm-chat" ]]; then
                info "the live file holds a 3-way merge WITH conflict markers — accept re-installs the pack template, keep restores your copy, or resolve the markers (run the resolve-merge-conflicts skill) then --resume"
            else
                info "the live file holds a key-merged config with reconciliation warnings (no conflict markers) — accept re-installs the pack template, keep restores your copy, or review/adjust the merged file by hand then --resume (the resolve-merge-conflicts skill does not apply to structured configs)"
            fi
        elif [[ "$class" == "trinity" ]]; then
            info "trinity file — resolve by hand or run the resolve-merge-conflicts skill (folds it section-aware), then --resume; or accept/keep to pick one side wholesale"
        elif [[ "$class" == "pack-script" || "$class" == "pack-agent" ]]; then
            info "script/agent — the skill does NOT merge these; re-apply your edit by hand over the pack v11 file, then --resume; or accept/keep to pick one side wholesale"
        fi
        # SHOULD-3: SPLIT form — `choice` is declared local ABOVE, so this
        # assignment preserves prompt_choice's rc (a combined `local
        # choice=$(…)` would mask it). prompt_choice: prompt→stderr,
        # token→stdout, rc!=0 on EOF. BD-287 (OI-F3 / N1): the migrator stays
        # pure bash — [3] and [s] both just DEFER (resolve during the pause per
        # the per-file guidance above — the skill for prose/trinity, by hand for
        # structured/scripts/agents — then --resume); there is NO in-bash merge.
        # The label is class-neutral so it does not imply the skill resolves
        # script/agent/structured rows (it does not).
        if choice=$(prompt_choice \
              "[1] accept pack  [2] keep yours  [3] defer / resolve later  [s] skip  [q] quit" \
              "1,2,3,s,q"); then
            case "$choice" in
                1) if _v10_v11_apply_accept_pack "$s" "$live" "$class" "$action" "$rel"; then
                       _resolved+=("$s")
                   else _deferred+=("$s"); fi ;;
                2) if mv "$s" "$live"; then
                       _v10_v11_apply_clear_base "$class" "$live"; _resolved+=("$s")
                   else warn "could not restore $s; deferring"; _deferred+=("$s"); fi ;;
                3|s) _deferred+=("$s") ;;
                q) _deferred+=("${_conflicts[@]:i}"); break ;;   # SHOULD-4: current + remainder
            esac
        else
            _deferred+=("${_conflicts[@]:i}")                    # EOF: current + remainder
            break
        fi
    done

    # SHOULD-1: prune RESOLVED (accept/keep) rows from dispositions.tsv so the
    # S6 report (and any intermediate pause report) does not list resolved
    # files under "Files needing manual reconciliation". Deferred rows stay.
    if (( ${#_resolved[@]} > 0 )) && [[ -f "$tsv" ]]; then
        _v10_v11_apply_prune_resolved_rows "$tsv" "${_resolved[@]}"
    fi

    # Rewrite the sentinel to the deferred subset (remove it if empty).
    if (( ${#_deferred[@]} > 0 )); then
        printf '%s\n' "${_deferred[@]}" > "$paused"
    else
        rm -f "$paused"
    fi

    _V10V11_DEFERRED_COUNT=${#_deferred[@]}
    return 0
}

# BD-283 — delete the RESOLVED (accept/keep) needs-reconciliation rows from
# dispositions.tsv, header-preservingly + atomically. The `needs` token MUST
# match `_v10_v11_apply_collect_conflicts`' awk (they are a matched pair). The
# `keep` set is the resolved sidecar paths (same strings the collector wrote
# to stage-S3.paused from column $5), so the `$5 in keep` test matches
# byte-for-byte. Gate-2-safe: introduces no unknown-classification row, never
# zero-bytes the tsv (the header stays), and does not touch the filesystem the
# orphan-sidecar check reads.
_v10_v11_apply_prune_resolved_rows() {
    local tsv="$1"; shift
    local tmp match
    tmp=$(mktemp); match=$(mktemp)
    printf '%s\n' "$@" > "$match"
    awk -F'\t' \
        -v needs="customization-detected-needs-reconciliation" \
        'NR==FNR { keep[$0]=1; next }
         FNR==1  { print; next }
         ($1==needs && ($5 in keep)) { next }
         { print }' \
        "$match" "$tsv" > "$tmp"
    mv "$tmp" "$tsv"
    rm -f "$match"
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
        if prompt_should_interact "${_V10V11_FORCE_NO_INTERACT:-0}" "${_V10V11_FORCE_INTERACT:-0}"; then
            # BD-283 interactive reconciliation: walk each conflict and apply
            # the user's choice in-process. If every conflict is resolved,
            # RETURN so the framework auto-continues S4–S6 (the tested
            # no-conflict control-flow path — no separate --resume). Any
            # deferred (merge-later / skip / quit / EOF) conflict falls back to
            # today's copy-paste + --resume flow for exactly those files.
            say ""
            say "── Interactive reconciliation ──"
            say "For each file, choose: accept pack / keep yours / resolve via skill later / skip / quit."
            _V10V11_DEFERRED_COUNT=0
            # PLAIN call, never $( ): the per-file summary uses say/info which
            # write to STDOUT; a command substitution would swallow the menu UX
            # AND corrupt the deferred count (MUST-1). The helper sets the
            # global _V10V11_DEFERRED_COUNT.
            _v10_v11_apply_interactive_reconcile "$_MIGRATOR_STATE_DIR"
            if (( _V10V11_DEFERRED_COUNT == 0 )); then
                # All resolved in-process — the helper already removed
                # stage-S3.paused. Return to the framework, which continues
                # S4/S5/S6 exactly as on the no-conflict path.
                return 0
            fi
            # Some conflicts deferred — the helper trimmed stage-S3.paused to
            # the deferred subset. Print today's copy-paste menu over that
            # subset and pause for --resume.
            _v10_v11_apply_print_copypaste_menu
            migrator_pause
        else
            # Non-interactive (--no-interactive, CI, piped stdin, non-TTY):
            # today's copy-paste menu over the FULL conflict list, then pause.
            # Byte-for-byte the pre-BD-283 behavior (same helper body, same
            # full stage-S3.paused input).
            _v10_v11_apply_print_copypaste_menu
            # Signal a deliberate, resumable pause. `migrator_pause` sets
            # `_MIGRATOR_PAUSED` and exits 0; the framework's EXIT trap then
            # renders the PAUSED (not FAILED) report. Pausing for user input is
            # not a failure — `--resume` completes the run.
            migrator_pause
        fi
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

    # F4 (BD-095 retro fix): paused-state guard. Refuse `--apply` when a
    # previous run paused for sidecar reconciliation. Without this check
    # `--apply` would silently re-execute S0..S3 and reach S1 with the
    # backup-dir-already-exists error — telling the user to remove the
    # backup when the right answer is `--resume`. (See PACK-REVIEW-
    # BD-095-RETRO.md F4.) Mirrors the F3 guard in the bare branch of
    # the adapter dispatcher.
    local _paused_sentinel="$state_dir/sentinels/stage-S3.paused"
    if [[ -f "$_paused_sentinel" ]]; then
        {
            printf 'error: --apply refused; a paused migration exists\n'
            printf '  paused-sentinel: %s\n' "$_paused_sentinel"
            printf '\n'
            printf '→ Resolve the listed sidecars then run:\n'
            # F12 (BD-095 retro fix): drop `:-/path/to/pack` fallback.
            printf '    PACK=%s scripts/migrate-%s-to-%s.sh --resume %s\n' \
                "$PACK" \
                "$MIGRATOR_FROM_VERSION" "$MIGRATOR_TO_VERSION" \
                "$target"
            printf '\n'
            printf '  Or to start over, restore from %s-backup and re-run.\n' \
                "$state_dir"
        } >&2
        exit "${EXIT_INTERNAL:-99}"
    fi

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
    # after _stage_libs has wiped the state dir, then run BD-101 Gate 2
    # (post-Phase-A) and Gate 3 (post-Phase-B, conditional).
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

            # BD-101 Gate 2 — post-Phase-A verification. On gate failure
            # exit with EXIT_GATE_FAILED so callers / `--resume` can
            # distinguish gate failure from stage failure (codes 20..30).
            if declare -F migrate_v10_to_v11_gate2_run >/dev/null 2>&1; then
                if ! migrate_v10_to_v11_gate2_run \
                        "$_MIGRATOR_TARGET" \
                        "$_MIGRATOR_STATE_DIR" \
                        "${PACK:-}"; then
                    exit "${EXIT_GATE_FAILED:-31}"
                fi
            fi

            # BD-101 Gate 3 — post-Phase-B verification, conditional on
            # tracker mode being active at the target. The gate itself
            # decides PASS / SKIP / FAIL.
            if declare -F migrate_v10_to_v11_gate3_run >/dev/null 2>&1; then
                if ! migrate_v10_to_v11_gate3_run \
                        "$_MIGRATOR_TARGET" \
                        "${PACK:-}"; then
                    exit "${EXIT_GATE_FAILED:-31}"
                fi
            fi
        }
    fi

    # Wrap _stage_libs to restore the fingerprint after it wipes the
    # state dir. (Pure additive: the original behavior is preserved;
    # we just re-stash the file the user already validated.)
    #
    # F8 + F9 (BD-095 retro fix): the underlying state-dir-wipe-then-
    # restore pattern is a workaround for the framework's `_stage_libs`
    # `rm -rf $_MIGRATOR_STATE_DIR`. A cleaner fix is a preserve-list
    # in `_stage_libs` (BD-119 framework cleanup, out of scope here).
    # In the meantime we (a) remove the stash file as soon as the
    # restore lands so the temp file does not survive a later
    # framework `die`/`fail_stage` (F9 leak fix), and (b) note that
    # restoring the fingerprint on a failed run is harmless because
    # any post-S2 mutation makes a future `--apply` fail at S0
    # idempotency or S1 backup-dir-exists (F8 — works around the
    # framework gap; documented for future BD-119 cleanup).
    if ! declare -F _v10_to_v11_orig_stage_libs >/dev/null 2>&1; then
        eval "$(declare -f _stage_libs \
            | sed '1s/_stage_libs/_v10_to_v11_orig_stage_libs/')"
        _stage_libs() {
            _v10_to_v11_orig_stage_libs
            # Restore the dry-run fingerprint after the framework's
            # `rm -rf $_MIGRATOR_STATE_DIR`. Resume mode reads it.
            cp "$fp_stash" "$_MIGRATOR_STATE_DIR/dry-run.fingerprint"
            # F9: the stash file's job is done — drop it now so a
            # later framework `die` cannot leak it under $TMPDIR.
            rm -f "$fp_stash"
            fp_stash=""
        }
    fi

    migrator_run --apply "$@"
    local rc=$?
    # Belt-and-braces: if the `_stage_libs` wrapper never ran (early
    # framework failure between trap-set and stage-libs entry), the
    # original cleanup line still removes the stash. Idempotent —
    # `rm -f ""` and `rm -f $fp_stash` both succeed silently.
    [[ -n "${fp_stash:-}" ]] && rm -f "$fp_stash"
    return "$rc"
}
